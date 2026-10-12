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
