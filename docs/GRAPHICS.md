# Grafiküberarbeitung — Relay District

Stand: 8. September 2026, Godot 4.5 stable, Windows. Ziel ist eine glaubwürdigere moderne Stadt im vorhandenen Petrol-/Sand-/Metallstil, passend zu den zuvor überarbeiteten Waffen. Die drei Lanes, Querrouten, Spawns und Spielregeln bleiben erhalten.

**Nachfolgender Stand:** Die Map wurde anschließend vergrößert und um begehbare Etagen und Dächer ergänzt. Dabei gelang auch ein neuer Grafikstart ohne erhöhte Rechte. Der frühere Hinweis auf die damals blockierte visuelle Nachprüfung weiter unten beschreibt den historischen Stand dieses Berichts. Aktuelle Änderungen, Bilder und Prüfungen: [Größere Karte und Etagen](MAP-EXPANSION.md).

## Eingebaute Änderungen

- Vier begehbare Gebäude mit gegliederten Fassaden, Fensterrahmen, Vordächern, Dachabschlüssen, Regenrohren, Dachtechnik und kleinen Inneneinrichtungen.
- Fahrzeuge mit abgeschrägten Karosserien, geneigten Scheiben, Reifen, Felgen, Kühlergrills, Leuchten und Türdetails. Die vorhandenen einfachen Fahrzeug-Kollisionsformen bleiben die Gameplay-Grundlage.
- Abgeschrägte Betonbarrieren, Bordsteine, Straßenabläufe, Kanaldeckel, Leuchten, Leitungen, Bäume, Hintergrundhäuser und zusammenhängendes Gelände außerhalb der Arena. Hintergrunddetails haben keine zusätzlichen Gameplay-Kollisionen.
- Taktische Spielfiguren mit geformten Armen und Beinen, Helm, Brille, Weste, Taschen und Stiefeln; Teamfarben bleiben erkennbar. Neue zusammenhängende First-Person-Arme und Handschuhe ergänzen die fünf Waffenmodelle.
- Vier lokal gespeicherte 1K-PBR-Materialsets mit Farb-, Normalen- und Rauheitstexturen; zusätzliche leichte Oberflächenstruktur für Putz, Metall und Vegetation. Weltkoordinaten halten die Texturgröße auf unterschiedlich großen Bauteilen konsistent.
- Ein lokaler 2K-HDR-Himmel, warmes Sonnenlicht, Himmelsreflexionen, dezenter atmosphärischer Nebel, Innenraum-Aufhellung, Umgebungsschatten und zurückhaltendes Bloom.
- Granaten mit Gehäuse, Bändern, Hebel und Ring; kurze Explosionsblitze, auslaufender Rauch und kleine Einschlageffekte. Physik, Zünder und Schadensberechnung sind weiterhin die bestehenden Systeme.
- Drei Grafikstufen in SETTINGS und Vollbild mit F11.

Die Geometrie wird direkt in Godot aufgebaut und nach Materialien zusammengefasst. Es sind eigene Modelle, keine gescannten Figuren oder fertigen AAA-Assets. Alle Texturen liegen bei; während des Spiels sind keine Downloads nötig. Quellen und CC0-Lizenzen: [assets/CREDITS.md](../assets/CREDITS.md).

## Dateien, Klassen und vollständiger Code

Alle verlinkten Dateien enthalten den vollständigen eingebauten Code. Es sind keine zusätzlichen Snippets oder manuellen Scene-Verknüpfungen erforderlich.

