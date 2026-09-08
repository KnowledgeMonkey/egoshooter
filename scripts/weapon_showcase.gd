class_name WeaponShowcase
extends SubViewportContainer

var stage: Node3D
var model: Node3D
var camera: Camera3D
var drag := false

func _ready() -> void:
	position = Vector2(670, 135)
	size = Vector2(840, 540)
	var view := SubViewport.new()
	view.size = Vector2i(840, 540)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	view.msaa_3d = Viewport.MSAA_4X
	add_child(view)
	stage = Node3D.new()
	view.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("13212a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("cadde1")
	env.environment.ambient_light_energy = 0.55
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.environment.sky = sky
	env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	stage.add_child(env)
	for pos in [Vector3(0.9, 1, 0.2), Vector3(-0.6, 0.4, -0.9)]:
		var light := OmniLight3D.new()
		light.position = pos
		light.omni_range = 3
		light.light_energy = 1.7
		stage.add_child(light)
	camera = Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(1.3, 0.5, 0.4)
	camera.look_at(Vector3(0, -0.025, -0.12))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true

func select_weapon(index: int) -> void:
	if model:
		stage.remove_child(model)
		model.queue_free()
	model = WeaponModels.build(index)
	stage.add_child(model)
	camera.size = 0.43 if index == 4 else 0.8

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag = event.pressed
	if event is InputEventMouseMotion and drag and model:
		model.rotation.y += event.relative.x * 0.008
		model.rotation.z = clampf(model.rotation.z - event.relative.y * 0.005, -0.8, 0.8)

func _process(_dt: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		drag = false
