class_name CombatSystem
extends RefCounted

var game: Node3D
const BLAST_RADIUS := 14.0
const BLAST_DAMAGE := 180.0

func _init(owner_game: Node3D) -> void:
	game = owner_game

func actions(p: Fighter) -> void:
	if not game.is_host or not game.active or game.match_over or p.hp <= 0:
		return
	var cmd := p.input_data
	if cmd.get("melee", false):
		melee(p)
	cmd["melee"] = false
	if p.melee_left > 0 or p.mantle_left > 0:
		return
	if cmd.get("switch", false):
		p.weapon = 4 if p.weapon == p.primary else p.primary
		p.reload_left = 0
		p.cooldown = maxf(p.cooldown, 0.25)
		cmd["switch"] = false
	if cmd.get("reload", false) and p.reload_left <= 0 and p.magazines[p.weapon] < Arsenal.DATA[p.weapon].mag and p.reserves[p.weapon] > 0:
		p.reload_left = Arsenal.DATA[p.weapon].reload
		game.fx.rpc("reload", p.eye(), p.peer_id, 0)
	cmd["reload"] = false
	if cmd.get("grenade", false) and p.grenades > 0:
		p.grenades -= 1
		p.protection = 0
		var dir := Arsenal.direction(p.yaw, p.pitch)
		game.spawn_grenade(p.peer_id, p.eye() + dir * 0.6, dir * 17 + Vector3.UP * 4)
	cmd["grenade"] = false
	if cmd.get("flash", false) and p.flashes > 0:
		p.flashes -= 1
		p.protection = 0
		var dir := Arsenal.direction(p.yaw, p.pitch)
		game.spawn_grenade(p.peer_id, p.eye() + dir * 0.6, dir * 16 + Vector3.UP * 4, "flash")
	cmd["flash"] = false
	if cmd.get("fire", false) and p.cooldown <= 0 and p.reload_left <= 0:
		if p.magazines[p.weapon] > 0:
			shoot(p)
		else:
			cmd["reload"] = true

func shoot(p: Fighter) -> void:
	p.radar_left = 1.5
	var w: Dictionary = Arsenal.DATA[p.weapon]
	p.magazines[p.weapon] -= 1
	p.cooldown = w.rate
	p.protection = 0
	var hit_any := false
	var head_any := false
	if p.weapon == 3:
		var spread: float = w.spread * (0.025 if p.aiming else 1.0)
		var projectile := RifleProjectile.new()
		projectile.game = game
		projectile.owner_id = p.peer_id
		projectile.speed = Arsenal.direction(p.yaw + randf_range(-spread, spread), p.pitch + randf_range(-spread, spread)) * 220
		projectile.position = p.eye()
		game.projectiles.add_child(projectile)
	for pellet in range(0 if p.weapon == 3 else int(w.pellets)):
		var spread: float = w.spread
		if p.aiming:
			spread *= 0.025 if p.weapon == 3 else (0.85 if p.weapon == 2 else 0.2)
		if p.velocity.length() > 4:
			spread *= 1.6
		var direction := Arsenal.direction(p.yaw + randf_range(-spread, spread), p.pitch + randf_range(-spread, spread))
		var start := p.eye()
		var end: Vector3 = start + direction * float(w.range)
		var query := PhysicsRayQueryParameters3D.create(start, end, 3, [p.get_rid()])
		var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
		if not p.bot and p.peer_id != 1 and not game.history.frames.is_empty():
			var peer: ENetPacketPeer = game.multiplayer.multiplayer_peer.get_peer(p.peer_id)
			if peer != null:
				var latency := minf(0.2, peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME) / 2000.0)
				hit = game.history.rewind_hit(p, start, end, latency)
		if not hit.is_empty():
			end = hit.position
			if pellet == 0:
				game.impact.rpc(end)
			if hit.collider is Fighter:
				var target: Fighter = hit.collider
				var relative_height: float = hit.position.y - hit.get("origin", target.global_position).y
				var head := relative_height > (1.0 if target.crouched else 1.48)
				var multiplier := 1.65 if head else (0.78 if relative_height < 0.7 else 1.0)
				var distance := start.distance_to(end)
				var falloff := lerpf(1, 0.55, clampf((distance - float(w.range) * 0.3) / (float(w.range) * 0.7), 0, 1))
				if damage(target, p, float(w.damage) * multiplier * falloff, w.short, head):
					hit_any = true
					head_any = head_any or head
		if pellet == 0:
			game.tracer.rpc(start + Vector3.DOWN * 0.18, end)
	game.fx.rpc("shot", p.eye(), p.peer_id, p.weapon)
	if hit_any and not p.bot:
		game.feedback.rpc_id(p.peer_id, head_any)
	if p.bot:
		p.pitch += float(w.recoil) * 0.3

