class_name WeaponGeometry
extends RefCounted

# Reusable modelling primitives. Dimensions are metres; barrels point toward -Z.
static var materials := {}

static func material(key: String) -> StandardMaterial3D:
	if materials.has(key):
		return materials[key]
	var palette := {"steel": Color("303740"), "edge": Color("626974"), "black": Color("151a21"),
		"polymer": Color("272b2b"), "sand": Color("8c8064"), "rubber": Color("111417"),
		"silver": Color("a4a9aa"), "brass": Color("b59753"), "red": Color("df603b"),
		"glass": Color("163f4b"), "mark": Color("b9b5a7"), "cloth": Color("515948")}
	var mat := StandardMaterial3D.new()
	mat.albedo_color = palette.get(key, Color.GRAY)
	mat.metallic = 0.82 if key in ["steel", "edge", "black", "silver", "brass"] else 0.05
	mat.roughness = 0.32 if mat.metallic > 0.5 else 0.77
	if key == "glass":
		mat.metallic = 0.65
		mat.roughness = 0.12
	if key == "red":
		mat.emission_enabled = true
		mat.emission = Color("db421b")
		mat.emission_energy_multiplier = 1.2
	var noise := FastNoiseLite.new()
	noise.seed = 427
	noise.frequency = 0.16
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.noise = noise
	texture.as_normal_map = true
	texture.bump_strength = 0.18
	mat.normal_enabled = true
	mat.normal_texture = texture
	mat.normal_scale = 0.1 if mat.metallic > 0.5 else 0.35
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * 5
	materials[key] = mat
	return mat

static func part(parent: Node3D, mesh: Mesh, pos: Vector3, key: String, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material(key)
	instance.position = pos
	instance.rotation = rotation
	parent.add_child(instance)
	return instance

static func tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)

static func profile(parent: Node3D, points: PackedVector2Array, width: float, pos: Vector3, key: String, bevel: float = 0.003) -> MeshInstance3D:
	# Polygon coordinates are (Z,Y). Four rings give physical edge chamfers.
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= points.size()
	var rings: Array = []
	for index in 4:
		var ring := PackedVector3Array()
		var outer := index == 0 or index == 3
		var x: float = [-width / 2, -width / 2 + bevel, width / 2 - bevel, width / 2][index]
		for point in points:
			var inset := center + (point - center) * 0.92 if outer else point
			ring.append(Vector3(x, inset.y, inset.x))
		rings.append(ring)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in 3:
		for i in points.size():
			var next := (i + 1) % points.size()
			tri(tool, rings[r][i], rings[r + 1][i], rings[r + 1][next])
			tri(tool, rings[r][i], rings[r + 1][next], rings[r][next])
	var indices := Geometry2D.triangulate_polygon(points)
	for i in range(0, indices.size(), 3):
		tri(tool, rings[0][indices[i]], rings[0][indices[i + 1]], rings[0][indices[i + 2]])
		tri(tool, rings[3][indices[i + 2]], rings[3][indices[i + 1]], rings[3][indices[i]])
	tool.generate_normals()
	var mesh := tool.commit()
	var result := part(parent, mesh, pos, key)
	# Thin open trigger guards and chamfers remain visible from either side.
	result.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result

static func block(parent: Node3D, pos: Vector3, size: Vector3, key: String, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var z := size.z / 2
	var y := size.y / 2
	var chamfer := minf(0.009, minf(y, z) * 0.28)
	var points := PackedVector2Array([Vector2(-z + chamfer, -y), Vector2(z - chamfer, -y),
		Vector2(z, -y + chamfer), Vector2(z, y - chamfer), Vector2(z - chamfer, y),
		Vector2(-z + chamfer, y), Vector2(-z, y - chamfer), Vector2(-z, -y + chamfer)])
	var result := profile(parent, points, size.x, pos, key, minf(0.003, size.x * 0.12))
	result.rotation = rotation
	return result

static func tube(parent: Node3D, pos: Vector3, radius: float, length: float, key: String, axis: Vector3 = Vector3(PI / 2, 0, 0), tip: float = -1) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius if tip < 0 else tip
	cylinder.bottom_radius = radius
	cylinder.height = length
	cylinder.radial_segments = 24
	cylinder.rings = 1
	return part(parent, cylinder, pos, key, axis)

static func screw(parent: Node3D, pos: Vector3) -> void:
	tube(parent, pos, 0.004, 0.002, "silver", Vector3(0, 0, PI / 2))
	block(parent, pos + Vector3(0.0015, 0, 0), Vector3(0.001, 0.0014, 0.005), "black")

static func rail(parent: Node3D, start: float, end: float, y: float) -> void:
	block(parent, Vector3(0, y, (start + end) / 2), Vector3(0.032, 0.009, absf(end - start)), "black")
	var z := start
	while z > end:
		block(parent, Vector3(0, y + 0.006, z), Vector3(0.043, 0.008, 0.007), "edge")
		z -= 0.016

static func label(parent: Node3D, value: String, pos: Vector3, size: int = 32) -> void:
	var text := Label3D.new()
	text.text = value
	text.font_size = size
	text.pixel_size = 0.00022
	text.outline_size = 0
	text.modulate = Color("b3b7b3")
	text.position = pos
	text.rotation.y = PI / 2
	parent.add_child(text)

static func batch(parent: Node3D) -> void:
	var groups := {}
	for child in parent.get_children():
		if child is MeshInstance3D:
			var mat: Material = child.material_override
			if not groups.has(mat):
				groups[mat] = SurfaceTool.new()
				groups[mat].begin(Mesh.PRIMITIVE_TRIANGLES)
			# Primitive cylinders are indexed; authored bevel meshes are not.
			# Normalize before merging, otherwise indexed surfaces omit prior faces.
			var source := SurfaceTool.new()
			source.create_from(child.mesh, 0)
			source.deindex()
			groups[mat].append_from(source.commit(), 0, child.transform)
			parent.remove_child(child)
			child.free()
	for mat in groups:
		var mesh: ArrayMesh = groups[mat].commit()
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.material_override = mat
		parent.add_child(instance)
