class_name PlayerSettings
extends RefCounted

const PATH := "user://settings.cfg"

static func restore(game: Node3D, path: String = PATH) -> void:
	var settings := ConfigFile.new()
	if settings.load(path) != OK:
		return
	WeaponSkins.designs.clear()
	for index in Arsenal.DATA.size():
		WeaponSkins.set_design(index, WeaponSkins.clean(settings.get_value("skins", str(index), {})))
	game.nickname = str(settings.get_value("player", "name", "Operator")).strip_edges().left(20)
	game.loadout = Arsenal.primary_id(int(settings.get_value("player", "loadout", 0)))
	game.sensitivity = number(settings, "sensitivity", 0.002, 0.0005, 0.005)
	game.base_fov = number(settings, "fov", 88, 70, 110)
	game.graphics_quality = int(number(settings, "graphics", 1, 0, 2))
	game.config.difficulty = int(number(settings, "difficulty", 0, 0, 3))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, number(settings, "volume", 1, 0, 1))))
	game.last_address = str(settings.get_value("player", "address", "127.0.0.1:27840")).left(64)
	if settings.get_value("options", "fullscreen", false) == true:
		game.get_window().mode = Window.MODE_FULLSCREEN

static func number(settings: ConfigFile, key: String, fallback: float, low: float, high: float) -> float:
	var value = settings.get_value("options", key, fallback)
	if not (value is int or value is float) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), low, high)

static func save(game: Node3D, path: String = PATH) -> Error:
	var settings := ConfigFile.new()
	for index in Arsenal.DATA.size():
		settings.set_value("skins", str(index), WeaponSkins.get_design(index))
	settings.set_value("player", "name", game.nickname)
	settings.set_value("player", "loadout", game.loadout)
	settings.set_value("player", "address", game.last_address)
	var values := {"sensitivity": game.sensitivity, "fov": game.base_fov, "graphics": game.graphics_quality,
		"difficulty": game.config.get("difficulty", 0), "volume": db_to_linear(AudioServer.get_bus_volume_db(0)),
		"fullscreen": game.get_window().mode == Window.MODE_FULLSCREEN}
	for key in values:
		settings.set_value("options", key, values[key])
	return settings.save(path)
