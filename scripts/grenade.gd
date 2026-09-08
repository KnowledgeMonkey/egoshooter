class_name FragGrenade
extends RigidBody3D

var game: Node3D
var owner_id := 0
var fuse := 2.6
var detonated := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	mass = 0.4
	linear_damp = 0.4
	angular_damp = 1.0
	var physics := PhysicsMaterial.new()
	physics.bounce = 0.38
	physics.friction = 0.7
	physics_material_override = physics
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.13
	shape.shape = sphere
	add_child(shape)
	var visual := Node3D.new()
	add_child(visual)
	var body := SphereMesh.new()
	body.radius = 0.105
	body.height = 0.25
	body.radial_segments = 20
	body.rings = 12
	WeaponGeometry.part(visual, body, Vector3.ZERO, "sand")
	WeaponGeometry.tube(visual, Vector3(0, 0.115, 0), 0.044, 0.055, "steel", Vector3.ZERO)
	WeaponGeometry.block(visual, Vector3(0.052, 0.079, 0), Vector3(0.035, 0.14, 0.025), "edge", Vector3(0, 0, -0.35))
	WeaponGeometry.block(visual, Vector3(0.014, 0.15, 0), Vector3(0.083, 0.018, 0.028), "edge")
	var ring := TorusMesh.new()
	ring.inner_radius = 0.02
	ring.outer_radius = 0.025
	ring.rings = 12
	ring.ring_segments = 8
	WeaponGeometry.part(visual, ring, Vector3(-0.05, 0.125, 0), "silver", Vector3(PI / 2, 0, 0))
	for band in [-0.06, 0.0, 0.06]:
		WeaponGeometry.tube(visual, Vector3(0, band, 0), 0.103 if band == 0 else 0.092, 0.007, "black", Vector3.ZERO)
	WeaponGeometry.batch(visual)
	freeze = not game.is_host

func _physics_process(delta: float) -> void:
	if game.is_host and not detonated:
		fuse -= delta
		if fuse <= 0:
			detonated = true
			game.combat.explode(global_position, owner_id)
			game.remove_grenade.rpc(int(name))
