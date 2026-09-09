extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", title)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27984
	game.host({"server_name": "Muzzle test", "mode": "FFA", "max_players": 8, "bots": 0, "score_limit": 100, "time_limit": 600})
	game.set_physics_process(false)
	game.headless = false
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	p.reset_at(Vector3(0, 0.1, 28))
	var expected := [-0.562, -0.422, -0.712, -0.797, -0.192, -0.85, -0.82, -0.562, -0.422, -0.712]
	var required := [5, 7, 2, 1, 5, 3, 4, 4, 10, 3]
	for i in 10:
		var w: Dictionary = Arsenal.DATA[i]
		check(ceili(100.0 / (w.damage * w.pellets)) == required[i], "weapon %s close body shots to kill = %s" % [i, required[i]])
		p.weapon = i
		p.gun.select_weapon(i)
		var marker: Marker3D = p.gun.model.get_node("Muzzle")
		check(is_equal_approx(marker.position.z, expected[i]), "weapon %s marker lies on model barrel end" % i)
		p.gun.model.rotation = Vector3(0.1, -0.15, 0.2)
		p.gun.model.position = Vector3(0.03, 0.02, 0.04)
		check(ShotOrigin.visual(p).is_equal_approx(marker.global_position), "weapon %s visual origin follows animated barrel" % i)
		check(p.gun.muzzle.position.z < marker.position.z and is_equal_approx(p.gun.muzzle.position.y, marker.position.y), "weapon %s flash aligned forward of bore" % i)
		for aiming in [false, true]:
			p.aiming = aiming
			var route := ShotOrigin.path(p, Arsenal.direction(0, 0), 20)
			check(not route.blocked and route.start.is_equal_approx(ShotOrigin.muzzle(p)), "weapon %s authoritative path starts at bore ADS=%s" % [i, aiming])
	game.leave()
	game.queue_free()
	await process_frame
	print("TTK MUZZLE RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
