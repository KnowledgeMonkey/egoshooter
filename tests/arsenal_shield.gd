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

func reset() -> void:
	a.reset_at(Vector3(0, 0.1, 28))
	b.reset_at(Vector3(0, 0.1, 18))
	a.protection = 0
	b.protection = 0
	a.yaw = 0
	a.pitch = -0.045
	a.aiming = true
	b.yaw = PI
	b.team = 1 - a.team
	a.set_physics_process(false)
	b.set_physics_process(false)
	await physics_frame
	await physics_frame

func projectiles() -> void:
	for frame in 20:
		for bullet in game.projectiles.get_children(): bullet._physics_process(0.01)
		await process_frame

func run() -> void:
	create_timer(40).timeout.connect(func(): quit(1))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27998
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_physics_process(false)
	a = game.players[1]
	b = game.add_player(-1, "Shield target", true, 0)
	await reset()
	check(Arsenal.DATA.size() == 10 and Arsenal.PRIMARY_IDS.size() == 9, "ten weapons with nine selectable primaries")
	for weapon in Arsenal.PRIMARY_IDS:
		await reset()
		a.weapon = weapon
		game.combat.shoot(a)
		await projectiles()
		check(a.magazines[weapon] == Arsenal.DATA[weapon].mag - 1, "weapon %s consumes its own magazine" % weapon)
		check(b.hp < 100, "weapon %s deals real damage" % weapon)
		var model := WeaponModels.build(weapon)
		check(model.has_node("Magazine") and model.has_node("Bolt") and model.get_node("Frame").get_child_count() > 0, "weapon %s has a complete animated model" % weapon)
		model.free()
	await reset()
	a.weapon = 3
	game.combat.shoot(a)
	await projectiles()
	check(b.hp == 0, "sniper one-shots an unprotected torso")
	await reset()
	a.weapon = 5
	a.input_data = {"fire": true}
	game.combat.actions(a)
	a.cooldown = 0
	game.combat.actions(a)
	check(a.magazines[5] == 14, "semi-auto DMR fires only once while trigger is held")
	a.input_data = {"fire": false}
	game.combat.actions(a)
	a.input_data = {"fire": true}
	game.combat.actions(a)
	check(a.magazines[5] == 13, "DMR fires again after a fresh trigger press")
	await reset()
	EnergyShield.activate(b)
	check(b.shield_left == 45 and b.shield_charges == 0, "shield activates for 45 seconds and consumes one charge")
	b.shield_left = 20
	EnergyShield.activate(b)
	check(b.shield_left == 20, "shield cannot be refreshed by spamming activation")
	for kind in ["AR", "M77", "MELEE", "FRAG", "FRAG / FIRE", "WRECK FIRE"]:
		check(not game.combat.damage(b, a, 200, kind, false, a.eye()) and b.hp == 100, "shield blocks frontal %s damage" % kind)
	check(game.combat.damage(b, a, 20, "AR", false, b.eye() + Vector3.FORWARD * 3) and b.hp == 80, "rear damage bypasses front shield")
	check(game.combat.damage(b, a, 10, "AR", false, b.eye() + Vector3.RIGHT * 3), "side damage bypasses shield")
	b.hp = 100
	game.combat.flash(a.eye())
	check(b.flash_left == 0, "front shield blocks flashbang exposure")
	game.combat.flash(b.eye() + Vector3.FORWARD * 2)
	check(b.flash_left > 0, "flash behind player remains effective")
	game.combat.shoot(a)
	check(b.hp == 100, "actual hitscan is intercepted by shield plane")
	a.weapon = 3
	game.combat.shoot(a)
	await projectiles()
	check(b.hp == 100 and game.projectiles.get_child_count() == 0, "shield intercepts and removes sniper projectile")
	var ray := EnergyShield.clip_ray(game, a, a.eye(), b.eye(), {})
	check(ray.has("shield") and ray.position.distance_to(b.eye()) > 0.5, "bullet stops at shield surface before reaching fighter")
	var outgoing := EnergyShield.clip_ray(game, b, b.eye(), a.eye(), {})
	check(outgoing.is_empty(), "shield does not block its owner's outgoing shots")
	b.shield_left = 0.01
	b.input_age = 0
	b.input_data = {}
	b.bot = false
	b._physics_process(0.02)
	check(b.shield_left == 0, "shield expires on authoritative physics clock")
	check(game.combat.damage(b, a, 10, "AR", false, a.eye()), "damage resumes after expiration")
	b.reset_at(b.position)
	check(b.shield_left == 0 and b.shield_charges == 1, "respawn resets active field and restores one charge")
	b.shield_left = 31
	a.apply_snapshot(b.snapshot())
	check(a.shield_left == 31, "shield remaining duration transfers in snapshots")
	await reset()
	a.weapon = 0
	var origin := ShotOrigin.muzzle(a)
	check(origin.y > a.position.y + 1.3 and origin.z < a.position.z - 0.5, "shot origin is at raised weapon rather than pelvis")
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 3, 0.1)
	shape.shape = box
	wall.add_child(shape)
	game.add_child(wall)
	wall.position = a.position + Vector3(0, 1.4, -0.3)
	await physics_frame
	await physics_frame
	check(ShotOrigin.path(a, Arsenal.direction(a.yaw, a.pitch), 70).blocked, "wall between camera and muzzle prevents barrel-through-wall shooting")
	game.combat.shoot(a)
	check(b.hp == 100, "barrel obstruction prevents damage behind wall")
	wall.queue_free()
	game.leave()
	game.queue_free()
	await process_frame
	print("ARSENAL SHIELD RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
