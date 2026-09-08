extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	create_timer(20).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(2).timeout
	await capture("res://docs/menu.png")
	game.ui.host_menu()
	await create_timer(0.2).timeout
	await capture("res://docs/host.png")
	game.port = 27992
	game.host(game.config)
	await create_timer(2).timeout
	var p: Fighter = game.players[1]
	p.reset_at(Vector3(0.3, 0.1, 28))
	p.protection = 60
	p.yaw = 0.15
	await create_timer(1).timeout
	await capture("res://docs/gameplay.png")
	print("VISUAL fps=", Engine.get_frames_per_second(), " renderer=", RenderingServer.get_video_adapter_name())
	game.leave()
	await process_frame
	quit()
