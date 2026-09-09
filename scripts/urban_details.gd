class_name UrbanDetails
extends RefCounted

# Visual-only dressing. Every feature is either flush with the ground or outside
# the combat routes. Materials are batched into one static mesh per finish.
var _groups: Dictionary = {}
var _rng := RandomNumberGenerator.new()

static func build() -> Node3D:
	var details := UrbanDetails.new()
	details._rng.seed = 30174
	return details._build()

func _build() -> Node3D:
	var root := Node3D.new()
	root.name = "DistrictEnvironment"
	# Perimeter collision and dressing are supplied by the expanded arena.
	_streets()
	_platforms()
	# The quarry escarpment supplies the skyline for this environment.
	# Sparse war-district dressing replaces the decorative planting.
	for x in [-28.0, 28.0]:
		for z in [-28.0, 28.0]:
			_streetlight(Vector3(x, 0, z), -signf(x))
	for material in _groups:
		var instance := MeshInstance3D.new()
		instance.name = "EnvironmentBatch_%02d" % root.get_child_count()
		instance.mesh = (_groups[material] as SurfaceTool).commit()
		instance.material_override = material
		root.add_child(instance)
	return root

func _add(mesh: Mesh, at: Vector3, kind: String, tint: Color = Color.WHITE,
		rotation: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> void:
	var finish: Material = UrbanMaterials.get_surface(kind, tint)
	if not _groups.has(finish):
		var batch := SurfaceTool.new()
		batch.begin(Mesh.PRIMITIVE_TRIANGLES)
		_groups[finish] = batch
	var source := SurfaceTool.new()
	source.create_from(mesh, 0)
	source.deindex()
	var basis := Basis.from_euler(rotation).scaled(scale)
	(_groups[finish] as SurfaceTool).append_from(source.commit(), 0, Transform3D(basis, at))

func _box(at: Vector3, size: Vector3, kind: String, tint: Color = Color.WHITE,
		bevel: float = 0.035, rotation: Vector3 = Vector3.ZERO) -> void:
	# Octagonal outline and inset end caps give actual bevels that catch sunlight.
	var half := size * 0.5
	var b := minf(bevel, minf(half.x, minf(half.y, half.z)) * 0.7)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)
	var rings: Array[PackedVector3Array] = []
	for i in 4:
		var outer: bool = i == 0 or i == 3
		var inset := b * 0.6 if outer else 0.0
		var hx := half.x - inset
		var hz := half.z - inset
		var y: float = [-half.y, -half.y + b, half.y - b, half.y][i]
		var ring := PackedVector3Array([
			Vector3(-hx + b, y, -hz), Vector3(hx - b, y, -hz),
			Vector3(hx, y, -hz + b), Vector3(hx, y, hz - b),
			Vector3(hx - b, y, hz), Vector3(-hx + b, y, hz),
			Vector3(-hx, y, hz - b), Vector3(-hx, y, -hz + b)])
		rings.append(ring)
	for r in 3:
		for i in 8:
			var n := (i + 1) % 8
			_tri(tool, rings[r][i], rings[r][n], rings[r + 1][n])
			_tri(tool, rings[r][i], rings[r + 1][n], rings[r + 1][i])
	for i in 8:
		var n := (i + 1) % 8
		_tri(tool, Vector3(0, -half.y, 0), rings[0][n], rings[0][i])
		_tri(tool, Vector3(0, half.y, 0), rings[3][i], rings[3][n])
	tool.generate_normals()
	_add(tool.commit(), at, kind, tint, rotation)

func _tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		tool.set_uv(Vector2(point.x + point.z, point.y + point.z))
		tool.add_vertex(point)

func _panel(at: Vector3, size: Vector3, kind: String, tint: Color) -> void:
	# Far facade glazing/mullions are truly flat fabricated panels. Their tiny
	# edge bevel would be subpixel, so reserve bevel geometry for silhouettes.
	var mesh := BoxMesh.new()
	mesh.size = size
	_add(mesh, at, kind, tint)

func _cylinder(at: Vector3, radius: float, height: float, kind: String,
		tint: Color = Color.WHITE, top_radius: float = -1.0) -> void:
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0 else top_radius
	mesh.radial_segments = 12
	mesh.rings = 1
	_add(mesh, at, kind, tint)

