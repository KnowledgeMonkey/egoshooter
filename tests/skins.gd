extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, title: String) -> void:
	checks += 1
	if ok: print("PASS ", title)
	else:
		failures += 1
		printerr("FAIL ", title)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var saved := WeaponSkins.designs.duplicate(true)
	for index in Arsenal.DATA.size():
		var a := WeaponModels.build(index)
		var b := WeaponModels.build(index)
		root.add_child(a)
		root.add_child(b)
		var stock: MeshInstance3D = a.get_node("Frame/receiver").get_child(0)
		var factory: Material = stock.material_override
		WeaponSkins.apply(a, {"receiver": Color.RED, "magazine": Color.BLUE, "text": "RELAY / 01"})
		check(stock.material_override.albedo_color == Color.RED, "weapon %s receiver accepts custom color" % index)
		check(b.get_node("Frame/receiver").get_child(0).material_override == factory, "weapon %s skin does not mutate another instance or cache" % index)
		var lettering_path := "Bolt/CustomLettering" if index == 4 else "CustomLettering"
		check(a.get_node(lettering_path).get_child(0).text == "RELAY / 01", "weapon %s displays literal custom text" % index)
		WeaponSkins.apply(a, {})
		check(stock.material_override == factory and a.get_node(lettering_path).get_child(0).text == "", "weapon %s reset restores factory appearance" % index)
		a.queue_free()
		b.queue_free()
	WeaponSkins.set_design(6, {"receiver": Color.CYAN, "text": "[b]Literal[/b]", "text_color": Color.YELLOW})
	var transfer := WeaponSkins.clean_loadout({"6": {"text": "LAN", "receiver": Color.CYAN}, "4": {"text": "SIDE"}, "0": {"text": "IGNORE"}}, 6)
	check(transfer.size() == 2 and transfer["6"].text == "LAN" and not transfer.has("0"), "LAN cosmetics limited to equipped primary and pistol")
	var path := "res://tests/skin-settings.cfg"
	check(PlayerSettings.save(game, path) == OK, "skin settings save successfully")
	WeaponSkins.designs.clear()
	PlayerSettings.restore(game, path)
	check(WeaponSkins.get_design(6).receiver == Color.CYAN and WeaponSkins.get_design(6).text == "[b]Literal[/b]", "skin colors and literal text survive settings roundtrip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(WeaponSkins.clean({"text": "a".repeat(80)}).text.length() == 32, "custom text has a bounded length")
	check(not WeaponSkins.clean({"receiver": Color(NAN, 1, 1)}).has("receiver"), "non-finite colors are rejected")
	game.ui.skin_menu(6)
	check(game.ui.fields.skin_weapon.item_count == 10 and game.ui.fields.skin_part.item_count == 9, "editor exposes every weapon and eight parts plus text color")
	game.ui.main_menu()
	check(game.ui.root.get_child_count() > 6, "title screen builds with account placeholder")
	WeaponSkins.designs = saved
	WeaponSkins.revision += 1
	game.queue_free()
	await process_frame
	print("SKINS RESULT ", checks - failures, "/", checks)
	quit(1 if failures else 0)
