# BLOCKLINE — Relay District

Spielbarer Godot-4.5-Prototyp eines kompakten LAN-Ego-Shooters. Eigene Stadtkarte, drei Lanes, kurze Runden und Respawns. Kein Battle Royale, keine kopierten Maps und keine externen Dienste.

## Start unter Windows

1. **`Start-Game.exe` doppelklicken.** Der Windows-Starter prüft bei jedem Start GitHub auf eine neue Spielversion, lädt sie automatisch herunter und prüft den Godot-Import. Die portable Engine liegt unter `tools/godot/`. `Start-Game.cmd` leitet ebenfalls an die EXE weiter.
2. **PLAY** startet ein lokales Team-Deathmatch mit sieben Bots.
3. Unter **LOADOUT** vorher Namen und Primärwaffe wählen.
4. **ESC** öffnet das Menü; das Match läuft dabei weiter.

Bei einem Startfehler zeigt die EXE eine Meldung mit dem Diagnoseordner `logs/`. Bitte die EXE **im Projektordner lassen**. Ein erster Import kann einige Sekunden dauern. Technische Details und aktuelle Waffenbilder: **[Redesign und Startkorrektur](docs/REDESIGN.md)**.

**Grafik-Update:** Relay District besitzt jetzt modellierte Fassaden und Fahrzeuge, taktische Spielfiguren, neue Hände, lokale PBR-Oberflächen und einen HDR-Himmel mit warmer Sonnenbeleuchtung. Die Petrol-/Sand-/Metallfarben bleiben erhalten. Unter **SETTINGS → Grafik** zwischen **Performance, Hoch und Sehr hoch** wählen; **F11** wechselt ins Vollbild. Standard ist Hoch mit dem Forward+-Renderer. Änderungen, Prüfstand und Grenzen: **[Grafiküberarbeitung](docs/GRAPHICS.md)**.

**Map-Erweiterung:** Die Arena misst jetzt **72 × 100 Meter**. Alle vier Hauptgebäude besitzen **Erdgeschoss, begehbares Obergeschoss und ein erreichbares Dach**. Innen- und Außentreppen führen nach oben; die offenen Fenster im Obergeschoss lassen Schüsse durch. Dachbrüstungen, Sichtschutz und Spawn-Unterstände ergänzen die bisherigen Deckungen. Zugänge, Bilder und Tests: **[Größere Karte und Etagen](docs/MAP-EXPANSION.md)**.

**Bot-Schwierigkeit:** Unter HOST GAME zwischen **Rekrut, Soldat, Veteran und Elite** wählen. Standard ist der einsteigerfreundliche Rekrut. Alternativ SETTINGS im Hauptmenü oder als Host während eines Matches öffnen: Änderungen wirken sofort. Die Stufe verändert Reaktion, Wahrnehmungsreichweite, Zielgenauigkeit und Feuerpausen; HP und Waffenschaden bleiben gleich.

**Waffen ansehen:** LOADOUT enthält eine drehbare 3D-Vorschau. Primärwaffe auswählen und mit gedrückter linker Maustaste am Modell ziehen. „P12 SIDEARM ANSEHEN“ zeigt die Pistole, ohne die Primärwaffe zu ändern.

Zum Entwickeln `Open-Editor.cmd` starten oder `project.godot` in Godot **4.5 stable** importieren, danach **F6/F5**. Die Szene `scenes/main.tscn` erstellt Map, Spieler und Oberfläche selbst; keine manuellen Node-Verknüpfungen oder Asset-Downloads erforderlich.

