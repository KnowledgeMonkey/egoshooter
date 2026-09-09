class_name ClassEditor
extends PanelContainer

var ui: GameUI
var slot := 0
var weapon := 0
var secondary := false
var draft: Dictionary
var showcase: WeaponShowcase
var options_panel: VBoxContainer
var list_panel: VBoxContainer
var title_label: Label
var stats_label: Label
var notice: Label
var class_name_edit: LineEdit
var tabs: OptionButton
var selected_sticker := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b1118")
	style.content_margin_left = 28; style.content_margin_right = 28
	style.content_margin_top = 20; style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)
	var theme_copy := ui.root.theme.duplicate() as Theme
	theme_copy.default_font_size = 17
	for state in ["normal", "hover", "pressed", "focus"]:
		var b := StyleBoxFlat.new()
		b.bg_color = Color("192630") if state == "normal" else Color("345047")
		b.border_width_bottom = 2; b.border_color = Color("be9c59") if state != "normal" else Color("3a474c")
		b.content_margin_left = 12; b.content_margin_right = 12
		b.content_margin_top = 9; b.content_margin_bottom = 9
		theme_copy.set_stylebox(state, "Button", b)
		theme_copy.set_stylebox(state, "OptionButton", b)
	theme = theme_copy
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 14); add_child(column)
	var heading := Label.new(); heading.text = "ARSENAL  /  KLASSENEDITOR"; heading.add_theme_font_size_override("font_size", 32); heading.modulate = Color("e8ca89"); column.add_child(heading)
	var row := HBoxContainer.new(); row.size_flags_vertical = Control.SIZE_EXPAND_FILL; row.add_theme_constant_override("separation", 22); column.add_child(row)
	var left := VBoxContainer.new(); left.custom_minimum_size.x = 225; row.add_child(left)
	add_label(left, "01 / EIGENE KLASSEN")
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; left.add_child(scroll)
	list_panel = VBoxContainer.new(); list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(list_panel)
	add_label(left, "VORLAGE IN DIESEN SLOT KOPIEREN")
	var preset := OptionButton.new()
	for name in ClassLoadouts.PRESETS: preset.add_item(name)
	left.add_child(preset)
	add_button(left, "VORLAGE ÜBERNEHMEN", func(): draft = ClassLoadouts.template(preset.selected).duplicate(true); refresh())
	add_button(left, "KLASSE DUPLIZIEREN", duplicate_class)
	var center := VBoxContainer.new(); center.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(center)
	title_label = add_label(center, ""); title_label.add_theme_font_size_override("font_size", 26)
	class_name_edit = LineEdit.new(); class_name_edit.max_length = 24; center.add_child(class_name_edit)
	class_name_edit.text_changed.connect(func(value): draft.name = value)
	var switch_row := HBoxContainer.new(); center.add_child(switch_row)
	add_button(switch_row, "PRIMÄRWAFFE", func(): secondary = false; refresh())
	add_button(switch_row, "P12 / SEKUNDÄR", func(): secondary = true; refresh())
	showcase = WeaponShowcase.new(); center.add_child(showcase)
	showcase.position = Vector2.ZERO
	showcase.custom_minimum_size = Vector2(300, 240)
	showcase.size_flags_vertical = Control.SIZE_EXPAND_FILL
	showcase.stretch = true
	add_label(center, "MAUS ZIEHEN: DREHEN  •  MAUSRAD: ZOOM")
	stats_label = add_label(center, ""); stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_label(center, "AUSRÜSTUNG   2 × FRAG  /  1 × FLASH  /  ENERGIESCHILD")
	var right := VBoxContainer.new(); right.custom_minimum_size.x = 340; row.add_child(right)
	tabs = OptionButton.new()
	for name in ["02 / WAFFE & AUFSÄTZE", "03 / LACKIERUNG", "04 / BILDSTICKER"]: tabs.add_item(name)
	right.add_child(tabs); tabs.item_selected.connect(func(_i): rebuild_options())
	var option_scroll := ScrollContainer.new(); option_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; right.add_child(option_scroll)
	options_panel = VBoxContainer.new(); options_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; options_panel.add_theme_constant_override("separation", 10); option_scroll.add_child(options_panel)
	notice = add_label(column, "Änderungen gelten für den nächsten Spawn. Klassen bleiben lokal gespeichert.")
	notice.modulate = Color("e8ca89")
	var footer := HBoxContainer.new(); footer.add_theme_constant_override("separation", 16); column.add_child(footer)
	add_button(footer, "SPEICHERN & AUSRÜSTEN", save_class)
	add_button(footer, "← ZURÜCK", ui.main_menu)
	var player := LineEdit.new(); player.text = ui.game.nickname; player.max_length = 20; player.custom_minimum_size.x = 190; player.placeholder_text = "Operatorname"; footer.add_child(player)
	player.text_changed.connect(func(value): ui.game.nickname = value.strip_edges())
	slot = ClassLoadouts.selected
	draft = ClassLoadouts.entries[slot].duplicate(true)
	refresh()

