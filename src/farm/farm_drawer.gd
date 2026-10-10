class_name FarmDrawer
extends RefCounted
## Draws a FarmSim onto any CanvasItem with placeholder shapes in the palette
## (top-down 3/4 view, ADR-0014). Placeholder art until the provisioned art
## arrives; listed in the asset register.
##
## Farming is magic (Q27): the farmer casts with a glow in warm living green
## and gold (Q28, working assumption C: nothing violet at the base yet).
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
	if sim.raining:
		_draw_rain(canvas, sim)
	_draw_target(canvas, sim)


## The tint to draw the world with: the time of day, dimmed and cooled
## while it rains.
static func world_tint(sim: FarmSim) -> Color:
	var tint: Color = sim.clock.sky_tint()
	return tint * Color(0.8, 0.85, 0.95) if sim.raining else tint


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


## The farmer's hands while casting: a glow in front, and the spell's mark
## on its target (earth for Till, droplets for Water, a seed for Sow); a
## crop in hand when harvesting. Hands empty otherwise.
static func _draw_tool(canvas: CanvasItem, sim: FarmSim, hand: Vector2) -> void:
	if sim.busy <= 0:
		return
	var progress: float = 1.0 - float(sim.busy) / FarmSim.cast_ticks()
	var tip: Vector2 = hand + sim.facing * 8.0
	if sim.last_action == &"harvest":
		canvas.draw_rect(Rect2(tip - Vector2(2, 2), Vector2(4, 4)), _c(Palette.CROPS[1]))
		return
	# The glow: untinted, like a light, so casting reads at night.
	var glow: Color = Palette.WARMTH[3] if sim.last_action != FarmSim.WATER else Palette.CROPS[1]
	canvas.draw_circle(tip, 2.0 + progress * 2.0, Color(glow, 0.55 * (1.0 - progress * 0.5)))
	canvas.draw_rect(Rect2(tip - Vector2(1, 1), Vector2(2, 2)), Color(Palette.PAPER[1], 0.9))
	var target: Vector2 = sim.cell_centre(sim.target_cell())
	match sim.last_action:
		FarmSim.TILL:
			for i: int in range(3):
				var puff: Vector2 = target + Vector2(-4 + i * 4, 2 - progress * 5.0 - i % 2)
				canvas.draw_rect(Rect2(puff, Vector2(2, 2)), Color(_c(Palette.WARMTH[1]), 1.0 - progress))
		FarmSim.WATER:
			for cell: Vector2i in sim.water_area(sim.target_cell()):
				var c: Vector2 = sim.cell_centre(cell)
				for i: int in range(2):
					var drop: Vector2 = c + Vector2(-3 + i * 5, -10 + progress * 10.0 + i * 2)
					canvas.draw_rect(Rect2(drop, Vector2(1, 2)), Color(Palette.WATER[1].lightened(0.3), 0.9))
		_:
			canvas.draw_rect(Rect2(target + Vector2(-1, -6 + progress * 6.0), Vector2(2, 2)), Color(_c(Palette.WARMTH[0]), 1.0))


## Rain (the watering spell's final form): streaks over the whole field.
static func _draw_rain(canvas: CanvasItem, sim: FarmSim) -> void:
	var b: Rect2 = sim.bounds()
	var phase: float = fposmod(sim.clock.total_minutes * 40.0, 24.0)
	var x: float = b.position.x
	var row: int = 0
	while x < b.end.x:
		var y: float = b.position.y + fposmod(phase + row * 7.0, 24.0) - 12.0
		while y < b.end.y:
			canvas.draw_line(Vector2(x, y), Vector2(x - 2, y + 6), Color(Palette.WATER[1].lightened(0.4), 0.5), 1.0)
			y += 24.0
		x += 11.0
		row += 1


## The tile the player acts on, outlined (untinted, so it reads at night).
## For the watering spell, its whole area is outlined faintly too.
static func _draw_target(canvas: CanvasItem, sim: FarmSim) -> void:
	var cell: Vector2i = sim.target_cell()
	if not sim.plot.contains(cell):
		return
	if sim.spell() == FarmSim.WATER:
		for c: Vector2i in sim.water_area(cell):
			if c != cell:
				canvas.draw_rect(sim.cell_rect(Rect2i(c, Vector2i.ONE)).grow(-1.5), Color(Palette.PAPER[1], 0.35), false, 1.0)
	var r: Rect2 = sim.cell_rect(Rect2i(cell, Vector2i.ONE))
	canvas.draw_rect(r.grow(-0.5), Color(Palette.PAPER[1], 0.8), false, 1.0)
