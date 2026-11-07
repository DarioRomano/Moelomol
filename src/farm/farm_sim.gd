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
const CAST_MS: int = 250
## How near the point in front of the player must be to the cat's feet.
const CAT_REACH: float = 12.0
## How long a parcel's thicket takes to wither back (base.md: one long
## moment, the camera following).
const WITHER_TICKS: int = 180  # the player stands still while casting or picking

## Farming is magic (Q27, decided 2026-10-10): every farming action is a
## spell that costs Mana. Sowing has one entry per seed kind, keyed by the
## seed item. Mana costs are starting values.
const TILL: StringName = &"till"
const WATER: StringName = &"water"
## Clear (Q38): long grass to grass. On the old fields (`:`) the ground is
## then ready to till; elsewhere (`,`) it becomes lawn. Thicket is too much
## for it without a boss's heart (opening a parcel: not built yet).
const CLEAR: StringName = &"clear"
const TILL_MANA: float = 2.0
const SOW_MANA: float = 1.0
const CLEAR_MANA: float = 2.0
const SPELL_NAMES: Dictionary = {TILL: "Till", WATER: "Water", CLEAR: "Clear"}
## What Clear works on: the old fields under long grass, and long grass.
const CLEARABLE: String = ":,"

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
## Tiles the Clear spell has cleared (Vector2i -> true); the farm
## remembers them.
var cleared: Dictionary = {}
## Where the cat sits at the farm (its feet), or INF when it is not here;
## the scene sets it from the game's Cat. Interact while facing it strokes it.
var cat_position: Vector2 = Vector2.INF
var cat_purring: bool = false
## The parcels opened with a boss's heart (base.md, Q38 C), remembered.
var parcels_open: Array[int] = []
## While a parcel's thicket withers (one long moment, about 3 s): the
## parcel, where it started (layout px), how far it has gone, and the tiles
## still to wither, nearest first: [{"cell", "char", "distance"}].
var withering: Dictionary = {}
## The tiles that withered this tick (for the ground to be painted again).
var withered_now: Array[Vector2i] = []
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
## farmhouse opens on the house inside (HouseSim). The player starts in
## front of the door.
static func make_farm() -> FarmSim:
	var farm_map: FarmMap = FarmMap.make_farm()
	var sim: FarmSim = FarmSim.new(Vector2.ZERO, farm_map.size)
	sim.map = farm_map
	sim.spells.insert(2, CLEAR)  # Till, Water, Clear, then the seeds
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
		CLEAR:
			return CLEAR_MANA
	return SOW_MANA


## True if Clear would do something on `cell`: long grass not yet cleared.
func can_clear(cell: Vector2i) -> bool:
	return map != null and CLEARABLE.contains(map.char_at(cell)) and not cleared.has(cell)


## The parcel whose thicket `cell` is (1-6), or 0.
func parcel_at(cell: Vector2i) -> int:
	if map == null:
		return 0
	var c: String = map.char_at(cell)
	if c == "-":
		return 1  # the old track, under the great fields' thicket
	if c.length() == 1 and "123456".contains(c):
		return int(c)
	return 0


## True if Clear on `cell` would open its parcel: thicket of a parcel not yet
## open (nor opening), with that parcel's boss heart in the bag (Q38 C).
## Only the great fields' heart exists so far.
func can_open(cell: Vector2i) -> bool:
	var parcel: int = parcel_at(cell)
	if parcel == 0 or parcel in parcels_open or not withering.is_empty():
		return false
	var heart: StringName = FarmLayout.PARCEL_HEARTS.get(parcel, &"")
	return heart != &"" and inventory.count(heart) > 0


## The heart is used up and the thicket begins to wither back from `from`.
func _start_opening(cell: Vector2i) -> void:
	var parcel: int = parcel_at(cell)
	inventory.take(FarmLayout.PARCEL_HEARTS[parcel])
	var origin: Vector2 = cell_centre(cell)
	var tiles: Array[Dictionary] = []
	var opened: Dictionary = FarmLayout.opened_tiles(parcel, map.rows)
	for t: Vector2i in opened:
		tiles.append({"cell": t, "char": opened[t], "distance": cell_centre(t).distance_to(origin)})
	tiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["distance"] < b["distance"])
	var farthest: Vector2 = cell_centre(tiles[tiles.size() - 1]["cell"]) if not tiles.is_empty() else origin
	withering = {"parcel": parcel, "origin": origin, "farthest": farthest, "ticks": 0, "tiles": tiles, "next": 0,
		"reach": float(tiles[tiles.size() - 1]["distance"]) if not tiles.is_empty() else 0.0}
	events.append({"type": "opening", "parcel": parcel, "position": origin})


