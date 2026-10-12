class_name Fade
extends CanvasLayer
## The short fade between places (ADR-0016): the screen fades to the time of
## day's colour, the next place's scene opens, and the screen fades back,
## about 0.3 s in all. It lives on the tree's root, so it outlasts the scene
## it was started from.

const HALF_SECONDS: float = 0.15

var _cover: ColorRect


## Fades out, changes to `scene_path`, fades back in.
static func to_scene(tree: SceneTree, scene_path: String, colour: Color) -> Fade:
	var fade: Fade = Fade.new()
	fade.layer = 90  # over the HUD, under the developer overlay
	tree.root.add_child(fade)
	fade._run(scene_path, colour)
	return fade


func _run(scene_path: String, colour: Color) -> void:
	_cover = ColorRect.new()
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_cover.color = Color(colour, 0.0)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cover)
	var tween: Tween = create_tween()
	tween.tween_property(_cover, "color:a", 1.0, HALF_SECONDS)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(scene_path))
	tween.tween_property(_cover, "color:a", 0.0, HALF_SECONDS)
	tween.tween_callback(queue_free)


## The colour a place fades through: the night's dark under the sky's tint.
static func colour_at(clock: GameClock) -> Color:
	var sky: Color = clock.sky_tint()
	return Color(Palette.SHADOW[1].r * sky.r, Palette.SHADOW[1].g * sky.g, Palette.SHADOW[1].b * sky.b)
