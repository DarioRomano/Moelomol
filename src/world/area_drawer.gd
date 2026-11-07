class_name AreaDrawer
extends RefCounted
## Draws an area's map (AreaMap) with placeholder shapes in the palette, in
## the top-down ¾ view (ADR-0014): ground first, then buildings as whole
## blocks with a lighter roof and a darker front wall. Only the cells in view
## are drawn. Placeholder art until the area's art arrives; listed in the
## asset register. Creatures, the player and props are drawn on top by
## CombatDrawer.
##
## Colours keep to art-direction.md: the world is cool and muted; warm
## colours are kept for the player, crops, lights and traces of people.

const BUILDINGS: String = "HKSMPcZ"
const CELL: float = AreaMap.CELL


## Draws the cells of `map` inside `view` (layout px). `tick` animates water.
## `drain`: 0 = floodwater, 1 = drained mud (Millbrook's sluice); for
## Kettlebridge, 0 = the bridge drawn up, 1 = down.
static func draw(canvas: CanvasItem, map: AreaMap, view: Rect2, tick: int, drain: float = 0.0) -> void:
	var low: Vector2i = AreaMap.cell_of(view.position) - Vector2i.ONE
	var high: Vector2i = AreaMap.cell_of(view.end) + Vector2i.ONE
	low = low.clamp(Vector2i.ZERO, map.size - Vector2i.ONE)
	high = high.clamp(Vector2i.ZERO, map.size - Vector2i.ONE)
	for y: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			_draw_ground(canvas, map, Vector2i(x, y), tick, drain)
	for y: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			_draw_cell_top(canvas, map, Vector2i(x, y), tick)
	_draw_bridge(canvas, map, view, drain)
	for block: Dictionary in buildings(map):
		var rect: Rect2 = block["rect"]
		if rect.intersects(view.grow(CELL)):
			_draw_building(canvas, block["char"], rect)


## Whole buildings: each run of building cells as one rectangle
## ({"char", "rect"}), cached per map.
static func buildings(map: AreaMap) -> Array[Dictionary]:
	if map.has_meta(&"buildings"):
		return map.get_meta(&"buildings")
	var found: Array[Dictionary] = []
	var taken: Dictionary = {}
	for y: int in range(map.size.y):
		for x: int in range(map.size.x):
			var c: String = map.rows[y][x]
			if not BUILDINGS.contains(c) or taken.has(Vector2i(x, y)):
				continue
			var w: int = 1
			while x + w < map.size.x and map.rows[y][x + w] == c and not taken.has(Vector2i(x + w, y)):
				w += 1
			var h: int = 1
			while y + h < map.size.y and map.rows[y + h].substr(x, w) == c.repeat(w):
				h += 1
			for yy: int in range(y, y + h):
				for xx: int in range(x, x + w):
					taken[Vector2i(xx, yy)] = true
			found.append({"char": c, "rect": Rect2(Vector2(x, y) * CELL, Vector2(w, h) * CELL)})
	var typed: Array[Dictionary] = found
	map.set_meta(&"buildings", typed)
	return typed


## A small, stable number per cell for variety (no randomness at runtime).
static func _hash(cell: Vector2i) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663)) % 997


