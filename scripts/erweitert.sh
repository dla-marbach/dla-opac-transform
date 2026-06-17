# Zusatzfelder für Digitalisierung und Bestandslisten in OpenRefine
DIR="${DIR:-example}"

# Daten in OpenRefine laden
for set in au ak hs ks pe; do
    orcli import csv "${DIR}"/output/${set}.csv --projectName "${set}" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Transformation
orcli transform "au" "${DIR}/tmp/config/erweitert/au-erweitert.json"
orcli transform "hs" "${DIR}/tmp/config/erweitert/hs-erweitert.json"

# Spalten sortieren
orcli sort columns "au" --first id --first display
orcli sort columns "hs" --first id --first display

# Export tektonik
orcli export csv "au" --output "${DIR}/tmp/au-erweitert.csv"
orcli export csv "hs" --output "${DIR}/tmp/hs-erweitert.csv"
