class_name FarmDrawer
extends RefCounted
## Draws a FarmSim onto any CanvasItem with placeholder shapes in the palette
## (top-down 3/4 view, ADR-0014). Placeholder art until the provisioned art
## arrives; listed in the asset register.
##
## Every world colour is multiplied by the time of day's tint (the sky);
## the base's warm lights and the target highlight are drawn untinted, so at
## dusk the windows stay warm while the world goes blue (art direction,
## "Light and time"). No Godot lights: one multiply per colour (ADR-0007).

static var _tint: Color = Color.WHITE


static func draw(canvas: CanvasItem, sim: FarmSim, alpha: float, tint: Color = Color.WHITE) -> void:
	_tint = tint
	_draw_ground(canvas, sim)
	for cell: Vector2i in sim.planted_cells():
		_draw_crop(canvas, sim, cell)
	_draw_house(canvas, sim)
	var at: Vector2 = sim.previous_position.lerp(sim.player_position, clampf(alpha, 0.0, 1.0))
	_draw_player(canvas, sim, at)
	_draw_lights(canvas, sim)
	_draw_target(canvas, sim)


static func _c(colour: Color) -> Color:
	return Color(colour.r * _tint.r, colour.g * _tint.g, colour.b * _tint.b, colour.a)


## A small, fixed scatter per tile (no randomness: the same every frame).
static func _hash(cell: Vector2i) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663))


static func _draw_ground(canvas: CanvasItem, sim: FarmSim) -> void:
	var b: Rect2 = sim.bounds()
	canvas.draw_rect(b.grow(6), _c(Palette.WARMTH[0]))  # the fence line
	canvas.draw_rect(b, _c(Palette.WILD[1]))
	for y: int in range(sim.plot.size.y):
		for x: int in range(sim.plot.size.x):
			var cell: Vector2i = Vector2i(x, y)
			var r: Rect2 = Rect2(sim.origin + Vector2(cell) * FarmSim.TILE, Vector2(FarmSim.TILE, FarmSim.TILE))
			if sim.plot.is_tilled(cell):
				var soil: Color = Palette.WARMTH[0].darkened(0.35) if sim.plot.is_watered(cell) else Palette.WARMTH[0]
				canvas.draw_rect(r.grow(-1), _c(soil))
				var furrow: Color = Palette.SHADOW[1] if sim.plot.is_watered(cell) else Palette.WARMTH[1].darkened(0.3)
				for i: int in range(3):
					canvas.draw_rect(Rect2(r.position + Vector2(3, 3 + i * 4), Vector2(10, 1)), _c(furrow))
			elif sim.plot.is_blocked(cell):
				# The path: worn, pale earth (grey stone read as water under the
				# dawn tint in the first render). The house is drawn over its part.
				canvas.draw_rect(r, _c(Palette.WILD[3]))
				canvas.draw_rect(Rect2(r.position + Vector2(4 + _hash(cell) % 6, 5), Vector2(2, 1)), _c(Palette.WILD[2]))
			else:
				var h: int = _hash(cell)
				if h % 3 == 0:
					var tuft: Vector2 = r.position + Vector2(3 + h % 9, 3 + (h / 9) % 9)
					canvas.draw_rect(Rect2(tuft, Vector2(1, 2)), _c(Palette.WILD[2]))
					canvas.draw_rect(Rect2(tuft + Vector2(2, 1), Vector2(1, 2)), _c(Palette.WILD[2]))
	# Fence posts along the edge.
	var post: float = b.position.x
	while post <= b.end.x:
		canvas.draw_rect(Rect2(post - 1, b.position.y - 6, 3, 6), _c(Palette.WARMTH[1]))
		canvas.draw_rect(Rect2(post - 1, b.end.y, 3, 6), _c(Palette.WARMTH[1]))
		post += FarmSim.TILE * 2


static func _draw_house(canvas: CanvasItem, sim: FarmSim) -> void:
	for rect: Rect2 in sim.solids:
		# Front wall, then a roof overhanging the top (3/4 view).
		canvas.draw_rect(Rect2(rect.position + Vector2(0, 14), rect.size - Vector2(0, 14)), _c(Palette.WARMTH[1]))
		canvas.draw_rect(Rect2(rect.position - Vector2(3, 6), Vector2(rect.size.x + 6, 24)), _c(Palette.WARMTH[0]))
		canvas.draw_rect(Rect2(rect.position + Vector2(-3, 14), Vector2(rect.size.x + 6, 4)), _c(Palette.WARMTH[0].darkened(0.3)))
	var door: Rect2 = sim.cell_rect(Rect2i(sim.door_cell, Vector2i.ONE))
	canvas.draw_rect(Rect2(door.position + Vector2(3, 2), Vector2(10, 14)), _c(Palette.SHADOW[1]))
	canvas.draw_rect(Rect2(door.position + Vector2(10, 9), Vector2(1, 2)), _c(Palette.WARMTH[3]))
	for window: Rect2 in _windows(sim):
		canvas.draw_rect(window, _c(Palette.SHADOW[2]))


## The house windows (lit by _draw_lights).
static func _windows(sim: FarmSim) -> Array[Rect2]:
	var door: Rect2 = sim.cell_rect(Rect2i(sim.door_cell, Vector2i.ONE))
	return [Rect2(door.position + Vector2(-22, 4), Vector2(10, 7)), Rect2(door.position + Vector2(28, 4), Vector2(10, 7))]


