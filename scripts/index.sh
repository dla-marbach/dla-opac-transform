#!/bin/bash
# Indexierung der JSONL-Dateien in Solr: Core "indexing" neu befüllen, prüfen und per SWAP live schalten.
# Der Core "internformat" bleibt bis zum SWAP unverändert; schlägt ein Schritt fehl, bricht das Skript mit
# Exit-Code ungleich 0 ab und der Katalog arbeitet mit dem bisherigen Index weiter.
#
# Voraussetzung: Die Solr-Konfiguration aus config/solr dieses Checkouts ist auf dem Solr-Server eingespielt
# (siehe docs/solr.md, Abschnitt "Konfiguration aktualisieren"). Das Skript prüft das in Schritt 2.
#
# Aufruf:
#   SOLR=http://<solr-host>:8983/solr OUTPUT=<Verzeichnis mit *.jsonl> scripts/index.sh
# Optional: MAX_ABWEICHUNGEN (Standard 100), siehe Schritt 7.
set -euo pipefail
SOLR="${SOLR:?SOLR setzen, z.B. http://<solr-host>:8983/solr}"
OUTPUT="${OUTPUT:?OUTPUT setzen: Verzeichnis mit den JSONL-Dateien}"
MAX_ABWEICHUNGEN="${MAX_ABWEICHUNGEN:-100}"
CONFIG="$(cd "$(dirname "$0")/.." && pwd)/config/solr"

# Anfrage an Solr; Antwort nach stderr, Abbruch bei HTTP-Status ungleich 200
solr() { local code; code=$(curl --silent --show-error -o /dev/stderr -w '%{http_code}' "$@"); echo >&2; [ "$code" -eq 200 ]; }

echo "1. Core indexing neu laden (aktuelle Konfiguration des Servers)" >&2
solr "$SOLR/admin/cores?action=RELOAD&core=indexing"

echo "2. Konfiguration des Servers mit $CONFIG vergleichen" >&2
for f in schema.xml solrconfig.xml; do
  if ! curl --silent --show-error --fail "$SOLR/indexing/admin/file?file=$f&contentType=text/plain" | cmp --silent - "$CONFIG/$f"; then
    echo "   Abbruch: $f auf dem Solr-Server weicht von $CONFIG/$f ab." >&2
    echo "   Zuerst die Konfiguration aktualisieren (docs/solr.md, Abschnitt \"Konfiguration aktualisieren\")." >&2
    exit 1
  fi
done

echo "3. Core indexing leeren" >&2
solr "$SOLR/indexing/update?commit=true" -H 'Content-Type: application/json' --data-binary '{"delete":{"query":"*:*"}}'

echo "4. Daten laden" >&2
for f in "$OUTPUT"/*.jsonl; do
  echo "   $f" >&2
  solr "$SOLR/indexing/update/json/docs" -X POST -H 'Content-Type: application/json' --upload-file "$f"
done

echo "5. Commit und Optimize" >&2
solr "$SOLR/indexing/update?commit=true&optimize=true"

echo "6. Suggester aufbauen" >&2
solr "$SOLR/indexing/suggest?suggest=true&suggest.build=true&suggest.dictionary=mySuggester"
solr "$SOLR/indexing/suggest?suggest=true&suggest.build=true&suggest.dictionary=text"

echo "7. Vollständigkeit prüfen (vor dem Live-Schalten)" >&2
abweichungen=$(diff <(perl -lne 'print $1 if /"id":\s*"([^"]+)"/' "$OUTPUT"/*.jsonl | LC_ALL=C sort) \
                    <(curl --silent --show-error "$SOLR/indexing/query?q=*:*&fl=id&rows=100000000&wt=csv&csv.header=false" | LC_ALL=C sort) \
               | grep -E '^[<>]' || true)
anzahl=$(printf '%s' "$abweichungen" | grep -c . || true)
if [ "$anzahl" -gt 0 ]; then
  echo "   $anzahl Abweichungen (< nur in JSONL, > nur in Solr), die ersten 100:" >&2
  printf '%s\n' "$abweichungen" | head -n 100 >&2
fi
if [ "$anzahl" -gt "$MAX_ABWEICHUNGEN" ]; then
  echo "   Abbruch: mehr als $MAX_ABWEICHUNGEN Abweichungen, internformat bleibt unverändert" >&2
  exit 1
fi

echo "8. Live schalten (SWAP)" >&2
solr "$SOLR/admin/cores?action=SWAP&core=indexing&other=internformat"
