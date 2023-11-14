DIR="${DIR:-example}"
orcli import jsonl "${DIR}"/input/*.jsonl --rename --projectName "test"
orcli transform "test" config/main/*.json
orcli export jsonl "test" --output "${DIR}/tmp/test.jsonl"
