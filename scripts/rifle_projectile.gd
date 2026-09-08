class_name RifleProjectile
extends Node3D

var game: Node3D
var owner_id := 0
var speed := Vector3.ZERO
var distance := 0.0
var trace_clock := 0.0
var trace_start := Vector3.ZERO

func _ready() -> void:
	trace_start = global_position

func _physics_process(dt: float) -> void:
	if not game.is_host or game.match_over or not game.players.has(owner_id):
		queue_free()
		return
	var source: Fighter = game.players[owner_id]
	var next := global_position + speed * dt
	var query := PhysicsRayQueryParameters3D.create(global_position, next, 3, [source.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	distance += global_position.distance_to(next)
	speed.y -= 9.8 * dt
	trace_clock += dt
	if not hit.is_empty():
		next = hit.position
		game.impact.rpc(next)
		if hit.collider is Fighter:
			var target: Fighter = hit.collider
			var height: float = next.y - target.global_position.y
			var head := height > (1.0 if target.crouched else 1.48)
			var factor := 1.65 if head else (0.78 if height < 0.7 else 1.0)
			if game.combat.damage(target, source, 85 * factor, "M77", head) and not source.bot:
				game.feedback.rpc_id(source.peer_id, head)
		queue_free()
	if trace_clock >= 0.05 or not hit.is_empty():
		game.tracer.rpc(trace_start, next)
		trace_start = next
		trace_clock = 0
	global_position = next
	if distance >= 120: queue_free()
