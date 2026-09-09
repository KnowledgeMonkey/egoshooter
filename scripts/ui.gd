class_name GameUI
extends CanvasLayer

var game: Node3D
var root: Control
var panel: VBoxContainer
var status: Label
var page := ""
var fields := {}
var browser_rows: VBoxContainer
var refresh_clock := 0.0
const INK := Color("101e27")
const PAPER := Color("e6eee9")
const MINT := Color("a5dec8")

func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Arial"])
	theme.default_font = font
	theme.default_font_size = 20
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("233943") if state == "normal" else Color("3c625f")
		style.border_width_bottom = 1
		style.border_color = Color("52776f")
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 14
		style.content_margin_bottom = 14
		theme.set_stylebox(state, "Button", style)
		theme.set_stylebox(state, "OptionButton", style)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_color", "Label", PAPER)
	root.theme = theme
	main_menu()

func clear(title: String, subtitle: String) -> void:
	root.show()
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	fields.clear()
	browser_rows = null
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.07, 0.1, 0.985)
	shade.position = Vector2.ZERO
	shade.size = Vector2(630, 900)
	root.add_child(shade)
	var rail := ColorRect.new()
	rail.color = MINT
	rail.position = Vector2(630, 0)
	rail.size = Vector2(3, 900)
	root.add_child(rail)
	panel = VBoxContainer.new()
	panel.position = Vector2(60, 44)
	panel.size = Vector2(510, 800)
	panel.add_theme_constant_override("separation", 12)
	root.add_child(panel)
	label("B / L     •     LOCAL OPERATIONS", 16, MINT)
	space(12)
	label(title, 57)
	label(subtitle, 17, Color("93aaa9"))
	space(18)
	status = Label.new()
	status.position = Vector2(60, 825)
	status.size = Vector2(515, 60)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", Color("f2c78e"))
	root.add_child(status)
	var caption_bg := ColorRect.new()
	caption_bg.color = Color(0.025, 0.07, 0.1, 0.87)
	caption_bg.position = Vector2(670, 732)
	caption_bg.size = Vector2(760, 135)
	root.add_child(caption_bg)
	var caption := Label.new()
	caption.position = Vector2(695, 744)
	caption.text = "01 / RELAY DISTRICT\nDREI WEGE. EIN AUFTRAG.\n90 × 128 m   /   2–8 OPERATORS   /   LAN"
	if title == "LOADOUT":
		caption.text = "ARMORY / ORIGINAL WEAPON MODELS\nMAUS ZIEHEN: MODELL DREHEN\nMetall / Polymer / Optik / bewegliche Bauteile"
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", PAPER)
	root.add_child(caption)

