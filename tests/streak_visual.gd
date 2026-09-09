extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(file: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + file + ".png")
func run() -> void:
	create_timer(25).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27985
	game.host({"server_name": "Visual", "mode": "FFA", "max_players": 8, "bots": 0, "score_limit": 100, "time_limit": 600})
	game.set_physics_process(false)
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	p.reset_at(Vector3(0, 0.1, 28))
	p.pitch = -0.35
	for i in 10: game.streaks.earned(p)
	await physics_frame
	await physics_frame
	game.streaks.place(p)
	p.ult_charge = 4
	await capture("killstreak-hud")
	for i in 10: game.streaks.earned(p)
	await capture("nuke-countdown")
	game.streaks.advance(8)
	await capture("nuke-wipe")
	game.leave()
	game.queue_free()
	await process_frame
	print("STREAK VISUAL PASS")
	quit()
