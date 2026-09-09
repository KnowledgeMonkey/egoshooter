extends SceneTree
var game: Node3D
var server := false
var id := ""
var switched := false
var saw_first := false
var saw_final := false
var elapsed := 0.0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	server = "--server" in OS.get_cmdline_user_args()
	WeaponStickers.directory = "user://class-network-server/" if server else "user://class-network-client/"
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game); game.port = 27986
	if server:
		game.host({"server_name": "Classes LAN", "mode": "TDM", "max_players": 2, "bots": 0, "score_limit": 50, "time_limit": 600})
	else:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8); img.fill(Color(0.2, 0.6, randf(), 1)); img.save_png("user://network-sticker-input.png")
		id = WeaponStickers.import_file("user://network-sticker-input.png")
		game.loadout = 0; WeaponSkins.set_design(0, {"attachments": {"magazine": 1}, "stickers": [id]})
		game.join("127.0.0.1:27986")
func _process(dt: float) -> bool:
	elapsed += dt
	if game == null: return false
	for p: Fighter in game.players.values():
		if p.peer_id == 1: continue
		if p.primary == 0 and p.magazines[0] == 42:
			var ids := WeaponStickers.clean(p.skin_designs.get("0", {}).get("stickers", []))
			saw_first = saw_first or (WeaponStickers.texture(ids[0]) != null)
		if not server and saw_first and not switched:
			switched = true; game.loadout = 6
			WeaponSkins.set_design(6, {"attachments": {"magazine": 1}, "stickers": [id]}); game.queue_local_class()
		if server and not p.pending_class.is_empty(): game.respawn(p)
		if p.primary == 6 and p.magazines[6] == 84:
			saw_final = true
	if elapsed > 10:
		print("CLASSES LAN ", "SERVER" if server else "CLIENT", " initial=", saw_first, " switched=", saw_final)
		game.leave(""); quit(0 if saw_first and saw_final else 1)
	return false