func label(text: String, size: int = 20, color: Color = PAPER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	panel.add_child(l)
	return l

func space(height: float) -> void:
	var c := Control.new()
	c.custom_minimum_size.y = height
	panel.add_child(c)

func button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 55
	b.pressed.connect(action)
	panel.add_child(b)
	return b

func message(text: String) -> void:
	if is_instance_valid(status):
		status.text = text

func main_menu() -> void:
	page = "main"
	clear("BLOCKLINE", "ARENA SHOOTER  /  RELAY DISTRICT")
	label("Kompakte Matches. Direkte Action.", 23)
	space(18)
	button("01    PLAY                         →", func(): game.host(game.config))
	button("02    MULTIPLAYER          →", multiplayer_menu)
	button("03    LOADOUT                  →", loadout_menu)
	button("04    SETTINGS                   →", settings_menu)
	button("05    QUIT", func(): get_tree().quit())
	space(26)
	label("PLAY startet lokal mit Bots.\nKein Konto. Kein externer Server.", 17, Color("93aaa9"))

func multiplayer_menu() -> void:
	page = "multiplayer"
	clear("MULTIPLAYER", "LAN / DEDICATED SERVER")
	button("HOST GAME                 →", host_menu)
	button("JOIN GAME                   →", browser_menu)
	button("DIRECT CONNECT       →", direct_menu)
	space(15)
	button("←  BACK", main_menu)

func text_field(key: String, title: String, value: String) -> void:
	label(title, 15, MINT)
	var field := LineEdit.new()
	field.text = value
	field.custom_minimum_size.y = 42
	field.max_length = 40
	panel.add_child(field)
	fields[key] = field

func option(key: String, title: String, items: Array, selected: int = 0) -> void:
	label(title, 15, MINT)
	var field := OptionButton.new()
	for item in items:
		field.add_item(str(item))
	field.select(selected)
	panel.add_child(field)
	fields[key] = field

func host_menu() -> void:
	page = "host"
	clear("HOST GAME", "RELAY DISTRICT  /  UDP %s" % game.port)
	panel.add_theme_constant_override("separation", 4)
	text_field("name", "SERVER NAME", game.config.server_name)
	option("mode", "GAME MODE", ["Team Deathmatch", "Free For All", "Domination", "Kill Confirmed"], ["TDM", "FFA", "DOM", "KC"].find(game.config.mode))
	option("slots", "MAXIMUM PLAYERS", [2, 4, 6, 8], 3)
	option("bots", "BOTS · FREIE PLÄTZE AUFFÜLLEN", [0, 1, 3, 5, 7], 4)
	option("difficulty", "BOT-SCHWIERIGKEIT", BotSkill.NAMES, int(game.config.get("difficulty", 0)))
	option("score", "SCORE LIMIT", [25, 50, 75, 100], 1)
	fields.mode.item_selected.connect(func(index): fields.score.select(0 if index == 1 else 1))
	option("time", "TIME LIMIT", ["5 Minuten", "10 Minuten", "15 Minuten"], 1)
	button("START GAME               →", func():
		game.host({"server_name": fields.name.text.left(30), "mode": ["TDM", "FFA", "DOM", "KC"][fields.mode.selected],
			"max_players": [2, 4, 6, 8][fields.slots.selected], "bots": [0, 1, 3, 5, 7][fields.bots.selected],
			"difficulty": fields.difficulty.selected,
			"score_limit": [25, 50, 75, 100][fields.score.selected], "time_limit": [300, 600, 900][fields.time.selected]}))
	button("←  BACK", multiplayer_menu)

func browser_menu() -> void:
	page = "browser"
	clear("JOIN GAME", "AUTOMATISCHE LAN-SUCHE / RELAY DISTRICT")
	browser_rows = VBoxContainer.new()
	browser_rows.custom_minimum_size.y = 260
	panel.add_child(browser_rows)
	refresh_browser()
	button("DIRECT CONNECT       →", direct_menu)
	button("←  BACK", multiplayer_menu)
	message("Server werden jede Sekunde aktualisiert. Discovery nutzt UDP 27841.")

func refresh_browser() -> void:
	for child in browser_rows.get_children():
		browser_rows.remove_child(child)
		child.queue_free()
	if game.discovery.servers.is_empty():
		var empty := Label.new()
		empty.text = "Suche nach lokalen Servern …\n\nNoch kein Host gefunden.\nDirect Connect ist ebenfalls verfügbar."
		empty.add_theme_font_size_override("font_size", 18)
		browser_rows.add_child(empty)
	for address in game.discovery.servers:
		var info: Dictionary = game.discovery.servers[address]
		var b := Button.new()
		var ping := "%s ms" % info.get("ping", -1) if info.get("ping", -1) >= 0 else "Ping …"
		b.text = "%s  ·  %s/%s  ·  %s\n%s / %s      JOIN →" % [str(info.get("name", "Server")).left(22), info.get("players", 0), info.get("max", 8), ping, info.get("mode", "TDM"), address]
		b.custom_minimum_size.y = 85
		b.pressed.connect(func(): game.join(address))
		browser_rows.add_child(b)

func direct_menu() -> void:
	page = "direct"
	clear("CONNECT", "DIREKT ZUM HOST / IPv4")
	text_field("ip", "SERVER-ADRESSE · OPTIONAL :PORT", game.last_address)
	button("CONNECT                     →", func(): game.join(fields.ip.text))
	button("←  BACK", multiplayer_menu)
	space(15)
	label("LAN- oder erreichbare Server-IP eingeben.\nDer Spielport muss per UDP erreichbar sein.\nFür Tests auf diesem PC: 127.0.0.1", 18, Color("93aaa9"))

func loadout_menu() -> void:
	page = "loadout"
	clear("LOADOUT", "EIN AUFTRAG. DEINE AUSRÜSTUNG.")
	text_field("player", "OPERATOR NAME", game.nickname)
	var names := []
	for i in Arsenal.PRIMARY_IDS:
		names.append(Arsenal.DATA[i].name)
	option("primary", "PRIMARY", names, Arsenal.PRIMARY_IDS.find(game.loadout))
	var showcase := WeaponShowcase.new()
	root.add_child(showcase)
	showcase.select_weapon(game.loadout)
	fields.primary.item_selected.connect(func(index): showcase.select_weapon(Arsenal.PRIMARY_IDS[index]))
	button("P12 SIDEARM ANSEHEN   →", func(): showcase.select_weapon(4))
	space(10)
	label("SECONDARY     P12 SIDEARM\nLETHAL             2 × FRAG (G)\nTACTICAL        1 × FLASH (F)", 20)
	label("9 PRIMÄRWAFFEN / P12 SEKUNDÄR\nM77: 1 Treffer / D58: Halbautomatik\nLM60: 60 Schuss / K16: hohe Kadenz\nB: FRONT-ENERGIESCHILD / 45 SEK.", 18, Color("93aaa9"))
	space(10)
	button("SAVE & BACK                →", func():
		game.nickname = fields.player.text.strip_edges().left(20)
		game.loadout = Arsenal.PRIMARY_IDS[fields.primary.selected]
		game.save_preferences()
		main_menu())

func settings_menu() -> void:
	page = "settings"
	clear("SETTINGS", "BEWEGUNG / SICHT / AUDIO")
	option("graphics", "GRAFIKQUALITÄT · F11 VOLLBILD", GraphicsSettings.NAMES, game.graphics_quality)
	fields.graphics.item_selected.connect(func(index): GraphicsSettings.apply(game, index))
	if not game.active or game.is_host:
		option("difficulty", "BOT-SCHWIERIGKEIT · DIREKT AKTIV", BotSkill.NAMES, int(game.config.get("difficulty", 0)))
		fields.difficulty.item_selected.connect(func(index): game.config["difficulty"] = index)
	slider("MAUSEMPFINDLICHKEIT", 0.0005, 0.005, game.sensitivity, func(v): game.sensitivity = v)
	slider("SICHTFELD", 70, 110, game.base_fov, func(v): game.base_fov = v)
	slider("LAUTSTÄRKE", 0, 1, db_to_linear(AudioServer.get_bus_volume_db(0)), func(v): AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, v))))
	space(14)
	label("WASD   Bewegen        SHIFT   Sprinten\nMAUS   Zielen              LMB / RMB   Feuer / ADS\nSPACE   Springen / Hochziehen        CTRL   Ducken / Rutschen\nR   Nachladen               Q   Primär / Pistole\nG   Frag / F   Flash          TAB   Scoreboard\nV   Nahkampf / E   Seilaufzug\nB   Frontschild / ESC   Menü", 18, Color("93aaa9"))
	button("SAVE & BACK", func():
		game.save_preferences()
		if game.active: pause_menu()
		else: main_menu())

func slider(title: String, minimum: float, maximum: float, value: float, callback: Callable) -> void:
	label(title, 15, MINT)
	var control := HSlider.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = (maximum - minimum) / 100
	control.value = value
	control.custom_minimum_size.y = 35
	control.value_changed.connect(callback)
	panel.add_child(control)

func pause_menu() -> void:
	page = "pause"
	clear("OPERATIONS", "MATCH LÄUFT WEITER")
	button("RESUME                         →", func():
		game.paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hide_menu())
	button("SETTINGS                       →", settings_menu)
	button("LEAVE MATCH", func(): game.leave())
	if game.is_host:
		label("Host verlassen beendet das Match für alle.", 16, Color("93aaa9"))
		var addresses := []
		for address in IP.get_local_addresses():
			if address.contains(".") and not address.begins_with("127."):
				addresses.append(address)
		label("HOST IP\n" + "\n".join(addresses), 18, MINT)

func hide_menu() -> void:
	page = ""
	root.hide()

func _process(dt: float) -> void:
	refresh_clock += dt
	if page == "browser" and refresh_clock > 1:
		refresh_clock = 0
		refresh_browser()
