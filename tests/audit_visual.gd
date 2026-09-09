extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + file + ".png")

func run() -> void:
	create_timer(45).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(2).timeout
	game.port = 27982
	game.host({"server_name": "Audit Visual", "mode": "DOM", "max_players": 2, "bots": 0, "difficulty": 0, "score_limit": 100, "time_limit": 600})
	game.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.set_physics_process(false)
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	p.reset_at(Vector3(0.2, 0.1, 24))
	p.yaw = 0
	p.pitch = -0.1
	await create_timer(2).timeout
	game.combat.explode(Vector3(0, 0.2, 3), 1)
	await create_timer(0.16).timeout
	await capture("audit-explosion")
	await create_timer(1.0).timeout
	await capture("audit-smoke")
	await create_timer(2.3).timeout
	await capture("audit-afterburn")
	game.paused = true
	game.ui.settings_menu()
	await create_timer(0.4).timeout
	await capture("audit-settings")
	game.ui.loadout_menu()
	await create_timer(0.4).timeout
	await capture("audit-loadout")
	game.leave()
	await process_frame
	print("AUDIT VISUAL PASS")
	quit()
