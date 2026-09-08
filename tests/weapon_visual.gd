extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(70).timeout.connect(func(): quit(1))
	var screen := Control.new()
	root.add_child(screen)
	var bg := ColorRect.new()
	bg.color = Color("0c151c")
	bg.size = Vector2(1600, 900)
	screen.add_child(bg)
	for index in 5:
		var col := index % 2
		var row := index / 2
		var container := SubViewportContainer.new()
		container.position = Vector2(30 + col * 790, 55 + row * 277)
		container.size = Vector2(760, 255)
		screen.add_child(container)
		var view := SubViewport.new()
		view.size = Vector2i(760, 255)
		view.own_world_3d = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		view.msaa_3d = Viewport.MSAA_4X
		container.add_child(view)
		var world := Node3D.new()
		view.add_child(world)
		var model := WeaponModels.build(index)
		world.add_child(model)
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color("19262e")
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color("bdcedb")
		env.environment.ambient_light_energy = 0.55
		var sky := Sky.new()
		sky.sky_material = ProceduralSkyMaterial.new()
		env.environment.sky = sky
		env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		world.add_child(env)
		for pos in [Vector3(0.9, 1, 0.2), Vector3(-0.6, 0.4, -0.9)]:
			var light := OmniLight3D.new()
			light.position = pos
			light.omni_range = 3
			light.light_energy = 1.7
			world.add_child(light)
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.position = Vector3(1.3, 0.62, 0.5)
		camera.look_at(Vector3(0, -0.02, -0.13))
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 0.47 if index != 4 else 0.31
		camera.current = true
		var label := Label.new()
		label.text = "%02d  /  %s" % [index + 1, Arsenal.DATA[index].name]
		label.position = container.position + Vector2(17, 12)
		label.add_theme_font_size_override("font_size", 19)
		screen.add_child(label)
	var title := Label.new()
	title.text = "BLOCKLINE / ARMORY     •     FIVE ORIGINAL WEAPON MODELS"
	title.position = Vector2(45, 15)
	title.add_theme_font_size_override("font_size", 22)
	screen.add_child(title)
	await create_timer(3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/weapons-redesign.png")
	screen.queue_free()
	await process_frame
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.ui.loadout_menu()
	await create_timer(1.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/weapon-loadout.png")
	game.port = 27994
	game.host({"server_name": "Weapon QA", "mode": "TDM", "max_players": 2, "bots": 0, "difficulty": 0, "score_limit": 50, "time_limit": 600})
	var p: Fighter = game.players[1]
	p.reset_at(Vector3(0, 0.05, 26))
	for index in 5:
		p.weapon = index
		await create_timer(1.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/weapon-fps-%s.png" % index)
	p.set_physics_process(false)
	p.weapon = 3
	p.aiming = true
	await create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/weapon-scope.png")
	p.aiming = false
	p.weapon = 0
	p.reload_left = 0.9
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/weapon-reload.png")
	p.reload_left = 0
	p.set_physics_process(true)
	game.config.bots = 7
	game.config.max_players = 8
	game.fill_bots()
	await create_timer(3).timeout
	var samples := []
	for i in 5:
		await create_timer(1).timeout
		samples.append(Engine.get_frames_per_second())
	print("EIGHT FIGHTER FPS SAMPLES=", samples)
	game.paused = true
	game.ui.host_menu()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/bot-settings.png")
	game.ui.settings_menu()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/bot-live-settings.png")
	print("WEAPON VISUAL PASS / FIVE MODELS / FPS=", Engine.get_frames_per_second())
	game.leave()
	quit()
