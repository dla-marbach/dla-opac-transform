DIR="${DIR:-example}"
sets=(ak au be bf bi hs ks mm pe se sy th)

### Import ###

for set in ${sets[@]}; do
    orcli import tsv "${DIR}"/input/${set}.tsv --projectName "${set}" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

### Transform ###

# Konfigurationsdateien in-place von YAML nach JSON konvertieren
find "${DIR}/tmp/config" -name '*.yaml' -exec yq -i -o json {} \;

# Schritt 1: Exemplar-IDs in AK ergänzen
for set in ${sets[@]}; do
    find "${DIR}/tmp/config/main/01/" -name "*_${set}.yaml" -exec ${BASH_ALIASES[orcli]} transform "${set}" '{}' \+ &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Schritt 2: Feld display für alle Datensätze bilden

for set in ${sets[@]}; do
    find "${DIR}/tmp/config/main/02/" -name "*_${set}.yaml" -exec ${BASH_ALIASES[orcli]} transform "${set}" '{}' \+ &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Schritt 3: Für Felder mit _id auch _display anreichern

for set in ${sets[@]}; do
    find "${DIR}/tmp/config/main/03/" -name "*_${set}.yaml" -exec ${BASH_ALIASES[orcli]} transform "${set}" '{}' \+ &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Schritt 4: Felder für Exportformate RIS, DC und MODS bilden

for set in ${sets[@]}; do
    find "${DIR}/tmp/config/main/04/" -name "*_${set}.yaml" -exec ${BASH_ALIASES[orcli]} transform "${set}" '{}' \+ &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

### Export ###

for set in ${sets[@]}; do
    orcli export tsv "${set}" --output "${DIR}/tmp/${set}.tsv" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

for set in ${sets[@]}; do
    orcli export jsonl "${set}" --separator "␟" --output "${DIR}/tmp/${set}.jsonl" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
