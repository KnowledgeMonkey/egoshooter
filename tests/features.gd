extends SceneTree

var game: Node3D
var a: Fighter
var b: Fighter
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

func settle() -> void:
	await physics_frame
	await physics_frame

func place(p: Fighter, position: Vector3) -> void:
	p.reset_at(position)
	p.protection = 0
	p.set_physics_process(false)

func run() -> void:
	create_timer(50).timeout.connect(func(): printerr("FAIL feature timeout"); quit(1))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27980
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_physics_process(false)
	a = game.players[1]
	b = game.add_player(-1, "Feature target", false, 0)
	place(a, Vector3(28, 0.1, 30))
	place(b, Vector3(5, 0.1, 0))
	await settle()
	game.combat.explode(Vector3(0, 0.2, 0), 1)
	check(b.hp < 100 and b.hp > 0, "blast damages exposed target within eight metres")
	check(game.burn_zones.zones.size() == 1, "frag creates an authoritative burn zone")
	place(b, Vector3(9, 0.1, 0))
	await settle()
	game.combat.explode(Vector3(0, 0.2, 0), 1)
	check(b.hp == 100, "blast stops outside eight metres")
	game.burn_zones.clear()
	game.burn_zones.ignite(Vector3(0, 0.2, 0), 1)
	place(b, Vector3(3, 0.1, 0))
	await settle()
	game.burn_zones.advance(1)
	check(is_equal_approx(b.hp, 92), "burn deals eight HP per second in four ticks")
	b.team = a.team
	game.burn_zones.advance(0.5)
	check(is_equal_approx(b.hp, 92), "burn preserves team damage immunity")
	b.team = 1
	b.protection = 1
	game.burn_zones.advance(0.5)
	check(is_equal_approx(b.hp, 92), "burn respects spawn protection")
	b.protection = 0
	b.position.y = 3.7
	game.burn_zones.advance(0.5)
	check(is_equal_approx(b.hp, 92), "ground fire does not reach another storey")
	var rows: Array = game.burn_zones.snapshot()
	game.burn_zones.advance(0.5)
	check(game.burn_zones.zones.is_empty(), "burn ends after three seconds")
	game.is_host = false
	game.burn_zones.sync(rows)
	check(game.burn_zones.zones.size() == 1 and is_equal_approx(game.burn_zones.zones.values()[0].left, 0.5), "late snapshot retains remaining burn lifetime")
	game.burn_zones.sync([])
	check(game.burn_zones.zones.is_empty(), "client removes expired fire from snapshot")
	game.is_host = true
	place(b, Vector3(0, 0.1, 30))
	await settle()
	game.burn_zones.ignite(Vector3(0, 0.2, 37), 1)
	game.burn_zones.advance(1)
	check(b.hp == 100, "solid wall blocks lingering fire")
	game.burn_zones.clear()
	place(b, Vector3(0, 0.1, -6))
	b.yaw = PI
	await settle()
	game.combat.flash(Vector3(0, 1.65, 0))
	var direct: float = b.flash_left
	b.flash_left = 0
	b.yaw = 0
	game.combat.flash(Vector3(0, 1.65, 0))
	check(direct > b.flash_left * 2 and b.flash_left > 0, "flash strength depends on viewing direction")
	check(b.hp == 100 and game.burn_zones.zones.is_empty(), "flashbang causes neither damage nor fire")
	place(b, Vector3(0, 0.1, 30))
	await settle()
	game.combat.flash(Vector3(0, 1.65, 37))
	check(b.flash_left == 0, "wall blocks flash exposure")
	game.config.mode = "DOM"
	game.objectives.reset()
	game.scores = [0, 0]
	place(a, Vector3(0, 0.1, 0))
	place(b, Vector3(0, 0.1, 1))
	await settle()
	game.objectives.advance(4.1)
	check(game.objectives.points[1].owner == -1, "contested domination point is not captured")
	place(b, Vector3(28, 0.1, 30))
	await settle()
	game.objectives.advance(4.1)
	check(game.objectives.points[1].owner == 0 and game.scores[0] > 0, "uncontested domination capture awards team points")
	game.objectives.reset()
	a.position.y = 3.7
	await settle()
	game.objectives.advance(4.1)
	check(game.objectives.points[1].owner == -1, "domination cannot be captured from the floor above")
	game.config.mode = "KC"
	game.scores = [0, 0]
	game.objectives.reset()
	place(a, Vector3(0, 0.1, 0))
	place(b, Vector3(0, 0.1, -0.8))
	await settle()
	game.combat.damage(b, a, 200, "P12", false)
	check(game.scores[0] == 0 and game.objectives.tags.size() == 1, "kill confirmed drops a tag instead of awarding an immediate point")
	game.objectives.advance(0.1)
	check(game.scores[0] == 1 and game.objectives.tags.is_empty(), "enemy tag collection confirms the team point")
	game.objectives.death(a)
	game.objectives.advance(0.1)
	check(game.scores[0] == 1 and game.objectives.tags.is_empty(), "friendly tag collection denies without adding points")
	game.config.mode = "TDM"
	place(a, Vector3(0, 0.1, 2))
	place(b, Vector3(0, 0.1, -12))
	a.weapon = 3
	a.yaw = 0
	a.pitch = 0
	a.aiming = true
	await settle()
	game.combat.shoot(a)
	check(game.projectiles.get_child_count() == 1 and b.hp == 100, "sniper creates a travelling projectile rather than instant damage")
	await create_timer(0.15).timeout
	check(b.hp == 0 and game.projectiles.get_child_count() == 0, "sniper swept projectile hits and cleans up")
	place(a, Vector3(0, 0.1, 39))
	place(b, Vector3(0, 0.1, 30))
	a.weapon = 3
	a.yaw = 0
	a.aiming = true
	await settle()
	game.combat.shoot(a)
	await create_timer(0.15).timeout
	check(b.hp == 100, "sniper projectile cannot tunnel through spawn wall")
	place(a, Vector3(3, 0.1, -20.6))
	a.yaw = 0
	for frame in 6:
		a.move_character(1.0 / 60)
		await physics_frame
	a.input_data = {"jump": true}
	for frame in 25:
		a.move_character(1.0 / 60)
		await physics_frame
	check(a.position.y > 1.3 and a.position.z < -21.2, "mantle moves the real capsule onto a low cover")
	place(a, Vector3(0, 0.1, 36))
	a.yaw = 0
	await settle()
	check(not Mantle.destination(a).is_finite(), "mantle refuses tall walls")
	game.history.frames.clear()
	place(a, Vector3(0, 0.1, 2))
	place(b, Vector3(0, 0.1, -10))
	game.history.record([b.snapshot()])
	b.position.x = 7
	await settle()
	var hit: Dictionary = game.history.rewind_hit(a, a.eye(), Vector3(0, 1.75, -20), 0.1)
	check(hit.get("collider") == b, "rewind hit uses the recorded historical position")
	b.life += 1
	hit = game.history.rewind_hit(a, a.eye(), Vector3(0, 1.75, -20), 0.1)
	check(hit.get("collider") != b, "rewind never hits a previous life after respawn")
	var path := "res://tests/audit-settings.cfg"
	game.nickname = "Audit Operator"
	game.base_fov = 97
	check(PlayerSettings.save(game, path) == OK, "settings can be saved to a writable path")
	game.nickname = "Changed"
	game.base_fov = 80
	PlayerSettings.restore(game, path)
	check(game.nickname == "Audit Operator" and game.base_fov == 97, "settings restore player and viewing preferences")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	place(a, Vector3(28, 0.1, 30))
	place(b, Vector3(-17, 0.1, -22.6))
	b.team = a.team
	b.bot = true
	b.bot_target = Vector3(-15, 7.4, -22.6)
	b.bot_path = game.bots.routes.path(b.position, b.bot_target)
	b.bot_think = 1000
	for frame in 650:
		game.bots.update(b, 1.0 / 60)
		b.move_character(1.0 / 60)
		await physics_frame
		if b.position.distance_to(b.bot_target) < 0.5: break
	check(b.position.distance_to(b.bot_target) < 0.5, "bot follows the actual exterior stair route onto the roof at %s" % b.position)
	game.leave()
	check(game.burn_zones.zones.is_empty() and game.history.frames.is_empty(), "leaving clears persistent combat and replay state")
	game.queue_free()
	await process_frame
	print("FEATURES RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
