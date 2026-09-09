class_name WeaponStickers
extends RefCounted

static var directory := "user://stickers/"
static var cache := {}
static var error := ""

static func valid(id: String) -> bool:
	if id.length() != 64: return false
	for c in id:
		if not c in "0123456789abcdef": return false
	return true

static func import_file(path: String) -> String:
	error = ""
	if not path.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
		error = "Bitte PNG, JPG oder WebP auswählen."; return ""
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null: error = "Datei konnte nicht geöffnet werden."; return ""
	if source.get_length() > 8 * 1024 * 1024:
		error = "Das Bild darf höchstens 8 MB groß sein."; return ""
	var img := Image.load_from_file(path)
	if img == null or img.is_empty(): error = "Bild konnte nicht gelesen werden."; return ""
	img.convert(Image.FORMAT_RGBA8)
	var factor := minf(1, 256.0 / maxf(img.get_width(), img.get_height()))
	img.resize(maxi(1, int(img.get_width() * factor)), maxi(1, int(img.get_height() * factor)), Image.INTERPOLATE_LANCZOS)
	var bytes := img.save_png_to_buffer()
	var id := bytes.hex_encode().sha256_text()
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(directory + id + ".png", FileAccess.WRITE)
	if file == null: error = "Sticker konnte nicht gespeichert werden."; return ""
	file.store_buffer(bytes)
	return id

static func texture(id: String) -> Texture2D:
	if not valid(id): return null
	if not cache.has(id):
		if not FileAccess.file_exists(directory + id + ".png"): return null
		var img := Image.load_from_file(directory + id + ".png")
		if img == null: return null
		img.generate_mipmaps()
		cache[id] = ImageTexture.create_from_image(img)
	return cache[id]

static func clean(value: Variant) -> Array:
	var result := []
	if value is Array:
		for i in mini(value.size(), 3):
			var id := str(value[i])
			result.append(id if valid(id) else "")
	while result.size() < 3: result.append("")
	return result

static func apply(model: Node3D, value: Variant) -> void:
	var old := model.get_node_or_null("Stickers")
	if old == null: old = model.get_node_or_null("Bolt/Stickers")
	if old: old.get_parent().remove_child(old); old.queue_free()
	var group := Node3D.new()
	group.name = "Stickers"
	var index := int(model.get_meta("weapon_index", 0))
	var pistol := index == 4
	if pistol: model.get_node("Bolt").add_child(group)
	else: model.add_child(group)
	var ids := clean(value)
	for i in 3:
		var tex := texture(ids[i])
		if tex == null: continue
		for side in [-1, 1]:
			var sticker := MeshInstance3D.new()
			var mesh := QuadMesh.new()
			var width := 0.028 if pistol else 0.043
			mesh.size = Vector2(width, width * tex.get_height() / tex.get_width())
			sticker.mesh = mesh
			var surface_x := 0.0192 if pistol else (0.0465 if index == 7 else 0.0358)
			sticker.position = Vector3(side * surface_x, 0.036 if pistol else 0.0, 0.015 - i * (0.065 if pistol else 0.075))
			sticker.rotation.y = side * PI / 2
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 0.75
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			sticker.material_override = mat
			group.add_child(sticker)

static func bundle(designs: Dictionary) -> Dictionary:
	var result := {}
	for design in designs.values():
		for id in clean(design.get("stickers", [])):
			if valid(id) and FileAccess.file_exists(directory + id + ".png"):
				result[id] = FileAccess.get_file_as_bytes(directory + id + ".png")
	return result

static func accept(payload: Dictionary) -> Dictionary:
	var accepted := {}
	if payload.size() > 6: return accepted
	for key in payload:
		var id := str(key)
		var bytes = payload[key]
		if not valid(id) or not bytes is PackedByteArray or bytes.size() < 24 or bytes.size() > 270000: continue
		if bytes.slice(0, 8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]): continue
		var width: int = (int(bytes[16]) << 24) | (int(bytes[17]) << 16) | (int(bytes[18]) << 8) | bytes[19]
		var height: int = (int(bytes[20]) << 24) | (int(bytes[21]) << 16) | (int(bytes[22]) << 8) | bytes[23]
		if width < 1 or height < 1 or width > 256 or height > 256: continue
		if bytes.hex_encode().sha256_text() != id: continue
		var img := Image.new()
		if img.load_png_from_buffer(bytes) != OK: continue
		DirAccess.make_dir_recursive_absolute(directory)
		var file := FileAccess.open(directory + id + ".png", FileAccess.WRITE)
		if file == null: continue
		file.store_buffer(bytes); file.close()
		accepted[id] = bytes
	return accepted
