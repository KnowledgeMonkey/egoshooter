# FPS-Erweiterungen

## Ziel
Direkteres Ego-Shooter-Feedback und eine kurze Nahkampfoption für enge Innenräume, ohne zusätzliche Progressionssysteme.

## Dateien und Klassen
- `scripts/combat.gd` / CombatSystem: autoritativer Nahkampf, Schaden und private Treffer-/Eliminierungsereignisse.
- `scripts/fighter.gd` / Fighter: Erholungszeit, Respawn-Reset und Snapshotfeld `melee`.
- `scripts/game.gd`: Taste V, zuverlässige Einzelaktion, nur vom Server akzeptierte Feedback-RPC.
- `scripts/hud.gd` / ArenaHUD: richtungsabhängiger Trefferbogen, Eliminierungsanzeige, Nachladehinweis. Lebens-ID verhindert verspätete Hinweise nach Respawn.
- `scripts/weapon_view.gd` / WeaponView und `scripts/audio.gd` / ArenaAudio: kurzer Waffenschlag und synthetische Sounds.
- Vollständiger Code ist in diesen Dateien eingebaut; keine manuellen Szenenverbindungen erforderlich.

## Verhalten
Nahkampf trifft höchstens einen sichtbaren Gegner im vorderen Kegel innerhalb von 2,1 m. Ein Treffer verursacht 65 Schaden; Teamschutz und Spawn-Unverwundbarkeit bleiben wirksam. 0,65 s Erholung auch bei einem Fehlschlag. Nachladen wird abgebrochen. Während des Hochziehens ist Nahkampf gesperrt; Schießen und andere Waffenaktionen sind während des Schlags gesperrt. Keine Reichweiten-Teleportation und keine zusätzlichen kritischen Nahkampftreffer.

Der Trefferbogen folgt beim Drehen weiterhin der Richtung des letzten Trefferursprungs und verblasst nach 0,9 s. Er verfolgt keinen Gegner. Die Eliminierungsanzeige bleibt zwei Sekunden stehen; KC-Punkte entstehen weiterhin erst durch Marken. Explosionen und Brandflächen melden ihren eigenen Ursprung statt des Werfers.

## Einbau und Test
Mit `Start-Local.cmd` starten. Gleichen neuen Stand auf Host und Clients verwenden, da eine neue RPC und eine neue Einzelaktion hinzugekommen sind. V neben einem Gegner drücken, danach an Wand, hinter dem Gegner und während eines Reloads vergleichen. Zwei Treffer eliminieren einen ungeschützten Gegner. Nach Respawn dürfen keine alten Trefferhinweise stehen bleiben.

Automatisch: `tests/Run-Tests.ps1` enthält 19 zusätzliche Prüfungen in `tests/fps.gd` sowie `tests/Run-FpsNetwork.ps1`. Der separate Zwei-Prozess-Test sendet V über die zuverlässige Aktionsverbindung bei gleichzeitig laufender Eingabeübertragung und prüft serverseitigen Tod, privaten Trefferhinweis, clientseitige Animation und Eliminierungsbestätigung. Die übrigen Gameplay-Tests bleiben erhalten.

## Grenzen und typische Fehler
Prüfstand: 19 neue Einzelprüfungen und der Zwei-Prozess-FPS-Test bestanden; die bisherigen 205 Prüfungen sowie der bestehende Killcam-Netzwerktest ebenfalls. Grafik und Schlagpose wurden mit dem Compatibility-Renderer geprüft (`tests/fps_visual.gd`, Bild `docs/fps-feedback.png`); das Testfenster beendete sich regulär. Shadercache-/Zertifikatshinweise der Testumgebung bleiben bestehen. Menschliches Nahkampf-Balancing und Grafik-/Animationstests auf mehreren PCs stehen aus. Nahkampf ist ein kurzer prozeduraler Waffenschlag, keine komplexe Körperanimation. Alle Teilnehmer benötigen dieselbe Version; normaler Start mit Auto-Updater kann einen älteren veröffentlichten Stand laden. Ein Teamschlag, Spawnschutz, Hindernis oder aktives Hochziehen verhindert den Treffer absichtlich. Änderungen wurden nicht automatisch committet oder gepusht.
