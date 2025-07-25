import csv
import subprocess
import tempfile
import os
import sys

# Verwende lokale XSD-Datei (z.B. mods-3-8.xsd im selben Verzeichnis wie das Script)
MODS_XSD_LOCAL = "mods-3-8.xsd"  # Nur Dateiname, kein Pfad

def validate_mods_xml(xml_content):
    script_dir = os.path.dirname(__file__)
    with tempfile.NamedTemporaryFile("w+", suffix=".xml", delete=False, dir=script_dir) as tmp:
        tmp.write(xml_content)
        tmp.flush()
        tmp_path = os.path.basename(tmp.name)  # Nur Dateiname
    try:
        result = subprocess.Popen(
            ["xmllint", "--noout", "--schema", MODS_XSD_LOCAL, tmp_path],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=script_dir
        )
        out, err = result.communicate()
        if result.returncode == 0:
            return True, ""
        else:
            return False, err.decode("utf-8").strip()
    finally:
        os.remove(os.path.join(script_dir, tmp_path))

def main(csv_path):
    error_count = 0
    with open(csv_path, newline='', mode='r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rec_id = row.get("id")
            mods_xml = row.get("exportMODS", "")
            if not mods_xml.strip():
                print("{}: Kein MODS-XML vorhanden.".format(rec_id))
                continue
            ok, err = validate_mods_xml(mods_xml)
            if err:
                print("{}: FEHLER\n{}\n".format(rec_id, err))
                error_count += 1
                if error_count >= 100:
                    print("Abbruch nach 100 Validierungsfehlern.")
                    sys.exit(1)
    if error_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Nutzung: python validate_mods_csv.py /pfad/zur/oai-mods.csv")
        sys.exit(1)
    main(sys.argv[1])
