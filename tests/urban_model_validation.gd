extends SceneTree

func _initialize() -> void:
	var batch := UrbanMeshBatch.new()
	batch.bevel_box(Vector3.ZERO, Vector3(2, 2, 2), "paint", Color.WHITE, 0.1)
	# Include a PrimitiveMesh in the same material to exercise mixed-source merge.
	batch.box(Vector3(4, 0, 0), Vector3.ONE, "paint")
	var check := Node3D.new()
	batch.finish(check)
	var mesh: Mesh = check.get_child(0).mesh
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var outward := true
	for i in vertices.size():
		if vertices[i].x < 2 and vertices[i].dot(normals[i]) < 0:
			outward = false
	assert(outward, "Profile normals must point outwards")
	assert(vertices.size() > 24, "Custom and primitive vertices must survive batching")
	check.free()
	for label in ["RELAY / 01", "ATELIER / 04", "NORTH MARKET", "MOTOR WORKS"]:
		var building := UrbanArchitecture.build(0, 0, Color("337f80"), label)
		assert(building.get_child_count() < 45, "Architecture batching draw/node budget")
		print(label, ": ", building.get_child_count(), " nodes")
		building.free()
	for long_vehicle in [false, true]:
		var vehicle := UrbanVehicles.build(Color("668f97"), long_vehicle)
		assert(vehicle.get_child_count() < 30, "Vehicle batching draw/node budget")
		print(vehicle.name, ": ", vehicle.get_child_count(), " nodes")
		vehicle.free()
	print("Urban model validation passed: exterior normals, mixed geometry batching, all variants and node budgets.")
	quit()
