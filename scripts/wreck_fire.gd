class_name WreckFire
extends Node3D

var clock := 0.0

func _physics_process(dt: float) -> void:
	var game := get_parent().get_parent()
	if not game.get("active") or not game.get("is_host") or game.get("match_over"): return
	clock += dt
	if clock < 0.25: return
	clock = 0
	for p: Fighter in game.players.values():
		if p.hp > 0 and p.eye().distance_to(global_position) < 2 and game.visible_between(global_position, p.eye(), [p.get_rid()]):
			game.combat.damage(p, p, 5, "WRECK FIRE", false, global_position)
