class_name FarmGround
extends RefCounted
## The farm's ground, painted once into one image (placeholder shapes in the
## palette; asset register): grass, paths, hedges, the pond, the woods round
## the edge and the thicket over the unopened parcels. What changes during
## play (soil, crops, buildings, the player, lights) is drawn over it each
## frame by FarmDrawer. One texture is one draw call for the whole ground
## (ADR-0007), tinted by the time of day when drawn.
##
## The thicket is the farm's ordinary greens, dull and cool, never the
## changed land's violets: neglect, not the calamity (base.md).

const TILE: int = 16

static var _cached: ImageTexture = null
static var _cached_rows: Array[String] = []


## The ground as a texture, painted on first use and kept.
static func texture_for(map: FarmMap) -> ImageTexture:
	if _cached == null or _cached_rows != map.rows:
		_cached = ImageTexture.create_from_image(paint(map))
		_cached_rows = map.rows.duplicate()
	return _cached


## Paints every tile of the map.
static func paint(map: FarmMap) -> Image:
	var img: Image = Image.create_empty(map.size.x * TILE, map.size.y * TILE, false, Image.FORMAT_RGBA8)
	for y: int in range(map.size.y):
		for x: int in range(map.size.x):
			_tile(img, map, Vector2i(x, y))
	return img


## A small, fixed scatter per tile (no randomness: the same every run).
static func _hash(cell: Vector2i) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663))


static func _px(img: Image, cell: Vector2i, x: int, y: int, w: int, h: int, colour: Color) -> void:
	img.fill_rect(Rect2i(cell.x * TILE + x, cell.y * TILE + y, w, h), colour)


static func _tile(img: Image, map: FarmMap, cell: Vector2i) -> void:
	var c: String = map.char_at(cell)
	var h: int = _hash(cell)
	match c:
		"t":
			_woods(img, cell, h)
		"1", "2", "3", "4", "5", "6", "-":
			_thicket(img, cell, h)
		"#":
			_hedge(img, map, cell, h)
		"=", "G":
			_px(img, cell, 0, 0, TILE, TILE, Palette.WILD[3])
			_px(img, cell, 3 + h % 9, 4 + (h / 9) % 8, 2, 1, Palette.WILD[2])
			if c == "G":
				_gate_posts(img, map, cell)
		"~":
			_pond(img, map, cell, h)
		",", "P", "C":
			_long_grass(img, cell, h)
			if c == "P":
				_pen_fence(img, map, cell, h)
		":":
			_long_grass(img, cell, h)
			# The old furrows, still there under the grass.
			_px(img, cell, 0, 5, TILE, 1, Palette.WILD[0])
			_px(img, cell, 0, 12, TILE, 1, Palette.WILD[0])
		"T":
			_grass(img, cell, h)
			_field_edge(img, map, cell)
		"f":
			_grass(img, cell, h)
			var flowers: Array[Color] = [Palette.PAPER[1], Palette.WARMTH[3], Palette.WARMTH[2]]
			for i: int in range(2):
				var k: int = (h >> (i * 4)) & 0xff
				_px(img, cell, 2 + k % 12, 2 + (k / 12) % 12, 2, 2, flowers[(k + i) % flowers.size()])
		"o":
			_grass(img, cell, h)
			_px(img, cell, 2, 5, 12, 9, Palette.STONE[0])
			_px(img, cell, 3, 4, 9, 4, Palette.STONE[1])
		"n":
			_grass(img, cell, h)
			_px(img, cell, 1, 6, 14, 3, Palette.WARMTH[0])  # the seat
			_px(img, cell, 2, 9, 2, 4, Palette.WARMTH[0])
			_px(img, cell, 12, 9, 2, 4, Palette.WARMTH[0])
		_:
			# Grass, and the ground under buildings and things (drawn over
			# by FarmDrawer).
			_grass(img, cell, h)


static func _grass(img: Image, cell: Vector2i, h: int) -> void:
	_px(img, cell, 0, 0, TILE, TILE, Palette.WILD[1])
	if h % 3 == 0:
		_px(img, cell, 3 + h % 9, 3 + (h / 9) % 9, 1, 2, Palette.WILD[2])
		_px(img, cell, 5 + h % 9, 4 + (h / 9) % 9, 1, 2, Palette.WILD[2])


## Long grass: walkable, taller and paler tufts.
static func _long_grass(img: Image, cell: Vector2i, h: int) -> void:
	_px(img, cell, 0, 0, TILE, TILE, Palette.WILD[1])
	for i: int in range(3):
		var k: int = (h >> (i * 3)) & 0x7f
		var at: Vector2i = Vector2i(1 + k % 13, 2 + (k / 13) % 10)
		_px(img, cell, at.x, at.y, 1, 4, Palette.WILD[2])
		_px(img, cell, at.x + 1, at.y + 1, 1, 3, Palette.WILD[3])


