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

Beispiel für Arbeitsverzeichnis `data` mit JSONL-Dateien in `data/input`:

```sh
task DIR=data
```

Das Verzeichnis `data` ist bereits in `.gitignore` gelistet.

## Entwicklung

```sh
openrefine/orcli run scripts/main.sh --interactive
```

OpenRefine GUI erreichbar unter http://localhost:3333