func _rod(a: Vector3, b: Vector3, radius: float, kind: String, tint: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.height = a.distance_to(b)
	mesh.top_radius = radius * 0.88
	mesh.bottom_radius = radius
	mesh.radial_segments = 10
	mesh.rings = 1
	var direction := (b - a).normalized()
	var rotation := Quaternion(Vector3.UP, direction).get_euler()
	_add(mesh, (a + b) * 0.5, kind, tint, rotation)

func _perimeter() -> void:
	var stone := Color("a2aaa2")
	var shadow := Color("455953")
	var cap := Color("bdc4b9")
	for side in [-1.0, 1.0]:
		# Narrow joints divide the existing perimeter into believable precast bays.
		_box(Vector3(side * 36, 4.41, 0), Vector3(1.16, 0.18, 100), "concrete", cap)
		_box(Vector3(side * 35.46, 0.36, 0), Vector3(0.12, 0.7, 99.6), "concrete", stone)
		_box(Vector3(side * 35.48, 3.75, 0), Vector3(0.08, 0.055, 99.8), "metal", shadow, 0.01)
		for z in range(-47, 49, 5):
			_box(Vector3(side * 35.45, 2.2, z), Vector3(0.13, 4.2, 0.13), "concrete", stone)
			_box(Vector3(side * 35.48, 2.2, z + 0.14), Vector3(0.025, 4.05, 0.035), "metal", shadow, 0.005)
		_box(Vector3(0, 4.41, side * 50), Vector3(72, 0.18, 1.16), "concrete", cap)
		_box(Vector3(0, 0.36, side * 49.46), Vector3(71.6, 0.7, 0.12), "concrete", stone)
		for x in range(-33, 36, 6):
			_box(Vector3(x, 2.2, side * 49.44), Vector3(0.15, 4.2, 0.15), "concrete", stone)
			_box(Vector3(x + 0.16, 2.2, side * 49.48), Vector3(0.03, 4.05, 0.025), "metal", shadow, 0.005)
	# The cable is overhead and beyond the arena; its gentle sag breaks straight silhouettes.
	var cable_color := Color("303c3b")
	for x in [-24.0, 0.0, 24.0]:
		_cylinder(Vector3(x, 4.6, -51.3), 0.095, 9.2, "metal", shadow, 0.065)
		_box(Vector3(x, 8.7, -51.3), Vector3(1.5, 0.085, 0.085), "metal", shadow)
	for x_start in [-24.0, 0.0]:
		for offset in [-0.5, 0.5]:
			for step in 16:
				var t0 := step / 16.0
				var t1 := (step + 1) / 16.0
				var a := Vector3(x_start + 24 * t0, 8.85 - sin(t0 * PI) * 1.1, -51.3 + offset)
				var b := Vector3(x_start + 24 * t1, 8.85 - sin(t1 * PI) * 1.1, -51.3 + offset)
				_rod(a, b, 0.012, "metal", cable_color)

func _streets() -> void:
	var stone := Color("b3b2a3")
	var iron := Color("414c4b")
	for x in [-27.1, -16.9, -5.1, 5.1, 16.9, 27.1]:
		for interval in [Vector2(-41.5, -34.6), Vector2(-27.4, -3.6), Vector2(3.6, 27.4), Vector2(34.6, 41.5)]:
			var z: float = interval.x
			while z < interval.y:
				var length := minf(1.25, interval.y - z)
				_box(Vector3(x, 0.055, z + length * 0.5), Vector3(0.22, 0.085, length - 0.02), "concrete", stone, 0.015)
				z += 1.25
	for z in [-24.0, -11.0, 13.0, 25.0]:
		for x in [-4.68, 4.68]:
			_box(Vector3(x, 0.052, z), Vector3(0.5, 0.045, 0.85), "metal", iron, 0.015)
			for n in 8:
				_box(Vector3(x, 0.078, z - 0.35 + n * 0.1), Vector3(0.4, 0.012, 0.026), "rubber", Color("1c2728"), 0.002)
	for p in [Vector3(-1.3, 0.044, -17), Vector3(2.1, 0.044, 22), Vector3(-21.7, 0.044, 28), Vector3(22, 0.044, -30)]:
		_cylinder(p, 0.5, 0.022, "metal", iron)
		_cylinder(p + Vector3(0, 0.014, 0), 0.45, 0.012, "metal", Color("606762"))
		for i in 7:
			var x := (i - 3) * 0.1
			var length := sqrt(maxf(0.02, 0.39 * 0.39 - x * x)) * 2
			_box(p + Vector3(x, 0.026, 0), Vector3(0.018, 0.008, length), "metal", iron, 0.001)

func _platforms() -> void:
	var edge := Color("b7c1b8")
	var rail := Color("405a59")
	for x in [-23.0, 23.0]:
		_box(Vector3(x, 2.214, 0), Vector3(3.94, 0.026, 4.94), "paving", Color("97a59c"), 0.008)
		for side in [-1.0, 1.0]:
			_box(Vector3(x + side * 1.95, 1.7, 0), Vector3(0.05, 0.1, 4.9), "metal", rail, 0.01)
		for end in [-1.0, 1.0]:
			for step in 11:
				var h := (step + 1) * 0.2
				var z: float = end * (7.94 - step * 0.5)
				_box(Vector3(x, h + 0.01, z), Vector3(2.96, 0.023, 0.095), "metal", edge, 0.006)
				for side in [-1.0, 1.0]:
					_box(Vector3(x + side * 1.45, h + 0.011, z - end * 0.15), Vector3(0.065, 0.02, 0.19), "paint", Color("bcb28b"), 0.003)
		_box(Vector3(x + signf(x) * 1.8, 3.311, 0), Vector3(0.42, 0.055, 5.08), "metal", edge, 0.02)
		_box(Vector3(x - signf(x) * 1.8, 3.014, 0), Vector3(0.42, 0.05, 2.07), "metal", edge, 0.02)

func _streetlight(at: Vector3, inward: float) -> void:
	var steel := Color("4a5c5b")
	_cylinder(at + Vector3(0, 0.11, 0), 0.22, 0.22, "concrete", Color("a2aaa2"))
	_cylinder(at + Vector3(0, 2.85, 0), 0.1, 5.7, "metal", steel, 0.055)
	_cylinder(at + Vector3(0, 0.4, 0), 0.16, 0.57, "metal", steel, 0.105)
	var previous := at + Vector3(0, 5.7, 0)
	for step in range(1, 9):
		var angle := step / 8.0 * PI * 0.5
		var next := at + Vector3(inward * (1 - cos(angle)) * 0.8, 5.7 + sin(angle) * 0.8, 0)
		_rod(previous, next, 0.055, "metal", steel)
		previous = next
	_rod(previous, previous + Vector3(inward * 0.7, 0, 0), 0.045, "metal", steel)
	_box(at + Vector3(inward * 1.6, 6.46, 0), Vector3(0.9, 0.13, 0.36), "metal", steel, 0.06)
	_box(at + Vector3(inward * 1.6, 6.396, 0), Vector3(0.66, 0.018, 0.25), "glass", Color("f3dfb4"), 0.006)
	# Inspection hatch and two base bolts make the pole read as manufactured hardware.
	_box(at + Vector3(0, 0.7, 0.096), Vector3(0.073, 0.25, 0.015), "metal", Color("8a9690"), 0.006)
	for side in [-1.0, 1.0]:
		_cylinder(at + Vector3(side * 0.145, 0.245, 0), 0.018, 0.035, "metal", Color("8a9690"))

func _skyline() -> void:
	var colors: Array[Color] = [Color("929e98"), Color("b5ad97"), Color("8c9e9c"), Color("a6aaa0")]
	for side in [-1.0, 1.0]:
		var index := 0
		for z in [-33.0, -10.0, 14.0, 36.0]:
			_backdrop_building(Vector3(side * (RelayArena.HALF_WIDTH + 10.5), 0, z), Vector3(11, 10.5 + (index % 3) * 2.7, 15), colors[index], index)
			index += 1
		for x in [-22.0, 1.0, 23.0]:
			_backdrop_building(Vector3(x, 0, side * (RelayArena.HALF_LENGTH + 12)), Vector3(16, 11 + absf(x) * 0.17, 12), colors[index % 4], index)
			index += 1
	_terrain()

func _terrain() -> void:
	# A continuous heightfield grounds the district; no giant sphere silhouettes.
	var noise := FastNoiseLite.new()
	noise.seed = 7831
	noise.frequency = 0.014
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-240, 240, 10):
		for z in range(-240, 240, 10):
			var corners: Array[Vector3] = []
			for offset in [Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)]:
				var px: float = x + offset.x
				var pz: float = z + offset.y
				var distance := Vector2(px, pz).length()
				var hill := smoothstep(85.0, 175.0, distance) * (10 + noise.get_noise_2d(px, pz) * 35)
				corners.append(Vector3(px, -0.45 + maxf(0, hill), pz))
			for index in [0, 1, 2, 0, 2, 3]:
				surface.set_uv(Vector2(corners[index].x, corners[index].z) * 0.04)
				surface.add_vertex(corners[index])
	surface.generate_normals()
	_add(surface.commit(), Vector3.ZERO, "ground", Color("858e76"))

