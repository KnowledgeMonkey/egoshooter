class_name UrbanMaterials
extends RefCounted

# CC0 scanned surfaces, metre-scaled world triplanar UVs. No runtime downloads.
static var cache := {}
static var textures := {}

static func texture(path: String) -> Texture2D:
	if not textures.has(path):
		textures[path] = load(path)
	return textures[path]

static func get_surface(kind: String, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key := kind + tint.to_html()
	if cache.has(key):
		return cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.82
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	var maps := {"asphalt": "asphalt", "concrete": "concrete", "plaster": "concrete", "paving": "paving", "ground": "ground"}
	if maps.has(kind):
		var prefix: String = maps[kind]
		mat.albedo_texture = texture("res://assets/materials/%s_color.jpg" % prefix)
		mat.normal_enabled = true
		mat.normal_texture = texture("res://assets/materials/%s_normal.jpg" % prefix)
		mat.normal_scale = 0.10 if kind == "plaster" else (0.4 if kind == "asphalt" else 0.65)
		mat.roughness_texture = texture("res://assets/materials/%s_roughness.jpg" % prefix)
		mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		mat.uv1_scale = Vector3.ONE * (0.23 if kind == "asphalt" else (0.25 if kind == "ground" else 0.42))
		if kind == "plaster":
			mat.albedo_texture = null
			var noise := FastNoiseLite.new()
			noise.seed = 7481
			noise.frequency = 0.09
			var tex := NoiseTexture2D.new()
			tex.width = 256
			tex.height = 256
			tex.seamless = true
			tex.noise = noise
			var gradient := Gradient.new()
			gradient.set_color(0, Color(0.88, 0.88, 0.88))
			gradient.set_color(1, Color(0.98, 0.98, 0.98))
			tex.color_ramp = gradient
			mat.albedo_texture = tex
	elif kind in ["metal", "paint"]:
		mat.metallic = 0.78 if kind == "metal" else 0.35
		mat.roughness = 0.37 if kind == "metal" else 0.32
		mat.clearcoat_enabled = kind == "paint"
		mat.clearcoat = 0.5
		mat.clearcoat_roughness = 0.24
	elif kind == "glass":
		mat.albedo_color = tint * Color(0.23, 0.32, 0.36)
		mat.metallic = 0.65
		mat.roughness = 0.16
	elif kind == "rubber":
		mat.roughness = 0.94
	elif kind == "foliage":
		mat.roughness = 0.96
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var noise := FastNoiseLite.new()
		noise.seed = 7904
		noise.frequency = 0.09
		var tex := NoiseTexture2D.new()
		tex.width = 256
		tex.height = 256
		tex.seamless = true
		tex.noise = noise
		var gradient := Gradient.new()
		gradient.set_color(0, Color(0.28, 0.36, 0.28))
		gradient.set_color(1, Color(0.82, 0.87, 0.73))
		tex.color_ramp = gradient
		mat.albedo_texture = tex
		mat.uv1_scale = Vector3.ONE * 2.8
	elif kind == "wood":
		mat.albedo_color = tint
		mat.normal_enabled = true
		mat.normal_texture = texture("res://assets/materials/concrete_normal.jpg")
		mat.normal_scale = 0.18
		mat.uv1_scale = Vector3(1, 0.07, 1)
	cache[key] = mat
	return mat
