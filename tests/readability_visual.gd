extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27982
	game.host({"server_name": "Visual", "mode": "TDM", "max_players": 8, "bots": 0, "score_limit": 100, "time_limit": 600})
	game.set_physics_process(false)
	var a: Fighter = game.players[1]
	a.set_physics_process(false)
	a.reset_at(Vector3(0, 0.1, 28))
	for i in 2:
		var b: Fighter = game.add_player(-1 - i, "EMBER" if i else "TEAMMATE", true, 0)
		b.set_physics_process(false)
		b.reset_at(Vector3(-1.2 if i else 1.2, 0.1, 24))
		b.team = 1 - a.team if i else a.team
		b.yaw = PI
	game.ammo_drops.drop(a)
	game.ammo_drops.refresh()
	await create_timer(2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/player-readability.png")
	game.leave()
	game.queue_free()
	await process_frame
	print("READABILITY VISUAL PASS")
	quit()
