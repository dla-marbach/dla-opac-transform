# dla-katalog-etl

Scripte und Konfigurationsdateien für den ETL-Workflow des Online-Katalogs des Deutschen Literaturarchivs Marbach https://www.dla-marbach.de/katalog-beta

## Voraussetzungen

* GNU/Linux mit Bash 4+
* [go-task](https://taskfile.dev)
* [jq](https://stedolan.github.io/jq)
* [curl](https://curl.se)

## Installation

[OpenRefine](https://openrefine.org) und [orcli](https://github.com/opencultureconsulting/orcli):

```sh
task install
```

## Nutzung

```sh
task default
```

## Entwicklung

```sh
cd main
../openrefine/orcli run main.sh --interactive
```

OpenRefine GUI erreichbar unter http://localhost:3333
