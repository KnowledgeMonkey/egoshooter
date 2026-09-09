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
			if kind == "flame":
				var height := 1.0 - float(y) / 63.0
				var width := 0.16 + (1 - height) * 0.66
				var sway := sin(height * 12 + cos(height * 7)) * 0.12 * height
				opacity = pow(maxf(0, 1 - absf(p.x + sway) / width), 1.4) * sin(height * PI) * noise
				image.set_pixel(x, y, Color(1, 0.18 + (1 - height) * 0.62, 0.035 + (1 - height) * 0.25, opacity))
			else:
				image.set_pixel(x, y, Color(1, 1, 1, opacity))
	image.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED if kind in ["embers", "ring"] else BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.25, 0.27, 0.27, 0.8) if kind == "smoke" else Color(1, 0.66, 0.25, 1)
	if kind == "flame":
		mat.albedo_color = Color.WHITE
	if kind == "embers":
		mat.albedo_color = Color(0.36, 0.08, 0.015, 0.8)
	if kind == "ring":
		mat.albedo_texture = null
		mat.albedo_color = Color(1, 0.65, 0.32, 0.7)
	if kind != "smoke":
		mat.emission_enabled = true
		mat.emission = Color(1, 0.54, 0.19)
		mat.emission_energy_multiplier = 0.6 if kind == "embers" else 2.5
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
	tween.tween_property(node, "scale", Vector3.ONE * (2.1 if kind in ["smoke", "fireball"] else 0.1), life)
	tween.tween_property(node, "transparency", 1.0, life)
	tween.chain().tween_callback(node.queue_free)

static func explosion(parent: Node3D, pos: Vector3) -> void:
	# A compact cinematic mushroom cloud: rising stem, expanding crown and shock ring.
	puff(parent, pos + Vector3.UP, 9, "flash", 0.22, Vector3.UP)
	for i in 8:
		var angle := i * TAU / 8
		var radial := Vector3(cos(angle), 0, sin(angle))
		puff(parent, pos + Vector3.UP * 1.3 + radial, 3.4, "fireball", 0.85, radial * 3 + Vector3.UP * 3)
		puff(parent, pos + Vector3.UP * 4 + radial * 2, 3.0, "smoke", 3.2, radial * 3 + Vector3.UP * 3.5)
	for i in 5:
		puff(parent, pos + Vector3.UP * (0.7 + i * 0.9), 2.1, "smoke", 2.4, Vector3(0.2, 3, 0.15))
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	torus.rings = 48
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = finish("ring")
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	ring.global_position = pos + Vector3.UP * 0.25
	var wave := parent.create_tween().set_parallel(true)
	wave.tween_property(ring, "scale", Vector3(14, 0.5, 14), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	wave.tween_property(ring, "transparency", 1.0, 0.65)
	wave.chain().tween_callback(ring.queue_free)
	var light := OmniLight3D.new()
	light.light_color = Color("ffb26d")
	light.light_energy = 9
	light.omni_range = 23
	parent.add_child(light)
	light.global_position = pos + Vector3.UP * 2
	var tween := parent.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.8)
	tween.tween_callback(light.queue_free)

static func flash(parent: Node3D, pos: Vector3) -> void:
	puff(parent, pos, 2.5, "flash", 0.12, Vector3.ZERO)

static func impact(parent: Node3D, pos: Vector3) -> void:
	puff(parent, pos, 0.1, "flash", 0.07, Vector3.UP * 0.03)
	puff(parent, pos, 0.22, "smoke", 0.32, Vector3.UP * 0.35)
