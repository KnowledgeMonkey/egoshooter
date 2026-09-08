# Entwicklung in sieben überprüfbaren Schritten

Nachfolgende Erweiterung: [EXE-Starter, vier Bot-Stufen und fünf neue Waffenmodelle](REDESIGN.md), inklusive vollständiger Code-Verweise und Prüfung.

Alle Schritte sind im Projekt eingebaut. Die verlinkten `.gd`-Dateien enthalten den vollständigen ausführbaren Code, keine Pseudocode-Fragmente. Gemeinsamer Einstieg: `project.godot` → `scenes/main.tscn` → `scripts/game.gd`. Keine Plugins erforderlich.

## 1. Blockout, Spieler und Kamera

**Ziel:** lesbare eigene Stadt mit drei Routen und direkter Ego-Steuerung.

**Dateien / Klassen / vollständiger Code:** [arena.gd](../scripts/arena.gd) (`RelayArena`), [fighter.gd](../scripts/fighter.gd) (`Fighter`), [main.tscn](../scenes/main.tscn), [project.godot](../project.godot).

**Einbau:** Hauptszene besteht aus einem `Node3D` mit `game.gd`. Dieser erzeugt `RelayArena`; deren `_ready()` baut statische Bodies und das Navigationsraster. `Fighter.setup()` erstellt Capsule, Körpermodell, Kamera und Viewmodel. InputMap wird beim Start eingerichtet. `CharacterBody3D.move_and_slide()` verarbeitet Kollisionen. Ein Sweep um 0,24 m erlaubt Treppenstufen von 0,2 m.

**Map-Koordinaten:** X verläuft links/rechts, Z nord/süd, Y nach oben. Spielfeld X ±30, Z ±43; Spawns bei Z ±39. Lanes bei X ungefähr −22/0/+22. Gebäude bei X ±11, Z ±18. Querrouten bei Z −31/0/+31 und durch die Türen. Seitenplattformen bei X ±23, Z 0, Höhe 2,2 m.

**Tests:** PLAY starten. Jede Lane von Spawn zu Spawn ablaufen, alle zwölf Gebäudedurchgänge nutzen, beide Treppenzugänge jeder Plattform prüfen. Springen, Sprinten, Ducken und Rutschen testen. `tests/integration.gd` prüft sechs Routen, Bewegungsgeschwindigkeit, Sprung und Treppenaufstieg mit der echten Physik.

**Typische Fehler:** Dekoration versperrt eine Treppe → Deckung versetzen und Kollisionstest erneut ausführen. Zu hoher Absatz → maximal 0,2 m pro Treppenstufe. Neue Gebäudeteile fehlen im Bot-Raster → über `RelayArena.box()` erstellen oder `obstacles` ergänzen. Beim Verschieben von Wänden bleibt das Raster sonst veraltet.

## 2. Assault Rifle, Schaden, Tod und Respawn

**Ziel:** funktionierender Kampfkern mit schneller TTK und abgesichertem Wiedereinstieg.

**Dateien / Klassen / vollständiger Code:** [weapons.gd](../scripts/weapons.gd) (`Arsenal`), [combat.gd](../scripts/combat.gd) (`CombatSystem`), [fighter.gd](../scripts/fighter.gd) (`Fighter`), [game.gd](../scripts/game.gd) (`respawn`, `visible_between`).

**Einbau:** `CombatSystem` bekommt die Hauptszene im Konstruktor. Der Host ruft `actions()` aus dem Physik-Tick auf. Ein Ray trifft Layer 1 (Welt) oder 2 (Spieler), ausgeschlossen wird der Schütze. Trefferhöhe relativ zum Spieler bestimmt Kopf/Körper/Beine. Waffenrückstoß wird erst **nach** der Trefferauswertung angezeigt. Bei Tod deaktiviert sich die Capsule, nach drei Sekunden wählt der Host einen neuen Spawn.

**Tests:** Auf Kopf und Beine schießen; Munition mitzählen; durch Wände schießen darf keinen Schaden verursachen. Während Schutzzeit immun, eigenes Feuern beendet den Schutz. Gegner in allen Heimatspawns platzieren → andere Spawnseite wird gewählt. Diese Fälle sind automatisiert geprüft.

**Typische Fehler:** Rückstoß vor dem Ray lässt Schüsse oberhalb des Fadenkreuzes landen. Disabled-Collision während Physics-Flush nur deferred setzen. Treffer auf gleiche Teams müssen in TDM ignoriert werden. Spawnwertung ersetzt nicht menschliche Spawn-Camping-Tests.

