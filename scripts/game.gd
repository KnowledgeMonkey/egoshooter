extends Node3D

const PORT := 27840
var port := PORT
var config := {"server_name": "Relay / Local", "mode": "TDM", "max_players": 8, "bots": 7, "difficulty": 0, "score_limit": 50, "time_limit": 600}
var active := false
var is_host := false
var dedicated := false
var local_id := 1
var players := {}
var scores := [0, 0]
var time_left := 600.0
var match_over := false
var winner := ""
var arena: RelayArena
var combat: CombatSystem
var bots: BotDirector
var audio: ArenaAudio
var discovery: LanDiscovery
var ui: GameUI
var hud: ArenaHUD
var menu_camera: Camera3D
var spectator_camera: Camera3D
var death_camera_active := false
var death_camera_target_id := 0
var death_camera_fallback := Transform3D.IDENTITY
var death_camera_look := Vector3.ZERO
var grenades: Node3D
var effects: Node3D
var projectiles: Node3D
var objectives: RoundObjectives
var history: CombatHistory
var burn_zones: BurnZones
var grenade_serial := 0
var snapshot_clock := 0.0
var input_clock := 0.0
var input_sequence := 0
var pending := {}
var sensitivity := 0.002
var base_fov := 88.0
var nickname := "Operator"
var loadout := 0
var paused := false
var graphics_quality := 1
var headless := false
var connect_clock := 0.0
var connecting := false
var last_address := "127.0.0.1:27840"
var action_sequence := 0

func _ready() -> void:
	headless = DisplayServer.get_name() == "headless"
	dedicated = "--dedicated" in OS.get_cmdline_user_args()
	if not headless:
		PlayerSettings.restore(self)
	history = CombatHistory.new()
	history.game = self
	add_child(history)
	setup_inputs()
	arena = RelayArena.new()
	add_child(arena)
	GraphicsSettings.apply(self, graphics_quality)
	grenades = Node3D.new()
	grenades.name = "Grenades"
	add_child(grenades)
	effects = Node3D.new()
	effects.name = "CombatEffects"
	add_child(effects)
	projectiles = Node3D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
	objectives = RoundObjectives.new()
	objectives.game = self
	add_child(objectives)
	objectives.reset()
	combat = CombatSystem.new(self)
	burn_zones = BurnZones.new()
	burn_zones.game = self
	add_child(burn_zones)
	bots = BotDirector.new(self)
	audio = ArenaAudio.new()
	add_child(audio)
	discovery = LanDiscovery.new()
	discovery.game = self
	add_child(discovery)
	menu_camera = Camera3D.new()
	add_child(menu_camera)
	menu_camera.position = Vector3(26, 13, 32)
	menu_camera.look_at(Vector3(-2, 1.2, -4))
	menu_camera.current = true
	spectator_camera = Camera3D.new()
	spectator_camera.name = "DeathCamera"
	spectator_camera.near = 0.04
	spectator_camera.fov = 78
	add_child(spectator_camera)
	ui = GameUI.new()
	ui.game = self
	add_child(ui)
	hud = ArenaHUD.new()
	hud.game = self
	add_child(hud)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): leave("Verbindung fehlgeschlagen. IP und Firewall prüfen."))
	multiplayer.server_disconnected.connect(func(): leave("Host hat das Spiel beendet."))
	multiplayer.peer_disconnected.connect(_disconnected)
	var args := OS.get_cmdline_user_args()
	if dedicated:
		var server := DedicatedServer.new()
		server.game = self
		add_child(server)
		server.start(args)
		return
	for arg in args:
		if arg.begins_with("--port="):
			port = int(arg.get_slice("=", 1))
	if "--host" in args:
		host(config)
	for arg in args:
		if arg.begins_with("--join="):
			join(arg.get_slice("=", 1))
	if "--smoke" in args:
		var timer := get_tree().create_timer(12)
		timer.timeout.connect(func():
			print("SMOKE active=", active, " players=", players.size(), " scores=", scores)
			get_tree().quit(0 if active and players.size() > 1 else 1))

