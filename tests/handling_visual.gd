extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(45).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(1).timeout
	game.port = 27992
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	p.reset_at(Vector3(0.2, 0.1, 24))
	for weapon in 5:
		p.weapon = weapon
		p.aiming = false
		p.reload_left = 0
		await create_timer(0.6).timeout
		for shot in 3:
			p.magazines[weapon] -= 1
			game.fx("shot", p.eye(), p.peer_id, weapon)
			await create_timer(Arsenal.DATA[weapon].rate).timeout
		p.aiming = true
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/handling-ads-%s.png" % weapon)
		p.reload_left = float(Arsenal.DATA[weapon].reload) * 0.55
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/handling-reload-%s.png" % weapon)
	game.leave()
	await process_frame
	print("HANDLING VISUAL PASS")
	quit()
