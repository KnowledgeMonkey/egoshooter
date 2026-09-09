extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if value:
		print("PASS ", description)
	else:
		failures += 1
		printerr("FAIL ", description)

func inspect(node: Node) -> Dictionary:
	var result := {"meshes": 0, "triangles": 0, "bodies": 0, "finite": true}
	if node is MeshInstance3D:
		result.meshes = 1
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			result.triangles += (indices.size() if indices.size() > 0 else vertices.size()) / 3
			for vertex in vertices:
				result.finite = result.finite and vertex.is_finite()
	if node is CollisionObject3D:
		result.bodies = 1
	for child in node.get_children():
		var nested := inspect(child)
		result.meshes += nested.meshes
		result.triangles += nested.triangles
		result.bodies += nested.bodies
		result.finite = result.finite and nested.finite
	return result

func run() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	var stage := Node3D.new()
	root.add_child(stage)
	for kind in ["asphalt", "concrete", "ground", "paving", "plaster", "wood", "floor"]:
		var mat := UrbanMaterials.get_surface(kind)
		check(mat.albedo_texture != null and mat.normal_texture != null and mat.roughness_texture != null, kind + " has local PBR maps")
		var resolution := 1024 if kind == "ground" else 4096
		for map in [mat.albedo_texture, mat.normal_texture, mat.roughness_texture]:
			check(map.get_width() == resolution and map.get_height() == resolution, kind + " PBR map resolution")
			check(map.get_image().has_mipmaps(), kind + " PBR map has mipmaps")
	check(UrbanMaterials.get_surface("plaster").albedo_texture != UrbanMaterials.get_surface("concrete").albedo_texture, "plaster uses its own surface")
	check(UrbanMaterials.get_surface("wood").normal_texture != UrbanMaterials.get_surface("concrete").normal_texture, "wood uses real wood normals")
	check(load("res://assets/sky/relay_clouds.hdr").get_width() == 2048, "bundled 2K HDR panorama loads")
	var objects := [UrbanArchitecture.build(-11, -18, Color("337f80"), "RELAY / 01"),
		UrbanArchitecture.build(11, 18, Color("c59857"), "ATELIER / 04"),
		UrbanArchitecture.build(11, -18, Color("abb8b1"), "NORTH MARKET"),
		UrbanArchitecture.build(-11, 18, Color("bd9d85"), "MOTOR WORKS"),
		UrbanVehicles.build(Color("b8c4bd")), UrbanVehicles.build(Color("c59857"), true), UrbanDetails.build()]
	for i in objects.size():
		var object: Node3D = objects[i]
		stage.add_child(object)
		var metrics := inspect(object)
		check(metrics.finite and metrics.meshes > 0, "urban visual %s has finite renderable geometry" % i)
		check(metrics.bodies == 0, "urban visual %s adds no gameplay colliders" % i)
		check(metrics.meshes < 45, "urban visual %s uses material batching (%s meshes)" % [i, metrics.meshes])
		print("GEOMETRY ", i, " triangles=", metrics.triangles)
	# Convex cover chamfers must have outward normals, not vanished interior faces.
	var batch := UrbanMeshBatch.new()
	var container := Node3D.new()
	stage.add_child(container)
	batch.bevel_box(Vector3.ZERO, Vector3(2, 1, 1), "concrete", Color.WHITE, 0.05)
	batch.finish(container)
	var arrays: Array = container.get_child(0).mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var outward := true
	for i in verts.size():
		outward = outward and verts[i].dot(normals[i]) > 0
	check(outward, "cover bevel surface normals face outwards")
	var before := stage.get_child_count()
	CombatVisuals.explosion(stage, Vector3.ZERO)
	CombatVisuals.impact(stage, Vector3.ONE)
	check(stage.get_child_count() > before, "explosion and impact instantiate effects")
	await create_timer(3.6).timeout
	check(stage.get_child_count() == before, "all transient effect nodes clean up")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for quality in range(3):
		GraphicsSettings.apply(game, quality)
		var env: Environment = game.arena.get_node("DistrictAtmosphere").environment
		check(env.ssao_enabled == (quality > 0), "quality %s updates ambient occlusion" % quality)
	GraphicsSettings.apply(game, 8)
	check(game.graphics_quality == 2, "quality input is clamped")
	check(game.arena.spawn_points.size() == 10, "ten original spawn points preserved")
	game.queue_free()
	stage.queue_free()
	await process_frame
	print("GRAPHICS RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
