# BLOCKLINE – Windows Dedicated Server

## Auf den Server kopieren und starten

1. Das komplette ZIP in einen beschreibbaren Ordner entpacken, zum Beispiel `C:\Games\BLOCKLINE-Server`. Die EXE benötigt die übrigen Dateien im Paket.
2. `server.json` mit einem Texteditor anpassen und speichern.
3. `Start-Server.exe` doppelklicken oder im Terminal ausführen. `Start-Server.cmd` hält Fehlermeldungen beim Doppelklick offen.
4. Auf `SERVER READY` warten. Beim ersten Start werden die Ressourcen importiert. Danach läuft der Server ohne Spielfenster; die Konsole zeigt Beitritte, Status und Rundenwechsel.
5. Im Spiel **MULTIPLAYER → DIRECT CONNECT** öffnen und die IPv4-Adresse des Servers eingeben, beispielsweise `192.168.178.50:27840`. Auf demselben Rechner: `127.0.0.1:27840`. Im selben LAN wird der Server außerdem in JOIN GAME angekündigt, sofern `discovery` aktiv ist und Broadcasts durchkommen.

Die Engine ist enthalten; Git, ein GitHub-Konto und eine separate Godot-Installation sind nicht erforderlich. Zielsystem: Windows x64 mit .NET Framework 4.x (4.8 empfohlen). Der Start erfolgt ohne Grafikoberfläche und ohne GPU-Anforderung. Der Ordner muss für Konfiguration, Importcache und Logs beschreibbar sein.

## Einstellungen

| Schlüssel | Bedeutung | Standard / Bereich |
|---|---|---|
| `server_name` | Anzeigename | BLOCKLINE Dedicated; 1–40 Zeichen |
| `bind` | Lokale Netzwerkschnittstelle | `0.0.0.0` = alle IPv4-Schnittstellen |
| `port` | UDP-Spielport | 27840; 1024–65535, außer 27841 |
| `mode` | Spielmodus | `TDM` oder `FFA` |
| `max_players` | Gesamtzahl der Spielerplätze | 8; 2–8 |
| `bots` | Bots füllen bis zu dieser Gesamtzahl an Teilnehmern auf | 8; 0–max_players |
| `difficulty` | Bot-Schwierigkeit | 1; 0 Rekrut, 1 Soldat, 2 Veteran, 3 Elite |
| `score_limit` | Punktelimit pro Runde | 50; 1–200 |
| `time_limit` | Rundenlänge in Sekunden | 600; 60–1800 |
| `round_delay` | Ergebnisanzeige vor der Folgerunde, Sekunden | 10; 3–120 |
| `discovery` | Server im LAN per Broadcast ankündigen | `true` oder `false` |

Der Server selbst belegt **keinen Spielerplatz**. Bei `bots: 8` und `max_players: 8` starten acht Bots; Menschen ersetzen sie beim Beitritt. Geht ein Mensch, füllt ein Bot den freien Platz wieder. Bei `bots: 0` wartet der Server ohne Bots auf Menschen. Nach Rundenende bleiben die Clients verbunden, Punkte und Spielerzustand werden zurückgesetzt und die nächste Runde auf Relay District beginnt automatisch.

Einstellungen werden beim Start gelesen. Zum Ändern den Server mit `stop` + Enter oder **Strg+C** beenden, JSON bearbeiten und neu starten. Das Beenden schließt die Verbindungen; auch beim Schließen des Konsolenfensters bleibt kein Engine-Prozess absichtlich im Hintergrund zurück.

## Kommandozeile

Optionen überschreiben die JSON-Einstellungen nur für diesen Start. Für Werte mit Leerzeichen das gesamte Argument in Anführungszeichen setzen.

```powershell
.\Start-Server.exe --help
.\Start-Server.exe --port=27840 --mode=FFA --max-players=8 --bots=4 --difficulty=2
.\Start-Server.exe "--name=Freunde LAN" --score-limit=75 --time-limit=900 --round-delay=10
.\Start-Server.exe "--config=C:\Games\Server Settings\server.json"
.\Start-Server.exe --bots=0 --discovery=false --run-for=20
```

`--run-for` beendet einen Testlauf nach der angegebenen Zahl an Sekunden ab Serverbereitschaft. Ohne diese Option läuft der Server weiter. `stop` + Enter oder Strg+C beendet ihn jederzeit. Rückgabecodes: 0 regulär beendet, 1 Start-/Enginefehler, 2 ungültige Serverkonfiguration. Protokolle liegen in `logs/server-*.log`; Importprotokolle in `logs/server-import-*.log`.

## Netzwerk auf dem Windows-Server

Der Server verwendet **UDP**, kein TCP. Der konfigurierte Spielport muss in der Windows-Firewall und gegebenenfalls in der Firewall des Serveranbieters erreichbar sein. Für die automatische LAN-Suche wird zusätzlich UDP 27841 für Broadcasts verwendet; Direct Connect benötigt diese Suche nicht.

Beispiel einer selbst ausführbaren Firewallfreigabe in einer PowerShell **als Administrator** auf dem Zielserver:

```powershell
New-NetFirewallRule -DisplayName "BLOCKLINE Spielserver UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 27840
```

Bei anderem Spielport den Wert anpassen. Das Paket verändert Firewall oder Router nicht selbst. Hinter einem Router muss für Verbindungen von außen derselbe UDP-Port an den Server weitergeleitet werden; bei gemieteten Servern die Anbieter-Firewall berücksichtigen. Öffentliche IP-Adressen funktionieren über Direct Connect. Die automatische Suche bleibt auf das LAN beschränkt.

Für automatischen Start nach Windows-Neustart kann `Start-Server.exe` über die Windows-Aufgabenplanung mit einem passenden Benutzer und dem entpackten Ordner als Arbeitsverzeichnis gestartet werden. Die EXE ist ein Konsolenprogramm, kein Windows-Dienst; sie registriert keine Dienste oder Autostarts.

## Versionen und Updates

Das Serverpaket startet seinen **enthaltenen, festen Spielstand** und aktualisiert sich nicht während des Betriebs. Für ein Serverupdate beenden, ein neu gebautes Paket entpacken, eigene Einstellungen aus `server.json` übernehmen und neu starten. Clients sollten denselben Spielstand verwenden. Der Client-Auto-Updater bezieht seinen Stand weiterhin von GitHub `main`; lokal neue Serverfunktionen werden erst nach Veröffentlichung der Spielquellen auf GitHub an diese Clients verteilt.

## Paket erneut erstellen

Im Projekt `launcher/Build-Server.ps1` kompiliert die Server-EXE. `server/Build-Package.ps1 -OutputDirectory <Zielordner>` erstellt das portable Verzeichnis und ZIP samt Engine. Beide Werkzeuge benötigen die vorhandene Engine unter `tools/godot/`. Godot-Lizenzhinweise sind in `third-party/`, Quellen der Spieltexturen in `assets/CREDITS.md` enthalten.

## Aktuelle Spielmodi

`--mode=TDM`, `--mode=FFA`, `--mode=DOM` (Domination) und `--mode=KC` (Kill Confirmed) werden unterstützt. In `server.json` entsprechend `mode` setzen. Server und Clients müssen denselben Projektstand verwenden. Lokale Clientänderungen mit `Start-Local.cmd` starten.
