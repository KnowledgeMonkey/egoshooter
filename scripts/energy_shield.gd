class_name EnergyShield
extends Node3D

const DURATION := 45.0
var fighter: Fighter
var opening := 0.0
var surface: MeshInstance3D

static func activate(p: Fighter) -> void:
	if not p.game.is_host or not p.game.active or p.game.match_over or p.hp <= 0 or p.shield_charges <= 0 or p.shield_left > 0: return
	p.shield_charges -= 1
	p.shield_left = DURATION
	p.protection = 0

static func blocks(p: Fighter, origin: Vector3) -> bool:
	if p.shield_left <= 0 or p.hp <= 0 or not origin.is_finite(): return false
	var offset := origin - p.eye()
	return offset.length_squared() > 0.001 and Arsenal.direction(p.yaw, p.pitch).dot(offset.normalized()) > 0.01

static func pose(p: Fighter) -> Transform3D:
	var facing := Basis.from_euler(Vector3(p.pitch, p.yaw, 0))
	return Transform3D(facing, p.eye() + facing * Vector3(0, -0.4, -0.95))

static func clip_ray(game: Node3D, source: Fighter, start: Vector3, end: Vector3, original: Dictionary) -> Dictionary:
	var best := start.distance_to(original.position) if not original.is_empty() else start.distance_to(end)
	var result := original
	for target: Fighter in game.players.values():
		if target == source or target.hp <= 0 or target.shield_left <= 0: continue
		var transform := pose(target)
		var a := transform.affine_inverse() * start
		var b := transform.affine_inverse() * end
		# Outward face is -Z. One-way shield: incoming rays only.
		if a.z >= 0 or b.z <= a.z: continue
		var t := -a.z / (b.z - a.z)
		if t < 0 or t > 1: continue
		var point := a.lerp(b, t)
		if absf(point.x) > 1.2 or absf(point.y) > 1.35: continue
		var world := transform * point
		if start.distance_to(world) < best:
			best = start.distance_to(world)
			result = {"position": world, "collider": null, "shield": target}
	return result

func _ready() -> void:
	surface = MeshInstance3D.new()
	var panel := QuadMesh.new()
	panel.size = Vector2(2.4, 2.7)
	surface.mesh = panel
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
 vec2 edge = abs(UV - vec2(0.5)) * 2.0;
 float rim = smoothstep(0.94, 0.99, max(edge.x, edge.y));
 vec2 cell = abs(fract(UV * vec2(18.0, 20.0)) - vec2(0.5));
 float grid = smoothstep(0.465, 0.495, max(cell.x, cell.y));
 float sweep = pow(max(0.0, sin(UV.y * 24.0 - TIME * 3.0)), 18.0);
 ALBEDO = mix(vec3(0.10, 0.65, 1.0), vec3(0.90, 0.98, 1.0), rim);
 EMISSION = ALBEDO * (0.7 + rim * 2.5);
 ALPHA = 0.035 + rim * 0.78 + grid * 0.15 + sweep * 0.06;
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	surface.material_override = material
	add_child(surface)
	visible = false

func _process(dt: float) -> void:
	var enabled: bool = fighter.game.active and fighter.hp > 0 and fighter.shield_left > 0
	opening = move_toward(opening, 1.0 if enabled else 0.0, dt * 6)
	visible = opening > 0
	if not visible: return
	global_transform = pose(fighter)
	surface.scale = Vector3(maxf(0.01, WeaponHandling.smooth(opening)), 1, 1)
