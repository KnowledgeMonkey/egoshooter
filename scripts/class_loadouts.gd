class_name ClassLoadouts
extends RefCounted

static var entries: Array = []
static var selected := 0
const PATH := "user://classes.cfg"
const PRESETS := ["Sturm", "Nahkampf", "Präzision", "Unterstützung", "Breacher"]

static func template(index: int) -> Dictionary:
	var ids := [0, 1, 3, 6, 2]
	var attachments := [{"optic": 1, "muzzle": 2}, {"stock": 1, "magazine": 2}, {"muzzle": 1}, {"underbarrel": 1, "magazine": 1}, {"stock": 1}]
	return {"name": PRESETS[index], "primary": ids[index], "skins": {str(ids[index]): {"attachments": attachments[index]}}}

static func clean(value: Variant) -> Dictionary:
	if not value is Dictionary: value = {}
	var raw = value.get("primary", 0)
	var primary := Arsenal.primary_id(int(raw)) if raw is int or raw is float else 0
	return {"name": str(value.get("name", "Eigene Klasse")).strip_edges().left(24), "primary": primary, "skins": WeaponSkins.clean_loadout(value.get("skins", {}), primary)}

static func restore(primary: int, path: String = PATH) -> void:
	entries.clear()
	var cfg := ConfigFile.new()
	cfg.load(path)
	var stored = cfg.get_value("classes", "entries", [])
	for i in 10:
		var fallback := {"name": "Eigene Klasse %d" % (i + 1), "primary": primary, "skins": WeaponSkins.loadout_designs(primary)}
		entries.append(clean(stored[i] if stored is Array and i < stored.size() else fallback))
	selected = clampi(int(cfg.get_value("classes", "selected", 0)), 0, 9)

static func save(path: String = PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("classes", "entries", entries)
	cfg.set_value("classes", "selected", selected)
	return cfg.save(path)

static func activate(game: Node3D, index: int) -> void:
	selected = clampi(index, 0, entries.size() - 1)
	var entry := clean(entries[selected])
	game.loadout = entry.primary
	for key in entry.skins: WeaponSkins.set_design(int(key), entry.skins[key])
	game.save_preferences()
	game.queue_local_class()
