# Automatische Spielupdates unter Windows

`Start-Game.exe` oder `Start-Game.cmd` starten. Der Starter prüft bei jedem Start den neuesten Commit von `KnowledgeMonkey/egoshooter`, Branch `main`. Ein neues GitHub-Release oder eine manuell gepflegte Versionsnummer ist nicht erforderlich. Der erste Start lädt einmal den aktuellen Stand herunter, auch wenn die lokalen Quelldateien bereits diesem Stand entsprechen.

Der Download kommt über HTTPS direkt von GitHub und ist an den zuvor abgefragten Commit gebunden. Neue Versionen werden in einem eigenen Ordner entpackt. Der Starter prüft Archivpfade, importiert die Ressourcen mit Godot und führt einen kurzen Spielstart ohne Fenster aus. Erst wenn diese Prüfungen erfolgreich sind, wird der Versionszeiger atomar umgestellt und das Spiel gestartet. Diese Startprüfung ersetzt keine vollständigen Gameplay-Tests.

Bei fehlendem Internet, GitHub-Limits, einem beschädigten Download oder einem fehlgeschlagenen Import startet die zuletzt installierte Version. Vor der ersten erfolgreichen Installation wird das lokale Projekt verwendet. Details stehen in `logs/updater.log`, `logs/update-import.log` und `logs/update-verify.log`. Ohne funktionsfähige lokale Version kann der Offline-Start nicht gelingen.

## Dateien und Speicherplatz

- `.updates/current.txt`: aktiver GitHub-Commit.
- `.updates/previous.txt`: zuvor aktiver Commit, ab der zweiten Installation.
- `.updates/versions/<commit>/`: vollständige Spielversion einschließlich Importcache.
- `logs/`: Diagnoseprotokolle.

Versionen werden getrennt installiert: Dateien, die auf GitHub gelöscht wurden, sind in der neuen Version nicht mehr enthalten. Alte Versionen bleiben erhalten, damit laufende Spielinstanzen ihre Ressourcen weiter nutzen können. Das benötigt zusätzlichen Speicherplatz. Alte Versionsordner können nach dem Beenden aller Spielinstanzen manuell entfernt werden; den aktiven Ordner aus `current.txt` behalten. Ein fehlender oder ungültiger Versionszeiger führt zum lokalen Projekt zurück.

Lokale Quelldateien, `.git`, Engine, Protokolle und Benutzerdaten werden nicht überschrieben. Zum Entwickeln weiterhin `Open-Editor.cmd` verwenden: Es öffnet das lokale Projekt. Der Spielstarter verwendet nach dem ersten Update die installierte GitHub-Version; nicht veröffentlichte lokale Änderungen sind dort nicht sichtbar.

## Updates veröffentlichen

Spieländerungen im Repository auf `main` hochladen. Beim nächsten Start laden die installierten Starter diesen Commit automatisch. Nicht geprüfte Änderungen daher nicht direkt nach `main` übernehmen.

Der äußere Starter und die portable Godot-4.5-Engine sind die feste Startumgebung. Sie werden durch Spielupdates nicht ausgetauscht. Bei Änderungen am Starter `launcher/Build-Launcher.ps1` ausführen und die neue `Start-Game.exe` mit dem Spielordner verteilen. Eine zukünftige Umstellung auf eine andere Godot-Version benötigt ebenfalls eine aktualisierte Startumgebung. Für eine frische Installation muss weiterhin die portable Engine unter `tools/godot/` enthalten sein, wie in der README beschrieben; sie ist im GitHub-Repository nicht enthalten.

## Diagnose und Tests

- `Start-Game.exe --offline`: GitHub-Prüfung überspringen, installierte Version starten.
- `Start-Game.exe --verify`: Updates prüfen und das Spiel kurz ohne Fenster testen; Fehlercode 1 bei Startfehlern.
- `Start-Game.exe --update-only`: nur Updateversuch durchführen, kein Spiel öffnen. Ein Updatefehler mit verfügbarer Rückfallversion ist kein Startfehler; das Ergebnis steht im Updateprotokoll.
- `tests/Run-UpdaterTests.ps1`: isolierte Tests für Installation, Versionswechsel, Offline-Betrieb, Netzwerkfehler, fehlerhafte Archive, Pfadmanipulation und Erhalt der bisherigen Version.

Die GitHub-Prüfung hat ein Zeitlimit von 10 Sekunden, Downloadverbindungen von 120 Sekunden je Netzwerkoperation und Godot-Prüfprozesse von jeweils 90 Sekunden. Gleichzeitige Updatevorgänge im selben Spielordner werden durch eine Dateisperre verhindert; bei einer Sperrmeldung den zweiten Start nach Abschluss des ersten wiederholen.
