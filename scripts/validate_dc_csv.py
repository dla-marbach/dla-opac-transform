import csv
import subprocess
import tempfile
import os
import sys

# Tipp: xmllint benötigt auch das xml.xsd lokal, da es keine externen XSDs per HTTP(S) lädt.
# Lade https://www.w3.org/2001/xml.xsd herunter und speichere sie als xml.xsd im selben Verzeichnis wie oai_dc.xsd.
# Passe die oai_dc.xsd so an, dass das import-Attribut auf "xml.xsd" (lokal) verweist.
OAI_DC_XSD_LOCAL = "oai_dc.xsd"  # Nur Dateiname, kein Pfad

# Hinweis: Damit xmllint alle Imports korrekt auflöst, müssen ALLE XSDs lokal vorliegen und die Imports in den XSDs auf lokale Dateinamen zeigen.
# 1. Lade https://www.openarchives.org/OAI/2.0/oai_dc.xsd, https://dublincore.org/schemas/xmls/simpledc20021212.xsd und https://www.w3.org/2001/xml.xsd in dieses Verzeichnis.
# 2. Passe in oai_dc.xsd die Zeile
#    <xs:import namespace="http://www.openarchives.org/OAI/2.0/oai_dc/" schemaLocation="http://dublincore.org/schemas/xmls/simpledc20021212.xsd"/>
#    zu
#    <xs:import namespace="http://www.openarchives.org/OAI/2.0/oai_dc/" schemaLocation="simpledc20021212.xsd"/>
#    an.
# 3. Passe in simpledc20021212.xsd die Zeile
#    <xs:import namespace="http://www.w3.org/XML/1998/namespace" schemaLocation="http://www.w3.org/2001/03/xml.xsd"/>
#    zu
#    <xs:import namespace="http://www.w3.org/XML/1998/namespace" schemaLocation="xml.xsd"/>
#    an.
# 4. Benutze dann wie gehabt xmllint mit cwd=os.path.dirname(__file__).

def validate_dc_xml(xml_content):
    script_dir = os.path.dirname(__file__)
    with tempfile.NamedTemporaryFile("w+", suffix=".xml", delete=False, dir=script_dir) as tmp:
        tmp.write(xml_content)
        tmp.flush()
        tmp_path = os.path.basename(tmp.name)  # Nur Dateiname
    try:
        # cwd=script_dir, alle Dateien liegen dort, xmllint bekommt nur Dateinamen
        result = subprocess.Popen(
            ["xmllint", "--noout", "--schema", OAI_DC_XSD_LOCAL, tmp_path],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=script_dir
        )
        out, err = result.communicate()
        if result.returncode == 0:
            return True, ""
        else:
            return False, err.decode("utf-8").strip()
    finally:
        # tmp_path ist nur Dateiname, vollständiger Pfad für remove
        os.remove(os.path.join(script_dir, tmp_path))

def main(csv_path):
    error_count = 0
    with open(csv_path, newline='', mode='r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rec_id = row.get("id")
            dc_xml = row.get("exportDC", "")
            if not dc_xml.strip():
                print("{}: Kein oai_dc-XML vorhanden.".format(rec_id))
                continue
            ok, err = validate_dc_xml(dc_xml)
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
        print("Nutzung: python validate_oai_dc_csv.py /pfad/zur/oai-dc.csv")
        sys.exit(1)
    main(sys.argv[1])
