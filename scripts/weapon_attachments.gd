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
	if a.get("stock", 0) == 1: w.speed *= 1.06; w.recoil *= 1.15
	return w

static func apply(model: Node3D, design: Dictionary) -> void:
	var old := model.get_node_or_null("Attachments")
	if old: model.remove_child(old); old.queue_free()
	var group := Node3D.new()
	group.name = "Attachments"
	model.add_child(group)
	var a := clean(design.get("attachments", {}))
	var muzzle := model.get_node_or_null("Muzzle") as Node3D
	var factory_optic := model.get_node_or_null("Frame/optic") as Node3D
	if factory_optic: factory_optic.visible = a.get("optic", 0) == 0
	if muzzle and a.get("muzzle", 0) > 0:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.023; mesh.bottom_radius = 0.023
		mesh.height = 0.18 if a.muzzle == 1 else 0.065
		WeaponGeometry.part(group, mesh, muzzle.position + Vector3(0, 0, -mesh.height / 2), "black", Vector3(PI / 2, 0, 0))
	if a.get("optic", 0) == 1:
		WeaponGeometry.block(group, Vector3(0, 0.06, -0.12), Vector3(0.055, 0.065, 0.085), "black")
		WeaponGeometry.block(group, Vector3(0, 0.11, -0.14), Vector3(0.055, 0.055, 0.012), "glass")
		WeaponGeometry.block(group, Vector3(0, 0.11, -0.132), Vector3(0.004, 0.004, 0.002), "red")
	if a.get("underbarrel", 0) == 1:
		WeaponGeometry.block(group, Vector3(0, -0.1, -0.3), Vector3(0.045, 0.12, 0.045), "polymer")
	var mag := model.get_node_or_null("Magazine") as Node3D
	if mag: mag.scale.y = 1.3 if a.get("magazine", 0) == 1 else (0.85 if a.get("magazine", 0) == 2 else 1.0)
	var stock := model.get_node_or_null("Frame/stock") as Node3D
	if stock: stock.scale = Vector3(0.8, 0.8, 1) if a.get("stock", 0) == 1 else Vector3.ONE
