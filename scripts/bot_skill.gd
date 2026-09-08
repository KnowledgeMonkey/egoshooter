class_name BotSkill
extends RefCounted

const NAMES = ["Rekrut · Leicht", "Soldat · Normal", "Veteran · Schwer", "Elite · Sehr schwer"]
const PROFILES = [
	{"reaction": 0.85, "tracking": 2.6, "error": 0.062, "range": 26.0, "burst": 0.32, "pause": 0.9},
	{"reaction": 0.45, "tracking": 4.4, "error": 0.032, "range": 35.0, "burst": 0.6, "pause": 0.5},
	{"reaction": 0.25, "tracking": 6.0, "error": 0.016, "range": 42.0, "burst": 0.85, "pause": 0.3},
	{"reaction": 0.15, "tracking": 8.0, "error": 0.008, "range": 50.0, "burst": 1.1, "pause": 0.18},
]

static func profile(level: int) -> Dictionary:
	return PROFILES[clampi(level, 0, 3)]
