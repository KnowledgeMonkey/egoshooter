class_name UrbanArchitecture
extends RefCounted

const FRAME := Color("343b3d")
const TRIM := Color("92938a")
const GLAZING := Color("71838a")
const WARNING := Color("c7aa64")

static func build(x: float, z: float, _tint: Color, title: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Architecture_" + title.validate_node_name()
	root.position = Vector3(x, 0, z)
	var batch := UrbanMeshBatch.new()
	var shop := "MARKET" in title
	var workshop := "MOTOR" in title
	var residence := "RELAY" in title
	var render_tint := Color("b7b4a7") if workshop else Color("c5c3b9")
	var accent := Color("707a75") if x < 0 else Color("827d70")
	batch.bevel_box(Vector3(0, 0.055, 0), Vector3(9.08, 0.11, 11.08), "floor", Color("b9bbb6"), 0.025)
	# These four wall runs align exactly with the existing collision shell.
	_facade(batch, Vector3(0, 0, 5.5), 0, 9.0, 3.2, render_tint, accent, shop, residence)
	_facade(batch, Vector3(0, 0, -5.5), PI, 9.0, 3.2, render_tint, accent, false, residence)
	_facade(batch, Vector3(4.5, 0, 0), PI * 0.5, 11.0, 4.2, render_tint, accent, false, false)
	_facade(batch, Vector3(-4.5, 0, 0), -PI * 0.5, 11.0, 4.2, render_tint, accent, false, false)
	# The old sealed roof is replaced by UrbanFloors' cut-out floor slabs.
	for side in [-1.0, 1.0]:
		batch.cylinder(Vector3(side * 4.69, 1.77, -5.31), 0.065, 3.4, "metal", TRIM)
		for y in [0.55, 1.95, 3.1]:
			batch.box(Vector3(side * 4.68, y, -5.31), Vector3(0.19, 0.035, 0.18), "metal", FRAME)
	_interior(batch, workshop, shop)
	# Real trim and supports frame the entrances, while the opening stays clear.
	var depot_name := "STORES / 03" if shop else ("MACHINE SHOP / 02" if workshop else ("PUMP HOUSE / 01" if residence else "PROCESSING / 04"))
	if "SECTOR" in title:
		depot_name = "LOADING / %02d" % (5 + int(x > 0) + 2 * int(z > 0))
	batch.bevel_box(Vector3(0, 3.0, 5.76), Vector3(5.5, 0.43, 0.085), "paint", FRAME, 0.018)
	_add_sign(root, depot_name, Vector3(0, 3.04, 5.809), 0, Color("d5d0b8"), 36, 0.007)
	_add_sign(root, "QUARRY OPERATIONS  /  AUTHORISED PERSONNEL", Vector3(0, 2.89, 5.811), 0, TRIM, 16, 0.004)
	# Powder-coated canopy with a thin metal edge rather than a solid slab.
	batch.box(Vector3(0, 3.36, 5.97), Vector3(6.32, 0.09, 1.06), "metal", FRAME)
	batch.box(Vector3(0, 3.3, 6.43), Vector3(6.32, 0.16, 0.055), "metal", TRIM)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 2.85, 3.18, 5.94), Vector3(0.055, 0.32, 0.7), "metal", FRAME, Vector3(0.18, 0, 0))
		batch.box(Vector3(side * 3.78, 2.62, 5.73), Vector3(0.13, 0.26, 0.11), "metal", FRAME)
		batch.box(Vector3(side * 3.78, 2.59, 5.8), Vector3(0.1, 0.13, 0.045), "paint", Color("dbe8df"))
	# Service conduits sit on solid piers, clear of all four entries.
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 4.16, 1.83, 5.715), Vector3(0.037, 2.9, 0.035), "metal", TRIM)
		batch.bevel_box(Vector3(side * 4.16, 1.18, 5.79), Vector3(0.27, 0.42, 0.14), "metal", FRAME, 0.015)
		batch.box(Vector3(side * 4.16, 1.25, 5.866), Vector3(0.09, 0.1, 0.008), "paint", WARNING)
		_add_sign(root, "HIGH\nVOLTAGE", Vector3(side * 4.16, 1.14, 5.868), 0, TRIM, 15, 0.0025)
	# Service hatch and exterior cooling compressor are above walking clearance.
	batch.bevel_box(Vector3(3.31, 2.42, -5.88), Vector3(1.1, 0.59, 0.46), "metal", Color("b0b3a7"), 0.035)
	batch.cylinder(Vector3(3.12, 2.42, -6.118), 0.215, 0.025, "metal", FRAME, Vector3(PI * 0.5, 0, 0))
	for index in 7:
		batch.box(Vector3(3.63, 2.21 + index * 0.065, -6.12), Vector3(0.34, 0.018, 0.035), "metal", FRAME)
	batch.finish(root, "Facade")
	var interior_light := OmniLight3D.new()
	interior_light.name = "IndustrialInteriorBounce"
	interior_light.position = Vector3(0, 2.8, 0)
	interior_light.light_color = Color("c9dfe1")
	interior_light.light_energy = 0.32
	interior_light.omni_range = 6.0
	interior_light.omni_attenuation = 1.6
	interior_light.shadow_enabled = false
	root.add_child(interior_light)
	return root

