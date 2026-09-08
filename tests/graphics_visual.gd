extends SceneTree

var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + file + ".png")

func run() -> void:
	create_timer(100).timeout.connect(func(): quit(1))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(3).timeout
	await capture("graphics-menu")
	game.port = 27996
	game.host({"server_name": "District Visual", "mode": "TDM", "max_players": 8, "bots": 7, "difficulty": 1, "score_limit": 100, "time_limit": 600})
	game.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.set_physics_process(false)
	for fighter: Fighter in game.players.values():
		fighter.set_physics_process(false)
	var p: Fighter = game.players[1]
	var viewpoints := [
		["graphics-center", Vector3(0.2, 0.1, 27), 0.1, 0.015],
		["graphics-left", Vector3(-22, 0.1, 28), -0.06, 0.0],
		["graphics-right", Vector3(21, 0.1, -29), 3.07, 0.0],
		["graphics-interior", Vector3(10.8, 0.1, 21), 0.15, 0.0],
		["graphics-platform", Vector3(-23, 2.4, 0), -1.6, -0.12],
	]
	for view in viewpoints:
		p.reset_at(view[1])
		p.yaw = view[2]
		p.pitch = view[3]
		await create_timer(1.2).timeout
		await capture(view[0])
	game.paused = true
	game.ui.settings_menu()
	await capture("graphics-settings")
	game.ui.hide_menu()
	game.paused = false
	p.reset_at(Vector3(0.2, 0.1, 27))
	p.protection = 120
	for fighter: Fighter in game.players.values():
		fighter.set_physics_process(true)
	game.set_physics_process(true)
	await create_timer(4).timeout
	for quality in [1, 0, 2]:
		GraphicsSettings.apply(game, quality)
		await create_timer(2).timeout
		var samples := []
		for i in 4:
			await create_timer(1).timeout
			samples.append(Engine.get_frames_per_second())
		print("GRAPHICS ", GraphicsSettings.NAMES[quality], " FPS=", samples, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	GraphicsSettings.apply(game, 1)
	print("GRAPHICS VISUAL PASS renderer=", RenderingServer.get_current_rendering_method(), " GPU=", RenderingServer.get_video_adapter_name())
	game.leave()
	await process_frame
	quit()
