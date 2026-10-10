class_name FarmSim
extends RefCounted
## The base as a deterministic simulation, like CombatSim: call step() once
## per fixed 60 Hz tick with that tick's input. Holds the clock, the plot,
## the inventory and the player (docs/design/farming.md). The scene only
## reads input and draws; tests drive step() directly.
##
## The layout is a test farm, not the base's design (level layout is the
## lead's decision).

const TILE: float = 16.0
const TICK_SECONDS: float = 1.0 / 60.0
const PLAYER_SPEED: float = 80.0  # layout px per second, as in combat
const PLAYER_RADIUS: float = 6.0
## The tile acted on is the one under this point in front of the feet.
const TARGET_REACH: float = 12.0
const TOOL_USE_MS: int = 250  # the player stands still while a tool is used

const HOE: StringName = &"hoe"
const WATERING_CAN: StringName = &"watering_can"
const TOOL_NAMES: Dictionary = {HOE: "Hoe", WATERING_CAN: "Watering can"}

## What the starting seed tin holds (Q25, working assumption A).
const STARTING_SEEDS: Dictionary = {&"catmint_seeds": 6, &"radish_seeds": 6}

var origin: Vector2  # layout px of the top-left of tile (0, 0)
var plot: FarmPlot
var clock: GameClock = GameClock.new()
var inventory: Inventory = Inventory.new()
var tools: Array[StringName] = [HOE, WATERING_CAN]
var tool_index: int = 0

var player_position: Vector2
var previous_position: Vector2
var facing: Vector2 = Vector2.DOWN
var busy: int = 0  # ticks left of a tool use
var last_action: StringName = &""  # for drawing the tool swing

## Solid things the player cannot walk through, in layout px.
var solids: Array[Rect2] = []
var door_cell: Vector2i
var wake_position: Vector2
## Real seconds the clock advances per real second (a developer key speeds
## it up).
var time_scale: float = 1.0

## What happened during the last step, for feedback. Each has "type".
var events: Array[Dictionary] = []


func _init(p_origin: Vector2, grid: Vector2i) -> void:
	origin = p_origin
	plot = FarmPlot.new(grid)
	for seed_id: StringName in STARTING_SEEDS:
		inventory.add(seed_id, STARTING_SEEDS[seed_id])
		tools.append(seed_id)


## The test farm: a 38 x 20 tile field with a farmhouse (its door is the
## bed: interact to sleep) and a short path. Fits 640 x 360 with a border.
static func make_test_farm() -> FarmSim:
	var sim: FarmSim = FarmSim.new(Vector2(16, 20), Vector2i(38, 20))
	var house: Rect2i = Rect2i(2, 1, 5, 4)
	sim.plot.block(house)
	sim.solids.append(sim.cell_rect(house))
	sim.door_cell = Vector2i(4, 4)
	sim.plot.block(Rect2i(4, 5, 1, 3))  # the path from the door
	sim.wake_position = sim.cell_centre(Vector2i(4, 5))
	sim.player_position = sim.wake_position
	sim.previous_position = sim.wake_position
	return sim


func cell_centre(cell: Vector2i) -> Vector2:
	return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * TILE


func cell_rect(cells: Rect2i) -> Rect2:
	return Rect2(origin + Vector2(cells.position) * TILE, Vector2(cells.size) * TILE)


func cell_at(at: Vector2) -> Vector2i:
	return Vector2i(((at - origin) / TILE).floor())


func bounds() -> Rect2:
	return Rect2(origin, Vector2(plot.size) * TILE)


## The tile the player acts on: the one in front of their feet.
func target_cell() -> Vector2i:
	return cell_at(player_position + facing * TARGET_REACH)


func tool() -> StringName:
	return tools[tool_index]


static func tool_use_ticks() -> int:
	return roundi(TOOL_USE_MS / 1000.0 / TICK_SECONDS)


