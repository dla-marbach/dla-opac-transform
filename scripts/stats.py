
import json
import sys
import os
from collections import defaultdict, Counter
import glob
import csv

internformat_path = "docs/internformat.csv"
with open(internformat_path, "r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    rows = list(reader)

def process_file(filename):
    source = os.path.splitext(os.path.basename(filename))[0].upper()
    field_count = defaultdict(int)
    field_distinct = defaultdict(set)
    field_top = defaultdict(Counter)
    total = 0
    with open(filename, "r", encoding="utf-8") as f:
        for line in f:
            total += 1
            obj = json.loads(line)
            for key, value in obj.items():
                field_count[key] += 1
                # Einzelwerte aus Arrays für distinct zählen, aber top zählt Arrays als Ganzes
                if isinstance(value, list):
                    # distinct: Einzelwerte
                    for item in value:
                        v = item if isinstance(item, (str, int, float, bool)) else repr(item)
                        field_distinct[key].add(v)
                    # top: Array als Ganzes
                    arr_repr = repr(value)
                    field_top[key][arr_repr] += 1
                else:
                    v = value if isinstance(value, (str, int, float, bool)) else repr(value)
                    field_distinct[key].add(v)
                    field_top[key][v] += 1
    stats = {}
    for key in field_count:
        count = field_count[key]
        percent = "{} %".format(int(round((count / total) * 100))) if total > 0 else "0 %"
        unique_items = len(field_distinct[key])
        top_value = field_top[key].most_common(1)[0][0]
        top_str = str(top_value)
        top_str = top_str.replace("\n", "\\n")
        if len(top_str) > 500:
            top_str = top_str[:500] + " (...)"
        stats[(source, key)] = {"count": count, "percent": percent, "unique_items": unique_items, "most_frequent_value": top_str}
    return stats

if len(sys.argv) < 2:
    print("Usage: python3 stats.py <inputfile|inputdir>", file=sys.stderr)
    sys.exit(1)

input_path = sys.argv[1]
all_stats = {}
if os.path.isdir(input_path):
    for filename in sorted(glob.glob(os.path.join(input_path, "*.jsonl"))):
        all_stats.update(process_file(filename))
else:
    all_stats.update(process_file(input_path))

for stat_col in ["count", "percent", "unique_items", "most_frequent_value"]:
    if stat_col not in fieldnames:
        fieldnames.append(stat_col)

row_index = {(row["source"], row["field"]): row for row in rows}
for (source, field), stat in all_stats.items():
    if (source, field) in row_index:
        row = row_index[(source, field)]
    else:
        row = {k: "" for k in fieldnames}
        row["source"] = source
        row["field"] = field
        rows.append(row)
        row_index[(source, field)] = row
    row["count"] = stat["count"]
    row["percent"] = stat["percent"]
    row["unique_items"] = stat["unique_items"]
    row["most_frequent_value"] = stat["most_frequent_value"]

with open(internformat_path, "w", encoding="utf-8", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)
