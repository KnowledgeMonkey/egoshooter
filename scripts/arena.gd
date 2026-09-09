class_name RelayArena
extends Node3D

var obstacles: Array[AABB] = []
var nav := AStarGrid2D.new()
var spawn_points: Array[Vector3] = []
var materials := {}
var building_origins: Array[Vector3] = []
var lifts: Array[Dictionary] = []
var vehicle_entries: Array[Vector3] = []
var vending_points: Array[Vector3] = []
var collision_only := false
const HALF_WIDTH := 45
const HALF_LENGTH := 64
const SPAWN_Z := 45
const ROAD = Color("39474d")
const CONCRETE = Color("b2b7ad")
const TEAL = Color("337f80")
const OCHRE = Color("c59857")

func _ready() -> void:
	build()
	build_navigation()

func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		materials[color] = UrbanMaterials.get_surface("concrete", color.lightened(0.25))
	return materials[color]

func box(pos: Vector3, size: Vector3, color: Color, solid: bool = true) -> Node3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material(color)
	if size.y < 0.7 and size.x > 50:
		mesh.material_override = UrbanMaterials.get_surface("sand", Color("b6a28a"))
	if color == ROAD:
		mesh.material_override = UrbanMaterials.get_surface("asphalt", Color("a8aaa7"))
		if absf(pos.x) == 39:
			mesh.material_override = UrbanMaterials.get_surface("sand", Color("c8b194"))
	if size.y == 4.4:
		mesh.material_override = UrbanMaterials.get_surface("rock", Color("b1b0a5"))
	if not solid and size.y < 0.05 and color != ROAD:
		mesh.material_override = UrbanMaterials.get_surface("paint", color)
	mesh.visible = not collision_only
	mesh.position = pos
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.add_child(shape)
		mesh.add_child(body)
		if pos.y + size.y / 2.0 > 0.45:
			obstacles.append(AABB(pos - size / 2.0, size))
	return mesh

func sign_text(words: String, pos: Vector3, yaw: float, tint: Color = Color.WHITE, font_size: int = 70) -> void:
	var label := Label3D.new()
	label.text = words
	label.font_size = font_size
	label.pixel_size = 0.009
	label.modulate = tint
	label.outline_size = 0
	label.position = pos
	label.rotation.y = yaw
	add_child(label)

func building(x: float, z: float, tint: Color, title: String) -> void:
	building_origins.append(Vector3(x, 0, z))
	collision_only = true
	# Two opposite doors plus a side door: a compact interior is a cross-route.
	box(Vector3(x, 0.05, z), Vector3(9, 0.1, 11), CONCRETE)
	for end in [-1, 1]:
		for side in [-1, 1]:
			box(Vector3(x + side * 3.05, 1.7, z + end * 5.5), Vector3(2.9, 3.4, 0.35), tint)
		box(Vector3(x, 3.05, z + end * 5.5), Vector3(3.2, 0.7, 0.35), tint)
	for side in [-1, 1]:
		for end in [-1, 1]:
			box(Vector3(x + side * 4.5, 1.7, z + end * 3.8), Vector3(0.35, 3.4, 3.4), tint)
		box(Vector3(x + side * 4.5, 3.05, z), Vector3(0.35, 0.7, 4.4), tint)
	box(Vector3(x - 2, 0.65, z), Vector3(1.7, 1.3, 2.4), Color("6e7773"))
	collision_only = false
	if DisplayServer.get_name() != "headless":
		add_child(UrbanArchitecture.build(x, z, tint, title))
	UrbanFloors.build(self, x, z, tint)

func car(x: float, z: float, tint: Color, long_vehicle: bool = false) -> void:
	collision_only = true
	var length := 6.5 if long_vehicle else 4.6
	box(Vector3(x, 0.65, z), Vector3(2.3, 1.1, length), tint)
	box(Vector3(x, 1.45, z - 0.3), Vector3(2.05, 0.9, length * 0.56), Color("2b414b"))
	collision_only = false
	if DisplayServer.get_name() != "headless":
		var model := UrbanVehicles.build(tint, long_vehicle)
		model.position = Vector3(x, 0, z)
		add_child(model)

