class_name UrbanArchitecture
extends RefCounted

const FRAME := Color("354043")
const TRIM := Color("c8c5b9")
const GLAZING := Color("55727b")

static func build(x: float, z: float, tint: Color, title: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Architecture_" + title.validate_node_name()
	root.position = Vector3(x, 0, z)
	var batch := UrbanMeshBatch.new()
	var shop := "MARKET" in title
	var workshop := "MOTOR" in title
	var residence := "RELAY" in title
	var render_tint := tint.lerp(Color("dad8cb"), 0.36)
	batch.bevel_box(Vector3(0, 0.055, 0), Vector3(9.08, 0.11, 11.08), "floor", Color("c7c4bc"), 0.025)
	# These four wall runs align exactly with the existing collision shell.
	_facade(batch, Vector3(0, 0, 5.5), 0, 9.0, 3.2, render_tint, tint, shop, residence)
	_facade(batch, Vector3(0, 0, -5.5), PI, 9.0, 3.2, render_tint, tint, false, residence)
	_facade(batch, Vector3(4.5, 0, 0), PI * 0.5, 11.0, 4.2, render_tint, tint, false, false)
	_facade(batch, Vector3(-4.5, 0, 0), -PI * 0.5, 11.0, 4.2, render_tint, tint, false, false)
	# The old sealed roof is replaced by UrbanFloors' cut-out floor slabs.
	for side in [-1.0, 1.0]:
		batch.cylinder(Vector3(side * 4.61, 1.77, -5.29), 0.065, 3.4, "metal", Color("677574"))
	_interior(batch, workshop, shop)
	# Real trim and supports frame the entrances, while the opening stays clear.
	var sign_background := tint.darkened(0.54)
	batch.bevel_box(Vector3(0, 2.99, 5.77), Vector3(5.85, 0.53, 0.15), "paint", sign_background, 0.035)
	_add_sign(root, title, Vector3(0, 3.01, 5.857), 0, Color("f0ece0"), 43, 0.008)
	var subline := "NEIGHBOURHOOD GOODS" if shop else ("SERVICE  /  REPAIR" if workshop else ("RESIDENCES" if residence else "DESIGN STUDIO"))
	_add_sign(root, subline, Vector3(0, 2.78, 5.863), 0, Color("c9cbbd"), 18, 0.005)
	# Powder-coated canopy with a thin metal edge rather than a solid slab.
	batch.box(Vector3(0, 3.36, 5.97), Vector3(6.32, 0.09, 1.06), "metal", FRAME)
	batch.box(Vector3(0, 3.3, 6.43), Vector3(6.32, 0.16, 0.055), "paint", tint)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 2.85, 3.18, 5.94), Vector3(0.055, 0.32, 0.7), "metal", FRAME, Vector3(0.18, 0, 0))
		batch.box(Vector3(side * 3.78, 2.62, 5.73), Vector3(0.13, 0.26, 0.11), "metal", FRAME)
		batch.box(Vector3(side * 3.78, 2.59, 5.8), Vector3(0.1, 0.13, 0.045), "paint", Color("ead5a5"))
	# Service hatch and exterior cooling compressor are above walking clearance.
	batch.bevel_box(Vector3(3.31, 2.42, -5.88), Vector3(1.1, 0.59, 0.46), "metal", Color("b0b3a7"), 0.035)
	batch.cylinder(Vector3(3.12, 2.42, -6.118), 0.215, 0.025, "metal", FRAME, Vector3(PI * 0.5, 0, 0))
	for index in 7:
		batch.box(Vector3(3.63, 2.21 + index * 0.065, -6.12), Vector3(0.34, 0.018, 0.035), "metal", FRAME)
	batch.finish(root, "Facade")
	var interior_light := OmniLight3D.new()
	interior_light.name = "WarmInteriorBounce"
	interior_light.position = Vector3(0, 2.8, 0)
	interior_light.light_color = Color("ffe5bd")
	interior_light.light_energy = 0.38
	interior_light.omni_range = 6.0
	interior_light.omni_attenuation = 1.6
	interior_light.shadow_enabled = false
	root.add_child(interior_light)
	return root

static func _face_box(batch: UrbanMeshBatch, origin: Vector3, yaw: float, position: Vector3, size: Vector3, kind: String, tint: Color) -> void:
	var rotation := Vector3(0, yaw, 0)
	batch.box(origin + Basis.from_euler(rotation) * position, size, kind, tint, rotation)

