class_name HouseDrawer
extends RefCounted
## Draws the farmhouse inside (HouseSim) in 3/4 view, in placeholder shapes
## and the draft palette (asset register). Sized for one person (base.md):
## one bed, one cup on the hook, a second chair pushed in and never pulled
## out. The windows show the sky; at night the stove glows and a candle
## burns on the table.

static var _tint: Color = Color.WHITE


## Indoors the time of day comes through the windows, softened: never as
## dark as outside, warmer at night.
static func room_tint(clock: GameClock) -> Color:
	var sky: Color = clock.sky_tint()
	return sky.lerp(Color(1.0, 0.9, 0.78), 0.55)


static func _c(colour: Color) -> Color:
	return Color(colour.r * _tint.r, colour.g * _tint.g, colour.b * _tint.b, colour.a)


static func draw(canvas: CanvasItem, sim: HouseSim, alpha: float, view: Rect2) -> void:
	_tint = room_tint(sim.clock)
	canvas.draw_rect(view.grow(32.0), Palette.SHADOW[0])  # outside the room: dark
	var map: FarmMap = sim.map
	for y: int in range(map.size.y):
		for x: int in range(map.size.x):
			_tile(canvas, sim, Vector2i(x, y))
	_furniture(canvas, sim)
	var at: Vector2 = sim.previous_position.lerp(sim.player_position, clampf(alpha, 0.0, 1.0))
	_draw_player(canvas, sim, at)
	_lights(canvas, sim)
	_target(canvas, sim)


static func _rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * HouseSim.TILE, Vector2(HouseSim.TILE, HouseSim.TILE))


static func _things(map: FarmMap, c: String) -> Rect2:
	var cells: Rect2i = map.bounds_of(c)
	return Rect2(Vector2(cells.position) * HouseSim.TILE, Vector2(cells.size) * HouseSim.TILE)


static func _tile(canvas: CanvasItem, sim: HouseSim, cell: Vector2i) -> void:
	var r: Rect2 = _rect(cell)
	var c: String = sim.map.char_at(cell)
	match c:
		"#":
			canvas.draw_rect(r, _c(Palette.WARMTH[0].darkened(0.55)))
			if sim.map.char_at(cell + Vector2i.UP) != "#" and cell.y > 0:
				canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), _c(Palette.WARMTH[0].darkened(0.3)))
		"^", "w", "h":
			# The back wall's face: plaster over a skirting board.
			canvas.draw_rect(r, _c(Palette.WARMTH[1]))
			canvas.draw_rect(Rect2(r.position + Vector2(0, 13), Vector2(16, 3)), _c(Palette.WARMTH[0]))
			if c == "w":
				_window(canvas, sim, r)
			elif c == "h":
				canvas.draw_rect(Rect2(r.position + Vector2(7, 3), Vector2(2, 2)), _c(Palette.WARMTH[0]))
				canvas.draw_rect(Rect2(r.position + Vector2(5, 5), Vector2(5, 5)), _c(Palette.PAPER[1]))  # the one cup
				canvas.draw_rect(Rect2(r.position + Vector2(10, 6), Vector2(1, 3)), _c(Palette.PAPER[1]))
		"D":
			# The doorway: the day (or night) outside.
			var outside: Color = Palette.WILD[1] * sim.clock.sky_tint()
			canvas.draw_rect(r, Color(outside, 1.0))
			canvas.draw_rect(Rect2(r.position, Vector2(16, 2)), _c(Palette.WARMTH[0]))
		_:
			_floor(canvas, cell, r)
			if c == "_":
				canvas.draw_rect(r.grow(-1), _c(Palette.DANGER[0].lerp(Palette.WARMTH[1], 0.5)))
				canvas.draw_rect(Rect2(r.position + Vector2(1, 3), Vector2(14, 1)), _c(Palette.WARMTH[2]))
				canvas.draw_rect(Rect2(r.position + Vector2(1, 12), Vector2(14, 1)), _c(Palette.WARMTH[2]))


## Floorboards, running across the room, their joints staggered.
static func _floor(canvas: CanvasItem, cell: Vector2i, r: Rect2) -> void:
	canvas.draw_rect(r, _c(Palette.WARMTH[0].lightened(0.12)))
	canvas.draw_rect(Rect2(r.position + Vector2(0, 7), Vector2(16, 1)), _c(Palette.WARMTH[0].darkened(0.15)))
	canvas.draw_rect(Rect2(r.position + Vector2(0, 15), Vector2(16, 1)), _c(Palette.WARMTH[0].darkened(0.15)))
	var joint: float = 4.0 + float((cell.x * 7 + cell.y * 3) % 9)
	canvas.draw_rect(Rect2(r.position + Vector2(joint, 0), Vector2(1, 7)), _c(Palette.WARMTH[0].darkened(0.15)))


