extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(50).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(2).timeout
	game.port = 27995
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	var views := [
		["bus", Vector3(38, 0.1, 17), 0.65, -0.02],
		["bus-interior", Vector3(32, 0.64, 10), 0.0, -0.05],
		["truck", Vector3(15, 0.1, 62.5), 0.25, 0.0],
		["tank", Vector3(32, 0.1, -58), -2.2, -0.02],
		["wreck", Vector3(40, 0.1, -7), 0.13, -0.03],
		["roof", Vector3(30, 7.43, 32), 2.8, -0.1],
		["armory", Vector3(-13.5, 0.1, -17), 0.4, 0.0],
		["ascender", Vector3(-11, 0.1, -9.5), 0.0, 0.25],
	]
	for view in views:
		p.reset_at(view[1])
		p.yaw = view[2]
		p.pitch = view[3]
		await create_timer(0.65).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/war-%s.png" % view[0])
	print("WAR VISUAL PASS")
	game.leave()
	await process_frame
	quit()
