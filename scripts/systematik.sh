# Thematischer Sucheinstieg (classification)
DIR="${DIR:-example}"

# se, sy in OpenRefine laden
for set in se sy; do
    orcli import csv "${DIR}"/output/${set}*.csv --projectName "${set}" &
    pids+=($!)
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Vorverarbeitung se
orcli transform "se" "${DIR}/tmp/config/systematik/systematik-00-se-00.json"
orcli transform "se" "${DIR}/tmp/config/systematik/systematik-00-se-01-autoren.json"
orcli transform "se" "${DIR}/tmp/config/systematik/systematik-00-se-02-bibliographie.json"
orcli transform "se" "${DIR}/tmp/config/systematik/systematik-00-se-03-fach.json"
orcli transform "se" "${DIR}/tmp/config/systematik/systematik-00-se-04-provenienz.json"
orcli transform "se" "${DIR}/tmp/config/systematik/systematik-00-se-05.json"

# Mappingtabellen erstellen
for i in autoren bibliographie fach provenienz; do
    orcli export template "se" "${DIR}/tmp/config/systematik/systematik-00-${i}.txt" --separator "" > "${DIR}/tmp/tmp-mapping-${i}.csv" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

for i in autoren bibliographie fach provenienz; do
    orcli import csv "${DIR}/tmp/tmp-mapping-${i}.csv" --projectName "mapping-${i}" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Projekte erstellen aus Init-Dateien
for i in autoren bibliographie fach provenienz; do
    orcli import tsv "${DIR}/tmp/config/systematik/init-systematik-${i}.tsv" --projectName "systematik-${i}" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Systematiken aufbauen
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-01-${i}.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# ak, ks, pe, th in OpenRefine laden
for set in ak ks pe th; do
    orcli import csv "${DIR}"/output/${set}*.csv --projectName "${set}" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Systematiken anreichern
# Spalten erstellen für Anreicherung
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-02.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
# Anreicherung ak
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-02-ak.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
# Anreicherung ks
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-02-ks.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
# Anreicherung pe
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-02-pe.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
# Anreicherung sy
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-02-sy.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
# Anreicherung th
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-02-th.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
# 1. Glied der Kette für Suche anreichern
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-03-${i}.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
# Spalten Sortieren
for i in autoren bibliographie fach provenienz; do
    orcli transform "systematik-${i}" "${DIR}/tmp/config/systematik/systematik-04.json" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done

# Zusammenführung Systematiken
for i in autoren bibliographie fach provenienz; do
    orcli export tsv "systematik-${i}" --output "${DIR}/tmp/tmp-systematik-${i}.tsv" &
done; for i in ${!pids[@]}; do wait ${pids[i]}; unset pids[$i]; done
zip "${DIR}/tmp/tmp-systematik.zip" "${DIR}/tmp/config/systematik/init-systematik.tsv" "${DIR}/tmp/tmp-systematik-autoren.tsv" "${DIR}/tmp/tmp-systematik-bibliographie.tsv" "${DIR}/tmp/tmp-systematik-fach.tsv" "${DIR}/tmp/tmp-systematik-provenienz.tsv"
orcli import tsv "${DIR}/tmp/tmp-systematik.zip" --projectName "systematik"

# Berechnung Anzahl der zu erwartenden Treffer #2572
# Teil 1 Export Hilfstabelle aus ak
orcli export template "ak" "${DIR}/tmp/config/systematik/systematik-05-template.txt" --separator "" --prefix "id,synkey
" > "${DIR}/tmp/tmp-systematik-count.csv"
# Teil 2 Neues Projekt systematik-count
orcli import csv "${DIR}/tmp/tmp-systematik-count.csv" --projectName "systematik-count"
# Teil 3 Berechnung in Projekt systematik
orcli transform "systematik" "${DIR}/tmp/config/systematik/systematik-05.json"

# Export Systematik
orcli export tsv "systematik" --output "${DIR}/tmp/systematik.tsv"