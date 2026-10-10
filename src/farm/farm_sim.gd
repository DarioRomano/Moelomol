class_name FarmSim
extends RefCounted
## The base as a deterministic simulation, like CombatSim: call step() once
## per fixed 60 Hz tick with that tick's input. Holds the clock, the plot,
## the inventory, Mana and the player (docs/design/farming.md). All farming
## is magic (Q27): tilling, watering and sowing are spells that cost Mana;
## harvesting is by hand. The scene only
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
	if cell == door_cell:
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


## Going to bed, any time: skips to the next 6:00 and refills Mana (Q22,
## Q27). The day also turns over at 6:00 without sleep.
func sleep() -> void:
	events.append({"type": "slept", "day": clock.day()})
	for i: int in range(clock.sleep_until_morning()):
		_new_day()
	mana.refill()
	player_position = wake_position
	previous_position = wake_position
	facing = Vector2.DOWN
	busy = 0


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
	return crop.display_name if crop != null else String(item)