func setup_inputs() -> void:
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "jump": KEY_SPACE,
		"sprint": KEY_SHIFT, "crouch": KEY_CTRL, "reload": KEY_R, "grenade": KEY_G, "flash": KEY_F, "interact": KEY_E, "melee": KEY_V, "switch": KEY_Q, "scoreboard": KEY_TAB}
	for action in keys:
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)

func host(settings: Dictionary, as_dedicated: bool = false) -> bool:
	dedicated = as_dedicated
	var peer := ENetMultiplayerPeer.new()
	if dedicated:
		peer.set_bind_ip(settings.get("bind", "0.0.0.0"))
	var err := peer.create_server(port, 8 if dedicated else 7)
	if err != OK:
		ui.message("Port %s ist belegt oder nicht verfügbar (Fehler %s)." % [port, err])
		if dedicated:
			printerr("SERVER ERROR: UDP %s konnte nicht gebunden werden (Fehler %s)." % [port, err])
		return false
	config = settings.duplicate()
	config["difficulty"] = clampi(int(config.get("difficulty", 0)), 0, 3)
	config.max_players = clampi(int(config.max_players), 2, 8)
	config.bots = clampi(int(config.bots), 0, config.max_players if dedicated else config.max_players - 1)
	config.score_limit = clampi(int(config.score_limit), 1, 200)
	config.time_limit = clampi(int(config.time_limit), 60, 1800)
	multiplayer.multiplayer_peer = peer
	local_id = 0 if dedicated else 1
	is_host = true
	active = true
	match_over = false
	winner = ""
	scores = [0, 0]
	time_left = config.time_limit
	if not dedicated:
		add_player(1, nickname, false, loadout)
	fill_bots()
	objectives.reset()
	enter_match()
	return true

