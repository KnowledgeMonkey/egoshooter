# Dedicated Server – Umsetzung und Prüfung

Der Windows-Starter `Start-Server.exe` startet die enthaltene Godot-4.5-Engine mit `--headless` und `--dedicated`. Er prüft zuerst den Ressourcenimport und reicht die Konfiguration an `ServerSettings` weiter. `DedicatedServer` startet den autoritären Host ohne Fighter für Peer 1; `local_id` ist dort 0. ENet erlaubt acht Clientverbindungen. Listen-Hosting aus dem Spiel bleibt mit einem Hostspieler und sieben Clientplätzen erhalten.

`server.json` und CLI-Optionen konfigurieren Netzwerk, Modus, Teilnehmer, Bots und Rundenregeln. Eingabefehler werden mit Meldung und Fehlercode abgewiesen. Ein Windows Job Object bindet die Engine an den Starter; reguläres `stop`/Strg+C schließt die Verbindung über die Serverlaufzeit, ein beendeter Starter hinterlässt keinen Engine-Prozess. Die internen Stopdateien und Protokolle sind pro Prozess getrennt.

Der Server startet nach der konfigurierten Ergebnisphase eine neue Runde. Spieler bleiben verbunden; Punkte, Munition, Gesundheit und Killer-ID werden zurückgesetzt, Granaten und Feuerzonen entfernt. Clients erkennen den Übergang im bestehenden Snapshot und korrigieren ihre Position und Blickrichtung. Das sieben Elemente lange Snapshotformat und die bisherigen RPC-Signaturen bleiben unverändert. Die Serverankündigung im LAN enthält den tatsächlichen Menschenanteil ohne fiktiven Hostspieler.

## Durchgeführte Prüfungen

- 21 Prüfungen für Konfiguration, CLI, fehlende Dateien, eigene Serveridentität, acht Bots, Rundenpause/-wechsel, FFA und Bot-Nachbesetzung.
- `Run-Dedicated.ps1`: die kompilierte EXE mit acht separaten ENet-Clientprozessen; kein Fighter für Peer 1, acht Menschen gleichzeitig, Bewegung und autoritative Snapshots, anschließende Rückkehr zu acht Bots. Auch gegen die aus dem fertigen ZIP entpackte EXE geprüft.
- `Run-DedicatedRounds.ps1`: zwei echte Clients über das Ende einer 60-Sekunden-Runde und den Beginn der Folgerunde hinweg verbunden; beide empfangen Ergebnisphase und Neustart.
- `Run-ServerLauncherTests.ps1`: ungültige Einstellung (Exit 2), belegter UDP-Port (Exit 1), reguläres `stop` und Beenden der Engine bei terminierter Starter-EXE.
- Bestehende Integration, Killcam, Waffen, Grafik, Figurenmodelle, Karte und Zwei-Prozess-Listen-Hosting über `Run-Tests.ps1`.

Die Netzwerkprüfungen laufen auf Loopback unter Windows. Die Einrichtung auf dem tatsächlichen Zielserver, dessen Firewall und eine Verbindung zwischen zwei physischen Rechnern bleiben dort zu prüfen. Betrieb und Paketbau sind in `server/README-SERVER.md` beschrieben.