static func _draw_ground(canvas: CanvasItem, map: AreaMap, cell: Vector2i, tick: int, drain: float = 0.0) -> void:
	var rect: Rect2 = AreaMap.cell_rect(cell)
	var c: String = map.char_at(cell)
	if AreaMap.MARKERS.contains(c):
		# A numbered place: the ground it stands on is its neighbours' (the
		# village green, the lane), not a patch of plain grass.
		c = map.char_at(cell + Vector2i.LEFT)
		if AreaMap.MARKERS.contains(c) or map.solid.contains(c):
			c = map.char_at(cell + Vector2i.RIGHT)
	var h: int = _hash(cell)
	var grass: Color = Palette.WILD[1] if h % 2 == 0 else Palette.WILD[1].darkened(0.06)
	match c:
		"~", "Y", "n":
			canvas.draw_rect(rect, Palette.WATER[0])
			var wave: float = fmod(tick * 0.2 + h, CELL)
			canvas.draw_line(rect.position + Vector2(4, wave * 0.5 + 6), rect.position + Vector2(12, wave * 0.5 + 6), Palette.WATER[1], 1.0)
		"w":
			var mud: Color = Palette.CHANGED[2].darkened(0.45)  # a drained meadow: mud
			if map.drained:
				canvas.draw_rect(rect, mud)
			else:
				# Draining: the water falls back cell by cell, from the edges
				# first (each cell's own threshold).
				var level: float = clampf((drain - (h % 100) / 200.0) * 2.0, 0.0, 1.0)
				canvas.draw_rect(rect, Palette.WATER[1].darkened(0.15).lerp(mud, level))
				var shimmer: float = fmod(tick * 0.15 + h * 3, CELL)
				canvas.draw_line(rect.position + Vector2(shimmer * 0.5 + 4, 10), rect.position + Vector2(shimmer * 0.5 + 12, 10), Palette.PAPER[0] * Color(1, 1, 1, 0.3), 1.0)
		"=":
			canvas.draw_rect(rect, Palette.CHANGED[2].lightened(0.1))
			canvas.draw_rect(Rect2(rect.position + Vector2(h % 20 + 4, h % 23 + 4), Vector2(2, 2)), Palette.CHANGED[2].darkened(0.1))
		",":
			canvas.draw_rect(rect, Palette.WILD[2])
		"g":
			canvas.draw_rect(rect, Palette.WILD[1].darkened(0.15))
			for i: int in range(3):
				canvas.draw_line(rect.position + Vector2(3, 6 + i * 10), rect.position + Vector2(29, 6 + i * 10), Palette.WILD[0], 2.0)
				canvas.draw_rect(Rect2(rect.position + Vector2(6 + (h + i * 7) % 18, 3 + i * 10), Vector2(4, 3)), Palette.WILD[2])
		"y":
			canvas.draw_rect(rect, Palette.CHANGED[2].darkened(0.2))
		"u":
			canvas.draw_rect(rect, Palette.CHANGED[2].darkened(0.35))
		"v":
			canvas.draw_rect(rect, Palette.CHANGED[1].darkened(0.25))
		"b":
			canvas.draw_rect(rect, Palette.WATER[0])
		"_", "k":
			# The market square's cobbles.
			canvas.draw_rect(rect, Palette.STONE[1].darkened(0.1))
			for i: int in range(2):
				var off: float = 4.0 if i == 0 else 20.0
				canvas.draw_line(rect.position + Vector2(0, off + 6), rect.position + Vector2(CELL, off + 6), Palette.STONE[0], 1.0)
				canvas.draw_line(rect.position + Vector2(off + float(h % 4), off - 4), rect.position + Vector2(off + float(h % 4), off + 6), Palette.STONE[0], 1.0)
		"O", "R":
			# The auction ring's sawdust, scuffed.
			canvas.draw_rect(rect, Palette.CHANGED[2].lightened(0.05))
			canvas.draw_rect(Rect2(rect.position + Vector2(h % 22 + 3, h % 19 + 5), Vector2(3, 2)), Palette.CHANGED[2].darkened(0.15))
		"q", "+":
			canvas.draw_rect(rect, Palette.WILD[1].darkened(0.2))  # the churchyard: grass gone long and dark
		_:
			canvas.draw_rect(rect, grass)
			if h % 5 == 0:
				canvas.draw_line(rect.position + Vector2(h % 24 + 4, 20), rect.position + Vector2(h % 24 + 5, 16), Palette.WILD[2], 1.0)


