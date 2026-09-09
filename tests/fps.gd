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

func positions(distance := 1.4) -> void:
	a.reset_at(Vector3(28, 0.1, 30))
	b.reset_at(Vector3(28, 0.1, 30 - distance))
	a.protection = 0
	b.protection = 0
	a.set_physics_process(false)
	b.set_physics_process(false)
	b.team = 1 - a.team
	await physics_frame
	await physics_frame

func run() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27983
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_physics_process(false)
	a = game.players[1]
	b = game.add_player(-1, "Sparring", true, 0)
	await positions()
	a.input_data = {"melee": true, "fire": true}
	a.reload_left = 1
	game.combat.actions(a)
	check(b.hp == 35, "melee hits close enemy for 65 damage")
	check(a.magazines[0] == 30, "melee blocks simultaneous gunfire without spending ammunition")
	check(a.reload_left == 0 and a.melee_left == 0.65, "melee interrupts reload and starts recovery")
	game.combat.melee(a)
	check(b.hp == 35, "repeated melee cannot bypass recovery")
	a.melee_left = 0
	game.combat.melee(a)
	check(b.hp == 0 and b.killer_weapon == "MELEE", "second strike kills through normal scoring and respawn path")
	check(game.hud.elimination_name == "Sparring" and game.hud.elimination_time > 0, "killer receives personal elimination confirmation")
	await positions(2.5)
	game.combat.melee(a)
	check(b.hp == 100, "melee cannot hit beyond reach")
	await positions()
	a.yaw = PI
	game.combat.melee(a)
	check(b.hp == 100, "melee cannot hit behind attacker")
	await positions()
	b.team = a.team
	game.combat.melee(a)
	check(b.hp == 100, "melee respects team immunity")
	await positions()
	b.protection = 1
	game.combat.melee(a)
	check(b.hp == 100, "melee respects spawn protection")
	await positions()
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 0.2)
	shape.shape = box
	wall.add_child(shape)
	game.add_child(wall)
	wall.position = Vector3(28, 1.5, 29.3)
	await physics_frame
	await physics_frame
	game.combat.melee(a)
	check(b.hp == 100, "solid wall blocks melee")
	wall.queue_free()
	await positions()
	a.mantle_left = 0.2
	game.combat.melee(a)
	check(b.hp == 100 and a.melee_left == 0, "no melee while climbing")
	a.mantle_left = 0
	game.combat.damage(a, b, 20, "AR", false)
	check(game.hud.hurt_time > 0 and game.hud.hurt_origin == b.eye(), "victim receives damage origin")
	check(ArenaHUD.damage_direction(b.eye(), a).is_equal_approx(Vector2.UP), "incoming front hit maps to top of reticle")
	a.yaw = PI / 2
	check(ArenaHUD.damage_direction(b.eye(), a).is_equal_approx(Vector2.RIGHT), "damage indicator rotates with current player view")
	game.combat.damage(a, b, 10, "FRAG", false, a.eye() + Vector3.RIGHT)
	check(game.hud.hurt_origin == a.eye() + Vector3.RIGHT, "explosion feedback uses explosion origin instead of thrower")
	var old_life := a.life
	a.reset_at(a.position)
	game.hud._process(0)
	check(game.hud.hurt_time == 0 and game.hud.elimination_time == 0, "respawn clears combat feedback")
	game.combat_notice("hurt", old_life, b.eye())
	check(game.hud.hurt_time == 0, "late feedback from a previous life is ignored")
	a.melee_left = 0.4
	b.apply_snapshot(a.snapshot())
	check(is_equal_approx(b.melee_left, 0.4), "melee animation recovery synchronizes in snapshots")
	game.leave()
	game.queue_free()
	await process_frame
	print("FPS RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
