class_name FarmLayout
extends RefCounted
## The farm's layout as accepted by the lead (2026-10-11; docs/design/base.md):
## the whole farm, one character per 4 x 4 tiles, and the homestead, one
## character per 2 x 2 tiles. Kept in code so exports carry them; tests check
## they still match the design doc's maps (docs/design/images/estate.txt and
## base.txt).
##
## tile_rows() expands both into one character per 16 px tile (FarmMap).

const ESTATE: Array[String] = [
	"tttttttttttttttttttttttttttttttttttttttt",
	"t55555555566666666666666666666444444444t",
	"t55555555566666666666666666666444444444t",
	"t55555555566666666666666666666444444444t",
	"t55555555566666666666666666666444444444t",
	"t5555555551111111-111111111111444444444t",
	"t5555555551111111-111111111111444444444t",
	"t5555555551111111-111111111111444444444t",
	"t5555555551111111-111111111111444444444t",
	"t5555555551111111-111111111111444444444t",
	"t5555555551111111-111111111111444444444t",
	"t5555555551111111-111111111111444444444t",
	"t3333333333333111-111111112222222222222t",
	"t3333333333333111-111111112222222222222t",
	"t3333333333333111-111111112222222222222t",
	"t3333333333333hhhhhhhhhhhh2222222222222t",
	"t3333333333333hhhhhhhhhhhh2222222222222t",
	"t3333333333333hhhhhhhhhhhh2222222222222t",
	"t3333333333333hhhhhhhhhhhh2222222222222t",
	"t3333333333333hhhhhhhhhhhh2222222222222t",
	"t3333333333333hhhhhhhhhhhh2222222222222t",
	"t3333333333333hhhhhhhhhhhh2222222222222t",
	"t3333333333333hhhhhhhhhhhh2222222222222t",
	"tttttttttttttttttttGGttttttttttttttttttt",
]

const HOMESTEAD: Array[String] = [
	"#######GG###############",
	"#,,....=.HHHHH...~~~~.,#",
	"#.BBB..=.HHHHHA.~~~~~,,#",
	"#.BBB..=.HHDHH..~~~~~,,#",
	"#.BbB..=...=L...~~~~.f,#",
	"#.s============.n.ff.f,#",
	"#,,,:::TTTT=::::.fffff,#",
	"#C,,:::TTTT=::::.ffoff,#",
	"#PPP:::TTTT=::::.fffff,#",
	"#PPP:::::::=::::..fff,,#",
	"#PPP:::::::=::::...ff,,#",
	"#,,,:::::::============G",
	"G===========.....,,,,,,#",
	"#,,,,,,....=m....,,,,,,#",
	"###########GG###########",
]

const ESTATE_SCALE: int = 4  # tiles per estate character
const HOMESTEAD_SCALE: int = 2  # tiles per homestead character
## The homestead's top-left tile. The estate gives it 48 x 32 tiles (the `h`
## squares); the homestead map is 48 x 30, so it sits at the bottom of that
## space, its south hedge against the woods, and the two rows above it are
## the great fields' thicket.
const HOMESTEAD_ORIGIN: Vector2i = Vector2i(56, 62)
## The lane out to Millbrook: through the woods below the homestead's south
## gate (the estate's `G`), the same 4 tiles wide as the gate.
const LANE: Rect2i = Rect2i(78, 92, 4, 4)


## The whole farm, one character per tile (160 x 96): the estate's woods and
## parcels (thicket until opened; the old track is under it too), the
## homestead over it, and the lane.
static func tile_rows() -> Array[String]:
	var grid: Array[PackedStringArray] = []
	for y: int in range(ESTATE.size() * ESTATE_SCALE):
		var row: PackedStringArray = PackedStringArray()
		for x: int in range(ESTATE[0].length() * ESTATE_SCALE):
			var c: String = ESTATE[y / ESTATE_SCALE][x / ESTATE_SCALE]
			match c:
				"h":
					c = "1"  # above the homestead's hedge: the great fields
				"G":
					c = "t"  # the woods, until the lane is cut through below
			row.append(c)
		grid.append(row)
	for y: int in range(HOMESTEAD.size() * HOMESTEAD_SCALE):
		for x: int in range(HOMESTEAD[0].length() * HOMESTEAD_SCALE):
			grid[HOMESTEAD_ORIGIN.y + y][HOMESTEAD_ORIGIN.x + x] = HOMESTEAD[y / HOMESTEAD_SCALE][x / HOMESTEAD_SCALE]
	for y: int in range(LANE.position.y, LANE.end.y):
		for x: int in range(LANE.position.x, LANE.end.x):
			grid[y][x] = "="
	var rows: Array[String] = []
	for row: PackedStringArray in grid:
		rows.append("".join(row))
	return rows