func step(input: FarmInput) -> void:
	events.clear()
	previous_position = player_position
	if clock.advance(TICK_SECONDS * time_scale):
		_fall_asleep()
		return
	if input.tool_next_pressed or input.tool_prev_pressed:
		var by: int = (1 if input.tool_next_pressed else 0) - (1 if input.tool_prev_pressed else 0)
		tool_index = posmod(tool_index + by, tools.size())
		events.append({"type": "tool", "tool": tool()})
	if busy > 0:
		busy -= 1
		return
	if input.use_pressed:
		_use_tool()
		return
	if input.interact_pressed:
		_interact()
		return
	_walk(input.move)


func _walk(move: Vector2) -> void:
	var direction: Vector2 = move.limit_length(1.0)
	if direction.length() > 0.1:
		facing = direction.normalized()
	var delta: Vector2 = direction * PLAYER_SPEED * TICK_SECONDS
	# One axis at a time, so the player slides along walls.
	for axis: Vector2 in [Vector2(delta.x, 0), Vector2(0, delta.y)]:
		var to: Vector2 = player_position + axis
		if _fits(to):
			player_position = to


func _fits(at: Vector2) -> bool:
	if not bounds().grow(-PLAYER_RADIUS).has_point(at):
		return false
	for rect: Rect2 in solids:
		var closest: Vector2 = Vector2(clampf(at.x, rect.position.x, rect.end.x), clampf(at.y, rect.position.y, rect.end.y))
		if closest.distance_to(at) < PLAYER_RADIUS:
			return false
	return true


func _use_tool() -> void:
	var cell: Vector2i = target_cell()
	var done: bool = false
	var kind: String = ""
	match tool():
		HOE:
			done = plot.till(cell)
			kind = "till"
		WATERING_CAN:
			done = plot.water(cell)
			kind = "water"
		_:
			var crop: CropKind = CropKind.from_seed(tool())
			if inventory.count(tool()) == 0:
				events.append({"type": "no_seeds", "seed": tool()})
				return
			if crop != null and plot.plant(cell, crop.id):
				inventory.take(tool())
				done = true
			kind = "plant"
	busy = tool_use_ticks()
	last_action = tool()
	if done:
		events.append({"type": kind, "cell": cell, "position": cell_centre(cell)})
	else:
		events.append({"type": "nothing", "cell": cell})


func _interact() -> void:
	var cell: Vector2i = target_cell()
	if cell == door_cell:
		sleep()
		return
	var items: Dictionary = plot.harvest(cell)
	if items.is_empty():
		return
	for item: StringName in items:
		inventory.add(item, items[item])
	busy = tool_use_ticks()
	last_action = &"harvest"
	events.append({"type": "harvest", "cell": cell, "items": items, "position": cell_centre(cell)})


## Going to bed (any time, Q22): the next day starts at 6:00.
func sleep() -> void:
	events.append({"type": "slept", "day": clock.day})
	_start_next_day()


## 2:00: the player falls asleep where they are and wakes at home (Q22,
## working assumption A: no penalty).
func _fall_asleep() -> void:
	events.append({"type": "passed_out", "day": clock.day})
	_start_next_day()


func _start_next_day() -> void:
	var grew: int = plot.new_day()
	clock.next_day()
	player_position = wake_position
	previous_position = wake_position
	facing = Vector2.DOWN
	busy = 0
	events.append({"type": "new_day", "day": clock.day, "grew": grew})


## Every crop planted on the plot, as cells.
func planted_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(plot.size.y):
		for x: int in range(plot.size.x):
			if plot.crop_at(Vector2i(x, y)) != &"":
				cells.append(Vector2i(x, y))
	return cells


static func item_name(item: StringName) -> String:
	if TOOL_NAMES.has(item):
		return TOOL_NAMES[item]
	var crop: CropKind = CropKind.from_seed(item)
	if crop != null:
		return "%s seeds" % crop.display_name
	crop = CropKind.of(item)
	return crop.display_name if crop != null else String(item)
