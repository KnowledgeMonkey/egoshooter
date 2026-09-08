class_name CombatVisuals
extends RefCounted

static var finishes := {}

static func finish(kind: String) -> StandardMaterial3D:
	if finishes.has(kind):
		return finishes[kind]
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var p := Vector2(x - 31.5, y - 31.5) / 31.5
			var noise := 0.82 + sin(x * 0.55 + cos(y * 0.37) * 4) * 0.1
			var opacity := pow(maxf(0, 1 - p.length()), 1.6) * noise
			image.set_pixel(x, y, Color(1, 1, 1, opacity))
	image.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.25, 0.27, 0.27, 0.8) if kind == "smoke" else Color(1, 0.66, 0.25, 1)
	if kind != "smoke":
		mat.emission_enabled = true
		mat.emission = Color(1, 0.54, 0.19)
		mat.emission_energy_multiplier = 2
	finishes[kind] = mat
	return mat

static func puff(parent: Node3D, pos: Vector3, size: float, kind: String, life: float, drift: Vector3) -> void:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	node.mesh = quad
	node.material_override = finish(kind)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.global_position = pos
	var tween := parent.create_tween().set_parallel(true)
	tween.tween_property(node, "global_position", pos + drift, life)
	tween.tween_property(node, "scale", Vector3.ONE * (2.1 if kind == "smoke" else 0.1), life)
	tween.tween_property(node, "transparency", 1.0, life)
	tween.chain().tween_callback(node.queue_free)

static func explosion(parent: Node3D, pos: Vector3) -> void:
	puff(parent, pos, 3, "flash", 0.16, Vector3.UP * 0.2)
	for i in 9:
		var angle := i * TAU / 9
		var drift := Vector3(cos(angle), 0.75 + i % 3 * 0.3, sin(angle)) * 1.5
		puff(parent, pos + drift * 0.1, 1.5 + i % 3 * 0.3, "smoke", 0.7 + i % 3 * 0.12, drift)
	var light := OmniLight3D.new()
	light.light_color = Color("ffb26d")
	light.light_energy = 4
	light.omni_range = 9
	parent.add_child(light)
	light.global_position = pos + Vector3.UP * 0.2
	var tween := parent.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.2)
	tween.tween_callback(light.queue_free)

static func impact(parent: Node3D, pos: Vector3) -> void:
	puff(parent, pos, 0.1, "flash", 0.07, Vector3.UP * 0.03)
	puff(parent, pos, 0.22, "smoke", 0.32, Vector3.UP * 0.35)
