extends SceneTree

var game: Node3D
var p: Fighter
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, title: String) -> void:
	checks += 1
	if ok: print("PASS ", title)
	else:
		failures += 1
		printerr("FAIL ", title)

func place(pos: Vector3) -> void:
	p.reset_at(pos)
	p.set_physics_process(false)
	p.set_process(false)
	await physics_frame
	await physics_frame

func run() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27994
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_physics_process(false)
	p = game.players[1]
	p.set_physics_process(false)
	check(RelayArena.HALF_WIDTH * RelayArena.HALF_LENGTH == 36 * 50 * 1.6, "play area is exactly 60 percent larger")
	check(game.arena.building_origins.size() == 8, "eight enterable multi-storey buildings")
	check(game.bots.routes.buildings.size() == 8, "bot floor routes include all added buildings")
	check(game.arena.vending_points.size() == 8, "eight offline armoury terminals")
	check(game.arena.vehicle_entries.size() == 4, "two buses and two cargo bays")
	for origin: Vector3 in game.arena.building_origins:
		if absf(origin.x) < 20: continue
		var shielded := true
		for spawn: Vector3 in game.arena.spawn_points:
			if game.visible_between(origin + Vector3(0, 9.05, 4.7), spawn + Vector3.UP * 1.65): shielded = false
		check(shielded, "new roof cannot see protected spawn centres")
		check(not game.bots.routes.path(origin + Vector3(signf(origin.x) * 6, 0.1, -4.6), origin + Vector3(0, 7.4, 4.7)).is_empty(), "new building has a connected bot route from street to roof")
	for entry: Vector3 in game.arena.vehicle_entries:
		await place(entry)
		check(not p.test_move(p.global_transform, Vector3(0, 0.1, 0)), "vehicle cabin has capsule headroom at %s" % entry)
		check(game.visible_between(p.eye(), p.eye() + Vector3.FORWARD), "vehicle interior has an open sightline")
	# Actually climb side steps into both bus interiors, rather than just teleporting in.
	for side in [-1, 1]:
		var center := Vector3(side * 32, 0, side * 10)
		await place(center + Vector3(3.2, 0.1, 0))
		p.yaw = 0
		for frame in 55:
			p.input_data = {"move": Vector2(-1, 0)}
			p.move_character(1.0 / 60)
			await physics_frame
			if absf(p.position.x - center.x) < 0.25: break
		check(p.position.y > 0.6 and absf(p.position.x - center.x) < 1.2, "real player climbs bus steps into central aisle at %s" % p.position)
	for side in [-1, 1]:
		var center := Vector3(side * 13, 0, side * 56)
		await place(center + Vector3(0, 0.1, 6.6))
		p.yaw = 0
		for frame in 55:
			p.input_data = {"move": Vector2(0, -1)}
			p.move_character(1.0 / 60)
			await physics_frame
		check(p.position.y > 0.85 and p.position.z < center.z + 3, "real player climbs into truck cargo bay")
	for lift: Dictionary in game.arena.lifts:
		await place(lift.bottom)
		RopeLift.start(p)
		check(p.rope_active, "rope attaches at ground endpoint")
		for frame in 220:
			RopeLift.advance(p, 1.0 / 60)
			if not p.rope_active: break
		check(p.position.distance_to(lift.top) < 0.05, "rope traverses parapet and delivers player onto roof")
		RopeLift.start(p)
		check(p.rope_active, "rope attaches at roof endpoint")
		for frame in 220:
			RopeLift.advance(p, 1.0 / 60)
			if not p.rope_active: break
		check(p.position.distance_to(lift.bottom) < 0.05, "rope descends to ground without wall teleport")
	await place(game.arena.lifts[0].bottom)
	RopeLift.start(p)
	var ammo: int = p.magazines[0]
	p.input_data = {"fire": true}
	game.combat.actions(p)
	check(p.magazines[0] == ammo, "firing blocked while using rope")
	p.input_data = {"jump": true}
	RopeLift.advance(p, 0.1)
	check(not p.rope_active, "jump releases rope")
	await place(Vector3(0, 0.1, 0))
	RopeLift.start(p)
	check(not p.rope_active, "remote interaction cannot teleport to a rope")
	for x in [-22, 0, 22]:
		check(not game.arena.path(Vector3(x, 0, -30), Vector3(x, 0, 30)).is_empty(), "original lane remains connected")
	game.leave()
	game.queue_free()
	await process_frame
	print("WAR DISTRICT RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