## What stands on a cell: trees, hedges, wheat, fences, bridges, small things.
static func _draw_cell_top(canvas: CanvasItem, map: AreaMap, cell: Vector2i, tick: int) -> void:
	var rect: Rect2 = AreaMap.cell_rect(cell)
	var p: Vector2 = rect.position
	var h: int = _hash(cell)
	match map.char_at(cell):
		"t":
			canvas.draw_rect(rect, Palette.WILD[0])
			canvas.draw_circle(p + Vector2(10 + h % 6, 12), 11.0, Palette.WILD[1].darkened(0.25))
			canvas.draw_circle(p + Vector2(22, 20 + h % 5), 10.0, Palette.WILD[0].lightened(0.08))
		"h":
			canvas.draw_rect(Rect2(p + Vector2(0, 4), Vector2(CELL, CELL - 6)), Palette.WILD[0])
			canvas.draw_circle(p + Vector2(8, 10), 8.0, Palette.WILD[1].darkened(0.1))
			canvas.draw_circle(p + Vector2(24, 12), 8.0, Palette.WILD[1].darkened(0.2))
		"a":
			canvas.draw_rect(Rect2(p + Vector2(14, 16), Vector2(4, 12)), Palette.CHANGED[0])
			canvas.draw_circle(p + Vector2(16, 12), 11.0, Palette.WILD[1].lightened(0.05))
			canvas.draw_circle(p + Vector2(12 + h % 6, 9), 2.0, Palette.DANGER[0])  # an apple nobody picked
		"i":
			canvas.draw_circle(rect.get_center(), 13.0, Palette.WILD[2])
			canvas.draw_circle(rect.get_center() + Vector2(0, -6), 9.0, Palette.WILD[1])
		"y":
			for i: int in range(5):
				var x: float = 3.0 + i * 6.0 + (h + i) % 3
				canvas.draw_line(p + Vector2(x, 30), p + Vector2(x + 1, 10 + (h + i) % 5), Palette.CHANGED[2], 1.0)
		"u":
			for i: int in range(6):
				canvas.draw_line(p + Vector2(3 + i * 5, 26), p + Vector2(3 + i * 5, 22), Palette.CHANGED[2].darkened(0.1), 1.0)
		"#":
			canvas.draw_line(p + Vector2(0, 20), p + Vector2(CELL, 20), Palette.CHANGED[0], 2.0)
			canvas.draw_line(p + Vector2(0, 26), p + Vector2(CELL, 26), Palette.CHANGED[0], 2.0)
			canvas.draw_rect(Rect2(p + Vector2(2, 12), Vector2(4, 18)), Palette.CHANGED[0].darkened(0.2))
			canvas.draw_rect(Rect2(p + Vector2(18, 12), Vector2(4, 18)), Palette.CHANGED[0].darkened(0.2))
		"b":
			for i: int in range(4):
				canvas.draw_rect(Rect2(p + Vector2(0, 4 + i * 7), Vector2(CELL, 5)), Palette.CHANGED[0].lightened(0.1))
		"W":
			canvas.draw_circle(rect.get_center(), 12.0, Palette.STONE[1])
			canvas.draw_circle(rect.get_center(), 8.0, Palette.WATER[0])
		"e":
			canvas.draw_rect(Rect2(p + Vector2(8, 10), Vector2(16, 16)), Palette.STONE[2])
			canvas.draw_rect(Rect2(p + Vector2(6, 8), Vector2(20, 4)), Palette.STONE[1])
		"X":
			canvas.draw_rect(rect, Palette.WATER[0])
			canvas.draw_rect(Rect2(p + Vector2(4, 0), Vector2(24, CELL)), Palette.CHANGED[0])
			canvas.draw_circle(rect.get_center(), 5.0, Palette.STONE[2])  # the sluice wheel
		"k":
			# A market stall left set out: trestle and awning.
			canvas.draw_rect(Rect2(p + Vector2(3, 14), Vector2(26, 10)), Palette.CHANGED[0])
			canvas.draw_rect(Rect2(p + Vector2(2, 6), Vector2(28, 7)), Palette.CHANGED[1] if h % 2 == 0 else Palette.STONE[2])
			canvas.draw_line(p + Vector2(4, 24), p + Vector2(4, 30), Palette.CHANGED[0].darkened(0.2), 2.0)
			canvas.draw_line(p + Vector2(28, 24), p + Vector2(28, 30), Palette.CHANGED[0].darkened(0.2), 2.0)
		"R":
			# The auctioneer's rostrum: a box with steps.
			canvas.draw_rect(Rect2(p + Vector2(4, 4), Vector2(24, 18)), Palette.CHANGED[0].lightened(0.1))
			canvas.draw_rect(Rect2(p + Vector2(4, 22), Vector2(24, 8)), Palette.CHANGED[0].darkened(0.2))
		"+":
			canvas.draw_rect(Rect2(p + Vector2(10, 8), Vector2(12, 18)), Palette.STONE[2])
			canvas.draw_rect(Rect2(p + Vector2(10, 22), Vector2(12, 4)), Palette.STONE[1])
		"n":
			# The barge, tied up: a long hull, its hold open.
			canvas.draw_rect(Rect2(p + Vector2(0, 6), Vector2(CELL, 22)), Palette.CHANGED[0].darkened(0.1))
			canvas.draw_rect(Rect2(p + Vector2(0, 11), Vector2(CELL, 12)), Palette.SHADOW[1])
		"s":
			canvas.draw_rect(Rect2(p + Vector2(15, 8), Vector2(3, 22)), Palette.CHANGED[0])
			canvas.draw_rect(Rect2(p + Vector2(8, 6), Vector2(18, 7)), Palette.PAPER[0].darkened(0.2))


## The bounds of every `c` cell, cached per map (Kettlebridge's bridge).
static func bounds_of(map: AreaMap, c: String) -> Rect2:
	var key: StringName = StringName("bounds_" + c)
	if map.has_meta(key):
		return map.get_meta(key)
	var cells: Array[Vector2i] = map.cells_of(c)
	var r: Rect2 = Rect2()
	if not cells.is_empty():
		r = AreaMap.cell_rect(cells[0])
		for cell: Vector2i in cells:
			r = r.merge(AreaMap.cell_rect(cell))
	map.set_meta(key, r)
	return r


