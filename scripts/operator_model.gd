class_name OperatorModel
extends Node3D

# Visual rig only. Hitboxes, movement and the network capsule belong to Fighter.
# All proportions are in metres; the operator faces -Z.
const G = preload("res://scripts/weapon_geometry.gd")
static var palette: Dictionary = {}
static var models: Dictionary = {}
var upper: Node3D
var head: Node3D
var weapon_mount: Node3D
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var stride := 0.0
var movement := 0.0

func setup(team: int) -> void:
	name = "OperatorModel"
	if models.has(team):
		add_child(models[team].instantiate())
	else:
		var rig := Node3D.new()
		rig.name = "Rig"
		add_child(rig)
		build(rig, team)
		WeaponModels.assign_owner(rig, rig)
		var packed := PackedScene.new()
		packed.pack(rig)
		models[team] = packed
	var root := get_node("Rig")
	upper = root.get_node("Upper")
	head = upper.get_node("Head")
	weapon_mount = upper.get_node("WeaponMount")
	for side in ["L", "R"]:
		var hip: Node3D = root.get_node("Hip" + side)
		hips.append(hip)
		knees.append(hip.get_node("Knee"))

static func material(key: String) -> StandardMaterial3D:
	if palette.has(key):
		return palette[key]
	var colors := {"fabric": "54594f", "fabric_dark": "3c423b", "webbing": "797864",
		"armor": "363d3c", "rubber": "202927", "leather": "404139", "lens": "293d41",
		"edge": "8a948c", "teal": "3eb6b3", "orange": "d98354", "thread": "a5a28b"}
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(colors.get(key, "54594f"))
	mat.roughness = 0.84
	if key == "lens":
		mat.metallic = 0.58
		mat.roughness = 0.17
	elif key == "edge":
		mat.metallic = 0.55
		mat.roughness = 0.4
	elif key in ["fabric", "fabric_dark", "webbing", "leather"]:
		var image := Image.create(64, 64, false, Image.FORMAT_RGB8)
		for y in 64:
			for x in 64:
				var grain := 0.79 + 0.13 * float((x * 31 + y * 17) % 11) / 10.0
				var weave := 0.08 if (x % 4 < 2) != (y % 4 < 2) else 0.0
				image.set_pixel(x, y, Color.WHITE * (grain + weave))
		image.generate_mipmaps()
		mat.albedo_texture = ImageTexture.create_from_image(image)
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3.ONE * 16
	palette[key] = mat
	return mat

