class_name UrbanVehicles
extends RefCounted

const DARK := Color("252a2a")
const RUBBER := Color("191d1d")
const ALLOY := Color("a2aaa8")
const WINDOW := Color("9aafb3")

static func build(tint: Color, long_vehicle: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "CourierVan" if long_vehicle else "UrbanSaloon"
	var batch := UrbanMeshBatch.new()
	if long_vehicle:
		_van(batch, tint)
	else:
		_sedan(batch, tint)
	batch.finish(root, "Bodywork")
	return root

static func _sedan(batch: UrbanMeshBatch, tint: Color) -> void:
	# Chamfered sill, bonnet and boot create a readable automotive silhouette.
	batch.profile(PackedVector2Array([Vector2(-2.28, 0.38), Vector2(2.22, 0.38),
		Vector2(2.3, 0.56), Vector2(2.24, 0.98), Vector2(1.77, 1.15),
		Vector2(-1.53, 1.17), Vector2(-2.2, 1.0), Vector2(-2.3, 0.67)]), 2.29, Vector3.ZERO, "paint", tint, 0.09)
	batch.profile(PackedVector2Array([Vector2(-1.62, 1.02), Vector2(1.22, 1.02),
		Vector2(1.16, 1.36), Vector2(0.65, 1.91), Vector2(-0.76, 1.91),
		Vector2(-1.62, 1.14)]), 2.04, Vector3.ZERO, "paint", tint, 0.095)
	# The bonnet has a shallow crown, with physical shut lines and a grille.
	batch.bevel_box(Vector3(0, 1.08, -1.91), Vector3(1.95, 0.073, 0.59), "paint", tint.lightened(0.035), 0.026)
	batch.bevel_box(Vector3(0, 0.56, -2.255), Vector3(1.98, 0.24, 0.11), "rubber", DARK, 0.032)
	batch.bevel_box(Vector3(0, 0.75, -2.292), Vector3(0.93, 0.22, 0.055), "metal", DARK, 0.02)
	for slat in 5:
		batch.box(Vector3(0, 0.67 + slat * 0.035, -2.326), Vector3(0.85, 0.012, 0.021), "metal", ALLOY.darkened(0.26))
	batch.box(Vector3(0, 0.94, -2.27), Vector3(0.14, 0.1, 0.035), "metal", ALLOY)
	batch.bevel_box(Vector3(0, 0.48, 2.26), Vector3(2.05, 0.17, 0.1), "rubber", DARK, 0.024)
	# Windshield and backlight follow the body slope instead of a vertical box.
	batch.quad(Vector3(-0.89, 1.23, -1.51), Vector3(0.89, 1.23, -1.51),
		Vector3(0.835, 1.822, -0.823), Vector3(-0.835, 1.822, -0.823), "glass", WINDOW, true)
	batch.quad(Vector3(0.86, 1.401, 1.12), Vector3(-0.86, 1.401, 1.12),
		Vector3(-0.82, 1.819, 0.722), Vector3(0.82, 1.819, 0.722), "glass", WINDOW, true)
	for side in [-1.0, 1.0]:
		var x: float = side * 1.025
		batch.quad(Vector3(x, 1.2, -1.38), Vector3(x, 1.2, -0.19),
			Vector3(x, 1.779, -0.19), Vector3(x, 1.779, -0.7), "glass", WINDOW, true)
		batch.quad(Vector3(x, 1.2, -0.085), Vector3(x, 1.2, 1.045),
			Vector3(x, 1.779, 0.57), Vector3(x, 1.779, -0.085), "glass", WINDOW, true)
		batch.box(Vector3(side * 1.087, 1.154, -0.18), Vector3(0.028, 0.04, 2.55), "metal", ALLOY.darkened(0.17))
		# Door seams, flush handles, side skirts and indicators.
		for z in [-1.37, -0.12, 1.18]:
			batch.box(Vector3(side * 1.151, 0.84, z), Vector3(0.015, 0.46, 0.014), "rubber", DARK)
		for z in [-0.39, 0.87]:
			batch.bevel_box(Vector3(side * 1.158, 1.022, z), Vector3(0.027, 0.058, 0.22), "metal", ALLOY, 0.008)
		batch.bevel_box(Vector3(side * 1.142, 0.44, 0), Vector3(0.1, 0.11, 3.82), "rubber", DARK, 0.028)
		batch.box(Vector3(side * 1.065, 1.262, -1.14), Vector3(0.2, 0.055, 0.07), "rubber", DARK, Vector3(0, side * 0.3, 0))
		batch.bevel_box(Vector3(side * 1.205, 1.304, -1.12), Vector3(0.25, 0.145, 0.29), "paint", tint, 0.04)
		batch.box(Vector3(side * 1.22, 1.305, -0.969), Vector3(0.185, 0.096, 0.021), "glass", Color.WHITE)
		batch.bevel_box(Vector3(side * 0.8, 0.9, -2.252), Vector3(0.49, 0.175, 0.073), "glass", Color("d9e3d5"), 0.025)
		batch.box(Vector3(side * 0.81, 0.966, -2.299), Vector3(0.4, 0.033, 0.019), "paint", Color("f2e9ca"))
		batch.bevel_box(Vector3(side * 0.82, 0.895, 2.263), Vector3(0.49, 0.175, 0.068), "paint", Color("993b31"), 0.022)
		batch.box(Vector3(side * 0.82, 0.915, 2.304), Vector3(0.37, 0.035, 0.013), "paint", Color("d96348"))
		batch.cylinder(Vector3(side * 0.75, 0.35, 2.245), 0.072, 0.25, "metal", ALLOY, Vector3(PI * 0.5, 0, 0))
		for axle in [-1.48, 1.44]:
			_wheel(batch, side, axle, 0.4)
	_number_plate(batch, Vector3(0, 0.593, -2.331))
	_number_plate(batch, Vector3(0, 0.8, 2.317))
	# Two subtle windscreen wipers, with no animated nodes per parked car.
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 0.43, 1.259, -1.465), Vector3(0.54, 0.024, 0.028), "rubber", DARK, Vector3(0, side * 0.14, 0))
	batch.cylinder(Vector3(0, 1.98, 0.49), 0.035, 0.15, "rubber", DARK, Vector3(0.25, 0, 0), 0.012)

