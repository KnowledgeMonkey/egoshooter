class_name ArenaHUD
extends CanvasLayer

var game: Node3D
var canvas: Control
var font: SystemFont
var feed: Array = []
var hit_time := 0.0
var head_hit := false
const WHITE := Color("e7eee8")
const MINT := Color("a5dec8")
const ORANGE := Color("ef9b72")

func _ready() -> void:
	layer = 5
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Arial"])
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(canvas)
	canvas.draw.connect(render)

func _process(dt: float) -> void:
	hit_time = maxf(0, hit_time - dt)
	canvas.visible = game.active
	canvas.queue_redraw()

func text(pos: Vector2, value: String, size: int = 20, tint: Color = WHITE) -> void:
	canvas.draw_string(font, pos + Vector2(1, 2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.7))
	canvas.draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)

func plate(rect: Rect2, color: Color = Color(0.025, 0.07, 0.1, 0.86)) -> void:
	canvas.draw_rect(rect, color)

func render() -> void:
	if not game.active:
		return
	var p: Fighter = game.players.get(game.local_id)
	plate(Rect2(628, 28, 344, 88))
	text(Vector2(657, 56), "RELAY", 14, MINT)
	text(Vector2(878, 56), "EMBER", 14, ORANGE)
	text(Vector2(660, 97), "%02d" % game.scores[0], 37, MINT)
	text(Vector2(883, 97), "%02d" % game.scores[1], 37, ORANGE)
	text(Vector2(755, 70), "%02d:%02d" % [int(game.time_left) / 60, int(game.time_left) % 60], 25)
	text(Vector2(759, 96), "%s / %s" % [game.config.mode, game.config.score_limit], 13)
	text(Vector2(40, 300), "RELAY DISTRICT", 16, MINT)
	text(Vector2(40, 324), "LOCAL OPERATIONS / 01", 12)
	minimap(p)
	var row := 0
	for notice in feed:
		if notice.until > Time.get_ticks_msec():
			text(Vector2(1060, 152 + row * 27), notice.text, 16)
			row += 1
	text(Vector2(1320, 38), "%s FPS  ·  %s" % [Engine.get_frames_per_second(), "HOST" if game.is_host else "LAN"], 14, MINT)
	if not p:
		text(Vector2(640, 440), "SYNCHRONISIERE …", 30)
		return
	plate(Rect2(40, 778, 255, 84))
	text(Vector2(60, 807), "RELAY" if p.team == 0 else "EMBER", 14, MINT if p.team == 0 else ORANGE)
	text(Vector2(60, 846), "%03d" % ceili(p.hp), 35)
	text(Vector2(139, 844), "HP", 17, MINT)
	canvas.draw_rect(Rect2(176, 826, 95, 5), Color("405057"))
	canvas.draw_rect(Rect2(176, 826, 95 * p.hp / 100, 5), MINT if p.hp > 30 else ORANGE)
	plate(Rect2(1280, 761, 280, 101))
	text(Vector2(1300, 790), Arsenal.DATA[p.weapon].name, 16, MINT)
	text(Vector2(1300, 835), "%02d" % p.magazines[p.weapon], 43)
	text(Vector2(1375, 833), "/ %03d" % p.reserves[p.weapon], 22)
	text(Vector2(1462, 837), "G × %s" % p.grenades, 19, ORANGE)
	text(Vector2(575, 866), "WASD MOVE   /   R RELOAD   /   Q SWITCH   /   G FRAG   /   TAB SCORE", 13)
	text(Vector2(42, 750), "%s ELIM   /   %s DEATHS" % [p.kills, p.deaths], 17)
	if p.hp > 0 and not game.match_over:
		var center := Vector2(800, 450)
		if p.weapon == 3 and p.aiming:
			canvas.draw_circle(center, 970, Color(0.01, 0.015, 0.018, 0.98), false, 1370, true)
			canvas.draw_circle(center, 285, Color("252d30"), false, 8, true)
			canvas.draw_line(center - Vector2(280, 0), center + Vector2(280, 0), Color.BLACK, 1.4)
			canvas.draw_line(center - Vector2(0, 280), center + Vector2(0, 280), Color.BLACK, 1.4)
			for i in range(-4, 5):
				canvas.draw_line(center + Vector2(i * 35, -4), center + Vector2(i * 35, 4), Color.BLACK, 1)
				canvas.draw_line(center + Vector2(-4, i * 35), center + Vector2(4, i * 35), Color.BLACK, 1)
			canvas.draw_circle(center, 2, ORANGE)
		var gap := 4.0 if p.aiming else 9.0 + p.velocity.length() * 0.6
		for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			canvas.draw_line(center + dir * gap, center + dir * (gap + 6), WHITE, 1.5, true)
		if hit_time > 0:
			for dir in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				canvas.draw_line(center + dir * 9, center + dir * 16, ORANGE if head_hit else WHITE, 2, true)
		if p.reload_left > 0:
			text(Vector2(730, 513), "RELOADING %.1f" % p.reload_left, 18, MINT)
		if p.protection > 0:
			text(Vector2(679, 715), "SPAWN PROTECTION  %.1f" % p.protection, 17, MINT)
		if p.hp < 35:
			canvas.draw_rect(Rect2(0, 0, 1600, 900), Color(0.7, 0.08, 0.03, 0.6), false, 13)
	if p.hp <= 0:
		plate(Rect2(520, 310, 560, 245))
		text(Vector2(698, 359), "KILLED BY", 22, ORANGE)
		text(Vector2(600, 410), p.killer, 38)
		text(Vector2(689, 453), p.killer_weapon, 21)
		text(Vector2(654, 510), "RESPAWN IN %.1f" % maxf(0, p.respawn_left), 24, MINT)
	if Input.is_action_pressed("scoreboard") or game.match_over:
		scoreboard()

