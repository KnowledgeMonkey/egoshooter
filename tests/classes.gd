extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ", label)
	else: failures += 1; printerr("FAIL ", label)
func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	var path := "user://classes-test.cfg"
	ClassLoadouts.restore(0, path)
	check(ClassLoadouts.entries.size() == 10, "ten editable slots")
	ClassLoadouts.entries[2] = ClassLoadouts.template(3)
	ClassLoadouts.selected = 2
	check(ClassLoadouts.save(path) == OK, "classes save")
	ClassLoadouts.entries.clear(); ClassLoadouts.restore(0, path)
	check(ClassLoadouts.selected == 2 and ClassLoadouts.entries[2].primary == 6, "class names selection and weapons persist")
	var config := {"attachments": {"magazine": 1, "muzzle": 1, "underbarrel": 1, "stock": 1}}
	var w := WeaponAttachments.stats(0, config)
	check(w.mag == 42 and is_equal_approx(w.reload, 2.16), "extended magazine capacity and reload tradeoff")
	check(w.range < Arsenal.DATA[0].range and w.spread < Arsenal.DATA[0].spread, "attachment range and precision")
	check(Arsenal.DATA[0].mag == 30, "shared factory data remains unchanged")
	check(WeaponAttachments.clean({"muzzle": 500, "stock": NAN}).muzzle == 2 and WeaponAttachments.clean({"stock": NAN}).stock == 0, "invalid attachment values sanitized")
	var img := Image.create(400, 200, false, Image.FORMAT_RGBA8); img.fill(Color(0.1, 0.8, 0.9, 0.8)); img.save_png("user://class-test-sticker.png")
	var id := WeaponStickers.import_file("user://class-test-sticker.png")
	check(WeaponStickers.valid(id), "PNG sticker imported")
	check(WeaponStickers.texture(id).get_width() == 256 and WeaponStickers.texture(id).get_height() == 128, "sticker preserves aspect and caps resolution")
	config.stickers = [id, "", ""]
	var packed := WeaponStickers.bundle({"0": config})
	check(WeaponStickers.accept(packed).has(id), "sticker reliable payload accepted")
	check(WeaponStickers.accept({id: PackedByteArray([1, 2, 3])}).is_empty(), "invalid sticker payload rejected")
	check(WeaponStickers.texture("../../settings") == null, "sticker paths constrained to hashes")
	var model := WeaponModels.build(0); root.add_child(model); WeaponSkins.apply(model, config)
	check(model.get_node("Stickers").get_child_count() == 2, "sticker on both weapon sides")
	check(model.get_node("Attachments").get_child_count() > 0, "attachments modeled")
	WeaponSkins.apply(model, {})
	check(model.get_node("Stickers").get_child_count() == 0 and model.get_node("Magazine").scale.y == 1, "reset removes stickers and extended magazine")
	game.port = 27987; game.loadout = 0; WeaponSkins.set_design(0, config)
	game.host({"server_name": "Classes test", "mode": "TDM", "max_players": 2, "bots": 0, "score_limit": 50, "time_limit": 600})
	var p: Fighter = game.players[1]
	check(p.magazines[0] == 42, "host spawns with attachment ammo capacity")
	game.loadout = 6; WeaponSkins.set_design(6, {"attachments": {"magazine": 1}}); game.queue_local_class()
	check(p.primary == 0 and p.pending_class.primary == 6, "live class change waits for spawn")
	game.respawn(p)
	check(p.primary == 6 and p.weapon == 6 and p.magazines[6] == 84, "spawn applies queued class and ammo")
	var replica := Fighter.new(); replica.setup(game, 222, "replica", 0, false, 0); root.add_child(replica); replica.apply_snapshot(p.snapshot())
	check(replica.primary == 6 and replica.weapon_stats().mag == 84, "snapshot synchronizes changed primary and attachment stats")
	game.ui.loadout_menu()
	var editor := game.ui.root.get_child(0) as ClassEditor
	check(editor != null and editor.showcase.model != null, "class editor builds")
	for i in 3: editor.tabs.selected = i; editor.rebuild_options()
	check(editor.options_panel.get_child_count() > 3, "all editor panels build")
	game.leave("")
	model.queue_free(); replica.queue_free(); game.queue_free()
	DirAccess.remove_absolute(path); DirAccess.remove_absolute("user://class-test-sticker.png")
	await process_frame
	print("CLASSES RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
