extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if value:
		print("PASS ", description)
	else:
		failures += 1
		printerr("FAIL ", description)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27995
	game.host({"server_name": "Skill QA", "mode": "TDM", "max_players": 2, "bots": 1, "difficulty": 99, "score_limit": 50, "time_limit": 600})
	check(game.config.difficulty == 3, "host clamps difficulty to valid range")
	game.set_physics_process(false)
	var a: Fighter = game.players[1]
	var b: Fighter = game.players[-1]
	a.set_physics_process(false)
	b.set_physics_process(false)
	a.reset_at(Vector3(0, 0.05, 2))
	b.reset_at(Vector3(0, 0.05, -14))
	await physics_frame
	await physics_frame
	var first_shots := []
	for level in 4:
		game.config.difficulty = level
		b.bot_acquired = 0
		b.bot_enemy = 0
		b.yaw = PI
		b.pitch = 0
		var first := -1.0
		for frame in 100:
			game.bots.update(b, 0.02)
			if b.input_data.fire and first < 0:
				first = (frame + 1) * 0.02
		first_shots.append(first)
		check(first >= BotSkill.PROFILES[level].reaction and first < 1.4, "difficulty %s respects actual reaction delay: %.2fs" % [level, first])
		check(b.hp == 100 and a.hp == 100, "difficulty %s does not change health" % level)
	check(first_shots[0] > first_shots[1] and first_shots[1] > first_shots[2] and first_shots[2] > first_shots[3], "all four difficulties produce distinct reaction timing")
	a.position = Vector3(0, 0.05, 39)
	await physics_frame
	await physics_frame
	game.bots.update(b, 0.02)
	check(not b.input_data.fire and b.bot_enemy == 0, "wall blocks perception and resets acquired target")
	for index in 5:
		var model := WeaponModels.build(index)
		var second := WeaponModels.build(index)
		check(model.has_node("Frame") and model.has_node("Magazine") and model.has_node("Bolt"), "weapon %s has independent animated components" % index)
		check(second != model and second.get_node("Magazine") != model.get_node("Magazine"), "weapon %s cached instances have independent transforms" % index)
		var vertices := 0
		for part in model.get_node("Frame").get_children():
			if part is MeshInstance3D:
				vertices += part.mesh.surface_get_array_len(0)
		check(vertices > 1000, "weapon %s contains detailed visible geometry (%s vertices)" % [index, vertices])
		model.free()
		second.free()
	game.ui.settings_menu()
	game.ui.fields.difficulty.select(1)
	game.ui.fields.difficulty.item_selected.emit(1)
	check(game.config.difficulty == 1, "settings menu applies difficulty during match")
	game.leave()
	await process_frame
	print("REDESIGN RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
