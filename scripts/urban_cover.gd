class_name UrbanCover
extends RefCounted

static func build(pos: Vector3, size: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	var batch := UrbanMeshBatch.new()
	batch.bevel_box(Vector3.ZERO, size, "concrete", Color("d6d2c5"), 0.09)
	for x in [-size.x * 0.32, size.x * 0.32]:
		batch.box(Vector3(x, -size.y * 0.12, size.z * 0.501), Vector3(0.2, size.y * 0.62, 0.015), "metal", Color("4e5c5b"))
		batch.box(Vector3(x, -size.y * 0.12, -size.z * 0.501), Vector3(0.2, size.y * 0.62, 0.015), "metal", Color("4e5c5b"))
	for x in [-0.7, 0.7]:
		batch.cylinder(Vector3(x, size.y * 0.502, 0), 0.055, 0.018, "metal", Color("545d59"))
	batch.box(Vector3(0, size.y * 0.22, size.z * 0.507), Vector3(0.5, 0.09, 0.015), "paint", Color("b7a374"))
	batch.finish(root, "ConcreteBarrier")
	return root
