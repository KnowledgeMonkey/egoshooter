extends SceneTree

var game: Node3D
var actor: Fighter
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, title: String) -> void:
	checks += 1
	if ok:
		print("PASS ", title)
	else:
		failures += 1
		printerr("FAIL ", title)

func walk_to(target: Vector3) -> bool:
	for frame in 240:
		var delta := Vector2(target.x - actor.position.x, target.z - actor.position.z)
		if delta.length() < 0.12:
			actor.input_data = {}
			actor.velocity = Vector3.ZERO
			return absf(actor.position.y - target.y) < 0.3
		actor.yaw = 0
		actor.input_data = {"move": delta.normalized() * minf(1, delta.length() * 4)}
		actor.move_character(1.0 / 60)
		await physics_frame
	print("STUCK at ", actor.position, " target ", target)
	return false

func reset_at(point: Vector3) -> void:
	actor.reset_at(point + Vector3.UP * 0.05)
	actor.slide_left = 0
	actor.input_data = {}
	for frame in 5:
		actor.move_character(1.0 / 60)
		await physics_frame

func run() -> void:
	create_timer(100).timeout.connect(func(): printerr("FAIL expansion timeout"); quit(1))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27994
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	settings.max_players = 2
	game.host(settings)
	game.set_physics_process(false)
	actor = game.players[1]
	actor.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(game.arena.nav.is_in_boundsv(Vector2i(34, 47)), "navigation retains the original expanded core")
	for x in [-33, -21, 0, 21, 33]:
		check(game.arena.path(Vector3(x, 0, 39), Vector3(x, 0, -39)).size() > 0, "extended route north to south x=%s" % x)
	for spawn: Vector3 in game.arena.spawn_points:
		check(game.arena.path(spawn, Vector3(0, 0, 0)).size() > 0, "spawn has a navigable side exit %s" % spawn)
	var houses := [Vector3(-11, 0, -18), Vector3(11, 0, -18), Vector3(-11, 0, 18), Vector3(11, 0, 18)]
	for house in houses:
		await reset_at(house + Vector3(2, 0, 4.6))
		check(await walk_to(house + Vector3(2, 3.7, -4.6)), "interior stairs reach upper floor %s" % house)
		var turn: bool = await walk_to(house + Vector3(0, 3.7, -4.6))
		turn = await walk_to(house + Vector3(-2.4, 3.7, -4.6)) and turn
		check(turn and await walk_to(house + Vector3(-2.4, 7.4, 4.6)), "continuous interior route reaches roof %s" % house)
		var side := signf(house.x)
		await reset_at(house + Vector3(side * 6, 0, -4.6))
		check(await walk_to(house + Vector3(side * 6, 3.7, 4.6)), "exterior stairs reach upper landing %s" % house)
		var door: bool = await walk_to(house + Vector3(side * 3.8, 3.7, 4.6))
		check(door, "exterior upper door is physically passable %s" % house)
		await walk_to(house + Vector3(side * 6, 3.7, 4.6))
		var landing: bool = await walk_to(house + Vector3(side * 8.3, 3.7, 4.6))
		landing = await walk_to(house + Vector3(side * 8.3, 7.4, -4.6)) and landing
		check(landing and await walk_to(house + Vector3(side * 4.0, 7.4, -4.6)), "independent exterior route reaches roof %s" % house)
		for end in [-1, 1]:
			check(game.visible_between(house + Vector3(-2.1, 5.35, end * 4.7), house + Vector3(-2.1, 5.35, end * 7)), "upper window passes shots %s end=%s" % [house, end])
		var front := -signf(house.z)
		check(game.visible_between(house + Vector3(3, 9.05, front * 5), Vector3(0, 1.65, 0)), "roof can fire toward central lane %s" % house)
		var protected_spawns := true
		for x in [-8.3, -3.8, 0.0, 3.8, 8.3]:
			for z in [-4.8, 0.0, 4.8]:
				for y in [9.05, 10.15]:
					for spawn: Vector3 in game.arena.spawn_points:
						if game.visible_between(house + Vector3(x, y, z), spawn + Vector3.UP * 1.65):
							protected_spawns = false
							print("EXPOSED ", house + Vector3(x, y, z), " -> ", spawn)
		check(protected_spawns, "all ten spawn centers shielded from sampled roof positions %s" % house)
	# One descent checks landings and stairwell headroom in the reverse direction.
	var last: Vector3 = houses[-1]
	await reset_at(last + Vector3(-2.4, 7.4, 4.6))
	var descent: bool = await walk_to(last + Vector3(-2.4, 3.7, -4.6))
	descent = await walk_to(last + Vector3(0, 3.7, -4.6)) and descent
	descent = await walk_to(last + Vector3(2, 3.7, -4.6)) and descent
	check(descent and await walk_to(last + Vector3(2, 0.1, 4.6)), "roof to ground descent without teleporting")
	game.leave()
	game.queue_free()
	await process_frame
	print("EXPANSION RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