| Aufgabe | Datei / Klasse |
|---|---|
| PBR-Materialien und Wiederverwendung | [urban_materials.gd](../scripts/urban_materials.gd), `UrbanMaterials` |
| Abgeschrägte Meshes, Profile und Material-Batching | [urban_mesh_batch.gd](../scripts/urban_mesh_batch.gd), `UrbanMeshBatch` |
| Gebäude und Innenräume | [urban_architecture.gd](../scripts/urban_architecture.gd), `UrbanArchitecture` |
| Fahrzeuge | [urban_vehicles.gd](../scripts/urban_vehicles.gd), `UrbanVehicles` |
| Deckungen | [urban_cover.gd](../scripts/urban_cover.gd), `UrbanCover` |
| Stadtumgebung und Gelände | [urban_details.gd](../scripts/urban_details.gd), `UrbanDetails` |
| Himmel und Beleuchtung | [urban_lighting.gd](../scripts/urban_lighting.gd), `UrbanLighting` |
| Grafikstufen | [graphics_settings.gd](../scripts/graphics_settings.gd), `GraphicsSettings` |
| Figuren und Waffenanbindung | [operator_model.gd](../scripts/operator_model.gd), `OperatorModel`; [fighter.gd](../scripts/fighter.gd) |
| First-Person-Hände | [weapon_view.gd](../scripts/weapon_view.gd) |
| Einschläge und Explosionen | [combat_visuals.gd](../scripts/combat_visuals.gd), `CombatVisuals`; [grenade.gd](../scripts/grenade.gd), [combat.gd](../scripts/combat.gd) |
| Einbau in Karte, Spiel und Einstellungen | [arena.gd](../scripts/arena.gd), [game.gd](../scripts/game.gd), [ui.gd](../scripts/ui.gd), [project.godot](../project.godot) |

## Start und Einstellungen

1. Den vollständigen Projektordner behalten, einschließlich `assets`, `scripts` und `tools/godot`.
2. `Start-Game.exe` starten. `Start-Game.cmd` verweist auf denselben Starter. Beim ersten Start werden neue Ressourcen importiert.
3. Unter SETTINGS die Grafikstufe wählen. **Hoch** ist die Voreinstellung. **Performance** senkt die interne 3D-Auflösung auf 85 Prozent, deaktiviert MSAA, SSAO und Glow und reduziert die Schattenreichweite. **Sehr hoch** nutzt 4× MSAA und einen größeren Schattenatlas.
4. PLAY starten oder wie bisher ein LAN-Match hosten. Die Bot-Stufen Rekrut, Soldat, Veteran und Elite stehen weiterhin zur Verfügung.

Die drei Stufen verwenden Forward+. Eine Vulkan-fähige GPU mit passendem Treiber ist dafür vorgesehen. Die Stufe Performance wechselt den Renderer nicht. Einstellungen gelten momentan für die laufende Anwendung.

## Ausgeführte Prüfungen

Der aktuelle Code wurde mit `tests/Run-Tests.ps1` geprüft. Die Testdateien sind ausführbar und gehören zum Projekt:

| Prüfung | Umfang |
|---|---|
| [integration.gd](../tests/integration.gd) | 34 Gameplay-/Physikprüfungen, darunter Lane-Verbindungen, Schüsse, Schaden, Respawn, Bewegung, Treppen, Matchende |
| [redesign.gd](../tests/redesign.gd) | 27 Prüfungen für Bot-Reaktionszeiten, Sichtblockade, fünf Waffenmodelle, unabhängige Animationen und Schwierigkeitsmenü |
| [graphics.gd](../tests/graphics.gd) | 38 Prüfungen für lokale Texturen, HDR, gültige Geometrie, Material-Batching, unveränderte Kollisionsanzahl, Oberflächennormalen, Effekte, Freigabe und Grafikstufen |
| [operator_metrics.gd](../tests/operator_metrics.gd) | Figurenabmessungen, unabhängige Instanzen und Waffenhalterungen; Mesh-/Dreieckzahlen für Figuren und Hände |
| [network_peer.gd](../tests/network_peer.gd) | Separater Host und Client auf Loopback, autoritäre Bewegung und Synchronisierung |
| [Run-EightPlayers.ps1](../tests/Run-EightPlayers.ps1) | Host und sieben separate Clients: alle acht Prozesse bestanden, acht echte Teilnehmer beobachtet |
| `Start-Game.exe --verify` | Import und anschließender Headless-Spielstart bestanden, Exitcode 0 |

Die 99 nummerierten Prüfungen, die Figurenprüfung und beide Netzwerkszenarien haben bestanden. Die Testprotokolle liegen unter `tests/`, die Starter-Protokolle unter `logs/`. Der Zertifikatsspeicher ist in der eingeschränkten Testumgebung nicht zugänglich; Godot meldet dies auch bei erfolgreichen Headless-Läufen. ENet/UDP benötigt hier kein TLS. Beim Import konnte Godot außerdem seine persönlichen Editor-Einstellungen außerhalb des Projektordners nicht speichern; der Projektimport und der nachfolgende Headless-Spielstart gelangen trotzdem ohne Script- oder Ladefehler. Die Starter-Prüfung öffnet kein Grafikfenster.

