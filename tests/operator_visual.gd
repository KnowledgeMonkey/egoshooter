extends SceneTree

# Isolated renderer: four views make team silhouettes and articulated limbs
# reviewable without moving the camera or changing a live match.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var screen := Control.new()
	root.add_child(screen)
	var background := ColorRect.new()
	background.color = Color("111b21")
	background.size = Vector2(1600, 900)
	screen.add_child(background)
	caption(screen, "BLOCKLINE / FIELD OPERATORS", Vector2(35, 27), 30)
	caption(screen, "Original tactical models  /  articulated gait  /  woven fabric and equipment", Vector2(35, 69), 17)
	for index in 4:
		var container := SubViewportContainer.new()
		container.position = Vector2(25 + index * 390, 122)
		container.size = Vector2(380, 682)
		screen.add_child(container)
		var view := SubViewport.new()
		view.size = Vector2i(380, 682)
		view.own_world_3d = true
		view.msaa_3d = Viewport.MSAA_4X
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		container.add_child(view)
		var world := Node3D.new()
		view.add_child(world)
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color("243138")
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color("bdced8")
		env.environment.ambient_light_energy = 0.48
		var sky := Sky.new()
		sky.sky_material = ProceduralSkyMaterial.new()
		env.environment.sky = sky
		env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		world.add_child(env)
		var floor_mesh := PlaneMesh.new()
		floor_mesh.size = Vector2(7, 7)
		var floor_instance := MeshInstance3D.new()
		floor_instance.mesh = floor_mesh
		var floor_mat := StandardMaterial3D.new()
		floor_mat.albedo_color = Color("3e4a4f")
		floor_mat.roughness = 0.9
		floor_instance.material_override = floor_mat
		world.add_child(floor_instance)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-43, -28, 0)
		sun.light_color = Color("fff0d6")
		sun.light_energy = 1.8
		sun.shadow_enabled = true
		world.add_child(sun)
		var fill := OmniLight3D.new()
		fill.position = Vector3(1.8, 2.8, -2.5)
		fill.omni_range = 7
		fill.light_color = Color("b6d3ed")
		fill.light_energy = 1.7
		world.add_child(fill)
		var operator := OperatorModel.new()
		operator.setup(index % 2)
		world.add_child(operator)
		operator.weapon_mount.add_child(WeaponModels.build(0 if index < 2 else 1))
		if index >= 2:
			operator.animate(0.1, 7.2, 0, false)
			operator.animate(0.025, 7.2, 0, false)
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.position = Vector3(2.4 if index % 2 == 0 else -2.4, 1.53, -4.1)
		camera.look_at(Vector3(0, 0.91, -0.02))
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.size = 1.32
		camera.current = true
		caption(screen, ("RELAY / TEAL" if index % 2 == 0 else "EMBER / ORANGE"), Vector2(39 + index * 390, 143), 18)
		caption(screen, "READY STANCE" if index < 2 else "RUNNING POSE", Vector2(39 + index * 390, 812), 17)
	caption(screen, "Helmet + comms  •  plate carrier  •  equipment pouches  •  knee protection  •  sculpted boots", Vector2(36, 860), 17)
	await create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/operators-redesign.png")
	quit()

func caption(parent: Control, text: String, position: Vector2, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color("d9e1df")
	parent.add_child(label)
