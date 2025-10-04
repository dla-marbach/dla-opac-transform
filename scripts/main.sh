DIR="${DIR:-example}"
sets=(ak au be bf bi hs ks mm pe se sy th)

### Import ###

# Kallías im Internformat
for set in ${sets[@]}; do
    orcli import tsv "${DIR}"/input/${set}*.tsv --projectName "${set}" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Mappings
for f in "${DIR}"/tmp/config/mappings/* ; do
    p=${f##*/}
    orcli import csv ${f} --projectName "${p%.csv}"
done

# Enrichment Cache
url="https://github.com/dla-marbach/dla-opac-gnd-enrichment/raw/refs/heads/main/output/"
files=(
    commons-rechte.tsv
    lobid-depiction.tsv
    lobid-deutsche-biographie.tsv
    lobid-dewiki.tsv
    lobid-filmportal.tsv
    lobid-wikidata.tsv
    wikidata-P109.tsv
    wikidata-P18.tsv
    wikidata-P2639.tsv
    wikidata-P856.tsv
)
for f in "${files[@]}"; do
    orcli import tsv "${url}${f}" --projectName "${f%.tsv}" --columnNames "key,value"
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
"op": "core/column-addition",
"engineConfig": { "facets": [], "mode": "row-based" },
"baseColumnName": "id",
"newColumnName": "schemaVersion",
"columnInsertIndex": 2,
"expression": "grel:\"0.9.0\""
} ]'
for set in ${sets[@]}; do
    echo "${grel}" | orcli transform "${set}" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Zeilen nach id sortieren
grel='[ {
"op": "core/row-reorder",
"mode": "row-based",
"sorting": { "criteria": [ { "valueType": "string", "column": "id" } ] }
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
