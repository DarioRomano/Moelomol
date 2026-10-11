class_name Area
extends RefCounted
## An adventure area at play (docs/design/world.md): its map, the combat
## simulation on it, the clock, and its roster of creatures for day and
## night. Deterministic like the simulations it wraps: the scene calls step()
## once per 60 Hz tick.
##
## The roster follows the world's rules: the night roster comes out at 20:00
## and the day roster at 6:00; creatures swap only where the player cannot see
## them (OFFSCREEN); defeated creatures come back at the next 6:00; a defeated
## boss never does. Falling means waking the next morning (Q36; the farm is
## not built yet, so the player wakes at the area's entrance).

## Further than this from the player, a creature can appear or vanish unseen
## on every screen (32:9 sees 640 px either side).
const OFFSCREEN: float = 680.0
const SYNC_TICKS: int = 30  # the roster is checked twice a second
const START_MINUTE: float = 9.0 * 60.0

var id: StringName
var map: AreaMap
var sim: CombatSim
var clock: GameClock = GameClock.new()
var entrance: Vector2
## {"kind": StringName, "at": Vector2, "when": &"day" | &"night" | &"both",
##  "fighter": Fighter or null, "defeated_day": int}
var roster: Array[Dictionary] = []
var bosses_defeated: Array[StringName] = []
var lights: Array[Vector2] = []  # always (glowing fungus)
var night_lights: Array[Vector2] = []  # at night only (fireflies)
var time_scale: float = 1.0
## What happened at the area level during the last step: "dawn", "dusk",
## "woke" (after falling).
var events: Array[Dictionary] = []

var _ticks: int = 0
var _was_night: bool = false


func _init(p_id: StringName, p_map: AreaMap, p_entrance: Vector2) -> void:
	id = p_id
	map = p_map
	entrance = p_entrance
	sim = CombatSim.new(map.rect(), entrance)
	sim.map = map
	clock.total_minutes = GameClock.DAY_START_MINUTE + (START_MINUTE - GameClock.DAY_START_MINUTE)


## Adds a creature to the roster (placed by start() or the next sync).
func add_to_roster(kind: StringName, at: Vector2, when: StringName) -> void:
	roster.append({"kind": kind, "at": at, "when": when, "fighter": null, "defeated_day": -1})


## Places everything for the time of day, at once.
func start() -> void:
	_was_night = is_night()
	_apply_light()
	sync(true)


func is_night() -> bool:
	return clock.phase() == GameClock.NIGHT


func step(input: CombatInput) -> void:
	events.clear()
	var new_days: int = clock.advance(time_scale / Engine.physics_ticks_per_second)
	_apply_light()
	sim.step(input)
	for e: Dictionary in sim.events:
		match e["type"]:
			"boss_defeated":
				var boss: Fighter = e["fighter"]
				if not (boss.creature_kind.id in bosses_defeated):
					bosses_defeated.append(boss.creature_kind.id)
			"respawn":
				if (e["fighter"] as Fighter) == sim.player:
					_wake_next_morning()
					return
	if new_days > 0:
		events.append({"type": "dawn"})
	if is_night() and not _was_night:
		events.append({"type": "dusk"})
	_was_night = is_night()
	_ticks += 1
	if new_days > 0 or _ticks % SYNC_TICKS == 0:
		sync(false)


## Skips to the next 20:00 or 6:00, whichever comes first (a developer key).
func skip_to_next_change() -> void:
	var at: float = clock.minute()
	var target: float = GameClock.NIGHT_START if at >= GameClock.DAWN_START and at < GameClock.NIGHT_START \
		else GameClock.DAWN_START
	var ahead: float = fposmod(target - at, GameClock.MINUTES_PER_DAY)
	clock.total_minutes += ahead + 0.01


## Brings the creatures in line with the time of day. `force`: everything
## at once, seen or not (entering, waking); otherwise only out of sight.
func sync(force: bool) -> void:
	for entry: Dictionary in roster:
		var f: Fighter = entry["fighter"]
		if f != null and f.creature_kind.boss and not f.is_alive() and not (f.creature_kind.id in bosses_defeated):
			bosses_defeated.append(f.creature_kind.id)  # a boss is defeated once (world.md)
		if f != null and f.state == Fighter.State.GONE and int(entry["defeated_day"]) < 0:
			entry["defeated_day"] = clock.day()
		var kind: StringName = entry["kind"]
		var wanted: bool = _wanted_now(entry) and not (kind in bosses_defeated)
		if not wanted:
			if f != null and (force or (_far(f.position) and f.state != Fighter.State.ATTACK)):
				_remove(f)
				entry["fighter"] = null
			continue
		var missing: bool = f == null or f.state == Fighter.State.GONE
		if not missing:
			continue
		if f != null and not force and clock.day() <= int(entry["defeated_day"]):
			continue  # defeated today: back at the next 6:00
		if force or _far(entry["at"]):
			if f != null:
				_remove(f)
			entry["fighter"] = _spawn(entry)
			entry["defeated_day"] = -1


func _wanted_now(entry: Dictionary) -> bool:
	match entry["when"]:
		&"day":
			return not is_night()
		&"night":
			return is_night()
	return true


func _far(at: Vector2) -> bool:
	return at.distance_to(sim.player.position) > OFFSCREEN


func _spawn(entry: Dictionary) -> Fighter:
	var kind: CreatureKind = CreatureKind.by_id(entry["kind"])
	kind.respawns = false  # the area brings it back at 6:00, not the arena's 3 s
	return sim.add_creature(entry["at"], kind)


func _remove(f: Fighter) -> void:
	sim.creatures.erase(f)
	if sim.lock_target == f:
		sim.lock_target = null


func _apply_light() -> void:
	sim.night = is_night()
	sim.lights = lights + night_lights if sim.night else lights.duplicate()


## Falling (Q36): the next morning, everything back in place. The farm is
## not built yet, so the player wakes at the area's entrance.
func _wake_next_morning() -> void:
	clock.sleep_until_morning()
	_apply_light()
	_was_night = false
	sim.projectiles.clear()
	sim.zones.clear()
	sync(true)
	events.append({"type": "woke"})
