# 4K-Oberflächen

Sechs originale Poly-Haven-Scans ersetzen bzw. ergänzen die bisherigen 1K-Oberflächen: Asphalt, Beton, Fassadenputz, Pflaster, Holz und Innenraumboden. Jede Oberfläche enthält 4096 × 4096 Pixel für Farbe, OpenGL-Normalen und Rauheit. Es sind keine hochskalierten 1K-Dateien.

Fassaden verwenden eigenen Putz statt Beton. Holz besitzt jetzt Farb- und Rauheitsmaps sowie echte Holz-Normalen. Innenraumböden und Treppen verwenden eine eigene Bodenoberfläche. Die Weltprojektion skaliert Texturen entsprechend den Scan-Abmessungen (1,5 bis 3,1 Meter je Wiederholung). Dezente Normalstärken erhalten Details ohne übertrieben grobe Oberflächen.

Alle Material-JPEGs werden mit Mipmaps, anisotroper Filterung und VRAM-Kompression importiert. Hochwertige BPTC-Kompression reduziert den Grafikspeicherbedarf. Der vorhandene Bodenbewuchs bleibt in 1K, der HDR-Himmel in 2K. Lack, Metall, Glas, Gummi und prozedurales Laub behalten ihre bisherigen Materialien.

Die Material-JPEGs belegen zusammen etwa 197 MiB. Der erste Import auf einem neuen Rechner kann mehrere Minuten dauern; spätere Starts nutzen den lokalen Import-Cache. Die Quellen liegen vollständig im Projekt, ohne Downloads während des Spiels. CC0-Quellen stehen in [CREDITS](../assets/CREDITS.md), Download-URLs, MD5-Prüfsummen und Scan-Abmessungen in [sources.json](../assets/materials/sources.json).

## Prüfung

`tests/graphics.gd` prüft Auflösung und Mipmaps aller drei Maps pro Oberfläche, eigenständige Putz-/Holztexturen und die vorhandenen Geometrieprüfungen. `tests/material_visual.gd` rendert Straße, Fassade, Pflaster und Innenraum aus festen Kamerapositionen nach `logs/material-after-*.png`. Mit `-- --label=before` lässt sich derselbe Vergleich vor einer Änderung erzeugen.

Ausführen mit der gebündelten Godot-4.5-Konsole: `--headless --path . --script tests/graphics.gd` beziehungsweise für die Bildprüfung `--path . --script tests/material_visual.gd` ohne `--headless`.


Validiert am 09.09.2026 mit Godot 4.5 stable: 81/81 Grafikprüfungen, fehlerfreier Import und vier visuell kontrollierte Kameraperspektiven unter Vulkan / Forward+ auf einer RTX 4060. Alle 18 gelieferten 4K-Quelldateien entsprechen den Download-Prüfsummen. Die Bildläufe sind kein Langzeit-FPS-Benchmark.
