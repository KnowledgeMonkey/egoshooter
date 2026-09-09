# Killstreaks und Claymore – Version 1

## Ziel und Regeln
Zwei Fortschritte: Serie pro Leben (5 Endlosmunition 60 s, 10 Radar 30 s, 15 Heilung/Schildladung, 20 Nuke) und eine über Tode erhaltene Fähigkeit (4 Kills → eine Claymore). Belohnungen werden automatisch aktiviert, H platziert die Mine. Bots können durch ihre Kills ebenfalls Serienbelohnungen verdienen; die gezielte H-Platzierung ist zunächst eine Spielerfunktion.

Die Nuke startet einen 8-Sekunden-Countdown, läuft auch nach Tod oder Disconnect des Auslösers weiter und beendet die Runde mit dessen Sieg. Alle lebenden Spieler einschließlich Auslöser und Team werden ausgeschaltet. Dafür gibt es keine zusätzlichen Kills/Serienpunkte; die vorhandene Serie wird gelöscht. Nuke-Sieg hat Vorrang vor gewöhnlichem Score-/Zeitlimit. Schutz vor gerichteten Angriffen schützt nicht vor diesem Kartenereignis.

## Dateien / vollständiger Code
- `scripts/killstreaks.gd` / Killstreaks: Belohnungen, Bodenplatzierung, Erkennungskegel, Minenmodell, Explosion, Nuke und Synchronisierung.
- `scripts/fighter.gd` / Fighter: Serie, Ladung, Timer, bestätigte Schussnummer und Snapshots.
- `scripts/combat.gd` / CombatSystem: Belohnung nach Eliminierung, Tod-Reset, endlose Munition und H-Aktion.
- `scripts/game.gd`: Eingabe H, zuverlässige Aktionsübertragung, Weltzustand, Rundencleanup und Nuke-Effekt.
- `scripts/hud.gd` / ArenaHUD: Leiste, Schwellen, Countdown, Restzeiten und UAV.
- `scripts/weapon_view.gd` / WeaponView: visuelles Schussfeedback auch ohne Munitionsverbrauch.

Vollständiger ausführbarer Code liegt in diesen Projektdateien; keine weiteren Pakete oder Assets nötig.

## Einbau
Mit Godot 4.5 importieren oder Start-Game.cmd im aktuellen Git-Projekt verwenden. LAN-Teilnehmer müssen dieselbe Version verwenden. Ein bestehendes Match neu starten, um die erweiterten Zustandsdaten zu verwenden.

## Testanleitung
`tests/Run-Tests.ps1` umfasst `tests/killstreaks.gd` und `tests/Run-StreakNetwork.ps1`. Der erste Test prüft Schwellen, Ablauf, normale Munition nach Ablauf, Reload-Sperre, Claymore, Tod/Respawn, Snapshot und Nuke. Der Zwei-Prozess-Test prüft echte H-Aktion vom Client, Platzierung auf dem Host und Rückübertragung von Mine, Bonus und Nuke-Countdown.

Grafik: Godot mit `--path . --rendering-method gl_compatibility --log-file ./tests/streak-visual.log --script tests/streak_visual.gd` starten. Erzeugt `docs/killstreak-hud.png`, `nuke-countdown.png`, `nuke-wipe.png`.

Manuell: 5 Gegner ohne Tod eliminieren; beide Waffen länger als ein Magazin abfeuern und R drücken. Tod muss Serie/Bonus löschen, H-Fortschritt erhalten. Aufladung vollständig füllen, H vor einer Wand und anschließend auf freiem Boden testen. Gegner von hinten, durch Deckung und von vorne annähern. 20 Kills erreichen, Countdown und gemeinsamen Rundenschluss prüfen. Tests mit zwei physischen LAN-PCs und menschliches Balancing stehen aus.

## Typische Fehler und Grenzen
- H benötigt vier Ladungspunkte und freien Boden in Reichweite; am Seil oder beim Mantling ist Platzierung gesperrt. Ungültige Platzierung erhält die Ladung.
- Ein Kill nach dem eigenen Tod, etwa durch eine liegengebliebene Mine, zählt im Score, lädt aber keine Fähigkeit oder Serie auf.
- UAV zeigt Gegner nur auf der eigenen Minimap; kein Sicht-durch-Wände-Effekt.
- Claymores sind in dieser Version nicht entschärfbar oder beschießbar. Die maximale Anzahl verhindert beliebiges Stapeln.
- Belohnungen sind feste Stufen und noch nicht im Loadout austauschbar.
