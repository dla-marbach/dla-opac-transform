orcli import csv "input/test.csv" --projectName "test"
orcli transform "test" "config/test.json"
orcli export tsv "test" --output "output/test.tsv"