func damage(target: Fighter, source: Fighter, amount: float, weapon_name: String, head: bool, origin: Vector3 = Vector3.INF) -> bool:
	if target.hp <= 0 or target.protection > 0:
		return false
	if target != source and not game.enemies(target, source):
		return false
	target.hp = maxf(0, target.hp - amount)
	target.last_hurt = 0
	if not target.bot and (target.peer_id == game.multiplayer.get_unique_id() or target.peer_id in game.multiplayer.get_peers()):
		game.combat_notice.rpc_id(target.peer_id, "hurt", target.life, origin if origin.is_finite() else source.eye())
	if target.hp <= 0:
		target.deaths += 1
		game.objectives.death(target)
		target.respawn_left = 3
		target.killer = source.nickname
		target.killer_weapon = weapon_name
		target.killer_id = source.peer_id if source != target else 0
		target.shape.set_deferred("disabled", true)
		if source != target:
			source.kills += 1
			if not source.bot and (source.peer_id == game.multiplayer.get_unique_id() or source.peer_id in game.multiplayer.get_peers()):
				game.combat_notice.rpc_id(source.peer_id, "elimination", source.life, target.eye(), target.nickname)
			if game.config.mode in ["TDM", "FFA"]: game.scores[source.team] += 1
		game.kill_notice.rpc(source.nickname, target.nickname, weapon_name, head)
		game.fx.rpc("death", target.eye(), target.peer_id, 0)
		game.check_win()
	return true

func explode(pos: Vector3, owner_id: int) -> void:
	if not game.is_host or not game.active or game.match_over:
		return
	game.detonate.rpc(pos)
	if not game.players.has(owner_id):
		return
	game.burn_zones.ignite(pos, owner_id)
	var source: Fighter = game.players[owner_id]
	for target: Fighter in game.players.values():
		var distance := pos.distance_to(target.eye())
		if distance < BLAST_RADIUS and game.visible_between(pos + Vector3.UP * 0.15, target.eye(), [target.get_rid()]):
			damage(target, source, lerpf(BLAST_DAMAGE, 0, distance / BLAST_RADIUS), "FRAG", false, pos)

func flash(pos: Vector3) -> void:
	if not game.is_host or not game.active or game.match_over: return
	game.fx.rpc("flash", pos, 0, 0)
	for target: Fighter in game.players.values():
		var offset := pos - target.eye()
		var distance := offset.length()
		if target.hp <= 0 or distance > 20 or not game.visible_between(pos, target.eye(), [target.get_rid()]): continue
		var facing := Arsenal.direction(target.yaw, target.pitch).dot(offset.normalized())
		var strength := (1 - distance / 20) * (1.0 if facing > 0.2 else 0.3)
		target.flash_left = maxf(target.flash_left, strength * 4)

func melee(p: Fighter) -> void:
	if not game.is_host or not game.active or game.match_over or p.hp <= 0 or p.melee_left > 0 or p.mantle_left > 0:
		return
	p.melee_left = 0.65
	p.aiming = false
	p.cooldown = maxf(p.cooldown, p.melee_left)
	p.reload_left = 0
	p.protection = 0
	game.fx.rpc("melee", p.eye(), p.peer_id, 0)
	var forward := Arsenal.direction(p.yaw, p.pitch)
	var nearest: Fighter = null
	var best := 2.1
	for target: Fighter in game.players.values():
		if target == p or target.hp <= 0 or not game.enemies(p, target):
			continue
		var point := target.global_position + Vector3.UP * (0.75 if target.crouched else 1.2)
		var offset := point - p.eye()
		if offset.length() >= best or forward.dot(offset.normalized()) < 0.65:
			continue
		var ray := PhysicsRayQueryParameters3D.create(p.eye(), point, 3, [p.get_rid()])
		var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider == target:
			nearest = target
			best = offset.length()
	if nearest != null and damage(nearest, p, 65, "MELEE", false) and not p.bot:
		game.feedback.rpc_id(p.peer_id, false)