static func _van(batch: UrbanMeshBatch, tint: Color) -> void:
	# A compact courier van keeps the original cover height and long footprint.
	batch.profile(PackedVector2Array([Vector2(-3.2, 0.38), Vector2(3.17, 0.38),
		Vector2(3.25, 0.57), Vector2(3.2, 1.16), Vector2(-2.36, 1.2),
		Vector2(-3.19, 1.01), Vector2(-3.25, 0.61)]), 2.29, Vector3.ZERO, "paint", tint, 0.09)
	batch.profile(PackedVector2Array([Vector2(-2.13, 1.0), Vector2(1.53, 1.0),
		Vector2(1.5, 1.81), Vector2(1.39, 1.9), Vector2(-1.47, 1.9),
		Vector2(-2.13, 1.32)]), 2.04, Vector3.ZERO, "paint", tint.lightened(0.035), 0.075)
	# An exposed loading bed behind the cab explains the long, low silhouette.
	batch.bevel_box(Vector3(0, 1.17, 2.28), Vector3(2.13, 0.085, 1.8), "rubber", Color("424a45"), 0.03)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 1.06, 1.25, 2.37), Vector3(0.1, 0.19, 1.64), "paint", tint)
		batch.box(Vector3(side * 1.12, 0.67, 0.3), Vector3(0.09, 0.095, 4.76), "rubber", DARK)
		batch.box(Vector3(side * 1.026, 1.456, 0.69), Vector3(0.015, 0.6, 0.018), "rubber", DARK)
		batch.box(Vector3(side * 1.047, 1.265, 0.37), Vector3(0.04, 0.055, 0.24), "rubber", DARK)
		batch.box(Vector3(side * 1.026, 1.739, 0.3), Vector3(0.035, 0.043, 2.03), "metal", ALLOY.darkened(0.24))
		batch.quad(Vector3(side * 1.025, 1.284, -1.98), Vector3(side * 1.025, 1.284, -0.71),
			Vector3(side * 1.025, 1.774, -0.71), Vector3(side * 1.025, 1.774, -1.455), "glass", WINDOW, true)
		batch.box(Vector3(side * 1.07, 1.277, -0.56), Vector3(0.025, 0.049, 0.19), "rubber", DARK)
		batch.box(Vector3(side * 1.14, 1.43, -1.82), Vector3(0.26, 0.052, 0.055), "metal", DARK)
		batch.bevel_box(Vector3(side * 1.27, 1.47, -1.8), Vector3(0.19, 0.24, 0.25), "rubber", DARK, 0.045)
		batch.box(Vector3(side * 1.28, 1.48, -1.665), Vector3(0.137, 0.174, 0.02), "glass", Color.WHITE)
		batch.bevel_box(Vector3(side * 0.83, 0.89, -3.207), Vector3(0.4, 0.23, 0.09), "glass", Color("d3d9cb"), 0.024)
		batch.box(Vector3(side * 0.85, 0.912, -3.26), Vector3(0.29, 0.033, 0.019), "paint", Color("efe3bb"))
		batch.bevel_box(Vector3(side * 0.96, 0.91, 3.203), Vector3(0.19, 0.27, 0.055), "paint", Color("a33c31"), 0.02)
		for axle in [-2.16, 2.08]:
			_wheel(batch, side, axle, 0.43)
	batch.quad(Vector3(-0.9, 1.391, -2.066), Vector3(0.9, 1.391, -2.066),
		Vector3(0.86, 1.809, -1.544), Vector3(-0.86, 1.809, -1.544), "glass", WINDOW, true)
	batch.bevel_box(Vector3(0, 0.56, -3.243), Vector3(2.15, 0.22, 0.11), "rubber", DARK, 0.035)
	batch.bevel_box(Vector3(0, 0.81, -3.234), Vector3(1.11, 0.25, 0.084), "rubber", DARK, 0.028)
	for slat in 5:
		batch.box(Vector3(0, 0.715 + slat * 0.04, -3.282), Vector3(0.99, 0.018, 0.019), "metal", ALLOY.darkened(0.22))
	batch.box(Vector3(0, 0.88, 3.256), Vector3(1.77, 0.045, 0.025), "metal", ALLOY)
	batch.box(Vector3(0, 0.47, 3.266), Vector3(1.96, 0.14, 0.1), "rubber", DARK)
	_number_plate(batch, Vector3(0, 0.535, -3.308))
	_number_plate(batch, Vector3(0, 0.72, 3.29))
	# Thin roof rails and a ribbed loading surface give the work vehicle purpose.
	for side in [-1.0, 1.0]:
		batch.cylinder(Vector3(side * 0.77, 1.952, -0.08), 0.03, 2.47, "metal", DARK, Vector3(PI * 0.5, 0, 0))
		for z in [-1.12, 0.96]:
			batch.box(Vector3(side * 0.77, 1.923, z), Vector3(0.085, 0.11, 0.14), "rubber", DARK)
	for rib in range(-4, 5):
		batch.box(Vector3(rib * 0.2, 1.225, 2.35), Vector3(0.022, 0.022, 1.57), "metal", Color("626d65"))
	batch.box(Vector3(0, 1.251, 3.15), Vector3(2.12, 0.19, 0.11), "paint", tint)

