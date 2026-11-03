# Ablauf bei neuem Feature oder Fix

Die verbindlichen Grundsätze (Branching, Prüfungen, Secrets, Betrieb) stehen in der [DevOps-Vorlage](https://github.com/dla-marbach/devops). Regeln für KI-Agenten stehen in der `AGENTS.md`. Die fachlichen Arbeitsschritte bei Erweiterungen (Schema, Beispieldaten, Transformationsregeln, Dokumentation) stehen im README unter „Vorgehen bei Erweiterungen“.

Die Pipeline läuft nicht als Container. Die Abschnitte „Release“, „Deployment“ und „Rollback“ ersetzen deshalb die der Vorlage, siehe „Projekte ohne Container-Betrieb“ in der DevOps-Vorlage.

## Entwicklung

1. **Ticket:** Redmine-Ticket anlegen oder übernehmen. Darin die geplante Änderung, wesentliche Schritte und den Abschluss dokumentieren.
2. **Branch anlegen:** `git switch main && git pull && git switch -c feature/1234-kurzbeschreibung` (bzw. `fix/…`, mit Ticketnummer). Branches, die KI-Agenten selbst anlegen (z. B. `copilot/…`), behalten ihren Namen; die Ticketnummer steht dann im PR-Titel.
3. **Im Devcontainer entwickeln:** Codespace auf dem Branch oder lokal „Reopen in Container“. Beispieldaten ergänzen, Daten generieren und prüfen wie in der CI: `task default yaml validate solr`. Ergebnisse mit `git diff example/output` prüfen und mitcommitten. Der Sicherheitsscan läuft in der CI.
4. **Pushen und Pull Request nach `main` öffnen:**
   - Titel mit Ticketnummer ohne „#“, z. B. „Neues Feld searchVariant_mv (Ticket 1234)“. `#1234` würde auf GitHub verlinken statt auf Redmine.
   - Beschreibung: Link zum Ticket, was sich ändert und warum, Breaking Changes (z. B. umbenannte oder entfernte Felder) und manuelle Upgrade-Schritte (z. B. Solr-Konfiguration).
5. **Copilot-Review anfordern** (unter „Reviewers“). Hinweise umsetzen oder im PR begründen, warum nicht.
6. **CI abwarten:** Alle Checks müssen grün sein, bei Funden nachbessern. Ist `main` weitergegangen, „Update branch“ und erneut abwarten.
7. **Squash-Merge:** Prüfen, dass die Ticketnummer in der Commit-Nachricht steht. Danach lokal aufräumen: `git switch main && git pull --prune && git branch -D feature/1234-kurzbeschreibung`

## Release

Releases und Tags legen nur Menschen an. Tags werden nie verschoben oder wiederverwendet.

1. **Version festlegen:** Patch (`v1.2.1`) für Fixes, Minor (`v1.3.0`) für neue Felder und Features, Major (`v2.0.0`) für Breaking Changes, z. B. umbenannte oder entfernte Felder, die Katalog oder Datendienst anpassen müssen. Maßgeblich ist die größte Änderung seit dem letzten Release.
2. **Release vorbereiten** per Pull Request wie unter „Entwicklung“: `schemaVersion` in `scripts/main.sh` auf die neue Version (ohne „v“) setzen, Daten mit `task default yaml` neu generieren und `example/output` mitcommitten.
3. **CI prüfen:** Nach dem Merge muss der Lauf auf `main` grün sein.
4. **Release anlegen:** „Releases“ → „Draft a new release“, neuen Tag auf `main`, „Generate release notes“. Neue, geänderte und entfernte Felder sowie manuelle Upgrade-Schritte (z. B. geänderte Solr-Konfiguration) ergänzen.
5. **Veröffentlichen:** „Publish release“. Ein Workflow läuft dabei nicht, das Release ist der Tag.

## Deployment

Auf den Servern läuft immer ein Release-Tag, nie `main`. Zuerst in der Testumgebung, danach mit demselben Tag in der Produktion. Im Verzeichnis des Repos auf dem Server:

1. **Vorbereiten:** Release Notes lesen.
2. **Sichern**, wenn das Release die Solr-Konfiguration ändert: Konfiguration der Cores `indexing` und `internformat` in das Sicherungsverzeichnis kopieren. Der Index selbst muss nicht gesichert werden; nach dem Swap liegt der bisherige Index im Core `indexing` (siehe „Rollback“).
3. **Version wechseln:**

   ```sh
   git fetch --tags
   git switch --detach v1.3.0
   ```

4. **Manuelle Upgrade-Schritte** aus den Release Notes ausführen, z. B. `config/solr/*` in beide Cores kopieren und Solr neu laden.
5. **Ausführen und prüfen:** Daten generieren, in den Core `indexing` laden und per Swap mit `internformat` live schalten (wie im regelmäßigen Lauf). Danach den Katalog bzw. den Datendienst kurz testen.
6. **Produktion:** Läuft das Release in der Testumgebung fehlerfrei, die Schritte 1–5 auf dem Produktionsserver wiederholen. Sonst dort nichts ändern und den Fix als neues Patch-Release ausliefern.

## Rollback

1. **Index zurückschalten:** Solange der nächste regelmäßige Lauf noch nicht gestartet ist, enthält der Core `indexing` den vorherigen Index. Ein erneuter Swap stellt ihn wieder live:

   ```sh
   curl 'http://localhost:8983/solr/admin/cores?action=SWAP&core=indexing&other=internformat'
   ```

2. **Alte Version auschecken:** `git switch --detach v1.2.1`, damit der nächste Lauf wieder mit der vorherigen Version arbeitet.
3. **Solr-Konfiguration zurückspielen**, falls das Release sie geändert hat: Sicherung aus dem Deployment in beide Cores kopieren und Solr neu laden. Ist der vorherige Index nicht mehr vorhanden, mit der alten Version neu generieren und indexieren.

## Projektspezifisch

- **Regelmäßiger Lauf:** Auf dem Server erzeugt ein zeitgesteuerter Lauf die Daten aus den aktuellen Exporten und indexiert sie. Er verwendet den ausgecheckten Release-Tag und ändert ihn nicht.
- **Anreicherungsdaten** (GND-Anreicherung, DBIS, EZB) lädt die Pipeline zur Laufzeit aus den `output`-Verzeichnissen der jeweiligen Repos. Das sind erzeugte Daten, kein Code; deshalb kann sich `example/output` auch ohne Änderung in diesem Repo ändern.
- **Statistik:** Die Spalten zur Statistik in `docs/internformat.csv` werden aus den Produktivdaten erzeugt (`task docs`). Übergangsweise committet der Server sie noch direkt auf `main`. Das wird umgestellt, sodass sie wie andere erzeugte Daten per Pull Request oder in einem eigenen Daten-Repo landen.
