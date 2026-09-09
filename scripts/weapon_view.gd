class_name WeaponView
extends Node3D

var model: Node3D
var hands: Node3D
var displayed := -1
var last_ammo := -1
var last_shots := -1
var kick := 0.0
var equip := 0.0
var recoil := Vector2.ZERO
var recoil_velocity := Vector2.ZERO
var sway := Vector2.ZERO
var previous_look := Vector2.ZERO
var look_initialized := false
var walk_clock := 0.0
var muzzle: MeshInstance3D
var muzzle_left := 0.0
var shot_age := 10.0
var previous_life := -1
var skin_revision := -1

func select_weapon(index: int) -> void:
	if model:
		remove_child(model)
		model.queue_free()
	model = WeaponModels.build(index)
	add_child(model)
	WeaponSkins.apply(model, WeaponSkins.get_design(index))
	skin_revision = WeaponSkins.revision
	displayed = index
	last_ammo = -1
	last_shots = -1
	equip = float(WeaponHandling.DATA[index].equip)
	recoil = Vector2.ZERO
	recoil_velocity = Vector2.ZERO
	muzzle_left = 0
	shot_age = 10
	look_initialized = false
	muzzle = MeshInstance3D.new()
	var flash := SphereMesh.new()
	flash.radius = 0.025
	flash.height = 0.13
	flash.radial_segments = 8
	flash.rings = 4
	muzzle.mesh = flash
	muzzle.position = WeaponModels.muzzle_position(index) + Vector3(0, 0, -0.035)
	muzzle.rotation.x = PI / 2
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1, 0.77, 0.32)
	glow.emission_enabled = true
	glow.emission = Color(1, 0.52, 0.12)
	glow.emission_energy_multiplier = 3
	muzzle.material_override = glow
	muzzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle.visible = false
	model.add_child(muzzle)
	if hands:
		remove_child(hands)
		hands.queue_free()
	hands = Node3D.new()
	add_child(hands)
	build_hands(index)
	WeaponGeometry.batch(hands)

func sleeve(elbow: Vector3, wrist: Vector3) -> void:
	var g = OperatorModel
	var axis := (wrist - elbow).normalized()
	# Tapered forearms connect to the hand at the wrist; the sleeve overlaps the
	# glove cuff so that aiming and recoil cannot reveal disconnected pipe ends.
	g.limb(hands, elbow, wrist, 0.068, 0.038, "fabric")
	for amount in [0.44, 0.63, 0.81]:
		var fold := g.oval(hands, elbow.lerp(wrist, amount), Vector3(0.112 - amount * 0.031, 0.026, 0.099 - amount * 0.026), "fabric_dark")
		fold.quaternion = Quaternion(Vector3.UP, axis)
	var cuff := g.oval(hands, wrist - axis * 0.012, Vector3(0.086, 0.051, 0.078), "fabric_dark")
	cuff.quaternion = Quaternion(Vector3.UP, axis)
	g.limb(hands, wrist - axis * 0.024, wrist + axis * 0.029, 0.038, 0.034, "leather")
	var strap := g.oval(hands, wrist + axis * 0.006, Vector3(0.083, 0.018, 0.074), "rubber")
	strap.quaternion = Quaternion(Vector3.UP, axis)

func finger(start: Vector3, joint: Vector3, end: Vector3, radius := 0.009) -> void:
	OperatorModel.limb(hands, start, joint, radius, radius * 0.96, "leather")
	OperatorModel.oval(hands, joint, Vector3.ONE * radius * 2.08, "rubber")
	OperatorModel.limb(hands, joint, end, radius * 0.95, radius * 0.74, "leather")
	OperatorModel.oval(hands, end, Vector3.ONE * radius * 1.48, "leather")

