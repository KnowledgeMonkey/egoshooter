class_name WarDistrict
extends RefCounted

var arena: RelayArena
var batch: UrbanMeshBatch
const STEEL := Color("525951")
const SCORCHED := Color("30312b")

static func build(target: RelayArena) -> void:
	var district := WarDistrict.new()
	district.arena = target
	if DisplayServer.get_name() != "headless": district.batch = UrbanMeshBatch.new()
	district.construct()

func part(pos: Vector3, size: Vector3, kind: String, tint: Color, solid := true) -> void:
	if solid: arena.box(pos, size, tint).visible = false
	if batch: batch.bevel_box(pos, size, kind, tint, 0.04)

func construct() -> void:
	for side in [-1, 1]:
		arena.box(Vector3(side * 39, 0.025, 0), Vector3(8, 0.04, 122), RelayArena.ROAD, false)
		for end in [-1, 1]:
			arena.building(side * 32, end * 34, Color("7a8175") if side < 0 else Color("998775"), "SECTOR %s / CIVIL DEFENCE" % (3 + side + end))
		bus(Vector3(side * 32, 0, side * 10))
		truck(Vector3(side * 13, 0, side * 56))
		tank(Vector3(side * 37, 0, -side * 54))
		arena.car(side * 39, -side * 15, SCORCHED)
		arena.car(side * 22, side * 56, Color("655e4e"))
		wreck(Vector3(side * 39, 0, -side * 15))
		for z in [-57, -7, 22, 58]:
			barricade(Vector3(side * 7, 0, z))
		for z in [-48, 48]:
			barricade(Vector3(side * 32, 0, z))
	# Keep the centre three lanes and the existing protected spawns intact.
	for point in [Vector3(-22, 0, -18), Vector3(23, 0, 19)]:
		wreck(point)
	for side in [-1, 1]:
		arena.sign_text("CHECKPOINT / NO CIVILIAN ACCESS", Vector3(0, 2.6, side * 34.65), PI if side > 0 else 0, Color("d8c18d"), 26)
	for origin in arena.building_origins:
		vending(origin + Vector3(-3.75, 0.1, -1.8))
		scars(origin)
	for origin in [Vector3(-11, 0, -18), Vector3(11, 0, 18), Vector3(-32, 0, 34), Vector3(32, 0, -34)]:
		lift(origin)
	if batch:
		var models := Node3D.new()
		models.name = "WarDistrictDetails"
		arena.add_child(models)
		batch.finish(models)

func wheels(origin: Vector3, length: float) -> void:
	if not batch: return
	for side in [-1, 1]:
		for z in [-length * 0.32, length * 0.32]:
			batch.cylinder(origin + Vector3(side * 1.45, 0.6, z), 0.58, 0.25, "rubber", Color("242822"), Vector3(0, 0, PI / 2))
			batch.cylinder(origin + Vector3(side * 1.59, 0.6, z), 0.30, 0.04, "metal", STEEL, Vector3(0, 0, PI / 2))

func bus(o: Vector3) -> void:
	# Two opposite open doors, empty central aisle, physical window openings.
	part(o + Vector3(0, 0.38, 0), Vector3(3, 0.5, 10), "metal", STEEL)
	part(o + Vector3(0, 3.02, 0), Vector3(3.1, 0.22, 10.2), "paint", Color("b2ac8e"))
	for side in [-1, 1]:
		for segment in [-1, 1]:
			part(o + Vector3(side * 1.46, 1.02, segment * 2.95), Vector3(0.12, 0.8, 4.1), "paint", Color("847d4f"))
			part(o + Vector3(side * 1.46, 2.7, segment * 2.95), Vector3(0.12, 0.43, 4.1), "paint", Color("aaa58c"))
		for z in [-4.8, -3.1, -1.15, 1.15, 3.1, 4.8]:
			part(o + Vector3(side * 1.46, 2.0, z), Vector3(0.12, 1.3, 0.12), "metal", STEEL)
		for step in 3:
			var height := (step + 1) * 0.21
			part(o + Vector3(side * (2.35 - step * 0.36), height / 2, 0), Vector3(0.36, height, 1.8), "metal", STEEL)
		for z in [-3.6, -2, 2, 3.6]:
			part(o + Vector3(side * 0.95, 0.99, z), Vector3(0.6, 0.3, 0.65), "rubber", Color("515c59"))
			part(o + Vector3(side * 0.95, 1.44, z + 0.26), Vector3(0.6, 0.9, 0.12), "rubber", Color("515c59"))
	for end in [-1, 1]:
		part(o + Vector3(0, 1.05, end * 4.96), Vector3(3, 0.85, 0.12), "paint", Color("a49a6b"))
		part(o + Vector3(0, 2.77, end * 4.96), Vector3(3, 0.32, 0.12), "metal", STEEL)
		part(o + Vector3(0, 0.56, end * 5.06), Vector3(3.12, 0.22, 0.18), "metal", STEEL)
	wheels(o, 10)
	arena.vehicle_entries.append(o + Vector3(0, 0.66, 0))
	arena.sign_text("EVAC / 07", o + Vector3(0, 2.73, 5.04), 0, Color("eadba2"), 23)