## The lifting bridge (`Y`): two leaves hinged at the banks. Drawn up, each
## stands on end (a dark underside seen from the ¾ view); lowering (`drain`
## 0 -> 1), each leaf's deck reaches out until they meet.
static func _draw_bridge(canvas: CanvasItem, map: AreaMap, view: Rect2, drain: float) -> void:
	var r: Rect2 = bounds_of(map, "Y")
	if r.size == Vector2.ZERO or not r.intersects(view.grow(CELL * 4.0)):
		return
	var down: float = 1.0 if map.drained else clampf(drain, 0.0, 1.0)
	var half: float = r.size.y / 2.0
	var reach: float = half * down
	var stands: float = half * 0.6 * (1.0 - down)  # the upright part, foreshortened
	var deck: Color = Palette.CHANGED[0].lightened(0.1)
	var under: Color = Palette.CHANGED[0].darkened(0.3)
	# The north leaf, hinged on the north bank.
	canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, reach)), deck)
	canvas.draw_rect(Rect2(r.position - Vector2(0, stands), Vector2(r.size.x, stands)), under)
	# The south leaf, hinged on the south bank, standing up over the river.
	canvas.draw_rect(Rect2(Vector2(r.position.x, r.end.y - reach), Vector2(r.size.x, reach)), deck)
	canvas.draw_rect(Rect2(Vector2(r.position.x, r.end.y - stands), Vector2(r.size.x, stands)), under)
	var y: float = r.position.y + 4.0
	while y < r.end.y:
		if y < r.position.y + reach or y > r.end.y - reach:
			canvas.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), deck.darkened(0.2), 1.0)
		y += 7.0
	# The rails along each side.
	for x: float in [r.position.x + 1.0, r.end.x - 1.0]:
		canvas.draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + reach), Palette.CHANGED[0].darkened(0.4), 2.0)
		canvas.draw_line(Vector2(x, r.end.y - reach), Vector2(x, r.end.y), Palette.CHANGED[0].darkened(0.4), 2.0)


## A building: the roof from above (the lighter top) and the front wall below
## it (darker), with a door and dark windows: nobody is home.
static func _draw_building(canvas: CanvasItem, c: String, rect: Rect2) -> void:
	var roofs: Dictionary = {"H": Palette.SHADOW[2], "K": Palette.STONE[0], "S": Palette.SHADOW[2].lightened(0.1),
		"M": Palette.STONE[0].darkened(0.1), "P": Palette.CHANGED[0], "c": Palette.CHANGED[0], "Z": Palette.STONE[0].darkened(0.05)}
	var walls: Dictionary = {"H": Palette.STONE[1], "K": Palette.STONE[2], "S": Palette.STONE[1],
		"M": Palette.STONE[1], "P": Palette.CHANGED[0].darkened(0.2), "c": Palette.CHANGED[0].darkened(0.2), "Z": Palette.STONE[2]}
	var wall_h: float = minf(18.0, rect.size.y * 0.4)
	var roof: Rect2 = Rect2(rect.position, Vector2(rect.size.x, rect.size.y - wall_h))
	var wall: Rect2 = Rect2(rect.position + Vector2(0, rect.size.y - wall_h), Vector2(rect.size.x, wall_h))
	canvas.draw_rect(roof, roofs[c])
	canvas.draw_rect(Rect2(roof.position, Vector2(roof.size.x, 3)), (roofs[c] as Color).lightened(0.15))
	canvas.draw_rect(wall, walls[c])
	var door: Rect2 = Rect2(Vector2(wall.get_center().x - 4, wall.end.y - 12), Vector2(8, 12))
	canvas.draw_rect(door, Palette.SHADOW[1])
	var x: float = wall.position.x + 6
	while x + 6 < wall.end.x - 2:
		if absf(x + 3 - door.get_center().x) > 10:
			canvas.draw_rect(Rect2(x, wall.position.y + 4, 6, 5), Palette.SHADOW[0])
		x += 16
	if c == "K":
		# The chapel's bell tower.
		canvas.draw_rect(Rect2(rect.position + Vector2(rect.size.x / 2 - 8, -14), Vector2(16, 16)), Palette.STONE[2])
		canvas.draw_rect(Rect2(rect.position + Vector2(rect.size.x / 2 - 3, -10), Vector2(6, 6)), Palette.SHADOW[0])
	if c == "M":
		# The mill wheel on the water side.
		var hub: Vector2 = Vector2(rect.end.x - 4, rect.get_center().y)
		canvas.draw_arc(hub, 14.0, 0, TAU, 20, Palette.CHANGED[0], 3.0)
		for i: int in range(4):
			canvas.draw_line(hub, hub + Vector2.from_angle(i * PI / 4.0) * 14.0, Palette.CHANGED[0], 1.0)