static func _face_box(batch: UrbanMeshBatch, origin: Vector3, yaw: float, position: Vector3, size: Vector3, kind: String, tint: Color) -> void:
	var rotation := Vector3(0, yaw, 0)
	batch.box(origin + Basis.from_euler(rotation) * position, size, kind, tint, rotation)

static func _facade(batch: UrbanMeshBatch, origin: Vector3, yaw: float, width: float, opening: float, tint: Color, accent: Color, shop: bool, masonry: bool) -> void:
	var panel_width := (width - opening) * 0.5
	var panel_center := opening * 0.5 + panel_width * 0.5
	for side in [-1.0, 1.0]:
		var u: float = side * panel_center
		_face_box(batch, origin, yaw, Vector3(u, 1.7, 0), Vector3(panel_width, 3.4, 0.35), "brick" if masonry else "plaster", Color("c5c0b4") if masonry else tint)
		_face_box(batch, origin, yaw, Vector3(u, 0.3, 0.19), Vector3(panel_width, 0.5, 0.065), "concrete", TRIM)
		var window_width := panel_width - 0.78
		var window_height := 1.2 if shop else 1.34
		var window_y := 1.8
		_face_box(batch, origin, yaw, Vector3(u, window_y, 0.209), Vector3(window_width + 0.17, window_height + 0.16, 0.12), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(u, window_y, 0.28), Vector3(window_width, window_height, 0.035), "glass", GLAZING)
		for edge in [-1.0, 1.0]:
			_face_box(batch, origin, yaw, Vector3(u + edge * (window_width * 0.5 + 0.038), window_y, 0.303), Vector3(0.074, window_height + 0.12, 0.074), "metal", FRAME)
			_face_box(batch, origin, yaw, Vector3(u, window_y + edge * (window_height * 0.5 + 0.035), 0.303), Vector3(window_width + 0.2, 0.072, 0.074), "metal", FRAME)
		for division in [-1.0, 1.0]:
			_face_box(batch, origin, yaw, Vector3(u + division * window_width / 6.0, window_y, 0.318), Vector3(0.028, window_height, 0.045), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(u, window_y, 0.318), Vector3(window_width, 0.032, 0.047), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(u, window_y - window_height * 0.5 - 0.1, 0.33), Vector3(window_width + 0.31, 0.12, 0.39), "concrete", TRIM)
		# Narrow lintels, vents and accent panels break the featureless wall mass.
		_face_box(batch, origin, yaw, Vector3(u, 2.96, 0.201), Vector3(panel_width - 0.27, 0.52, 0.06), "corrugated", accent)
		_face_box(batch, origin, yaw, Vector3(u, 2.68, 0.235), Vector3(panel_width - 0.18, 0.075, 0.09), "metal", FRAME)
		# Steel reveals and corner columns attach to the existing solid walls.
		_face_box(batch, origin, yaw, Vector3(side * (opening * 0.5 + 0.035), 1.38, 0.03), Vector3(0.11, 2.76, 0.46), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(side * (width * 0.5 - 0.075), 1.7, 0.21), Vector3(0.15, 3.4, 0.115), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(side * (opening * 0.5 + 0.12), 0.62, 0.25), Vector3(0.095, 1.1, 0.02), "paint", WARNING)
	_face_box(batch, origin, yaw, Vector3(0, 3.05, 0), Vector3(opening + 0.06, 0.7, 0.35), "plaster", tint)
	_face_box(batch, origin, yaw, Vector3(0, 2.726, 0.03), Vector3(opening + 0.14, 0.1, 0.46), "metal", FRAME)
	_face_box(batch, origin, yaw, Vector3(0, 3.31, 0.215), Vector3(width + 0.08, 0.09, 0.13), "metal", FRAME)
	# Raised roller-door cassette occupies only the pre-existing lintel volume.
	_face_box(batch, origin, yaw, Vector3(0, 3.035, 0.225), Vector3(opening - 0.06, 0.46, 0.095), "corrugated", accent)
	# Flush transition: neither an invisible step nor a decorative door collider.
	_face_box(batch, origin, yaw, Vector3(0, 0.075, 0), Vector3(opening - 0.08, 0.04, 0.48), "metal", Color("838d87"))

