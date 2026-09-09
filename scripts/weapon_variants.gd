class_name WeaponVariants
extends RefCounted

const G = preload("res://scripts/weapon_geometry.gd")

static func decorate(index: int, frame: Node3D, magazine: Node3D) -> void:
	match index:
		5: # Long precision barrel, cheek rest and folded bipod.
			G.tube(frame, Vector3(0, 0.012, -0.72), 0.018, 0.26, "steel")
			G.block(frame, Vector3(0, 0.016, 0.21), Vector3(0.09, 0.07, 0.13), "rubber")
			for side in [-1, 1]: G.block(frame, Vector3(side * 0.047, -0.052, -0.36), Vector3(0.014, 0.016, 0.20), "edge")
		6: # Box-fed LMG with barrel shroud and carry handle.
			G.block(magazine, Vector3(0, -0.13, -0.14), Vector3(0.17, 0.17, 0.16), "polymer")
			G.tube(frame, Vector3(0, 0.01, -0.68), 0.031, 0.28, "black")
			G.block(frame, Vector3(0.07, 0.14, -0.25), Vector3(0.016, 0.018, 0.15), "rubber")
			for z in [-0.31, -0.19]: G.block(frame, Vector3(0.07, 0.09, z), Vector3(0.014, 0.10, 0.014), "steel")
		7: # Heavy receiver, reinforced handguard and foregrip.
			G.block(frame, Vector3(0, 0, -0.10), Vector3(0.092, 0.07, 0.20), "black")
			G.block(frame, Vector3(0, -0.11, -0.34), Vector3(0.035, 0.16, 0.045), "rubber")
			for side in [-1, 1]: G.block(frame, Vector3(side * 0.051, 0, -0.36), Vector3(0.02, 0.055, 0.16), "steel")
		8: # Compact high-rate SMG with extended magazine and wire stock.
			G.block(magazine, Vector3(0, -0.23, -0.03), Vector3(0.039, 0.12, 0.055), "black")
			for side in [-1, 1]: G.block(frame, Vector3(side * 0.04, 0, 0.16), Vector3(0.01, 0.014, 0.24), "steel")
			G.block(frame, Vector3(0, 0, 0.28), Vector3(0.10, 0.09, 0.015), "rubber")
		9: # Automatic shotgun with a broad drum and heat shield.
			G.tube(magazine, Vector3(0, -0.15, -0.1), 0.10, 0.10, "black", Vector3(0, 0, PI / 2))
			G.block(frame, Vector3(0, 0.043, -0.4), Vector3(0.08, 0.024, 0.28), "steel")
			for z in [-0.5, -0.45, -0.4, -0.35]: G.block(frame, Vector3(0, 0.058, z), Vector3(0.045, 0.006, 0.012), "black")
