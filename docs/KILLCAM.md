# Live-Killcam

Nach einem tödlichen Treffer sieht der lokale Spieler seinen lebenden Killer während des bestehenden Respawn-Fensters (drei Sekunden) aus einer geglätteten Schulterperspektive. Die persistente Kamera hängt direkt am Spiel, unabhängig von den Fighter-Kameras und deren Lebensdauer. Die Death-Plate zeigt weiterhin Name, Waffe und Countdown, ergänzt um `KILLCAM`. Während der Killcam liegt sie weiter unten, damit der Killer sichtbar bleibt.

`CombatSystem.damage()` setzt `killer_id`; der bestehende 20-Hz-Snapshot überträgt dieses eine zusätzliche Feld. Bots mit negativen IDs und menschliche Killer durchlaufen denselben Code. Der Client verwendet die bereits synchronisierte Position und Blickrichtung. Es gibt keine neuen RPCs, keine Änderung der Serverautorität und keinen Rewind-Puffer.

Bei Suizid/Fall, unbekanntem, entferntem oder totem Killer bleibt die Kamera statisch über dem eigenen Todesort. Das KILLCAM-Label erscheint nur bei tatsächlich aktivierter Killer-Verfolgung. Während Pause wird weder Kamera noch Perspektive gewechselt. Der serverseitige Respawn läuft weiter; beim Entpausieren wechselt ein bereits respawnter Spieler zurück zur eigenen Kamera. Matchende stellt das bisherige Kameraverhalten für das Scoreboard wieder her; Verlassen des Matches aktiviert die Menükamera. Im Headless-Modus bleibt die neue Kameralogik inaktiv.

Mausbewegung und Spielaktionen werden während des Todeszustands nicht angenommen. Respawn setzt Killer-ID, Name, Waffe und Countdown zurück. Alte Snapshots ohne `killer_id` führen zur statischen Fallback-Ansicht.

## Prüfen

- `tests/Run-Tests.ps1`: inklusive 22 Killcam-Prüfungen und tatsächlicher Killer-ID-/Respawn-Übertragung zwischen Host und Client auf Loopback.
- `tests/Run-EightPlayers.ps1`: unveränderter Test mit Host und sieben Clientprozessen.
- `tools/godot/Godot_v4.5-stable_win64_console.exe --path . --log-file ./logs/killcam-visual.log --script tests/killcam.gd -- --visual`: zusätzlicher Grafiktest; Vorschau unter `logs/killcam-preview.png`.

Die Tests prüfen Kameraeigentum, Bot- und Spieler-Killer, geglättetes Tracking, Input-Sperre, fehlendes Snapshot-Feld, Tod/Despawn des Killers, Pause, Matchende, Host-/Client-Respawn und Headless-Verhalten. Die Netzwerkprüfung verwendet echte lokale ENet-Prozesse; sie ersetzt keinen Test auf mehreren physischen LAN-Rechnern.

Zum Testen unveröffentlichter Änderungen das lokale Projekt mit `Open-Editor.cmd` öffnen und in Godot F6/F5 starten. `Start-Game.exe` spielt weiterhin die von GitHub installierte Version. Die Killcam steht dort zur Verfügung, sobald die geänderten Spielquellen auf `main` veröffentlicht sind.
