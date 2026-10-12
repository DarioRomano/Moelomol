class_name FarmMap
extends RefCounted
## The farm's ground, one character per 16 px tile (FarmLayout.tile_rows()):
## what is solid, what can be farmed, and where things are. Keys are those of
## docs/design/base.md; the parcel digits 1-6 and the old track (`-`) are
## thicket, which cannot be walked into until its parcel opens (Q38; not
## built yet).

const TILE: float = 16.0
## Characters that block walking.
const SOLID: String = "t123456-#HDBbs~nALCom"
const THICKET: String = "123456-"
## The first field: the only ground that can be tilled from the start (the
## old fields, `:`, need the Clear spell first; not built yet).
const TILLABLE: String = "T"

var rows: Array[String] = []
var size: Vector2i


func _init(p_rows: Array[String]) -> void:
	rows = p_rows
	size = Vector2i(rows[0].length(), rows.size())


static func make_farm() -> FarmMap:
	return FarmMap.new(FarmLayout.tile_rows())


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## The character at a tile; outside the farm, woods.
func char_at(cell: Vector2i) -> String:
	return rows[cell.y][cell.x] if contains(cell) else "t"


func is_solid(cell: Vector2i) -> bool:
	return SOLID.contains(char_at(cell))


## Every tile holding character `c`, row by row.
func cells_of(c: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y: int in range(size.y):
		var at: int = rows[y].find(c)
		while at >= 0:
			found.append(Vector2i(at, y))
			at = rows[y].find(c, at + 1)
	return found


## The smallest rectangle of tiles holding every `c` (a building, the pond).
func bounds_of(c: String) -> Rect2i:
	var cells: Array[Vector2i] = cells_of(c)
	if cells.is_empty():
		return Rect2i()
	var r: Rect2i = Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		r = r.expand(cell).expand(cell + Vector2i.ONE)
	return r