Der erste grafische Durchlauf dieser Überarbeitung wurde tatsächlich auf einer **NVIDIA GeForce GTX 1080 mit Forward+ bei 1280 × 720** ausgeführt. Die kurzen Stichproben mit aktivem VSync lagen bei **59–60 FPS**. Das ist kein garantierter Mindestwert und kein kontrollierter Vergleich der drei Grafikstufen; Bots, sichtbare Geometrie und Schatten ändern sich zwischen Stichproben.

Anschließend wurden anhand der betrachteten Bilder unter anderem zu fleckiger Fassadenputz, zu starke Bodenstruktur, eine unpassende Hintergrundsilhouette und der Menü-Kamerawinkel korrigiert. Hinzu kamen die neuen Granaten-/Einschlageffekte. Diese letzten Änderungen sind durch die technischen Tests abgedeckt, aber **noch nicht erneut grafisch abgenommen**: Die automatische Freigabeprüfung hat den erneuten Godot-Grafikstart abgewiesen, weil erhöhte Ausführungsrechte in dieser Arbeitssitzung deaktiviert sind. Die vorhandenen `docs/graphics-*.png` und das FPS-Protokoll zeigen deshalb den vorherigen Zwischenstand, nicht alle letzten Korrekturen. Insbesondere die rechte Testkamera wurde danach stabilisiert; ihr altes Bild ist kein brauchbarer Blick auf die rechte Lane.

## Grafik und LAN selbst prüfen

```powershell
./tests/Run-Tests.ps1
./tests/Run-EightPlayers.ps1
./tools/godot/Godot_v4.5-stable_win64_console.exe --path . --log-file ./tests/graphics-visual.log --script tests/graphics_visual.gd
```

Der letzte Befehl öffnet ein Grafikfenster, erzeugt neue Vorschauen und nimmt kurze FPS-Stichproben auf. Für Figurenansichten gibt es zusätzlich `tests/operator_visual.gd`. Headless-Prüfungen ersetzen diese Bildkontrolle nicht.

Manuell alle drei Lanes und vier Gebäude durchlaufen, auf Fenster-/Türöffnungen, Fahrzeugkanten, Figurenerkennung vor hellen und dunklen Flächen sowie den Treppenaufstieg achten. Alle Waffen mit ADS und Nachladen ausprobieren; Granaten und Einschläge aus mehreren Richtungen betrachten. Danach mit zwei physischen LAN-Rechnern verbinden, da Loopback keine WLAN-, Firewall- oder echte Netzwerklatenzprüfung ersetzt.

## Typische Fehler und Grenzen

- **Fehlende Klassen oder pinke/fehlende Materialien nach dem Kopieren:** Den vollständigen Ordner verwenden und über `Start-Game.exe` neu importieren. Diagnose unter `logs/` ansehen.
- **Grafiktreiber-/Vulkanfehler:** Treiber und Vulkan-Unterstützung prüfen. Für die optische Abnahme wird Forward+ verwendet; ein manuell gewählter Compatibility-Renderer stellt nicht alle Effekte gleich dar.
- **Weniger FPS bei hoher Auflösung:** Zunächst Performance wählen; Schatten und 3D-Auflösung kosten vor allem GPU-Zeit. Die dokumentierte Kurzprüfung war bei 720p.
- **Dekoration berührt den Spieler anders als ihr sichtbares Detail:** Die Karte verwendet weiterhin einfache, geprüfte Kollisionsformen; Zierleisten, Außendekoration und kleine Karosseriedetails bekommen keine separaten Collider.
- **Bots nutzen Höhenpositionen wenig:** Die bestehende KI priorisiert Bodenrouten. Diese Grafikänderung ersetzt keine weitere Bot- oder Map-Balancing-Runde.

Das Ergebnis bleibt ein eigener Indie-Prototyp mit einfach animierten Figuren, synthetischem Audio und ausstehender menschlicher 4v4-Abnahme. Der Schwerpunkt dieser Änderung liegt auf sichtbarer Form, Materialwirkung, Licht und konsistentem Stil.
