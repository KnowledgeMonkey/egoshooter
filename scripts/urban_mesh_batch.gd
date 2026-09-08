class_name UrbanMeshBatch
extends RefCounted

# Static city detail is merged into one mesh per material, rather than one node
# per bolt, brick or frame. All dimensions are metres. No physics is added here.
var _surfaces: Dictionary = {}
var _materials: Dictionary = {}

func _surface(kind: String, tint: Color) -> SurfaceTool:
	var key := kind + tint.to_html()
	if not _surfaces.has(key):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		_surfaces[key] = tool
		_materials[key] = UrbanMaterials.get_surface(kind, tint)
	return _surfaces[key]

func mesh(source: Mesh, position: Vector3, kind: String, tint: Color = Color.WHITE, angles: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE) -> void:
	var basis := Basis.from_euler(angles).scaled(scale_value)
	var normalized := SurfaceTool.new()
	normalized.create_from(source, 0)
	normalized.deindex()
	_surface(kind, tint).append_from(normalized.commit(), 0, Transform3D(basis, position))

func box(position: Vector3, size: Vector3, kind: String, tint: Color = Color.WHITE, angles: Vector3 = Vector3.ZERO) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	mesh(shape, position, kind, tint, angles)

func cylinder(position: Vector3, radius: float, height: float, kind: String, tint: Color = Color.WHITE, angles: Vector3 = Vector3.ZERO, top_radius: float = -1.0) -> void:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top_radius < 0 else top_radius
	shape.height = height
	shape.radial_segments = 16
	shape.rings = 1
	mesh(shape, position, kind, tint, angles)

func sphere(position: Vector3, size: Vector3, kind: String, tint: Color = Color.WHITE) -> void:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 16
	shape.rings = 8
	mesh(shape, position, kind, tint, Vector3.ZERO, size)

func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (c - a).cross(b - a).normalized()
	for vertex in [a, b, c]:
		tool.set_normal(normal)
		tool.set_uv(Vector2(vertex.x + vertex.z, vertex.y))
		tool.add_vertex(vertex)

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, kind: String, tint: Color = Color.WHITE, double_sided: bool = false) -> void:
	var tool := _surface(kind, tint)
	_triangle(tool, a, b, c)
	_triangle(tool, a, c, d)
	if double_sided:
		_triangle(tool, c, b, a)
		_triangle(tool, d, c, a)

# Profile points are (Z,Y). Bevel rings give sloping bodywork and softened
# concrete edges without a heavyweight external asset dependency.
func profile(points: PackedVector2Array, width: float, position: Vector3, kind: String, tint: Color = Color.WHITE, bevel: float = 0.06) -> void:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= points.size()
	var rings: Array[PackedVector3Array] = []
	var safe_bevel := minf(bevel, width * 0.2)
	for ring_index in 4:
		var ring := PackedVector3Array()
		var x: float = [-width * 0.5, -width * 0.5 + safe_bevel, width * 0.5 - safe_bevel, width * 0.5][ring_index]
		for point in points:
			var offset := (center - point).normalized() * safe_bevel if ring_index in [0, 3] else Vector2.ZERO
			ring.append(position + Vector3(x, point.y + offset.y, point.x + offset.x))
		rings.append(ring)
	var surface := _surface(kind, tint)
	for ring_index in 3:
		for i in points.size():
			var j := (i + 1) % points.size()
			_triangle(surface, rings[ring_index][i], rings[ring_index + 1][j], rings[ring_index + 1][i])
			_triangle(surface, rings[ring_index][i], rings[ring_index][j], rings[ring_index + 1][j])
	var indices := Geometry2D.triangulate_polygon(points)
	for i in range(0, indices.size(), 3):
		_triangle(surface, rings[0][indices[i]], rings[0][indices[i + 2]], rings[0][indices[i + 1]])
		_triangle(surface, rings[3][indices[i + 2]], rings[3][indices[i]], rings[3][indices[i + 1]])

func bevel_box(position: Vector3, size: Vector3, kind: String, tint: Color = Color.WHITE, bevel: float = 0.06) -> void:
	var half_z := size.z * 0.5
	var half_y := size.y * 0.5
	var cut := minf(bevel, minf(half_y, half_z) * 0.35)
	profile(PackedVector2Array([Vector2(-half_z + cut, -half_y), Vector2(half_z - cut, -half_y),
		Vector2(half_z, -half_y + cut), Vector2(half_z, half_y - cut),
		Vector2(half_z - cut, half_y), Vector2(-half_z + cut, half_y),
		Vector2(-half_z, half_y - cut), Vector2(-half_z, -half_y + cut)]), size.x, position, kind, tint, cut)

func finish(parent: Node3D, name_prefix: String = "Static") -> void:
	for key in _surfaces:
		var tool: SurfaceTool = _surfaces[key]
		tool.index()
		var result := MeshInstance3D.new()
		result.name = name_prefix + "_" + str(key)
		result.mesh = tool.commit()
		result.material_override = _materials[key]
		parent.add_child(result)
	_surfaces.clear()
	_materials.clear()
