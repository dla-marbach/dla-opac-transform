import csv
import subprocess
import tempfile
import os
import sys

# Verwende lokale XSD-Datei (z.B. mods-3-8.xsd im selben Verzeichnis wie das Script)
MODS_XSD_LOCAL = os.path.join(os.path.dirname(__file__), "mods-3-8.xsd")

def validate_mods_xml(xml_content):
    with tempfile.NamedTemporaryFile("w+", suffix=".xml", delete=False) as tmp:
        tmp.write(xml_content)
        tmp.flush()
        tmp_path = tmp.name
    try:
        result = subprocess.run(
            ["xmllint", "--noout", "--schema", MODS_XSD_LOCAL, tmp_path],
            capture_output=True, text=True, cwd=os.path.dirname(__file__)
        )
        if result.returncode == 0:
            return True, ""
        else:
            return False, result.stderr.strip()
    finally:
        os.remove(tmp_path)

def main(csv_path):
    has_error = False
    with open(csv_path, newline='', encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rec_id = row.get("id")
            mods_xml = row.get("exportMODS", "")
            if not mods_xml.strip():
                print(f"{rec_id}: Kein MODS-XML vorhanden.")
                continue
            ok, err = validate_mods_xml(mods_xml)
            if err:
                print(f"{rec_id}: FEHLER\n{err}\n")
                has_error = True
    if has_error:
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Nutzung: python validate_mods_csv.py /pfad/zur/oai-mods.csv")
        sys.exit(1)
    main(sys.argv[1])
