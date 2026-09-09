extends SceneTree

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

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27990
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	game.host(settings)
	game.set_physics_process(false)
	game.headless = false # Exercise the actual local presentation path with the dummy renderer.
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	var view: WeaponView = p.gun
	for index in 5:
		p.reset_at(Vector3(28, 0.1, 30))
		p.weapon = index
		view.animate(p, 1.0 / 120)
		p.magazines[index] -= 1
		view.animate(p, 1.0 / 120)
		check(view.recoil.x > 0 and view.recoil.y > 0, "weapon %s has confirmed-shot recoil" % index)
		check(view.muzzle.visible, "weapon %s produces a short muzzle flash" % index)
		for frame in 180: view.animate(p, 1.0 / 120)
		check(view.recoil.length() < 0.001 and not view.muzzle.visible, "weapon %s settles without permanent model drift" % index)
		p.reload_left = float(Arsenal.DATA[index].reload) * 0.6
		view.animate(p, 0.016)
		check(view.model.get_node("Magazine").position.y < 0, "weapon %s has a staged reload" % index)
		p.reload_left = 0
		p.aiming = true
		p.aim_blend = 0
		p._process(float(WeaponHandling.DATA[index].ads) * 0.5)
		check(is_equal_approx(p.aim_blend, 0.5), "weapon %s reaches half ADS at its own timing" % index)
		p._process(float(WeaponHandling.DATA[index].ads) * 0.5)
		check(is_equal_approx(p.aim_blend, 1), "weapon %s completes ADS predictably" % index)
		p.reload_left = 1
		p._process(float(WeaponHandling.DATA[index].ads))
		check(p.aim_blend == 0, "weapon %s leaves sights during reload" % index)
	var slow: Array[Vector2] = [Vector2(0.5, 0.1), Vector2(2, 1)]
	var fast := slow.duplicate()
	for i in 30: slow = WeaponHandling.settle(slow[0], slow[1], 18, 1.0 / 30)
	for i in 120: fast = WeaponHandling.settle(fast[0], fast[1], 18, 1.0 / 120)
	check(slow[0].distance_to(fast[0]) < 0.00001, "recoil spring agrees at 30 and 120 FPS")
	p.reset_at(Vector3(28, 0.1, 30))
	p.primary = 3
	p.weapon = 4
	p.input_data = {"switch": true, "fire": true}
	game.combat.actions(p)
	check(is_equal_approx(p.cooldown, 0.48) and p.magazines[3] == 5, "heavy weapon switch blocks immediate firing on host")
	p.input_data = {"switch": true}
	p.cooldown = 0
	game.combat.actions(p)
	check(is_equal_approx(p.cooldown, 0.20), "pistol equips faster than rifle")
	check(game.audio.sounds.shot_3.get_length() > game.audio.sounds.shot_1.get_length(), "sniper and SMG use distinct shot samples")
	game.leave()
	game.queue_free()
	await process_frame
	print("HANDLING RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