## The first field: short grass, with a line of worked earth round its edge.
static func _field_edge(img: Image, map: FarmMap, cell: Vector2i) -> void:
	var edge: Color = Palette.WARMTH[0]
	if map.char_at(cell + Vector2i.UP) != "T":
		_px(img, cell, 0, 0, TILE, 1, edge)
	if map.char_at(cell + Vector2i.DOWN) != "T":
		_px(img, cell, 0, TILE - 1, TILE, 1, edge)
	if map.char_at(cell + Vector2i.LEFT) != "T":
		_px(img, cell, 0, 0, 1, TILE, edge)
	if map.char_at(cell + Vector2i.RIGHT) != "T":
		_px(img, cell, TILE - 1, 0, 1, TILE, edge)


## The woods round the farm: dark crowns crowding each other.
static func _woods(img: Image, cell: Vector2i, h: int) -> void:
	_px(img, cell, 0, 0, TILE, TILE, Palette.WILD[0])
	var dark: Color = Palette.SHADOW[1]
	_px(img, cell, 2 + h % 6, 2 + (h / 6) % 6, 7, 5, dark)
	_px(img, cell, 3 + h % 6, 1 + (h / 6) % 6, 5, 2, Palette.WILD[1].darkened(0.25))


## Thicket: bramble and young trees, a dull cool green.
static func _thicket(img: Image, cell: Vector2i, h: int) -> void:
	var cool: Color = Palette.WILD[1].lerp(Palette.WATER[0], 0.25).darkened(0.2)
	_px(img, cell, 0, 0, TILE, TILE, cool)
	for i: int in range(3):
		var k: int = (h >> (i * 4)) & 0xff
		_px(img, cell, k % 12, (k / 12) % 12, 4, 4, Palette.WILD[0])
	var k2: int = (h >> 13) & 0xff
	_px(img, cell, 2 + k2 % 11, 2 + (k2 / 11) % 11, 2, 1, Palette.WILD[2].darkened(0.3))  # a bramble cane


## The hedge round the homestead: dense leaves, lit along the top.
static func _hedge(img: Image, map: FarmMap, cell: Vector2i, h: int) -> void:
	_px(img, cell, 0, 0, TILE, TILE, Palette.WILD[0].lerp(Palette.WILD[1], 0.4))
	_px(img, cell, h % 10, 3 + (h / 10) % 8, 5, 4, Palette.WILD[0])
	_px(img, cell, (h / 7) % 11, (h / 77) % 10, 3, 2, Palette.CROPS[0].darkened(0.35))
	if map.char_at(cell + Vector2i.UP) != "#":
		_px(img, cell, 0, 0, TILE, 2, Palette.CROPS[0].darkened(0.2))


## A gate in the hedge: a post where it meets the hedge.
static func _gate_posts(img: Image, map: FarmMap, cell: Vector2i) -> void:
	for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if map.char_at(cell + side) == "#":
			var x: int = 0 if side == Vector2i.LEFT else (TILE - 3 if side == Vector2i.RIGHT else 6)
			var y: int = 0 if side == Vector2i.UP else (TILE - 3 if side == Vector2i.DOWN else 2)
			var w: int = 3 if side.x != 0 else 4
			var hgt: int = 12 if side.x != 0 else 3
			_px(img, cell, x, y, w, hgt, Palette.WARMTH[1])


## The pond: deep water, a pale glint, a bank of earth where it meets land.
static func _pond(img: Image, map: FarmMap, cell: Vector2i, h: int) -> void:
	_px(img, cell, 0, 0, TILE, TILE, Palette.WATER[0])
	if h % 4 == 0:
		_px(img, cell, 3 + h % 8, 5 + (h / 8) % 6, 4, 1, Palette.WATER[1])
	var bank: Color = Palette.WARMTH[0].darkened(0.2)
	if map.char_at(cell + Vector2i.UP) != "~":
		_px(img, cell, 0, 0, TILE, 3, bank)
	if map.char_at(cell + Vector2i.DOWN) != "~":
		_px(img, cell, 0, TILE - 2, TILE, 2, bank)
	if map.char_at(cell + Vector2i.LEFT) != "~":
		_px(img, cell, 0, 0, 2, TILE, bank)
	if map.char_at(cell + Vector2i.RIGHT) != "~":
		_px(img, cell, TILE - 2, 0, 2, TILE, bank)


## The pen's fence, down: posts along its edge, some leaning, rails fallen.
static func _pen_fence(img: Image, map: FarmMap, cell: Vector2i, h: int) -> void:
	var post: Color = Palette.WARMTH[0]
	var outside: Array[Vector2i] = []
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if map.char_at(cell + side) != "P":
			outside.append(side)
	for side: Vector2i in outside:
		if side.y != 0:
			var y: int = 0 if side == Vector2i.UP else TILE - 3
			_px(img, cell, 1, y - 4 if y > 0 else 0, 2, 6, post)
			if h % 2 == 0:
				_px(img, cell, 3, y + 1, 9, 1, post)  # a rail, still up
			else:
				_px(img, cell, 4, y + 2, 8, 1, post.darkened(0.3))  # fallen
		else:
			var x: int = 0 if side == Vector2i.LEFT else TILE - 3
			_px(img, cell, x, 3, 2, 6 + h % 3, post)