# --- The great fields (parcel 1; Q42 A, accepted 2026-11-06) --------------------------

## What is inside the great fields' thicket, one character per estate square
## (4 x 4 tiles), for estate columns 10-29 and rows 5-14; spaces are other
## parcels. `:` old field under long grass, `-` the old track, `h`
## hedgerow, `=` a gap in a hedgerow, `F` the ruined field shelter.
const GREAT_FIELDS: Array[String] = [
	":::::::-:::::h::::::",
	":::::::-:::::=::::::",
	"hhhhhhh-hhhhhhhhhhhh",
	"::::::F-:::::h::::::",
	":::::::-:::::=::::::",
	"hhhhhhh-hhhhhhhhhhhh",
	":::::::-:::::=::::::",
	"    :::-::::::::    ",
	"    :::-::::::::    ",
	"    :::-::::::::    ",
]
const GREAT_FIELDS_ORIGIN: Vector2i = Vector2i(10, 5)  # its top-left estate square
## The old track, moved 2 tiles east of its estate column to meet the north
## gate (Q42): 4 tiles wide, like the gate.
const TRACK_X: int = 70
const TRACK_WIDTH: int = 4
## Grist's heart opens the great fields (Q38 C, base.md).
const PARCEL_HEARTS: Dictionary = {1: &"grist_heart"}


## The tile characters the great fields become when opened: every tile of
## parcel 1's thicket (`1` and the old track `-`) gets one. Hedgerows are a
## 1-tile hedge (`r`) through their square, with long grass (`,`) either
## side; the shelter is 3 x 2 tiles (`F`); the track is path (`=`).
static func opened_tiles(parcel: int, rows: Array[String]) -> Dictionary:
	var out: Dictionary = {}  # Vector2i -> String
	if parcel != 1:
		return out
	for y: int in range(rows.size()):
		for x: int in range(rows[y].length()):
			var c: String = rows[y][x]
			if c != "1" and c != "-":
				continue
			out[Vector2i(x, y)] = _great_fields_tile(Vector2i(x, y))
	return out


static func _sketch_at(square: Vector2i) -> String:
	var r: Vector2i = square - GREAT_FIELDS_ORIGIN
	if r.y < 0 or r.y >= GREAT_FIELDS.size() or r.x < 0 or r.x >= GREAT_FIELDS[0].length():
		return " "
	return GREAT_FIELDS[r.y][r.x]


static func _great_fields_tile(tile: Vector2i) -> String:
	if tile.x >= TRACK_X and tile.x < TRACK_X + TRACK_WIDTH:
		return "="  # the track, all the way to the north gate
	var square: Vector2i = Vector2i(tile.x / ESTATE_SCALE, tile.y / ESTATE_SCALE)
	var local: Vector2i = Vector2i(tile.x % ESTATE_SCALE, tile.y % ESTATE_SCALE)
	var c: String = _sketch_at(square)
	match c:
		":":
			return ":"
		"-":
			return ":"  # the sketch's track column, west of where the track now runs
		"=":
			return ","
		"F":
			return "F" if local.x < 3 and local.y >= 1 and local.y < 3 else ","
		"h":
			var across: bool = _sketch_at(square + Vector2i.LEFT) in ["h", "-", "="] \
				or _sketch_at(square + Vector2i.RIGHT) in ["h", "-", "="]
			var down: bool = _sketch_at(square + Vector2i.UP) in ["h", "="] \
				or _sketch_at(square + Vector2i.DOWN) in ["h", "="]
			if (across and local.y == 1) or (down and local.x == 1):
				return "r"
			return ","
	# Outside the sketch: the two rows above the homestead's hedge.
	return ","
