extends SceneTree

var game: Node3D
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, title: String) -> void:
	checks += 1
	if value:
		print("PASS ", title)
	else:
		failures += 1
		printerr("FAIL ", title)

func settle() -> void:
	await physics_frame
	await physics_frame

func run() -> void:
	seed(7102)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.port = 27990
	game.host({"server_name": "Integration", "mode": "TDM", "max_players": 8, "bots": 7, "score_limit": 50, "time_limit": 600})
	check(game.active and game.players.size() == 8, "host creates eight slots including seven bots")
	var sides := [0, 0]
	for p: Fighter in game.players.values():
		sides[p.team] += 1
	check(sides == [4, 4], "automatic 4v4 team balance")
	game.set_physics_process(false)
	for p: Fighter in game.players.values():
		p.set_physics_process(false)
	for x in [-21, 0, 21]:
		var route: PackedVector2Array = game.arena.path(Vector3(x, 0, 30), Vector3(x, 0, -30))
		check(route.size() > 0, "lane %s connects north and south" % x)
		var length := 0.0
		for i in range(1, route.size()):
			length += route[i - 1].distance_to(route[i])
		print("LANE ", x, " path_m=", snappedf(length, 0.1), " sprint_seconds=", snappedf(length / 8.7, 0.1))
	for z in [-30, 0, 30]:
		check(game.arena.path(Vector3(-19, 0, z), Vector3(19, 0, z)).size() > 0, "cross connection at z=%s" % z)
	var a: Fighter = game.players[1]
	var b: Fighter = game.players[-1]
	for p: Fighter in game.players.values():
		p.position = Vector3(26, 0, 35 + p.peer_id * 0.1)
	a.reset_at(Vector3(0, 0.05, 2))
	b.reset_at(Vector3(0, 0.05, -14))
	a.protection = 0
	b.protection = 0
	a.yaw = 0
	a.pitch = -0.027
	a.aiming = true
	await settle()
	game.combat.shoot(a)
	check(b.hp < 100 and b.hp > 0 and a.magazines[0] == 29, "authoritative hitscan deals damage and consumes one round")
	b.hp = 100
	a.pitch = 0
	game.combat.shoot(a)
	check(b.hp < 60, "head hit has increased damage")
	b.hp = 100
	b.protection = 1
	game.combat.shoot(a)
	check(b.hp == 100, "spawn protection blocks damage")
	b.protection = 0
	b.team = a.team
	game.combat.shoot(a)
	check(b.hp == 100, "TDM friendly fire disabled")
	b.team = 1
	a.position = Vector3(0, 0.05, 39)
	b.position = Vector3(0, 0.05, 30)
	await settle()
	game.combat.shoot(a)
	check(b.hp == 100, "spawn wall blocks hitscan")
	game.combat.damage(b, a, 200, "AR-4", false)
	check(b.hp == 0 and b.respawn_left == 3 and a.kills == 1 and game.scores[0] == 1, "death sets respawn timer and team score")
	b.bot = false
	b._physics_process(3.1)
	check(b.hp == 100 and b.protection > 0 and b.magazines[0] == 30, "automatic respawn restores health, ammo and protection")
	a.weapon = 0
	a.magazines[0] = 2
	a.reserves[0] = 17
	a.input_data = {"reload": true}
	game.combat.actions(a)
	a._physics_process(1.9)
	check(a.magazines[0] == 19 and a.reserves[0] == 0, "reload transfers only available reserve")
	for w in 5:
		a.weapon = w
		a.magazines[w] = Arsenal.DATA[w].mag
		var before: int = a.magazines[w]
		game.combat.shoot(a)
		check(a.magazines[w] == before - 1 and a.cooldown == Arsenal.DATA[w].rate, "weapon %s ammunition and cadence" % Arsenal.DATA[w].short)
	game.config.mode = "FFA"
	b.team = a.team
	b.protection = 0
	b.hp = 100
	check(game.combat.damage(b, a, 20, "P12", false) and b.hp == 80, "FFA removes team immunity")
	a.reset_at(Vector3(0, 0.05, 2))
	b.reset_at(Vector3(0, 0.05, -1))
	a.protection = 0
	b.protection = 0
	await settle()
	game.combat.explode(Vector3(0, 0.3, 0), a.peer_id)
	check(b.hp < 100, "grenade radial damage reaches exposed target")
	a.reset_at(Vector3(0, 0.05, 39))
	b.reset_at(Vector3(0, 0.05, 30))
	b.protection = 0
	await settle()
	game.combat.explode(Vector3(0, 1, 37), a.peer_id)
	check(b.hp == 100, "grenade damage does not penetrate spawn wall")
	game.spawn_grenade(1, Vector3(0, 3, 0), Vector3(2, 2, 0))
	await create_timer(2.9).timeout
	check(game.grenades.get_child_count() == 0, "physical grenade expires after fuse")
	# Actual CharacterBody collision integration, not a formula-only movement test.
	a.reset_at(Vector3(0, 0.05, 20))
	a.input_data = {"move": Vector2(0, -1)}
	await settle()
	for frame in 60:
		a.move_character(1.0 / 60.0)
		await physics_frame
	var walked := 20 - a.position.z
	check(walked > 5 and walked < 6.2, "walking travels about 5.8 metres per second")
	a.reset_at(Vector3(0, 0.05, 20))
	a.input_data = {"move": Vector2(0, -1), "sprint": true}
	await settle()
	for frame in 60:
		a.move_character(1.0 / 60.0)
		await physics_frame
	check(20 - a.position.z > walked + 2, "sprint increases real movement speed")
	a.input_data = {"move": Vector2(0, -1), "sprint": true, "crouch": true}
	a.move_character(1.0 / 60.0)
	check(a.slide_left > 0 and a.crouched, "sprint plus crouch initiates slide")
	a.reset_at(Vector3(0, 0.05, 20))
	a.input_data = {}
	for frame in 8:
		a.move_character(1.0 / 60.0)
		await physics_frame
	a.input_data = {"jump": true}
	a.move_character(1.0 / 60.0)
	check(a.velocity.y > 6, "jump launches from ground")
	# Both ends of each platform are reachable with the small engine-sweep step.
	a.reset_at(Vector3(-23, 0.05, 9))
	a.slide_left = 0
	a.input_data = {"move": Vector2(0, -1)}
	for frame in 110:
		a.move_character(1.0 / 60.0)
		await physics_frame
	check(a.position.y > 1.8, "stairs lead to the elevated side platform")
	var enemy_index := 0
	for other: Fighter in game.players.values():
		if other == a:
			continue
		other.team = 1
		other.hp = 100
		other.position = game.arena.spawn_points[5 + enemy_index % 5]
		enemy_index += 1
	game.config.mode = "TDM"
	a.team = 0
	await settle()
	game.respawn(a)
	check(a.position.z < 0, "spawn selection flips away from occupied home base")
	game.config.mode = "TDM"
	game.scores = [50, 3]
	game.check_win()
	check(game.match_over and game.winner == "TEAM RELAY WINS", "TDM score limit ends match")
	game.config.mode = "FFA"
	game.match_over = false
	game.config.score_limit = 25
	a.kills = 25
	game.check_win()
	check(game.match_over and game.winner.contains(a.nickname), "FFA score limit ends match")
	game.leave()
	await process_frame
	check(not game.active and game.players.is_empty(), "leave cleans up session")
	print("RESULT ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
