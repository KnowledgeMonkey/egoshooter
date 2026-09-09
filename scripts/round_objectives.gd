class_name RoundObjectives
extends Node3D

var game: Node3D
var points: Array = []
var tags: Array = []
var score_clock := 0.0
var serial := 0
var visuals := {}

func reset() -> void:
	points = []
	tags = []
	score_clock = 0
	for pos in [Vector3(-21, 0.1, -12), Vector3(0, 0.1, 0), Vector3(21, 0.1, 12)]:
		points.append({"p": pos, "owner": -1, "capture": 0.0, "team": -1})
	refresh_visuals()

func death(victim: Fighter) -> void:
	if game.config.mode != "KC": return
	serial += 1
	tags.append({"id": serial, "p": victim.global_position + Vector3.UP * 0.7, "team": victim.team, "left": 30.0})

func advance(dt: float) -> void:
	if not game.is_host or game.match_over: return
	if game.config.mode == "DOM":
		for point: Dictionary in points:
			var teams := [0, 0]
			for p: Fighter in game.players.values():
				if p.hp > 0 and absf(p.global_position.y - point.p.y) < 1.5 and p.global_position.distance_to(point.p) < 4 and game.visible_between(p.eye(), point.p + Vector3.UP * 0.2):
					teams[p.team] += 1
			var team := 0 if teams[0] > 0 and teams[1] == 0 else (1 if teams[1] > 0 and teams[0] == 0 else -1)
			if team < 0: continue
			if point.team != team: point.capture = 0
			point.team = team
			if point.owner != team:
				point.capture += dt
				if point.capture >= 4:
					point.owner = team
					point.capture = 0
		score_clock += dt
		if score_clock >= 2:
			score_clock -= 2
			for point: Dictionary in points:
				if point.owner >= 0: game.scores[point.owner] += 1
			game.check_win()
	elif game.config.mode == "KC":
		for i in range(tags.size() - 1, -1, -1):
			var tag: Dictionary = tags[i]
			tag.left -= dt
			var taken := false
			for p: Fighter in game.players.values():
				if p.hp > 0 and p.eye().distance_to(tag.p) < 1.8 and game.visible_between(p.eye(), tag.p):
					if p.team != tag.team: game.scores[p.team] += 1
					taken = true
					break
			if taken or tag.left <= 0: tags.remove_at(i)
		game.check_win()
	refresh_visuals()

func snapshot() -> Dictionary:
	return {"points": points, "tags": tags}

func sync(state: Dictionary) -> void:
	points = state.get("points", [])
	tags = state.get("tags", [])
	refresh_visuals()

func refresh_visuals() -> void:
	if game.headless: return
	var wanted := {}
	var rows: Array = points if game.config.mode == "DOM" else (tags if game.config.mode == "KC" else [])
	for i in rows.size():
		var row: Dictionary = rows[i]
		var key := str(row.get("id", i))
		wanted[key] = true
		if not visuals.has(key):
			var mesh := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 1.1 if game.config.mode == "DOM" else 0.18
			cylinder.bottom_radius = cylinder.top_radius
			cylinder.height = 0.1 if game.config.mode == "DOM" else 0.4
			mesh.mesh = cylinder
			mesh.material_override = StandardMaterial3D.new()
			add_child(mesh)
			if game.config.mode == "DOM":
				var label := Label3D.new()
				label.text = ["A", "B", "C"][i]
				label.font_size = 64
				label.pixel_size = 0.014
				label.position.y = 1.3
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				mesh.add_child(label)
			visuals[key] = mesh
		var visual: MeshInstance3D = visuals[key]
		visual.position = row.p
		var team: int = row.get("owner", row.get("team", -1))
		visual.material_override.albedo_color = Color("a5dec8") if team == 0 else (Color("ef9b72") if team == 1 else Color("d9d69d"))
	for key in visuals.keys():
		if not wanted.has(key):
			visuals[key].queue_free()
			visuals.erase(key)