Falls die Engine beim Weitergeben fehlt: [Godot 4.5 für Windows](https://godotengine.org/download/archive/4.5-stable/) herunterladen und beide EXE-Dateien nach `tools/godot/` entpacken. Alternativ mit einer bereits installierten Godot-4.5-Engine `project.godot` öffnen. Ein eigenständiger Release-Export ohne Editor-Binary benötigt die passenden Godot-Exportvorlagen; diese sind nicht enthalten.

Details zu Installation, Offline-Start und Veröffentlichung neuer Spielversionen: **[Auto-Updater](docs/AUTO-UPDATER.md)**.

## LAN spielen

**Separater Windows-Server:** `Start-Server.exe` startet einen Dedicated Server ohne eigenen Spielerplatz. Einstellungen in `server.json` oder per Kommandozeile; bis zu acht Clients, Bot-Auffüllung und automatische Folgerunden. Der Server läuft ohne Spielfenster. Bereitstellung, Netzwerkfreigabe und alle Optionen: **[Windows-Server-Anleitung](server/README-SERVER.md)**. Ein kopierbares Paket inklusive Engine lässt sich mit `server/Build-Package.ps1 -OutputDirectory <Zielordner>` erzeugen.

**Host:** MULTIPLAYER → HOST GAME → Servername, Modus, Slots, Bots, Punktelimit und Zeit auswählen → START GAME. Die Karte ist Relay District. Im Pausenmenü stehen die lokalen Host-IP-Adressen.

**Mitspieler:** denselben Projektstand auf den anderen PC kopieren → starten → MULTIPLAYER → JOIN GAME. Der Host wird per UDP-Broadcast gefunden. Alternativ DIRECT CONNECT → IPv4-Adresse des Hosts, z. B. `192.168.178.25`. Optional ist `IP:Port` möglich.

- Spielverbindung: **UDP 27840**. Serversuche: **UDP 27841**.
- Eine eventuelle Windows-Firewall-Abfrage für Godot im **privaten Netzwerk** zulassen. Das Projekt ändert keine Firewallregeln selbst.
- Alle PCs müssen einander im LAN erreichen können. Gast-WLAN/AP-Isolation kann dies verhindern.
- Auf demselben PC: zweite Instanz starten und `127.0.0.1` verwenden. Nur eine Instanz kann den Discovery-Port belegen; Direct Connect funktioniert trotzdem.
- Echte Spieler ersetzen bei Bedarf Bots. Nach Verbindungsabbruch werden die eingestellten Bot-Plätze wieder aufgefüllt. Maximal acht Teilnehmer inklusive Host.
- Verlassen des Hosts beendet die Sitzung für alle. Kein Host-Migration-System.
- Kein externer Dedicated Server, Account, Cloud-Backend oder Port-Forwarding erforderlich.

## Steuerung

| Eingabe | Funktion |
|---|---|
| WASD / Maus | Bewegen / Umschauen |
| Linke / rechte Maustaste | Schießen / Aim Down Sight |
| Shift | Sprinten |
| Strg | Ducken; beim Sprinten rutschen |
| Leertaste | Springen, niedrige Hindernisse überspringen |
| R | Nachladen |
| Q | Primärwaffe ↔ Pistole |
| G | Frag-Granate werfen, 2 pro Leben |
| Tab | Scoreboard |
| F11 | Vollbild umschalten |
| Esc | Menü / Maus freigeben |

## Enthalten

- 72 × 100 m große eigene Stadtmap mit vier zweigeschossigen, begehbaren Gebäuden und vier erreichbaren Dächern, drei Lanes, fünf Querstraßen, Fahrzeugdeckungen, geschützten Spawn-Unterständen und zwei zusätzlichen Seitenplattformen.
- Modellierte Architektur, Fenster, Dachtechnik, Fahrzeuge, abgerundete Deckungen, Straßen- und Hintergrunddetails; PBR-Texturen, HDR-Himmel, Umgebungsschatten und drei Grafikstufen. Texturen und Himmel liegen lokal bei; Quellen in [assets/CREDITS.md](assets/CREDITS.md).
- Godot-CharacterBody-Bewegung mit Gravitation, Springen, Sprinten, Ducken, Rutschen und kleinen Treppenstufen.
- AR-4, V9-SMG, SG-8-Shotgun, M77-Sniper und P12-Pistole mit unterschiedlicher Kadenz, Schaden, Streuung, Magazingröße, Nachladen, ADS und Rückstoß. Alle fünf nutzen Hitscan.
- 100 HP, Kopf-/Körper-/Beintreffer, Entfernungsabfall, schnelle TTK, Regeneration nach fünf Sekunden ohne Schaden. Kein Friendly Fire in TDM; eigene Granaten können verletzen.
- Drei Sekunden Respawn mit [Live-Killcam aus der Schulterperspektive](docs/KILLCAM.md), Killed-by-Anzeige und Countdown; statische Todesansicht bei fehlendem oder totem Killer. Dynamische Spawnwertung anhand Gegnernähe, Sichtlinien, belegten Positionen und jüngstem Beschuss. 1,8 Sekunden Schutz, der beim Schießen/Werfen endet.
- TDM mit standardmäßig 50 Team-Eliminierungen/10 Minuten; FFA mit im Host-Menü vorgeschlagenen 25 Eliminierungen. Bei Zeitablauf entscheidet der Punktestand; Gleichstände sind möglich.
- Serverautoritäre Bewegung, Schaden, Munition, Schüsse, Teams, Granaten, Respawns und Matchregeln; ENet, 60 Physik-Ticks und 20 komprimierte Zustandsupdates pro Sekunde. Clients interpolieren fremde Spieler und sagen ihre eigene Bewegung einfach voraus.
- Bots mit AStarGrid-Routen, Sichtprüfung, Verfolgung, wechselnden Lanes, Schießen, Nachladen und Respawn.
- Physikalische Frag-Granaten mit Abprallen, Rollen, Zünder, Radius-Schaden und Deckungsprüfung.
- HUD, Minimap für eigene Position/Team, Hitmarker/Headshot-Marker, Killfeed, Scoreboard, Matchzeit und Loadout-Menü.
- Prozedurale 3D-Schuss-, Schritt-, Nachlade-, Treffer-, Todes- und Explosionssounds. Keine fremden Audiodateien.

## Entwicklung und Tests

Die sieben Entwicklungsschritte mit Zielen, Dateien/Klassen, vollständigen Code-Verweisen, Einbau, Tests und typischen Fehlern stehen in **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**.

```powershell
./tests/Run-Tests.ps1
./tests/Run-EightPlayers.ps1
./tests/Run-VerticalLan.ps1
./tests/Run-Dedicated.ps1
./tests/Run-DedicatedRounds.ps1
./tests/Run-ServerLauncherTests.ps1
```

Der erste Befehl prüft Gameplay/Physik, Waffen, Bot-Schwierigkeit, Grafikressourcen, Figurenmodelle, die neuen Etagen und einen Host mit einem separaten Client. Der zweite startet einen Host und sieben echte Clientprozesse auf Loopback. Der dritte prüft den serverautoritären Treppenaufstieg eines Clients. Ergebnisse liegen unter `tests/*.log`. Der ursprüngliche Prüfbericht steht in **[docs/TEST-REPORT.md](docs/TEST-REPORT.md)**; den aktuellen Karten-Prüfstand beschreibt **[docs/MAP-EXPANSION.md](docs/MAP-EXPANSION.md)**.

Grafikprüfung: `tools/godot/Godot_v4.5-stable_win64_console.exe --path . --log-file ./tests/graphics-visual.log --script tests/graphics_visual.gd`. Sie öffnet kurz das Spiel, erzeugt Vorschauen unter `docs/` und beendet sich wieder. Währenddessen das Spielfenster im Vordergrund lassen. Dies ist ein kurzer Funktionstest mit FPS-Stichproben, kein Langzeitbenchmark.

## Bewusster Prototyp-Umfang

Das Spiel ist weiterhin ein **spielbarer Prototyp**, dessen Stadtgrafik und Figuren inzwischen deutlich über den ursprünglichen Blockout hinausgehen. Die fünf Waffen besitzen eigene detaillierte 3D-Modelle mit abgeschrägten Kanten, Metall-/Polymermaterialien, Visierungen, Magazinen und beweglichen Verschlüssen. Architektur, Fahrzeuge und taktische Figuren werden aus eigenen Meshes aufgebaut; Animationen bleiben einfach, Sounds synthetisch. Dekorative Details ergänzen die einfachen Kollisionsformen; Treppen, Etagenböden, Fensteröffnungen und Dachdeckungen haben passende Gameplay-Kollisionen. Menschliches Map-Balancing, Sound-Mixing und längere Netzwerk-/Performance-Tests stehen aus. Die erweiterte Karte wurde auch im Grafikfenster geprüft; aktuelle Bilder liegen unter `docs/expansion-*.png`.

Nicht enthalten sind die optionalen Flashbangs, Rewind-Killcam, Mantling, Projektil-Sniper, Gegner-Radarpings sowie spätere Spielmodi. Der LAN-Browser listet Server ohne Ping-Messung. Es gibt keine Rückrechnung historischer Treffer (Lag Compensation), aufwendige Client-Reconciliation oder Produktions-Anti-Cheat-Lösung. Bei LAN-Paketverlust können einzelne kurze Tastenaktionen verloren gehen. Einstellungen gelten für die laufende Anwendung. Bots benutzen primär Bodenrouten und werfen noch keine Granaten.

## Technikquellen

Godots integriertes [High-level Multiplayer mit ENet](https://docs.godotengine.org/en/4.5/tutorials/networking/high_level_multiplayer.html) bildet die Netzwerkbasis. Die Engine ist [MIT-lizenziert](https://godotengine.org/license/); eigene Mapgeometrie und Sounds werden aus dem Projektcode erzeugt. Die beigefügten Oberflächentexturen und das HDR-Panorama stammen von [Poly Haven unter CC0](assets/CREDITS.md).
