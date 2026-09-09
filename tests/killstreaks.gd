extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", name)
func run() -> void:
	create_timer(40).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27987
	game.host({"server_name": "Streak test", "mode": "FFA", "max_players": 8, "bots": 0, "score_limit": 100, "time_limit": 600})
	game.set_physics_process(false)
	var a: Fighter = game.players[1]
	var b: Fighter = game.add_player(-1, "Target", true, 0)
	a.set_physics_process(false)
	b.set_physics_process(false)
	a.reset_at(Vector3(0, 0.1, 28))
	b.reset_at(Vector3(0, 0.1, 18))
	a.protection = 0
	b.protection = 0
	await physics_frame
	await physics_frame
	for i in 5: game.streaks.earned(a)
	check(a.streak == 5 and a.infinite_left == 60 and a.ult_charge == 4, "five kills award one minute and cap ultimate charge")
	a.yaw = PI / 2
	var ammo: int = a.magazines[a.weapon]
	var reserve: int = a.reserves[a.weapon]
	var shots := a.shot_serial
	game.combat.shoot(a)
	check(a.magazines[a.weapon] == ammo and a.reserves[a.weapon] == reserve and a.shot_serial == shots + 1, "infinite fire consumes no ammo and confirms visual shot")
	a.magazines[a.weapon] = 2
	a.input_data = {"reload": true}
	game.combat.actions(a)
	check(a.reload_left == 0, "reload suppressed while infinite reward active")
	a.infinite_left = 0.01
	a._physics_process(0.02)
	check(a.infinite_left == 0, "infinite ammunition expires on host clock")
	game.combat.shoot(a)
	check(a.magazines[a.weapon] == 1, "normal ammunition consumption resumes")
	for i in 5: game.streaks.earned(a)
	check(a.recon_left == 30 and a.streak == 10, "ten kills unlock thirty-second radar")
	a.hp = 30
	a.shield_charges = 0
	for i in 5: game.streaks.earned(a)
	check(a.hp == 100 and a.shield_charges == 1, "fifteen kills heal and refill shield")
	a.yaw = 0
	a.cooldown = 0
	a.protection = 0
	check(game.streaks.place(a), "charged H ability places claymore on clear ground")
	check(a.ult_charge == 0 and game.streaks.mines.size() == 1, "placement spends one charge")
	check(not game.streaks.place(a), "empty charge cannot place again")
	var m: Dictionary = game.streaks.mines.values()[0]
	b.global_position = m.p + Vector3(0, 0.04, -2)
	await physics_frame
	await physics_frame
	check(game.streaks.triggers(m, b), "front cone detects enemy")
	b.global_position = m.p + Vector3(0, 0.04, 2)
	check(not game.streaks.triggers(m, b), "rear does not trigger mine")
	b.global_position = m.p + Vector3(0, 4, -2)
	check(not game.streaks.triggers(m, b), "other floor does not trigger mine")
	b.global_position = m.p + Vector3(0, 0.04, -2)
	await physics_frame
	await physics_frame
	game.streaks.advance(0.5)
	check(game.streaks.mines.size() == 1, "mine requires arming delay")
	game.streaks.advance(0.6)
	check(game.streaks.mines.is_empty() and b.hp < 100, "armed claymore detonates and applies damage")
	a.ult_charge = 3
	a.protection = 0
	a.shield_left = 0
	b.hp = 100
	game.combat.damage(a, b, 200, "TEST", false)
	check(a.streak == 0 and a.infinite_left == 0 and a.recon_left == 0 and a.ult_charge == 3, "death clears streak buffs but preserves ultimate")
	a.reset_at(Vector3(0, 0.1, 28))
	check(a.ult_charge == 3, "respawn preserves accumulated ultimate charge")
	for i in 20: game.streaks.earned(a)
	check(game.streaks.nuke_left == 8 and game.streaks.nuke_owner == 1, "twenty consecutive kills start nuke countdown")
	game.config.score_limit = 1
	a.kills = 20
	game.check_win()
	check(not game.match_over, "armed nuke takes priority over score ending")
	var snapshot: Dictionary = a.snapshot()
	b.apply_snapshot(snapshot)
	check(b.streak == 20 and b.ult_charge == 4 and b.infinite_left == 60, "reward state transfers through player snapshot")
	game.streaks.advance(7.9)
	check(not game.match_over, "nuke respects countdown")
	a.protection = 60
	b.protection = 60
	a.shield_left = 45
	b.shield_left = 45
	game.streaks.advance(0.2)
	check(game.match_over and a.hp == 0 and b.hp == 0 and "NUKE" in game.winner, "nuke wipes all players despite shields and awards round victory")
	check(a.streak == 0, "nuke cannot farm a new streak")
	game.streaks.clear()
	check(game.streaks.nuke_left == 0 and game.streaks.mines.is_empty(), "round cleanup removes rewards and devices")
	game.leave()
	game.queue_free()
	await process_frame
	print("KILLSTREAK RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