func join(address: String) -> void:
	last_address = address.strip_edges()
	save_preferences()
	var host_address := address.strip_edges()
	if host_address.contains(":"):
		port = int(host_address.get_slice(":", 1))
		host_address = host_address.get_slice(":", 0)
	if not host_address.is_valid_ip_address() or port < 1024 or port > 65535:
		ui.message("Bitte eine gültige lokale IPv4-Adresse eingeben.")
		return
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host_address, port)
	if err != OK:
		ui.message("Verbindung konnte nicht gestartet werden: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	is_host = false
	connecting = true
	connect_clock = 0
	ui.message("Verbinde mit %s …" % host_address)

func _connected() -> void:
	local_id = multiplayer.get_unique_id()
	register_player.rpc_id(1, nickname, loadout)

@rpc("any_peer", "call_remote", "reliable")
func register_player(display_name: String, selected: int) -> void:
	if not is_host or not active:
		return
	var id := multiplayer.get_remote_sender_id()
	if players.has(id):
		return
	var humans := 0
	for p: Fighter in players.values():
		if not p.bot:
			humans += 1
	if humans >= config.max_players:
		rejected.rpc_id(id, "Server ist voll.")
		return
	for p: Fighter in players.values():
		if p.bot and (dedicated or players.size() >= config.max_players):
			remove_player(p.peer_id)
			break
	add_player(id, display_name.strip_edges().left(20), false, clampi(selected, 0, 3))
	welcome.rpc_id(id, config)
	print("JOIN accepted ", id, " roster=", players.size())

@rpc("authority", "call_remote", "reliable")
func rejected(reason: String) -> void:
	leave(reason)

@rpc("authority", "call_remote", "reliable")
func welcome(settings: Dictionary) -> void:
	config = settings
	active = true
	connecting = false
	match_over = false
	enter_match()

func enter_match() -> void:
	ui.hide_menu()
	paused = false
	if not headless:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func add_player(id: int, display_name: String, ai: bool, selected: int) -> Fighter:
	var counts := [0, 0]
	for p: Fighter in players.values():
		counts[p.team] += 1
	var p := Fighter.new()
	p.setup(self, id, display_name if not display_name.is_empty() else "Operator", 0 if counts[0] <= counts[1] else 1, ai, selected)
	players[id] = p
	add_child(p)
	respawn(p)
	return p

func fill_bots() -> void:
	var target: int = mini(config.max_players, config.bots + (0 if dedicated else 1))
	var id := -1
	while players.size() < target:
		while players.has(id):
			id -= 1
		add_player(id, ["Rook", "Mica", "Cinder", "Atlas", "Echo", "Vale", "Finch"][(-id - 1) % 7] + " [BOT]", true, (-id - 1) % 4)

func restart_round() -> void:
	if not is_host or not dedicated or not active:
		return
	history.stop()
	history.frames.clear()
	scores = [0, 0]
	time_left = config.time_limit
	winner = ""
	match_over = false
	for grenade in grenades.get_children():
		grenades.remove_child(grenade)
		grenade.queue_free()
	burn_zones.clear()
	for effect in effects.get_children():
		effects.remove_child(effect)
		effect.queue_free()
	objectives.reset()
	for projectile in projectiles.get_children():
		projectiles.remove_child(projectile)
		projectile.queue_free()
	for fighter: Fighter in players.values():
		fighter.kills = 0
		fighter.deaths = 0
		respawn(fighter)
	snapshot_clock = 0.05

func remove_player(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

func _disconnected(id: int) -> void:
	if is_host:
		remove_player(id)
		fill_bots()

func leave(reason: String = "") -> void:
	history.stop()
	history.frames.clear()
	death_camera_active = false
	death_camera_target_id = 0
	active = false
	connecting = false
	match_over = false
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	is_host = false
	for id in players.keys():
		remove_player(id)
	for grenade in grenades.get_children():
		grenade.queue_free()
	burn_zones.clear()
	for effect in effects.get_children():
		effects.remove_child(effect)
		effect.queue_free()
	objectives.reset()
	for projectile in projectiles.get_children():
		projectiles.remove_child(projectile)
		projectile.queue_free()
	menu_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.main_menu()
	ui.message(reason)

func enemies(a: Fighter, b: Fighter) -> bool:
	return a != b and (config.mode == "FFA" or a.team != b.team)

func death_camera_killer(victim: Fighter) -> Fighter:
	if victim.hp > 0 or victim.killer_id == 0 or victim.killer_id == victim.peer_id:
		return null
	var target: Fighter = players.get(victim.killer_id)
	if not is_instance_valid(target) or target.is_queued_for_deletion() or target.hp <= 0:
		return null
	return target

func is_killcam_visible(victim: Fighter) -> bool:
	return not headless and not match_over and death_camera_active and spectator_camera.current \
		and death_camera_target_id == victim.killer_id and death_camera_killer(victim) != null

# Returns true while normal first-person camera animation must be suppressed.
# Only the local Fighter calls this; remote/bot cameras never become current.
func update_death_camera(victim: Fighter, delta: float) -> bool:
	if headless or paused:
		return true
	if not active or not victim.is_local():
		return true
	if victim.hp > 0 or match_over:
		history.stop()
		death_camera_active = false
		death_camera_target_id = 0
		victim.camera.make_current()
		return false
	if not death_camera_active:
		history.begin(victim.killer_id)
		death_camera_active = true
		death_camera_target_id = 0
		# Capture once: even later authoritative corpse corrections cannot move it.
		death_camera_fallback = victim.camera.global_transform
		death_camera_fallback.origin = victim.eye() + Vector3.UP * 0.5
	var target := death_camera_killer(victim)
	if target == null:
		history.stop()
		death_camera_target_id = 0
		spectator_camera.global_transform = death_camera_fallback
	else:
		if history.advance(delta, spectator_camera):
			death_camera_target_id = target.peer_id
			return true
		spectator_camera.fov = 78
		var pivot := target.eye()
		var forward := Arsenal.direction(target.yaw, target.pitch)
		var shoulder := Basis(Vector3.UP, target.yaw) * Vector3.RIGHT * 0.45
		var destination := pivot - forward * 2.4 + Vector3.UP * 0.5 + shoulder
		if death_camera_target_id != target.peer_id:
			# Cut on entry; never fly across the map from the victim to the killer.
			spectator_camera.global_position = destination
			death_camera_look = pivot
		else:
			var weight := 1.0 - exp(-delta * 8.0)
			spectator_camera.global_position = spectator_camera.global_position.lerp(destination, weight)
			death_camera_look = death_camera_look.lerp(pivot, weight)
		spectator_camera.look_at(death_camera_look)
		death_camera_target_id = target.peer_id
	spectator_camera.make_current()
	return true

func visible_between(a: Vector3, b: Vector3, exclude: Array = []) -> bool:
	var rids: Array[RID] = []
	rids.assign(exclude)
	var ray := PhysicsRayQueryParameters3D.create(a, b, 1, rids)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func respawn(p: Fighter) -> void:
	var best := arena.spawn_points[0]
	var best_score := -INF
	for candidate in arena.spawn_points:
		var score := randf_range(0, 2)
		var home := candidate.z > 0 if p.team == 0 else candidate.z < 0
		if home and config.mode != "FFA":
			score += 12
		for other: Fighter in players.values():
			if other == p or other.hp <= 0:
				continue
			var distance := candidate.distance_to(other.global_position)
			if distance < 2:
				score -= 1000
			if enemies(p, other):
				score -= maxf(0, 30 - distance) * 3
				if visible_between(candidate + Vector3.UP * 1.65, other.eye()):
					score -= 65
				if other.cooldown > 0 and distance < 25:
					score -= 25
		if score > best_score:
			best_score = score
			best = candidate
	p.reset_at(best)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		save_preferences()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and active:
		paused = not paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
		if paused:
			ui.pause_menu()
		else:
			ui.hide_menu()
	if not active or paused or match_over or not players.has(local_id):
		return
	var p: Fighter = players[local_id]
	if p.hp <= 0:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		p.yaw = wrapf(p.yaw - event.relative.x * sensitivity, -PI, PI)
		p.pitch = clampf(p.pitch - event.relative.y * sensitivity, -1.5, 1.5)
	for action in ["jump", "reload", "grenade", "flash", "switch", "melee", "interact"]:
		if event.is_action_pressed(action):
			pending[action] = true

func _physics_process(dt: float) -> void:
	if connecting:
		connect_clock += dt
		if connect_clock > 10:
			leave("Zeitüberschreitung. Host-IP, Port und Netzwerk prüfen.")
	if not active:
		return
	if players.has(local_id) and not players[local_id].bot:
		var p: Fighter = players[local_id]
		var command := {"move": Vector2.ZERO, "yaw": p.yaw, "pitch": p.pitch}
		if p.hp > 0 and not paused and not match_over and not headless:
			command.merge({"move": Input.get_vector("left", "right", "forward", "back"),
				"sprint": Input.is_action_pressed("sprint"), "crouch": Input.is_action_pressed("crouch"),
				"ads": Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT), "fire": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)}, true)
			if is_host:
				command.merge(pending)
			elif not pending.is_empty():
				action_sequence += 1
				submit_actions.rpc_id(1, action_sequence, pending)
		pending.clear()
		p.input_data = command.duplicate()
		p.input_age = 0
		if not is_host:
			input_sequence += 1
			submit_input.rpc_id(1, input_sequence, command)
	if is_host:
		burn_zones.advance(dt)
		objectives.advance(dt)
		if not match_over:
			time_left = maxf(0, time_left - dt)
			if time_left <= 0:
				finish_match()
		snapshot_clock += dt
		if snapshot_clock >= 0.05:
			snapshot_clock = 0
			var roster := []
			for p: Fighter in players.values():
				roster.append(p.snapshot())
			history.record(roster)
			var frags := []
			for g: FragGrenade in grenades.get_children():
				frags.append({"id": int(g.name), "p": g.global_position, "owner": g.owner_id, "kind": g.kind})
			var packet := var_to_bytes([roster, scores, time_left, match_over, winner, frags, burn_zones.snapshot(), objectives.snapshot()]).compress(FileAccess.COMPRESSION_DEFLATE)
			receive_state.rpc(packet)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func submit_input(seq: int, command: Dictionary) -> void:
	if not is_host or not active:
		return
	var id := multiplayer.get_remote_sender_id()
	if not players.has(id):
		return
	var p: Fighter = players[id]
	if seq <= p.last_sequence:
		return
	var axis = command.get("move", Vector2.ZERO)
	var y = command.get("yaw", 0.0)
	var tilt = command.get("pitch", 0.0)
	if not axis is Vector2 or not axis.is_finite() or not (y is float or y is int) or not (tilt is float or tilt is int):
		return
	if not is_finite(float(y)) or not is_finite(float(tilt)):
		return
	p.last_sequence = seq
	p.yaw = wrapf(float(y), -PI, PI)
	p.pitch = clampf(float(tilt), -1.5, 1.5)
	var clean := {"move": axis.limit_length()}
	for flag in ["sprint", "crouch", "ads", "fire"]:
		clean[flag] = command.get(flag, false) == true
	p.input_data = clean
	p.input_age = 0

