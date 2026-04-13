# Bestandsübersicht (collection)
DIR="${DIR:-example}"

# Daten in OpenRefine laden
for set in bf bi ks pe; do
    orcli import csv "${DIR}"/output/${set}*.csv --projectName "${set}" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Auszüge erstellen
orcli export template "bf" "${DIR}/tmp/config/tektonik/00-tektonik-template.txt" --separator "" > "${DIR}/tmp/tmp-tektonik.csv"
orcli import csv "${DIR}/tmp/tmp-tektonik.csv" --projectName "tmp-tektonik"

# Transformation Auszüge
orcli transform "tmp-tektonik" "${DIR}/tmp/config/tektonik/01-tektonik.json"

# Export Auszüge
orcli export tsv "tmp-tektonik" --output "${DIR}/tmp/tmp-tektonik.tsv"

# Aus Exporten Projekt tektonik
zip "${DIR}/tmp/tmp-tektonik.zip" "${DIR}/tmp/config/tektonik/init-tektonik.tsv" "${DIR}/tmp/tmp-tektonik.tsv"
orcli import tsv "${DIR}/tmp/tmp-tektonik.zip" --projectName "tektonik"

# Transformation tektonik
# PE und KS ergänzen
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/02-tektonik.json"
# Kinder in BF und BI ergänzen (aktuell 4 Ebenen, 3 weitere sicherheitshalber)
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/03-tektonik.json"
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/03-tektonik.json"
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/03-tektonik.json"
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/03-tektonik.json"
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/03-tektonik.json"
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/03-tektonik.json"
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/03-tektonik.json"
# Weitere Felder für BF anreichern
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/04-tektonik.json"
# Weitere Felder für BI anreichern
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/05-tektonik.json"
# Spalten Sortieren
orcli transform "tektonik" "${DIR}/tmp/config/tektonik/06-tektonik.json"

# Export tektonik
orcli export tsv "tektonik" --output "${DIR}/tmp/tektonik.tsv"
