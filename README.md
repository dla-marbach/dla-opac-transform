# dla-opac-transform

Scripte und Konfigurationsdateien für den ETL-Workflow des Online-Katalogs des Deutschen Literaturarchivs Marbach https://www.dla-marbach.de/katalog-beta

## Voraussetzungen

* GNU/Linux mit Bash 4+
* [go-task](https://taskfile.dev)
* [curl](https://curl.se)
* [jq](https://stedolan.github.io/jq)
* [yq](https://github.com/mikefarah/yq)

## Installation

[OpenRefine](https://openrefine.org) und [orcli](https://github.com/opencultureconsulting/orcli):

```sh
task install
```

## Nutzung

Das Arbeitsverzeichnis wird über die Variable `DIR` gesetzt. Die JSON-Lines-Dateien müssen in einem Unterverzeichnis `input` bereitgestellt werden.

Weitere Variablen:
* `MEMORY`: Wieviel Arbeitsspeicher OpenRefine verwenden darf. Default: `2G`
* `PORT`: Der von OpenRefine zu verwendende Port. Default: `3333`

Beispiel für Arbeitsverzeichnis `data` mit JSONL-Dateien in `data/input`, 4 GB Java heap space für OpenRefine und Port `3334`:

```sh
task DIR=data MEMORY=4G PORT=3334
```

Das Verzeichnis `data` ist bereits in `.gitignore` gelistet.

## Entwicklung

```sh
task dev
```

OpenRefine GUI erreichbar unter http://localhost:3333
