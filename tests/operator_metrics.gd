extends SceneTree

func _initialize() -> void:
	var a := OperatorModel.new()
	a.setup(0)
	var b := OperatorModel.new()
	b.setup(0)
	var opponent := OperatorModel.new()
	opponent.setup(1)
	assert(a.weapon_mount != b.weapon_mount, "Each operator needs an independent weapon mount")
	assert(a.hips[0] != b.hips[0], "Cached operators must animate independently")
	a.animate(0.1, 6, 0.2, false)
	assert(a.hips[0].rotation != b.hips[0].rotation, "Animation cannot modify cached instances")
	var result := measure(a, Transform3D.IDENTITY)
	var bounds: AABB = result.bounds
	assert(bounds.position.y > -0.01 and bounds.end.y < 1.9, "Operator must fit the existing gameplay height")
	assert(result.meshes < 50, "Material batching keeps draw calls bounded")
	print("OPERATOR meshes=", result.meshes, " triangles=", result.triangles, " bounds=", bounds)
	for index in 5:
		var view := WeaponView.new()
		view.select_weapon(index)
		var hand_metrics := measure(view.hands, Transform3D.IDENTITY)
		assert(hand_metrics.meshes < 8, "Hands are grouped by material")
		print("HANDS ", index, " meshes=", hand_metrics.meshes, " triangles=", hand_metrics.triangles)
		view.free()
	a.free()
	b.free()
	opponent.free()
	print("OPERATOR RIG CHECK PASSED")
	quit()

func measure(node: Node3D, parent_transform: Transform3D) -> Dictionary:
	var transform := parent_transform * node.transform
	var output := {"meshes": 0, "triangles": 0, "bounds": AABB()}
	if node is MeshInstance3D:
		output.meshes = 1
		output.bounds = transform * node.mesh.get_aabb()
		for surface in node.mesh.get_surface_count():
			var indices: int = node.mesh.surface_get_array_index_len(surface)
			output.triangles += indices / 3 if indices > 0 else node.mesh.surface_get_array_len(surface) / 3
	for child in node.get_children():
		if child is Node3D:
			var result := measure(child, transform)
			if result.meshes > 0:
				output.bounds = output.bounds.merge(result.bounds) if output.meshes > 0 else result.bounds
			output.meshes += result.meshes
			output.triangles += result.triangles
	return output