static func attach(parent: Node3D, mesh: Mesh, pos: Vector3, key: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = material(key)
	parent.add_child(node)
	return node

static func oval(parent: Node3D, pos: Vector3, size: Vector3, key: String) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 10
	var node := attach(parent, mesh, pos, key)
	node.scale = size
	return node

static func panel(parent: Node3D, pos: Vector3, size: Vector3, key: String, rot := Vector3.ZERO) -> MeshInstance3D:
	var node := G.block(parent, pos, size, "polymer", rot)
	node.material_override = material(key)
	return node

# Contoured elliptical rings form fabric volume and tapered anatomy, with smooth
# analytic normals rather than sharp box faces. Vector4: Y, radius X/Z, offset Z.
static func loft(parent: Node3D, rings: Array[Vector4], pos: Vector3, key: String, sides := 16) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for r in rings.size():
		var ring := rings[r]
		var previous := rings[maxi(0, r - 1)]
		var next := rings[mini(rings.size() - 1, r + 1)]
		for i in sides + 1:
			var angle := float(i) * TAU / sides
			var sx := sin(angle)
			var cz := cos(angle)
			vertices.append(Vector3(sx * ring.y, ring.x, cz * ring.z + ring.w))
			var tangent := Vector3(cz * ring.y, 0, -sx * ring.z)
			var vertical := Vector3(sx * (next.y - previous.y), next.x - previous.x,
				cz * (next.z - previous.z) + next.w - previous.w)
			normals.append(tangent.cross(vertical).normalized())
			uvs.append(Vector2(float(i) / sides, ring.x))
	for r in rings.size() - 1:
		for i in sides:
			var a := r * (sides + 1) + i
			var b := a + sides + 1
			indices.append_array(PackedInt32Array([a, b, b + 1, a, b + 1, a + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return attach(parent, mesh, pos, key)

static func limb(parent: Node3D, start: Vector3, finish: Vector3, radius: float, tip: float, key: String) -> MeshInstance3D:
	var length := start.distance_to(finish)
	var mesh := loft(parent, [Vector4(0, radius * 0.45, radius * 0.45, 0),
		Vector4(length * 0.1, radius * 0.94, radius * 0.86, 0),
		Vector4(length * 0.3, radius, radius * 0.95, 0),
		Vector4(length * 0.58, lerpf(radius, tip, 0.55), lerpf(radius, tip, 0.55) * 0.91, 0),
		Vector4(length * 0.87, tip, tip * 0.9, 0),
		Vector4(length, tip * 0.68, tip * 0.68, 0)], start, key)
	mesh.quaternion = Quaternion(Vector3.UP, (finish - start).normalized())
	return mesh

static func bone(parent: Node3D, label: String, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = pos
	parent.add_child(node)
	return node

static func build(rig: Node3D, team: int) -> void:
	var accent := "teal" if team == 0 else "orange"
	var body := bone(rig, "Upper", Vector3.ZERO)
	# Contoured jacket: hips, waist, rib cage, shoulders and collar.
	loft(body, [Vector4(0.81, 0.17, 0.10, 0.02), Vector4(0.89, 0.21, 0.135, 0.02),
		Vector4(1.01, 0.19, 0.13, 0.015), Vector4(1.13, 0.215, 0.145, 0),
		Vector4(1.31, 0.24, 0.14, 0), Vector4(1.41, 0.245, 0.12, 0.015),
		Vector4(1.465, 0.15, 0.10, 0.025), Vector4(1.49, 0.08, 0.07, 0.02)], Vector3.ZERO, "fabric")
	# Rounded armor carrier plates, side closures, shoulder harness and MOLLE.
	panel(body, Vector3(0, 1.245, -0.129), Vector3(0.37, 0.36, 0.075), "armor")
	panel(body, Vector3(0, 1.26, -0.176), Vector3(0.31, 0.265, 0.035), "fabric_dark")
	panel(body, Vector3(0, 1.12, 0.149), Vector3(0.325, 0.33, 0.11), "webbing")
	oval(body, Vector3(0, 1.34, 0.156), Vector3(0.31, 0.23, 0.13), "fabric_dark")
	for side in [-1, 1]:
		panel(body, Vector3(side * 0.157, 1.414, 0.006), Vector3(0.063, 0.045, 0.29), "webbing", Vector3(0, 0, side * -0.24))
		panel(body, Vector3(side * 0.171, 1.365, -0.14), Vector3(0.066, 0.06, 0.029), "rubber")
		panel(body, Vector3(side * 0.198, 1.05, 0), Vector3(0.07, 0.12, 0.27), "webbing")
		panel(body, Vector3(side * 0.15, 1.075, -0.17), Vector3(0.072, 0.17, 0.052), "webbing")
		for row in 3:
			panel(body, Vector3(side * 0.085, 1.20 + row * 0.044, -0.2), Vector3(0.085, 0.015, 0.009), "webbing")
		for row in 3:
			panel(body, Vector3(side * 0.18, 1.03 + row * 0.09, 0.21), Vector3(0.05, 0.045, 0.02), "armor")
	for x in [-0.085, 0.0, 0.085]:
		panel(body, Vector3(x, 1.074, -0.21), Vector3(0.073, 0.155, 0.06), "webbing")
		panel(body, Vector3(x, 1.137, -0.244), Vector3(0.065, 0.043, 0.012), "fabric_dark")
	panel(body, Vector3(0, 1.358, -0.196), Vector3(0.108, 0.038, 0.008), accent)
	for x in [-0.027, 0, 0.027]:
		panel(body, Vector3(x, 1.36, -0.202), Vector3(0.008, 0.019, 0.003), "thread")
	# Belt and radio, with subdued material break-up on the back.
	loft(body, [Vector4(0.885, 0.215, 0.145, 0.015), Vector4(0.94, 0.21, 0.142, 0.015)], Vector3.ZERO, "rubber")
	panel(body, Vector3(0, 0.917, -0.136), Vector3(0.065, 0.038, 0.018), "edge")
	panel(body, Vector3(-0.233, 1.19, 0.025), Vector3(0.065, 0.12, 0.06), "rubber")
	limb(body, Vector3(-0.25, 1.24, 0.025), Vector3(-0.24, 1.45, 0.025), 0.004, 0.003, "rubber")
	limb(body, Vector3(0, 1.44, 0.015), Vector3(0, 1.56, 0.015), 0.069, 0.065, "fabric_dark")
	make_head(bone(body, "Head", Vector3(0, 1.615, 0.005)), accent)
	make_arms(body, accent)
	bone(body, "WeaponMount", Vector3(0.2, 1.25, -0.26))
	G.batch(body)
	for side in [-1, 1]:
		make_leg(rig, side)

static func make_head(node: Node3D, accent: String) -> void:
	oval(node, Vector3(0, -0.012, -0.014), Vector3(0.235, 0.296, 0.224), "fabric_dark")
	# The helmet has a full dome, rolled rim and side-mounted headset cups.
	loft(node, [Vector4(-0.012, 0.133, 0.136, 0.01), Vector4(0.035, 0.143, 0.146, 0.015),
		Vector4(0.094, 0.128, 0.133, 0.018), Vector4(0.145, 0.086, 0.09, 0.019),
		Vector4(0.166, 0.001, 0.001, 0.02)], Vector3.ZERO, "armor", 24)
	loft(node, [Vector4(-0.018, 0.135, 0.14, 0.01), Vector4(0.002, 0.143, 0.147, 0.01),
		Vector4(0.011, 0.141, 0.145, 0.01)], Vector3.ZERO, "rubber", 24)
	oval(node, Vector3(0, -0.005, -0.114), Vector3(0.246, 0.079, 0.079), "rubber")
	for side in [-1, 1]:
		var glass := oval(node, Vector3(side * 0.055, -0.004, -0.143), Vector3(0.101, 0.049, 0.022), "lens")
		glass.rotation.y = side * 0.12
		oval(node, Vector3(side * 0.128, -0.034, 0.017), Vector3(0.067, 0.123, 0.087), "rubber")
		panel(node, Vector3(side * 0.148, 0.011, 0.048), Vector3(0.022, 0.023, 0.095), "edge")
		panel(node, Vector3(side * 0.139, 0.057, 0.006), Vector3(0.018, 0.048, 0.081), accent)
		limb(node, Vector3(side * 0.109, -0.051, -0.01), Vector3(side * 0.061, -0.122, -0.071), 0.011, 0.009, "webbing")
	oval(node, Vector3(0, -0.067, -0.109), Vector3(0.113, 0.083, 0.055), "fabric_dark")
	for x in [-0.018, 0, 0.018]:
		panel(node, Vector3(x, -0.075, -0.135), Vector3(0.006, 0.023, 0.006), "rubber")
	panel(node, Vector3(0, 0.072, -0.128), Vector3(0.045, 0.058, 0.024), "rubber")
	panel(node, Vector3(0, 0.086, -0.144), Vector3(0.029, 0.021, 0.011), "edge")
	limb(node, Vector3(-0.148, -0.036, -0.01), Vector3(-0.08, -0.098, -0.137), 0.005, 0.004, "rubber")
	oval(node, Vector3(-0.07, -0.101, -0.145), Vector3(0.031, 0.014, 0.017), "rubber")
	G.batch(node)

static func make_arms(body: Node3D, accent: String) -> void:
	for side in [-1, 1]:
		var shoulder := Vector3(side * 0.245, 1.387, 0.012)
		var elbow := Vector3(0.353, 1.083, -0.025) if side == 1 else Vector3(-0.287, 1.105, -0.206)
		var wrist := Vector3(0.218, 1.131, -0.185) if side == 1 else Vector3(0.167, 1.192, -0.49)
		limb(body, shoulder, elbow, 0.092, 0.065, "fabric")
		oval(body, shoulder, Vector3(0.20, 0.185, 0.203), "fabric")
		oval(body, elbow, Vector3(0.127, 0.11, 0.131), "armor")
		limb(body, elbow, wrist, 0.074, 0.046, "fabric")
		var patch := oval(body, shoulder + Vector3(side * 0.081, -0.038, -0.006), Vector3(0.048, 0.129, 0.13), accent)
		patch.rotation.z = side * -0.22
		for fold in [0.24, 0.48, 0.72]:
			var at := elbow.lerp(wrist, fold)
			var crease := oval(body, at, Vector3(0.124 - fold * 0.03, 0.025, 0.12 - fold * 0.025), "fabric_dark")
			crease.quaternion = Quaternion(Vector3.UP, (wrist - elbow).normalized())
		oval(body, wrist + Vector3(0, -0.006, -0.029), Vector3(0.093, 0.095, 0.121), "leather")
		for finger in 4:
			oval(body, wrist + Vector3(-0.025 + finger * 0.017, 0.029, -0.067), Vector3(0.019, 0.04, 0.05), "rubber")

static func make_leg(rig: Node3D, side: int) -> void:
	var hip := bone(rig, "HipL" if side < 0 else "HipR", Vector3(side * 0.132, 0.884, 0.016))
	limb(hip, Vector3.ZERO, Vector3(side * 0.018, -0.408, -0.009), 0.123, 0.089, "fabric")
	oval(hip, Vector3(side * 0.083, -0.19, 0.014), Vector3(0.092, 0.185, 0.17), "fabric_dark")
	panel(hip, Vector3(side * 0.103, -0.141, -0.014), Vector3(0.043, 0.053, 0.153), "webbing")
	var knee := bone(hip, "Knee", Vector3(side * 0.018, -0.408, -0.009))
	oval(knee, Vector3(0, 0.01, -0.062), Vector3(0.15, 0.15, 0.086), "armor")
	oval(knee, Vector3(0, 0.012, -0.098), Vector3(0.104, 0.104, 0.028), "rubber")
	limb(knee, Vector3(0, -0.015, 0), Vector3(0, -0.321, 0.019), 0.09, 0.059, "fabric")
	for y in [-0.103, -0.219]:
		oval(knee, Vector3(0, y, 0.017), Vector3(0.16, 0.043, 0.148), "fabric_dark")
	oval(knee, Vector3(0, -0.332, 0.016), Vector3(0.146, 0.19, 0.161), "leather")
	oval(knee, Vector3(0, -0.392, -0.047), Vector3(0.157, 0.128, 0.276), "leather")
	panel(knee, Vector3(0, -0.431, -0.043), Vector3(0.163, 0.043, 0.281), "rubber")
	oval(knee, Vector3(0, -0.389, -0.125), Vector3(0.15, 0.073, 0.104), "rubber")
	for row in 4:
		panel(knee, Vector3(0, -0.335 - row * 0.011, -0.043 - row * 0.018), Vector3(0.067, 0.007, 0.007), "webbing", Vector3(0, (1 if row % 2 else -1) * 0.19, 0))
	G.batch(hip)
	G.batch(knee)

func animate(dt: float, speed: float, view_pitch: float, crouching: bool) -> void:
	movement = move_toward(movement, clampf(speed / 6.0, 0, 1.35), dt * 8)
	stride += dt * lerpf(4.0, 11.5, minf(movement, 1.0))
	var amount := movement * (0.3 if crouching else 0.53)
	for index in 2:
		var phase := stride + index * PI
		hips[index].rotation.x = sin(phase) * amount
		knees[index].rotation.x = maxf(0, -sin(phase)) * amount * 1.05
	upper.position.y = absf(cos(stride)) * movement * 0.018
	upper.rotation.z = sin(stride) * movement * 0.015
	upper.rotation.x = -movement * 0.025
	head.rotation.x = clampf(view_pitch * 0.6, -0.48, 0.42)
