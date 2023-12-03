# Dokumentation Internformat für Katalog und Datendienst

Version: 0.4

## Feldliste

Die Tabelle [internformat.csv](internformat.csv) beinhaltet eine Liste aller Felder und deren Bedeutung.

## Datenbestände

* AK: Bibliotheksmaterialien und Werke
  * Werke enthalten im Feld `category` den Wert `Werktitel`.
* AU: Exemplare
  * Exemplare werden nicht als eigenständige Datensätze im Katalog präsentiert.
  * Relevante Exemplarinformationen werden in AK, BI und HS in Feldern mit Präfix `item` ergänzt.
* BE: Erwerbung
  * Erwerbungsdaten werden nicht als eigenständige Datensätze im Katalog präsentiert.
  * Relevante Informationen zur Erwerbung werden in BF, BI und HS in Feldern mit Präfix `accession` ergänzt.
* BF: Nachlässe und Spezialsammlungen
* BI: Bilder & Objekte
* HS: Handschriften
* KS: Körperschaften
* MM: Digitale Objekte
  * Digitale Objekte werden nicht als eigenständige Datensätze im Katalog präsentiert.
  * Relevante Informationen zu digitalen Objekten werden in AK, BF, BI und HS in Feldern mit Präfix `media` ergänzt.
* PE: Personen
* SE: Systematikketten
* SY: Fachsystematik
* TH: Orte und Sachbegriffe
* DBIS: Digitale Nachschlagewerke
* EZB: Elektronische Zeitschriftenbibliothek

## Datenformat

Felder mit Suffix `_mv` können mehrere Werte enthalten.
* Im Ausgabeformat JSON- bzw. JSONL werden diese Felder als Array kodiert.
* Im Ausgabeformat TSV und während der Datenverarbeitung wird als temporäres Trennzeichen `␟` (Symbol For Unit Separator, [U+241F](https://www.unicode.org/charts/PDF/U2400.pdf)) verwendet.

Beziehungen zwischen Feldern mit synchron mehrfachbelegten Werten werden mit einem Unterstrich `_` dargestellt. Sie sind immer gleich oft belegt. Als Platzhalterzeichen wird `␣` (Open Box, [U+2423](https://www.unicode.org/charts/PDF/U2400.pdf)) verwendet. Beispiel:
* personBy_id:
  * 0: `PE00000001`
  * 1: `PE00000002`
  * 2: `PE00000003`
* personBy_label:
  * 0: `Person 1`
  * 1: `Person 2`
  * 2: `Person 3`
* personBy_role:
  * 0: `Funktion Person 1`
  * 1: `␣`
  * 2: `Funktion Person 3`

Für den Katalog werden zahlreiche Zusatzfelder gebildet, um Funktionen wie Facettierung und Suche zu unterstützen. Diese werden mit folgenden Präfixen gruppiert:
* `display` für Trefferliste und Detailanzeige
* `filter` für Facetten und Suchfilter
* `media` für digitale Objekte
* `search` für erweiterte Suche und Normdaten
* `lobid` für angereicherte Daten aus GND und Entity Facts über lobid-gnd
* `wikidata` für angereicherte Daten aus Wikidata

## Datenquellen

Fast alle Daten entstammen der hauseigenen Katalogisierung mit Kallías. Nur wenige Daten werden aus externen Quellen angereichert:
* Datenbestand `EZB`: Datenabruf aus der Elektronischen Zeitschriftenbibliothek (EZB), jährliche Aktualisierung
* Datenbestand `DBIS`: Datenlieferung des Datenbank-Informationssystems (DBIS), jährliche Aktualisierung
* Felder mit Präfix `wikidata`: Anreicherung über Wikidata API, wöchentliche Aktualisierung
* Felder mit Präfix `lobid`: Anreicherung mit Daten aus GND und Entity Facts über lobid-gnd API, wöchentliche Aktualisierung
  * [lobid-gnd](https://lobid.org/gnd) ist ein LOD-Dienst des hbz — Hochschulbibliothekszentrum des Landes NRW
