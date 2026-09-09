extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.ui.hide_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var views := [
		["street", Vector3(0.2, 1.7, 27), Vector3(-1, 1.4, 0)],
		["facade", Vector3(5.3, 1.7, 25.5), Vector3(9, 2, 23.5)],
		["paving", Vector3(4, 1.6, 26), Vector3(5, 0, 23)],
		["interior", Vector3(11.9, 1.6, 21), Vector3(9, 1.0, 17)],
	]
	var label := "after"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): label = arg.trim_prefix("--label=").validate_filename()
	for view in views:
		game.menu_camera.global_position = view[1]
		game.menu_camera.look_at(view[2])
		game.menu_camera.fov = 75
		game.menu_camera.make_current()
		await create_timer(1.8).timeout
		await RenderingServer.frame_post_draw
		var path := "res://logs/material-%s-%s.png" % [label, view[0]]
		if root.get_texture().get_image().save_png(path) != OK: quit(1)
		print("MATERIAL VIEW ", path, " fps=", Engine.get_frames_per_second())
	quit(0)
