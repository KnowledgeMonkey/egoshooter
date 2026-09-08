class_name BotRoutes
extends RefCounted

var arena: RelayArena
var buildings: Array = []

func _init(owner_arena: RelayArena) -> void:
	arena = owner_arena
	for x in [-11, 11]:
		for z in [-18, 18]:
			var origin := Vector3(x, 0, z)
			var side := signf(x)
			var graph := AStar3D.new()
			var points := [Vector3(2, 0.1, 4.6), Vector3(2, 3.7, -4.6), Vector3(0, 3.7, -4.6),
				Vector3(-2.4, 3.7, -4.6), Vector3(-2.4, 7.4, 4.6), Vector3(0, 7.4, 4.7),
				Vector3(side * 4, 7.4, 4.7), Vector3(side * 4, 7.4, -4.6),
				Vector3(side * 8.3, 7.4, -4.6), Vector3(side * 8.3, 3.7, 4.6),
				Vector3(side * 6, 3.7, 4.6), Vector3(side * 6, 0.1, -4.6),
				Vector3(side * 3.8, 3.7, 4.6), Vector3(0, 3.7, 4.6)]
			for i in points.size(): graph.add_point(i, origin + points[i])
			for edge in [[0,1],[1,2],[2,3],[3,4],[4,5],[5,6],[6,7],[7,8],[8,9],[9,10],[10,11],[10,12],[12,13],[13,2]]:
				graph.connect_points(edge[0], edge[1])
			buildings.append({"origin": origin, "graph": graph})

func house(point: Vector3) -> Dictionary:
	var best: Dictionary = buildings[0]
	for building: Dictionary in buildings:
		if Vector2(point.x, point.z).distance_to(Vector2(building.origin.x, building.origin.z)) < Vector2(point.x, point.z).distance_to(Vector2(best.origin.x, best.origin.z)):
			best = building
	return best

func node_on_floor(graph: AStar3D, position: Vector3) -> int:
	var best := -1
	var distance := INF
	for id in graph.get_point_ids():
		var point := graph.get_point_position(id)
		if absf(point.y - position.y) > 1.5: continue
		if point.distance_to(position) < distance:
			best = id
			distance = point.distance_to(position)
	return graph.get_closest_point(position) if best < 0 else best

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	var start_house := house(from)
	var end_house := house(to)
	if from.y > 2.5 and to.y > 2.5 and start_house == end_house:
		return start_house.graph.get_point_path(node_on_floor(start_house.graph, from), node_on_floor(end_house.graph, to))
	var ground_start := from
	var ground_end := to
	if from.y > 2.5:
		result.append_array(start_house.graph.get_point_path(node_on_floor(start_house.graph, from), 11))
		ground_start = start_house.graph.get_point_position(11)
	if to.y > 2.5:
		ground_end = end_house.graph.get_point_position(11)
	for point in arena.path(ground_start, ground_end):
		result.append(Vector3(point.x, 0.1, point.y))
	if to.y > 2.5:
		result.append_array(end_house.graph.get_point_path(11, node_on_floor(end_house.graph, to)))
	return result

func patrol(id: int, phase: int) -> Vector3:
	var building: Dictionary = buildings[posmod(id + phase, buildings.size())]
	return building.graph.get_point_position(7 if phase % 2 == 0 else 3)
