class_name FarmSim
extends RefCounted
## The base as a deterministic simulation, like CombatSim: call step() once
## per fixed 60 Hz tick with that tick's input. Holds the clock, the plot,
## the inventory, Mana and the player (docs/design/farming.md). All farming
## is magic (Q27): tilling, watering and sowing are spells that cost Mana;
## harvesting is by hand. The scene only
## reads input and draws; tests drive step() directly.
##
## Two layouts: make_farm() is the farm as accepted (docs/design/base.md,
## FarmMap); make_test_farm() is the small test field the farming rules were
## first built on, kept for rule tests and the review renders of spells.

const TILE: float = 16.0
const TICK_SECONDS: float = 1.0 / 60.0
const PLAYER_SPEED: float = 80.0  # layout px per second, as in combat
const PLAYER_RADIUS: float = 6.0
## The tile acted on is the one under this point in front of the feet.
const TARGET_REACH: float = 12.0
const CAST_MS: int = 250  # the player stands still while casting or picking

## Farming is magic (Q27, decided 2026-10-10): every farming action is a
## spell that costs Mana. Sowing has one entry per seed kind, keyed by the
## seed item. Mana costs are starting values.
const TILL: StringName = &"till"
const WATER: StringName = &"water"
const TILL_MANA: float = 2.0
const SOW_MANA: float = 1.0
const SPELL_NAMES: Dictionary = {TILL: "Till", WATER: "Water"}

## The watering spell's tiers (Q23): areas grow with farming upgrades; the
## final tier makes it rain, which waters the whole farm until the next 6:00.
## size = tiles across x tiles forward; ZERO for rain.
const WATER_TIERS: Array[Dictionary] = [
	{"name": "Water", "size": Vector2i(2, 2), "mana": 4.0},
	{"name": "Water II", "size": Vector2i(3, 3), "mana": 8.0},
	{"name": "Water III", "size": Vector2i(5, 5), "mana": 16.0},
	{"name": "Rain", "size": Vector2i.ZERO, "mana": 30.0},
]

## Things brought home from the areas, by name.
const ITEM_NAMES: Dictionary = {&"sluice_crank": "Sluice crank", &"grist_heart": "Grist's heart", &"tusk": "Tusk"}

## What the starting seed tin holds (Q25).
const STARTING_SEEDS: Dictionary = {&"catmint_seeds": 6, &"radish_seeds": 6}

var origin: Vector2  # layout px of the top-left of tile (0, 0)
var plot: FarmPlot
var clock: GameClock = GameClock.new()
var inventory: Inventory = Inventory.new()
var mana: Mana = Mana.new()
var spells: Array[StringName] = [TILL, WATER]
var spell_index: int = 0
## Which watering tier the player has (upgrades unlock the next; until the
## upgrade system exists, a developer key cycles it).
var water_tier: int = 0
var raining: bool = false  # until the next 6:00

var player_position: Vector2
var previous_position: Vector2
var facing: Vector2 = Vector2.DOWN
var busy: int = 0  # ticks left of a cast or a harvest
var last_action: StringName = &""  # for drawing the cast

## Solid things the player cannot walk through, in layout px (the test
## field's house; the farm's are in its map).
var solids: Array[Rect2] = []
## The farm's ground (make_farm); null on the test field.
var map: FarmMap = null
var door_cell: Vector2i
var wake_position: Vector2
## Where the player arrives from Millbrook: the top of the lane below the
## south gate (ADR-0016).
var gate_position: Vector2
## Exits: {"id": StringName, "rect": Rect2}. Walking into one reports
## {"type": "exit", "to": id} once.
var exits: Array[Dictionary] = []
var _in_exit: StringName = &""
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
		spells.append(seed_id)


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


## The farm as accepted (docs/design/base.md): 160 x 96 tiles, the homestead
## at the bottom centre. Only the first field can be tilled; the door of the
## farmhouse is the bed until the house has an inside (base.md, "Built later",
## step 2). The player starts in front of the door.
static func make_farm() -> FarmSim:
	var farm_map: FarmMap = FarmMap.make_farm()
	var sim: FarmSim = FarmSim.new(Vector2.ZERO, farm_map.size)
	sim.map = farm_map
	for y: int in range(farm_map.size.y):
		for x: int in range(farm_map.size.x):
			if not FarmMap.TILLABLE.contains(farm_map.rows[y][x]):
				sim.plot.block(Rect2i(x, y, 1, 1))
	var door: Rect2i = farm_map.bounds_of("D")
	sim.door_cell = door.position
	# In front of the door, between its two tiles.
	sim.wake_position = Vector2((door.position.x + door.size.x / 2.0) * TILE, (door.end.y + 0.5) * TILE)
	var lane: Rect2i = FarmLayout.LANE
	sim.gate_position = Vector2((lane.position.x + lane.size.x / 2.0) * TILE, (lane.position.y + 1.5) * TILE)
	sim.exits.append({"id": &"millbrook", "rect": Rect2(lane.position.x * TILE, farm_map.size.y * TILE - 10.0,
		lane.size.x * TILE, 10.0)})
	sim.player_position = sim.wake_position
	sim.previous_position = sim.wake_position
	return sim


