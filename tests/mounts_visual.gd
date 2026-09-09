extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game: Node3D = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
 var config := {"attachments": {"optic": 1, "muzzle": 1, "underbarrel": 1, "magazine": 1, "stock": 1}, "text": "P12"}
 game.ui.loadout_menu()
 var editor: ClassEditor = game.ui.root.get_child(0)
 for index in 10:
  editor.secondary = index == 4
  editor.draft.primary = index if index != 4 else 0
  editor.draft.skins[str(index)] = config.duplicate(true)
  editor.refresh()
  await create_timer(0.3).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://logs/mount-%d.png" % index)
  var mount := editor.showcase.model.get_node("Bolt/SlideAttachments/Reflex" if index == 4 else "Attachments/Reflex") as Node3D
  var lens := mount.get_node("Lens") as MeshInstance3D
  assert(lens.material_override.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
  assert(lens.material_override.albedo_color.a < 0.15)
  assert(editor.showcase.model.get_node("Frame/optic").visible)
  if index == 4:
   editor.showcase.camera.position = Vector3(0, 0.0805, 0.45)
   editor.showcase.camera.look_at(Vector3(0, 0.0805, -1))
   editor.showcase.camera.size = 0.15
   await create_timer(0.3).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://logs/mount-pistol-sight.png")
   editor.showcase.camera.position = Vector3(1.3, 0.5, 0.4)
 print("MOUNTS: 10 weapon models and transparent optics checked")
 quit()