## A window pane shows the sky: pale by day, deep at night (untinted, it is
## the light coming in).
static func _window(canvas: CanvasItem, sim: HouseSim, r: Rect2) -> void:
	var sky: Color = sim.clock.sky_tint()
	var pane: Color = Color(Palette.WATER[1].r * sky.r, Palette.WATER[1].g * sky.g, Palette.WATER[1].b * sky.b)
	canvas.draw_rect(Rect2(r.position + Vector2(1, 2), Vector2(14, 10)), _c(Palette.WARMTH[0]))
	canvas.draw_rect(Rect2(r.position + Vector2(2, 3), Vector2(12, 8)), pane)
	canvas.draw_rect(Rect2(r.position + Vector2(7, 3), Vector2(2, 8)), _c(Palette.WARMTH[0]))


static func _furniture(canvas: CanvasItem, sim: HouseSim) -> void:
	var map: FarmMap = sim.map
	# The bed: a frame, a pillow, a quilt turned back.
	var bed: Rect2 = _things(map, "B")
	canvas.draw_rect(bed.grow_individual(-1, 0, -1, -2), _c(Palette.WARMTH[0]))
	canvas.draw_rect(Rect2(bed.position + Vector2(3, 2), Vector2(bed.size.x - 6, 9)), _c(Palette.PAPER[1]))
	canvas.draw_rect(Rect2(bed.position + Vector2(2, 13), Vector2(bed.size.x - 4, bed.size.y - 17)), _c(Palette.WATER[0].lerp(Palette.WARMTH[2], 0.35)))
	canvas.draw_rect(Rect2(bed.position + Vector2(2, 13), Vector2(bed.size.x - 4, 3)), _c(Palette.PAPER[0]))
	# The window seat, under its window: a bench and a cushion.
	var seat: Rect2 = _things(map, "S")
	canvas.draw_rect(Rect2(seat.position + Vector2(0, 4), Vector2(seat.size.x, 12)), _c(Palette.WARMTH[0]))
	canvas.draw_rect(Rect2(seat.position + Vector2(2, 2), Vector2(seat.size.x - 4, 5)), _c(Palette.DANGER[0].lerp(Palette.WARMTH[2], 0.6)))
	# The stove: iron on a stone hearth, a small fire door.
	var stove: Rect2 = _things(map, "O")
	canvas.draw_rect(stove.grow(-1), _c(Palette.STONE[0]))
	canvas.draw_rect(Rect2(stove.position + Vector2(4, 3), Vector2(stove.size.x - 8, 14)), _c(Palette.SHADOW[1]))
	canvas.draw_rect(Rect2(stove.position + Vector2(10, 20), Vector2(12, 7)), _c(Palette.SHADOW[0]))
	canvas.draw_rect(Rect2(stove.position + Vector2(12, 23), Vector2(8, 3)), Color(Palette.WARMTH[3], 0.85))  # embers
	canvas.draw_rect(Rect2(stove.position + Vector2(stove.size.x - 9, -10), Vector2(5, 12)), _c(Palette.STONE[0]))  # the flue
	# The cat's basket, by the stove (empty: base.md step 4 brings the cat).
	var basket: Rect2 = _things(map, "k")
	canvas.draw_rect(Rect2(basket.position + Vector2(1, 6), Vector2(14, 8)), _c(Palette.WARMTH[1].darkened(0.1)))
	canvas.draw_rect(Rect2(basket.position + Vector2(3, 7), Vector2(10, 4)), _c(Palette.WARMTH[0].darkened(0.2)))
	# The table, and its two chairs: one pulled out, one pushed in.
	var table: Rect2 = _things(map, "T")
	canvas.draw_rect(Rect2(table.position + Vector2(1, 2), Vector2(table.size.x - 2, 16)), _c(Palette.WARMTH[1].darkened(0.15)))
	canvas.draw_rect(Rect2(table.position + Vector2(1, 18), Vector2(table.size.x - 2, 3)), _c(Palette.WARMTH[0]))
	canvas.draw_rect(Rect2(table.position + Vector2(3, 21), Vector2(3, 10)), _c(Palette.WARMTH[0]))
	canvas.draw_rect(Rect2(table.end + Vector2(-6, -11), Vector2(3, 10)), _c(Palette.WARMTH[0]))
	var chairs: Array[Vector2i] = map.cells_of("c")
	for i: int in range(chairs.size()):
		var r: Rect2 = _rect(chairs[i])
		var shift: float = -3.0 if i == 0 else 3.0  # the first pulled out, the other pushed in to the table
		canvas.draw_rect(Rect2(r.position + Vector2(3 + shift, 4), Vector2(10, 9)), _c(Palette.WARMTH[0]))
		canvas.draw_rect(Rect2(r.position + Vector2(3 + shift, 0), Vector2(10, 4)), _c(Palette.WARMTH[0].darkened(0.2)))
	# The cupboard, and the seed tin on it.
	var cupboard: Rect2 = _things(map, "u")
	canvas.draw_rect(cupboard.grow_individual(-1, 2, -3, -1), _c(Palette.WARMTH[0]))
	canvas.draw_rect(Rect2(cupboard.position + Vector2(2, 14), Vector2(10, 1)), _c(Palette.WARMTH[0].darkened(0.3)))
	var tin: Vector2 = cupboard.position + Vector2(3, -2)
	canvas.draw_rect(Rect2(tin, Vector2(8, 7)), _c(Palette.STONE[1]))
	canvas.draw_rect(Rect2(tin + Vector2(1, 3), Vector2(6, 2)), _c(Palette.CROPS[0]))  # its label
	if sim.tin_taken:
		canvas.draw_rect(Rect2(tin + Vector2(7, -2), Vector2(4, 2)), _c(Palette.STONE[1]))  # the lid, off
	else:
		canvas.draw_rect(Rect2(tin + Vector2(-1, -1), Vector2(10, 2)), _c(Palette.STONE[0]))  # the lid, on
	# A candle on the table.
	canvas.draw_rect(Rect2(table.get_center() + Vector2(-1, -6), Vector2(2, 4)), _c(Palette.PAPER[1]))


