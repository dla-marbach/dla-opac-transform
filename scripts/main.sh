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

# Spalten sortieren
for set in ${sets[@]}; do
    orcli sort columns "${set}" --first id --first display &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# TSV
for set in ${sets[@]}; do
    orcli export tsv "${set}" --output "${DIR}/tmp/${set}.tsv" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# JSON-Lines
for set in ${sets[@]}; do
    orcli export jsonl "${set}" --separator "␟" --output "${DIR}/tmp/${set}.jsonl" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# export DC für OAI
for set in ak bf bi hs; do
    orcli export csv "${set}" \
    --select id,dateModified,exportDC \
    --facets '[ { "type": "text", "columnName": "confidential", "invert":true, "query":"true" } ]' \
    --output "${DIR}/tmp/tmp-oai-dc_${set}.csv" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
head -n 1 "${DIR}"/tmp/tmp-oai-dc_ak.csv > "${DIR}"/tmp/oai-dc.csv && tail -n+2 -q "${DIR}"/tmp/tmp-oai-dc_*.csv >> "${DIR}"/tmp/oai-dc.csv
rm "${DIR}"/tmp/tmp-oai-dc*.csv

# export MODS für OAI
for set in ak bf bi hs; do
    orcli export csv "${set}" \
    --select id,dateModified,exportMODS \
    --facets '[ { "type": "text", "columnName": "confidential", "invert":true, "query":"true" } ]' \
    --output "${DIR}/tmp/tmp-oai-mods_${set}.csv" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
head -n 1 "${DIR}"/tmp/tmp-oai-mods_ak.csv > "${DIR}"/tmp/oai-mods.csv && tail -n+2 -q "${DIR}"/tmp/tmp-oai-mods_*.csv >> "${DIR}"/tmp/oai-mods.csv
rm "${DIR}"/tmp/tmp-oai-mods*.csv
