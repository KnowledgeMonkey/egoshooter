class_name BurnVisual
extends Node3D

var points: Array[Vector3] = []
var remaining := 6.0
var elapsed := 0.0
var smoke_clock := 0.0
var flames: Array[MeshInstance3D] = []
var embers: Array[MeshInstance3D] = []
var light: OmniLight3D

func _ready() -> void:
	for point in points:
		var flame := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.7, 2.5)
		flame.mesh = quad
		flame.material_override = CombatVisuals.finish("flame")
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(flame)
		flame.global_position = point + Vector3.UP * 1.0
		flames.append(flame)
		var ember := MeshInstance3D.new()
		var disk := QuadMesh.new()
		disk.size = Vector2(2.8, 2.8)
		ember.mesh = disk
		ember.material_override = CombatVisuals.finish("embers")
		ember.rotation.x = -PI / 2
		ember.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ember)
		ember.global_position = point
		embers.append(ember)
	if not points.is_empty():
		light = OmniLight3D.new()
		light.light_color = Color("ff772b")
		light.light_energy = 1.5
		light.omni_range = 9
		add_child(light)
		light.global_position = points[0] + Vector3.UP * 1.2

func _process(dt: float) -> void:
	remaining -= dt
	elapsed += dt
	if remaining <= 0:
		queue_free()
		return
	var fade := clampf(remaining, 0, 1)
	for i in flames.size():
		var flicker := 0.85 + sin(elapsed * 13 + i * 2.7) * 0.16
		flames[i].scale = Vector3(1, flicker, 1)
		flames[i].transparency = 1 - fade * (0.82 + sin(elapsed * 9 + i) * 0.12)
		embers[i].transparency = 1 - fade * 0.85
	if light:
		light.light_energy = fade * (1.3 + sin(elapsed * 17) * 0.25)
	smoke_clock -= dt
	if smoke_clock <= 0 and not points.is_empty():
		smoke_clock = 0.25
		var index := int(elapsed * 7) % points.size()
		CombatVisuals.puff(self, points[index] + Vector3.UP * 1.3, 1.3, "smoke", 1.1, Vector3(0.25, 2.1, 0.1))