static func _facade(batch: UrbanMeshBatch, origin: Vector3, yaw: float, width: float, opening: float, tint: Color, accent: Color, shop: bool, timber: bool) -> void:
	var panel_width := (width - opening) * 0.5
	var panel_center := opening * 0.5 + panel_width * 0.5
	for side in [-1.0, 1.0]:
		var u: float = side * panel_center
		_face_box(batch, origin, yaw, Vector3(u, 1.7, 0), Vector3(panel_width, 3.4, 0.35), "plaster", tint)
		_face_box(batch, origin, yaw, Vector3(u, 0.39, 0.188), Vector3(panel_width, 0.68, 0.035), "concrete", Color("7d8580"))
		_face_box(batch, origin, yaw, Vector3(u, 0.76, 0.218), Vector3(panel_width, 0.07, 0.1), "concrete", TRIM)
		# Fine horizontal masonry joints make the plinth read as a built surface.
		for row in 3:
			_face_box(batch, origin, yaw, Vector3(u, 0.2 + row * 0.2, 0.211), Vector3(panel_width - 0.03, 0.013, 0.012), "concrete", Color("5e6866"))
		var window_width := panel_width - 0.78
		var window_height := 1.42 if shop else 1.34
		var window_y := 1.66 if shop else 1.78
		_face_box(batch, origin, yaw, Vector3(u, window_y, 0.209), Vector3(window_width + 0.17, window_height + 0.16, 0.12), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(u, window_y, 0.28), Vector3(window_width, window_height, 0.035), "glass", GLAZING)
		for edge in [-1.0, 1.0]:
			_face_box(batch, origin, yaw, Vector3(u + edge * (window_width * 0.5 + 0.038), window_y, 0.303), Vector3(0.074, window_height + 0.12, 0.074), "metal", TRIM)
			_face_box(batch, origin, yaw, Vector3(u, window_y + edge * (window_height * 0.5 + 0.035), 0.303), Vector3(window_width + 0.2, 0.072, 0.074), "metal", TRIM)
		_face_box(batch, origin, yaw, Vector3(u + window_width * 0.13, window_y, 0.318), Vector3(0.055, window_height, 0.052), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(u, window_y + 0.33, 0.318), Vector3(window_width, 0.04, 0.047), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(u, window_y - window_height * 0.5 - 0.1, 0.33), Vector3(window_width + 0.31, 0.12, 0.39), "concrete", TRIM)
		# Narrow lintels, vents and accent panels break the featureless wall mass.
		_face_box(batch, origin, yaw, Vector3(u, 2.65, 0.195), Vector3(panel_width - 0.24, 0.12, 0.07), "paint", accent.darkened(0.14))
		if timber:
			for slat in 4:
				_face_box(batch, origin, yaw, Vector3(u + side * (window_width * 0.5 + 0.22), 1.15 + slat * 0.33, 0.235), Vector3(0.18, 0.27, 0.13), "wood", Color("927452"))
		# Inner reveal is cream plaster; no pane or leaf blocks the route.
		_face_box(batch, origin, yaw, Vector3(side * (opening * 0.5 + 0.035), 1.38, 0.03), Vector3(0.11, 2.76, 0.46), "metal", FRAME)
		_face_box(batch, origin, yaw, Vector3(side * (width * 0.5 - 0.075), 1.7, 0.195), Vector3(0.15, 3.4, 0.085), "plaster", TRIM)
	_face_box(batch, origin, yaw, Vector3(0, 3.05, 0), Vector3(opening + 0.06, 0.7, 0.35), "plaster", tint)
	_face_box(batch, origin, yaw, Vector3(0, 2.726, 0.03), Vector3(opening + 0.14, 0.1, 0.46), "metal", FRAME)
	_face_box(batch, origin, yaw, Vector3(0, 3.31, 0.215), Vector3(width + 0.08, 0.09, 0.13), "concrete", TRIM)
	# Flush transition: neither an invisible step nor a decorative door collider.
	_face_box(batch, origin, yaw, Vector3(0, 0.075, 0), Vector3(opening - 0.08, 0.04, 0.48), "metal", Color("838d87"))

static func _interior(batch: UrbanMeshBatch, workshop: bool, shop: bool) -> void:
	# Dress the exact pre-existing central cover bounds as a cabinet/work island.
	batch.bevel_box(Vector3(-2, 0.64, 0), Vector3(1.7, 1.26, 2.4), "paint", Color("5b6966") if workshop else Color("797f71"), 0.035)
	batch.box(Vector3(-2, 1.293, 0), Vector3(1.72, 0.065, 2.42), "wood" if not workshop else "metal", Color("9d8762") if not workshop else Color("727e7c"))
	batch.box(Vector3(-2, 0.14, 0), Vector3(1.6, 0.2, 2.32), "metal", FRAME)
	for drawer in 3:
		batch.box(Vector3(-1.139, 0.39 + drawer * 0.29, 0), Vector3(0.03, 0.265, 2.19), "paint", Color("88948a"))
		for z in [-0.55, 0.55]:
			batch.box(Vector3(-1.11, 0.44 + drawer * 0.29, z), Vector3(0.06, 0.034, 0.28), "metal", FRAME)
	if workshop:
		batch.bevel_box(Vector3(-2.1, 1.44, 0.59), Vector3(0.68, 0.23, 0.47), "paint", Color("9a5541"), 0.03)
		batch.box(Vector3(-2.1, 1.57, 0.59), Vector3(0.31, 0.035, 0.035), "metal", FRAME)
	elif shop:
		batch.bevel_box(Vector3(-2, 1.45, 0.66), Vector3(0.55, 0.26, 0.43), "paint", Color("30433e"), 0.035)
		batch.box(Vector3(-1.94, 1.61, 0.66), Vector3(0.04, 0.22, 0.32), "glass", Color("53837b"), Vector3(0, 0, -0.2))
	# Ceiling fixture has no gameplay collision and keeps the interior readable.
	batch.box(Vector3(0, 3.365, 0), Vector3(0.34, 0.09, 2.35), "metal", FRAME)
	batch.box(Vector3(0, 3.307, 0), Vector3(0.25, 0.024, 2.18), "paint", Color("efe8cd"))

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