func _backdrop_building(at: Vector3, size: Vector3, tint: Color, variant: int) -> void:
	var trim := Color("566c68")
	var glazing := Color("465b60")
	_box(at + Vector3(0, size.y * 0.5, 0), size, "plaster", tint, 0.12)
	_box(at + Vector3(0, size.y + 0.12, 0), Vector3(size.x + 0.24, 0.24, size.z + 0.24), "concrete", Color("bdc4b9"), 0.045)
	_box(at + Vector3(-size.x * 0.15, size.y + 0.55, 0), Vector3(2.5, 0.95, 2), "metal", trim, 0.08)
	for floor_index in range(1, int(size.y / 2.65)):
		var y := floor_index * 2.65 + 0.9
		for side in [-1.0, 1.0]:
			# Recess-coloured glazing, thin concrete sills, and asymmetric service fins.
			# Omit outer faces nobody in the arena can see.
			if absf(at.x) < 30 or side == -signf(at.x):
				for j in range(1, int(size.z / 2.4)):
					var z := -size.z * 0.5 + j * 2.4
					_panel(at + Vector3(side * (size.x * 0.5 + 0.015), y, z), Vector3(0.05, 1.5, 1.6), "glass", glazing)
					_panel(at + Vector3(side * (size.x * 0.5 + 0.09), y - 0.8, z), Vector3(0.18, 0.1, 1.8), "concrete", Color("bdc4b9"))
					_panel(at + Vector3(side * (size.x * 0.5 + 0.06), y, z), Vector3(0.07, 1.51, 0.055), "metal", trim)
			if absf(at.z) < 43 or side == -signf(at.z):
				for j in range(1, int(size.x / 2.5)):
					var x := -size.x * 0.5 + j * 2.5
					_panel(at + Vector3(x, y, side * (size.z * 0.5 + 0.02)), Vector3(1.7, 1.5, 0.055), "glass", glazing)
					_panel(at + Vector3(x, y - 0.8, side * (size.z * 0.5 + 0.1)), Vector3(1.87, 0.1, 0.2), "concrete", Color("bdc4b9"))
					_panel(at + Vector3(x, y, side * (size.z * 0.5 + 0.06)), Vector3(0.055, 1.51, 0.07), "metal", trim)
	if variant % 2 == 0:
		for side in [-1.0, 1.0]:
			_box(at + Vector3(side * size.x * 0.38, size.y * 0.55, -size.z * 0.5 - 0.18), Vector3(0.38, size.y * 0.85, 0.42), "paint", Color("667f79"), 0.04)

