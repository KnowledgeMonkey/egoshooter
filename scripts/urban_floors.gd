class_name UrbanFloors
extends RefCounted

# One definition supplies both visible geometry and authoritative collision.
# Each house has ground -> upper -> roof internal stairs and an exterior escape stair.
const LEVEL := 3.7
const ROOF := 7.4
const FRAME := Color("343b3d")
const TRIM := Color("92938a")
const WARNING := Color("c7aa64")
var arena: Node3D
var origin: Vector3
var accent: Color
var outward: float
var batch: UrbanMeshBatch

static func build(target: Node3D, x: float, z: float, _tint: Color) -> void:
	var floors := UrbanFloors.new()
	floors.arena = target
	floors.origin = Vector3(x, 0, z)
	# Restrained factory sheet metal replaces the former pastel residential walls.
	floors.accent = Color("929b94") if x < 0 else Color("a39f91")
	floors.outward = signf(x)
	if DisplayServer.get_name() != "headless":
		floors.batch = UrbanMeshBatch.new()
	floors._build()

func part(at: Vector3, size: Vector3, kind: String, tint: Color, solid: bool = true) -> void:
	if solid:
		arena.box(origin + at, size, tint).visible = false
	if batch:
		batch.bevel_box(origin + at, size, kind, tint, minf(0.025, size.y * 0.15))

func _slab(height: float, left: float, right: float, near: float, far: float) -> void:
	# Rectangle around a real stairwell opening; no invisible ceiling over stairs.
	part(Vector3((-4.9 + left) / 2, height - 0.15, 0), Vector3(left + 4.9, 0.3, 11.8), "floor", TRIM)
	part(Vector3((right + 4.9) / 2, height - 0.15, 0), Vector3(4.9 - right, 0.3, 11.8), "floor", TRIM)
	part(Vector3((left + right) / 2, height - 0.15, (-5.9 + near) / 2), Vector3(right - left, 0.3, near + 5.9), "floor", TRIM)
	part(Vector3((left + right) / 2, height - 0.15, (far + 5.9) / 2), Vector3(right - left, 0.3, 5.9 - far), "floor", TRIM)

func _wall_box(axis: int, fixed: float, along: float, y: float, length: float, height: float, kind: String, tint: Color, solid: bool = true) -> void:
	var pos := Vector3(along, y, fixed) if axis == 0 else Vector3(fixed, y, along)
	var size := Vector3(length, height, 0.35) if axis == 0 else Vector3(0.35, height, length)
	part(pos, size, kind, tint, solid)

func _wall(axis: int, fixed: float, width: float, openings: Array[Vector4]) -> void:
	var cursor := -width / 2
	for gap in openings:
		if gap.x > cursor:
			_wall_box(axis, fixed, (cursor + gap.x) / 2, LEVEL + 1.7, gap.x - cursor, 3.4, "corrugated", accent)
			_column(axis, fixed, (cursor + gap.x) / 2)
		if gap.z > 0:
			_wall_box(axis, fixed, (gap.x + gap.y) / 2, LEVEL + gap.z / 2, gap.y - gap.x, gap.z, "corrugated", accent)
		_wall_box(axis, fixed, (gap.x + gap.y) / 2, LEVEL + (gap.w + 3.4) / 2, gap.y - gap.x, 3.4 - gap.w, "corrugated", accent)
		# Real empty opening: frames only, no glass panel or hidden collision face.
		for edge in [gap.x, gap.y]:
			_wall_box(axis, fixed, edge, LEVEL + (gap.z + gap.w) / 2, 0.07, gap.w - gap.z, "metal", FRAME, false)
		for y in [gap.z, gap.w]:
			_wall_box(axis, fixed, (gap.x + gap.y) / 2, LEVEL + y, gap.y - gap.x + 0.1, 0.07, "metal", TRIM, false)
		cursor = gap.y
	if cursor < width / 2:
		_wall_box(axis, fixed, (cursor + width / 2) / 2, LEVEL + 1.7, width / 2 - cursor, 3.4, "corrugated", accent)
		_column(axis, fixed, (cursor + width / 2) / 2)
	_wall_box(axis, fixed + signf(fixed) * 0.055, 0, LEVEL + 3.32, width + 0.12, 0.14, "metal", FRAME, false)
	_wall_box(axis, fixed + signf(fixed) * 0.055, 0, LEVEL - 0.17, width + 0.12, 0.18, "metal", FRAME, false)

func _column(axis: int, fixed: float, along: float) -> void:
	# Sheet-metal support posts remain on solid wall spans, never in a window gap.
	_wall_box(axis, fixed + signf(fixed) * 0.05, along, LEVEL + 1.68, 0.12, 3.36, "metal", FRAME, false)
	_wall_box(axis, fixed + signf(fixed) * 0.075, along, LEVEL + 0.1, 0.23, 0.17, "metal", TRIM, false)

func _flight(x: float, first_z: float, direction: float, bottom: float, exterior: bool) -> void:
	for i in 19:
		var height := (i + 1) * LEVEL / 19.0
		var z := first_z + direction * i * 0.4
		# Thin connected treads form a real stair underside, not a filled cuboid.
		part(Vector3(x, bottom + height - 0.12, z), Vector3(1.8, 0.24, 0.4), "floor", Color("a9ada6"))
		part(Vector3(x, bottom + height + 0.008, z - direction * 0.16), Vector3(1.78, 0.016, 0.065), "metal", TRIM, false)
		if exterior:
			for side in [-1, 1]:
				# Solid low guards and thin handrails follow each flight without blocking entry.
				part(Vector3(x + side * 1.0, bottom + height + 0.43, z), Vector3(0.12, 0.86, 0.4), "metal", FRAME)
				part(Vector3(x + side * 1.0, bottom + height + 0.89, z), Vector3(0.16, 0.07, 0.43), "metal", TRIM, false)

