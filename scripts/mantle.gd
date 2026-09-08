class_name Mantle
extends RefCounted

static func destination(p: Fighter) -> Vector3:
	var forward := Arsenal.direction(p.yaw, 0)
	var space := p.get_world_3d().direct_space_state
	var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(p.global_position + Vector3.UP * 0.65,
		p.global_position + Vector3.UP * 0.65 + forward * 0.95, 1))
	if wall.is_empty(): return Vector3.INF
	var over := p.global_position + forward * 1.05 + Vector3.UP * 1.9
	var top := space.intersect_ray(PhysicsRayQueryParameters3D.create(over, over - Vector3.UP * 1.7, 1))
	if top.is_empty() or top.normal.y < 0.7: return Vector3.INF
	var rise: float = top.position.y - p.global_position.y
	if rise < 0.35 or rise > 1.5: return Vector3.INF
	var target: Vector3 = top.position + Vector3.UP * 0.04
	var elevated := p.global_transform
	var lift := Vector3.UP * (rise + 0.08)
	# Sweep the actual capsule up, forward and down. Never cross an overhang/wall.
	if p.test_move(elevated, lift): return Vector3.INF
	elevated.origin += lift
	var across := Vector3(target.x - p.global_position.x, 0, target.z - p.global_position.z)
	if p.test_move(elevated, across): return Vector3.INF
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = p.capsule
	query.transform = Transform3D(Basis.IDENTITY, target + p.shape.position)
	query.collision_mask = 3
	query.exclude = [p.get_rid()]
	if not space.intersect_shape(query, 1).is_empty(): return Vector3.INF
	return target
