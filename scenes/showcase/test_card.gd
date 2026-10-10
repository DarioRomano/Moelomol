extends Control
## Pixel-scale test card (debug scene, not game content).
##
## Shows at a glance whether the ADR-0008 display settings hold:
## - a 1 px frame on every edge: missing or doubled lines mean clipping or
##   non-integer scaling;
## - a 16 px tile checkerboard: uneven squares mean non-integer scaling;
## - 1 px stripes: blur or uneven widths mean filtering or fractional scaling;
## - the draft palette, so colours can be judged on a real screen;
## - full-resolution rendering (ADR-0008 Amendment 3): a row of squares, each
##   a quarter of an art pixel further right than the last, should step
##   smoothly; and a half-pixel marker that render_checks() verifies in every
##   review render.
## HUD parts (labels, red corner markers, teal outline) sit in a UiFrame, so
## they follow the UI width setting (Q15): at "full" they reach the screen
## corners; at 21:9 or 16:9 on a wider screen they stay in a centred frame
## while the checkerboard and yellow edge (the "world") fill the screen.

const TILE: int = 16
const FIGURE_SIZE: Vector2i = Vector2i(16, 24)
## Art pixel whose right half the half-pixel marker covers (layout units).
const MARKER_PIXEL: Vector2i = Vector2i(120, 52)

## Draws the HUD frame's corner markers and outline.
class HudCorners extends Control:
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var area: Vector2i = Vector2i(size)
		var marker: int = 8
		for corner: Vector2i in [
				Vector2i(2, 2), Vector2i(area.x - marker - 2, 2),
				Vector2i(2, area.y - marker - 2), Vector2i(area.x - marker - 2, area.y - marker - 2)]:
			draw_rect(Rect2(corner, Vector2i(marker, marker)), Palette.DANGER[1])
		# Outline 4 px inside the frame so it never hides the yellow world edge.
		draw_rect(Rect2(4, 4, area.x - 8, area.y - 8), Palette.WATER[1], false, 1.0)


var _hud: UiFrame
var _info_label: Label
var _build_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud = UiFrame.new()
	add_child(_hud)
	_hud.add_child(HudCorners.new())
	_hud.settings.changed.connect(_refresh)
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
	_hud.add_child(label)
	return label


func _refresh() -> void:
	var visible_size: Vector2 = get_viewport_rect().size
	var window_size: Vector2i = DisplayServer.window_get_size()
	_info_label.text = "TEST CARD  view %dx%d  window %dx%d  scale %dx  ui %s" % [
		int(visible_size.x), int(visible_size.y), window_size.x, window_size.y,
		DisplayMath.expected_scale(window_size),
		GameSettings.UI_WIDTH_NAMES[_hud.settings.ui_width],
	]
	queue_redraw()


func _draw() -> void:
	var view: Vector2i = Vector2i(get_viewport_rect().size)
	_draw_checkerboard(view)
	_draw_palette(Vector2i(TILE, TILE))
	_draw_stripes(Vector2i(TILE, TILE * 3))
	_draw_full_resolution_row(Vector2(TILE, TILE * 5))
	_draw_figure(Vector2i(view.x / 2 - FIGURE_SIZE.x / 2, view.y / 2 - FIGURE_SIZE.y / 2))
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


func _draw_full_resolution_row(origin: Vector2) -> void:
	# Eight 4x4 squares, each a quarter art pixel further right than a plain
	# 8-pixel spacing: only full-resolution rendering can show the steps.
	for i: int in range(8):
		draw_rect(Rect2(origin.x + i * 8.25, origin.y, 4, 4), Palette.WARMTH[3])
	# Background for the half-pixel marker, then the marker itself: the right
	# half of one art pixel, 4 art pixels tall.
	draw_rect(Rect2(MARKER_PIXEL.x - 2, MARKER_PIXEL.y - 1, 5, 6), Palette.SHADOW[0])
	draw_rect(Rect2(MARKER_PIXEL.x + 0.5, MARKER_PIXEL.y, 0.5, 4), Palette.DANGER[1])


## Called by tools/render_showcase.gd on every review render. Returns problems
## (empty if fine). Checks the scene really is drawn at full resolution: the
## marker covers only the right half of its art pixel, which the old
## low-resolution rendering could not show. Skipped at 1x, where an art pixel
## is a single screen pixel.
func render_checks(image: Image, to_screen: Transform2D) -> Array[String]:
	var scale: int = roundi(to_screen.get_scale().x)
	if scale < 2:
		return []
	var left: Vector2i = Vector2i(to_screen * (Vector2(MARKER_PIXEL) + Vector2(0.0, 2.0)))
	var right: Vector2i = left + Vector2i(scale - 1, 0)
	var marker: Color = Palette.DANGER[1]
	var problems: Array[String] = []
	if image.get_pixelv(left).is_equal_approx(marker):
		problems.append("left half of the marker's art pixel (%s) is marker colour: not full resolution" % left)
	if not image.get_pixelv(right).is_equal_approx(marker):
		problems.append("right half of the marker's art pixel (%s) is %s, not the marker: not full resolution"
			% [right, image.get_pixelv(right).to_html(false)])
	return problems


func _draw_figure(origin: Vector2i) -> void:
	# Placeholder 16x24 character silhouette for judging on-screen size.
	draw_rect(Rect2(origin.x + 4, origin.y, 8, 8), Palette.WARMTH[2])
	draw_rect(Rect2(origin.x + 3, origin.y + 8, 10, 10), Palette.WARMTH[1])
	draw_rect(Rect2(origin.x + 4, origin.y + 18, 3, 6), Palette.WARMTH[0])
	draw_rect(Rect2(origin.x + 9, origin.y + 18, 3, 6), Palette.WARMTH[0])
	draw_rect(Rect2(origin.x + 6, origin.y + 3, 1, 1), Palette.SHADOW[0])
	draw_rect(Rect2(origin.x + 9, origin.y + 3, 1, 1), Palette.SHADOW[0])


func _draw_frame(view: Vector2i) -> void:
	var colour: Color = Palette.WARMTH[3]
	draw_rect(Rect2(0, 0, view.x, 1), colour)
	draw_rect(Rect2(0, view.y - 1, view.x, 1), colour)
	draw_rect(Rect2(0, 0, 1, view.y), colour)
	draw_rect(Rect2(view.x - 1, 0, 1, view.y), colour)
