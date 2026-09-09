class_name Arsenal
extends RefCounted

# Metres, seconds, rounds. Shared presentation data; damage is evaluated on host.
const DATA = [
	{"name": "AR-4 KESTREL", "short": "AR-4", "damage": 29.0, "rate": 0.105, "mag": 30, "reserve": 120, "reload": 1.8, "spread": 0.022, "recoil": 0.014, "range": 70.0, "pellets": 1, "speed": 1.0},
	{"name": "V9 VECTOR", "short": "V9", "damage": 22.0, "rate": 0.068, "mag": 36, "reserve": 144, "reload": 1.5, "spread": 0.033, "recoil": 0.011, "range": 35.0, "pellets": 1, "speed": 1.08},
	{"name": "SG-8 BREACH", "short": "SG-8", "damage": 19.0, "rate": 0.72, "mag": 8, "reserve": 32, "reload": 2.3, "spread": 0.075, "recoil": 0.055, "range": 24.0, "pellets": 8, "speed": 0.98},
	{"name": "M77 LONGSHOT", "short": "M77", "damage": 130.0, "rate": 1.15, "mag": 5, "reserve": 25, "reload": 2.7, "spread": 0.06, "recoil": 0.07, "range": 85.0, "pellets": 1, "speed": 0.9},
	{"name": "P12 SIDEARM", "short": "P12", "damage": 27.0, "rate": 0.24, "mag": 12, "reserve": 60, "reload": 1.25, "spread": 0.028, "recoil": 0.023, "range": 40.0, "pellets": 1, "speed": 1.08},
	{"name": "D58 SENTINEL", "short": "D58", "damage": 58.0, "rate": 0.38, "mag": 15, "reserve": 75, "reload": 2.0, "spread": 0.018, "recoil": 0.038, "range": 85.0, "pellets": 1, "speed": 0.95, "semi": true},
	{"name": "LM60 BASTION", "short": "LM60", "damage": 34.0, "rate": 0.12, "mag": 60, "reserve": 180, "reload": 3.6, "spread": 0.036, "recoil": 0.020, "range": 75.0, "pellets": 1, "speed": 0.84},
	{"name": "AK42 HAMMER", "short": "AK42", "damage": 42.0, "rate": 0.18, "mag": 20, "reserve": 100, "reload": 2.2, "spread": 0.026, "recoil": 0.032, "range": 65.0, "pellets": 1, "speed": 0.96},
	{"name": "K16 VIPER", "short": "K16", "damage": 16.0, "rate": 0.045, "mag": 45, "reserve": 180, "reload": 1.65, "spread": 0.045, "recoil": 0.009, "range": 28.0, "pellets": 1, "speed": 1.12},
	{"name": "AS12 CYCLONE", "short": "AS12", "damage": 12.0, "rate": 0.32, "mag": 12, "reserve": 48, "reload": 2.8, "spread": 0.09, "recoil": 0.041, "range": 20.0, "pellets": 6, "speed": 0.92},
]

static func direction(yaw: float, pitch: float) -> Vector3:
	return Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))

const PRIMARY_IDS := [0, 1, 2, 3, 5, 6, 7, 8, 9]
const FAMILIES := [0, 1, 2, 3, 4, 0, 0, 0, 1, 2]

static func primary_id(value: int) -> int:
	return value if value in PRIMARY_IDS else 0

static func ammunition(reserve := false) -> Array:
	var result := []
	for weapon: Dictionary in DATA: result.append(weapon.reserve if reserve else weapon.mag)
	return result
