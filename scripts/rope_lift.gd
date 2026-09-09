class_name RopeLift
extends RefCounted

static func nearby(p: Fighter) -> Dictionary:
	for lift: Dictionary in p.game.arena.lifts:
		for endpoint in ["bottom", "top"]:
			if p.global_position.distance_to(lift[endpoint]) < 1.6:
				return {"lift": lift, "up": endpoint == "bottom"}
	return {}

static func start(p: Fighter) -> void:
	if not p.game.is_host or p.hp <= 0 or p.mantle_left > 0 or not p.rope_path.is_empty(): return
	var candidate := nearby(p)
	if candidate.is_empty(): return
	var lift: Dictionary = candidate.lift
	var above_roof := Vector3(lift.top.x, lift.over.y, lift.top.z)
	var destination: Vector3 = lift.top if candidate.up else lift.bottom
	for other: Fighter in p.game.players.values():
		if other != p and other.hp > 0 and other.global_position.distance_to(destination) < 1.0: return
	# Validate the full capsule corridor before mounting; no teleport through walls.
	var route := PackedVector3Array([lift.bottom, lift.over, above_roof, lift.top]) if candidate.up else PackedVector3Array([lift.top, above_roof, lift.over, lift.bottom])
	var pose := p.global_transform
	for point in route:
		if p.test_move(pose, point - pose.origin): return
		pose.origin = point
	p.rope_path = route
	p.rope_active = true
	p.reload_left = 0
	p.aiming = false
	p.protection = 0

static func advance(p: Fighter, dt: float) -> void:
	if p.input_data.get("jump", false):
		p.input_data["jump"] = false
		p.rope_path.clear()
		p.rope_active = false
		return
	if p.rope_path.is_empty():
		p.rope_active = false
		return
	var target := p.rope_path[0]
	var motion := p.global_position.move_toward(target, dt * 5.5) - p.global_position
	if p.test_move(p.global_transform, motion):
		p.rope_path.clear()
		p.rope_active = false
		return
	p.global_position += motion
	p.velocity = Vector3.ZERO
	if p.global_position.distance_to(target) < 0.015: p.rope_path.remove_at(0)
	p.rope_active = not p.rope_path.is_empty()