@rpc("any_peer", "call_remote", "reliable", 3)
func submit_actions(seq: int, actions: Dictionary) -> void:
	if not is_host or not active or match_over:
		return
	var p: Fighter = players.get(multiplayer.get_remote_sender_id())
	if p == null or p.hp <= 0 or seq <= p.last_action_sequence:
		return
	p.last_action_sequence = seq
	for action in ["jump", "reload", "grenade", "flash", "switch", "melee", "interact"]:
		if actions.get(action, false) == true:
			p.queued_actions[action] = true

func save_preferences() -> void:
	if not headless and not dedicated:
		if PlayerSettings.save(self) != OK and is_instance_valid(ui):
			ui.message("Einstellungen konnten nicht gespeichert werden.")

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func receive_state(packet: PackedByteArray) -> void:
	if not active:
		return
	var decoded: Array = bytes_to_var(packet.decompress_dynamic(65536, FileAccess.COMPRESSION_DEFLATE))
	if decoded.size() < 7 or decoded.size() > 8:
		return
	var roster: Array = decoded[0]
	history.record(roster)
	var team_scores: Array = decoded[1]
	var remaining: float = decoded[2]
	var ended: bool = decoded[3]
	var result: String = decoded[4]
	var new_round := match_over and not ended
	if new_round:
		history.stop()
		history.frames.clear()
	var frags: Array = decoded[5]
	burn_zones.sync(decoded[6])
	if decoded.size() > 7: objectives.sync(decoded[7])
	scores = team_scores
	time_left = remaining
	match_over = ended
	winner = result
	var seen := []
	for state: Dictionary in roster:
		seen.append(state.id)
		if not players.has(state.id):
			var p := Fighter.new()
			p.setup(self, state.id, state.name, state.team, state.bot, state.primary)
			players[state.id] = p
			add_child(p)
			p.position = state.p
		players[state.id].apply_snapshot(state)
		if new_round and state.id == local_id:
			players[state.id].global_position = state.p
			players[state.id].velocity = Vector3.ZERO
			players[state.id].yaw = state.yaw
			players[state.id].pitch = state.pitch
	for id in players.keys():
		if not id in seen:
			remove_player(id)
	var frag_ids := []
	for data: Dictionary in frags:
		frag_ids.append(str(data.id))
		if not grenades.has_node(str(data.id)):
			create_grenade(data.id, data.owner, data.p, Vector3.ZERO, data.get("kind", "frag"))
		grenades.get_node(str(data.id)).position = data.p
	for g in grenades.get_children():
		if not str(g.name) in frag_ids:
			g.queue_free()

