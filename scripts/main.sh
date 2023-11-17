DIR="${DIR:-example}"
sets=(ak au be bf bi hs ks mm pe se sy th)

### Import ###

for set in ${sets[@]}; do
    orcli import jsonl "${DIR}"/input/${set}.jsonl --rename --projectName "${set}" &
done
wait

### Transform ###

# Konfigurationsdateien in-place von YAML nach JSON konvertieren
find "${DIR}/tmp/config" -name '*.yaml' -exec yq -i -o json {} \;

orcli transform "ak" "${DIR}/tmp/config/main/name_ak.yaml"

### Export ###

for set in ${sets[@]}; do
    orcli export jsonl "${set}" --output "${DIR}/tmp/${set}.jsonl" &
done
wait
