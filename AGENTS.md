# AGENTS.md

Regeln für KI-Agenten in diesem Repository. Zweck, Aufbau und Befehle des Projekts stehen im README.

## Umgebung
- Lokal und in Codespaces läuft die Entwicklung im Devcontainer (`.devcontainer/`).
- Fehlt ein Werkzeug, benenne es im PR; die Ergänzung gehört in `.devcontainer/`.

## Checks vor Abschluss
- Maßgeblich sind die Schritte in `.github/workflows/`. Führe die Pipeline mit den Beispieldaten lokal genauso aus wie die CI (`task default yaml validate solr`). Der Sicherheitsscan läuft nur in der CI; behebe seine Funde.
- Alle Schritte müssen grün sein. Neue Felder und Fixes bekommen passende Beispieldaten in `example/input`, damit die Änderung in `example/output` sichtbar wird.

## Git und Pull Requests
- Jede Änderung gehört zu einem Redmine-Ticket. Arbeite in einem Branch `feature/<ticket>-<kurzbeschreibung>` oder `fix/<ticket>-<kurzbeschreibung>`, nie direkt auf `main`. Vergibt dein Werkzeug den Branch-Namen selbst (z. B. `copilot/…`), behalte ihn und nenne die Ticketnummer im PR-Titel. Fehlt die Ticketnummer, frage danach.
- Halte Änderungen klein und auf eine Aufgabe beschränkt. Gemergt wird per Squash, und zwar nur durch Menschen.
- Nenne die Ticketnummer im PR-Titel ohne „#“ (z. B. „… (Ticket 1234)“), verlinke das Ticket in der Beschreibung und beschreibe, was sich ändert und warum. Breaking Changes und manuelle Upgrade-Schritte (z. B. geänderte Felder im Solr-Schema) werden zusätzlich in die Release Notes übernommen.
- Setze Hinweise aus dem Copilot-Review um oder begründe im PR, warum nicht.

## Abhängigkeiten
- Updates von GitHub Actions und dem Base Image des Devcontainers übernimmt Dependabot. Ändere Versionen nur, wenn die Aufgabe es erfordert.
- Füge neue Abhängigkeiten nur hinzu, wenn die Aufgabe es erfordert, und begründe sie im PR. Versionen von OpenRefine, orcli und Solr stehen fest im `Taskfile.yml`, go-task und yq im `.devcontainer/Dockerfile` und in `.github/workflows/ci.yml`; nie `latest`.
- Base Image in `.devcontainer/Dockerfile` immer mit festem Versionstag, nie `latest`.

## Betrieb
- Die Pipeline läuft nicht als Container, sondern per `task` auf dem Server. Die Abläufe für Release, Deployment und Rollback stehen in der `CONTRIBUTING.md`.
- Änderungen an Feldern gehen immer einher mit Solr-Schema (`config/solr/schema.xml`), Dokumentation (`docs/internformat.csv`) und, falls nötig, der Standard-Feldliste in `config/solr/solrconfig.xml`; siehe „Vorgehen bei Erweiterungen“ im README.
- Versionen folgen SemVer (`vX.Y.Z`), die `schemaVersion` in `scripts/main.sh` entspricht der Version ohne „v“. Tags und Releases legen nur Menschen an.

## No-Gos
- Keine Secrets, Tokens oder Passwörter in Code, Tests, Logs oder Commits.
- Keine personenbezogenen Daten oder Produktivdaten in Code, Tests, Beispieldaten, Logs oder Commits. Ergänzungen in `example/input` sind synthetisch.
- Tests nicht abschwächen oder löschen und Checks oder Scans nicht deaktivieren oder unterdrücken, um die CI grün zu bekommen.
- Keine Einträge in `.trivyignore`. Ausnahmen für Sicherheitsfunde legen nur Menschen an.
- `.github/` und `.devcontainer/` nur auf ausdrückliche Anweisung ändern.

## Projektspezifisch
- Transformationsregeln liegen als YAML in `config/main`, sortiert nach Teil (`a`, `b`, …) und Verzeichnis; die Dateien eines Verzeichnisses laufen je Datenbestand (Suffix `_ak`, `_pe`, …) nacheinander. JSON aus der OpenRefine-History wird vor dem Ablegen in YAML konvertiert.
- `example/output` wird nicht von Hand bearbeitet, sondern mit `task default yaml` erzeugt und mitcommittet.
- Die Spalten `type` und Statistik in `docs/internformat.csv` werden nicht von Hand bearbeitet; sie erzeugt `task docs` aus dem Solr-Schema und den Produktivdaten. Von Hand gepflegt werden nur `source`, `field` und `description`.