func build() -> void:
	box(Vector3(0, -0.3, 0), Vector3(HALF_WIDTH * 2 + 2, 0.6, HALF_LENGTH * 2 + 2), Color("7d8a7a"))
	for x in [-22, 0, 22]:
		box(Vector3(x, 0.012, 0), Vector3(10, 0.025, HALF_LENGTH * 2 - 2), ROAD, false)
	for z in [-55, -39, -31, 0, 31, 39, 55]:
		box(Vector3(0, 0.018, z), Vector3(HALF_WIDTH * 2 - 2, 0.03, 7), ROAD, false)
	for z in range(-43, 45, 5):
		box(Vector3(0, 0.04, z), Vector3(0.14, 0.025, 2.4), Color("cebb8b"), false)
	for x in [-HALF_WIDTH, HALF_WIDTH]:
		box(Vector3(x, 2.2, 0), Vector3(1, 4.4, HALF_LENGTH * 2), Color("718780"))
	for z in [-HALF_LENGTH, HALF_LENGTH]:
		box(Vector3(0, 2.2, z), Vector3(HALF_WIDTH * 2, 4.4, 1), Color("718780"))
	building(-11, -18, TEAL, "RELAY / 01")
	building(11, 18, OCHRE, "ATELIER / 04")
	building(11, -18, Color("abb8b1"), "NORTH MARKET")
	building(-11, 18, Color("bd9d85"), "MOTOR WORKS")
	car(-2.5, -6, OCHRE, true)
	car(2.8, 11, Color("b8c4bd"))
	car(-22, -18, Color("373c37"))
	car(23, 19, Color("423d35"))
	for pos in [Vector3(-19, 0.7, 12), Vector3(-19, 0.7, -3), Vector3(20, 0.7, -10), Vector3(27, 0.7, 13), Vector3(3, 0.7, -22), Vector3(-3, 0.7, 24)]:
		box(pos, Vector3(3.2, 1.4, 1.5), CONCRETE).visible = false
		if DisplayServer.get_name() != "headless":
			add_child(UrbanCover.build(pos, Vector3(3.2, 1.4, 1.5)))
	# Dogleg spawn shields prevent a single straight line across both bases.
	for z in [-35, 35]:
		box(Vector3(0, 1.9, z), Vector3(13, 3.8, 0.65), TEAL if z > 0 else OCHRE)
		for x in [-26, -13, 0, 13, 26]:
			spawn_points.append(Vector3(x, 0.15, sign(z) * SPAWN_Z))
			spawn_shelter(x, sign(z))
		for x in [-14, 14]:
			box(Vector3(x, 1.3, z + sign(z) * 2), Vector3(0.55, 2.6, 4.2), CONCRETE)
	# Added side courtyards remain connected to the existing lanes.
	for x in [-32, 32]:
		for z in [-19, 3, 23]:
			var pos := Vector3(x, 0.7, z)
			box(pos, Vector3(3.2, 1.4, 1.5), CONCRETE).visible = false
			if DisplayServer.get_name() != "headless":
				add_child(UrbanCover.build(pos, Vector3(3.2, 1.4, 1.5)))
	for x in [-23, 23]:
		# Reachable platform with two stair approaches, broken side sightlines.
		box(Vector3(x, 1.1, 0), Vector3(4, 2.2, 5), Color("657b7c"))
		for end in [-1, 1]:
			for step in range(11):
				var h := (step + 1) * 0.2
				box(Vector3(x, h / 2, end * (7.75 - step * 0.5)), Vector3(3, h, 0.5), CONCRETE)
		box(Vector3(x + sign(x) * 1.8, 2.75, 0), Vector3(0.35, 1.1, 5), TEAL)
		box(Vector3(x - sign(x) * 1.8, 2.6, 0), Vector3(0.35, 0.8, 2), CONCRETE)
	WarDistrict.build(self)
	QuarryLandscape.build_routes(self)
	if DisplayServer.get_name() != "headless":
		add_child(UrbanDetails.build())
		DepotDetails.build(self)
		QuarryLandscape.build(self)
	sign_text("RELAY / QUARRY 07", Vector3(0, 3, -HALF_LENGTH + 0.6), 0, Color("f2d8a4"), 110)
	sign_text("BLOCKLINE  /  SOUTH", Vector3(0, 3, HALF_LENGTH - 0.6), PI, Color("bce4de"), 85)
	UrbanLighting.build(self)

func spawn_shelter(x: float, side: float) -> void:
	var z := side * SPAWN_Z
	# Front baffle + canopy stop elevated fire; both side exits remain open.
	box(Vector3(x, 3.3, z), Vector3(9.6, 0.3, 6.6), CONCRETE)
	box(Vector3(x, 1.65, z - side * 2.9), Vector3(9.4, 3.3, 0.3), TEAL if side > 0 else OCHRE)
	for dx in [-4.55, 4.55]:
		box(Vector3(x + dx, 1.65, z - side * 1.65), Vector3(0.3, 3.3, 2.7), CONCRETE)
		box(Vector3(x + dx, 1.65, z + side * 2.8), Vector3(0.25, 3.3, 0.25), CONCRETE)

func blocked(pos: Vector3) -> bool:
	var clearance := AABB(pos + Vector3(-0.48, -0.95, -0.48), Vector3(0.96, 1.8, 0.96))
	for bounds in obstacles:
		if bounds.intersects(clearance):
			return true
	return false

func build_navigation() -> void:
	nav.region = Rect2i(-HALF_WIDTH + 1, -HALF_LENGTH + 2, HALF_WIDTH * 2 - 1, HALF_LENGTH * 2 - 3)
	nav.cell_size = Vector2.ONE
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for x in range(-HALF_WIDTH + 1, HALF_WIDTH):
		for z in range(-HALF_LENGTH + 2, HALF_LENGTH - 1):
			if blocked(Vector3(x, 1, z)):
				nav.set_point_solid(Vector2i(x, z))

func path(from: Vector3, to: Vector3) -> PackedVector2Array:
	var a := Vector2i(roundi(from.x), roundi(from.z))
	var b := Vector2i(clampi(roundi(to.x), -HALF_WIDTH + 2, HALF_WIDTH - 2), clampi(roundi(to.z), -HALF_LENGTH + 3, HALF_LENGTH - 3))
	if not nav.is_in_boundsv(a) or nav.is_point_solid(a) or nav.is_point_solid(b):
		return PackedVector2Array()
	return nav.get_point_path(a, b)

