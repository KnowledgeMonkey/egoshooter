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
	# Tile width in metres (source scan dimensions), restrained normal strength.
	var maps := {
		"asphalt": [2.1, 0.3], "concrete": [2.71, 0.4],
		"plaster": [2.0, 0.22], "paving": [3.1, 0.45],
		"ground": [4.0, 0.6], "wood": [1.5, 0.3], "floor": [2.08, 0.25],
		"rock": [2.38, 0.9], "sand": [2.1, 0.65], "corrugated": [2.7, 0.85], "brick": [4.0, 0.65]
	}
	if maps.has(kind):
		var prefix: String = kind
		mat.albedo_texture = texture("res://assets/materials/%s_color.jpg" % prefix)
		mat.normal_enabled = true
		mat.normal_texture = texture("res://assets/materials/%s_normal.jpg" % prefix)
		mat.normal_scale = maps[kind][1]
		mat.roughness_texture = texture("res://assets/materials/%s_roughness.jpg" % prefix)
		mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		mat.uv1_scale = Vector3.ONE / float(maps[kind][0])
		mat.roughness = 1.0
		if kind == "asphalt":
			mat.roughness = 0.72
			mat.normal_scale = 0.5
		if kind == "corrugated": mat.metallic = 0.45

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
	cache[key] = mat
	return mat
