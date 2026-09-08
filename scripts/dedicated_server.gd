class_name DedicatedServer
extends Node

var game: Node3D
var round_number := 1
var round_left := -1.0
var elapsed := 0.0
var status_clock := 0.0
var run_for := 0
var stop_file := ""

func start(args: PackedStringArray) -> void:
	var loaded := ServerSettings.read(args)
	if not loaded.error.is_empty():
		printerr("SERVER CONFIG ERROR: ", loaded.error)
		get_tree().quit(2)
		return
	if not game.headless:
		printerr("SERVER ERROR: Dedicated Server mit --headless starten.")
		get_tree().quit(2)
		return
	run_for = loaded.run_for
	stop_file = loaded.stop_file
	game.port = int(loaded.settings.port)
	if not game.host(loaded.settings, true):
		get_tree().quit(1)
		return
	print("SERVER READY bind=%s port=%s name=%s mode=%s max_players=%s bots=%s" % [
		game.config.bind, game.port, game.config.server_name, game.config.mode, game.config.max_players, game.config.bots])
	print("SERVER ROUND START 1 | Ctrl+C oder 'stop' beendet den Server.")
	print("SERVER CONFIG ", JSON.stringify(game.config))

func _physics_process(dt: float) -> void:
	if not game.active:
		return
	elapsed += dt
	status_clock += dt
	if (run_for > 0 and elapsed >= run_for) or (not stop_file.is_empty() and FileAccess.file_exists(stop_file)):
		print("SERVER STOP | Verbindungen werden geschlossen.")
		game.leave()
		get_tree().quit(0)
		return
	if game.match_over:
		if round_left < 0:
			round_left = float(game.config.round_delay)
			print("SERVER ROUND END %s winner=%s | Naechste Runde in %ss" % [round_number, game.winner, game.config.round_delay])
		round_left -= dt
		if round_left <= 0:
			game.restart_round()
			round_number += 1
			round_left = -1
			print("SERVER ROUND START ", round_number)
	if status_clock >= 10:
		status_clock = 0
		var humans := 0
		for fighter: Fighter in game.players.values():
			if not fighter.bot:
				humans += 1
		print("SERVER STATUS round=%s clients=%s/%s bots=%s time=%s score=%s" % [
			round_number, humans, game.config.max_players, game.players.size() - humans, ceili(game.time_left), game.scores])
