extends SceneTree

var game: Node3D
var is_server := false
var elapsed := 0.0
var sequence := 0
var started := false
var initial := Vector3.ZERO
var moved := false
var saw_two_humans := false
var expected_humans := 2
var snapshots := 0
var vertical := false
var placed := false
var saw_upper_floor := false
var killcam := false
var forced_kill := false
var saw_killer := false
var saw_respawn := false
var saw_skin := false
var saw_shield := false
var requested_shield := false

func _initialize() -> void:
	is_server = "--server" in OS.get_cmdline_user_args()
	vertical = "--vertical" in OS.get_cmdline_user_args()
	killcam = "--killcam" in OS.get_cmdline_user_args()
	expected_humans = 8 if "--eight" in OS.get_cmdline_user_args() else 2
	call_deferred("start")

func start() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.port = 27993 if vertical else 27991
	if is_server:
		game.host({"server_name": "Network test", "mode": "TDM", "max_players": 8, "bots": 7, "score_limit": 50, "time_limit": 600})
	else:
		game.nickname = "NetworkClient"
		game.loadout = 9
		WeaponSkins.set_design(9, {"receiver": Color.CYAN, "text": "LAN TEST"})
		game.join("127.0.0.1:%s" % game.port)
	started = true

func _physics_process(dt: float) -> bool:
	if not started:
		return false
	elapsed += dt
	if game.active:
		var humans := 0
		for p: Fighter in game.players.values():
			if not p.bot:
				humans += 1
				if p.peer_id != 1 and p.shield_left > 0 and p.shield_charges == 0:
					saw_shield = true
				if p.peer_id != 1 and p.primary == 9:
					var finish: Dictionary = p.skin_designs.get("9", {})
					saw_skin = saw_skin or (finish.get("text", "") == "LAN TEST" and finish.get("receiver", Color.WHITE) == Color.CYAN)
		if humans == expected_humans:
			saw_two_humans = true
		if killcam and is_server:
			for candidate: Fighter in game.players.values():
				candidate.protection = 60
			if humans == 2 and elapsed > 2 and not forced_kill:
				for candidate: Fighter in game.players.values():
					if candidate.bot or candidate.peer_id == 1:
						continue
					for attacker: Fighter in game.players.values():
						if attacker.bot and game.enemies(candidate, attacker):
							candidate.protection = 0
							candidate.shield_left = 0
							game.combat.damage(candidate, attacker, 200, "KILLCAM TEST", false)
							forced_kill = true
							break
		if vertical and is_server and humans == 2 and not placed:
			for candidate: Fighter in game.players.values():
				if not candidate.bot and candidate.peer_id != 1:
					candidate.reset_at(Vector3(-9, 0.15, -13.4))
					candidate.protection = 30
					placed = true
		if not is_server and game.players.has(game.local_id):
			game.set_physics_process(false)
			var p: Fighter = game.players[game.local_id]
			if not requested_shield:
				game.submit_actions.rpc_id(1, 1, {"shield": true})
				requested_shield = true
			if killcam:
				saw_killer = saw_killer or (p.hp <= 0 and p.killer_id < 0 and game.players.has(p.killer_id) and p.killer_weapon == "KILLCAM TEST")
				saw_respawn = saw_respawn or (saw_killer and p.hp > 0 and p.killer_id == 0)
			if snapshots == 0:
				initial = p.target_position
			snapshots += 1
			moved = moved or initial.distance_to(p.target_position) > 1.5
			saw_upper_floor = saw_upper_floor or p.target_position.y > 3.4
			sequence += 1
			var movement := Vector2(-1, 0)
			if vertical:
				movement = Vector2(0, -1) if p.target_position.z > -22.5 else Vector2.ZERO
			# Spoofed HP and positions are deliberately present: server ignores them.
			game.submit_input.rpc_id(1, sequence, {"move": movement, "yaw": 0.0, "pitch": 0.0,
				"hp": 99999, "p": Vector3(900, 900, 900)})
			if p.hp > 100 or p.target_position.length() > 100:
				printerr("FAIL client-authoritative state accepted")
				quit(1)
	if elapsed > (15 if is_server else 9):
		var success: bool = saw_shield and saw_skin and saw_two_humans and game.players.size() == 8 and (is_server or moved)
		if killcam:
			success = success and (forced_kill if is_server else saw_killer and saw_respawn)
			print("NETWORK KILLCAM killed=", forced_kill, " received_killer=", saw_killer, " respawn=", saw_respawn)
		if vertical and not is_server:
			success = success and saw_upper_floor
			print("VERTICAL upper_floor_snapshot=", saw_upper_floor)
		print("NETWORK SKIN received=", saw_skin, " SHIELD received=", saw_shield)
		print("NETWORK ", "HOST" if is_server else "CLIENT", " expected_humans=", expected_humans, " observed=", saw_two_humans, " slots=", game.players.size(), " moved=", moved, " result=", success)
		game.leave()
		quit(0 if success else 1)
	return false
