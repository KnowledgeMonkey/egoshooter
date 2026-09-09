class_name UrbanLighting
extends RefCounted

static func build(parent: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.name = "DistrictAtmosphere"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = load("res://assets/sky/relay_clouds.hdr")
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.sky_rotation.y = 0.8
	env.background_energy_multiplier = 0.62
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Keep indirect light cool and modest: the sandstone is warmed by the sun,
	# while loading bays and the backs of cliffs still read as shaded spaces.
	env.ambient_light_color = Color("a6b9cd")
	env.ambient_light_sky_contribution = 0.7
	env.ambient_light_energy = 0.20
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.02
	env.ssao_enabled = true
	env.ssao_radius = 0.75
	env.ssao_intensity = 1.25
	env.ssao_power = 1.25
	env.ssao_detail = 0.75
	env.ssao_light_affect = 0.15
	env.fog_enabled = true
	env.fog_light_color = Color("b5bec1")
	env.fog_light_energy = 0.7
	env.fog_density = 0.0018
	env.fog_sky_affect = 0.12
	env.fog_aerial_perspective = 0.24
	env.glow_enabled = true
	env.glow_intensity = 0.14
	env.glow_bloom = 0.0
	world.environment = env
	parent.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "LateAfternoonSun"
	sun.rotation_degrees = Vector3(-31, -38, 0)
	sun.light_color = Color("ffe5c3")
	sun.light_energy = 1.9
	sun.light_angular_distance = 0.55
	sun.shadow_enabled = true
	# Large batched road and cliff surfaces need sufficient bias at this grazing
	# sun angle; too little produces diagonal self-shadow bands on every surface.
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 0.85
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 95
	parent.add_child(sun)
	# Shadowless fill represents scattered skylight inside the open loading bays.
	# It lifts local detail without flattening the exterior's sunlight and shade.
	for x in [-11, 11]:
		for z in [-18, 18]:
			var bounce := OmniLight3D.new()
			bounce.position = Vector3(x, 2.65, z)
			bounce.name = "WarehouseSkyBounce_%s_%s" % [x, z]
			bounce.light_color = Color("a6c4d5")
			bounce.light_energy = 0.32
			bounce.omni_range = 7
			bounce.omni_attenuation = 1.7
			bounce.shadow_enabled = false
			parent.add_child(bounce)
