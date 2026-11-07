class_name GameState
extends RefCounted
## One game in play: what belongs to the player wherever they are (the
## clock, Mana, the bag), which place they are in, and what each place
## remembers (ADR-0016). Places are scenes; each builds its simulation from
## here when it opens and stores what it remembers when the player leaves.
##
## GameState.current is the game being played. A scene opened on its own
## (F2, `--start-scene`, a test) gets a new game that is never saved.
##
## Saving (ADR-0017): one save, a JSON file, written quietly when the player
## sleeps, falls, or passes the farm's south gate either way. It records the
## place and how the player arrives there (the bed or the gate), so a game
## always resumes where it was saved.

const FARM: StringName = &"farm"
const HOUSE: StringName = &"house"
const MILLBROOK: StringName = &"millbrook"
const KETTLEBRIDGE: StringName = &"kettlebridge"
const SCENES: Dictionary = {
	FARM: "res://scenes/farm/farm.tscn",
	HOUSE: "res://scenes/farm/house.tscn",
	MILLBROOK: "res://scenes/world/millbrook.tscn",
	KETTLEBRIDGE: "res://scenes/world/kettlebridge.tscn",
}
## Where the player appears on arriving at a place.
const AT_BED: StringName = &"bed"  # the house, beside the bed (waking)
const AT_DOOR: StringName = &"door"  # through the farmhouse door, either side
const AT_GATE: StringName = &"gate"  # the farm's south gate or an area's entrance

## The one save (ADR-0017).
const SAVE_PATH: String = "user://save.json"
## The save file's format; a later format reads this one and converts it.
const FORMAT: int = 1

static var current: GameState = null
## Why the last load_from() returned null, for the title screen.
static var last_load_error: String = ""

var clock: GameClock = GameClock.new()
var inventory: Inventory = Inventory.new()
var mana: Mana = Mana.new()
## The cat (Q41): where it is, wherever the player is.
var cat: Cat = Cat.new()
## Every note found, anywhere, in the order found (one satchel, Q37). An
## area being played shares this very array as its `satchel`.
var satchel: Array[StringName] = []
var place: StringName = HOUSE
var arrival: StringName = AT_BED
## The place the player last came from: an area with more than one way in
## puts them at the matching one (Millbrook: the lane from the farm, or the
## ford from Kettlebridge).
var came_from: StringName = &""
## FarmSim.export_state() as the player last left the farm; empty until then.
var farm_state: Dictionary = {}
## HouseSim.export_state(): the seed tin.
var house_state: Dictionary = {}
## Area id -> Area.export_state() as the player last left it.
var area_states: Dictionary = {}
## Where save() writes; empty for a game that is never saved (a place
## opened on its own, tests).
var save_path: String = ""
## When and where the game was last saved (summary()), for the pause menu;
## empty until the first save or load.
var last_saved: String = ""


## A new game: day 1, 6:00, waking in the farmhouse bed, the bag empty and
## the first seeds in the seed tin (Q25).
static func new_game() -> GameState:
	return GameState.new()


## The game in play, starting a new unsaved one if there is none (a place
## opened on its own). Such a game starts with the seed tin already emptied
## into the bag, so the farm can be tried straight away.
static func ensure() -> GameState:
	if current == null:
		current = new_game()
		for seed_id: StringName in FarmSim.STARTING_SEEDS:
			current.inventory.add(seed_id, FarmSim.STARTING_SEEDS[seed_id])
		current.house_state = {"tin_taken": true}
	return current


## The farm as the player left it, with the game's clock, Mana and bag, the
## days since then run, and the player at the bed or the gate.
func make_farm() -> FarmSim:
	var sim: FarmSim = FarmSim.make_farm()
	sim.clock = clock
	sim.inventory = inventory
	sim.mana = mana
	if not farm_state.is_empty():
		sim.apply_state(farm_state)
	if arrival == AT_GATE:
		sim.place_player(sim.gate_position, Vector2.UP)
	else:
		sim.place_player(sim.wake_position, Vector2.DOWN)  # out of the farmhouse door
	return sim


func store_farm(sim: FarmSim) -> void:
	farm_state = sim.export_state()


## The farmhouse inside, with the game's clock, Mana and bag; the player
## beside the bed or just in from the door.
func make_house() -> HouseSim:
	var sim: HouseSim = HouseSim.new()
	sim.clock = clock
	sim.mana = mana
	sim.inventory = inventory
	sim.apply_state(house_state)
	if arrival == AT_DOOR:
		sim.place_player(sim.door_position, Vector2.UP)
	else:
		sim.place_player(sim.bed_position, Vector2.DOWN)
	return sim


func store_house(sim: HouseSim) -> void:
	house_state = sim.export_state()


## An area as the player left it, on the game's clock and bag, with the
## player at its entrance.
func make_area(area_id: StringName) -> Area:
	var area: Area
	match area_id:
		MILLBROOK:
			area = Millbrook.make()
		KETTLEBRIDGE:
			area = Kettlebridge.make()
		_:
			push_error("GameState: no area called %s" % area_id)
			return null
	area.clock = clock
	area.bag = inventory
	area.wakes_at_home = true
	if area_states.has(area_id):
		area.apply_state(area_states[area_id])
	else:
		area.start()
	# One satchel: notes the area remembered finding (saves from before the
	# satchel was the game's) join it, then the area adds to it directly.
	for note_id: StringName in area.satchel:
		if not (note_id in satchel):
			satchel.append(note_id)
	area.satchel = satchel
	area.enter(came_from)
	return area


func store_area(area: Area) -> void:
	area_states[area.id] = area.export_state()


