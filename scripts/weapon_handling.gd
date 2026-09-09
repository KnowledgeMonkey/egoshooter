class_name WeaponHandling
extends RefCounted

# Presentation/handling profiles: seconds, metres and radians; shared by host and client.
const DATA := [
	{"ads": 0.23, "equip": 0.32, "kick": 0.043, "rise": 0.055, "spring": 23.0, "sway": 0.8, "muzzle": -0.66},
	{"ads": 0.16, "equip": 0.24, "kick": 0.027, "rise": 0.036, "spring": 29.0, "sway": 0.6, "muzzle": -0.47},
	{"ads": 0.28, "equip": 0.38, "kick": 0.090, "rise": 0.13, "spring": 18.0, "sway": 1.0, "muzzle": -0.74},
	{"ads": 0.38, "equip": 0.48, "kick": 0.105, "rise": 0.15, "spring": 15.0, "sway": 1.15, "muzzle": -0.88},
	{"ads": 0.13, "equip": 0.20, "kick": 0.045, "rise": 0.11, "spring": 26.0, "sway": 0.55, "muzzle": -0.20},
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