func add_label(parent: Node, value: String) -> Label:
	var label := Label.new(); label.text = value; label.add_theme_font_size_override("font_size", 16); parent.add_child(label); return label

func add_button(parent: Node, value: String, callback: Callable) -> Button:
	var button := Button.new(); button.text = value; button.pressed.connect(callback); parent.add_child(button); return button

func clear_children(parent: Node) -> void:
	for child in parent.get_children(): parent.remove_child(child); child.queue_free()

func refresh() -> void:
	weapon = 4 if secondary else int(draft.primary)
	class_name_edit.text = draft.name
	title_label.text = Arsenal.DATA[weapon].name
	clear_children(list_panel)
	for i in ClassLoadouts.entries.size():
		var label := "%02d  %s" % [i + 1, ClassLoadouts.entries[i].name]
		if i == ClassLoadouts.selected: label = "● " + label
		var button := add_button(list_panel, label, func():
			ClassLoadouts.entries[slot] = ClassLoadouts.clean(draft)
			slot = i; draft = ClassLoadouts.entries[i].duplicate(true); refresh())
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size.x = 220
		button.modulate = Color("e8ca89") if i == slot else Color.WHITE
	showcase.select_weapon(weapon)
	showcase.camera.size = 0.48 if weapon == 4 else (0.95 if weapon in [3, 5, 6] else 0.75)
	update_model()
	rebuild_options()

func design() -> Dictionary:
	var key := str(weapon)
	if not draft.skins.has(key): draft.skins[key] = WeaponSkins.clean({})
	return draft.skins[key]

func update_model() -> void:
	WeaponSkins.apply(showcase.model, design())
	var w := WeaponAttachments.stats(weapon, design())
	stats_label.text = "SCHADEN  %s   •   MAGAZIN  %d   •   REICHWEITE  %.0f m\nNACHLADEN  %.2f s   •   ZIELZEIT  %.2f s   •   TEMPO  %.0f %%" % [str(w.damage), w.mag, w.range, w.reload, w.ads, w.speed * 100]

