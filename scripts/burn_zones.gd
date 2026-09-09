class_name BurnZones
extends Node3D

const RADIUS := 3.5
const DURATION := 3.0
const DAMAGE_PER_SECOND := 8.0
const TICK := 0.25
var game: Node3D
var zones: Dictionary = {}
var visuals: Dictionary = {}
var serial := 0

func ignite(pos: Vector3, owner_id: int) -> void:
	if not game.is_host:
		return
	var hit := ground_at(pos + Vector3.UP * 0.2, 14)
	if hit.is_empty():
		return
	serial += 1
	var point: Vector3 = hit.position + Vector3.UP * 0.035
	zones[serial] = {"id": serial, "p": point, "owner": owner_id, "left": DURATION, "clock": 0.0}
	show_zone(zones[serial])

func ground_at(pos: Vector3, depth: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(pos, pos + Vector3.DOWN * depth, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit if not hit.is_empty() and hit.normal.y > 0.65 else {}

func advance(dt: float) -> void:
	if not game.is_host:
		return
	for id in zones.keys():
		var zone: Dictionary = zones[id]
		var alive_time := minf(maxf(0, dt), zone.left)
		zone.left -= alive_time
		zone.clock += alive_time
		while zone.clock + 0.00001 >= TICK:
			zone.clock -= TICK
			if not game.match_over and game.players.has(zone.owner):
				var source: Fighter = game.players[zone.owner]
				for target: Fighter in game.players.values():
					if affects(zone.p, target):
						game.combat.damage(target, source, DAMAGE_PER_SECOND * TICK, "FRAG / FIRE", false, zone.p)
		if zone.left <= 0 or not game.players.has(zone.owner):
			remove_zone(id)

func affects(pos: Vector3, target: Fighter) -> bool:
	# Flames occupy one floor, not a vertical cylinder through the entire house.
	var offset := target.global_position - pos
	return absf(offset.y) < 1.5 and Vector2(offset.x, offset.z).length() < RADIUS \
		and game.visible_between(pos + Vector3.UP * 0.25, target.eye(), [target.get_rid()])

func snapshot() -> Array:
	var result := []
	for zone: Dictionary in zones.values():
		result.append({"id": zone.id, "p": zone.p, "owner": zone.owner, "left": zone.left})
	return result

func sync(rows: Array) -> void:
	if game.is_host:
		return
	var seen := []
	for row: Dictionary in rows:
		seen.append(row.id)
		zones[row.id] = row.duplicate()
		show_zone(row)
	for id in zones.keys():
		if not id in seen:
			remove_zone(id)

func show_zone(zone: Dictionary) -> void:
	if game.headless:
		return
	if visuals.has(zone.id) and is_instance_valid(visuals[zone.id]):
		visuals[zone.id].remaining = zone.left
		return
	var points: Array[Vector3] = []
	var count: int = [10, 16, 20][game.graphics_quality]
	for i in count:
		var angle := i * 2.399963
		var radius := sqrt(float(i) / count) * (RADIUS - 0.8)
		var sample: Vector3 = zone.p + Vector3(cos(angle), 0, sin(angle)) * radius
		if not game.visible_between(zone.p + Vector3.UP * 0.3, sample + Vector3.UP * 0.3):
			continue
		var floor_hit := ground_at(sample + Vector3.UP * 0.6, 1.2)
		if not floor_hit.is_empty():
			points.append(floor_hit.position + Vector3.UP * 0.04)
	var effect := BurnVisual.new()
	effect.points = points
	effect.remaining = zone.left
	add_child(effect)
	visuals[zone.id] = effect

func remove_zone(id: int) -> void:
	zones.erase(id)
	if visuals.has(id):
		if is_instance_valid(visuals[id]):
			visuals[id].queue_free()
		visuals.erase(id)

func clear() -> void:
	for id in zones.keys():
		remove_zone(id)
