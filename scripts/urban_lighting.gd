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
	env.background_energy_multiplier = 0.68
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.52
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 1.1
	env.ssao_power = 1.25
	env.ssao_detail = 0.6
	env.ssao_light_affect = 0.25
	env.fog_enabled = true
	env.fog_light_color = Color("b6c5cb")
	env.fog_light_energy = 0.65
	env.fog_density = 0.0016
	env.fog_sky_affect = 0.1
	env.fog_aerial_perspective = 0.18
	env.glow_enabled = true
	env.glow_intensity = 0.2
	env.glow_bloom = 0.02
	world.environment = env
	parent.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "LateAfternoonSun"
	sun.rotation_degrees = Vector3(-39, -28, 0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 1.1
	sun.light_angular_distance = 1.2
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 0.8
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 95
	parent.add_child(sun)
	# Four modest indoor bounce lights make the open flank routes readable.
	for x in [-11, 11]:
		for z in [-18, 18]:
			var bounce := OmniLight3D.new()
			bounce.position = Vector3(x, 2.65, z)
			bounce.light_color = Color("c7d9da")
			bounce.light_energy = 0.6
			bounce.omni_range = 7
			bounce.omni_attenuation = 1.5
			parent.add_child(bounce)