static func _wheel(batch: UrbanMeshBatch, side: float, z: float, radius: float) -> void:
	var x := side * 1.132
	# Dark wheel-well backing, rounded tyre shoulders, brake disc and five spokes.
	batch.cylinder(Vector3(side * 1.156, radius + 0.02, z), radius * 1.13, 0.025, "rubber", Color("101615"), Vector3(0, 0, PI * 0.5))
	batch.cylinder(Vector3(x, radius, z), radius, 0.235, "rubber", RUBBER, Vector3(0, 0, PI * 0.5))
	batch.cylinder(Vector3(side * 1.26, radius, z), radius * 0.94, 0.043, "rubber", Color("242a27"), Vector3(0, 0, PI * 0.5), radius * 0.89)
	batch.cylinder(Vector3(side * 1.286, radius, z), radius * 0.7, 0.038, "metal", ALLOY, Vector3(0, 0, PI * 0.5))
	batch.cylinder(Vector3(side * 1.309, radius, z), radius * 0.58, 0.02, "metal", Color("36423f"), Vector3(0, 0, PI * 0.5))
	batch.cylinder(Vector3(side * 1.328, radius, z), radius * 0.23, 0.042, "metal", ALLOY, Vector3(0, 0, PI * 0.5))
	for spoke in 5:
		var angle := TAU * spoke / 5.0
		batch.box(Vector3(side * 1.33, radius + cos(angle) * radius * 0.37, z + sin(angle) * radius * 0.37), Vector3(0.035, radius * 0.7, 0.055), "metal", ALLOY, Vector3(angle, 0, 0))
		batch.cylinder(Vector3(side * 1.356, radius + cos(angle) * 0.054, z + sin(angle) * 0.054), 0.018, 0.015, "metal", DARK, Vector3(0, 0, PI * 0.5))
	# Tread blocks give tyres side detail without dozens of separate scene nodes.
	for tread in 20:
		var angle := TAU * tread / 20.0
		batch.box(Vector3(x, radius + cos(angle) * radius * 0.975, z + sin(angle) * radius * 0.975), Vector3(0.2, 0.025, 0.041), "rubber", Color("292e2a"), Vector3(angle, 0, 0))

static func _number_plate(batch: UrbanMeshBatch, position: Vector3) -> void:
	batch.bevel_box(position, Vector3(0.53, 0.123, 0.028), "paint", Color("d4d4ba"), 0.011)
	batch.box(position + Vector3(-0.229, 0, -0.017 if position.z < 0 else 0.017), Vector3(0.052, 0.105, 0.009), "paint", Color("446677"))
	for digit in 6:
		batch.box(position + Vector3(-0.15 + digit * 0.057, 0, -0.019 if position.z < 0 else 0.019), Vector3(0.019, 0.06, 0.009), "paint", Color("43534e"))
