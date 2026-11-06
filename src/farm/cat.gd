class_name Cat
extends RefCounted
## The cat (ADR-0010; Q41 A, decided 2026-11-06): a cat of places. It is
## always in one of its places (base.md, "The pet's places"), chosen by the
## time of day, and it moves only while the player can see neither the place
## it leaves nor the place it goes to, so it is simply there when the
## player looks. Interact while facing it strokes it: a purr on the
## controller, its eyes closing, no text (story.md rule 2).
##
## After a fall it is curled on the blanket when the player wakes (Q36).
## The impossible moments (story.md) come later, with the story's stages.

const BASKET: StringName = &"basket"  # by the stove, the house
const WINDOW_SEAT: StringName = &"window_seat"  # the house
const BLANKET: StringName = &"blanket"  # on the bed, the house: only after a fall
const PORCH: StringName = &"porch_step"  # the farm, by the farmhouse door
const APPLE_TREE: StringName = &"apple_tree"  # the farm
const BENCH: StringName = &"bench"  # the farm, by the pond, facing the sunset
const ROOF: StringName = &"workshop_roof"  # the farm

const HOUSE_PLACES: Array[StringName] = [BASKET, WINDOW_SEAT, BLANKET]
const FARM_PLACES: Array[StringName] = [PORCH, APPLE_TREE, BENCH, ROOF]
## How long the eyes stay closed after a stroke.
const PURR_TICKS: int = 90

var place: StringName = BASKET
var purr_ticks: int = 0


## Where the cat wants to be at `minute` (of the day) on `day`: the basket
## in the early morning, the porch step or the apple tree by day (the
## workshop roof some afternoons), the bench at dusk, the window seat at
## night. Even and odd days differ, so its days are not all the same.
static func wanted_at(minute: float, day: int) -> StringName:
	var hour: float = minute / 60.0
	if hour >= 6.0 and hour < 8.0:
		return BASKET
	if hour >= 8.0 and hour < 12.0:
		return PORCH if day % 2 == 0 else APPLE_TREE
	if hour >= 12.0 and hour < 17.0:
		return APPLE_TREE if day % 2 == 0 else ROOF
	if hour >= 17.0 and hour < 20.5:
		return BENCH
	return WINDOW_SEAT


static func in_house(p: StringName) -> bool:
	return p in HOUSE_PLACES


## Moves to where it wants to be, but only unseen: `seen` tells whether the
## player can see a place right now. Returns true if it moved.
func settle(clock: GameClock, seen: Callable) -> bool:
	if purr_ticks > 0:
		purr_ticks -= 1
	var wanted: StringName = wanted_at(clock.minute(), clock.day())
	if wanted == place:
		return false
	if bool(seen.call(place)) or bool(seen.call(wanted)):
		return false
	place = wanted
	return true


func stroke() -> void:
	purr_ticks = PURR_TICKS


## Where it sits at the farm (its feet, layout px), from the farm's map.
static func farm_position(p: StringName, map: FarmMap) -> Vector2:
	var tile: float = FarmMap.TILE
	match p:
		PORCH:
			# The step beside the farmhouse door, just left of it.
			var door: Rect2i = map.bounds_of("D")
			return Vector2((door.position.x - 0.5) * tile, (door.end.y + 0.4) * tile)
		APPLE_TREE:
			var tree: Rect2i = map.bounds_of("A")
			return Vector2((tree.position.x + 1.6) * tile, (tree.end.y + 0.3) * tile)
		BENCH:
			# Beside where the player sits, on the bench (base.md).
			var bench: Rect2i = map.bounds_of("n")
			return Vector2((bench.position.x + 1.4) * tile, (bench.position.y + 1.0) * tile)
		ROOF:
			var shop: Rect2i = map.bounds_of("B").merge(map.bounds_of("b"))
			return Vector2((shop.position.x + shop.size.x * 0.7) * tile, (shop.position.y + 0.6) * tile)
	return Vector2.INF


## Where it sits in the farmhouse (its feet, layout px).
static func house_position(p: StringName, map: FarmMap) -> Vector2:
	var tile: float = HouseSim.TILE
	match p:
		BASKET:
			var basket: Rect2i = map.bounds_of("k")
			return Vector2((basket.position.x + 0.5) * tile, (basket.position.y + 0.8) * tile)
		WINDOW_SEAT:
			var seat: Rect2i = map.bounds_of("S")
			return Vector2((seat.position.x + 1.4) * tile, (seat.position.y + 0.6) * tile)
		BLANKET:
			var bed: Rect2i = map.bounds_of("B")
			return Vector2((bed.position.x + 1.0) * tile, (bed.position.y + 2.2) * tile)
	return Vector2.INF


func to_dict() -> Dictionary:
	return {"place": String(place)}


func load_dict(d: Dictionary) -> void:
	var p: StringName = StringName(str(d.get("place", "")))
	if p in HOUSE_PLACES or p in FARM_PLACES:
		place = p
