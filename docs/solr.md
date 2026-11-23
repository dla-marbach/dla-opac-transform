# Solr

Einrichtung und Betrieb des Solr-Servers für den Online-Katalog und Indexierung der Daten aus diesem Repository.

| Pfad | Inhalt |
|---|---|
| [config/solr](../config/solr) | `schema.xml` und `solrconfig.xml` (Configset des Katalogs) |
| [config/solr-server/solr.in.sh](../config/solr-server/solr.in.sh) | DLA-Einstellungen, eingebunden in `/etc/default/solr.in.sh` |
| [config/solr-server/log4j2.xml](../config/solr-server/log4j2.xml) | Logging (Solr-Vorlage, ohne Protokollierung einzelner Suchanfragen) |
| [config/solr-server/solr.service.d/user-managed.conf](../config/solr-server/solr.service.d/user-managed.conf) | systemd-Drop-in: Start im Standalone-Modus |
| [config/solr-server/sysctl-solr.conf](../config/solr-server/sysctl-solr.conf) | Kernel-Einstellungen (`/etc/sysctl.d/90-solr.conf`) |
| [scripts/index.sh](../scripts/index.sh) | Indexierung (lokal per `task solr`, auf der ETL-VM per Rundeck oder manuell) |

## Versionen

* Solr 10.1.0 (Standalone, ein Server ohne ZooKeeper)
* Java 21 (Mindestversion für Solr 10)
* SUSE Linux Enterprise Server 15 SP7

## Cores und Konfiguration

Zwei Cores mit gemeinsamem Configset `internformat` (`schema.xml` und `solrconfig.xml` aus `config/solr`):

* `internformat`: live, wird von TYPO3 abgefragt
* `indexing`: wird beim Import neu befüllt und danach per `SWAP` mit `internformat` getauscht

