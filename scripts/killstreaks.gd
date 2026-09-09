class_name Killstreaks
extends Node3D

const ULT_KILLS := 4
var game: Node3D
var mines: Dictionary = {}
var visuals: Dictionary = {}
var serial := 0
var nuke_left := 0.0
var nuke_owner := 0
var nuke_name := ""
var nuke_team := 0
var flash_left := 0.0

func earned(p: Fighter) -> void:
	if not game.is_host or game.match_over or p.hp <= 0: return
	p.streak += 1
	p.ult_charge = mini(ULT_KILLS, p.ult_charge + 1)
	match p.streak:
		5:
			p.infinite_left = 60
			p.reload_left = 0
			p.magazines = Arsenal.ammunition()
		10: p.recon_left = 30
		15:
			p.hp = 100
			p.shield_charges = 1
		20:
			if nuke_left <= 0:
				nuke_left = 8
				nuke_owner = p.peer_id
				nuke_name = p.nickname
				nuke_team = p.team

func place(p: Fighter) -> bool:
	if not game.is_host or not game.active or game.match_over or p.hp <= 0 or p.ult_charge < ULT_KILLS or p.rope_active or p.mantle_left > 0: return false
	var direction := Arsenal.direction(p.yaw, 0)
	var probe := p.eye() + direction * 1.2
	if not game.visible_between(p.eye(), probe, [p.get_rid()]): return false
	var ground: Dictionary = game.burn_zones.ground_at(probe, 2.2)
	if ground.is_empty(): return false
	var pos: Vector3 = ground.position + Vector3.UP * 0.06
	for m: Dictionary in mines.values():
		if pos.distance_to(m.p) < 0.65: return false
	var owned := []
	for id in mines:
		if mines[id].owner == p.peer_id: owned.append(id)
	if owned.size() >= 2: remove_mine(owned[0])
	serial += 1
	mines[serial] = {"id": serial, "owner": p.peer_id, "p": pos, "yaw": p.yaw, "arm": 1.0}
	p.ult_charge = 0
	p.protection = 0
	show_mine(mines[serial])
	return true

func triggers(m: Dictionary, p: Fighter) -> bool:
	var source: Fighter = game.players.get(m.owner)
	if source == null or p.hp <= 0 or p.protection > 0 or not game.enemies(source, p): return false
	var delta: Vector3 = p.global_position - m.p
	var flat := Vector3(delta.x, 0, delta.z)
	return absf(delta.y) < 1.3 and flat.length() < 5 and flat.length() > 0.05 and Arsenal.direction(m.yaw, 0).dot(flat.normalized()) > 0.5 and game.visible_between(m.p + Vector3.UP * 0.3, p.eye(), [p.get_rid()])

func advance(dt: float) -> void:
	if not game.is_host or not game.active or game.match_over: return
	if nuke_left > 0:
		nuke_left = maxf(0, nuke_left - dt)
		if nuke_left == 0:
			wipe()
			return
	for id in mines.keys():
		var m: Dictionary = mines[id]
		if not game.players.has(m.owner):
			remove_mine(id)
			continue
		m.arm = maxf(0, m.arm - dt)
		if m.arm > 0: continue
		for p: Fighter in game.players.values():
			if triggers(m, p):
				remove_mine(id)
				game.detonate.rpc(m.p)
				var source: Fighter = game.players[m.owner]
				for target: Fighter in game.players.values():
					var distance: float = (target.eye() - m.p).length()
					if distance < 6 and game.visible_between(m.p + Vector3.UP * 0.3, target.eye(), [target.get_rid()]):
						game.combat.damage(target, source, lerpf(180, 0, distance / 6), "CLAYMORE", false, m.p)
				break

func wipe() -> void:
	# A round-ending event, not directional damage: no shield, spawn guard or kill farming.
	game.match_over = true
	game.winner = nuke_name + " / NUKE VICTORY" if game.config.mode == "FFA" else ("TEAM RELAY / NUKE VICTORY" if nuke_team == 0 else "TEAM EMBER / NUKE VICTORY")
	for p: Fighter in game.players.values():
		if p.hp <= 0: continue
		p.hp = 0
		p.deaths += 1
		p.streak = 0
		p.infinite_left = 0
		p.recon_left = 0
		p.shield_left = 0
		p.killer = nuke_name
		p.killer_weapon = "NUKE"
		p.respawn_left = 3
		p.shape.set_deferred("disabled", true)
	for id in mines.keys(): remove_mine(id)
	game.nuke_effect.rpc()

func snapshot() -> Dictionary:
	return {"mines": mines.values(), "nuke": nuke_left, "name": nuke_name}

func sync(state: Dictionary) -> void:
	if game.is_host: return
	nuke_left = state.get("nuke", 0)
	nuke_name = state.get("name", "")
	var seen := []
	for row: Dictionary in state.get("mines", []):
		seen.append(row.id)
		mines[row.id] = row
		show_mine(row)
	for id in mines.keys():
		if not id in seen: remove_mine(id)

func show_mine(m: Dictionary) -> void:
	if game.headless or visuals.has(m.id): return
	var model := Node3D.new()
	add_child(model)
	model.position = m.p
	model.rotation.y = m.yaw
	WeaponGeometry.block(model, Vector3(0, 0.15, 0), Vector3(0.32, 0.20, 0.09), "cloth")
	for side in [-1, 1]:
		WeaponGeometry.block(model, Vector3(side * 0.12, 0.03, 0), Vector3(0.015, 0.16, 0.015), "steel")
		WeaponGeometry.block(model, Vector3(side * 0.11, 0.19, -0.053), Vector3(0.018, 0.018, 0.01), "red")
	WeaponGeometry.batch(model)
	visuals[m.id] = model

func remove_mine(id: int) -> void:
	mines.erase(id)
	if visuals.has(id):
		visuals[id].queue_free()
		visuals.erase(id)

func clear() -> void:
	for id in mines.keys(): remove_mine(id)
	nuke_left = 0
	nuke_owner = 0
	nuke_name = ""
	flash_left = 0

func _process(dt: float) -> void:
	flash_left = maxf(0, flash_left - dt)
