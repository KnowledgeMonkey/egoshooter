class_name CombatHistory
extends Node3D

var game: Node3D
var frames: Array = []
var clip: Array = []
var playing := false
var elapsed := 0.0
var killer_id := 0
var ghosts := {}

func record(roster: Array, stamp: float = -1) -> void:
	var time := Time.get_ticks_msec() / 1000.0 if stamp < 0 else stamp
	var actors := {}
	for row: Dictionary in roster:
		actors[row.id] = {"p": row.p, "yaw": row.yaw, "pitch": row.pitch, "hp": row.hp,
			"team": row.team, "weapon": row.weapon, "duck": row.duck, "life": row.get("life", 0)}
	frames.append({"time": time, "actors": actors})
	while frames.size() > 45 or (frames.size() > 1 and time - frames[0].time > 2.2): frames.pop_front()

func begin(id: int) -> void:
	stop()
	if game.headless or id == 0 or frames.size() < 4: return
	if not frames[-1].actors.has(id): return
	killer_id = id
	clip = frames.duplicate(true)
	elapsed = 0
	playing = true

func sample(time: float, source: Array = frames) -> Dictionary:
	if source.is_empty(): return {}
	var a: Dictionary = source[0]
	var b: Dictionary = source[-1]
	for frame: Dictionary in source:
		if frame.time <= time: a = frame
		if frame.time >= time:
			b = frame
			break
	var weight := clampf((time - float(a.time)) / maxf(0.001, float(b.time) - float(a.time)), 0, 1)
	var result: Dictionary = a.actors.duplicate(true)
	for id in result:
		if b.actors.has(id) and result[id].life == b.actors[id].life:
			result[id].p = result[id].p.lerp(b.actors[id].p, weight)
			result[id].yaw = lerp_angle(result[id].yaw, b.actors[id].yaw, weight)
			result[id].pitch = lerpf(result[id].pitch, b.actors[id].pitch, weight)
	return result

func advance(dt: float, camera: Camera3D) -> bool:
	if not playing: return false
	elapsed += dt
	var duration: float = minf(2, clip[-1].time - clip[0].time)
	if elapsed >= duration:
		stop()
		return false
	var actors := sample(float(clip[-1].time) - duration + elapsed, clip)
	if not actors.has(killer_id):
		stop()
		return false
	for id in actors:
		var row: Dictionary = actors[id]
		if id == killer_id: continue
		if not ghosts.has(id):
			var model := OperatorModel.new()
			add_child(model)
			model.setup(row.team)
			model.weapon_mount.add_child(WeaponModels.build(row.weapon))
			ghosts[id] = model
		var ghost: OperatorModel = ghosts[id]
		ghost.position = row.p
		ghost.rotation.y = row.yaw
		ghost.scale.y = 0.67 if row.duck else 1.0
		ghost.visible = row.hp > 0
		ghost.animate(dt, 0, row.pitch, row.duck)
	var killer: Dictionary = actors[killer_id]
	camera.global_position = killer.p + Vector3.UP * (1 if killer.duck else 1.65)
	camera.global_rotation = Vector3(killer.pitch, killer.yaw, 0)
	camera.fov = 88
	camera.make_current()
	return true

func stop() -> void:
	playing = false
	clip.clear()
	for ghost in ghosts.values(): ghost.queue_free()
	ghosts.clear()

func rewind_hit(source: Fighter, start: Vector3, end: Vector3, seconds: float) -> Dictionary:
	var wall := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, end, 1))
	if not wall.is_empty(): end = wall.position
	var actors := sample(Time.get_ticks_msec() / 1000.0 - clampf(seconds, 0, 0.2))
	var best := {}
	var nearest := start.distance_to(end)
	for id in actors:
		var row: Dictionary = actors[id]
		var target: Fighter = game.players.get(id)
		if target == null or target == source or target.hp <= 0 or row.hp <= 0 or target.life != row.life: continue
		var bounds := AABB(row.p + Vector3(-0.32, 0, -0.32), Vector3(0.64, 1.15 if row.duck else 1.8, 0.64))
		var hit = bounds.intersects_segment(start, end)
		if hit is Vector3 and start.distance_to(hit) < nearest:
			nearest = start.distance_to(hit)
			best = {"position": hit, "collider": target, "origin": row.p}
	return wall if best.is_empty() else best
