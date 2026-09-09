class_name ArenaAudio
extends Node

var sounds := {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 721
	for kind in ["shot", "step", "reload", "explosion", "hit", "death", "flash", "melee", "confirm"]:
		sounds[kind] = synthesize(kind)
	for weapon in Arsenal.DATA.size():
		sounds["shot_%s" % weapon] = synthesize("shot", weapon)

func synthesize(kind: String, weapon: int = 0) -> AudioStreamWAV:
	var duration: float = {"melee": 0.18, "confirm": 0.24, "shot": 0.16, "step": 0.08, "reload": 0.3, "explosion": 1.8, "flash": 0.22, "hit": 0.08, "death": 0.25}[kind]
	if kind == "shot": duration = [0.20, 0.13, 0.34, 0.42, 0.15, 0.28, 0.24, 0.26, 0.10, 0.27][weapon]
	var data := PackedByteArray()
	var count := int(duration * 22050)
	data.resize(count * 2)
	var filtered := 0.0
	for i in count:
		var t := float(i) / 22050.0
		var envelope := pow(1.0 - float(i) / count, 2)
		var noise := rng.randf_range(-1, 1)
		filtered = lerpf(filtered, noise, 0.16)
		var value := noise * 0.5 + sin(t * 520) * 0.5
		match kind:
			"shot":
				var bass: float = [105.0, 165.0, 65.0, 52.0, 190.0, 85.0, 72.0, 92.0, 220.0, 62.0][weapon]
				value = noise * exp(-t * 65) * 0.8 + filtered * exp(-t * 12) * 1.8 + sin(TAU * bass * t) * exp(-t * 18) * 0.6
			"melee": value = filtered * 2.0 + sin(t * 210) * 0.3
			"confirm": value = sin(t * (5400 if t < 0.1 else 7200)) * 0.32
			"step": value = filtered * 2 + sin(t * 380) * 0.2
			"reload": value = noise * (0.5 if fmod(t, 0.1) < 0.025 else 0.04)
			"explosion": value = filtered * 2.7 + sin(TAU * (48 * t - 7 * t * t)) * 0.7 + noise * exp(-t * 32) * 0.5
			"flash": value = noise * 0.7 + sin(t * 2500) * 0.25
			"hit": value = sin(t * 6200) * 0.4
			"death": value = sin(t * (900 - t * 1800)) * 0.4
		data.encode_s16(i * 2, int(clampf(value * envelope * 0.7, -1, 1) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.data = data
	return wav

func play_at(kind: String, pos: Vector3, local: bool = false, variant: int = 0) -> void:
	if DisplayServer.get_name() == "headless" or not sounds.has(kind):
		return
	var sound_key := "shot_%s" % clampi(variant, 0, Arsenal.DATA.size() - 1) if kind == "shot" else kind
	if local:
		var player := AudioStreamPlayer.new()
		player.stream = sounds[sound_key]
		player.volume_db = -14 if kind == "step" else -8
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
	else:
		var player := AudioStreamPlayer3D.new()
		player.stream = sounds[sound_key]
		player.unit_size = 18 if kind == "explosion" else (9 if kind == "shot" else 4)
		player.max_distance = 75 if kind != "step" else 22
		player.volume_db = -8
		player.pitch_scale = 1.0
		add_child(player)
		player.global_position = pos
		player.finished.connect(player.queue_free)
		player.play()
