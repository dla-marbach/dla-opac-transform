DIR="${DIR:-example}"
sets=(ak au be bf bi hs ks mm pe se sy th)

### Import ###

for set in ${sets[@]}; do
    orcli import jsonl "${DIR}"/input/${set}.jsonl --rename --projectName "${set}" &
done
wait

### Transform ###

# Kopie der Konfigurationsdateien erstellen
mkdir -p "${DIR}/tmp/config"
cp -r "${DIR}/config/main" "${DIR}/tmp/config/main"
# Konfigurationsdateien in-place von YAML nach JSON konvertieren
find "${DIR}/tmp/config" -name '*.yaml' -exec yq -i -o json {} \;

orcli transform "ak" "${DIR}/tmp/config/main/name_ak.yaml"

# Kopie der Konfigurationsdateien löschen
rm -r "${DIR}/tmp/config"

### Export ###

for set in ${sets[@]}; do
    orcli export jsonl "${set}" --output "${DIR}/tmp/${set}.jsonl" &
done
wait
