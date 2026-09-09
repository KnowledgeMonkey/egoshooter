extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(18).timeout.connect(func(): quit(1))
	var server := "--server" in OS.get_cmdline_user_args()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27997
	if server:
		var settings: Dictionary = game.config.duplicate()
		settings.bots = 0
		game.host(settings)
	else: game.join("127.0.0.1:27997")
	game.set_physics_process(false)
	var initialized := false
	var sent := false
	var saw_active := false
	var saw_roof := false
	var sequence := 0
	for tick in 200:
		await create_timer(0.05).timeout
		for p: Fighter in game.players.values(): p.set_physics_process(false)
		if server and game.players.size() == 2:
			var roster := []
			for p: Fighter in game.players.values():
				if p.peer_id != 1:
					if not initialized:
						p.reset_at(game.arena.lifts[0].bottom)
						initialized = true
					p.input_data.merge(p.queued_actions, true)
					p.queued_actions.clear()
					if p.input_data.get("interact", false): RopeLift.start(p)
					p.input_data["interact"] = false
					if p.rope_active: RopeLift.advance(p, 0.05)
					saw_active = saw_active or p.rope_active
					saw_roof = saw_roof or p.position.distance_to(game.arena.lifts[0].top) < 0.1
				roster.append(p.snapshot())
			game.receive_state.rpc(var_to_bytes([roster, game.scores, 600.0, false, "", [], [], game.objectives.snapshot()]).compress(FileAccess.COMPRESSION_DEFLATE))
		elif not server and game.active and game.players.has(game.local_id):
			var p: Fighter = game.players[game.local_id]
			if p.life < 2: continue
			if not sent:
				game.submit_actions.rpc_id(1, 1, {"interact": true})
				sent = true
			sequence += 1
			game.submit_input.rpc_id(1, sequence, {"move": Vector2.ZERO, "yaw": 0.0, "pitch": 0.0})
			saw_active = saw_active or p.rope_active
			saw_roof = saw_roof or p.target_position.distance_to(game.arena.lifts[0].top) < 0.1
	var passed := saw_active and saw_roof
	print("ROPE NETWORK ", "HOST" if server else "CLIENT", " result=", passed)
	game.leave()
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)