## 3. Listen Server, Join und LAN

**Ziel:** Host plus bis zu sieben Clients, keine externen Dienste.

**Dateien / Klassen / vollständiger Code:** [game.gd](../scripts/game.gd) (Sitzung/RPCs), [discovery.gd](../scripts/discovery.gd) (`LanDiscovery`), [ui.gd](../scripts/ui.gd) (`GameUI`), [fighter.gd](../scripts/fighter.gd) (Snapshots).

**Einbau:** Beide Seiten laufen auf derselben Szene mit identischem Nodepfad `/root/Game`. `ENetMultiplayerPeer.create_server()` bzw. `create_client()` setzen den Peer. Beim Verbinden wird Name/Loadout registriert; der Server weist ein Team zu. Clients senden Bewegungs- und Aktionsabsichten, niemals gültige HP/Positionen. Yaw/Pitch werden auf gültige Zahlen geprüft und begrenzt. 20 vollständige, per Deflate komprimierte Snapshots pro Sekunde enthalten auch die aktuelle Teilnehmerliste; dadurch funktioniert später Beitritt ohne separate Szene-Synchronisierung.

**Tests:** `tests/Run-Tests.ps1` nutzt zwei Prozesse; `tests/Run-EightPlayers.ps1` acht. Manipulierte Positions-/HP-Felder werden ignoriert. Danach auf zwei physischen PCs JOIN GAME und DIRECT CONNECT testen, Client schließen, Wiederbeitritt prüfen.

**Typische Fehler:** RPC-Pfade müssen identisch bleiben. Port 27840 bereits belegt → Hostfehler statt stiller Weiterbetrieb. UDP-Broadcast wird vom Router/WLAN isoliert → Direct Connect oder Netzwerk korrigieren. Auf einem PC kann der Discovery-Port bereits gebunden sein. Unterschiedliche Projektversionen können RPC-Inkompatibilitäten verursachen. Godots dynamische Dekomprimierung verlangt Deflate/Gzip, nicht Zstd.

## 4. TDM, FFA, Teams und Matchzeit

**Ziel:** kurze abgeschlossene Matches mit sichtbarer Wertung.

**Dateien / Klassen / vollständiger Code:** [game.gd](../scripts/game.gd) (`check_win`, `finish_match`, `add_player`), [combat.gd](../scripts/combat.gd) (Eliminierungswertung), [hud.gd](../scripts/hud.gd) (`ArenaHUD`).

**Einbau:** Teamverteilung bevorzugt die kleinere Mannschaft. TDM addiert erfolgreiche gegnerische Eliminierungen zum Team. FFA nutzt persönliche Eliminierungen und ignoriert Team-Immunität. Zeit und Sieg werden nur auf dem Host ermittelt. Nach Ende werden Bewegungs-/Kampf-Ticks angehalten. ESC → LEAVE MATCH → PLAY startet eine neue Runde.

**Tests:** Acht Teilnehmer ergeben 4:4; TDM 50 Punkte erzwingen; FFA 25 persönliche Punkte erzwingen; Zeitlimit und Gleichstand manuell prüfen. Scoreboard mit Tab, Matchend-Anzeige und anschließenden Neustart testen.

**Typische Fehler:** Eigene Granatentode geben keine Eliminierung. FFA darf `team` nicht für Schadensfilter verwenden. Pausenmenü ist keine globale Multiplayer-Pause. Verlassen des Hosts beendet die Sitzung.

## 5. Fünf Waffen und Loadout

**Ziel:** kleine Auswahl mit klar unterschiedlichen Rollen.

**Dateien / Klassen / vollständiger Code:** [weapons.gd](../scripts/weapons.gd), [combat.gd](../scripts/combat.gd), [fighter.gd](../scripts/fighter.gd), [ui.gd](../scripts/ui.gd).

**Einbau:** Arsenal-Tabelle hält Schaden, Rate, Magazin, Reserve, Nachladezeit, Streuung, Rückstoß, Reichweite, Pellets und Movement-Faktor. Primärwahl ist 0–3, Pistole Index 4. Q wechselt nur zwischen gewählter Primärwaffe und Pistole. Alle Waffen nutzen dieselbe Trefferlogik; Shotgun führt acht Rays aus. Sniper erhält beim ADS geringste Streuung und engeres Sichtfeld.