## Puts the player somewhere at once, facing `towards` (entering the farm).
func place_player(at: Vector2, towards: Vector2) -> void:
	player_position = at
	previous_position = at
	facing = towards
	busy = 0
	_in_exit = &""
	for exit: Dictionary in exits:
		if (exit["rect"] as Rect2).has_point(at):
			_in_exit = exit["id"]


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


func spell() -> StringName:
	return spells[spell_index]


static func cast_ticks() -> int:
	return roundi(CAST_MS / 1000.0 / TICK_SECONDS)


## The watering spell at the player's tier.
func water_spell() -> Dictionary:
	return WATER_TIERS[water_tier]


## Mana the selected spell costs.
func spell_mana(spell_id: StringName) -> float:
	match spell_id:
		TILL:
			return TILL_MANA
		WATER:
			return float(water_spell()["mana"])
	return SOW_MANA


## The tiles the watering spell covers from `target`: `size.x` across and
## `size.y` forward, extending the way the player faces (the stronger axis
## of a diagonal), centred across (two wide: the target and the tile to the
## player's right). Empty for rain, which covers the whole farm.
func water_area(target: Vector2i) -> Array[Vector2i]:
	var size: Vector2i = water_spell()["size"]
	var cells: Array[Vector2i] = []
	if size == Vector2i.ZERO:
		return cells
	var forward: Vector2i = Vector2i(int(signf(facing.x)), 0) if absf(facing.x) > absf(facing.y) \
		else Vector2i(0, int(signf(facing.y)) if facing.y != 0.0 else 1)
	var side: Vector2i = Vector2i(-forward.y, forward.x)  # the player's right
	for depth: int in range(size.y):
		for across: int in range(size.x):
			var cell: Vector2i = target + forward * depth + side * (across - (size.x - 1) / 2)
			if plot.contains(cell):
				cells.append(cell)
	return cells


func step(input: FarmInput) -> void:
	events.clear()
	previous_position = player_position
	for i: int in range(clock.advance(TICK_SECONDS * time_scale)):
		_new_day()  # 6:00, asleep or awake (Q21)
	if input.tool_next_pressed or input.tool_prev_pressed:
		var by: int = (1 if input.tool_next_pressed else 0) - (1 if input.tool_prev_pressed else 0)
		spell_index = posmod(spell_index + by, spells.size())
		events.append({"type": "spell", "spell": spell()})
	if busy > 0:
		busy -= 1
		return
	if input.use_pressed:
		_cast()
		return
	if input.interact_pressed:
		_interact()
		return
	_walk(input.move)
	_check_exits()


## Walking into an exit reports it once, until the player steps out again.
func _check_exits() -> void:
	var inside: StringName = &""
	for exit: Dictionary in exits:
		if (exit["rect"] as Rect2).has_point(player_position):
			inside = exit["id"]
	if inside != &"" and inside != _in_exit:
		events.append({"type": "exit", "to": inside})
	_in_exit = inside


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
	var near: Array[Rect2] = solids
	if map != null:
		near = solids.duplicate()
		var low: Vector2i = cell_at(at - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))
		var high: Vector2i = cell_at(at + Vector2(PLAYER_RADIUS, PLAYER_RADIUS))
		for y: int in range(low.y, high.y + 1):
			for x: int in range(low.x, high.x + 1):
				if map.is_solid(Vector2i(x, y)):
					near.append(cell_rect(Rect2i(x, y, 1, 1)))
	for rect: Rect2 in near:
		var closest: Vector2 = Vector2(clampf(at.x, rect.position.x, rect.end.x), clampf(at.y, rect.position.y, rect.end.y))
		if closest.distance_to(at) < PLAYER_RADIUS:
			return false
	return true


