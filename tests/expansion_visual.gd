extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(70).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(3).timeout
	game.port = 27995
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_process_unhandled_input(false)
	game.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	var views := [
		["expansion-street", Vector3(0, 0.1, 30), Vector3(-11, 4.5, -18)],
		["expansion-stairs", Vector3(-26, 0.1, -9), Vector3(-17, 4.3, -18)],
		["expansion-upper", Vector3(-14.8, 3.7, -14.0), Vector3(-10, 5.35, -19)],
		["expansion-window", Vector3(-13.1, 3.7, -13.3), Vector3(-11, 1.65, 0)],
		["expansion-roof", Vector3(-7.3, 7.4, -17), Vector3(0, 3.5, 0)],
		["expansion-spawn", Vector3(0, 0.1, 46.5), Vector3(-7, 2.0, 42)]
	]
	for view in views:
		p.reset_at(view[1])
		var direction: Vector3 = (view[2] - p.eye()).normalized()
		p.yaw = atan2(-direction.x, -direction.z)
		p.pitch = asin(direction.y)
		await create_timer(1.5).timeout
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://docs/" + view[0] + ".png")
		if result != OK:
			printerr("FAIL screenshot ", view[0])
			quit(1)
		print("CAPTURE ", view[0], " FPS=", Engine.get_frames_per_second())
	# Warm each quality level, then sample with seven active bots in the same view.
	p.reset_at(Vector3(0, 0.1, 30))
	p.yaw = 0
	p.pitch = 0.06
	p.protection = 120
	game.config.bots = 7
	game.fill_bots()
	game.set_physics_process(true)
	for quality in [1, 0, 2]:
		GraphicsSettings.apply(game, quality)
		await create_timer(3).timeout
		var samples := []
		for i in 3:
			await create_timer(1).timeout
			samples.append(Engine.get_frames_per_second())
		print("EXPANSION FPS ", GraphicsSettings.NAMES[quality], " samples=", samples,
			" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("EXPANSION VISUAL PASS renderer=", RenderingServer.get_current_rendering_method())
	game.leave()
	await process_frame
	quit()