func build_hands(index: int) -> void:
	var g = OperatorModel
	var right_wrist := Vector3(0.054, -0.17, 0.114)
	sleeve(Vector3(0.185, -0.34, 0.435), right_wrist)
	var palm := g.oval(hands, Vector3(0.028, -0.12, 0.069), Vector3(0.079, 0.097, 0.064), "leather")
	palm.rotation.x = 0.32
	palm.rotation.z = -0.17
	g.oval(hands, Vector3(0.053, -0.123, 0.082), Vector3(0.031, 0.064, 0.048), "rubber")
	for i in 3:
		var y := -0.116 - i * 0.017
		finger(Vector3(0.049, y, 0.066), Vector3(0.041, y + 0.005, 0.033), Vector3(-0.016, y + 0.002, 0.036), 0.009)
	# The index finger reaches the trigger; thumb wraps the rear of the grip.
	finger(Vector3(0.05, -0.088, 0.062), Vector3(0.044, -0.066, -0.004), Vector3(0.005, -0.069, -0.019), 0.0085)
	finger(Vector3(-0.001, -0.122, 0.087), Vector3(-0.024, -0.085, 0.072), Vector3(-0.012, -0.069, 0.026), 0.012)
	for i in 3:
		g.panel(hands, Vector3(0.06, -0.104 - i * 0.019, 0.072), Vector3(0.008, 0.006, 0.031), "webbing", Vector3(0.18, 0, -0.1))
	# Pistols use a two-hand wrap; long guns have a separate fore-end support.
	if index == 4:
		var wrist := Vector3(-0.056, -0.171, 0.105)
		sleeve(Vector3(-0.215, -0.345, 0.415), wrist)
		g.oval(hands, Vector3(-0.035, -0.127, 0.056), Vector3(0.056, 0.097, 0.089), "leather")
		for i in 4:
			var y := -0.091 - i * 0.018
			finger(Vector3(-0.051, y, 0.041), Vector3(-0.044, y, 0.009), Vector3(0.026, y, 0.007), 0.0083)
		finger(Vector3(-0.047, -0.102, 0.074), Vector3(-0.037, -0.066, 0.044), Vector3(-0.031, -0.053, -0.008), 0.011)
	else:
		var support_z := -0.22 if Arsenal.FAMILIES[index] == 1 else -0.31
		var wrist := Vector3(-0.072, -0.093, support_z + 0.065)
		sleeve(Vector3(-0.246, -0.308, 0.203), wrist)
		var support := g.oval(hands, Vector3(-0.047, -0.061, support_z), Vector3(0.061, 0.058, 0.103), "leather")
		support.rotation.z = -0.27
		g.oval(hands, Vector3(-0.072, -0.059, support_z), Vector3(0.024, 0.04, 0.081), "rubber")
		for i in 4:
			var z := support_z - 0.029 + i * 0.019
			finger(Vector3(-0.053, -0.053, z), Vector3(-0.049, -0.016, z), Vector3(-0.014, -0.01, z), 0.0085)
		finger(Vector3(-0.044, -0.049, support_z + 0.05), Vector3(-0.007, -0.041, support_z + 0.057), Vector3(0.028, -0.025, support_z + 0.041), 0.011)

