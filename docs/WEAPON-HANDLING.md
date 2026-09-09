# Waffenhandling-Überarbeitung

## Ziel
Fünf unterscheidbare Waffen mit kontrollierbaren Übergängen und abgestimmter Hand-/Waffendarstellung im vorhandenen visuellen Stil.

| Waffe | ADS | Wechsel | Charakter |
|---|---:|---:|---|
| AR-4 | 0,23 s | 0,32 s | kontrollierter Allrounder |
| V9 | 0,16 s | 0,24 s | leicht, schnelle Rückkehr |
| SG-8 | 0,28 s | 0,38 s | kräftiger Impuls, Pumpbewegung |
| M77 | 0,38 s | 0,48 s | schwer, langsamere Rückkehr und Repetieren |
| P12 | 0,13 s | 0,20 s | schnelle Zweitwaffe, offener Verschluss bei leerem Magazin |

## Dateien / Klassen / vollständiger Code
`WeaponHandling` in `scripts/weapon_handling.gd` enthält Profile, Übergangskurven und eine analytisch gedämpfte Rückstoßfeder. `WeaponView` in `scripts/weapon_view.gd` verbindet bestätigte Munitionsänderungen mit Rückstoß, Mündungsfeuer, Handbewegung, Reload-Phasen und Verschluss. `Fighter`, `CombatSystem`, `ArenaHUD`, `ArenaAudio` und `WeaponModels` sind in den entsprechend benannten Dateien erweitert. Alles ist direkt eingebaut; keine Codefragmente einzufügen.

ADS-FOV und Waffenposition verwenden denselben geglätteten Fortschritt. Reload und Nahkampf lösen ADS. Beim Wechsel startet der Übergang neu. Bewegungsträgheit ist im ADS ausgeblendet; M77-Scope erscheint erst am Ende des Übergangs. Die Rotpunkte von AR und SMG sitzen auf der Zielachse. Hände und Modell teilen die gleiche Rückstoßpose.

Die visuelle Feder kehrt zum Ausgangspunkt zurück; der vorhandene spielerisch zu kontrollierende Kamerarückstoß bleibt bestehen. Kein automatisches Zurückziehen der echten Zielrichtung. Nachladen zeigt Herausnehmen, kurze Haltephase, Einsetzen und Rückkehr. Dies bleiben prozedurale Animationen mit vereinfachter Magazin-/Handinteraktion, keine Motion-Capture-Animationen. Die Waffengeometrie wurde erhalten und die Visierung korrigiert.

Host entscheidet über Munition, Treffer und Wechsel-Sperrzeit. Lokale Darstellung folgt bestätigter Munition; unter Netzwerkverzögerung kann Schussfeedback entsprechend später ankommen. Schadenswerte und Magazinmengen bleiben erhalten. Neue Schussklänge sind pro Waffe synthetisiert, keine real aufgenommenen Samples.

## Test / Einbau
`Start-Local.cmd` starten; LOADOUT wählen und Einzelschüsse, Dauerfeuer, ADS, Sprint, Q und R vergleichen. Der normale Updater kann einen anderen veröffentlichten Stand laden. Alle LAN-Teilnehmer auf demselben Projektstand halten.

`tests/handling.gd`: 39 Prüfungen für alle fünf Waffen, ADS-Zeiten, Reloads, Feder-Rückkehr, Mündungsfeuer, Wechsel-Sperre und unterschiedliche Sounds. Federrückkehr bei 30 und 120 FPS verglichen. `tests/handling_visual.gd` prüft alle Waffen im Grafikfenster und erzeugt `docs/handling-*.png`. Der Compatibility-Lauf wurde ohne Skriptfehler abgeschlossen; Shadercache-Hinweise gehören zur eingeschränkten Testumgebung. Laufzeiten im Bild sind kein FPS-Benchmark. Menschliches Feintuning des subjektiven Waffengefühls bleibt sinnvoll.
