extends SceneTree
var game: Node3D
var server := false
var elapsed := 0.0
var ready := false
var placed := false
var rewarded := false
var saw_reward := false
var saw_mine := false
var saw_nuke := false
var sent := false
func _initialize() -> void:
	server = "--server" in OS.get_cmdline_user_args()
	call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.port = 27986
	if server: game.host({"server_name": "Streak LAN", "mode": "FFA", "max_players": 8, "bots": 0, "score_limit": 100, "time_limit": 600})
	else: game.join("127.0.0.1:27986")
	ready = true
func _physics_process(dt: float) -> bool:
	if not ready: return false
	elapsed += dt
	if game.active:
		if server:
			for p: Fighter in game.players.values():
				if p.peer_id == 1: continue
				if not placed:
					p.reset_at(Vector3(0, 0.1, 28))
					for i in 5: game.streaks.earned(p)
					placed = true
				saw_reward = p.infinite_left > 0 and p.streak >= 5
				if not game.streaks.mines.is_empty():
					saw_mine = true
					if not rewarded:
						for i in 15: game.streaks.earned(p)
						rewarded = true
		else:
			game.set_physics_process(false)
			var p: Fighter = game.players.get(game.local_id)
			if p != null and p.streak >= 5:
				saw_reward = p.infinite_left > 0
				if not sent:
					game.submit_actions.rpc_id(1, 1, {"ultimate": true})
					sent = true
			saw_mine = saw_mine or not game.streaks.mines.is_empty()
		saw_nuke = saw_nuke or game.streaks.nuke_left > 0
	if elapsed > (7 if server else 5):
		var ok := saw_reward and saw_mine and saw_nuke
		print("STREAK NETWORK ", "HOST" if server else "CLIENT", " result=", ok, " reward=", saw_reward, " mine=", saw_mine, " nuke=", saw_nuke)
		game.leave()
		quit(0 if ok else 1)
	return false
