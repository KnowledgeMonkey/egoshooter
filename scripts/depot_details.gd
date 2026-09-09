class_name DepotDetails
extends RefCounted

# Fabricated depot details use the existing collision shell. Four freight stacks
# replace the art of concrete cover, never its size or authoritative collision.
# Everything else is wall-mounted or above the highest opening in a facade.
const STEEL := Color("424b4b")
const GALVANIZED := Color("89918b")
const RUST := Color("74634e")
const WOOD := Color("c8b79c")
const DARK_WOOD := Color("9b896e")
const CABLE := Color("252e2e")
const MARKING := Color("bdac72")
const FREIGHT_POSITIONS := [Vector3(-19, 0.7, 12), Vector3(20, 0.7, -10),
	Vector3(-32, 0.7, 23), Vector3(32, 0.7, -19)]

static func build(arena: RelayArena) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var detail := DepotDetails.new()
	detail._construct(arena)

func _construct(arena: RelayArena) -> void:
	var root := Node3D.new()
	root.name = "DepotDetails"
	arena.add_child(root)
	var batch := UrbanMeshBatch.new()
	var lamps := UrbanMeshBatch.new()
	for location in FREIGHT_POSITIONS:
		_replace_cover_art(arena, location)
		_freight(batch, location - Vector3(0, 0.7, 0))
	for side in [-1.0, 1.0]:
		_perimeter_services(batch, side)
		_gantry(batch, side * 18.0)
	# Consistent repeated fittings make the eight structures read as one facility.
	for origin in arena.building_origins:
		_wall_services(batch, lamps, origin)
	for side in [-1.0, 1.0]:
		for z in [-48.0, -16.0, 16.0, 48.0]:
			_boundary_lamp(batch, lamps, Vector3(side * 44.44, 3.35, z), side)
	batch.finish(root, "DepotFabrication")
	var luminaires := Node3D.new()
	luminaires.name = "DepotLuminaireDiffusers"
	root.add_child(luminaires)
	lamps.finish(luminaires, "LightDiffusers")
	var diffuser := StandardMaterial3D.new()
	diffuser.albedo_color = Color("c2d3ce")
	diffuser.emission_enabled = true
	diffuser.emission = Color("b9d8d6")
	diffuser.emission_energy_multiplier = 2.0
	diffuser.roughness = 0.4
	for child in luminaires.get_children():
		(child as MeshInstance3D).material_override = diffuser
		(child as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _replace_cover_art(arena: RelayArena, position: Vector3) -> void:
	for child in arena.get_children():
		if not child is Node3D or not (child as Node3D).position.is_equal_approx(position):
			continue
		# Collision is under an arena MeshInstance3D, whereas UrbanCover is a
		# plain Node3D whose only children are these static visual batches.
		if child is MeshInstance3D:
			continue
		for surface in child.get_children():
			if surface is MeshInstance3D and str(surface.name).begins_with("ConcreteBarrier"):
				(child as Node3D).visible = false

func _rod(batch: UrbanMeshBatch, a: Vector3, b: Vector3, radius: float,
		kind: String = "metal", tint: Color = STEEL) -> void:
	var rotation := Quaternion(Vector3.UP, (b - a).normalized()).get_euler()
	batch.cylinder((a + b) * 0.5, radius, a.distance_to(b), kind, tint, rotation)

func _beam(batch: UrbanMeshBatch, a: Vector3, b: Vector3, width: float,
		depth: float, tint: Color = STEEL) -> void:
	var rotation := Quaternion(Vector3.UP, (b - a).normalized()).get_euler()
	batch.box((a + b) * 0.5, Vector3(width, a.distance_to(b), depth), "metal", tint, rotation)

func _freight(batch: UrbanMeshBatch, origin: Vector3) -> void:
	# Pallet stringers and deck carry two framed export cases. The combined
	# silhouette fills the unchanged 3.2 x 1.4 x 1.5 cover bounds.
	for z in [-0.59, 0.0, 0.59]:
		batch.box(origin + Vector3(0, 0.085, z), Vector3(3.19, 0.17, 0.18), "wood", DARK_WOOD)
	for slat in 10:
		batch.box(origin + Vector3(-1.435 + slat * 0.319, 0.205, 0), Vector3(0.298, 0.07, 1.49), "wood", WOOD)
	for side in [-1.0, 1.0]:
		var at := origin + Vector3(side * 0.805, 0.805, 0)
		batch.bevel_box(at, Vector3(1.51, 1.12, 1.4), "wood", WOOD, 0.016)
		# Vertical corner battens meet the top and bottom ledgers exactly.
		for z in [-0.715, 0.715]:
			for x in [-0.665, 0.665]:
				batch.box(at + Vector3(x, 0, z), Vector3(0.115, 1.18, 0.07), "wood", DARK_WOOD)
			for y in [-0.525, 0.525]:
				batch.box(at + Vector3(0, y, z), Vector3(1.52, 0.13, 0.068), "wood", DARK_WOOD)
			# Two steel packing straps sit against the wood, including over the lid.
			for x in [-0.37, 0.37]:
				batch.box(at + Vector3(x, 0, z * 0.985), Vector3(0.037, 1.12, 0.018), "metal", STEEL)
			# Small shipping label and two arrow stencils are mounted flush.
			batch.box(at + Vector3(0.14, 0.1, z * 1.011), Vector3(0.36, 0.19, 0.008), "paint", Color("bcb8a3"))
			for arrow in [-0.52, -0.42]:
				batch.box(at + Vector3(arrow, -0.23, z * 1.012), Vector3(0.02, 0.14, 0.01), "paint", CABLE)
				batch.box(at + Vector3(arrow, -0.17, z * 1.012), Vector3(0.065, 0.025, 0.01), "paint", CABLE)
		for x in [-0.37, 0.37]:
			batch.box(at + Vector3(x, 0.566, 0), Vector3(0.037, 0.018, 1.41), "metal", STEEL)
		for x in [-0.759, 0.759]:
			for y in [-0.525, 0.525]:
				batch.box(at + Vector3(x, y, 0), Vector3(0.065, 0.13, 1.45), "wood", DARK_WOOD)

func _perimeter_services(batch: UrbanMeshBatch, side: float) -> void:
	# Pipes are secured against the inner face of the existing 4.4 m wall;
	# no freestanding poles or cables occupy a walking route.
	var x := side * 44.37
	for level in [3.52, 3.99]:
		_rod(batch, Vector3(x, level, -62.4), Vector3(x, level, 62.4), 0.12, "metal", RUST if level < 3.8 else GALVANIZED)
		for z in range(-60, 61, 12):
			batch.cylinder(Vector3(x, level, z), 0.165, 0.085, "metal", STEEL, Vector3(PI / 2, 0, 0))
			for bolt in 6:
				var angle := TAU * bolt / 6.0
				batch.cylinder(Vector3(x + cos(angle) * 0.14, level + sin(angle) * 0.14, z + 0.053), 0.017, 0.035, "metal", GALVANIZED, Vector3(PI / 2, 0, 0))
	for z in range(-60, 61, 6):
		batch.box(Vector3(side * 44.48, 3.71, z), Vector3(0.06, 1.02, 0.1), "metal", STEEL)
		for level in [3.52, 3.99]:
			batch.box(Vector3(side * 44.36, level - 0.18, z), Vector3(0.32, 0.08, 0.1), "metal", STEEL)
	for z in [-47.0, 47.0]:
		# A wall-mounted junction box with real conduit connections.
		batch.bevel_box(Vector3(side * 44.42, 2.55, z), Vector3(0.14, 0.68, 0.5), "paint", STEEL, 0.025)
		_rod(batch, Vector3(side * 44.33, 2.9, z), Vector3(side * 44.33, 3.52, z), 0.026)
		batch.box(Vector3(side * 44.338, 2.55, z), Vector3(0.014, 0.16, 0.18), "paint", MARKING)

func _gantry(batch: UrbanMeshBatch, z: float) -> void:
	# Utility truss bridges the centre lane between the two inner facades.
	# End shoes bolt into the solid lintel, above all upper firing windows.
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 6.39, 6.79, z), Vector3(0.22, 0.85, 1.08), "metal", STEEL)
		for dz in [-0.4, 0.4]:
			batch.box(Vector3(side * 6.27, 7.07, z + dz), Vector3(0.38, 0.12, 0.16), "metal", GALVANIZED)
	for dz in [-0.39, 0.39]:
		batch.box(Vector3(0, 7.13, z + dz), Vector3(12.65, 0.15, 0.12), "metal", STEEL)
		batch.box(Vector3(0, 6.57, z + dz), Vector3(12.65, 0.12, 0.1), "metal", STEEL)
		for bay in 10:
			var x0 := -6.25 + bay * 1.25
			_beam(batch, Vector3(x0, 6.62, z + dz), Vector3(x0 + 0.625, 7.06, z + dz), 0.045, 0.06)
			_beam(batch, Vector3(x0 + 0.625, 7.06, z + dz), Vector3(x0 + 1.25, 6.62, z + dz), 0.045, 0.06)
	for x in [-6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0]:
		batch.box(Vector3(x, 7.06, z), Vector3(0.1, 0.12, 0.86), "metal", GALVANIZED)
	for dz in [-0.18, 0.17]:
		_rod(batch, Vector3(-6.45, 7.27, z + dz), Vector3(6.45, 7.27, z + dz), 0.1, "metal", RUST if dz < 0 else GALVANIZED)
	# Modest cable sag supplies a curved silhouette against the rigid steel.
	for offset in [-0.12, 0.12]:
		for segment in 20:
			var t0 := segment / 20.0
			var t1 := (segment + 1) / 20.0
			_rod(batch, Vector3(lerpf(-6.4, 6.4, t0), 6.65 - sin(t0 * PI) * 0.37, z + offset),
				Vector3(lerpf(-6.4, 6.4, t1), 6.65 - sin(t1 * PI) * 0.37, z + offset), 0.017, "rubber", CABLE)