func _cast() -> void:
	var cell: Vector2i = target_cell()
	var cost: float = spell_mana(spell())
	var crop: CropKind = CropKind.from_seed(spell())
	if crop != null and inventory.count(spell()) == 0:
		events.append({"type": "no_seeds", "seed": spell()})
		return
	# Would the spell do anything? Mana is only spent when it does.
	var does_something: bool = false
	match spell():
		TILL:
			does_something = not plot.is_blocked(cell) and not plot.is_tilled(cell)
		WATER:
			if water_spell()["size"] == Vector2i.ZERO:
				does_something = not raining
			else:
				for c: Vector2i in water_area(cell):
					does_something = does_something or (plot.is_tilled(c) and not plot.is_watered(c))
		_:
			does_something = plot.is_tilled(cell) and plot.crop_at(cell) == &""
	busy = cast_ticks()
	last_action = spell()
	if not does_something:
		events.append({"type": "nothing", "cell": cell})
		return
	if not mana.try_spend(cost):
		events.append({"type": "no_mana", "cost": cost})
		return
	match spell():
		TILL:
			plot.till(cell)
			if raining:
				plot.water(cell)
			events.append({"type": "till", "cell": cell, "position": cell_centre(cell)})
		WATER:
			if water_spell()["size"] == Vector2i.ZERO:
				raining = true
				var n: int = plot.water_all()
				events.append({"type": "rain", "watered": n, "position": player_position})
			else:
				var watered: Array[Vector2i] = []
				for c: Vector2i in water_area(cell):
					if plot.water(c):
						watered.append(c)
				events.append({"type": "water", "cells": watered, "position": cell_centre(cell)})
		_:
			plot.plant(cell, crop.id)
			inventory.take(spell())
			events.append({"type": "plant", "cell": cell, "position": cell_centre(cell)})


func _interact() -> void:
	var cell: Vector2i = target_cell()
	if is_door(cell):
		sleep()
		return
	var items: Dictionary = plot.harvest(cell)
	if items.is_empty():
		return
	for item: StringName in items:
		inventory.add(item, items[item])
	busy = cast_ticks()
	last_action = &"harvest"
	events.append({"type": "harvest", "cell": cell, "items": items, "position": cell_centre(cell)})


## True for the farmhouse door's tiles (the bed, for now).
func is_door(cell: Vector2i) -> bool:
	if map != null:
		return map.char_at(cell) == "D"
	return cell == door_cell


## Going to bed, any time: skips to the next 6:00 and refills Mana (Q22,
## Q27). The day also turns over at 6:00 without sleep.
func sleep() -> void:
	events.append({"type": "slept", "day": clock.day()})
	for i: int in range(clock.sleep_until_morning()):
		_new_day()
	mana.refill()
	place_player(wake_position, Vector2.DOWN)


## What the farm remembers between visits and in the save (the clock, Mana
## and the bag belong to the game, not the farm: GameState).
func export_state() -> Dictionary:
	return {"cells": plot.export_cells(), "raining": raining, "day": clock.day(),
		"spell_index": spell_index, "water_tier": water_tier}


## Restores export_state(), then runs every 6:00 that passed since (the
## clock may have moved on while the player was away).
func apply_state(state: Dictionary) -> void:
	plot.import_cells(state.get("cells", []))
	raining = bool(state.get("raining", false))
	water_tier = clampi(int(state.get("water_tier", 0)), 0, WATER_TIERS.size() - 1)
	spell_index = clampi(int(state.get("spell_index", 0)), 0, spells.size() - 1)
	catch_up(clock.day() - int(state.get("day", clock.day())))


## The days that started while the player was away (in an area): each runs
## the farm's 6:00, so crops watered before leaving grow once, and nothing
## dries twice.
func catch_up(days: int) -> void:
	for i: int in range(maxi(days, 0)):
		_new_day()


## 6:00: watered crops grow, the soil dries, any rain stops.
func _new_day() -> void:
	var grew: int = plot.new_day()
	raining = false
	events.append({"type": "new_day", "day": clock.day(), "grew": grew})


## Every crop planted on the plot, as cells.
func planted_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(plot.size.y):
		for x: int in range(plot.size.x):
			if plot.crop_at(Vector2i(x, y)) != &"":
				cells.append(Vector2i(x, y))
	return cells


## The HUD's name for a spell.
func spell_name(spell_id: StringName) -> String:
	if spell_id == WATER:
		return water_spell()["name"]
	if SPELL_NAMES.has(spell_id):
		return SPELL_NAMES[spell_id]
	var crop: CropKind = CropKind.from_seed(spell_id)
	return "Sow %s" % crop.display_name.to_lower() if crop != null else String(spell_id)


static func item_name(item: StringName) -> String:
	var crop: CropKind = CropKind.from_seed(item)
	if crop != null:
		return "%s seeds" % crop.display_name
	crop = CropKind.of(item)
	if crop != null:
		return crop.display_name
	return ITEM_NAMES.get(item, String(item).capitalize())
