class_name WeaponHandling
extends RefCounted

# Presentation/handling profiles: seconds, metres and radians; shared by host and client.
const DATA := [
	{"ads": 0.23, "equip": 0.32, "kick": 0.043, "rise": 0.055, "spring": 23.0, "sway": 0.8},
	{"ads": 0.16, "equip": 0.24, "kick": 0.027, "rise": 0.036, "spring": 29.0, "sway": 0.6},
	{"ads": 0.28, "equip": 0.38, "kick": 0.090, "rise": 0.13, "spring": 18.0, "sway": 1.0},
	{"ads": 0.38, "equip": 0.48, "kick": 0.105, "rise": 0.15, "spring": 15.0, "sway": 1.15},
	{"ads": 0.13, "equip": 0.20, "kick": 0.045, "rise": 0.11, "spring": 26.0, "sway": 0.55},
	{"ads": 0.30, "equip": 0.36, "kick": 0.065, "rise": 0.09, "spring": 20.0, "sway": 0.95},
	{"ads": 0.40, "equip": 0.52, "kick": 0.052, "rise": 0.068, "spring": 21.0, "sway": 1.3},
	{"ads": 0.26, "equip": 0.34, "kick": 0.059, "rise": 0.084, "spring": 21.0, "sway": 0.9},
	{"ads": 0.12, "equip": 0.19, "kick": 0.022, "rise": 0.030, "spring": 32.0, "sway": 0.5},
	{"ads": 0.31, "equip": 0.42, "kick": 0.072, "rise": 0.10, "spring": 20.0, "sway": 1.1},
]

static func smooth(value: float) -> float:
	value = clampf(value, 0, 1)
	return value * value * (3 - 2 * value)

static func reload_pose(progress: float) -> float:
	# Remove, hold clear, seat, then return to the sight line.
	return smooth(progress / 0.2) * (1 - smooth((progress - 0.68) / 0.32))

static func settle(value: Vector2, velocity: Vector2, frequency: float, dt: float) -> Array[Vector2]:
	# Exact critically damped solution, stable even after a slow frame.
	var impulse := velocity + value * frequency
	var decay := exp(-frequency * dt)
	return [(value + impulse * dt) * decay, (velocity - impulse * frequency * dt) * decay]
