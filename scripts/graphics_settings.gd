class_name GraphicsSettings
extends RefCounted

const NAMES = ["Performance", "Hoch", "Sehr hoch"]

static func apply(game: Node3D, quality: int) -> void:
	game.graphics_quality = clampi(quality, 0, 2)
	quality = game.graphics_quality
	var view := game.get_viewport()
	view.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][quality]
	view.scaling_3d_scale = 0.85 if quality == 0 else 1.0
	var world := game.arena.get_node_or_null("DistrictAtmosphere") as WorldEnvironment
	if world:
		world.environment.ssao_enabled = quality > 0
		world.environment.glow_enabled = quality > 0
	var sun := game.arena.get_node_or_null("LateAfternoonSun") as DirectionalLight3D
	if sun:
		sun.directional_shadow_max_distance = 65 if quality == 0 else 95
	RenderingServer.directional_shadow_atlas_set_size(4096 if quality == 2 else 2048, true)
