# DLA-Einstellungen für Solr 10. Ablage: /server/conf/solr/solr.in.sh, eingebunden am Ende von /etc/default/solr.in.sh:
#   . /server/conf/solr/solr.in.sh
# Die übrigen Einstellungen (SOLR_HOME, SOLR_PID_DIR, SOLR_PORT_LISTEN) setzt install_solr_service.sh dort.

# Verzeichnisse nach DLA-Konvention: Konfiguration in /server/conf/solr, Logs in /server/logs/solr,
# Daten in /server/data/solr (SOLR_HOME, vom Installer gesetzt)
SOLR_LOGS_DIR="/server/logs/solr"
LOG4J_PROPS="/server/conf/solr/log4j2.xml"
# Solr liest Configsets aus SOLR_HOME/configsets (/server/data/solr/data/configsets, Symlink auf
# /server/conf/solr/configsets). Der Java-Sicherheitsmanager von Solr erlaubt Zugriffe nur auf freigegebene
# Verzeichnisse und prüft den aufgelösten Pfad, daher /server/conf/solr ausdrücklich freigeben.
SOLR_OPTS="$SOLR_OPTS -Dsolr.security.allow.paths=/server/conf/solr"

# Java-Heap: so klein wie möglich, damit der Arbeitsspeicher für den Datei-Cache des Betriebssystems frei bleibt
# (Index und docValues werden per mmap gelesen). 12g hat sich im bisherigen Betrieb bewährt; GC-Log beobachten
# (/server/logs/solr/solr_gc.log) und ggf. verkleinern.
SOLR_HEAP="12g"

# Zugriff aus dem Netzwerk (Voreinstellung seit Solr 9: nur 127.0.0.1). Zusätzlich per Firewall auf TYPO3-Server
# und ETL-VM beschränken, solange Solr ohne Authentifizierung läuft.
SOLR_HOST_BIND="0.0.0.0"

# Kein Request-Log von Jetty: bei Instant Search mehrere Anfragen pro Tastendruck. Langsame Anfragen stehen in
# solr_slow_requests.log, Fehler in solr.log.
SOLR_LOGS_REQUESTLOG_ENABLED=false

# Keine Kompression: Antworten (ca. 10-40 KB) gehen im lokalen Netz an TYPO3, Komprimieren kostet mehr Zeit als
# die Übertragung. Gilt ohnehin nur für Clients, die "Accept-Encoding: gzip" senden.
SOLR_GZIP_ENABLED=false

# Größere HTTP-Header (Voreinstellung 8192 Byte): TYPO3 schickt Suchanfragen mit vielen Facetten und Filtern
# als GET. Entfällt, sobald TYPO3 lange Anfragen per POST schickt (Solarium-Plugin PostBigRequest).
SOLR_OPTS="$SOLR_OPTS -Dsolr.jetty.request.header.size=24576"

# Zeitzone für Datumsrundungen wie NOW/DAY (Facetten "Neu im Katalog", "Zeit"); Voreinstellung wäre UTC.
SOLR_TIMEZONE="Europe/Berlin"
