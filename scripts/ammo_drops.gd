class_name AmmoDrops
extends Node3D
var game: Node3D
var rows: Array = []
var visuals := {}
var serial := 0
func drop(p: Fighter) -> void:
	if not game.is_host: return
	serial += 1
	rows.append({"id": serial, "p": p.global_position + Vector3.UP * 0.25, "left": 30.0})
	if rows.size() > 32: rows.pop_front()
func advance(dt: float) -> void:
	if not game.is_host or game.match_over: return
	for i in range(rows.size() - 1, -1, -1):
		var row: Dictionary = rows[i]
		row.left -= dt
		var taken := false
		for p: Fighter in game.players.values():
			if p.hp <= 0 or p.global_position.distance_to(row.p) > 1.5 or not game.visible_between(p.eye(), row.p, [p.get_rid()]): continue
			for weapon in [p.primary, 4]:
				var cap: int = Arsenal.DATA[weapon].reserve
				if p.reserves[weapon] < cap:
					p.reserves[weapon] = mini(cap, p.reserves[weapon] + int(Arsenal.DATA[weapon].mag))
					taken = true
			if taken: break
		if taken or row.left <= 0: rows.remove_at(i)
	refresh()
func sync(data: Array) -> void:
	rows = data
	refresh()
func clear() -> void:
	rows.clear()
	refresh()
func refresh() -> void:
	if game.headless: return
	var seen := []
	for row: Dictionary in rows:
		seen.append(row.id)
		if visuals.has(row.id): continue
		var box := Node3D.new()
		add_child(box)
		box.position = row.p
		WeaponGeometry.block(box, Vector3.ZERO, Vector3(0.4, 0.22, 0.26), "cloth")
		WeaponGeometry.block(box, Vector3(0, 0.12, 0), Vector3(0.42, 0.025, 0.28), "edge")
		WeaponGeometry.batch(box)
		var label := Label3D.new()
		label.text = "+ MUNITION"
		label.font_size = 36
		label.pixel_size = 0.004
		label.position.y = 0.4
		label.modulate = Color("9deaff")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		box.add_child(label)
		visuals[row.id] = box
	for id in visuals.keys():
		if not id in seen:
			visuals[id].queue_free()
			visuals.erase(id)
