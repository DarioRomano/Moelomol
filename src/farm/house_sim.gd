class_name HouseSim
extends RefCounted
## The farmhouse inside (base.md; ADR-0016: its own place) as a deterministic
## 60 Hz simulation: walking, the bed, the seed tin, and the door out to the
## farm. No farming spells here and no combat.
##
## Events (cleared each step):
##   {"type": "slept", "day": int}           the bed: the next 6:00, Mana full
##   {"type": "seed_tin", "items": Dictionary}  the starting seeds taken (Q25)
##   {"type": "seed_tin_empty"}
##   {"type": "exit", "to": &"farm"}          out of the door
##   {"type": "stroke", "position": Vector2}  the cat, stroked

const TILE: float = FarmSim.TILE
const TICK_SECONDS: float = FarmSim.TICK_SECONDS
const PLAYER_SPEED: float = FarmSim.PLAYER_SPEED
const PLAYER_RADIUS: float = FarmSim.PLAYER_RADIUS
const TARGET_REACH: float = FarmSim.TARGET_REACH

var map: FarmMap = FarmMap.new(HouseLayout.ROWS, HouseLayout.SOLID)
var clock: GameClock = GameClock.new()
var mana: Mana = Mana.new()
var inventory: Inventory = Inventory.new()
var time_scale: float = 1.0
var player_position: Vector2
var previous_position: Vector2
var facing: Vector2 = Vector2.DOWN
## True once the seed tin's seeds are in the bag (the house remembers it).
var tin_taken: bool = false
var events: Array[Dictionary] = []
## Where the cat sits in the house, or INF (the scene sets it).
var cat_position: Vector2 = Vector2.INF
var cat_purring: bool = false
var cat_curled: bool = false
## Waking: beside the bed, at its foot. Arriving from the farm: on the rug,
## facing into the room.
var bed_position: Vector2
var door_position: Vector2
var exit_rect: Rect2


func _init() -> void:
	var bed: Rect2i = map.bounds_of("B")
	bed_position = Vector2((bed.end.x + 0.5) * TILE, (bed.position.y + bed.size.y / 2.0) * TILE)
	var door: Rect2i = map.bounds_of("D")
	door_position = Vector2((door.position.x + door.size.x / 2.0) * TILE, (door.position.y - 0.5) * TILE)
	# The lower half of the door's tiles: stepping into the doorway goes out.
	exit_rect = Rect2(door.position.x * TILE, (door.position.y + 0.5) * TILE, door.size.x * TILE, TILE / 2.0)
	place_player(bed_position, Vector2.DOWN)


func place_player(at: Vector2, towards: Vector2) -> void:
	player_position = at
	previous_position = at
	facing = towards


func bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map.size) * TILE)


func cell_at(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / TILE), floori(at.y / TILE))


## The tile the player faces: what Interact uses.
func target_cell() -> Vector2i:
	return cell_at(player_position + facing.normalized() * TARGET_REACH)


## What the faced tile is, for the prompt: &"bed", &"seed_tin" or &"".
func target_kind() -> StringName:
	match map.char_at(target_cell()):
		"B":
			return &"bed"
		"u":
			return &"seed_tin"
	return &""


func step(input: FarmInput) -> void:
	events.clear()
	previous_position = player_position
	clock.advance(TICK_SECONDS * time_scale)
	if input.interact_pressed:
		interact()
		return
	_walk(input.move)
	if exit_rect.has_point(player_position):
		events.append({"type": "exit", "to": &"farm"})


func interact() -> void:
	if cat_position != Vector2.INF \
			and (player_position + facing.normalized() * TARGET_REACH).distance_to(cat_position) < FarmSim.CAT_REACH:
		events.append({"type": "stroke", "position": cat_position})
		return
	match target_kind():
		&"bed":
			sleep()
		&"seed_tin":
			if tin_taken:
				events.append({"type": "seed_tin_empty"})
				return
			tin_taken = true
			for seed_id: StringName in FarmSim.STARTING_SEEDS:
				inventory.add(seed_id, FarmSim.STARTING_SEEDS[seed_id])
			events.append({"type": "seed_tin", "items": FarmSim.STARTING_SEEDS.duplicate()})


## The bed, at any time: the next 6:00, Mana full, up beside the bed. The
## farm's crops grow when the player next goes out (FarmSim.catch_up).
func sleep() -> void:
	events.append({"type": "slept", "day": clock.day()})
	clock.sleep_until_morning()
	mana.refill()
	place_player(bed_position, Vector2.DOWN)


func _walk(move: Vector2) -> void:
	var direction: Vector2 = move.limit_length(1.0)
	if direction.length() > 0.1:
		facing = direction.normalized()
	var delta: Vector2 = direction * PLAYER_SPEED * TICK_SECONDS
	for axis: Vector2 in [Vector2(delta.x, 0), Vector2(0, delta.y)]:
		var to: Vector2 = player_position + axis
		if _fits(to):
			player_position = to


func _fits(at: Vector2) -> bool:
	if not bounds().grow(-PLAYER_RADIUS).has_point(at):
		return false
	var low: Vector2i = cell_at(at - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))
	var high: Vector2i = cell_at(at + Vector2(PLAYER_RADIUS, PLAYER_RADIUS))
	for y: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			if not map.is_solid(Vector2i(x, y)):
				continue
			var rect: Rect2 = Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			var closest: Vector2 = Vector2(clampf(at.x, rect.position.x, rect.end.x), clampf(at.y, rect.position.y, rect.end.y))
			if closest.distance_to(at) < PLAYER_RADIUS:
				return false
	return true


## What the house remembers between visits and in the save.
func export_state() -> Dictionary:
	return {"tin_taken": tin_taken}


func apply_state(state: Dictionary) -> void:
	tin_taken = bool(state.get("tin_taken", false))
