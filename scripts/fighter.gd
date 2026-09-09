class_name Fighter
extends CharacterBody3D

var game: Node3D
var peer_id := 0
var nickname := "Operator"
var team := 0
var bot := false
var hp := 100.0
var shield_left := 0.0
var shield_charges := 1
var trigger_held := false
var life := 0
var kills := 0
var streak := 0
var ult_charge := 0
var infinite_left := 0.0
var recon_left := 0.0
var shot_serial := 0
var deaths := 0
var yaw := 0.0
var pitch := 0.0
var primary := 0
var weapon := 0
var magazines := Arsenal.ammunition()
var reserves := Arsenal.ammunition(true)
var grenades := 2
var cooldown := 0.0
var melee_left := 0.0
var reload_left := 0.0
var respawn_left := 0.0
var protection := 0.0
var slide_left := 0.0
var slide_lock := 0.0
var last_hurt := 0.0
var crouched := false
var aiming := false
var aim_blend := 0.0
var input_data := {}
var input_age := 0.0
var sequence := 0
var last_sequence := -1
var last_action_sequence := -1
var queued_actions := {}
var target_position := Vector3.ZERO
var target_velocity := Vector3.ZERO
var body_mesh: OperatorModel
var camera: Camera3D
var gun: Node3D
var world_gun: Node3D
var world_weapon := -1
var skin_designs: Dictionary = {}
var shape: CollisionShape3D
var capsule: CapsuleShape3D
var step_clock := 0.0
var blast_shake := 0.0
var bot_route := PackedVector2Array()
var bot_path := PackedVector3Array()
var bot_grenade_cooldown := 0.0
var flash_left := 0.0
var flashes := 1
var radar_left := 0.0
var mantle_left := 0.0
var rope_path := PackedVector3Array()
var rope_active := false
var mantle_start := Vector3.ZERO
var mantle_target := Vector3.ZERO
var bot_think := 0.0
var bot_target := Vector3.ZERO
var bot_phase := 0
var bot_enemy := 0
var bot_acquired := 0.0
var killer := ""
var killer_weapon := ""
var killer_id := 0

func setup(owner_game: Node3D, id: int, display_name: String, team_index: int, ai: bool, loadout: int) -> void:
	game = owner_game
	peer_id = id
	nickname = display_name
	team = team_index
	bot = ai
	primary = Arsenal.primary_id(loadout)
	weapon = primary
	if not bot and peer_id == game.local_id:
		skin_designs = WeaponSkins.loadout_designs(primary)
	name = "Fighter_%s" % id
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(48)
	shape = CollisionShape3D.new()
	capsule = CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	body_mesh = OperatorModel.new()
	add_child(body_mesh)
	body_mesh.setup(team)
	world_gun = body_mesh.weapon_mount
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.near = 0.04
	camera.fov = 88
	add_child(camera)
	gun = WeaponView.new()
	camera.add_child(gun)
	gun.position = Vector3(0.18, -0.22, -0.43)
	gun.visible = false
	if not game.headless:
		var shield := EnergyShield.new()
		shield.fighter = self
		add_child(shield)

func is_local() -> bool:
	return not bot and peer_id == game.local_id

func eye() -> Vector3:
	return global_position + Vector3.UP * (1.0 if crouched else 1.65)