func _planting() -> void:
	# All trunks and crowns remain outside the perimeter, preserving target visibility.
	for at in [Vector3(-39.2, 0, -24), Vector3(-39.4, 0, 6), Vector3(39.7, 0, -6), Vector3(39.4, 0, 28), Vector3(-15, 0, 54), Vector3(14, 0, -54)]:
		_tree(at, _rng.randf_range(0.9, 1.13))

func _tree(at: Vector3, size: float) -> void:
	var bark := Color("6d6b55")
	var foliage: Array[Color] = [Color("647b51"), Color("7f8d60"), Color("536d4f")]
	_rod(at, at + Vector3(0.17, 5.5, 0.12) * size, 0.22 * size, "wood", bark)
	for i in 8:
		var angle := i * 2.39996
		var height := 4.8 + i * 0.26
		var offset := Vector3(cos(angle) * _rng.randf_range(0.8, 1.7), height, sin(angle) * _rng.randf_range(0.7, 1.7))
		_rod(at + Vector3(0.1, 3.6 + i * 0.23, 0.1) * size, at + offset * size, 0.075 * size, "wood", bark)
		var crown := _crown_mesh(i)
		_add(crown, at + offset * size, "foliage", foliage[i % 3], Vector3(0, angle, 0), Vector3(1.45, 1.3, 1.4) * size)

func _crown_mesh(seed_value: int) -> ArrayMesh:
	# Deformed, layered crowns replace primitive green balls. Geometry-only leaves
	# avoid transparent alpha overdraw in the compatibility renderer.
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 14
	mesh.rings = 9
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise := FastNoiseLite.new()
	noise.seed = 601 + seed_value
	noise.frequency = 3.7
	for i in vertices.size():
		var point := vertices[i]
		vertices[i] = point * (1.0 + noise.get_noise_3dv(point) * 0.28 + sin(point.y * 19.0) * 0.045)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var altered := ArrayMesh.new()
	altered.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var tool := SurfaceTool.new()
	tool.create_from(altered, 0)
	tool.generate_normals()
	return tool.commit()
