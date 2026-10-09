class_name UiFrame
extends Control
## Holds HUD and menu elements. Its rect is the visible area narrowed to the
## player's UI width setting (Q15), centred, full height. Anchor children to
## this frame's edges instead of the screen's.
##
## Widths are aspect ratios of the visible area:
## - 16:9 is the 640x360 base shape.
## - "21:9" is 43:18 (3440x1440), the widest common 21:9 panel, so that the
##   setting changes nothing on any real 21:9 monitor (2560x1080 is 64:27,
##   narrower) and on 32:9 matches what a 3440x1440 player sees.

const RATIO_16_9: float = 16.0 / 9.0
const RATIO_21_9: float = 43.0 / 18.0

var settings: GameSettings = null


## The frame for a visible area of view_size at the given width setting.
static func frame_rect(view_size: Vector2i, width: GameSettings.UiWidth) -> Rect2i:
	var max_width: int = view_size.x
	match width:
		GameSettings.UiWidth.WIDE_16_9:
			max_width = floori(view_size.y * RATIO_16_9)
		GameSettings.UiWidth.WIDE_21_9:
			max_width = floori(view_size.y * RATIO_21_9)
	var frame_width: int = mini(view_size.x, max_width)
	return Rect2i((view_size.x - frame_width) / 2, 0, frame_width, view_size.y)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if settings == null:
		settings = GameSettings.shared()
	settings.changed.connect(_refresh)
	get_viewport().size_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var view: Vector2i = Vector2i(get_viewport_rect().size)
	var rect: Rect2i = frame_rect(view, settings.ui_width)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = rect.position.x
	offset_right = rect.end.x - view.x
	offset_top = 0
	offset_bottom = 0
