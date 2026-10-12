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
## boss never does. Falling means waking the next morning (Q36): in the game
## the area reports "fell" and the scene takes the player home to the farm;
## on its own (tests, the arena-like review scenes) the player wakes at the
## area's entrance.

## Further than this from the player, a creature can appear or vanish unseen
## on every screen (32:9 sees 640 px either side).
const OFFSCREEN: float = 680.0
const SYNC_TICKS: int = 30  # the roster is checked twice a second
const START_MINUTE: float = 9.0 * 60.0
## How close the player must be to something to interact with it.
const INTERACT_RANGE: float = 22.0
## Millbrook's flood drains over this long once the sluice opens.
const DRAIN_SECONDS: float = 10.0

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
## In the game (GameState), falling sends the player home to the farm bed
## instead of waking them at the entrance.
var wakes_at_home: bool = false
## Things the player can interact with (Area.interact): each
## {"id": StringName, "kind": &"note" | &"crank" | &"sluice" | &"heart",
##  "position": Vector2, "shown": bool, "taken": bool}.
var things: Array[Dictionary] = []
## The notes this area holds: {id: {"title", "text", "objective"}}.
var notes: Dictionary = {}
## Notes found, in the order found (the satchel shows them newest first; Q37).
var satchel: Array[StringName] = []
## What the player carries out here (the crank, Grist's heart and tusk).
var bag: Inventory = Inventory.new()
## The area's objective is done (Millbrook: the sluice is open).
var objective_done: bool = false
## 0 = flooded, 1 = drained; rises over DRAIN_SECONDS once the sluice opens.
var drain_progress: float = 0.0
## Exits: {"id": StringName, "rect": Rect2, "needs_drained": bool}.
var exits: Array[Dictionary] = []
## What happened at the area level during the last step: "dawn", "dusk",
## "woke" (after falling).
var events: Array[Dictionary] = []

var _ticks: int = 0
var _was_night: bool = false
var _in_exit: StringName = &""


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
	_step_drain()
	_check_exits()
	for c: Fighter in sim.creatures:
		if c.creature_kind.boss and not c.is_alive():
			_boss_defeated(c)
	for e: Dictionary in sim.events:
		match e["type"]:
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
		if f != null and f.creature_kind.boss and not f.is_alive():
			_boss_defeated(f)
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
		if clock.day() <= int(entry["defeated_day"]):
			continue  # defeated today (even before leaving and coming back): back at the next 6:00
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


## Falling (Q36): the next morning, everything back in place. In the game
## the player wakes in the farm bed (the scene goes home on "fell");
## otherwise at the area's entrance.
func _wake_next_morning() -> void:
	clock.sleep_until_morning()
	if wakes_at_home:
		events.append({"type": "fell"})
		return
	_apply_light()
	_was_night = false
	sim.projectiles.clear()
	sim.zones.clear()
	sync(true)
	events.append({"type": "woke"})


# --- Things to interact with ------------------------------------------------------------

## Adds something to interact with.
func add_thing(thing_id: StringName, kind: StringName, at: Vector2, shown: bool = true) -> void:
	things.append({"id": thing_id, "kind": kind, "position": at, "shown": shown, "taken": false})


## The nearest thing within reach of the player, or {}.
func thing_in_reach() -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = INTERACT_RANGE
	for thing: Dictionary in things:
		if not thing["shown"] or thing["taken"]:
			continue
		var d: float = (thing["position"] as Vector2).distance_to(sim.player.position)
		if d <= best_distance:
			best = thing
			best_distance = d
	return best


## The player interacts with whatever is in reach. Returns what happened:
## {"type": "note", "note": id}, {"type": "taken", "item": id},
## {"type": "sluice_opened"}, {"type": "sluice_stuck"} (no crank), or
## {"type": "nothing"}.
func interact() -> Dictionary:
	if not sim.player.is_alive() or sim.player.state != Fighter.State.FREE:
		return {"type": "nothing"}
	var thing: Dictionary = thing_in_reach()
	if thing.is_empty():
		return {"type": "nothing"}
	match thing["kind"]:
		&"note":
			var note_id: StringName = thing["id"]
			if not (note_id in satchel):
				satchel.append(note_id)
			return {"type": "note", "note": note_id}
		&"crank", &"heart":
			thing["taken"] = true
			var item: StringName = thing["id"]
			bag.add(item)
			if item == &"grist_heart":
				bag.add(&"tusk")
			return {"type": "taken", "item": item}
		&"sluice":
			if objective_done:
				return {"type": "nothing"}
			if not bag.take(&"sluice_crank"):
				return {"type": "sluice_stuck"}
			objective_done = true
			return {"type": "sluice_opened"}
	return {"type": "nothing"}


## True if the note carries the satchel's loose-thread mark: about the
## objective, which is not done yet (Q37).
func has_loose_thread(note_id: StringName) -> bool:
	return bool((notes[note_id] as Dictionary)["objective"]) and not objective_done


## The satchel's notes, newest first.
func satchel_newest_first() -> Array[StringName]:
	var listed: Array[StringName] = satchel.duplicate()
	listed.reverse()
	return listed


