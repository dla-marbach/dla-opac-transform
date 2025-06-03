# dla-opac-transform

Scripte und Konfigurationsdateien für den ETL-Workflow des Online-Katalogs des Deutschen Literaturarchivs Marbach https://www.dla-marbach.de/katalog

## Formatdokumentation

siehe [Dokumentation Internformat](docs/README.md)

## Voraussetzungen

* GNU/Linux mit Bash 4+
* [go-task](https://taskfile.dev)
* [curl](https://curl.se)
* [jq](https://stedolan.github.io/jq)
* [yq](https://github.com/mikefarah/yq)

## Installation

[OpenRefine](https://openrefine.org), [orcli](https://github.com/opencultureconsulting/orcli) und [Apache Solr](https://solr.apache.org):

```sh
task install
```

## Nutzung

Das Arbeitsverzeichnis wird über die Variable `DIR` gesetzt. Die Quelldateien im TSV-Format müssen in einem Unterverzeichnis `input` bereitgestellt werden.

Weitere Variablen:
* `MEMORY`: Wieviel Arbeitsspeicher OpenRefine verwenden darf. Default: `2G`
* `PORT`: Der von OpenRefine zu verwendende Port. Default: `3333`

Beispiel für Arbeitsverzeichnis `data` mit Quelldateien in `data/input`, 4 GB Java heap space für OpenRefine und Port `3334`:

```sh
task DIR=data MEMORY=4G PORT=3334
```

Das Verzeichnis `data` ist bereits in `.gitignore` gelistet.

## Entwicklung

orcli im interaktiven Modus starten (vgl. http://localhost:3333):

```sh
task dev
```

Indexierung in Solr testen (vgl. http://localhost:8983):

```sh
task solr
```

Konvertierung der JSONL-Daten in YAML:

```sh
task yaml
```

## Vorgehen bei Erweiterungen

1. Solr [Schema](config/solr/schema.xml) erweitern und ggf. [Konfiguration](config/solr/solrconfig.xml) anpassen
2. Beispieldaten ergänzen in [example/input](example/input)
3. OpenRefine Transformationsregeln ergänzen in [config/main](config/main).
    * Dazu ggf. orcli im interaktiven Modus starten mit `task dev`
    * JSON aus OpenRefine-History in YAML konvertieren z.B. mit https://onlineyamltools.com/convert-json-to-yaml
4. Daten generieren
    ```sh
    task main yaml
    ```
5. Ergebnisse prüfen mit git diff
    ```sh
    git diff example/output/*.yaml
    git diff -U0 --word-diff-regex='[^,]+' --word-diff=porcelain example/output/*.jsonl
    ```
6. Indexierung in Solr testen
    ```sh
    task solr
    ```
7. Dokumentation in [docs/internformat.csv](docs/internformat.csv)
8. schemaVersion in [scripts/main.sh](scripts/main.sh) hochzählen
9. Git Commit und Push
10. GitHub [Release Notes](https://github.com/dla-marbach/dla-opac-transform/releases)
11. Konfiguration des Solr auf Produktivsystem aktualisieren
