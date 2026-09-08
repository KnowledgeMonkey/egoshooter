# Prüfbericht — 8. September 2026

Dieser Bericht beschreibt die erste Blockout-Version. Die spätere Startkorrektur, vier Bot-Stufen, fünf neuen Waffenmodelle und zusätzliche Prüfungen sind im [Redesign-Bericht](REDESIGN.md) dokumentiert. Den anschließenden Umbau der Stadt, Figuren, Materialien und Beleuchtung auf Forward+ sowie dessen aktuellen Prüfstand beschreibt die [Grafiküberarbeitung](GRAPHICS.md).

Geprüft mit Godot **4.5.stable.official.876b29033**, Windows, OpenGL Compatibility. Der folgende Stand beschreibt tatsächlich ausgeführte Prüfungen, keine geplanten Tests.

| Prüfung | Ergebnis | Nachweis |
|---|---|---|
| Parser/Projektimport | bestanden, keine verbleibenden Script-Parserfehler | Engine-Import und ausführbare Tests |
| Gameplay und Physik | **34/34 bestanden** | `tests/integration.log` |
| Host + ein separater Client | bestanden | `tests/network-host.log`, `network-client.log` |
| Host + sieben separate Clients | **alle acht Prozesse bestanden** | `tests/eight-host.log`, `eight-client-1.log` bis `eight-client-7.log` |
| Fremde HP-/Positionsfelder vom Client | ignoriert; Bewegung kommt vom Host | `tests/network_peer.gd` |
| Acht Slots bei späterem Beitritt | Bots werden ersetzt; acht echte Teilnehmer beobachtet | Acht-Prozess-Test |
| Visueller Start, Host-Menü und Spielansicht | ausgeführt und PNGs angesehen | `docs/menu.png`, `host.png`, `gameplay.png` |
| Kurze Grafikmessung | **60 FPS**, NVIDIA GeForce GTX 1080 | `tests/visual.log` |

## Was die 34 Prüfungen abdecken

Hoststart mit sieben Bots; 4:4-Verteilung; Verbindung jeder der drei Lanes und drei Querrouten; tatsächlicher Hitscan-Schaden/Munitionsverbrauch; erhöhter Kopfschaden; Spawn-Schutz; TDM-Freundbeschussfilter; Wandblockade von Schüssen; Tod/Score/Respawntimer; automatischer Respawn; Nachladen mit begrenzter Reserve; fünf Waffen/Kadenzen; FFA-Schaden ohne Team-Immunität; Explosionsschaden; Explosionsdeckung; physikalischer Granatenzünder; tatsächliche Geh-/Sprintbewegung; Rutschen; Sprung; Treppenaufstieg; alternativer Spawn bei besetzter Heimatbasis; TDM- und FFA-Sieg; Sitzungsabbau.

Die Navigation zwischen Z +30 und −30 ergibt je nach Lane etwa **60,0 bis 64,1 m**. Rechnerisch sind dies **6,9 bis 7,4 Sekunden Sprintzeit für die gesamte Teststrecke**, nicht die gemessene Zeit bis zum ersten Gegner. Gegnerkontakt hängt von Spawnwahl und menschlicher Routenwahl ab; das gewünschte Kontaktfenster von 5–15 Sekunden benötigt echte Spieltests.

## Korrigierte Fehler aus den Testläufen

- Namenskollision in einer GDScript-Funktion und dynamisch übergebene typisierte RID-Arrays.
- Zu früh ausgeführter Host-Rückstoß, der den Trefferstrahl bereits vor dem Schuss verschob.
- Eine Deckung blockierte den Zugang zur linken Treppe; die Deckung wurde versetzt und der physikalische Aufstieg bestätigt.
- Unkomprimierte Zustandsupdates überschritten die ENet-MTU. Die finalen Deflate-Updates liefen im Zwei- und Acht-Prozess-Test ohne die vorherige Fragmentierungswarnung.
- Falsches Kompressionsformat für `decompress_dynamic`; final wird das unterstützte Deflate-Format auf beiden Seiten genutzt.

## Grenzen der Aussage

- Die Netzwerktests liefen auf **Loopback desselben PCs**, nicht über zwei physische Rechner, WLAN, Paketverlustsimulation oder unterschiedliche Firewalls. Der LAN-Broadcast-Browser ist implementiert, aber auf mehreren Rechnern noch nicht praktisch abgenommen.
- 60 FPS sind eine kurze Beobachtung dieser GPU bei 1280×720-Fenstergröße, kein belastbarer Mindest-FPS-/Langzeitbenchmark für alle Gaming-PCs. Die Grafikprüfung läuft mit aktiviertem VSync.
- Das Acht-Prozess-Szenario prüft Verbindungen, Teilnehmerlisten, Slots, serverseitige Bewegung und ignorierte Zustandsmanipulation. Es ist kein menschliches 4v4-Match mit vollständig bewerteter Waffenbalance.
- Headless-Läufe in der eingeschränkten Arbeitsumgebung melden `Failed to read the root certificate store`. Die reine ENet/UDP-Verbindung nutzt kein TLS; alle finalen Tests bestanden trotzdem. Der freigegebene grafische Lauf zeigte diese Umgebungsfehlermeldung nicht. Es gab in den finalen Testläufen keine GDScript-Laufzeitfehler.
- Audio-Events und räumliche Wiedergabe sind implementiert. Richtungserkennung und Lautstärke wurden nicht durch einen menschlichen Kopfhörertest abgenommen.
- Grafik und Animationen bleiben bewusst Blockout-/Prototyp-Niveau. Es wurden keine fertigen Produktionsmodelle oder fremden Karten eingebaut.

## Manuelle LAN-Abnahme

1. Projekt auf zwei Rechner kopieren, identische Godot-Version verwenden.
2. Host mit 8 Slots und 7 Bots starten. Auf dem zweiten PC den LAN-Browser öffnen und beitreten.
3. Beide bewegen/schießen/nachladen; gleiche Scores und Todesereignisse prüfen. Beim Beitritt sind insgesamt weiterhin acht Figuren vorhanden.
4. Client beenden und erneut verbinden: Bot-Nachbesetzung und neuer Beitritt prüfen.
5. FFA hosten, Kills und Matchende prüfen. Anschließend über Direct Connect verbinden.
6. Mit weiteren Personen alle drei Routen und beide Höhenpositionen ausprobieren; Spawn-to-Contact-Zeit, Spawn-Kills und starke Positionen protokollieren.