static func _interior(batch: UrbanMeshBatch, workshop: bool, shop: bool) -> void:
	# Dress the exact pre-existing central cover bounds as a cabinet/work island.
	batch.bevel_box(Vector3(-2, 0.64, 0), Vector3(1.7, 1.26, 2.4), "paint", Color("596562"), 0.035)
	batch.box(Vector3(-2, 1.293, 0), Vector3(1.72, 0.065, 2.42), "wood" if not workshop else "metal", Color("c0b9a5") if not workshop else TRIM)
	batch.box(Vector3(-2, 0.14, 0), Vector3(1.6, 0.2, 2.32), "metal", FRAME)
	for drawer in 3:
		batch.box(Vector3(-1.139, 0.39 + drawer * 0.29, 0), Vector3(0.03, 0.265, 2.19), "paint", Color("778078"))
		for z in [-0.55, 0.55]:
			batch.box(Vector3(-1.11, 0.44 + drawer * 0.29, z), Vector3(0.06, 0.034, 0.28), "metal", FRAME)
	if workshop:
		batch.bevel_box(Vector3(-2.1, 1.44, 0.59), Vector3(0.68, 0.23, 0.47), "paint", Color("9a5541"), 0.03)
		batch.box(Vector3(-2.1, 1.57, 0.59), Vector3(0.31, 0.035, 0.035), "metal", FRAME)
	elif shop:
		batch.bevel_box(Vector3(-2, 1.47, 0.55), Vector3(0.63, 0.3, 0.62), "wood", Color("c0b9a5"), 0.014)
		for z in [0.32, 0.78]:
			batch.box(Vector3(-2, 1.624, z), Vector3(0.64, 0.018, 0.04), "metal", FRAME)
	# Ceiling fixture has no gameplay collision and keeps the interior readable.
	batch.box(Vector3(-0.35, 3.365, 0), Vector3(0.34, 0.09, 2.35), "metal", FRAME)
	for x in [-0.42, -0.28]:
		batch.cylinder(Vector3(x, 3.292, 0), 0.022, 2.12, "paint", Color("e2ede5"), Vector3(PI * 0.5, 0, 0))
	# Exposed joists remain wholly outside the ground-floor stairwell at x=2.
	for x in [-3.83, -0.54]:
		batch.box(Vector3(x, 3.46, 0), Vector3(0.12, 0.1, 10.8), "metal", FRAME)
		batch.box(Vector3(x, 3.405, 0), Vector3(0.25, 0.03, 10.8), "metal", FRAME)

static func _add_sign(parent: Node3D, words: String, position: Vector3, yaw: float, color: Color, size: int, pixel: float) -> void:
	var label := Label3D.new()
	label.text = words
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	label.position = position
	label.rotation.y = yaw
	parent.add_child(label)