func check_win() -> void:
	if config.mode != "FFA":
		if scores.max() >= config.score_limit:
			finish_match()
	else:
		for p: Fighter in players.values():
			if p.kills >= config.score_limit:
				finish_match()

func finish_match() -> void:
	match_over = true
	if config.mode != "FFA":
		winner = "DRAW" if scores[0] == scores[1] else ("TEAM RELAY WINS" if scores[0] > scores[1] else "TEAM EMBER WINS")
	else:
		var best := -1
		var leaders := []
		for p: Fighter in players.values():
			if p.kills > best:
				best = p.kills
				leaders = [p.nickname]
			elif p.kills == best:
				leaders.append(p.nickname)
		winner = "%s WINS" % leaders[0] if leaders.size() == 1 else "DRAW"

func spawn_grenade(owner_id: int, pos: Vector3, speed: Vector3, kind: String = "frag") -> void:
	grenade_serial += 1
	create_grenade(grenade_serial, owner_id, pos, speed, kind)

func create_grenade(id: int, owner_id: int, pos: Vector3, speed: Vector3, kind: String = "frag") -> void:
	var g := FragGrenade.new()
	g.game = self
	g.owner_id = owner_id
	g.kind = kind
	g.fuse = 1.6 if kind == "flash" else 2.6
	g.name = str(id)
	grenades.add_child(g)
	g.position = pos
	g.linear_velocity = speed
	g.angular_velocity = Vector3(4, 2, 3)