func rebuild_options() -> void:
	clear_children(options_panel)
	var d := design()
	if tabs.selected == 0:
		add_label(options_panel, "WAFFENAUSWAHL")
		var select := OptionButton.new()
		var ids: Array = [4] if secondary else Arsenal.PRIMARY_IDS
		for id in ids: select.add_item(Arsenal.DATA[id].name)
		select.selected = ids.find(weapon); options_panel.add_child(select)
		select.item_selected.connect(func(i): draft.primary = ids[i]; refresh())
		if not d.has("attachments"): d.attachments = {}
		for i in WeaponAttachments.SLOTS.size():
			var key: String = WeaponAttachments.SLOTS[i]
			add_label(options_panel, WeaponAttachments.LABELS[i].to_upper())
			var choice := OptionButton.new()
			for name in WeaponAttachments.OPTIONS[key]: choice.add_item(name)
			choice.selected = d.attachments.get(key, 0); options_panel.add_child(choice)
			if weapon == 4 and key == "stock": choice.selected = 0; choice.disabled = true
			var hint := add_label(options_panel, WeaponAttachments.HELP[key][choice.selected]); hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; hint.custom_minimum_size.x = 310; hint.modulate = Color("97b6af")
			if weapon == 4 and key == "stock": hint.text = "P12 besitzt keinen austauschbaren Schaft."
			choice.item_selected.connect(func(value): d.attachments[key] = value; hint.text = WeaponAttachments.HELP[key][value]; update_model())
	elif tabs.selected == 1:
		for i in WeaponSkins.PARTS.size():
			var key: String = WeaponSkins.PARTS[i]
			var row := HBoxContainer.new(); options_panel.add_child(row)
			var label := add_label(row, WeaponSkins.LABELS[i]); label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var picker := ColorPickerButton.new(); picker.custom_minimum_size = Vector2(96, 28); picker.edit_alpha = false; picker.color = d.get(key, Color("586267")); row.add_child(picker)
			picker.color_changed.connect(func(value): d[key] = value; update_model())
		add_label(options_panel, "BESCHRIFTUNG")
		var words := LineEdit.new(); words.max_length = 32; words.text = d.get("text", ""); options_panel.add_child(words)
		words.text_changed.connect(func(value): d.text = value; update_model())
		add_label(options_panel, "TEXTFARBE")
		var text_color := ColorPickerButton.new()
		text_color.custom_minimum_size.y = 28
		text_color.edit_alpha = false
		text_color.color = d.get("text_color", Color.WHITE)
		options_panel.add_child(text_color)
		text_color.color_changed.connect(func(value): d.text_color = value; update_model())
		add_button(options_panel, "LACKIERUNG ZURÜCKSETZEN", func():
			for key in WeaponSkins.PARTS + ["text", "text_color"]: d.erase(key)
			update_model(); rebuild_options())
	else:
		add_label(options_panel, "3 STICKERPLÄTZE / BEIDE WAFFENSEITEN")
		var positions := OptionButton.new()
		for name in ["Gehäuse hinten", "Gehäuse Mitte", "Gehäuse vorne"]: positions.add_item(name)
		positions.selected = selected_sticker; options_panel.add_child(positions)
		positions.item_selected.connect(func(i): selected_sticker = i; rebuild_options())
		d.stickers = WeaponStickers.clean(d.get("stickers", []))
		var preview := TextureRect.new(); preview.custom_minimum_size = Vector2(256, 180); preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; preview.texture = WeaponStickers.texture(d.stickers[selected_sticker]); options_panel.add_child(preview)
		add_button(options_panel, "BILD IMPORTIEREN …", import_sticker)
		add_button(options_panel, "STICKER ENTFERNEN", func(): d.stickers[selected_sticker] = ""; update_model(); rebuild_options())
		var hint := add_label(options_panel, "PNG / JPG / WebP · maximal 8 MB\nTransparente PNGs empfohlen.\nImport wird auf 256 Pixel verkleinert."); hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_label(options_panel, "GESPEICHERTE STICKER")
		var gallery := GridContainer.new(); gallery.columns = 4; options_panel.add_child(gallery)
		var folder := DirAccess.open(WeaponStickers.directory)
		if folder:
			for file in folder.get_files():
				var id := file.get_basename()
				if not WeaponStickers.valid(id) or gallery.get_child_count() >= 32: continue
				var tile := TextureButton.new()
				tile.texture_normal = WeaponStickers.texture(id)
				tile.ignore_texture_size = true
				tile.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				tile.custom_minimum_size = Vector2(68, 68)
				tile.tooltip_text = "Sticker auf ausgewählten Platz setzen"
				gallery.add_child(tile)
				tile.pressed.connect(func(): d.stickers[selected_sticker] = id; update_model(); rebuild_options())

func import_sticker() -> void:
	var dialog := FileDialog.new(); dialog.access = FileDialog.ACCESS_FILESYSTEM; dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Bilder"])
	add_child(dialog); dialog.popup_centered_ratio(0.75)
	dialog.file_selected.connect(func(path):
		var id := WeaponStickers.import_file(path)
		if id.is_empty(): notice.text = WeaponStickers.error
		else: design().stickers[selected_sticker] = id; update_model(); rebuild_options(); notice.text = "Sticker importiert. Zum Behalten Klasse speichern."
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)

func save_class() -> void:
	ClassLoadouts.entries[slot] = ClassLoadouts.clean(draft)
	ClassLoadouts.selected = slot
	if ClassLoadouts.save() != OK: notice.text = "Speichern fehlgeschlagen."; return
	ClassLoadouts.activate(ui.game, slot)
	notice.text = "Klasse gespeichert und ausgerüstet. Wird beim nächsten Spawn verwendet."
	refresh()

func duplicate_class() -> void:
	var next := (slot + 1) % 10
	ClassLoadouts.entries[slot] = ClassLoadouts.clean(draft)
	slot = next; draft = draft.duplicate(true); draft.name = str(draft.name).left(17) + " Kopie"
	notice.text = "Kopie in Slot %d vorbereitet. Speichern bestätigt das Ersetzen." % (slot + 1)
	refresh()
