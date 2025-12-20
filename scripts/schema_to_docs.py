import csv
import xml.etree.ElementTree as ET

SCHEMA_PATH = 'config/solr/schema.xml'
CSV_PATH = 'docs/internformat.csv'

def read_schema_types(schema_path):
    tree = ET.parse(schema_path)
    root = tree.getroot()
    name2type = {}
    for field in root.findall('.//field'):
        name = field.get('name')
        typ = field.get('type')
        if name and typ:
            name2type[name] = typ
    return name2type

def update_csv_types(csv_path, name2type):
    with open(csv_path, 'r', encoding='utf-8') as fin:
        reader = csv.reader(fin)
        rows = list(reader)
    if not rows:
        return
    header = rows[0]
    with open(csv_path, 'w', encoding='utf-8', newline='') as fout:
        writer = csv.writer(fout)
        writer.writerow(header)
        for row in rows[1:]:
            if len(row) > 2:
                field_name = row[1]
                if field_name in name2type:
                    row[2] = name2type[field_name]
            writer.writerow(row)

def main():
    name2type = read_schema_types(SCHEMA_PATH)
    update_csv_types(CSV_PATH, name2type)

if __name__ == '__main__':
    main()
