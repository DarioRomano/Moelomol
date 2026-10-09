extends Control
## Pixel-scale test card (debug scene, not game content).
##
## Shows at a glance whether the ADR-0008 display settings hold:
## - a 1 px frame on every edge: missing or doubled lines mean clipping or
##   non-integer scaling;
## - a 16 px tile checkerboard: uneven squares mean non-integer scaling;
## - 1 px stripes: blur or uneven widths mean filtering or fractional scaling;
## - markers anchored to each corner: they must sit in the corners at every
##   aspect ratio (aspect = expand grows the visible area);
## - the draft palette, so colours can be judged on a real screen.

const TILE: int = 16
const FIGURE_SIZE: Vector2i = Vector2i(16, 24)

var _info_label: Label
var _build_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_info_label = _make_label()
	_info_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	_build_label = _make_label()
	_build_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	_build_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_build_label.text = BuildInfo.label()
	get_viewport().size_changed.connect(_refresh)
	_refresh()


func _make_label() -> Label:
	var label: Label = Label.new()
	label.add_theme_color_override("font_color", Palette.PAPER[1])
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
	return label


func _refresh() -> void:
	var visible_size: Vector2 = get_viewport_rect().size
	var window_size: Vector2i = DisplayServer.window_get_size()
	_info_label.text = "TEST CARD  view %dx%d  window %dx%d  scale %dx" % [
		int(visible_size.x), int(visible_size.y), window_size.x, window_size.y,
		DisplayMath.expected_scale(window_size),
	]
	queue_redraw()


func _draw() -> void:
	var view: Vector2i = Vector2i(get_viewport_rect().size)
	_draw_checkerboard(view)
	_draw_palette(Vector2i(TILE, TILE))
	_draw_stripes(Vector2i(TILE, TILE * 3))
	_draw_figure(Vector2i(view.x / 2 - FIGURE_SIZE.x / 2, view.y / 2 - FIGURE_SIZE.y / 2))
	_draw_corner_markers(view)
	_draw_frame(view)


func _draw_checkerboard(view: Vector2i) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Palette.SHADOW[0])
	for y: int in range(0, view.y, TILE):
		for x: int in range(0, view.x, TILE):
			if (x / TILE + y / TILE) % 2 == 0:
				draw_rect(Rect2(x, y, TILE, TILE), Palette.SHADOW[1])


func _draw_palette(origin: Vector2i) -> void:
	# A pale backing strip so the darkest swatches stay visible.
	var count: int = Palette.all_colours().size()
	draw_rect(Rect2(origin.x - 2, origin.y - 2, count * TILE + 4, TILE + 4), Palette.STONE[2])
	var x: int = origin.x
	for colour: Color in Palette.all_colours():
		draw_rect(Rect2(x, origin.y, TILE, TILE), colour)
		x += TILE


func _draw_stripes(origin: Vector2i) -> void:
	# 32 alternating 1 px columns, and beside them 16 alternating 1 px rows.
	for i: int in range(32):
		var colour: Color = Palette.PAPER[1] if i % 2 == 0 else Palette.SHADOW[0]
		draw_rect(Rect2(origin.x + i, origin.y, 1, TILE), colour)
		if i < TILE:
			draw_rect(Rect2(origin.x + 40, origin.y + i, 32, 1), colour)


func _draw_figure(origin: Vector2i) -> void:
	# Placeholder 16x24 character silhouette for judging on-screen size.
	draw_rect(Rect2(origin.x + 4, origin.y, 8, 8), Palette.WARMTH[2])
	draw_rect(Rect2(origin.x + 3, origin.y + 8, 10, 10), Palette.WARMTH[1])
	draw_rect(Rect2(origin.x + 4, origin.y + 18, 3, 6), Palette.WARMTH[0])
	draw_rect(Rect2(origin.x + 9, origin.y + 18, 3, 6), Palette.WARMTH[0])
	draw_rect(Rect2(origin.x + 6, origin.y + 3, 1, 1), Palette.SHADOW[0])
	draw_rect(Rect2(origin.x + 9, origin.y + 3, 1, 1), Palette.SHADOW[0])


func _draw_corner_markers(view: Vector2i) -> void:
	var size: int = 8
	var corners: Array[Vector2i] = [
		Vector2i(2, 2),
		Vector2i(view.x - size - 2, 2),
		Vector2i(2, view.y - size - 2),
		Vector2i(view.x - size - 2, view.y - size - 2),
	]
	for corner: Vector2i in corners:
		draw_rect(Rect2(corner, Vector2i(size, size)), Palette.DANGER[1])


func _draw_frame(view: Vector2i) -> void:
	var colour: Color = Palette.WARMTH[3]
	draw_rect(Rect2(0, 0, view.x, 1), colour)
	draw_rect(Rect2(0, view.y - 1, view.x, 1), colour)
	draw_rect(Rect2(0, 0, 1, view.y), colour)
	draw_rect(Rect2(view.x - 1, 0, 1, view.y), colour)
