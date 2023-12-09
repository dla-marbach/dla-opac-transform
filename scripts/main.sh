DIR="${DIR:-example}"
sets=(ak au be bf bi hs ks mm pe se sy th)

### Import ###

for set in ${sets[@]}; do
    orcli import tsv "${DIR}"/input/${set}.tsv --projectName "${set}" &
done
wait

### Transform ###

# Konfigurationsdateien in-place von YAML nach JSON konvertieren
find "${DIR}/tmp/config" -name '*.yaml' -exec yq -i -o json {} \;

# Schritt 1: Exemplar-IDs in AK ergänzen
for set in ${sets[@]}; do
    find "${DIR}/tmp/config/main/01/" -name "*_${set}.yaml" -exec ${BASH_ALIASES[orcli]} transform "${set}" '{}' \+ &
done
wait

# Schritt 2: Feld display für alle Datensätze bilden
for set in ${sets[@]}; do
    find "${DIR}/tmp/config/main/02/" -name "*_${set}.yaml" -exec ${BASH_ALIASES[orcli]} transform "${set}" '{}' \+ &
done
wait

### Export ###

for set in ${sets[@]}; do
    orcli export tsv "${set}" --output "${DIR}/tmp/${set}.tsv" &
done
wait
for set in ${sets[@]}; do
    orcli export jsonl "${set}" --separator "␟" --output "${DIR}/tmp/${set}.jsonl" &
done
wait
