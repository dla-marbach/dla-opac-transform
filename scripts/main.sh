DIR="${DIR:-example}"
orcli import csv "${DIR}"/input/*.csv --projectName "test"
orcli transform "test" config/main/*.json
orcli export tsv "test" --output "${DIR}/tmp/test.tsv"
