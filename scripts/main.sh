DIR="${DIR:-example}"
sets=(ak au be bf bi hs ks mm pe se sy th)

### Import ###

for set in ${sets[@]}; do
    orcli import tsv "${DIR}"/input/${set}*.tsv --projectName "${set}" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

for f in "${DIR}"/tmp/config/mappings/* ; do
    p=${f##*/}
    orcli import csv ${f} --projectName "${p%.csv}"
done

### Transform ###

# Konfigurationsdateien in-place von YAML nach JSON konvertieren
find "${DIR}/tmp/config" -name '*.yaml' -exec yq -i -o json {} \;

# Jedes Verzeichnis nacheinander bearbeiten
for d in "${DIR}"/tmp/config/main/*/ ; do
    for set in ${sets[@]}; do
        find "${d}" -name "*_${set}.yaml" -exec ${BASH_ALIASES[orcli]} transform "${set}" '{}' \+ &
        pids+=($!)
    done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
done

# schemaVersion setzen
grel='[ {
"op": "core/text-transform",
"engineConfig": { "facets": [], "mode": "row-based" },
"columnName": "schemaVersion",
"expression": "grel:\"0.6.4\""
} ]'
for set in ${sets[@]}; do
    echo "${grel}" | orcli transform "${set}" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

### Export ###

# Spalten sortieren
for set in ${sets[@]}; do
    orcli sort columns "${set}" --first id --first display &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# CSV
for set in ${sets[@]}; do
    orcli export csv "${set}" --output "${DIR}/tmp/${set}.csv" &
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
    --facets '[ { "type": "text", "columnName": "confidential", "invert":true, "query":"true" }, { "type": "list", "expression": "grel:isNonBlank(value)", "columnName": "exportDC", "selection": [{"v": {"v": true}}] } ]' \
    --output "${DIR}/tmp/tmp-oai-dc_${set}.csv" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
head -n 1 "${DIR}"/tmp/tmp-oai-dc_ak.csv > "${DIR}"/tmp/oai-dc.csv && tail -n+2 -q "${DIR}"/tmp/tmp-oai-dc_*.csv >> "${DIR}"/tmp/oai-dc.csv
rm "${DIR}"/tmp/tmp-oai-dc*.csv

# export MODS für OAI
for set in ak bf bi hs; do
    orcli export csv "${set}" \
    --select id,dateModified,exportMODS \
    --facets '[ { "type": "text", "columnName": "confidential", "invert":true, "query":"true" }, { "type": "list", "expression": "grel:isNonBlank(value)", "columnName": "exportMODS", "selection": [{"v": {"v": true}}] } ]' \
    --output "${DIR}/tmp/tmp-oai-mods_${set}.csv" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
head -n 1 "${DIR}"/tmp/tmp-oai-mods_ak.csv > "${DIR}"/tmp/oai-mods.csv && tail -n+2 -q "${DIR}"/tmp/tmp-oai-mods_*.csv >> "${DIR}"/tmp/oai-mods.csv
rm "${DIR}"/tmp/tmp-oai-mods*.csv
