class_name ArenaAudio
extends Node

var sounds := {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 721
	for kind in ["shot", "step", "reload", "explosion", "hit", "death"]:
		sounds[kind] = synthesize(kind)

func synthesize(kind: String) -> AudioStreamWAV:
	var duration: float = {"shot": 0.16, "step": 0.08, "reload": 0.3, "explosion": 0.8, "hit": 0.08, "death": 0.25}[kind]
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
			"step": value = filtered * 2 + sin(t * 380) * 0.2
			"reload": value = noise * (0.5 if fmod(t, 0.1) < 0.025 else 0.04)
			"explosion": value = filtered * 2.5 + sin(t * 120) * 0.5
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
	if local:
		var player := AudioStreamPlayer.new()
		player.stream = sounds[kind]
		player.volume_db = -14 if kind == "step" else -8
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
	else:
		var player := AudioStreamPlayer3D.new()
		player.stream = sounds[kind]
		player.unit_size = 9 if kind == "shot" else 4
		player.max_distance = 75 if kind != "step" else 22
		player.volume_db = -8
		player.pitch_scale = 1.0 + variant * 0.06
		add_child(player)
		player.global_position = pos
		player.finished.connect(player.queue_free)
		player.play()
