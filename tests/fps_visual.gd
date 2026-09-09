extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(1).timeout
	game.port = 27985
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	p.reset_at(Vector3(0.2, 0.1, 24))
	p.protection = 0
	p.magazines[0] = 5
	await create_timer(1).timeout
	game.combat_notice("hurt", p.life, p.eye() + Vector3.RIGHT * 3)
	game.combat_notice("elimination", p.life, p.eye(), "Training Target")
	p.melee_left = 0.32
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/fps-feedback.png")
	print("FPS VISUAL PASS")
	game.leave()
	await process_frame
	quit()