## One tick of the withering: every tile the front has reached turns into
## what was under the thicket. At the end the parcel is open.
func _step_withering() -> void:
	withering["ticks"] = int(withering["ticks"]) + 1
	var reach: float = float(withering["reach"]) * minf(float(withering["ticks"]) / WITHER_TICKS, 1.0)
	var tiles: Array[Dictionary] = withering["tiles"]
	var i: int = int(withering["next"])
	while i < tiles.size() and float(tiles[i]["distance"]) <= reach:
		map.set_tile(tiles[i]["cell"], tiles[i]["char"])
		withered_now.append(tiles[i]["cell"])
		i += 1
	withering["next"] = i
	if i >= tiles.size():
		var parcel: int = withering["parcel"]
		parcels_open.append(parcel)
		withering = {}
		events.append({"type": "opened", "parcel": parcel})


## How far the withering front has gone (0 to 1), and the point the camera
## follows: from where it started out to its farthest reach.
func withering_progress() -> float:
	return clampf(float(withering.get("ticks", 0)) / WITHER_TICKS, 0.0, 1.0) if not withering.is_empty() else 0.0


## How far from where it started the thicket has withered (layout px).
func withering_reach() -> float:
	return float(withering.get("reach", 0.0)) * withering_progress()


func withering_focus() -> Vector2:
	if withering.is_empty():
		return player_position
	var origin: Vector2 = withering["origin"]
	return origin.lerp(withering["farthest"], withering_progress())


## Opens a parcel at once (loading a game where it was opened).
func open_parcel(parcel: int) -> void:
	if parcel in parcels_open:
		return
	var opened: Dictionary = FarmLayout.opened_tiles(parcel, map.rows)
	if opened.is_empty():
		return
	for t: Vector2i in opened:
		map.set_tile(t, opened[t])
	parcels_open.append(parcel)


## Clears a tile: lawn, or on the old fields, ground ready to till.
func clear_tile(cell: Vector2i) -> void:
	cleared[cell] = true
	if map.char_at(cell) == ":":
		plot.unblock(cell)


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
	withered_now.clear()
	previous_position = player_position
	for i: int in range(clock.advance(TICK_SECONDS * time_scale)):
		_new_day()  # 6:00, asleep or awake (Q21)
	if not withering.is_empty():
		_step_withering()  # the player stands and watches
		return
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
		CLEAR:
			does_something = can_clear(cell) or can_open(cell)
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
		CLEAR:
			if can_open(cell):
				_start_opening(cell)
			else:
				clear_tile(cell)
				events.append({"type": "clear", "cell": cell, "position": cell_centre(cell)})
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
	if faces_cat():
		events.append({"type": "stroke", "position": cat_position})
		return
	var cell: Vector2i = target_cell()
	if is_door(cell):
		if map != null:
			# The farm's door opens on the farmhouse inside (its own place).
			events.append({"type": "exit", "to": &"house"})
		else:
			sleep()  # the test field: the door is the bed
		return
	var items: Dictionary = plot.harvest(cell)
	if items.is_empty():
		return
	for item: StringName in items:
		inventory.add(item, items[item])
	busy = cast_ticks()
	last_action = &"harvest"
	events.append({"type": "harvest", "cell": cell, "items": items, "position": cell_centre(cell)})


## True if the cat is here and the player faces it, close enough to reach.
func faces_cat() -> bool:
	if cat_position == Vector2.INF:
		return false
	return (player_position + facing.normalized() * TARGET_REACH).distance_to(cat_position) < CAT_REACH


## True for the farmhouse door's tiles (on the test field, the bed).
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
	var cleared_cells: Array = []
	for cell: Vector2i in cleared:
		cleared_cells.append([cell.x, cell.y])
	var opened: Array[int] = parcels_open.duplicate()
	if not withering.is_empty():
		opened.append(int(withering["parcel"]))  # the heart is spent: it opens
	return {"cells": plot.export_cells(), "cleared": cleared_cells, "parcels_open": opened,
		"raining": raining, "day": clock.day(),
		"spell_index": spell_index, "water_tier": water_tier}


## Restores export_state(), then runs every 6:00 that passed since (the
## clock may have moved on while the player was away).
func apply_state(state: Dictionary) -> void:
	# Opened parcels first (cleared ground may be inside them), then cleared
	# ground (tilled tiles on the old fields need it), then the soil.
	for parcel: Variant in state.get("parcels_open", []):
		if parcel is int or parcel is float:
			open_parcel(int(parcel))
	for entry: Variant in state.get("cleared", []):
		if entry is Array and (entry as Array).size() == 2:
			var cell: Vector2i = Vector2i(int(entry[0]), int(entry[1]))
			if can_clear(cell):
				clear_tile(cell)
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
