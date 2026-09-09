extends SceneTree

var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(15).timeout.connect(func(): quit(1))
	var server := "--server" in OS.get_cmdline_user_args()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27984
	if server:
		var settings: Dictionary = game.config.duplicate()
		settings.bots = 0
		game.host(settings)
	else:
		game.join("127.0.0.1:27984")
	game.set_physics_process(false)
	var initialized := false
	var strikes := 0
	var clock := 0.0
	var sequence := 0
	var confirmed := false
	var hurt := false
	var animated := false
	for tick in 180:
		await create_timer(0.05).timeout
		for p: Fighter in game.players.values(): p.set_physics_process(false)
		if server and game.players.size() == 2:
			if not initialized:
				for p: Fighter in game.players.values():
					p.reset_at(Vector3(28, 0.1, 28.6 if p.peer_id == 1 else 30.0))
					p.protection = 0
					p.yaw = 0
				initialized = true
			var roster := []
			for p: Fighter in game.players.values():
				p.melee_left = maxf(0, p.melee_left - 0.05)
				p.cooldown = maxf(0, p.cooldown - 0.05)
				p.input_data.merge(p.queued_actions, true)
				p.queued_actions.clear()
				game.combat.actions(p)
				roster.append(p.snapshot())
			game.receive_state.rpc(var_to_bytes([roster, game.scores, 600.0, false, "", [], [], game.objectives.snapshot()]).compress(FileAccess.COMPRESSION_DEFLATE))
			hurt = hurt or game.hud.hurt_time > 0
		elif not server and game.active and game.players.has(game.local_id):
			var p: Fighter = game.players[game.local_id]
			if p.life < 2: continue
			clock += 0.05
			sequence += 1
			if strikes < 2 and clock >= 0.4 + strikes * 0.9:
				strikes += 1
				game.submit_actions.rpc_id(1, strikes, {"melee": true})
			game.submit_input.rpc_id(1, sequence, {"move": Vector2.ZERO, "yaw": 0.0, "pitch": 0.0})
			animated = animated or p.melee_left > 0
			confirmed = confirmed or game.hud.elimination_time > 0
	var passed: bool = (initialized and game.players.has(1) and game.players[1].hp == 0 and hurt) if server else (confirmed and animated and strikes == 2)
	print("FPS NETWORK ", "HOST" if server else "CLIENT", " result=", passed, " hurt=", hurt, " confirmation=", confirmed, " animation=", animated)
	game.leave()
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)
