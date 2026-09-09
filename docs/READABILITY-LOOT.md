# Spielerlesbarkeit und Munitionsbeute

Ziel: Teamzugehörigkeit und Oberflächen leichter erkennen, schwächere Frags und eine einfache Munitionsaufnahme.

Vollständiger Code: `scripts/ammo_drops.gd` (AmmoDrops, Spawn/Limit/Ablauf/Aufnahme/Modell), `game.gd` (Host-Update, Weltzustand und Cleanup), `combat.gd` (Drop nach Tod, Fragwerte), `burn_zones.gd` (Brandwerte), `hud.gd` (sichtabhängige Namen), `operator_model.gd` (offenes Gesicht), `urban_materials.gd` (gescannte Fassaden und Normalmaps).

Einbau: Godot 4.5 Projekt importieren und lokal starten; im LAN dieselbe Version verwenden. Keine neuen Downloads nötig. Munitionskisten werden automatisch beim Darüberlaufen aufgenommen. Namen brauchen keine Taste.

Tests: `tests/Run-Tests.ps1` einschließlich `readability.gd` (Tod-Drop, volle Reserve, Primär-/Pistolenaufnahme, Ablauf und Material-/Granatenwerte). `network_peer.gd` prüft einen Beutedrop zwischen getrennten Host-/Clientprozessen. `readability_visual.gd` erzeugt `docs/player-readability.png` für Gesichter, Namen und Fassaden.

Manuell zwei Teams gegenüberstellen; Teamnamen hinter Deckung und Gegnernamen ausschließlich bei Sicht prüfen. Gegner töten, Reserven leeren und über die Kiste laufen. Auf angrenzender Etage oder hinter einer Wand darf kein Pickup passieren. Frags auf mehrere Distanzen prüfen.

Grenzen: prozedurale Gesichter, keine individuellen Portraits. Beute enthält nur Munition, keine Waffen oder Granaten. Kisten liegen am Todesort und verwenden keine aufwendige RigidBody-Physik. Name und Lebensbalken sind HUD-Markierungen, keine Konturen um das gesamte Modell. Physischer LAN- und längerer Balancing-Test stehen aus.
