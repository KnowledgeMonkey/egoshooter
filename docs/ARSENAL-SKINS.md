# Arsenal und Skins

## Ziel
Zehn unterschiedlich spielbare Waffen, Mündungsursprung, Frontschild und individuell gestaltbare Waffen ohne Backend. Bestehende Waffenmodelle bleiben die Basis; fünf Varianten erhalten eigene Anbauteile und Handlingprofile.

## Dateien und Klassen
- `scripts/weapons.gd` / Arsenal: Werte, Primärwaffenauswahl und Magazine.
- `scripts/weapon_variants.gd` / WeaponVariants: zusätzliche Modellgeometrie.
- `scripts/weapon_models.gd`, `weapon_geometry.gd`, `weapon_handling.gd`, `weapon_view.gd`: vollständige Modell-, Material- und Animationsimplementierung.
- `scripts/shot_origin.gd`, `combat.gd`, `rifle_projectile.gd`: Mündungsursprung und Treffer.
- `scripts/energy_shield.gd` / EnergyShield: Frontprüfung, Strahlblockade und Shader.
- `scripts/weapon_skins.gd` / WeaponSkins: acht Materialgruppen, Farben, beidseitige Beschriftung, Bereinigung und begrenzte LAN-Daten.
- `scripts/player_settings.gd`: lokale Designs in `user://settings.cfg`.
- `scripts/weapon_showcase.gd`, `ui.gd`: drehbare Vorschau, Skin-Editor und Account-Platzhalter.
- `scripts/fighter.gd`, `game.gd`: aktive Skins, Registrierung und Zustandssynchronisierung.

Der vollständige Code liegt direkt in diesen Projektdateien; zusätzliche Assets oder Pakete sind nicht nötig.

## Einbau und Bedienung
Projekt mit Godot 4.5 importieren oder im Git-Arbeitsordner `Start-Game.cmd` starten. LOADOUT öffnen, Waffe wählen oder WEAPON LAB aufrufen. Bauteil auswählen, Farbe ändern, optional Text eingeben und speichern. Primärwaffe im Loadout separat bestätigen. R lädt nach, B aktiviert das Schild. Ein gespeichertes Design gilt lokal sofort; andere LAN-Spieler erhalten es beim nächsten Beitritt.

## Tests
`tests/Run-Tests.ps1` führt auch `arsenal_shield.gd` und `skins.gd` aus. Diese prüfen Waffenwerte, Einzelschuss, Mündungs-/Wandprüfung, Schildrichtung, Dauer, Respawn und Snapshot sowie Instanzisolation, Textbegrenzung, Farben und Speicher-Roundtrip. Der Zwei-Prozess-Test `network_peer.gd` prüft zusätzlich die Übertragung eines AS12-Designs mit Beschriftung. `arsenal_visual.gd` erzeugt Screenshots von neuen Waffen, Editor, Titel und Schild; mit `--rendering-method gl_compatibility` ausführbar.

Manuell: jede Waffe schießen/nachladen/ADS testen, Schild von vorne und hinten beschießen, Design speichern und Spiel neu starten; mit zweitem LAN-PC die fremde Waffe ansehen. Physische LAN- und längere Performance-Tests stehen aus.

## Typische Fehler / Grenzen
- Vor Waffenwechsel im Editor speichern, sonst geht der Entwurf verloren.
- Schreibgeschützte Benutzerdaten verhindern dauerhafte Speicherung; der Editor meldet dies.
- Der Shop und die Anmeldung sind absichtlich deaktiviert. Es gibt noch keine Kontodaten oder Währung.
- Beschriftung sitzt fest am Gehäuse, wird für lange Texte verkleinert und ist kein frei verschiebbarer Aufkleber.
- Varianten sind eigene prozedurale Modelle auf gemeinsamen Waffenfamilien, keine fotorealistischen Scan-Assets.
- Beide LAN-PCs benötigen dieselbe Projektversion wegen der erweiterten Registrierung.

## Prüfstand 09.09.2026
Gesamte `Run-Tests.ps1`-Suite bestanden, inklusive separater Host-/Clientprozesse (Skins, Schild, Bewegung, Killcam und Seilaufzüge). Arsenal/Schild: 54/54; Skins: 47/47. Grafischer Durchlauf mit Compatibility-Renderer bestanden; Editor, Account-Platzhalter und neue Modelle anhand der erzeugten Bilder geprüft. Godot meldet in der eingeschränkten Testumgebung Zertifikats-/Shadercache-Schreibwarnungen, jedoch keine Skriptfehler im abschließenden Durchlauf.