func truck(o: Vector3) -> void:
	part(o + Vector3(0, 0.7, 0), Vector3(3.2, 0.4, 8), "metal", STEEL)
	# Cargo bay is open at the rear with a five-step loading ramp.
	for side in [-1, 1]:
		part(o + Vector3(side * 1.52, 2, 1.1), Vector3(0.16, 2.2, 5.8), "metal", Color("727567"))
	part(o + Vector3(0, 3.2, 1.1), Vector3(3.2, 0.2, 6), "metal", Color("7e8170"))
	part(o + Vector3(0, 1.7, -2.9), Vector3(3.0, 2.0, 2.1), "paint", Color("767451"))
	part(o + Vector3(0, 2.2, -3.96), Vector3(2.55, 0.76, 0.03), "glass", Color("303e3d"), false)
	for step in 5:
		var h := (step + 1) * 0.18
		part(o + Vector3(0, h / 2, 6 - step * 0.4), Vector3(2.4, h, 0.4), "metal", STEEL)
	part(o + Vector3(-0.95, 1.35, 0), Vector3(0.8, 0.9, 1.1), "wood", Color("736548"))
	wheels(o, 8)
	arena.vehicle_entries.append(o + Vector3(0, 0.92, 2))
	arena.sign_text("SUPPLY / 12", o + Vector3(0, 3.1, 4.13), 0, Color("ddd1a6"), 22)

func barricade(o: Vector3) -> void:
	part(o + Vector3(0, 0.35, 0), Vector3(3.5, 0.7, 1.0), "concrete", Color("7f8074"))
	part(o + Vector3(0, 0.95, 0), Vector3(3.3, 0.5, 0.5), "concrete", Color("999587"))
	for x in [-1.2, -0.4, 0.4, 1.2]:
		part(o + Vector3(x, 0.93, 0.26), Vector3(0.35, 0.22, 0.02), "paint", Color("c2a153"), false)
	# Staggered sandbags soften the silhouette and provide low cover.
	for row in 2:
		for bag in 4:
			part(o + Vector3(-1.2 + bag * 0.75 + row * 0.15, 1.3 + row * 0.23, 0), Vector3(0.72, 0.24, 0.5), "concrete", Color("8c805e"))

func tank(o: Vector3) -> void:
	arena.box(o + Vector3(0, 1.05, 0), Vector3(3.8, 1.1, 6.8), STEEL).visible = false
	arena.box(o + Vector3(0, 1.95, -0.5), Vector3(2.6, 0.95, 3.0), STEEL).visible = false
	arena.box(o + Vector3(0, 2.15, -3.7), Vector3(0.25, 0.25, 4.2), STEEL).visible = false
	if batch:
		batch.profile(PackedVector2Array([Vector2(-3.4, 0.55), Vector2(3.4, 0.55), Vector2(3.1, 1.6), Vector2(-2.4, 1.6), Vector2(-3.4, 0.9)]), 3.8, o, "metal", Color("62664f"), 0.18)
		batch.profile(PackedVector2Array([Vector2(-2, 1.5), Vector2(1, 1.5), Vector2(0.7, 2.4), Vector2(-1.3, 2.4)]), 2.6, o, "metal", Color("717257"), 0.22)
		batch.cylinder(o + Vector3(0, 2.15, -3.7), 0.14, 4.2, "metal", STEEL, Vector3(PI / 2, 0, 0), 0.10)
	for side in [-1, 1]:
		part(o + Vector3(side * 1.8, 0.55, 0), Vector3(0.7, 1.0, 7), "rubber", SCORCHED)
		if batch:
			for z in [-2.6, -1.3, 0, 1.3, 2.6]:
				batch.cylinder(o + Vector3(side * 2.17, 0.55, z), 0.4, 0.08, "metal", STEEL, Vector3(0, 0, PI / 2))
			for z in range(14):
				batch.bevel_box(o + Vector3(side * 2.18, 0.12, -3.25 + z * 0.5), Vector3(0.08, 0.12, 0.30), "metal", SCORCHED)
			for z in [-1.8, -0.9, 0, 0.9, 1.8]:
				batch.bevel_box(o + Vector3(side * 1.89, 1.35, z), Vector3(0.11, 0.34, 0.7), "metal", Color("85836b"))
	if batch: batch.cylinder(o + Vector3(0.6, 2.5, -0.5), 0.46, 0.1, "metal", STEEL)

