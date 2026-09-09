extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	ClassLoadouts.entries[0] = ClassLoadouts.template(0)
	ClassLoadouts.entries[0].name = "KESTREL / URBAN"
	ClassLoadouts.entries[0].skins["0"] = {"receiver": Color("247575"), "stock": Color("354b52"), "handguard": Color("a8b1ad"), "attachments": {"optic": 1, "muzzle": 1, "underbarrel": 1, "magazine": 1}, "text": "RELAY"}
	ClassLoadouts.selected = 0
	var icon := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	icon.fill(Color("e2b958"))
	icon.fill_rect(Rect2i(30, 24, 22, 80), Color("182732"))
	icon.fill_rect(Rect2i(52, 24, 45, 18), Color("182732"))
	icon.fill_rect(Rect2i(52, 57, 38, 18), Color("182732"))
	icon.fill_rect(Rect2i(52, 86, 45, 18), Color("182732"))
	icon.save_png("user://classes-preview-sticker.png")
	var sticker := WeaponStickers.import_file("user://classes-preview-sticker.png")
	ClassLoadouts.entries[0].skins["0"].stickers = [sticker]
	game.ui.loadout_menu()
	var editor: ClassEditor = game.ui.root.get_child(0)
	for i in 3:
		editor.tabs.selected = i
		editor.rebuild_options()
		await create_timer(1.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://logs/classes-editor-%d.png" % i)
	quit()