static func _draw_player(canvas: CanvasItem, sim: HouseSim, at: Vector2) -> void:
	canvas.draw_rect(Rect2(at.x - 6, at.y - 2, 12, 4), Color(_c(Palette.SHADOW[0]), 0.6))
	var top: Vector2 = at + Vector2(-8, -24)
	canvas.draw_rect(Rect2(top + Vector2(4, 0), Vector2(8, 8)), _c(Palette.WARMTH[2]))
	canvas.draw_rect(Rect2(top + Vector2(3, 8), Vector2(10, 10)), _c(Palette.WARMTH[1]))
	canvas.draw_rect(Rect2(top + Vector2(4, 18), Vector2(3, 6)), _c(Palette.WARMTH[0]))
	canvas.draw_rect(Rect2(top + Vector2(9, 18), Vector2(3, 6)), _c(Palette.WARMTH[0]))
	if sim.facing.y > -0.5:
		var shift: float = roundf(sim.facing.x * 2.0)
		canvas.draw_rect(Rect2(top + Vector2(6 + shift, 3), Vector2(1, 1)), _c(Palette.SHADOW[0]))
		canvas.draw_rect(Rect2(top + Vector2(9 + shift, 3), Vector2(1, 1)), _c(Palette.SHADOW[0]))


## At dusk and night: the candle's flame and the stove's glow (untinted).
static func _lights(canvas: CanvasItem, sim: HouseSim) -> void:
	var on: float = sim.clock.lights()
	if on <= 0.0:
		return
	var table: Rect2 = _things(sim.map, "T")
	var flame: Vector2 = table.get_center() + Vector2(0, -8)
	canvas.draw_rect(Rect2(flame - Vector2(1, 1), Vector2(2, 2)), Color(Palette.WARMTH[3], on))
	var stove: Rect2 = _things(sim.map, "O")
	for i: int in range(5):
		canvas.draw_circle(flame, 26.0 - i * 5.0, Color(Palette.WARMTH[2], on * 0.05))
		canvas.draw_circle(stove.position + Vector2(16, 26), 30.0 - i * 6.0, Color(Palette.WARMTH[3], on * 0.04))


## A quiet outline on what Interact would use.
static func _target(canvas: CanvasItem, sim: HouseSim) -> void:
	if sim.target_kind() == &"":
		return
	var r: Rect2 = _rect(sim.target_cell())
	canvas.draw_rect(r, Color(Palette.PAPER[1], 0.5), false, 1.0)