## The player is going to `to`, arriving at `at` (AT_BED, AT_DOOR or
## AT_GATE), from the place `from` (it picks the way in). The place being
## left must store itself first.
func travel(to: StringName, at: StringName, from: StringName = &"") -> void:
	place = to
	arrival = at
	came_from = from


## Falling out in an area (Q36): the next 6:00, waking in the farmhouse bed
## with everything carried kept and Mana full, as after a night's sleep. The
## area has already moved the clock on.
func fell() -> void:
	mana.refill()
	cat.place = Cat.BLANKET  # curled on the blanket when the player wakes (Q36)
	travel(HOUSE, AT_BED)


func scene_path() -> String:
	return SCENES[place]



# --- Saving (ADR-0017) ----------------------------------------------------------------

## Everything the game remembers, as plain data for JSON.
func to_dict() -> Dictionary:
	return {
		"format": FORMAT,
		"saved_at": Time.get_unix_time_from_system(),
		"minutes": clock.total_minutes,
		"mana": {"current": mana.current, "maximum": mana.maximum},
		"items": inventory.to_dict(),
		"place": String(place),
		"arrival": String(arrival),
		"came_from": String(came_from),
		"farm": farm_state,
		"house": house_state,
		"cat": cat.to_dict(),
		"satchel": satchel.map(func(n: StringName) -> String: return String(n)),
		"areas": area_states,
	}


## A game from to_dict(), or null with last_load_error set if the data is
## not a save this build can read.
static func from_dict(data: Dictionary) -> GameState:
	last_load_error = ""
	if int(data.get("format", -1)) != FORMAT:
		last_load_error = "the save's format (%s) is not one this build reads" % str(data.get("format", "missing"))
		return null
	var place_name: StringName = StringName(str(data.get("place", "")))
	if not SCENES.has(place_name):
		last_load_error = "the save is in a place this build does not know (%s)" % place_name
		return null
	var minutes: Variant = data.get("minutes")
	if not (minutes is float or minutes is int) or float(minutes) < GameClock.DAY_START_MINUTE:
		last_load_error = "the save's clock is missing"
		return null
	var state: GameState = GameState.new()
	state.clock.total_minutes = float(minutes)
	var mana_data: Variant = data.get("mana", {})
	if mana_data is Dictionary:
		state.mana.maximum = maxf(float((mana_data as Dictionary).get("maximum", Mana.STARTING_MAXIMUM)), 1.0)
		state.mana.current = clampf(float((mana_data as Dictionary).get("current", state.mana.maximum)), 0.0, state.mana.maximum)
	var items: Variant = data.get("items", {})
	if items is Dictionary:
		state.inventory.load_dict(items)
	state.place = place_name
	state.came_from = StringName(str(data.get("came_from", "")))
	var arrival_name: StringName = StringName(str(data.get("arrival", "")))
	state.arrival = arrival_name if arrival_name in [AT_BED, AT_DOOR, AT_GATE] else AT_BED
	var farm: Variant = data.get("farm", {})
	state.farm_state = farm if farm is Dictionary else {}
	var found: Variant = data.get("satchel", [])
	if found is Array:
		for note_id: Variant in found:
			var n: StringName = StringName(str(note_id))
			if not Notes.find(n).is_empty() and not (n in state.satchel):
				state.satchel.append(n)
	var cat_data: Variant = data.get("cat")
	if cat_data is Dictionary:
		state.cat.load_dict(cat_data)
	var house: Variant = data.get("house")
	if house is Dictionary:
		state.house_state = house
	else:
		# Saved before the house was built (2026-11-06): the seeds were
		# already in the bag, and sleeping happened at the farmhouse door.
		state.house_state = {"tin_taken": true}
		if state.place == FARM and state.arrival == AT_BED:
			state.place = HOUSE
	var areas: Variant = data.get("areas", {})
	if areas is Dictionary:
		for key: Variant in areas:
			if areas[key] is Dictionary:
				state.area_states[StringName(str(key))] = areas[key]
				# Saves from before one satchel kept each area's notes there.
				for note_id: Variant in (areas[key] as Dictionary).get("satchel", []):
					var n: StringName = StringName(str(note_id))
					if not Notes.find(n).is_empty() and not (n in state.satchel):
						state.satchel.append(n)
	return state


## Writes the save, if this game has one: to a temporary file first, then
## over the old save, so a crash mid-write never leaves half a save.
func save() -> Error:
	if save_path.is_empty():
		return OK
	var temporary: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("GameState: cannot write %s (%s)" % [temporary, error_string(FileAccess.get_open_error())])
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	var result: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),
		ProjectSettings.globalize_path(save_path))
	if result != OK:
		push_warning("GameState: cannot replace %s (%s)" % [save_path, error_string(result)])
	else:
		last_saved = summary()
	return result


static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


## The saved game at `path` (saving back to it), or null with
## last_load_error set.
static func load_from(path: String = SAVE_PATH) -> GameState:
	if not FileAccess.file_exists(path):
		last_load_error = "there is no save"
		return null
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		last_load_error = "the save could not be read (line %d: %s)" % [json.get_error_line() + 1, json.get_error_message()]
		return null
	var state: GameState = from_dict(json.data)
	if state != null:
		state.save_path = path
		state.last_saved = state.summary()
	return state


## A short line about a save for the title screen: "Day 3, 18:40, at the farm".
func summary() -> String:
	var where: String = {FARM: "at the farm", HOUSE: "in the farmhouse"}.get(place, "in " + String(place).capitalize())
	return "Day %d, %s, %s" % [clock.day(), clock.time_text(), where]
