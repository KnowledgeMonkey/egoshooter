class_name WeaponSkins
extends RefCounted

const PARTS := ["receiver", "handguard", "stock", "barrel", "grip", "optic", "magazine", "bolt"]
const LABELS := ["Gehäuse", "Handschutz", "Schaft", "Lauf", "Griff", "Visierung", "Magazin", "Verschluss"]
static var designs: Dictionary = {}
static var revision := 0

static func clean(value: Variant) -> Dictionary:
	if not value is Dictionary: return {}
	var result := {}
	for key in PARTS + ["text_color"]:
		if value.get(key) is Color:
			var c: Color = value[key]
			if is_finite(c.r) and is_finite(c.g) and is_finite(c.b): result[key] = Color(clampf(c.r, 0, 1), clampf(c.g, 0, 1), clampf(c.b, 0, 1), 1)
	var words := str(value.get("text", "")).replace("\n", " ").replace("\r", " ").replace("\t", " ").left(32)
	result.text = words
	return result

static func set_design(weapon: int, design: Dictionary) -> void:
	if weapon < 0 or weapon >= Arsenal.DATA.size(): return
	designs[str(weapon)] = clean(design)
	revision += 1

static func get_design(weapon: int) -> Dictionary:
	return clean(designs.get(str(weapon), {}))

static func split_frame(frame: Node3D) -> void:
	# Preserve semantic parts before batching so customization never recolors an entire weapon.
	var nodes := {}
	for part in PARTS.slice(0, 6):
		var group := Node3D.new()
		group.name = part
		frame.add_child(group)
		nodes[part] = group
	for child in frame.get_children():
		if not child is MeshInstance3D: continue
		var at: Vector3 = child.transform * child.mesh.get_aabb().get_center()
		var part := "receiver"
		if at.z > 0.10: part = "stock"
		elif at.z < -0.53: part = "barrel"
		elif at.z < -0.23: part = "handguard"
		elif at.y > 0.065: part = "optic"
		elif at.y < -0.055: part = "grip"
		frame.remove_child(child)
		nodes[part].add_child(child)
	for part in nodes:
		WeaponGeometry.batch(nodes[part])
		nodes[part].set_meta("skin_part", part)

static func apply(model: Node3D, design: Dictionary) -> void:
	design = clean(design)
	for part in PARTS:
		var group := model.get_node_or_null("Frame/" + part)
		if part == "magazine": group = model.get_node_or_null("Magazine")
		if part == "bolt": group = model.get_node_or_null("Bolt")
		if group == null: continue
		for child in group.get_children():
			if not child is MeshInstance3D: continue
			if not child.has_meta("factory_material"): child.set_meta("factory_material", child.material_override)
			var factory: StandardMaterial3D = child.get_meta("factory_material")
			child.material_override = factory
			if design.has(part) and not factory.emission_enabled:
				var finish := factory.duplicate() as StandardMaterial3D
				finish.albedo_color = design[part]
				child.material_override = finish
	var lettering := model.get_node_or_null("CustomLettering")
	if lettering == null:
		lettering = Node3D.new()
		lettering.name = "CustomLettering"
		model.add_child(lettering)
		for side in [-1, 1]:
			var label := Label3D.new()
			label.name = "Text" + str(side)
			label.position = Vector3(side * 0.082, 0.018, -0.02)
			label.rotation.y = side * PI / 2
			label.pixel_size = 0.00035
			label.font_size = 48
			label.outline_size = 0
			label.no_depth_test = false
			lettering.add_child(label)
	for label: Label3D in lettering.get_children():
		label.text = design.get("text", "")
		label.pixel_size = minf(0.00035, 0.20 / maxf(1, label.text.length() * 28))
		label.modulate = design.get("text_color", Color.WHITE)

static func loadout_designs(primary: int) -> Dictionary:
	return clean_loadout(designs, primary)

static func clean_loadout(value: Variant, primary: int) -> Dictionary:
	var result := {}
	if value is Dictionary:
		for index in [Arsenal.primary_id(primary), 4]:
			result[str(index)] = clean(value.get(str(index), {}))
	return result
