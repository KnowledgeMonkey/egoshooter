class_name ShotOrigin
extends RefCounted

static func muzzle(p: Fighter) -> Vector3:
	var sight: float = [0.11, 0.11, 0.06, 0.108, 0.068][Arsenal.FAMILIES[p.weapon]]
	var mount := Vector3(0, -sight, -0.36 if p.weapon == 4 else -0.20) if p.aiming else (Vector3(0.18, -0.22, -0.43) if p.weapon == 4 else Vector3(0.17, -0.18, -0.22))
	return p.eye() + Basis.from_euler(Vector3(p.pitch, p.yaw, 0)) * (mount + WeaponModels.muzzle_position(p.weapon))

static func path(p: Fighter, direction: Vector3, reach: float) -> Dictionary:
	var space := p.get_world_3d().direct_space_state
	var end := p.eye() + direction * reach
	var aim := space.intersect_ray(PhysicsRayQueryParameters3D.create(p.eye(), end, 3, [p.get_rid()]))
	if not aim.is_empty(): end = aim.position
	var start := muzzle(p)
	# A barrel inside/behind cover must not shoot through it.
	var obstruction := space.intersect_ray(PhysicsRayQueryParameters3D.create(p.eye(), start, 1))
	if not obstruction.is_empty(): return {"start": p.eye(), "end": obstruction.position, "hit": obstruction, "blocked": true}
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(start, end + direction * 0.015, 3, [p.get_rid()]))
	return {"start": start, "end": end, "hit": hit, "blocked": false}

static func visual(p: Fighter) -> Vector3:
	if p.is_local() and p.gun.displayed == p.weapon and is_instance_valid(p.gun.muzzle):
		return p.gun.model.get_node("Muzzle").global_position
	if p.world_weapon == p.weapon and p.world_gun.get_child_count() > 0:
		return p.world_gun.get_child(0).get_node("Muzzle").global_position
	return muzzle(p)
