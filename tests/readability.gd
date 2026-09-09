extends SceneTree
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	if not ok: failed += 1
	print("PASS " if ok else "FAIL ", title)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27983
	game.host({"server_name": "Loot", "mode": "FFA", "max_players": 8, "bots": 0, "score_limit": 100, "time_limit": 600})
	game.set_physics_process(false)
	var a: Fighter = game.players[1]
	var b: Fighter = game.add_player(-1, "Target", true, 0)
	a.set_physics_process(false)
	b.set_physics_process(false)
	a.reset_at(Vector3(0, 0.1, 28))
	b.reset_at(Vector3(0, 0.1, 18))
	b.protection = 0
	await physics_frame
	game.combat.damage(b, a, 200, "TEST", false)
	check(game.ammo_drops.rows.size() == 1, "death drops one ammo box")
	a.position = b.position
	await physics_frame
	await physics_frame
	game.ammo_drops.advance(0.1)
	check(game.ammo_drops.rows.size() == 1, "full ammo does not waste pickup")
	a.reserves[a.primary] = 0
	a.reserves[4] = 0
	game.ammo_drops.advance(0.1)
	check(game.ammo_drops.rows.is_empty() and a.reserves[a.primary] == Arsenal.DATA[a.primary].mag and a.reserves[4] == 12, "pickup grants primary and pistol reserve")
	game.ammo_drops.drop(b)
	a.reserves[a.primary] = 0
	a.position = b.position + Vector3.UP * 3.5
	game.ammo_drops.advance(0.1)
	check(game.ammo_drops.rows.size() == 1 and a.reserves[a.primary] == 0, "pickup cannot cross floors")
	for i in 40: game.ammo_drops.drop(b)
	check(game.ammo_drops.rows.size() == 32, "drop count bounded at thirty-two")
	a.position += Vector3.RIGHT * 10
	game.ammo_drops.advance(31)
	check(game.ammo_drops.rows.is_empty(), "unclaimed ammo expires")
	check(CombatSystem.BLAST_RADIUS == 8 and CombatSystem.BLAST_DAMAGE == 110 and BurnZones.DAMAGE_PER_SECOND == 8, "grenade balance reduced")
	check(UrbanMaterials.get_surface("plaster").normal_scale == 0.5, "plaster relief strengthened")
	game.leave()
	game.queue_free()
	await process_frame
	print("READABILITY RESULT failures=", failed)
	quit(1 if failed else 0)