## The base's warm lights, untinted: the windows glow and throw a little
## light onto the ground in front, from dusk on.
static func _draw_lights(canvas: CanvasItem, sim: FarmSim) -> void:
	var on: float = sim.clock.lights()
	if on <= 0.0:
		return
	for window: Rect2 in _windows(sim):
		canvas.draw_rect(window, Color(Palette.WARMTH[3], on))
		canvas.draw_rect(Rect2(window.position + Vector2(4, 0), Vector2(1, window.size.y)), Color(Palette.WARMTH[1], on))
		# A soft amber pool on the ground: many faint, flattened rings (3/4
		# view), so the edge fades instead of reading as a grey disc (the
		# first render).
		var pool: Vector2 = window.get_center() + Vector2(0, 20)
		for i: int in range(6):
			_ellipse(canvas, pool, Vector2(18.0 - i * 2.5, 8.0 - i * 1.1), Color(Palette.WARMTH[2], on * 0.06))


static func _ellipse(canvas: CanvasItem, centre: Vector2, radii: Vector2, colour: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(20):
		var angle: float = TAU * i / 20.0
		points.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	canvas.draw_colored_polygon(points, colour)


static func _draw_crop(canvas: CanvasItem, sim: FarmSim, cell: Vector2i) -> void:
	var stage: int = sim.plot.stage(cell)
	var base: Vector2 = sim.cell_centre(cell) + Vector2(0, 4)  # the soil line
	var crop: StringName = sim.plot.crop_at(cell)
	match stage:
		0:  # seed: two dark specks
			canvas.draw_rect(Rect2(base + Vector2(-3, -1), Vector2(2, 2)), _c(Palette.SHADOW[1]))
			canvas.draw_rect(Rect2(base + Vector2(2, -2), Vector2(2, 2)), _c(Palette.SHADOW[1]))
		1:  # sprout
			canvas.draw_rect(Rect2(base + Vector2(0, -4), Vector2(1, 4)), _c(Palette.CROPS[0]))
			canvas.draw_rect(Rect2(base + Vector2(-2, -5), Vector2(2, 2)), _c(Palette.CROPS[1]))
			canvas.draw_rect(Rect2(base + Vector2(1, -5), Vector2(2, 2)), _c(Palette.CROPS[1]))
		_:  # growing or ripe: a leafy plant, the produce showing when ripe
			var height: float = 7.0 if stage == 2 else 10.0
			canvas.draw_rect(Rect2(base + Vector2(-4, -height), Vector2(8, height)), _c(Palette.CROPS[0]))
			canvas.draw_rect(Rect2(base + Vector2(-5, -height + 2), Vector2(3, 4)), _c(Palette.CROPS[1]))
			canvas.draw_rect(Rect2(base + Vector2(2, -height + 1), Vector2(3, 4)), _c(Palette.CROPS[1]))
			if stage == 3:
				if crop == &"catmint":
					for p: Vector2 in [Vector2(-3, -11), Vector2(0, -13), Vector2(3, -11), Vector2(-1, -9)]:
						canvas.draw_rect(Rect2(base + p, Vector2(2, 2)), _c(Palette.PAPER[1]))
				else:
					canvas.draw_rect(Rect2(base + Vector2(-3, -2), Vector2(6, 4)), _c(Palette.PAPER[0]))
					canvas.draw_rect(Rect2(base + Vector2(-2, 2), Vector2(4, 1)), _c(Palette.PAPER[0]))


static func _draw_player(canvas: CanvasItem, sim: FarmSim, at: Vector2) -> void:
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
	_draw_tool(canvas, sim, at + Vector2(0, -12))


## The tool in hand: held out while working, at the side otherwise.
static func _draw_tool(canvas: CanvasItem, sim: FarmSim, hand: Vector2) -> void:
	var working: bool = sim.busy > 0
	var direction: Vector2 = sim.facing if working else Vector2(0.4, 1).normalized()
	var tip: Vector2 = hand + direction * (12.0 if working else 7.0)
	match sim.last_action if working else sim.tool():
		FarmSim.HOE:
			canvas.draw_line(hand, tip, _c(Palette.WARMTH[0]), 2.0)
			canvas.draw_rect(Rect2(tip - Vector2(2, 1), Vector2(4, 3)), _c(Palette.STONE[2]))
		FarmSim.WATERING_CAN:
			canvas.draw_rect(Rect2(tip - Vector2(3, 3), Vector2(6, 5)), _c(Palette.WATER[0]))
			canvas.draw_line(tip, tip + direction * 4, _c(Palette.WATER[1]), 1.0)
			if working:
				for i: int in range(3):
					canvas.draw_rect(Rect2(tip + direction * (6 + i * 2) + Vector2(0, i), Vector2(1, 1)), _c(Palette.WATER[1]))
		&"harvest":
			canvas.draw_rect(Rect2(tip - Vector2(2, 2), Vector2(4, 4)), _c(Palette.CROPS[1]))
		_:  # a seed pouch
			canvas.draw_rect(Rect2(tip - Vector2(2, 2), Vector2(5, 5)), _c(Palette.PAPER[0]))
			canvas.draw_rect(Rect2(tip - Vector2(1, 3), Vector2(3, 1)), _c(Palette.WARMTH[0]))


## The tile the player acts on, outlined (untinted, so it reads at night).
static func _draw_target(canvas: CanvasItem, sim: FarmSim) -> void:
	var cell: Vector2i = sim.target_cell()
	if not sim.plot.contains(cell):
		return
	var r: Rect2 = sim.cell_rect(Rect2i(cell, Vector2i.ONE))
	canvas.draw_rect(r.grow(-0.5), Color(Palette.PAPER[1], 0.8), false, 1.0)