func _wall_services(batch: UrbanMeshBatch, lamps: UrbanMeshBatch, origin: Vector3) -> void:
	# Rear corners have continuous solid wall. These small fixtures follow it,
	# staying well away from doors, exterior stairs and the ascender ropes.
	for side in [-1.0, 1.0]:
		var at := origin + Vector3(side * 3.75, 2.88, 5.735)
		batch.bevel_box(at, Vector3(0.61, 0.21, 0.14), "metal", STEEL, 0.025)
		lamps.box(at + Vector3(0, -0.004, 0.077), Vector3(0.48, 0.11, 0.024), "paint", Color.WHITE)
		for x in [-0.22, 0.0, 0.22]:
			batch.box(at + Vector3(x, 0, 0.097), Vector3(0.018, 0.14, 0.016), "metal", STEEL)
		_rod(batch, at + Vector3(0, 0.12, -0.01), origin + Vector3(side * 3.75, 3.22, 5.725), 0.018)
	# Cable tray and louvers use the solid band above first-floor openings.
	batch.box(origin + Vector3(0, 6.75, 5.712), Vector3(8.74, 0.14, 0.07), "metal", STEEL)
	for x in [-3.8, -1.9, 0.0, 1.9, 3.8]:
		batch.box(origin + Vector3(x, 6.75, 5.758), Vector3(0.055, 0.19, 0.04), "metal", GALVANIZED)
	var vent := origin + Vector3(0, 6.26, 5.724)
	batch.box(vent, Vector3(1.24, 0.51, 0.1), "metal", CABLE)
	for slat in 7:
		batch.box(vent + Vector3(0, -0.206 + slat * 0.069, 0.062), Vector3(1.14, 0.024, 0.052), "metal", GALVANIZED, Vector3(-0.25, 0, 0))

func _boundary_lamp(batch: UrbanMeshBatch, lamps: UrbanMeshBatch, position: Vector3, side: float) -> void:
	batch.box(position, Vector3(0.11, 0.23, 0.55), "metal", STEEL)
	lamps.box(position + Vector3(-side * 0.065, 0, 0), Vector3(0.035, 0.14, 0.45), "paint", Color.WHITE)
	for z in [-0.18, 0.0, 0.18]:
		batch.box(position + Vector3(-side * 0.087, 0, z), Vector3(0.016, 0.17, 0.018), "metal", STEEL)
