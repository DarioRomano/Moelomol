class_name Palette
extends RefCounted
## The draft shared palette from docs/design/art-direction.md.
## Placeholder art and debug scenes draw only with these colours.
## Changing a colour here is an art-direction change: update the doc too.

const SHADOW: Array[Color] = [Color("#1b1e2b"), Color("#2a2f40"), Color("#3d4459")]
const STONE: Array[Color] = [Color("#5a6377"), Color("#7d869a"), Color("#a9b0bf")]
const PAPER: Array[Color] = [Color("#d9d6cc"), Color("#f0ece1")]
const WILD: Array[Color] = [Color("#2f3b2e"), Color("#47573f"), Color("#6b7a57"), Color("#94a07a")]
const CHANGED: Array[Color] = [Color("#4a3f52"), Color("#6e5b73"), Color("#8f8a6a")]
const WATER: Array[Color] = [Color("#2e5566"), Color("#4f8296")]
const WARMTH: Array[Color] = [Color("#7a4a2b"), Color("#b8733a"), Color("#e0a95b"), Color("#f3d58a")]
const CROPS: Array[Color] = [Color("#5f8f3e"), Color("#8cbf4a")]
const DANGER: Array[Color] = [Color("#8c3b3b"), Color("#c2584a")]
const EXTREMES: Array[Color] = [Color("#0e0f16"), Color("#ffffff")]

const GROUP_NAMES: Array[String] = [
	"shadow", "stone", "paper", "wild", "changed",
	"water", "warmth", "crops", "danger", "extremes",
]


## Every colour group in the order of GROUP_NAMES.
static func groups() -> Array[Array]:
	return [SHADOW, STONE, PAPER, WILD, CHANGED, WATER, WARMTH, CROPS, DANGER, EXTREMES]


## All colours, flattened, in group order.
static func all_colours() -> Array[Color]:
	var result: Array[Color] = []
	for group: Array in groups():
		for colour: Color in group:
			result.append(colour)
	return result
