class_name CatDrawer
extends RefCounted
## Draws the cat (placeholder shapes in the draft palette; asset register): a
## small grey cat sitting, its tail round its feet; curled up asleep on the
## blanket; eyes closed while it is stroked. Its eyes are the only warm
## points on it, and at night they stay a touch too bright (untinted).


## `at` is where its feet are; `tint` the place's light; `purring` closes
## its eyes; `curled` is the blanket pose.
static func draw(canvas: CanvasItem, at: Vector2, tint: Color, purring: bool, curled: bool) -> void:
	var fur: Color = _t(Palette.STONE[0].darkened(0.25), tint)
	var dark: Color = _t(Palette.SHADOW[1], tint)
	var p: Vector2 = at.round()
	canvas.draw_rect(Rect2(p + Vector2(-5, -1), Vector2(10, 2)), Color(_t(Palette.SHADOW[0], tint), 0.5))
	if curled:
		canvas.draw_rect(Rect2(p + Vector2(-6, -5), Vector2(12, 5)), fur)
		canvas.draw_rect(Rect2(p + Vector2(-7, -4), Vector2(14, 3)), fur)
		canvas.draw_rect(Rect2(p + Vector2(2, -7), Vector2(4, 3)), fur)  # the head, tucked
		canvas.draw_rect(Rect2(p + Vector2(2, -8), Vector2(1, 1)), fur)
		canvas.draw_rect(Rect2(p + Vector2(5, -8), Vector2(1, 1)), fur)
		canvas.draw_rect(Rect2(p + Vector2(-6, -1), Vector2(9, 1)), dark)  # the tail round it
		return
	# Sitting: body, chest, head, ears, tail curled round the front.
	canvas.draw_rect(Rect2(p + Vector2(-3, -7), Vector2(6, 7)), fur)
	canvas.draw_rect(Rect2(p + Vector2(-4, -4), Vector2(8, 4)), fur)
	canvas.draw_rect(Rect2(p + Vector2(-3, -12), Vector2(6, 5)), fur)
	canvas.draw_rect(Rect2(p + Vector2(-3, -13), Vector2(1, 1)), fur)
	canvas.draw_rect(Rect2(p + Vector2(2, -13), Vector2(1, 1)), fur)
	canvas.draw_rect(Rect2(p + Vector2(-5, -1), Vector2(8, 1)), dark)
	canvas.draw_rect(Rect2(p + Vector2(-6, -3), Vector2(1, 2)), dark)
	if purring:
		canvas.draw_rect(Rect2(p + Vector2(-2, -10), Vector2(1, 1)), dark)
		canvas.draw_rect(Rect2(p + Vector2(1, -10), Vector2(1, 1)), dark)
	else:
		canvas.draw_rect(Rect2(p + Vector2(-2, -10), Vector2(1, 1)), Palette.WARMTH[3])
		canvas.draw_rect(Rect2(p + Vector2(1, -10), Vector2(1, 1)), Palette.WARMTH[3])


static func _t(colour: Color, tint: Color) -> Color:
	return Color(colour.r * tint.r, colour.g * tint.g, colour.b * tint.b, colour.a)
