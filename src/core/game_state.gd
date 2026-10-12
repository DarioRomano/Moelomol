class_name GameState
extends RefCounted
## One game in play: what belongs to the player wherever they are (the
## clock, Mana, the bag), which place they are in, and what each place
## remembers (ADR-0016). Places are scenes; each builds its simulation from
## here when it opens and stores what it remembers when the player leaves.
##
## GameState.current is the game being played. A scene opened on its own
## (F2, `--start-scene`, a test) gets a new game that is never saved.

const FARM: StringName = &"farm"
const MILLBROOK: StringName = &"millbrook"
const SCENES: Dictionary = {
	FARM: "res://scenes/farm/farm.tscn",
	MILLBROOK: "res://scenes/world/millbrook.tscn",
}
## Where the player appears on arriving at a place.
const AT_BED: StringName = &"bed"  # the farm, in front of the farmhouse door
const AT_GATE: StringName = &"gate"  # the place's entrance from the other

static var current: GameState = null

var clock: GameClock = GameClock.new()
var inventory: Inventory = Inventory.new()
var mana: Mana = Mana.new()
var place: StringName = FARM
var arrival: StringName = AT_BED
## FarmSim.export_state() as the player last left the farm; empty until then.
var farm_state: Dictionary = {}
## Area id -> Area.export_state() as the player last left it.
var area_states: Dictionary = {}


## A new game: day 1, 6:00, at the farm, with the seed tin's seeds (Q25).
static func new_game() -> GameState:
	var state: GameState = GameState.new()
	for seed_id: StringName in FarmSim.STARTING_SEEDS:
		state.inventory.add(seed_id, FarmSim.STARTING_SEEDS[seed_id])
	return state


## The game in play, starting a new unsaved one if there is none (a place
## opened on its own).
static func ensure() -> GameState:
	if current == null:
		current = new_game()
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
		sim.place_player(sim.wake_position, Vector2.DOWN)
	return sim


func store_farm(sim: FarmSim) -> void:
	farm_state = sim.export_state()


## An area as the player left it, on the game's clock and bag, with the
## player at its entrance.
func make_area(area_id: StringName) -> Area:
	var area: Area
	match area_id:
		MILLBROOK:
			area = Millbrook.make()
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
	area.enter()
	return area


func store_area(area: Area) -> void:
	area_states[area.id] = area.export_state()


## The player is going to `to`, arriving at `at` (AT_BED or AT_GATE). The
## place being left must store itself first.
func travel(to: StringName, at: StringName) -> void:
	place = to
	arrival = at


## Falling out in an area (Q36): the next 6:00, waking in the farm bed with
## everything carried kept and Mana full, as after a night's sleep. The area
## has already moved the clock on.
func fell() -> void:
	mana.refill()
	travel(FARM, AT_BED)


func scene_path() -> String:
	return SCENES[place]