func _build() -> void:
	_slab(LEVEL, 0.95, 3.05, -3.6, 4.4)
	_slab(ROOF, -3.45, -1.35, -4.4, 3.6)
	for end in [-1, 1]:
		_wall(0, end * 5.5, 9, [Vector4(-3.2, -1.0, 0.85, 2.45), Vector4(1.0, 3.2, 0.85, 2.45)])
	for side in [-1, 1]:
		var gaps: Array[Vector4] = [Vector4(-3.4, -1, 0.85, 2.45), Vector4(0, 2.4, 0.85, 2.45)]
		if side == outward:
			gaps.append(Vector4(3.15, 5.3, 0, 2.8))
		_wall(1, side * 4.5, 11, gaps)
	# Parallel internal flights leave a full-height landing at each end.
	_flight(2.0, 3.8, -1, 0, false)
	_flight(-2.4, -3.8, 1, LEVEL, false)
	# Guard the long sides of the upper stairwell. Ends remain open for walking.
	for x in [0.9, 3.1]:
		part(Vector3(x, LEVEL + 0.46, 0.4), Vector3(0.1, 0.92, 7.7), "metal", FRAME)
	for x in [-3.5, -1.3]:
		part(Vector3(x, ROOF + 0.46, -0.4), Vector3(0.1, 0.92, 7.7), "metal", FRAME)
	# Exterior switchback: ground -> upper door -> roof, an independent counter-route.
	_flight(outward * 6.0, -3.8, 1, 0, true)
	_flight(outward * 8.3, 3.8, -1, LEVEL, true)
	part(Vector3(outward * 6.4, LEVEL - 0.15, 4.6), Vector3(5.0, 0.3, 2.0), "floor", TRIM)
	part(Vector3(outward * 6.4, ROOF - 0.15, -4.6), Vector3(5.0, 0.3, 2.0), "floor", TRIM)
	for y in [LEVEL, ROOF]:
		var z := 5.58 if y == LEVEL else -5.58
		part(Vector3(outward * 6.4, y + 0.48, z), Vector3(5.0, 0.96, 0.13), "metal", FRAME)
		part(Vector3(outward * 8.9, y + 0.48, z - signf(z) * 0.85), Vector3(0.13, 0.96, 1.8), "metal", FRAME)
	# Solid parapets protect crouched players; the rear screen limits spawn views.
	for side in [-1, 1]:
		if side == outward:
			part(Vector3(side * 4.6, ROOF + 0.5, 1), Vector3(0.25, 1, 9), "concrete", Color("bab8aa"))
		else:
			part(Vector3(side * 4.6, ROOF + 0.5, 0), Vector3(0.25, 1, 11.3), "concrete", Color("bab8aa"))
		var height := 2.2 if side == signf(origin.z) else 1.0
		part(Vector3(0, ROOF + height / 2, side * 5.6), Vector3(9.4, height, 0.25), "concrete", Color("bab8aa"))
		part(Vector3(0, ROOF + height + 0.035, side * 5.6), Vector3(9.5, 0.07, 0.34), "metal", FRAME, false)
	# Central roof machinery interrupts diagonal roof-to-roof sightlines.
	part(Vector3(1, ROOF + 0.65, 0.3), Vector3(2.3, 1.3, 2.3), "corrugated", Color("a1aaa2"))
	if batch:
		for x in [0.45, 1.55]:
			batch.cylinder(origin + Vector3(x, ROOF + 1.33, 0.3), 0.42, 0.06, "metal", FRAME)
		for i in 8:
			part(Vector3(1, ROOF + 0.2 + i * 0.12, 1.46), Vector3(2.05, 0.025, 0.035), "metal", FRAME, false)
		for x in [-0.08, 2.08]:
			part(Vector3(x, ROOF + 0.66, 0.3), Vector3(0.055, 1.26, 2.28), "metal", FRAME, false)
		# Ceiling flanges stay away from the roof stairwell at x=-2.4.
		for x in [0.0, 3.8]:
			part(Vector3(x, ROOF - 0.38, 0), Vector3(0.23, 0.11, 10.8), "metal", FRAME, false)
		# Flush warehouse wayfinding and fixtures sit on solid upper-wall panels.
		part(Vector3(-0.03, LEVEL + 2.87, -5.28), Vector3(0.85, 0.18, 0.025), "paint", FRAME, false)
		part(Vector3(-0.03, LEVEL + 2.87, -5.255), Vector3(0.7, 0.075, 0.02), "paint", Color("dee8df"), false)
		var model := Node3D.new()
		model.name = "UpperFloors_%s_%s" % [int(origin.x), int(origin.z)]
		arena.add_child(model)
		batch.finish(model, "FloorDetail")
		var light := OmniLight3D.new()
		light.position = origin + Vector3(-0.4, LEVEL + 2.8, 0)
		light.name = "WarehouseUpperBounce"
		light.light_color = Color("c9dfe1")
		light.light_energy = 0.32
		light.omni_range = 7
		arena.add_child(light)
		arena.sign_text("01 / OPERATIONS", origin + Vector3(0, LEVEL + 2.6, -5.28), 0, TRIM, 30)
		arena.sign_text("ROOF ACCESS  →", origin + Vector3(-0.15, LEVEL + 2.2, -5.28), 0, WARNING, 23)
