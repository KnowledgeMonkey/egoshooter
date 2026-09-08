extends SceneTree

var game: Node3D
var elapsed := 0.0
var saw_eight := false
var moved := false
var initial := Vector3.ZERO
var snapshots := 0
var sequence := 0
var rounds := false
var saw_ended := false
var saw_restart := false

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	rounds = "--rounds" in OS.get_cmdline_user_args()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.nickname = "DedicatedClient"
	game.join("127.0.0.1:27987" if rounds else "127.0.0.1:27988")

func _physics_process(dt: float) -> bool:
	if not is_instance_valid(game):
		return false
	elapsed += dt
	if game.active and game.players.has(game.local_id):
		game.set_physics_process(false)
		var p: Fighter = game.players[game.local_id]
		var humans := 0
		for fighter: Fighter in game.players.values():
			if not fighter.bot:
				humans += 1
		saw_eight = saw_eight or humans == (2 if rounds else 8)
		if rounds:
			saw_ended = saw_ended or game.match_over
			saw_restart = saw_restart or (saw_ended and not game.match_over and game.time_left > 50 and p.hp > 0 and p.killer_id == 0)
		if game.players.has(1) or game.players.size() > 8:
			printerr("FAIL dedicated server occupies a player slot")
			quit(1)
		if snapshots == 0:
			initial = p.target_position
		snapshots += 1
		moved = moved or initial.distance_to(p.target_position) > 1.0
		sequence += 1
		game.submit_input.rpc_id(1, sequence, {"move": Vector2(-1, 0), "yaw": 0.0, "pitch": 0.0, "hp": 99999})
		if p.hp > 100:
			printerr("FAIL client state accepted")
			quit(1)
	if elapsed >= (69 if rounds else 12):
		var success := saw_eight and moved and snapshots > 30
		if rounds:
			success = success and saw_ended and saw_restart
			print("DEDICATED ROUNDS ended=", saw_ended, " restarted=", saw_restart)
		print("DEDICATED CLIENT eight_humans=", saw_eight, " moved=", moved, " snapshots=", snapshots, " result=", success)
		game.leave()
		quit(0 if success else 1)
	return false