func _process(delta: float) -> void:
	if not game.active:
		return
	if not game.is_host:
		cooldown = maxf(0, cooldown - delta)
		if is_local():
			# Local movement prediction; authoritative snapshots correct drift.
			var error := target_position - global_position
			if error.length() > 3:
				global_position = target_position
			elif error.length() > 0.08:
				global_position += error * minf(delta * 8, 0.4)
		else:
			global_position = global_position.lerp(target_position, minf(delta * 18, 1))
	body_mesh.rotation.y = yaw
	world_gun.rotation.x = pitch
	body_mesh.visible = hp > 0 and not is_local() and not game.history.playing
	body_mesh.scale.y = 0.67 if crouched else 1.0
	if not game.headless and body_mesh.visible:
		var visual_velocity := velocity if game.is_host else target_velocity
		body_mesh.animate(delta, Vector2(visual_velocity.x, visual_velocity.z).length(), pitch, crouched)
	if not game.headless and not is_local() and world_weapon != weapon:
		for child in world_gun.get_children():
			world_gun.remove_child(child)
			child.queue_free()
		var model := WeaponModels.build(weapon)
		WeaponSkins.apply(model, skin_designs.get(str(weapon), {}))
		world_gun.add_child(model)
		world_weapon = weapon
	if is_local():
		gun.visible = hp > 0
		if game.update_death_camera(self, delta):
			return
		camera.make_current()
		camera.rotation = Vector3(pitch, yaw, 0)
		blast_shake = move_toward(blast_shake, 0, delta * 1.8)
		var shake_clock := Time.get_ticks_msec() * 0.001
		camera.rotation += Vector3(sin(shake_clock * 61) * 0.014, 0, sin(shake_clock * 47) * 0.018) * blast_shake
		camera.position.x = sin(shake_clock * 73) * 0.08 * blast_shake
		camera.position.z = cos(shake_clock * 59) * 0.04 * blast_shake
		camera.position.y = lerpf(camera.position.y, 1.0 if crouched else 1.65, minf(delta * 15, 1))
		var sight_ready := aiming and reload_left <= 0 and melee_left <= 0 and mantle_left <= 0 and not rope_active
		aim_blend = move_toward(aim_blend, 1.0 if sight_ready else 0.0, delta / float(WeaponHandling.DATA[weapon].ads))
		var sight_mix := WeaponHandling.smooth(aim_blend)
		var scope := 32.0 if weapon == 3 else 64.0
		camera.fov = lerpf(game.base_fov, scope, sight_mix)
		gun.visible = hp > 0
		var bob := 0.0 # WeaponView owns movement so camera and weapon bob are not stacked.
		var sight_height: float = [0.11, 0.11, 0.06, 0.108, 0.068][Arsenal.FAMILIES[weapon]]
		var hip := Vector3(0.17, -0.18 + bob, -0.22) if weapon != 4 else Vector3(0.18, -0.22 + bob, -0.43)
		var gun_target := hip.lerp(Vector3(0, -sight_height, -0.20 if weapon != 4 else -0.36), sight_mix)
		if reload_left > 0:
			gun_target.y -= 0.10 * WeaponHandling.reload_pose(1 - reload_left / float(Arsenal.DATA[weapon].reload))
		gun.position = gun.position.lerp(gun_target, minf(delta * 16, 1))
		if not game.headless:
			gun.animate(self, delta)

func _physics_process(delta: float) -> void:
	if not game.active or game.match_over:
		return
	if game.is_host:
		bot_grenade_cooldown = maxf(0, bot_grenade_cooldown - delta)
		flash_left = maxf(0, flash_left - delta)
		shield_left = maxf(0, shield_left - delta)
		infinite_left = maxf(0, infinite_left - delta)
		recon_left = maxf(0, recon_left - delta)
		radar_left = maxf(0, radar_left - delta)
		if bot:
			game.bots.update(self, delta)
		input_age += delta
		if not bot and input_age > 0.3:
			input_data = {}
		if hp <= 0:
			queued_actions.clear()
			respawn_left -= delta
			if respawn_left <= 0:
				game.respawn(self)
			return
		protection = maxf(0, protection - delta)
		cooldown = maxf(0, cooldown - delta)
		melee_left = maxf(0, melee_left - delta)
		last_hurt += delta
		if last_hurt > 5:
			hp = minf(100, hp + delta * 18)
		if reload_left > 0:
			reload_left -= delta
			if reload_left <= 0:
				var need: int = mini(Arsenal.DATA[weapon].mag - magazines[weapon], reserves[weapon])
				magazines[weapon] += need
				reserves[weapon] -= need
		input_data.merge(queued_actions, true)
		queued_actions.clear()
		if input_data.get("interact", false): RopeLift.start(self)
		input_data["interact"] = false
		move_character(delta)
		game.combat.actions(self)
	elif is_local() and hp > 0:
		move_character(delta)

