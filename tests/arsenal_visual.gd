extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + file + ".png")

func run() -> void:
	create_timer(50).timeout.connect(func(): quit(1))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(1).timeout
	await capture("account-placeholder")
	var saved := WeaponSkins.designs.duplicate(true)
	var saved_loadout: int = game.loadout
	WeaponSkins.set_design(6, {"receiver": Color("279697"), "stock": Color("c4cbd0"), "handguard": Color("c4cbd0"), "magazine": Color("e3a95b"), "text": "RELAY 01", "text_color": Color.WHITE})
	game.ui.skin_menu(6)
	await capture("weapon-skin-editor")
	for index in [5, 6, 7, 8, 9]:
		game.loadout = index
		game.ui.loadout_menu()
		await capture("arsenal-weapon-%s" % index)
	game.port = 27999
	var settings: Dictionary = game.config.duplicate()
	settings.bots = 0
	WeaponSkins.designs = saved.duplicate(true)
	game.loadout = saved_loadout
	game.host(settings)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p: Fighter = game.players[1]
	p.set_physics_process(false)
	p.reset_at(Vector3(0.2, 0.1, 24))
	p.weapon = 6
	EnergyShield.activate(p)
	await capture("energy-shield-first-person")
	var b: Fighter = game.add_player(-1, "Shield", true, 0)
	b.set_physics_process(false)
	b.reset_at(Vector3(0.2, 0.1, 18))
	b.yaw = PI
	EnergyShield.activate(b)
	p.shield_left = 0
	await capture("energy-shield-front")
	b.shield_left = 0
	game.muzzle_trace(1, ShotOrigin.muzzle(p), b.eye())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/muzzle-trace.png")
	WeaponSkins.designs = saved
	WeaponSkins.revision += 1
	game.leave()
	game.queue_free()
	await process_frame
	print("ARSENAL VISUAL PASS")
	quit()