@rpc("authority", "call_local", "reliable")
func remove_grenade(id: int) -> void:
	var g := grenades.get_node_or_null(str(id))
	if g:
		g.queue_free()

@rpc("authority", "call_local", "unreliable")
func fx(kind: String, pos: Vector3, id: int, variant: int) -> void:
	audio.play_at(kind, pos, id == local_id, variant)
	if kind == "shot" and id == local_id and players.has(id):
		var p: Fighter = players[id]
		p.pitch = minf(1.5, p.pitch + float(Arsenal.DATA[variant].recoil) * (0.7 if p.aiming else 1.0))
		# WeaponView drives the visual recoil spring from confirmed ammunition changes.
	if kind == "flash" and not headless:
		CombatVisuals.flash(effects, pos)
	if kind == "explosion" and not headless:
		CombatVisuals.explosion(effects, pos)

@rpc("authority", "call_local", "reliable")
func detonate(pos: Vector3) -> void:
	audio.play_at("explosion", pos, false)
	if not headless:
		CombatVisuals.explosion(effects, pos)
		if players.has(local_id):
			var p: Fighter = players[local_id]
			p.blast_shake = maxf(p.blast_shake, clampf(1 - p.eye().distance_to(pos) / 28.0, 0, 1))

@rpc("authority", "call_local", "unreliable")
func impact(pos: Vector3) -> void:
	if not headless:
		CombatVisuals.impact(effects, pos)

@rpc("authority", "call_local", "unreliable")
func tracer(a: Vector3, b: Vector3) -> void:
	if headless or a.distance_to(b) < 0.01:
		return
	var line := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.012, 0.012, a.distance_to(b))
	line.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffe3a5")
	line.material_override = mat
	effects.add_child(line)
	line.position = (a + b) / 2
	line.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	get_tree().create_timer(0.045).timeout.connect(line.queue_free)

@rpc("authority", "call_local", "reliable")
func feedback(head: bool) -> void:
	hud.hit_time = 0.18
	hud.head_hit = head
	audio.play_at("hit", Vector3.ZERO, true)

@rpc("authority", "call_local", "reliable")
func kill_notice(attacker: String, victim: String, weapon_name: String, head: bool) -> void:
	hud.feed.push_front({"text": "%s   ›   %s   ›   %s%s" % [attacker, weapon_name, victim, "  [HS]" if head else ""], "until": Time.get_ticks_msec() + 5500})
	if hud.feed.size() > 5:
		hud.feed.pop_back()

@rpc("authority", "call_local", "reliable")
func combat_notice(kind: String, actor_life: int, origin: Vector3, victim: String = "") -> void:
	var p: Fighter = players.get(local_id)
	if not active or p == null or p.life != actor_life:
		return
	hud.notice_life = actor_life
	if kind == "hurt":
		hud.hurt_origin = origin
		hud.hurt_time = 0.9
	elif kind == "elimination":
		hud.elimination_name = victim
		hud.elimination_time = 2.0
		audio.play_at("confirm", p.eye(), true)