func move_character(delta: float) -> void:
	if rope_active:
		if game.is_host: RopeLift.advance(self, delta)
		return
	if mantle_left > 0:
		mantle_left = maxf(0, mantle_left - delta)
		var t := 1 - mantle_left / 0.35
		# Follow the same up-then-forward sweep that Mantle.destination validated.
		# A diagonal interpolation collided with the ledge before reaching its top.
		var next := mantle_start.lerp(mantle_target, maxf(0, (t - 0.5) * 2))
		next.y = lerpf(mantle_start.y, mantle_target.y, minf(t * 2, 1))
		if test_move(global_transform, next - global_position):
			mantle_left = 0
		else:
			global_position = next
		velocity = Vector3.ZERO
		return
	if input_data.get("jump", false) and is_on_floor():
		var ledge := Mantle.destination(self)
		if ledge.is_finite():
			mantle_start = global_position
			mantle_target = ledge
			mantle_left = 0.35
			input_data["jump"] = false
			return
	aiming = bool(input_data.get("ads", false)) and melee_left <= 0
	var axis: Vector2 = input_data.get("move", Vector2.ZERO)
	axis = axis.limit_length()
	var sprint: bool = input_data.get("sprint", false) and not aiming
	var duck: bool = input_data.get("crouch", false)
	slide_left = maxf(0, slide_left - delta)
	slide_lock = maxf(0, slide_lock - delta)
	if duck and sprint and is_on_floor() and velocity.length() > 5 and slide_lock <= 0:
		slide_left = 0.65
		slide_lock = 1.4
	var want_crouch := duck or slide_left > 0
	if crouched and not want_crouch:
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.9, global_position + Vector3.UP * 1.85, 1)
		want_crouch = not get_world_3d().direct_space_state.intersect_ray(q).is_empty()
	crouched = want_crouch
	capsule.height = 1.15 if crouched else 1.8
	shape.position.y = capsule.height * 0.5
	var speed := 8.7 if sprint else 5.8
	if crouched:
		speed = 3.1
	if aiming:
		speed *= 0.68
	speed *= float(Arsenal.DATA[weapon].speed)
	var dir := Basis(Vector3.UP, yaw) * Vector3(axis.x, 0, axis.y)
	if slide_left > 0:
		speed = 10.8
		if dir.length() < 0.1:
			dir = Basis(Vector3.UP, yaw) * Vector3.FORWARD
	velocity.x = move_toward(velocity.x, dir.x * speed, delta * 65)
	velocity.z = move_toward(velocity.z, dir.z * speed, delta * 65)
	if not is_on_floor():
		velocity.y -= 23 * delta
	elif input_data.get("jump", false):
		velocity.y = 7.0
	input_data["jump"] = false
	# Engine collision sweeps implement a small stair step, never teleport through walls.
	var horizontal := Vector3(velocity.x, 0, velocity.z) * delta
	if is_on_floor() and horizontal.length() > 0.001 and test_move(global_transform, horizontal):
		var raised := global_transform
		raised.origin.y += 0.24
		if not test_move(global_transform, Vector3.UP * 0.24) and not test_move(raised, horizontal):
			global_position.y += 0.24
	move_and_slide()
	if global_position.y < -6 and game.is_host:
		game.combat.damage(self, self, 200, "FALL", false)
	step_clock -= delta
	if game.is_host and is_on_floor() and velocity.length() > 2 and step_clock <= 0:
		step_clock = 0.28 if sprint else 0.43
		game.fx.rpc("step", global_position, peer_id, 0)

