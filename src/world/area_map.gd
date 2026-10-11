class_name AreaMap
extends RefCounted
## An area's layout from its accepted text map (docs/design/world.md,
## area-millbrook.md): one character per cell of 2 x 2 tiles (32 layout px).
## Says which cells are solid, where the numbered places are, and turns cells
## into layout positions. Floodwater (`w`) is solid until drained.

const CELL: float = 32.0  # layout px: 2 x 2 tiles of 16 px
## Characters that block walking (`world.md` keys in area-millbrook.md).
const SOLID: String = "tH#KSM~PcWeaXih"
const FLOODWATER: String = "w"
## Characters that mark the doc's numbered places; the ground under them is
## walkable.
const MARKERS: String = "123456789ABCDEFG"

var rows: Array[String] = []
var size: Vector2i  # in cells
var drained: bool = false  # floodwater gone (Millbrook's objective)
var markers: Dictionary = {}  # marker character -> Vector2i cell


func _init(p_rows: Array[String]) -> void:
	rows = p_rows
	size = Vector2i(rows[0].length(), rows.size())
	for y: int in range(size.y):
		for x: int in range(size.x):
			var c: String = rows[y][x]
			if MARKERS.contains(c):
				markers[c] = Vector2i(x, y)


## The whole map in layout px.
func rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size) * CELL)


func char_at(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return "t"  # outside the map: woods
	return rows[cell.y][cell.x]


func is_solid(cell: Vector2i) -> bool:
	var c: String = char_at(cell)
	if FLOODWATER.contains(c):
		return not drained
	return SOLID.contains(c)


## The cell containing a layout position.
static func cell_of(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL), floori(at.y / CELL))


## The centre of a cell in layout px.
static func centre_of(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL


static func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL))


## Every cell holding character `c`.
func cells_of(c: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y: int in range(size.y):
		for x: int in range(size.x):
			if rows[y][x] == c:
				found.append(Vector2i(x, y))
	return found


## Solid cell rectangles touching a circle at `at` of radius r (collision).
func solid_rects_near(at: Vector2, r: float) -> Array[Rect2]:
	var found: Array[Rect2] = []
	var low: Vector2i = cell_of(at - Vector2(r, r))
	var high: Vector2i = cell_of(at + Vector2(r, r))
	for y: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			if is_solid(cell):
				found.append(cell_rect(cell))
	return found