## The sluice is open: the floodwater drains, played out over DRAIN_SECONDS,
## then the meadow is walkable.
func _step_drain() -> void:
	if not objective_done or map.drained:
		return
	drain_progress = minf(1.0, drain_progress + 1.0 / (DRAIN_SECONDS * Engine.physics_ticks_per_second))
	if drain_progress >= 1.0:
		map.drained = true
		events.append({"type": "drained"})


## A boss is defeated once (world.md): recorded, and it leaves its heart.
func _boss_defeated(boss: Fighter) -> void:
	if boss.creature_kind.id in bosses_defeated:
		return
	bosses_defeated.append(boss.creature_kind.id)
	_leave_heart(boss)


## A defeated boss leaves its heart where it fell (enemies.md).
func _leave_heart(boss: Fighter) -> void:
	if not (&"grist_heart" in boss.creature_kind.drops):
		return
	add_thing(&"grist_heart", &"heart", boss.position)
	for thing: Dictionary in things:
		if thing["id"] == &"grist_apples":
			thing["shown"] = true  # the note for after (enemies.md)


func add_exit(exit_id: StringName, rect: Rect2, needs_drained: bool) -> void:
	exits.append({"id": exit_id, "rect": rect, "needs_drained": needs_drained})


## Walking into an exit reports it once, until the player steps out again.
func _check_exits() -> void:
	var inside: StringName = &""
	for exit: Dictionary in exits:
		if (exit["rect"] as Rect2).has_point(sim.player.position) and (not exit["needs_drained"] or map.drained):
			inside = exit["id"]
	if inside != &"" and inside != _in_exit:
		events.append({"type": "exit", "to": inside})
	_in_exit = inside



# --- Remembering the area ------------------------------------------------------------

## What the area remembers between visits and in the save: notes found, the
## objective, the drained meadow, bosses defeated (and what they left), things
## taken, and the creatures defeated today (back at the next 6:00).
func export_state() -> Dictionary:
	var defeated: Dictionary = {}
	for i: int in range(roster.size()):
		var entry: Dictionary = roster[i]
		var f: Fighter = entry["fighter"]
		var day: int = int(entry["defeated_day"])
		if f != null and not f.is_alive() and day < 0:
			day = clock.day()
		if day >= clock.day():
			defeated[str(i)] = day
	var saved_things: Array = []
	for thing: Dictionary in things:
		var at: Vector2 = thing["position"]
		saved_things.append({"id": String(thing["id"]), "kind": String(thing["kind"]), "x": at.x, "y": at.y,
			"shown": thing["shown"], "taken": thing["taken"]})
	var found: Array = []
	for note_id: StringName in satchel:
		found.append(String(note_id))
	var bosses: Array = []
	for boss: StringName in bosses_defeated:
		bosses.append(String(boss))
	return {"satchel": found, "objective_done": objective_done, "drain_progress": drain_progress,
		"drained": map.drained, "bosses_defeated": bosses, "things": saved_things, "defeated_today": defeated}


## Restores export_state() onto a freshly made area, then places the
## creatures for the time of day. Unknown notes are dropped; a thing the area
## does not make itself (a boss's heart) is added where it was left.
func apply_state(state: Dictionary) -> void:
	satchel.clear()
	for note_id: Variant in state.get("satchel", []):
		if notes.has(StringName(str(note_id))) and not (StringName(str(note_id)) in satchel):
			satchel.append(StringName(str(note_id)))
	objective_done = bool(state.get("objective_done", false))
	map.drained = bool(state.get("drained", false))
	drain_progress = 1.0 if map.drained else clampf(float(state.get("drain_progress", 0.0)), 0.0, 1.0)
	bosses_defeated.clear()
	for boss: Variant in state.get("bosses_defeated", []):
		bosses_defeated.append(StringName(str(boss)))
	for saved: Variant in state.get("things", []):
		if not saved is Dictionary:
			continue
		var d: Dictionary = saved
		var thing_id: StringName = StringName(str(d.get("id", "")))
		var thing: Dictionary = _thing(thing_id)
		if thing.is_empty():
			if thing_id == &"":
				continue
			add_thing(thing_id, StringName(str(d.get("kind", ""))), Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0))))
			thing = things[things.size() - 1]
		thing["shown"] = bool(d.get("shown", thing["shown"]))
		thing["taken"] = bool(d.get("taken", false))
	var defeated: Dictionary = state.get("defeated_today", {})
	for key: Variant in defeated:
		var i: int = int(str(key))
		if i >= 0 and i < roster.size():
			roster[i]["defeated_day"] = int(defeated[key])
			var f: Fighter = roster[i]["fighter"]
			if f != null and clock.day() <= int(defeated[key]):
				_remove(f)  # placed when the area was made; not back until 6:00
				roster[i]["fighter"] = null
	start()


func _thing(thing_id: StringName) -> Dictionary:
	for thing: Dictionary in things:
		if thing["id"] == thing_id:
			return thing
	return {}


## Puts the player at the entrance, facing into the area (arriving from the
## farm; ADR-0016).
func enter() -> void:
	sim.player.position = entrance
	sim.player.previous_position = entrance
	sim.player.facing = Vector2.DOWN
	_in_exit = &""
	for exit: Dictionary in exits:
		if (exit["rect"] as Rect2).has_point(entrance):
			_in_exit = exit["id"]
