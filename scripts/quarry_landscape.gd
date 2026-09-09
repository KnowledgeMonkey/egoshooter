class_name QuarryLandscape
extends RefCounted

const CLIFF := "res://assets/quarry/namaqualand_cliff_02/namaqualand_cliff_02.gltf"
const BOULDER := "res://assets/quarry/namaqualand_boulder_03/namaqualand_boulder_03.gltf"
static var templates := {}

static func build_routes(arena: RelayArena) -> void:
 var root := Node3D.new(); root.name = "QuarryRouteRocks"; arena.add_child(root)
 for side in [-1, 1]:
  var center := Vector3(side * 32, -2.0, -side * 12)
  var size := Vector3(11, 12, 22)
  place(root, BOULDER, center, size, side * PI / 2, true)
  arena.obstacles.append(AABB(Vector3(center.x - size.x / 2, center.y, center.z - size.z / 2), size))

static func build(arena: RelayArena) -> void:
 var root := Node3D.new(); root.name = "QuarryEscarpment"; arena.add_child(root)
 # Scanned forms sit behind the existing retaining-wall collision envelope.
 # Their uneven silhouette replaces the exposed edge of the flat arena.
 for side in [-1, 1]:
  for i in 6:
   var z := -65.0 + i * 25.0
   var height := 15.0 + 8.0 * (0.5 + 0.5 * sin(i * 2.3 + side))
   place(root, CLIFF, Vector3(side * 58.5, -8.0, z), Vector3(27, height + 7, 32), side * PI / 2 + i * 0.15)
  for i in 4:
   var x := -43.5 + i * 29.0
   place(root, CLIFF, Vector3(x, -8.0, side * 80), Vector3(34, 25 + i % 3 * 4, 32), (PI if side > 0 else 0.0) + i * 0.13)
 # Lower fragments meet the retaining wall, rather than hovering above the ground.
 for side in [-1, 1]:
  for i in 9:
   place(root, BOULDER, Vector3(side * 48.4, -0.3, -60 + i * 15), Vector3(7.8, 4.0 + i % 3, 10), i * 0.71)
 # A thin dust skirt blends the new quarry floor into the retaining walls.
 for side in [-1, 1]:
  dust_skirt(root, side)

static func collect(node: Node, transform: Transform3D, result: Array) -> void:
 var current := transform
 if node is Node3D: current = transform * node.transform
 if node is MeshInstance3D: result.append([node.mesh, current])
 for child in node.get_children(): collect(child, current, result)

static func template(path: String) -> Array:
 if not templates.has(path):
  var scene: Node3D = load(path).instantiate()
  var entries := []
  collect(scene, Transform3D.IDENTITY, entries)
  templates[path] = entries
  scene.free()
 return templates[path]

static func place(root: Node3D, path: String, center: Vector3, dimensions: Vector3, yaw: float, solid := false) -> void:
 var entries := template(path)
 var turn := Transform3D(Basis(Vector3.UP, yaw), Vector3.ZERO)
 var bounds := AABB()
 var first := true
 for entry in entries:
  var box: AABB = (turn * entry[1]) * entry[0].get_aabb()
  bounds = box if first else bounds.merge(box)
  first = false
 var scale_value := dimensions / bounds.size
 var basis := Basis.from_scale(scale_value)
 var offset := center - basis * Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
 var fit := Transform3D(basis, offset)
 for entry in entries:
  var instance := MeshInstance3D.new()
  instance.mesh = entry[0]
  instance.transform = fit * turn * entry[1]
  instance.visibility_range_end = 260
  instance.lod_bias = 0.55
  root.add_child(instance)
  if solid:
   instance.create_trimesh_collision()
   instance.visible = DisplayServer.get_name() != "headless"

static func dust_skirt(root: Node3D, side: int) -> void:
 var material := UrbanMaterials.get_surface("sand", Color("baa081")).duplicate() as StandardMaterial3D
 material.vertex_color_use_as_albedo = true
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in 128:
  var z := -64.0 + i
  var inner := 42.9 + sin(z * 0.7) * 0.3
  var points := [Vector3(side * 44.48, 0.042, z), Vector3(side * inner, 0.044, z), Vector3(side * (42.9 + sin((z + 1) * 0.7) * 0.3), 0.044, z + 1), Vector3(side * 44.48, 0.042, z + 1)]
  for index in [0, 1, 2, 0, 2, 3]:
   tool.set_normal(Vector3.UP); tool.set_color(Color(1, 1, 1, 1.0 if index in [0, 3] else 0.0)); tool.set_uv(Vector2(points[index].x, points[index].z)); tool.add_vertex(points[index])
 var mesh := MeshInstance3D.new(); mesh.mesh = tool.commit(); mesh.material_override = material
 # A separate alpha-faded mesh keeps the full floor opaque and inexpensive.
 root.add_child(mesh)