func reset_at(pos: Vector3) -> void:
	life += 1
	rope_path.clear()
	rope_active = false
	mantle_left = 0
	killer_id = 0
	killer = ""
	killer_weapon = ""
	respawn_left = 0
	blast_shake = 0
	aim_blend = 0
	global_position = pos
	target_position = pos
	velocity = Vector3.ZERO
	hp = 100
	protection = 1.8
	reload_left = 0
	cooldown = 0
	melee_left = 0
	grenades = 2
	flashes = 1
	shield_left = 0
	shield_charges = 1
	streak = 0
	infinite_left = 0
	recon_left = 0
	trigger_held = false
	flash_left = 0
	radar_left = 0
	bot_grenade_cooldown = 4
	last_hurt = 0
	weapon = primary
	magazines = Arsenal.ammunition()
	reserves = Arsenal.ammunition(true)
	input_data = {}
	queued_actions.clear()
	bot_route.clear()
	bot_path.clear()
	bot_enemy = 0
	bot_acquired = 0
	yaw = 0 if pos.z > 0 else PI
	pitch = 0
	# Queue after any pending death disable, including an immediate round reset.
	shape.set_deferred("disabled", false)

func snapshot() -> Dictionary:
	return {"id": peer_id, "name": nickname, "team": team, "bot": bot, "primary": primary,
		"p": global_position, "v": velocity, "yaw": yaw, "pitch": pitch, "hp": hp,
		"kills": kills, "deaths": deaths, "weapon": weapon, "mag": magazines, "reserve": reserves,
		"rewards": [streak, ult_charge, snappedf(infinite_left, 0.1), snappedf(recon_left, 0.1), shot_serial], "skins": skin_designs, "shield": shield_left, "shield_charges": shield_charges, "rope": rope_active, "cooldown": cooldown, "melee": melee_left, "reload": reload_left, "respawn": respawn_left, "guard": protection, "duck": crouched,
		"grenades": grenades, "killer": killer, "killer_weapon": killer_weapon, "killer_id": killer_id,
		"flash": flash_left, "flashes": flashes, "radar": radar_left, "mantle": mantle_left, "life": life}

func apply_snapshot(s: Dictionary) -> void:
	var incoming := WeaponSkins.clean_loadout(s.get("skins", {}), primary)
	if incoming != skin_designs:
		skin_designs = incoming
		world_weapon = -1
	var new_life := life != int(s.get("life", life))
	life = int(s.get("life", life))
	var rewards: Array = s.get("rewards", [0, 0, 0.0, 0.0, 0])
	streak = rewards[0]
	ult_charge = rewards[1]
	infinite_left = rewards[2]
	recon_left = rewards[3]
	shot_serial = rewards[4]
	var was_dead := hp <= 0
	target_position = s.p
	target_velocity = s.v
	hp = s.hp
	kills = s.kills
	deaths = s.deaths
	if weapon != int(s.weapon): aim_blend = 0
	weapon = s.weapon
	magazines = s.mag
	reserves = s.reserve
	rope_active = bool(s.get("rope", false))
	cooldown = float(s.get("cooldown", 0))
	melee_left = float(s.get("melee", 0))
	reload_left = s.reload
	respawn_left = s.respawn
	protection = s.guard
	crouched = s.duck
	if not is_local():
		capsule.height = 1.15 if crouched else 1.8
		shape.position.y = capsule.height * 0.5
	grenades = s.grenades
	killer = s.killer
	killer_weapon = s.killer_weapon
	killer_id = s.get("killer_id", 0)
	flash_left = float(s.get("flash", 0))
	flashes = int(s.get("flashes", 1))
	shield_left = float(s.get("shield", 0))
	shield_charges = int(s.get("shield_charges", 1))
	radar_left = float(s.get("radar", 0))
	if not is_local() or was_dead:
		yaw = s.yaw
		pitch = s.pitch
	if (was_dead or new_life) and hp > 0:
		global_position = s.p
		velocity = Vector3.ZERO
		mantle_left = 0
	shape.disabled = hp <= 0
