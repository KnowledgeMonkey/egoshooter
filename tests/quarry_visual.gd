extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game: Node3D = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
 game.ui.hide_menu(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 var views := [
  ["depot", Vector3(0.2, 1.7, 27), Vector3(-1, 2.8, 0)],
  ["quarry", Vector3(40, 1.7, -22), Vector3(33, 4.0, -7)],
  ["rockpass", Vector3(40, 1.7, -3), Vector3(37, 3.5, -22)],
  ["warehouse", Vector3(-11.9, 1.7, -14), Vector3(-8, 1.6, -22)],
  ["cargo", Vector3(-19, 1.7, 18), Vector3(-18, 1.3, 10)],
  ["overview", Vector3(43, 22, 48), Vector3(0, 2, 0)]
 ]
 for view in views:
  game.menu_camera.position = view[1]; game.menu_camera.look_at(view[2]); game.menu_camera.fov = 75; game.menu_camera.make_current()
  await create_timer(1.2).timeout; await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://logs/quarry-%s.png" % view[0])
  print("QUARRY VIEW ", view[0], " fps=", Engine.get_frames_per_second())
 quit()
