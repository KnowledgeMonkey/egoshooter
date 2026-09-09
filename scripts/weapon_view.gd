class_name WeaponView
extends Node3D

var model: Node3D
var hands: Node3D
var displayed := -1
var last_ammo := -1
var kick := 0.0
var equip := 0.0

func select_weapon(index: int) -> void:
	if model:
		remove_child(model)
		model.queue_free()
	model = WeaponModels.build(index)
	add_child(model)
	displayed = index
	last_ammo = -1
	equip = 0.15
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
		var support_z := -0.22 if index == 1 else -0.31
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
	if displayed != p.weapon:
		select_weapon(p.weapon)
	var ammo: int = p.magazines[p.weapon]
	if last_ammo >= 0 and ammo < last_ammo:
		kick = 1
	last_ammo = ammo
	kick = move_toward(kick, 0, dt * 10)
	equip = move_toward(equip, 0, dt)
	var progress := 0.0
	if p.reload_left > 0:
		progress = 1.0 - p.reload_left / float(Arsenal.DATA[p.weapon].reload)
	var reload_curve := sin(clampf(progress, 0, 1) * PI)
	model.rotation = Vector3(kick * 0.035 - reload_curve * 0.08, 0, reload_curve * 0.22)
	model.position = Vector3(0, -equip * 0.5, kick * 0.024)
	var magazine := model.get_node("Magazine") as Node3D
	magazine.position.y = -reload_curve * (0.08 if p.weapon == 2 else 0.20)
	magazine.rotation.x = reload_curve * 0.13
	var bolt := model.get_node("Bolt") as Node3D
	bolt.position.z = kick * (0.04 if p.weapon == 4 else 0.025)
	if p.weapon == 2:
		bolt.position.z += reload_curve * 0.06
	hands.rotation.z = reload_curve * 0.1
	var strike := sin(clampf((0.65 - p.melee_left) / 0.65, 0, 1) * PI) if p.melee_left > 0 else 0.0
	model.position += Vector3(-0.10, 0.025, -0.24) * strike
	model.rotation += Vector3(-0.12, -0.3, 0.38) * strike
	hands.position = Vector3(-0.10, 0.025, -0.24) * strike
	hands.rotation.z += strike * 0.38
	model.visible = not (p.weapon == 3 and p.aiming)
	hands.visible = model.visible
