class_name WeaponAttachments
extends RefCounted

const SLOTS := ["optic", "muzzle", "underbarrel", "magazine", "stock"]
const LABELS := ["Visier", "Mündung", "Unterlauf", "Magazin", "Schaft"]
const OPTIONS := {
	"optic": ["Standard", "Reflexvisier"], "muzzle": ["Standard", "Schalldämpfer", "Kompensator"],
	"underbarrel": ["Standard", "Vordergriff"], "magazine": ["Standard", "Erweitert", "Schnellwechsel"], "stock": ["Standard", "Leichtbau"]}
const HELP := {
	"optic": ["Werksvisierung", "−10 % Streuung; +5 % Zielzeit"],
	"muzzle": ["Werksmündung", "Kein Schuss-Radarping; −15 % Reichweite", "−25 % Rückstoß; +8 % Zielzeit"],
	"underbarrel": ["Ohne Griff", "−20 % Streuung; −3 % Lauftempo"],
	"magazine": ["Standardmagazin", "+40 % Kapazität; +20 % Nachladezeit", "−20 % Nachladezeit; −15 % Kapazität"],
	"stock": ["Standardschaft", "+6 % Lauftempo; +15 % Rückstoß"]}

static func clean(value: Variant) -> Dictionary:
	var result := {}
	if value is Dictionary:
		for slot in SLOTS:
			var v = value.get(slot, 0)
			result[slot] = clampi(int(v), 0, OPTIONS[slot].size() - 1) if (v is int or v is float) and is_finite(float(v)) else 0
	return result

static func stats(index: int, design: Dictionary) -> Dictionary:
	var w: Dictionary = Arsenal.DATA[index].duplicate()
	var a := clean(design.get("attachments", {}))
	w.ads = float(WeaponHandling.DATA[index].ads)
	if a.get("optic", 0) == 1: w.spread *= 0.9; w.ads *= 1.05
	if a.get("muzzle", 0) == 1: w.range *= 0.85
	if a.get("muzzle", 0) == 2: w.recoil *= 0.75; w.ads *= 1.08
	if a.get("underbarrel", 0) == 1: w.spread *= 0.8; w.speed *= 0.97
	if a.get("magazine", 0) == 1: w.mag = int(ceil(w.mag * 1.4)); w.reload *= 1.2
	if a.get("magazine", 0) == 2: w.mag = maxi(1, int(floor(w.mag * 0.85))); w.reload *= 0.8
	if index != 4 and a.get("stock", 0) == 1: w.speed *= 1.06; w.recoil *= 1.15
	return w

static func apply(model: Node3D, design: Dictionary) -> void:
	var old := model.get_node_or_null("Attachments")
	if old: model.remove_child(old); old.queue_free()
	# Pistol optics follow the animated slide.
	var bolt := model.get_node("Bolt") as Node3D
	var old_slide := bolt.get_node_or_null("SlideAttachments")
	if old_slide: bolt.remove_child(old_slide); old_slide.queue_free()
	var group := Node3D.new(); group.name = "Attachments"; model.add_child(group)
	var index := int(model.get_meta("weapon_index", 0))
	var family: int = Arsenal.FAMILIES[index]
	var pistol := index == 4
	var a := clean(design.get("attachments", {}))
	var muzzle := model.get_node_or_null("Muzzle") as Node3D
	var factory_optic := model.get_node_or_null("Frame/FactoryOptic") as Node3D
	if factory_optic: factory_optic.visible = a.get("optic", 0) == 0
	# Never hide the heuristically classified Frame/optic structural group.
	var structural := model.get_node_or_null("Frame/optic") as Node3D
	if structural: structural.show()
	if muzzle and a.get("muzzle", 0) > 0:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.017 if pistol else 0.023; mesh.bottom_radius = mesh.top_radius
		mesh.height = (0.11 if pistol else 0.18) if a.muzzle == 1 else 0.045
		WeaponGeometry.part(group, mesh, muzzle.position + Vector3(0, 0, -mesh.height / 2 + 0.002), "black", Vector3(PI / 2, 0, 0))
	if a.get("optic", 0) == 1:
		var mount := Node3D.new(); mount.name = "Reflex"
		if pistol:
			var slide := Node3D.new(); slide.name = "SlideAttachments"; bolt.add_child(slide); slide.add_child(mount)
		else: group.add_child(mount)
		mount.position = Vector3(0, 0.058 if pistol else 0.057, 0.018 if pistol else -0.065)
		var width := 0.032 if pistol else 0.048
		var height := 0.029 if pistol else 0.043
		WeaponGeometry.block(mount, Vector3(0, 0.004, 0), Vector3(width, 0.008, 0.042), "black")
		for side in [-1, 1]:
			WeaponGeometry.block(mount, Vector3(side * (width / 2 - 0.002), height / 2 + 0.008, 0), Vector3(0.004, height, 0.008), "edge")
		WeaponGeometry.block(mount, Vector3(0, height + 0.008, 0), Vector3(width, 0.004, 0.008), "edge")
		var lens := MeshInstance3D.new(); lens.name = "Lens"
		var pane := QuadMesh.new(); pane.size = Vector2(width - 0.008, height - 0.003); lens.mesh = pane
		lens.position = Vector3(0, height / 2 + 0.008, 0)
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(0.55, 0.85, 0.9, 0.09)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lens.material_override = glass; lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; mount.add_child(lens)
		WeaponGeometry.block(mount, Vector3(0, height / 2 + 0.008, 0.001), Vector3(0.0012, 0.0012, 0.0005), "red")
	if a.get("underbarrel", 0) == 1:
		var z := -0.115 if pistol else (-0.22 if family == 1 else (-0.34 if index == 7 else -0.3))
		var top := -0.037 if pistol else (-0.073 if family == 1 else (-0.060 if family == 2 else -0.032))
		var length := 0.045 if pistol else 0.10
		WeaponGeometry.block(group, Vector3(0, top - length / 2 + 0.003, z), Vector3(0.028 if pistol else 0.039, length, 0.04), "polymer")
	var mag := model.get_node_or_null("Magazine") as Node3D
	if mag:
		mag.scale = Vector3.ONE
		for child in mag.get_children():
			if not child is MeshInstance3D: continue
			var scale_y := 1.3 if a.get("magazine", 0) == 1 else (0.85 if a.get("magazine", 0) == 2 else 1.0)
			# Scale around the seating surface, not around the weapon origin.
			var top := -0.177 if pistol else -0.035
			child.scale.y = scale_y
			child.position.y = top * (1.0 - scale_y)
	var stock := model.get_node_or_null("Frame/stock") as Node3D
	if stock: stock.scale = Vector3.ONE
	if a.get("stock", 0) == 1 and not pistol:
		WeaponGeometry.block(group, Vector3(0, -0.015 if family == 1 else -0.043, 0.315 if family == 1 else 0.352), Vector3(0.06, 0.07, 0.008), "edge")
