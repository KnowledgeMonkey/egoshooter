# TTK und Laufmündung

## Ziel
Längere Feuergefechte bei unverändertem Movement, Rückstoß, Feuertempo und 100 HP. Die zuvor gewünschte One-Shot-M77 bleibt erhalten. Mündungen werden aus dem Modellbau abgeleitet statt in Handlingprofilen geschätzt.

## Dateien / vollständiger Code
- `scripts/weapons.gd` / Arsenal: neue Schadenswerte.
- `scripts/weapon_models.gd` / WeaponModels: Muzzle-Marker an der Lauföffnung, gespeicherte lokale Koordinaten.
- `scripts/weapon_variants.gd`: eigene Laufenden für D58 und LM60.
- `scripts/shot_origin.gd` / ShotOrigin: serverautoritärer Schussursprung und animierter visueller Ursprung.
- `scripts/weapon_view.gd`: ausgerichtetes Mündungsfeuer.
- `scripts/weapon_handling.gd`: entfernt die veralteten, unabhängig gepflegten Mündungsschätzungen.

## Balancing
Benötigte Schüsse gegen 100 HP, naher Oberkörper, alle Schrotkörner treffen, ohne Schutz:

| Waffe | Schaden | Schüsse |
|---|---:|---:|
| AR-4 | 20 | 5 |
| V9 | 15 | 7 |
| SG-8 | 11 × 8 | 2 |
| M77 | 130 | 1 |
| P12 | 21 | 5 |
| D58 | 45 | 3 |
| LM60 | 26 | 4 |
| AK42 | 32 | 4 |
| K16 | 11 | 10 |
| AS12 | 7,5 × 6 | 3 |

Headshots, Gliedmaßentreffer, Distanz und Streuung verändern diese Werte. Granaten, Claymore, Nahkampf und Lebenspunkte wurden nicht verändert.

## Einbau und Tests
Aktuelles Projekt mit Godot 4.5 importieren und starten; beide LAN-PCs müssen denselben Stand verwenden. Keine neuen Assets nötig.

`tests/ttk_muzzle.gd` prüft 60 Fälle: Trefferanzahl, Laufenden aller zehn Modelle, animierte visuelle Mündung, Ausrichtung des Feuerblitzes und serverautoritären Ursprung für Hipfire/ADS. In `tests/Run-Tests.ps1` integriert. Der bestehende Headshot-Test vergleicht jetzt Kopf- und Körperschaden statt eines alten absoluten Grenzwerts.

Manuell: Schüsse bei Hipfire/ADS, Bewegung und Ducken ansehen; besonders AR-4 und Pistole. An Deckung herantreten und prüfen, dass der Lauf nicht durch Wände feuert. Typische Verwechslung: Eine höhere TTK bedeutet mehr benötigte Treffer, keine höhere Feuerrate. Serverseitige Trefferberechnung nutzt eine stabile Waffenhaltung; kosmetisches Wackeln bleibt auf die Darstellung beschränkt.