**Tests:** Alle fünf Waffen verbrauchen genau eine Patrone pro Schuss; die Kadenz stimmt. Nachladen überträgt nie mehr als vorhandene Reserve. Manuell kurze vs. mittlere Reichweite, Hipfire vs. ADS sowie Wechsel während Nachladen prüfen.

**Typische Fehler:** Nachladen darf keine Munition erzeugen. Waffenwechsel bricht Nachladen ab und setzt kurze Wechselpause. Bei neuer Waffe müssen Startmagazine/Reserven und Loadout-Optionen ebenfalls ergänzt werden; V1 bleibt absichtlich bei fünf.

## 6. Bots, Frag, Audio und HUD

**Ziel:** vollständige lokale Runde auch ohne weitere Menschen.

**Dateien / Klassen / vollständiger Code:** [bots.gd](../scripts/bots.gd) (`BotDirector`), [grenade.gd](../scripts/grenade.gd) (`FragGrenade`), [audio.gd](../scripts/audio.gd) (`ArenaAudio`), [hud.gd](../scripts/hud.gd) (`ArenaHUD`), [discovery.gd](../scripts/discovery.gd).

**Einbau:** Bot-Entscheidungen laufen auf dem Host und schreiben dieselben Eingabefelder wie echte Spieler. Godots `AStarGrid2D` sucht Bodenrouten. Frags sind serverseitige `RigidBody3D`-Objekte, Clients zeigen ihre synchronisierte Position. Der Host prüft beim Explodieren Radius und statische Sichtblocker. Audio wird einmal aus Samples synthetisiert und je Event lokal bzw. räumlich abgespielt. HUD und Minimap sind CanvasLayer-Controls.

**Tests:** PLAY mindestens zwei Minuten beobachten; Bots sollen verschiedene Lanes nutzen und Punkte erzielen. G an eine Wand werfen → Abprallen und Explosion nach 2,6 s. Ziel hinter Wand bleibt unbeschädigt. Automatische Tests prüfen Explosion/Fuse. Für 3D-Audio Kopfhörer nutzen und an einer vorbeilaufenden Figur drehen.

**Typische Fehler:** Clients dürfen die Granatenphysik nicht unabhängig simulieren. Bot-Routen dürfen nicht durch massive Plattformen gehen. Minimap zeigt bewusst keine versteckten Gegner. Persönliche Lebenspunkte/Munition kommen auch beim Client vom Host. Sounds sind Platzhalter, kein fertig gemischtes Audio-Set.

## 7. Lesbarkeit, Darstellung und Performance

**Ziel:** gut prüfbarer Blockout mit eigener visueller Identität und wenig Asset-Aufwand.

**Dateien / Klassen / vollständiger Code:** [arena.gd](../scripts/arena.gd), [fighter.gd](../scripts/fighter.gd), [ui.gd](../scripts/ui.gd), [hud.gd](../scripts/hud.gd), [visual.gd](../tests/visual.gd).

**Einbau:** Teal/Ocker unterscheiden Gebäude und Teams. Eine Sonne und Ambient-Licht beleuchten die kompakte Karte. Materialien werden wiederverwendet; keine großen Texturen, Physikfahrzeuge oder Welt-Streaming-Systeme. HUD/Menü arbeiten auf 1600×900 mit Canvas-Stretch. Die Grafikprüfung speichert tatsächliche Engine-Renderings.

**Tests:** `tests/visual.gd` ausführen; `docs/menu.png`, `host.png`, `gameplay.png` auf Lesbarkeit/Überlappung prüfen. FPS in einer Bot-Runde beobachten. Drei Lanes laufen, Spawn-to-Contact-Zeit notieren; aktuell sind vollständige Nord-Süd-Routen zwischen Z ±30 ungefähr 60–64 m lang. Diese rechnerischen Sprintzeiten sind kein Ersatz für menschliche Gefechtsmessungen.

**Typische Fehler:** Zu hohe Lichtenergie überstrahlt Teamfarben. Deckung darf keine Treppen blockieren. Eine neue starke Höhenposition benötigt mindestens zwei Zugänge/Schwachstellen. Nach bestandenem Gameplay sollten erst schrittweise richtige Waffen-/Figurenmodelle, Obergeschossdetails, passende Animationen und gemischte Sounds eingebaut werden. Keine funktionierende Netzwerk-/Combatlogik dafür neu schreiben.
