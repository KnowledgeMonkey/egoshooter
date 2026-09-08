extends SceneTree

var game: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, title: String) -> void:
	checks += 1
	if value:
		print("PASS ", title)
	else:
		failures += 1
		printerr("FAIL ", title)

func run() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	var good := ServerSettings.DEFAULTS.duplicate()
	check(ServerSettings.validate(good).is_empty(), "Default dedicated configuration is valid")
	for item in [["port", -1], ["port", 27841], ["max_players", 9], ["bots", "8"], ["mode", "CTF"],
		["bind", "bad address"], ["difficulty", 8], ["round_delay", 0], ["discovery", "true"], ["typo", 1]]:
		var bad := good.duplicate()
		bad[item[0]] = item[1]
		check(not ServerSettings.validate(bad).is_empty(), "Invalid server setting rejected: %s" % item[0])
	var loaded := ServerSettings.read(PackedStringArray(["--dedicated", "--port=27989", "--bots=0", "--name=LAN Test", "--mode=FFA"]))
	check(loaded.error.is_empty() and loaded.settings.port == 27989 and loaded.settings.bots == 0 and loaded.settings.server_name == "LAN Test", "CLI overrides config without changing the file")
	check(not ServerSettings.read(PackedStringArray(["--port=oops"])).error.is_empty(), "Malformed CLI value is rejected")
	check(not ServerSettings.read(PackedStringArray(["--config=res://missing-server.json"])).error.is_empty(), "Missing configuration fails clearly")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	var server := DedicatedServer.new()
	server.game = game
	game.add_child(server)
	server.start(PackedStringArray(["--dedicated", "--port=27989", "--bots=8", "--round-delay=3", "--discovery=false"]))
	check(game.active and game.is_host and game.dedicated and game.local_id == 0, "Dedicated server owns authority without a local player")
	check(not game.players.has(1) and game.players.size() == 8, "All eight slots can be bots; server consumes no slot")
	game.set_physics_process(false)
	server.set_physics_process(false)
	for fighter: Fighter in game.players.values():
		fighter.set_physics_process(false)
	var player: Fighter = game.players[-1]
	player.kills = 5
	player.deaths = 2
	player.hp = 0
	player.killer_id = -2
	game.scores = [9, 4]
	game.time_left = 0
	game.finish_match()
	server._physics_process(0.1)
	check(game.match_over and server.round_number == 1, "Round end preserves scoreboard during intermission")
	server._physics_process(3.1)
	check(not game.match_over and game.scores == [0, 0] and game.time_left == game.config.time_limit and server.round_number == 2, "Dedicated runtime automatically starts next round")
	check(player.hp == 100 and player.kills == 0 and player.deaths == 0 and player.killer_id == 0, "New round resets fighters, scores and death-camera identity")
	game.config.mode = "FFA"
	game.finish_match()
	check(game.match_over and not game.winner.is_empty(), "FFA can finish and restart as dedicated match")
	game.remove_player(-1)
	game.add_player(123, "Remote", false, 0).set_physics_process(false)
	game._disconnected(123)
	check(game.players.size() == 8 and not game.players.has(123), "Disconnected client slot is refilled by a bot")
	game.leave()
	await process_frame
	print("DEDICATED ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
