# Klasseneditor und Waffenwerkstatt

Öffne **LOADOUT** im Hauptmenü. Links stehen zehn eigene Klassen. Ein Slot lässt sich benennen, mit einer der fünf Vorlagen (Sturm, Nahkampf, Präzision, Unterstützung, Breacher) füllen oder in den nächsten Slot duplizieren. **Speichern & Ausrüsten** speichert die Klassen und aktiviert die ausgewählte Klasse. Während eines Matches wird sie erst beim nächsten Spawn übernommen, ohne kostenlose Munition beim Bearbeiten zu vergeben.

In der Mitte lässt sich die Waffe mit gedrückter linker Maustaste drehen und mit dem Mausrad zoomen. Primärwaffe und P12-Sekundärwaffe haben jeweils eigene Aufsätze, Farben, Beschriftung und drei Stickerplätze. Die vorhandenen neun Primärwaffen bleiben verfügbar. Granaten, Flashbang und Energieschild bleiben die gemeinsame Standardausrüstung; ein Perk-/Wildcard- oder Freischaltsystem gehört nicht zu diesem Editor.

## Aufsätze

Der rechte Bereich zeigt Auswahl und Auswirkungen. Der Server berechnet die Werte aus erlaubten Aufsatz-IDs, nicht aus übermittelten Schadenswerten.

| Aufsatz | Vorteil | Nachteil |
|---|---|---|
| Reflexvisier | 10 % weniger Streuung | 5 % längere Zielzeit |
| Schalldämpfer | kein Schuss-Radarping | 15 % weniger Reichweite |
| Kompensator | 25 % weniger Rückstoß | 8 % längere Zielzeit |
| Vordergriff | 20 % weniger Streuung | 3 % weniger Lauftempo |
| Erweitertes Magazin | 40 % mehr Kapazität | 20 % längere Nachladezeit |
| Schnellwechselmagazin | 20 % kürzere Nachladezeit | 15 % weniger Kapazität |
| Leichter Schaft | 6 % mehr Lauftempo | 15 % mehr Rückstoß |

Die Veränderungen sind in Vorschau, Egoansicht und Weltmodell sichtbar. Magazine werden auf ganze Patronen gerundet. Der Schalldämpfer unterdrückt den Radarping; die vorhandene Schuss-Audiodatei bleibt erhalten. Das Reflexvisier nutzt weiterhin das vorhandene Zielsystem, ohne separate optische Simulation.

## Farben und Sticker

**Lackierung** bietet acht Bauteilfarben und bis zu 32 Zeichen Beschriftung. **Bildsticker** importiert PNG, JPG und WebP bis 8 MB. Transparente PNGs eignen sich besonders gut. Bilder werden proportional auf maximal 256 Pixel verkleinert und als PNG gespeichert. Drei feste Plätze auf dem Gehäuse werden auf beiden Seiten dargestellt. Die Galerie zeigt bis zu 32 gespeicherte Bilder; weitere Bilder lassen sich erneut importieren. Es gibt keine freie Verschiebung der Sticker.

Stickerdateien werden einmal zuverlässig beim Beitritt bzw. Klassenwechsel verteilt. Die laufenden Zustandsnachrichten enthalten nur Bild-IDs. Empfänger prüfen Format, Abmessungen, Dateigröße und Inhalts-Hash. Auch später beitretende Spieler erhalten die aktiven Sticker. Host und Clients benötigen denselben aktuellen Projektstand.

Klassen liegen in `user://classes.cfg`, aktive Einstellungen in `user://settings.cfg` und Bildkopien in `user://stickers/`. Die Originalbilder können danach verschoben werden. Diese Daten liegen außerhalb des Projekt-Updateordners.

## Validierung

- `tests/classes.gd`: 21 Prüfungen für Speichern/Laden, Statistiken, Import, ungültige Daten, Modellreset, Spawnwechsel und Editorbereiche.
- `tests/classes_network.gd`: zwei echte Godot-Prozesse mit getrennten Stickerverzeichnissen; Beitritt, Bildübertragung, Aufsatzmagazin und Klassenwechsel auf Host und Client geprüft.
- Bestehende Tests: Skins 47/47, Waffenhandling 39/39, Spielintegration 34/34.
- `tests/classes_visual.gd`: drei gerenderte Editoransichten mit beispielhafter Lackierung, Aufsätzen und importiertem Sticker; Godot 4.5, Vulkan/Forward+, RTX 4060.
