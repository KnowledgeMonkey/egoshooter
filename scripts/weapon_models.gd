class_name WeaponModels
extends RefCounted

const G = preload("res://scripts/weapon_geometry.gd")
static var cache := {}

static func build(index: int) -> Node3D:
	if cache.has(index):
		return cache[index].instantiate()
	var root := Node3D.new()
	root.name = "WeaponModel"
	var frame := Node3D.new()
	frame.name = "Frame"
	root.add_child(frame)
	var magazine := Node3D.new()
	magazine.name = "Magazine"
	root.add_child(magazine)
	var bolt := Node3D.new()
	bolt.name = "Bolt"
	root.add_child(bolt)
	match index:
		0: rifle(frame, magazine, bolt)
		1: smg(frame, magazine, bolt)
		2: shotgun(frame, magazine, bolt)
		3: sniper(frame, magazine, bolt)
		4: pistol(frame, magazine, bolt)
	G.batch(frame)
	G.batch(magazine)
	G.batch(bolt)
	assign_owner(root, root)
	var scene := PackedScene.new()
	scene.pack(root)
	cache[index] = scene
	return root

static func assign_owner(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		assign_owner(child, owner_node)

static func grip(parent: Node3D, z: float, key: String = "polymer") -> void:
	G.profile(parent, PackedVector2Array([Vector2(z - 0.025, -0.03), Vector2(z + 0.03, -0.045),
		Vector2(z + 0.082, -0.18), Vector2(z + 0.027, -0.192), Vector2(z - 0.017, -0.10)]), 0.044, Vector3.ZERO, key)
	for i in 7:
		G.block(parent, Vector3(0, -0.091 - i * 0.012, z + 0.035 + i * 0.004), Vector3(0.046, 0.003, 0.045), "rubber", Vector3(-0.32, 0, 0))
	# Open trigger guard, curved trigger and a safety lever.
	G.block(parent, Vector3(0, -0.094, z - 0.038), Vector3(0.015, 0.008, 0.073), "black")
	G.block(parent, Vector3(0, -0.066, z - 0.07), Vector3(0.015, 0.06, 0.008), "black")
	G.block(parent, Vector3(0, -0.065, z - 0.034), Vector3(0.009, 0.035, 0.009), "silver", Vector3(0.3, 0, 0))

static func stock(parent: Node3D, key: String, precision: bool = false) -> void:
	G.tube(parent, Vector3(0, 0, 0.12), 0.019, 0.2, "steel")
	G.profile(parent, PackedVector2Array([Vector2(0.07, 0.026), Vector2(0.32, 0.033),
		Vector2(0.34, -0.11), Vector2(0.28, -0.115), Vector2(0.18, -0.052), Vector2(0.07, -0.024)]), 0.06, Vector3.ZERO, key)
	G.block(parent, Vector3(0, -0.043, 0.34), Vector3(0.067, 0.148, 0.022), "rubber")
	G.block(parent, Vector3(0, 0.035, 0.24), Vector3(0.064, 0.025, 0.135), "polymer")
	for z in [0.17, 0.23, 0.29]:
		G.screw(parent, Vector3(0.034, -0.035, z))
	if precision:
		G.block(parent, Vector3(0, 0.065, 0.23), Vector3(0.06, 0.035, 0.14), "rubber")
		G.tube(parent, Vector3(0.048, -0.065, 0.23), 0.017, 0.018, "edge", Vector3(0, 0, PI / 2))

static func barrel(parent: Node3D, z: float, length: float, radius: float = 0.011) -> void:
	G.tube(parent, Vector3(0, 0.016, z), radius, length, "steel")
	var tip := z - length / 2
	G.tube(parent, Vector3(0, 0.016, tip - 0.018), radius * 1.6, 0.044, "black")
	G.tube(parent, Vector3(0, 0.016, tip - 0.041), radius * 0.76, 0.002, "rubber")
	for i in 3:
		G.block(parent, Vector3(radius * 1.6, 0.016, tip - 0.004 - i * 0.012), Vector3(0.002, 0.014, 0.006), "rubber")

static func optic(parent: Node3D, z: float, scope: bool = false) -> void:
	if scope:
		for at in [z - 0.075, z + 0.06]:
			G.block(parent, Vector3(0, 0.077, at), Vector3(0.042, 0.032, 0.027), "steel")
			G.tube(parent, Vector3(0, 0.108, at), 0.027, 0.017, "edge")
		G.tube(parent, Vector3(0, 0.108, z), 0.022, 0.27, "black")
		G.tube(parent, Vector3(0, 0.108, z - 0.165), 0.035, 0.065, "black", Vector3(PI / 2, 0, 0), 0.022)
		G.tube(parent, Vector3(0, 0.108, z + 0.155), 0.032, 0.05, "rubber")
		G.tube(parent, Vector3(0, 0.108, z + 0.181), 0.025, 0.001, "glass")
		G.tube(parent, Vector3(0, 0.145, z), 0.018, 0.023, "edge", Vector3.ZERO)
		G.tube(parent, Vector3(0.032, 0.108, z), 0.018, 0.023, "edge", Vector3(0, 0, PI / 2))
		for i in 14:
			var angle := i * TAU / 14
			G.block(parent, Vector3(sin(angle) * 0.033, 0.108 + cos(angle) * 0.033, z + 0.14), Vector3(0.004, 0.005, 0.028), "edge", Vector3(0, 0, -angle))
	else:
		G.block(parent, Vector3(0, 0.077, z), Vector3(0.047, 0.022, 0.065), "black")
		for side in [-1, 1]:
			G.block(parent, Vector3(side * 0.023, 0.11, z), Vector3(0.007, 0.046, 0.022), "edge")
		G.block(parent, Vector3(0, 0.134, z), Vector3(0.047, 0.007, 0.022), "edge")
		G.block(parent, Vector3(0, 0.092, z + 0.012), Vector3(0.006, 0.004, 0.006), "red")

static func magazine(parent: Node3D, z: float, length: float, key: String, curve: float = 0.025) -> void:
	G.profile(parent, PackedVector2Array([Vector2(z - 0.035, -0.035), Vector2(z + 0.035, -0.035),
		Vector2(z + 0.035 + curve, -length), Vector2(z - 0.032 + curve, -length - 0.012)]), 0.043, Vector3.ZERO, key)
	for side in [-1, 1]:
		for rib in 3:
			G.block(parent, Vector3(side * 0.023, -length * 0.6, z - 0.022 + rib * 0.02 + curve / 2), Vector3(0.003, length * 0.6, 0.004), "black", Vector3(-curve * 2, 0, 0))
	G.block(parent, Vector3(0, -length, z + curve), Vector3(0.051, 0.015, 0.077), "rubber")

static func rifle(frame: Node3D, mag: Node3D, bolt: Node3D) -> void:
	G.block(frame, Vector3(0, 0, -0.075), Vector3(0.069, 0.085, 0.225), "steel")
	G.block(frame, Vector3(0, -0.038, -0.055), Vector3(0.062, 0.045, 0.19), "black")
	G.block(frame, Vector3(0, 0.005, -0.305), Vector3(0.075, 0.075, 0.245), "sand")
	for side in [-1, 1]:
		for i in 7:
			G.block(frame, Vector3(side * 0.038, 0.004, -0.22 - i * 0.026), Vector3(0.002, 0.018, 0.016), "black")
		for z in [-0.04, -0.14, -0.2, -0.4]:
			G.screw(frame, Vector3(side * 0.04, -0.022, z))
	barrel(frame, -0.46, 0.12)
	stock(frame, "sand")
	grip(frame, 0.015)
	magazine(mag, -0.115, 0.2, "sand")
	G.block(bolt, Vector3(0.036, 0.006, -0.09), Vector3(0.004, 0.024, 0.065), "silver")
	G.block(frame, Vector3(0.04, -0.025, -0.09), Vector3(0.007, 0.012, 0.066), "black")
	G.rail(frame, 0.015, -0.43, 0.047)
	optic(frame, -0.06)
	G.label(frame, "KESTREL  /  AR-4\n5.56   •   BL-0427", Vector3(0.036, -0.014, -0.04), 26)

static func smg(frame: Node3D, mag: Node3D, bolt: Node3D) -> void:
	G.profile(frame, PackedVector2Array([Vector2(0.05, 0.037), Vector2(-0.28, 0.037), Vector2(-0.31, -0.01),
		Vector2(-0.25, -0.075), Vector2(-0.09, -0.085), Vector2(0.05, -0.04)]), 0.065, Vector3.ZERO, "polymer")
	G.block(frame, Vector3(0, 0.018, -0.1), Vector3(0.07, 0.056, 0.27), "black")
	grip(frame, 0.01)
	magazine(mag, -0.095, 0.25, "steel", 0.008)
	barrel(frame, -0.335, 0.09)
	for side in [-1, 1]:
		G.tube(frame, Vector3(side * 0.025, 0.006, 0.17), 0.007, 0.27, "edge")
	G.block(frame, Vector3(0, -0.032, 0.3), Vector3(0.065, 0.11, 0.025), "rubber")
	for i in 6:
		G.block(frame, Vector3(0.034, -0.015, -0.15 - i * 0.02), Vector3(0.002, 0.019, 0.007), "rubber")
	G.block(bolt, Vector3(0.037, 0.015, -0.07), Vector3(0.006, 0.018, 0.06), "silver")
	G.rail(frame, 0.01, -0.26, 0.052)
	optic(frame, -0.07)
	G.label(frame, "VECTOR V9\n9 × 19 / RELAY", Vector3(0.037, -0.033, -0.15), 25)

static func shotgun(frame: Node3D, mag: Node3D, bolt: Node3D) -> void:
	G.block(frame, Vector3(0, 0.004, -0.07), Vector3(0.065, 0.085, 0.23), "steel")
	stock(frame, "polymer")
	grip(frame, 0.015)
	barrel(frame, -0.425, 0.49, 0.016)
	G.tube(frame, Vector3(0, -0.034, -0.37), 0.015, 0.39, "black")
	G.block(bolt, Vector3(0, -0.025, -0.31), Vector3(0.079, 0.069, 0.18), "polymer")
	for i in 10:
		G.block(bolt, Vector3(0, -0.025, -0.23 - i * 0.017), Vector3(0.083, 0.075, 0.007), "rubber")
	G.block(frame, Vector3(0.034, 0.008, -0.065), Vector3(0.004, 0.03, 0.083), "black")
	for i in 4:
		G.tube(mag, Vector3(-0.047, -0.015, -0.005 - i * 0.025), 0.009, 0.058, "red", Vector3.ZERO)
		G.tube(mag, Vector3(-0.047, 0.015, -0.005 - i * 0.025), 0.0095, 0.009, "brass", Vector3.ZERO)
	G.rail(frame, 0.015, -0.17, 0.053)
	G.block(frame, Vector3(0, 0.047, -0.61), Vector3(0.008, 0.04, 0.014), "steel")
	G.tube(frame, Vector3(0, 0.067, -0.61), 0.002, 0.014, "red")
	G.label(frame, "BREACH SG-8 / 12 GA", Vector3(0.035, -0.02, -0.06), 25)

static func sniper(frame: Node3D, mag: Node3D, bolt: Node3D) -> void:
	G.block(frame, Vector3(0, -0.023, -0.1), Vector3(0.068, 0.054, 0.31), "sand")
	G.tube(frame, Vector3(0, 0.021, -0.1), 0.027, 0.3, "steel")
	G.block(frame, Vector3(0, 0.005, -0.385), Vector3(0.068, 0.064, 0.26), "sand")
	barrel(frame, -0.54, 0.43, 0.013)
	stock(frame, "sand", true)
	grip(frame, 0.025)
	magazine(mag, -0.12, 0.12, "steel", 0)
	for i in 8:
		G.block(frame, Vector3(0.035, 0, -0.28 - i * 0.027), Vector3(0.002, 0.027, 0.014), "black")
	G.rail(frame, 0.025, -0.26, 0.052)
	optic(frame, -0.1, true)
	G.tube(bolt, Vector3(0.044, 0.022, 0.01), 0.005, 0.056, "silver", Vector3(0, 0, PI / 2))
	G.tube(bolt, Vector3(0.07, 0.005, 0.01), 0.009, 0.04, "black", Vector3(0, 0, -0.35))
	for side in [-1, 1]:
		G.tube(frame, Vector3(side * 0.044, -0.051, -0.47), 0.009, 0.15, "black")
		G.tube(frame, Vector3(side * 0.044, -0.051, -0.55), 0.013, 0.02, "rubber")
	G.label(frame, "LONGSHOT M77\n7.62 / PRECISION SYSTEMS", Vector3(0.036, -0.026, -0.1), 23)

static func pistol(frame: Node3D, mag: Node3D, bolt: Node3D) -> void:
	G.profile(frame, PackedVector2Array([Vector2(0.065, 0.01), Vector2(-0.18, 0.01), Vector2(-0.18, -0.04),
		Vector2(-0.055, -0.05), Vector2(0.015, -0.075), Vector2(0.064, -0.055)]), 0.033, Vector3.ZERO, "polymer")
	G.block(bolt, Vector3(0, 0.036, -0.058), Vector3(0.035, 0.044, 0.25), "steel")
	G.tube(frame, Vector3(0, 0.036, -0.075), 0.009, 0.23, "silver")
	G.tube(frame, Vector3(0, 0.036, -0.191), 0.006, 0.002, "rubber")
	grip(frame, 0.017)
	G.block(mag, Vector3(0, -0.185, 0.073), Vector3(0.047, 0.016, 0.059), "rubber")
	for side in [-1, 1]:
		for i in 7:
			G.block(bolt, Vector3(side * 0.018, 0.037, 0.043 - i * 0.008), Vector3(0.002, 0.035, 0.003), "black", Vector3(-0.15, 0, 0))
	for x in [-0.012, 0.012]:
		G.block(bolt, Vector3(x, 0.065, 0.05), Vector3(0.009, 0.016, 0.015), "black")
		G.block(bolt, Vector3(x, 0.067, 0.058), Vector3(0.003, 0.003, 0.001), "mark")
	G.block(bolt, Vector3(0, 0.065, -0.163), Vector3(0.006, 0.013, 0.011), "black")
	G.block(bolt, Vector3(0, 0.072, -0.157), Vector3(0.002, 0.002, 0.004), "red")
	G.block(bolt, Vector3(0.018, 0.039, -0.048), Vector3(0.002, 0.021, 0.035), "silver")
	G.label(bolt, "P12  /  9×19", Vector3(0.019, 0.04, -0.11), 23)
