class_name Arsenal
extends RefCounted

# Metres, seconds, rounds. Shared presentation data; damage is evaluated on host.
const DATA = [
	{"name": "AR-4 KESTREL", "short": "AR-4", "damage": 29.0, "rate": 0.105, "mag": 30, "reserve": 120, "reload": 1.8, "spread": 0.022, "recoil": 0.014, "range": 70.0, "pellets": 1, "speed": 1.0},
	{"name": "V9 VECTOR", "short": "V9", "damage": 22.0, "rate": 0.068, "mag": 36, "reserve": 144, "reload": 1.5, "spread": 0.033, "recoil": 0.011, "range": 35.0, "pellets": 1, "speed": 1.08},
	{"name": "SG-8 BREACH", "short": "SG-8", "damage": 19.0, "rate": 0.72, "mag": 8, "reserve": 32, "reload": 2.3, "spread": 0.075, "recoil": 0.055, "range": 24.0, "pellets": 8, "speed": 0.98},
	{"name": "M77 LONGSHOT", "short": "M77", "damage": 85.0, "rate": 1.15, "mag": 5, "reserve": 25, "reload": 2.7, "spread": 0.06, "recoil": 0.07, "range": 85.0, "pellets": 1, "speed": 0.9},
	{"name": "P12 SIDEARM", "short": "P12", "damage": 27.0, "rate": 0.24, "mag": 12, "reserve": 60, "reload": 1.25, "spread": 0.028, "recoil": 0.023, "range": 40.0, "pellets": 1, "speed": 1.08},
]

static func direction(yaw: float, pitch: float) -> Vector3:
	return Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
