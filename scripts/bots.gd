class_name BotDirector
extends RefCounted

var game: Node3D
var routes: BotRoutes

func _init(owner_game: Node3D) -> void:
	game = owner_game
	routes = BotRoutes.new(game.arena)

func update(p: Fighter, dt: float) -> void:
	if p.hp <= 0:
		return
	p.bot_think -= dt
	var skill := BotSkill.profile(int(game.config.get("difficulty", 0)))
	var enemy: Fighter = null
	var nearest: float = skill.range
	for candidate: Fighter in game.players.values():
		if not game.enemies(p, candidate) or candidate.hp <= 0:
			continue
		var distance := p.global_position.distance_to(candidate.global_position)
		if distance < nearest and game.visible_between(p.eye(), candidate.eye(), [p.get_rid(), candidate.get_rid()]):
			nearest = distance
			enemy = candidate
	var shooting := false
	if enemy:
		if p.bot_enemy != enemy.peer_id:
			p.bot_enemy = enemy.peer_id
			p.bot_acquired = 0
		p.bot_acquired += dt
		# Aim at the torso; difficulty affects aim and decisions, never damage/HP.
		var direction := (enemy.eye() - Vector3.UP * 0.25 - p.eye()).normalized()
		var target_yaw := atan2(-direction.x, -direction.z)
		var target_pitch := asin(direction.y)
		var clock := Time.get_ticks_msec() * 0.0025 + p.peer_id * 1.7
		p.yaw = lerp_angle(p.yaw, target_yaw + sin(clock) * float(skill.error), minf(dt * float(skill.tracking), 1))
		p.pitch = lerpf(p.pitch, target_pitch + cos(clock * 1.3) * float(skill.error), minf(dt * float(skill.tracking), 1))
		var burst_time := fmod(maxf(0, p.bot_acquired - float(skill.reaction)), float(skill.burst) + float(skill.pause))
		shooting = p.bot_acquired >= float(skill.reaction) and burst_time < float(skill.burst) and absf(angle_difference(p.yaw, target_yaw)) < 0.12
	else:
		p.bot_enemy = 0
		p.bot_acquired = 0
	var movement := Vector2.ZERO
	if p.bot_think <= 0 and (p.bot_path.is_empty() or p.global_position.y < 0.6):
		p.bot_think = randf_range(0.6, 1.1)
		if enemy and (nearest > 15 or absf(enemy.global_position.y - p.global_position.y) > 2):
			p.bot_target = enemy.global_position
		elif p.bot_path.is_empty() or p.global_position.distance_to(p.bot_target) < 1:
			p.bot_phase = (p.bot_phase + 1) % 4
			var lanes := [-21.0, 0.0, 21.0]
			var lane: float = lanes[randi() % 3]
			var target_z: float = [-29.0, 0.0, 29.0, 0.0][p.bot_phase]
			p.bot_target = Vector3(lane, 0, target_z)
			if p.bot_phase % 2 == 0:
				p.bot_target = routes.patrol(p.peer_id, p.bot_phase)
		p.bot_path = routes.path(p.global_position, p.bot_target)
	while not p.bot_path.is_empty() and p.global_position.distance_to(p.bot_path[0]) < 0.4:
		p.bot_path.remove_at(0)
	if not p.bot_path.is_empty() and (not enemy or nearest > 12 or absf(enemy.global_position.y - p.global_position.y) > 2):
		var next: Vector3 = p.bot_path[0]
		var world_dir := (next - p.global_position).normalized()
		if not enemy:
			p.yaw = lerp_angle(p.yaw, atan2(-world_dir.x, -world_dir.z), dt * 9)
			p.pitch = lerpf(p.pitch, 0, dt * 5)
		var local_dir := Basis(Vector3.UP, -p.yaw) * world_dir
		movement = Vector2(local_dir.x, local_dir.z)
	p.input_data = {"move": movement, "fire": shooting, "ads": enemy != null,
		"sprint": enemy == null, "reload": p.magazines[p.weapon] == 0}
	if enemy and p.bot_acquired > 1.5 and nearest > 7 and nearest < 20 and p.grenades > 0 and p.bot_grenade_cooldown <= 0:
		p.input_data["grenade"] = true
		p.bot_grenade_cooldown = 12
	if p.flash_left > 0.8:
		p.input_data["fire"] = false
		p.input_data["grenade"] = false