func animate(p: Fighter, dt: float) -> void:
	if displayed != p.weapon or previous_life != p.life:
		select_weapon(p.weapon)
		previous_life = p.life
		WeaponSkins.apply(model, p.skin_designs.get(str(p.weapon), {}))
	if skin_revision != WeaponSkins.revision:
		WeaponSkins.apply(model, p.skin_designs.get(str(p.weapon), {}))
		skin_revision = WeaponSkins.revision
	var profile: Dictionary = WeaponHandling.DATA[p.weapon]
	var ammo: int = p.magazines[p.weapon]
	var ads := WeaponHandling.smooth(p.aim_blend)
	shot_age += dt
	if last_ammo >= 0 and (ammo < last_ammo or (last_shots >= 0 and p.shot_serial > last_shots)):
		var count := mini(maxi(last_ammo - ammo, p.shot_serial - last_shots), 3)
		recoil_velocity += Vector2(profile.kick, profile.rise) * float(profile.spring) * 2.1 * count * lerpf(1, 0.65, ads)
		kick = 1
		muzzle_left = 0.04
		shot_age = 0
	last_ammo = ammo
	last_shots = p.shot_serial
	var spring := WeaponHandling.settle(recoil, recoil_velocity, profile.spring, dt)
	recoil = spring[0]
	recoil_velocity = spring[1]
	kick = move_toward(kick, 0, dt * 12)
	equip = move_toward(equip, 0, dt)
	muzzle_left = maxf(0, muzzle_left - dt)
	muzzle.visible = muzzle_left > 0
	var look := Vector2(p.yaw, p.pitch)
	var turn := Vector2(wrapf(look.x - previous_look.x, -PI, PI), look.y - previous_look.y) if look_initialized else Vector2.ZERO
	previous_look = look
	look_initialized = true
	var sway_target := (turn / maxf(dt, 0.001) * 0.012).limit_length(0.045) * float(profile.sway) * (1 - ads)
	sway = sway.lerp(sway_target, 1 - exp(-dt * 12))
	var speed := Vector2(p.velocity.x, p.velocity.z).length()
	walk_clock += dt * minf(speed, 9) * 1.8
	var bob := Vector3(sin(walk_clock) * 0.007, absf(cos(walk_clock)) * 0.009, 0) * minf(speed / 5.8, 1.4) * (1 - ads)
	var sprinting := speed > 6.5 and not p.aiming and p.slide_left <= 0
	var sprint_pose := Vector3(-0.13, 0.12, -0.19) if sprinting else Vector3.ZERO
	rotation = rotation.lerp(sprint_pose + Vector3(-sway.y, -sway.x, -sway.x * 0.5), 1 - exp(-dt * 12))
	var progress := 1 - p.reload_left / float(p.weapon_stats().reload) if p.reload_left > 0 else 0.0
	var reload_curve := WeaponHandling.reload_pose(progress)
	var equip_curve := WeaponHandling.smooth(equip / float(profile.equip))
	model.rotation = Vector3(recoil.y - reload_curve * 0.13, reload_curve * 0.12, reload_curve * 0.36 + equip_curve * 0.16)
	model.position = bob + Vector3(0, -equip_curve * 0.20, recoil.x)
	var magazine := model.get_node("Magazine") as Node3D
	var removed := WeaponHandling.smooth((progress - 0.12) / 0.16) * (1 - WeaponHandling.smooth((progress - 0.50) / 0.18))
	magazine.position = Vector3(-0.04 * removed, -removed * (0.06 if Arsenal.FAMILIES[p.weapon] == 2 else 0.23), 0)
	magazine.rotation.x = removed * 0.22
	var bolt := model.get_node("Bolt") as Node3D
	var cycle := clampf(shot_age / float(p.weapon_stats().rate), 0, 1)
	var manual_cycle := sin(clampf((cycle - 0.2) / 0.6, 0, 1) * PI) if cycle < 1 and p.weapon in [2, 3] else 0.0
	bolt.position.z = kick * (0.04 if p.weapon == 4 else 0.025) + manual_cycle * 0.07
	bolt.rotation.z = manual_cycle * 0.5 if p.weapon == 3 else 0.0
	if ammo == 0 and p.weapon == 4: bolt.position.z = 0.04
	var strike := sin(clampf((0.65 - p.melee_left) / 0.65, 0, 1) * PI) if p.melee_left > 0 else 0.0
	model.position += Vector3(-0.10, 0.025, -0.24) * strike
	model.rotation += Vector3(-0.12, -0.3, 0.38) * strike
	hands.position = model.position
	hands.rotation = model.rotation
	model.visible = not (p.weapon == 3 and p.aim_blend > 0.92)
	hands.visible = model.visible