Die Konfiguration wird bei Bedarf auf dem Solr-Server aktualisiert (siehe [Konfiguration
aktualisieren](#konfiguration-aktualisieren)) und wirkt mit der nächsten Indexierung: `scripts/index.sh` lädt
`indexing` neu, prüft, ob die Konfiguration des Servers mit `config/solr` des Checkouts auf der ETL-VM übereinstimmt,
und bricht sonst ab, bevor etwas gelöscht wird. Daten und Konfiguration gehen so immer gemeinsam per `SWAP` live.

Nach jedem Commit wärmt Solr die Caches mit den typischen Katalogabfragen vor (`newSearcher`), beim Start ebenso
(`firstSearcher`). Der Core ist nach dem `SWAP` also bereits warm.

## Verzeichnisse auf dem Server

Nach DLA-Konvention:

| Verzeichnis | Inhalt |
|---|---|
| `/server/service/solr` | Solr-Installation (Symlink auf `/server/service/solr-10.1.0-slim`) |
| `/server/conf/solr` | `solr.in.sh` und `log4j2.xml` aus `config/solr-server`, Configset in `configsets/internformat/conf` aus `config/solr` |
| `/server/data/solr` | Daten: `data/` (`SOLR_HOME` mit `solr.xml` und den Cores `internformat`, `indexing`), PID-Datei |
| `/server/data/solr/data/configsets` | Symlink auf `/server/conf/solr/configsets` |
| `/server/logs/solr` | `solr.log`, `solr_slow_requests.log`, `solr_gc.log` |
| `/server/src/dla-opac-transform` | Checkout dieses Repositorys, Quelle der Konfiguration |
| `/etc/default/solr.in.sh` | vom Installer angelegt, bindet `/server/conf/solr/solr.in.sh` ein |

## Installation auf SLES 15 SP7

Alle Befehle als Benutzer mit `sudo`-Rechten.

### 1. Java 21 und Hilfsprogramme

```sh
sudo zypper install java-21-openjdk-headless lsof curl git
java -version
```

`lsof` braucht das Startskript, um zu prüfen, ob Solr bereits auf dem Port läuft.

### 2. Solr herunterladen und prüfen

```sh
cd ~
SOLR_VERSION=10.1.0
curl -sSfL -o solr-$SOLR_VERSION-slim.tgz "https://www.apache.org/dyn/closer.lua/solr/solr/$SOLR_VERSION/solr-$SOLR_VERSION-slim.tgz?action=download"
curl -sSfL -o solr-$SOLR_VERSION-slim.tgz.sha512 "https://downloads.apache.org/solr/solr/$SOLR_VERSION/solr-$SOLR_VERSION-slim.tgz.sha512"
echo "$(cut -d ' ' -f 1 solr-$SOLR_VERSION-slim.tgz.sha512)  solr-$SOLR_VERSION-slim.tgz" | sha512sum -c -
tar xzf solr-$SOLR_VERSION-slim.tgz solr-$SOLR_VERSION-slim/bin/install_solr_service.sh --strip-components=2
```

Die `slim`-Variante genügt, weil keine Solr-Module (z.B. Extraction, LTR) verwendet werden.

### 3. Installer ausführen

```sh
sudo mkdir -p /server/service /server/data /server/conf /server/logs /server/src
sudo bash ./install_solr_service.sh solr-$SOLR_VERSION-slim.tgz -i /server/service -d /server/data/solr -n
```

Der Installer legt den Benutzer `solr`, `/server/service/solr`, `/server/data/solr`, `/etc/default/solr.in.sh` und
den Dienst `solr.service` an. `-n` verhindert den Start, weil die Konfiguration noch fehlt. Die vom Installer
angelegte `/server/data/solr/log4j2.xml` wird nicht verwendet (siehe `LOG4J_PROPS` in `solr.in.sh`).

### 4. Repository auschecken

```sh
sudo git clone https://github.com/dla-marbach/dla-opac-transform.git /server/src/dla-opac-transform
```

Aus diesem Checkout kommen die Server-Einstellungen und die Konfiguration der Cores.

### 5. Kernel-Einstellungen

```sh
sudo install -m 0644 /server/src/dla-opac-transform/config/solr-server/sysctl-solr.conf /etc/sysctl.d/90-solr.conf
sudo sysctl --system
```

Die Limits für offene Dateien und Prozesse setzt die systemd-Unit von Solr (`LimitNOFILE=65000`,
`LimitNPROC=65000`); Einträge in `/etc/security/limits.conf` wirken auf systemd-Dienste nicht.

### 6. Standalone-Modus

Solr 10 startet ohne Option im SolrCloud-Modus mit eingebettetem ZooKeeper (`bin/solr` setzt den Modus fest, eine
Einstellung in `solr.in.sh` wirkt nicht). Ein systemd-Drop-in startet Solr stattdessen im Standalone-Modus
(`--user-managed`):

```sh
sudo install -D -m 0644 /server/src/dla-opac-transform/config/solr-server/solr.service.d/user-managed.conf /etc/systemd/system/solr.service.d/user-managed.conf
sudo systemctl daemon-reload
```

### 7. DLA-Einstellungen

```sh
sudo install -d /server/conf/solr/configsets/internformat/conf
sudo install -m 0644 /server/src/dla-opac-transform/config/solr-server/solr.in.sh /server/src/dla-opac-transform/config/solr-server/log4j2.xml /server/conf/solr/
sudo install -m 0644 /server/src/dla-opac-transform/config/solr/schema.xml /server/src/dla-opac-transform/config/solr/solrconfig.xml /server/conf/solr/configsets/internformat/conf/
echo '. /server/conf/solr/solr.in.sh' | sudo tee -a /etc/default/solr.in.sh > /dev/null
sudo install -d -o solr -g solr /server/logs/solr
```

Die Einstellungen stehen mit Begründung in [config/solr-server/solr.in.sh](../config/solr-server/solr.in.sh):

| Variable | Wert | |
|---|---|---|
| `SOLR_LOGS_DIR` | `/server/logs/solr` | DLA-Konvention |
| `LOG4J_PROPS` | `/server/conf/solr/log4j2.xml` | Logging-Konfiguration |
| `SOLR_OPTS` | `-Dsolr.security.allow.paths=/server/conf/solr` | Der Java-Sicherheitsmanager von Solr lässt sonst keinen Zugriff auf das Configset außerhalb von `/server/data/solr` zu |
| `SOLR_HEAP` | `12g` | Java-Heap; der Rest des Arbeitsspeichers dient als Datei-Cache für den Index |
| `SOLR_HOST_BIND` | `0.0.0.0` | Zugriff aus dem Netzwerk (ersetzt das veraltete `SOLR_JETTY_HOST`) |
| `SOLR_LOGS_REQUESTLOG_ENABLED` | `false` | kein Jetty-Request-Log (mehrere Anfragen pro Tastendruck) |
| `SOLR_GZIP_ENABLED` | `false` | keine Kompression im lokalen Netz |
| `SOLR_OPTS` | `-Dsolr.jetty.request.header.size=24576` | lange GET-Anfragen von TYPO3; ersetzt die frühere Änderung an `server/etc/jetty.xml`, die bei jedem Update verloren ginge |
| `SOLR_TIMEZONE` | `Europe/Berlin` | Datumsrundung `NOW/DAY` in den Facetten |

Das Logging ([config/solr-server/log4j2.xml](../config/solr-server/log4j2.xml)) entspricht der Vorlage von Solr 10,
protokolliert aber keine einzelnen Suchanfragen. Langsame Anfragen (über 500 ms, `slowQueryThresholdMillis` in der
`solrconfig.xml`) stehen in `/server/logs/solr/solr_slow_requests.log`, Fehler und Warnungen in
`/server/logs/solr/solr.log`.

Spätere Änderungen an `solr.in.sh` oder `log4j2.xml`: Checkout aktualisieren (`sudo git -C /server/src/dla-opac-transform pull`),
Dateien wie oben erneut kopieren und Solr neu starten (`sudo systemctl restart solr`).

### 8. Cores anlegen

```sh
cd /server/data/solr/data
sudo -u solr ln -s /server/conf/solr/configsets configsets
for core in internformat indexing; do
  sudo -u solr mkdir $core
  printf 'name=%s\nconfigSet=internformat\n' $core | sudo -u solr tee $core/core.properties > /dev/null
done
```

### 9. Starten und prüfen

```sh
sudo systemctl enable --now solr
curl -s 'http://localhost:8983/solr/admin/info/system?wt=json' | grep '"mode"'     # erwartet: "mode":"std"
curl -s 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json' | grep -o '"initFailures":{[^}]*}'  # erwartet: leer
```

### 10. Zugriff beschränken

Solr läuft ohne Authentifizierung. Den Port 8983 per Firewall nur für den TYPO3-Server, die ETL-VM und das
Entwicklungsnetz (VPN) öffnen, z.B. mit firewalld:

```sh
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<TYPO3-IP>/32" port port="8983" protocol="tcp" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<ETL-IP>/32" port port="8983" protocol="tcp" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<VPN-Netz>/24" port port="8983" protocol="tcp" accept'
sudo firewall-cmd --reload
```

## Solr aktualisieren

Neue Version wie in Schritt 2 herunterladen und prüfen, dann:

```sh
sudo bash ./install_solr_service.sh solr-$SOLR_VERSION-slim.tgz -i /server/service -d /server/data/solr -f -n
sudo systemctl restart solr
```

`-f` ersetzt den Symlink `/server/service/solr` und die systemd-Unit; `/etc/default/solr.in.sh`, das Drop-in und
die Daten bleiben erhalten. Vorher die Upgrade-Hinweise von Solr lesen und `luceneMatchVersion` in der
`solrconfig.xml` prüfen.

## Konfiguration aktualisieren

Nach Änderungen an `config/solr` (Schema, `solrconfig.xml`) auf dem Solr-Server, manuell oder als eigener Rundeck-Job:

```sh
sudo git -C /server/src/dla-opac-transform pull
sudo install -m 0644 /server/src/dla-opac-transform/config/solr/schema.xml /server/src/dla-opac-transform/config/solr/solrconfig.xml /server/conf/solr/configsets/internformat/conf/
```

Die neue Konfiguration wirkt mit der nächsten Indexierung (`RELOAD` von `indexing`, dann `SWAP`). Der Live-Core
`internformat` lädt sie erst beim Neustart von Solr; bei nur hinzugefügten Feldern oder Handlern ist das unkritisch,
bei umbenannten oder entfernten Feldern sollte die Indexierung direkt nach der Aktualisierung laufen.

Der Checkout auf der ETL-VM und der auf dem Solr-Server sollten auf demselben Stand sein (in der Regel `main`). Weicht
die Konfiguration ab, bricht die Indexierung in Schritt 2 mit einem Hinweis ab und der Katalog bleibt unverändert.

## Indexierung

Auf der ETL-VM, manuell oder als Rundeck-Job (ein Inline-Script):

```sh
export SOLR=http://<solr-host>:8983/solr
export OUTPUT=<dla-opac-transform>/data/output
<dla-opac-transform>/scripts/index.sh
```

[scripts/index.sh](../scripts/index.sh) bricht beim ersten Fehler mit Exit-Code ungleich 0 ab; `internformat` bleibt
dann unverändert. Die Schritte:

1. **`RELOAD`** von `indexing`: lädt die aktuelle Konfiguration des Servers.
2. **Konfiguration vergleichen**: `schema.xml` und `solrconfig.xml` des Servers müssen mit `config/solr` des
   Checkouts auf der ETL-VM übereinstimmen, aus dem auch die Daten stammen. Sonst Abbruch, bevor etwas gelöscht wird.
3. **Leeren**: Nach dem letzten `SWAP` enthält `indexing` den vorherigen Live-Index. `*:*` statt `id:*`: Solr erkennt
   die Abfrage auf alle Dokumente und verwirft die Segmente direkt.
4. **Daten laden**: Datensätze mit ungültigen Werten (z.B. Datumsbereich `2011 TO 2010`) überspringt Solr
   (`TolerantUpdateProcessorFactory`, bis zu 100 Fehler pro Datei) und meldet sie unter `errors`. Mehr Fehler in einer
   Datei führen zum Abbruch.
5. **Commit und Optimize**: `optimize` fasst den Index zu einem Segment zusammen. Für einen Index, der komplett neu
   aufgebaut und bis zum nächsten Import nicht verändert wird, ist das sinnvoll, braucht aber vorübergehend
   zusätzlichen Plattenplatz: auf dem Server mindestens das Dreifache der Indexgröße frei halten (Live-Core, neuer
   Core, Zusammenführung).
6. **Suggester aufbauen** (`buildOnCommit` ist aus). Bei `mySuggester` protokolliert Solr `Store Lookup build failed`;
   das ist ohne Folgen, `AnalyzingInfixLookupFactory` speichert seinen Index selbst.
7. **Vollständigkeit prüfen**: IDs der JSONL-Dateien gegen die IDs in `indexing`. Bis zu `MAX_ABWEICHUNGEN`
   (Standard 100, übersprungene Datensätze aus Schritt 4) wird nur protokolliert, darüber Abbruch vor dem `SWAP`.
8. **`SWAP`**: `internformat` ist danach der neue Index, `indexing` der alte.

Lokal (z.B. im Codespace) indexiert `task solr` die Daten aus `DIR/output` in einen lokalen Solr mit demselben Aufbau.

## Instant Search

Gegenüber der Konfiguration für Solr 9:

* **Wortanfänge**: Feldtyp `texts_prefix` (EdgeNGram 2–20 Zeichen beim Indexieren, Normalisierung wie
  `text_normalized`) und die Felder `searchName_prefix_mv` (aus `searchName_mv`) und `display_prefix_mv` (aus
  `display`, `displayAddition1`, `displayAddition2`). So findet „Hyperio“ bereits „Hyperion“, ohne
  Platzhalter-Abfragen.
* **Request-Handler `/instant`**: Relevanzranking (`qf`, `boost`) fest auf dem Server, Suchtext ohne Feldsyntax
  (`uf=-*`), leere Suche liefert alle Datensätze (`q.alt=*:*`). TYPO3 übergibt nur Suchtext, Filter, Facetten,
  Sortierung und Paging. `/select` bleibt unverändert für den bisherigen Katalog.
* **Vorwärmen nach jedem Commit** (`newSearcher`), nicht nur beim Start.
* **`ClassicIndexSchemaFactory`**: `schema.xml` wird nicht in ein `managed-schema` umgewandelt und nicht per
  Schema-API verändert.
* `luceneMatchVersion` 10.4 (Lucene-Version von Solr 10.1.0).

## Offene Punkte

* Authentifizierung (Basic Auth mit getrennten Benutzern für Lesen und Import): setzt voraus, dass dla-opac-ng
  Zugangsdaten an Solr übergeben kann.
* TYPO3 schickt lange Anfragen per POST (Solarium-Plugin `PostBigRequest`); danach entfällt die Header-Einstellung
  in `solr.in.sh`.
* Wachstum des Index durch die Wortanfang-Felder und Antwortzeiten von `/instant` mit Volldaten messen.
