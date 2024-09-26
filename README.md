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

Änderungen im Ausgabeformat JSON-Lines prüfen:

```sh
git diff -U0 --word-diff-regex='[^,]+' --word-diff=porcelain example/output/*.jsonl
```