func wreck(o: Vector3) -> void:
	for i in 7:
		part(o + Vector3(-2 + i * 0.6, 0.06, 2.8 + sin(i) * 0.8), Vector3(0.55, 0.10, 0.35), "metal", SCORCHED, false)
	if batch:
		var fire := BurnVisual.new()
		fire.remaining = INF
		fire.points = [o + Vector3(0, 0.7, -1.5)]
		arena.add_child(fire)
	# Environmental fire is visible and dangerous only within the wreck footprint.
	var hazard := WreckFire.new()
	hazard.position = o + Vector3(0, 0.7, -1.5)
	arena.add_child(hazard)

func vending(o: Vector3) -> void:
	part(o + Vector3(0, 1.0, 0), Vector3(0.8, 2, 0.8), "metal", Color("354e4c"))
	part(o + Vector3(0, 1.35, 0.41), Vector3(0.55, 0.55, 0.03), "glass", Color("526b61"), false)
	arena.sign_text("ARMORY\nOFFLINE", o + Vector3(0, 1.38, 0.44), 0, Color("c2af78"), 15)
	arena.vending_points.append(o)

func scars(o: Vector3) -> void:
	for side in [-1, 1]:
		for i in 9:
			part(o + Vector3(side * 3.4 + sin(i * 13) * 0.38, 0.7 + fmod(i * 0.67, 2), 5.685), Vector3(0.09, 0.07, 0.01), "concrete", SCORCHED, false)
		for i in 5:
			part(o + Vector3(side * (3.2 + fmod(i * 0.47, 1.2)), 0.1, 6.2 + i * 0.12), Vector3(0.5, 0.2, 0.33), "concrete", Color("76766c"), false)
	# Boarded partial ground-floor frontage; entrances and upper firing windows remain clear.
	part(o + Vector3(3.0, 1.2, 5.71), Vector3(1.9, 0.24, 0.08), "wood", Color("746348"), false)
	# Irregular blast soot sits on the closed ground-floor wall panels.
	for i in 5:
		part(o + Vector3(-3.0 + sin(i * 2.3) * 0.45, 1.0 + i * 0.32, -5.684), Vector3(0.8 - i * 0.09, 0.36, 0.009), "concrete", Color("494941"), false)

func lift(o: Vector3) -> void:
	var side := -signf(o.z) # Use the low, centre-facing parapet, never the rear spawn screen.
	var bottom := o + Vector3(0, 0.1, side * 7.0)
	var top := o + Vector3(0, 7.43, side * 4.7)
	arena.lifts.append({"bottom": bottom, "top": top, "over": o + Vector3(0, 9.1, side * 7.0)})
	part(o + Vector3(0, 10.1, side * 5.4), Vector3(0.25, 2.6, 0.25), "metal", STEEL, false)
	part(o + Vector3(0, 11.3, side * 6.2), Vector3(0.25, 0.2, 2.5), "metal", STEEL, false)
	part(bottom + Vector3(0, 5.5, 0), Vector3(0.035, 11, 0.035), "metal", Color("322f26"), false)
	part(bottom + Vector3(0, 1.1, 0), Vector3(0.22, 0.3, 0.2), "paint", Color("d8ad43"), false)
	arena.sign_text("E / ASCENDER", bottom + Vector3(0, 2.1, 0), 0, Color("ddbf77"), 24)
