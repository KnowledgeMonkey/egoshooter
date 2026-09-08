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

func run() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.port = 27995
	game.host({"server_name": "Killcam test", "mode": "FFA", "max_players": 8, "bots": 2, "score_limit": 100, "time_limit": 600})
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	for fighter: Fighter in game.players.values():
		fighter.set_physics_process(false)
		fighter.set_process(false)
	var victim: Fighter = game.players[1]
	var attacker: Fighter = game.players[-1]
	victim.reset_at(Vector3(0, 0.1, 27))
	attacker.reset_at(Vector3(0, 0.1, 20))
	attacker.yaw = 0
	victim.protection = 0
	game.combat.damage(victim, attacker, 200, "AR-4", false)
	check(victim.killer_id == -1 and victim.respawn_left == 3, "Bot kill records negative killer ID and unchanged countdown")
	var state: Dictionary = victim.snapshot()
	var replica := Fighter.new()
	replica.setup(game, 77, "Replica", 1, false, 0)
	game.add_child(replica)
	replica.set_process(false)
	replica.set_physics_process(false)
	replica.apply_snapshot(bytes_to_var(var_to_bytes(state)))
	check(replica.killer_id == -1 and replica.killer == attacker.nickname and replica.hp == 0, "Serialized snapshot delivers killer identity")
	state.erase("killer_id")
	replica.apply_snapshot(state)
	check(replica.killer_id == 0, "Older snapshot without killer ID remains compatible")
	var was_headless: bool = game.headless
	game.headless = true
	var before_camera: Camera3D = root.get_camera_3d()
	victim._process(0.1)
	check(root.get_camera_3d() == before_camera and not game.death_camera_active, "Headless death never switches cameras")
	# Exercise the actual Camera3D nodes even with the headless rendering driver.
	game.headless = false
	game.paused = false
	victim.camera.make_current()
	victim._process(0.1)
	check(game.spectator_camera.current and not victim.camera.current and not attacker.camera.current, "Death activates only dedicated spectator camera")
	check(game.is_killcam_visible(victim) and not victim.gun.visible, "Live killer label enabled and first-person weapon hidden")
	var start: Vector3 = game.spectator_camera.global_position
	attacker.position.x += 2
	victim._process(0.05)
	check(game.spectator_camera.global_position.x > start.x and game.spectator_camera.global_position.x < start.x + 2, "Live tracking interpolates killer motion")
	if "--visual" in OS.get_cmdline_user_args():
		attacker._process(0.1)
		for frame in 20:
			victim._process(0.05)
			await process_frame
		await RenderingServer.frame_post_draw
		var output := "res://logs/killcam-preview.png"
		check(root.get_texture().get_image().save_png(output) == OK, "Killcam screenshot saved")
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(120, 80)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var angles := Vector2(victim.yaw, victim.pitch)
	game._unhandled_input(mouse)
	check(Vector2(victim.yaw, victim.pitch) == angles, "Mouse motion cannot rotate a dead player")
	var reload_key := InputEventAction.new()
	reload_key.action = "reload"
	reload_key.pressed = true
	game._unhandled_input(reload_key)
	check(game.pending.is_empty(), "Dead input cannot queue a respawn action")
	game.paused = true
	var frozen: Transform3D = game.spectator_camera.global_transform
	attacker.position.x += 4
	victim._process(0.1)
	check(game.spectator_camera.global_transform == frozen and game.spectator_camera.current, "Pause freezes camera and suppresses switching")
	game.paused = false
	attacker.hp = 0
	victim._process(0.1)
	check(game.spectator_camera.global_transform == game.death_camera_fallback and not game.is_killcam_visible(victim), "Dead killer switches to static corpse fallback")
	var corpse: Transform3D = game.spectator_camera.global_transform
	victim.position.x += 3
	victim._process(0.1)
	check(game.spectator_camera.global_transform == corpse, "Fallback stays static despite corpse corrections")
	attacker.hp = 100
	victim._process(0.1)
	game.remove_player(attacker.peer_id)
	victim._process(0.1)
	await process_frame
	victim._process(0.1)
	check(game.spectator_camera.current and not game.is_killcam_visible(victim), "Despawned killer leaves persistent fallback camera")
	game.match_over = true
	victim._process(0.1)
	check(victim.camera.current and not game.spectator_camera.current and not game.death_camera_active, "Match end restores original camera behavior")
	game.match_over = false
	victim._process(0.1)
	game.paused = true
	victim._physics_process(3.1)
	check(victim.hp == 100 and victim.killer_id == 0 and victim.killer.is_empty() and victim.killer_weapon.is_empty(), "Server respawn resets all killer fields during pause")
	victim._process(0.1)
	check(game.spectator_camera.current, "Paused respawn defers camera switching")
	game.paused = false
	victim._process(0.1)
	check(victim.camera.current and not game.spectator_camera.current, "Unpausing restores respawned player's camera")
	check(victim.snapshot().killer_id == 0, "Alive snapshot clears killer identity")
	victim.protection = 0
	game.combat.damage(victim, victim, 200, "FALL", false)
	victim._process(0.1)
	check(victim.killer_id == 0 and game.spectator_camera.current and not game.is_killcam_visible(victim), "Suicide uses fallback without KILLCAM label")
	# A human killer uses exactly the same path as a negative bot ID.
	game.players[77] = replica
	replica.reset_at(Vector3(2, 0.1, 20))
	victim.reset_at(Vector3(0, 0.1, 27))
	victim._process(0.1)
	victim.protection = 0
	game.combat.damage(victim, replica, 200, "P12", false)
	victim._process(0.1)
	check(victim.killer_id == 77 and game.is_killcam_visible(victim), "Human killer enters live shoulder view")
	var live_state: Dictionary = victim.snapshot()
	live_state.hp = 100.0
	live_state.killer_id = 0
	live_state.killer = ""
	live_state.killer_weapon = ""
	victim.apply_snapshot(live_state)
	victim._process(0.1)
	check(victim.camera.current and not game.spectator_camera.current, "Client respawn snapshot restores first-person camera")
	game.headless = was_headless
	game.leave()
	check(game.menu_camera.current and not game.death_camera_active, "Leaving match restores menu camera")
	await process_frame
	print("KILLCAM ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
