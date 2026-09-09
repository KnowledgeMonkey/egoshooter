# Relay District · Kampfgebiet-Erweiterung

## Ziel und Layout
90 × 128 m = 11.520 m². Gegenüber 72 × 100 m sind das genau 60 % zusätzliche Spielfläche; die Kantenlängen wurden nicht jeweils um 60 % vergrößert. Die drei ursprünglichen Lanes und der Spawn-Kern bleiben erhalten. Seitliche Servicewege und zwei zusätzliche Querstraßen erschließen den neuen Randbereich. Die alten Hintergrundgebäude wurden außerhalb der neuen Grenzen versetzt; dekorative Grünflächen am Rand entfallen.

## Inhalt
- Acht begehbare Gebäude mit Obergeschoss, Dach und Innen-/Außentreppen: vier Bestandshäuser, vier zusätzliche Häuser bei X ±32 / Z ±34.
- Zwei Busse bei (-32,-10) und (32,10): beidseitige Türen mit echten Stufen, Mittelgang, Sitze und offene Fenster. Keine unsichtbare Vollkörper-Kollision über den Innenräumen.
- Zwei Lkw bei (-13,-56) und (13,56): hinten offene Laderäume, Stufen und innere Ladung als Deckung.
- Vier zusätzliche Autos, insgesamt vier brennende Wracks, zwölf Barrikaden mit Sandbags, zwei abgestellte Panzer als feste Deckung. Fahrzeuge sind nicht fahrbar; Panzer schießen nicht.
- Einschlag-/Rußspuren, Trümmer, verbretterte Fassadenteile und Checkpoint-Schilder; weniger warme, leicht staubige Atmosphäre. Die Stadt ist weiterhin lesbar und kein flächig zerstörtes Gelände.
- Acht Automaten im Erdgeschoss, `ARMORY / OFFLINE`. Bewusst ohne Auswahlmenü oder Spielwirkung; Gehäuse besitzen Kollision.

## Seilaufzüge
Vier Aufzüge an Dächern der Häuser (-11,-18), (11,18), (-32,34), (32,-34). Am Boden oder Dach innerhalb von 1,6 m **E** drücken; **SPACE** lässt los. Sie funktionieren in beide Richtungen, fahren mit 5,5 m/s und führen über die niedrige Brüstung auf die Dachfläche. Die gesamte Kapselbahn wird vorab und während der Fahrt gegen Kollisionen geprüft. Besetzter Ausstieg verhindert den Start. Waffenaktionen sind während der Fahrt gesperrt, Schaden bleibt möglich. Spawn-Schutz endet beim Einsteigen. Die Bewegung wird vom Host berechnet und per Snapshot übertragen. Bots nutzen weiterhin ihre Treppenrouten, keine Aufzug-KI.

Wrackfeuer verursacht im unmittelbaren Nahbereich 5 HP pro Viertelsekunde und berücksichtigt Sichtlinien sowie Spawnschutz. Die Dauerflammen sind Kartenelemente; sie vergrößern nicht die zeitlich begrenzten Granaten-Brandzonen.

## Dateien / Klassen und Einbau
| System | Vollständiger Code |
|---|---|
| Grenzen, Straßen, Gebäude-Liste | `scripts/arena.gd` / RelayArena |
| Fahrzeuge, Aufzugmodelle, Automaten, Kampfspuren | `scripts/war_district.gd` / WarDistrict |
| Aufzugbewegung | `scripts/rope_lift.gd` / RopeLift; Einbindung in Fighter, Game und HUD |
| Kartenfeuer | `scripts/wreck_fire.gd` / WreckFire, vorhandenes BurnVisual |
| Neue Bot-Etagenrouten | `scripts/bot_routes.gd` / BotRoutes |
| Umgebung und Minimap | UrbanDetails, UrbanLighting, ArenaHUD |

Die Änderungen sind bereits eingebaut. Mit `Start-Local.cmd` starten; vollständigen gleichen Projektstand auf LAN-Clients und Server verwenden. Keine neuen Assets, Engine-Plugins oder manuellen Szenenverknüpfungen nötig.

## Testanleitung und Prüfstand
`tests/Run-Tests.ps1` enthält 47 Kartenprüfungen (`tests/war_district.gd`) und `tests/Run-RopeNetwork.ps1`. Geprüft: Flächenverhältnis, Fahrzeugeintritt mit echter Spielerkapsel, Kopffreiheit, alle vier Aufzüge aufwärts/abwärts, Abbruch, gesperrtes Schießen, Reichweitenschutz, verbundene Lanes und Bot-Routen, Sichtschutz der Spawnmittelpunkte von neuen Dachpositionen. Der Zwei-Prozess-Test sendet die Interaktion über die zuverlässige LAN-Aktionsverbindung und prüft den Dachzustand auf Host und Client.

`tests/war_visual.gd` erzeugt `docs/war-*.png` im Grafikfenster. Manuell zusätzlich Busfenster, Lkw-Ausstieg, Dachwechsel unter Beschuss und die drei Lanes mit mehreren Menschen spielen. Nicht durch Dauerfeuer direkt an Flammen stehen: das Wrackfeuer ist absichtlich gefährlich. Der Waffenautomat reagiert absichtlich nicht.

Grafik ist prozedural, Details bleiben vereinfacht. Physische Mehr-PC-LAN-Tests, ein Langzeitbenchmark und menschliches Balancing der größeren Karte stehen aus. 60 FPS sind nicht bestätigt; im kurzen Compatibility-Grafiklauf gab es auch Werte darunter. Verwendete Testumgebung meldet Zertifikats-/Shadercache-Einschränkungen. Änderungen wurden nicht automatisch committet oder gepusht.

Abschließender Durchlauf: `tests/Run-Tests.ps1` mit Exitcode 0, insgesamt 310 Einzelprüfungen (34 + 22 + 27 + 38 + 53 + 31 + 19 + 39 + 47), Operator-Metriken sowie separate FPS-, Aufzug- und Killcam-Netzwerktests bestanden.
