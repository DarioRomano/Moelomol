class_name HouseLayout
extends RefCounted
## The farmhouse inside (docs/design/base.md, "The farmhouse inside"), one
## character per 16 px tile; layout accepted by the lead on 2026-11-06. One
## room, 12 x 8 tiles inside its walls, the door at the bottom centre.
##
## Keys: `#` wall, `^` the back wall's face, `w` window, `h` the cup on its
## hook, `B` bed, `S` window seat, `O` stove, `k` the cat's basket, `T`
## table, `c` chair, `u` cupboard (the seed tin on it), `_` rug, `D` door,
## `.` floor.

const ROWS: Array[String] = [
	"##############",
	"#^^^^ww^ww^h^#",
	"#BB..SS....OO#",
	"#BB........OO#",
	"#BB.......k..#",
	"#....cTTc....#",
	"#.....TT.....#",
	"#u...........#",
	"#u....__.....#",
	"######DD######",
]

## What blocks walking: walls and furniture. The rug, the floor and the
## door's tiles do not (walking down into the door goes out).
const SOLID: String = "#^whBSOkTcu"