func minimap(local: Fighter) -> void:
	var origin := Vector2(40, 40)
	plate(Rect2(origin, Vector2(225, 243)))
	var scale_map := Vector2(2.8, 2.1)
	var offset := origin + Vector2(112, 128)
	for bounds: AABB in game.arena.obstacles:
		if bounds.position.y > 2.5:
			continue
		var rect := Rect2(offset + Vector2(bounds.position.x, bounds.position.z) * scale_map, Vector2(bounds.size.x, bounds.size.z) * scale_map)
		canvas.draw_rect(rect, Color("546866"))
	for p: Fighter in game.players.values():
		if p.hp <= 0:
			continue
		if p != local and (not local or game.enemies(local, p)):
			continue
		var point := offset + Vector2(p.global_position.x, p.global_position.z) * scale_map
		canvas.draw_circle(point, 4 if p == local else 3, WHITE if p == local else MINT)
		if p == local:
			if p.global_position.y > 3.2:
				text(origin + Vector2(12, 234), "DACH" if p.global_position.y > 7 else "1. OBERGESCHOSS", 11, MINT)
			canvas.draw_line(point, point + Vector2(-sin(p.yaw), -cos(p.yaw)) * 12, WHITE, 2)
	text(origin + Vector2(12, 18), "N ↑     LEFT / MID / RIGHT", 12)

func scoreboard() -> void:
	plate(Rect2(360, 190, 880, 525), Color(0.025, 0.07, 0.1, 0.96))
	text(Vector2(401, 237), game.winner if game.match_over else "MATCH / RELAY DISTRICT", 31, MINT)
	text(Vector2(402, 281), "OPERATOR", 16)
	text(Vector2(924, 281), "ELIM      DEATHS", 16)
	var roster: Array = game.players.values()
	roster.sort_custom(func(a, b): return a.kills > b.kills)
	var y := 325
	for p: Fighter in roster:
		text(Vector2(402, y), ("› " if p.peer_id == game.local_id else "  ") + p.nickname, 21, MINT if p.team == 0 else ORANGE)
		text(Vector2(946, y), "%02d          %02d" % [p.kills, p.deaths], 21)
		y += 38
	if game.match_over:
		text(Vector2(402, 691), "MATCH COMPLETE   /   ESC → LEAVE MATCH → PLAY", 16, MINT)
