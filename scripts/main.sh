DIR="${DIR:-example}"
sets=(ak au be bf bi hs ks mm pe se sy th)
# import
for set in ${sets[@]}; do
    orcli import jsonl "${DIR}"/input/${set}.jsonl --rename --projectName "${set}" &
done
wait
# transform
## orcli transform "test" config/main/*.json
# export
for set in ${sets[@]}; do
    orcli export jsonl "${set}" --output "${DIR}/tmp/${set}.jsonl" &
done
wait
