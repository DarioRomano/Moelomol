extends TestCase
## The farm and Millbrook joined at the gate (ADR-0016): one clock, one bag
## and one Mana for the whole game; each place remembers itself between
## visits; falling out there wakes the player in the farm bed (Q36).

const T: GDScript = preload("res://src/combat/combat_tuning.gd")
const FARM_SCENE: PackedScene = preload("res://scenes/farm/farm.tscn")
const MILLBROOK_SCENE: PackedScene = preload("res://scenes/world/millbrook.tscn")


## Walks the farm's player until an exit is reported; returns where to.
func _walk_farm_out(sim: FarmSim, direction: Vector2, ticks: int) -> StringName:
	for i: int in range(ticks):
		sim.step(FarmInput.with_move(direction))
		for e: Dictionary in sim.events:
			if e["type"] == "exit":
				return e["to"]
	return &""


func _walk_area_out(area: Area, direction: Vector2, ticks: int) -> StringName:
	var input: CombatInput = CombatInput.new()
	input.move = direction
	for i: int in range(ticks):
		area.step(input)
		for e: Dictionary in area.events:
			if e["type"] == "exit":
				return e["to"]
	return &""


## Down through the farm's south gate to Millbrook and back.
func _round_trip(state: GameState) -> Dictionary:
	var farm: FarmSim = state.make_farm()
	farm.place_player(farm.gate_position, Vector2.DOWN)
	assert_eq(_walk_farm_out(farm, Vector2.DOWN, 120), &"millbrook", "down the lane to Millbrook")
	state.store_farm(farm)
	state.travel(GameState.MILLBROOK, GameState.AT_GATE)
	var area: Area = state.make_area(GameState.MILLBROOK)
	var arrived_in_area: Dictionary = {"position": area.sim.player.position, "facing": area.sim.player.facing,
		"minutes": state.clock.total_minutes}
	for c: Fighter in area.sim.creatures:
		c.ai_enabled = false
	assert_eq(_walk_area_out(area, Vector2.UP, 120), &"farm", "up Millbrook's lane to the farm")
	state.store_area(area)
	state.travel(GameState.FARM, GameState.AT_GATE)
	return {"area": arrived_in_area, "farm": state.make_farm()}


func test_through_the_gate_and_back() -> void:
	# ADR-0016, Verification.
	var state: GameState = GameState.new_game()
	var start: float = state.clock.total_minutes
	var trip: Dictionary = _round_trip(state)
	var in_area: Dictionary = trip["area"]
	var farm: FarmSim = trip["farm"]
	assert_eq(in_area["position"], Millbrook.make().entrance, "in Millbrook at the top of the lane")
	assert_eq(in_area["facing"], Vector2.DOWN, "facing away from the farm, into Millbrook")
	assert_true(float(in_area["minutes"]) > start, "the clock ran on the way down")
	assert_eq(farm.player_position, farm.gate_position, "back at the farm, in the lane below the gate")
	assert_eq(farm.facing, Vector2.UP, "facing away from Millbrook, up to the homestead")
	assert_true(state.clock.total_minutes > float(in_area["minutes"]), "the clock kept running")
	assert_eq(farm.clock, state.clock, "one clock for the whole game")


func test_the_farm_scene_loads_no_combat() -> void:
	# ADR-0016, Verification: no combat nodes or simulation at the farm.
	GameState.current = null
	var farm: Node2D = FARM_SCENE.instantiate()
	farm.set("travels", false)
	(Engine.get_main_loop() as SceneTree).root.add_child(farm)
	await (Engine.get_main_loop() as SceneTree).process_frame
	for node: Node in farm.find_children("*", "", true, false):
		assert_false(node is CombatHud, "no combat HUD")
		var script: Script = node.get_script()
		assert_true(script == null or not script.resource_path.contains("/combat/"), "%s is not combat" % node.name)
	for property: Dictionary in farm.get_property_list():
		var value: Variant = farm.get(property["name"])
		assert_false(value is CombatSim or value is Area or value is Fighter, "%s is not combat" % property["name"])
	var source: String = (farm.get_script() as GDScript).source_code
	assert_false(source.contains("Combat"), "the farm's scene script never mentions combat")
	farm.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame


func test_crops_grow_while_the_player_is_away_once_per_watering() -> void:
	var state: GameState = GameState.new_game()
	var farm: FarmSim = state.make_farm()
	var cell: Vector2i = farm.map.cells_of("T")[0]
	farm.plot.till(cell)
	farm.plot.plant(cell, &"radish")
	farm.plot.water(cell)
	state.store_farm(farm)
	state.travel(GameState.MILLBROOK, GameState.AT_GATE)
	# Two whole days pass out there.
	state.clock.total_minutes += 2.0 * GameClock.MINUTES_PER_DAY
	state.travel(GameState.FARM, GameState.AT_GATE)
	var back: FarmSim = state.make_farm()
	assert_eq(back.plot.crop_at(cell), &"radish", "the radish is still there")
	assert_eq(back.plot.grown_days(cell), 1, "it grew once: it was watered once")
	assert_false(back.plot.is_watered(cell), "the soil has dried")


func test_the_bag_and_mana_are_the_game_s_not_a_place_s() -> void:
	var state: GameState = GameState.new_game()
	var area: Area = state.make_area(GameState.MILLBROOK)
	area.bag.add(&"sluice_crank")
	state.mana.try_spend(30.0)
	state.store_area(area)
	state.travel(GameState.FARM, GameState.AT_GATE)
	var farm: FarmSim = state.make_farm()
	assert_eq(farm.inventory.count(&"sluice_crank"), 1, "the crank came home")
	assert_eq(farm.inventory.count(&"radish_seeds"), 6, "the seed tin's seeds are in the same bag")
	assert_eq(farm.mana.current, 70.0, "the same Mana")
	assert_eq(FarmSim.item_name(&"sluice_crank"), "Sluice crank", "named in the HUD")


func test_millbrook_remembers_notes_things_the_sluice_and_today_s_defeats() -> void:
	var state: GameState = GameState.new_game()
	var area: Area = state.make_area(GameState.MILLBROOK)
	area.satchel.append(&"lost_pet_poster")
	for thing: Dictionary in area.things:
		if thing["id"] == &"sluice_crank":
			thing["taken"] = true
	area.objective_done = true
	area.drain_progress = 0.4
	var mouse_index: int = -1
	for i: int in range(area.roster.size()):
		if area.roster[i]["kind"] == &"field_mouse" and area.roster[i]["fighter"] != null:
			mouse_index = i
			area.sim.defeat(area.roster[i]["fighter"])
			break
	state.store_area(area)
	var again: Area = state.make_area(GameState.MILLBROOK)
	assert_eq(again.satchel, [&"lost_pet_poster"] as Array[StringName], "the note is in the satchel")
	assert_true(again.objective_done, "the sluice is open")
	assert_eq(again.drain_progress, 0.4, "the meadow drains on from where it was")
	for thing: Dictionary in again.things:
		if thing["id"] == &"sluice_crank":
			assert_true(thing["taken"], "the crank is not back on its hook")
	assert_eq(again.roster[mouse_index]["fighter"], null, "the mouse defeated today is not back today")
	var mice: Callable = func(a: Area) -> int:
		return a.sim.creatures.filter(func(c: Fighter) -> bool: return c.creature_kind.id == &"field_mouse").size()
	assert_eq(mice.call(again), mice.call(Millbrook.make()) - 1, "nor anywhere in the area: one mouse fewer")
	# The next morning it is.
	state.clock.sleep_until_morning()
	var next_day: Area = state.make_area(GameState.MILLBROOK)
	assert_true(next_day.roster[mouse_index]["fighter"] != null, "back the next day")


func test_grist_stays_defeated_and_its_heart_stays_where_it_fell() -> void:
	var state: GameState = GameState.new_game()
	var area: Area = state.make_area(GameState.MILLBROOK)
	var grist: Fighter = null
	for c: Fighter in area.sim.creatures:
		if c.creature_kind.id == &"grist":
			grist = c
	area.sim.defeat(grist)
	area.step(CombatInput.new())
	var fell_at: Vector2 = grist.position
	state.store_area(area)
	state.clock.sleep_until_morning()
	var again: Area = state.make_area(GameState.MILLBROOK)
	assert_eq(again.sim.creatures.filter(func(c: Fighter) -> bool: return c.creature_kind.id == &"grist").size(), 0,
		"Grist is not back, days later")
	var heart: Array[Dictionary] = again.things.filter(func(t: Dictionary) -> bool: return t["id"] == &"grist_heart")
	assert_eq(heart.size(), 1, "its heart is there")
	assert_eq(heart[0]["position"], fell_at, "where it fell")
	assert_eq(heart[0]["kind"], &"heart", "a heart to take")


func test_falling_out_there_wakes_the_player_in_the_farm_bed() -> void:
	var state: GameState = GameState.new_game()
	state.mana.try_spend(60.0)
	var area: Area = state.make_area(GameState.MILLBROOK)
	area.bag.add(&"tusk")
	area.sim.player.position = Vector2(900, 400)
	var day: int = state.clock.day()
	area.sim.defeat(area.sim.player)
	var fell: bool = false
	for i: int in range(T.ticks(T.PLAYER_DOWN_MS) + 2):
		area.step(CombatInput.new())
		for e: Dictionary in area.events:
			fell = fell or e["type"] == "fell"
	assert_true(fell, "the area reports the fall")
	state.store_area(area)
	state.fell()
	assert_eq(state.place, GameState.FARM, "home")
	var farm: FarmSim = state.make_farm()
	assert_eq(state.clock.day(), day + 1, "the next day")
	assert_true(absf(state.clock.minute() - GameClock.DAY_START_MINUTE) < 1.0, "at 6:00")
	assert_eq(farm.player_position, farm.wake_position, "in front of the farmhouse door (the bed, for now)")
	assert_eq(farm.mana.current, farm.mana.maximum, "rested: Mana full")
	assert_eq(farm.inventory.count(&"tusk"), 1, "everything carried is kept")


func test_the_scenes_hand_over_at_the_exits() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	GameState.current = null
	var farm: Node2D = FARM_SCENE.instantiate()
	farm.set("travels", false)
	tree.root.add_child(farm)
	var state: GameState = farm.get("state")
	var went: Array[StringName] = []
	farm.connect("leaving", func(to: StringName) -> void: went.append(to))
	var sim: FarmSim = farm.get("sim")
	sim.place_player(sim.gate_position, Vector2.DOWN)
	Input.action_press(&"move_down")
	for i: int in range(60):
		await tree.physics_frame
	Input.action_release(&"move_down")
	assert_eq(went, [&"millbrook"] as Array[StringName], "the farm scene leaves for Millbrook once")
	assert_eq(state.place, GameState.MILLBROOK, "the game is in Millbrook now")
	assert_false(state.farm_state.is_empty(), "the farm stored itself")
	farm.queue_free()
	await tree.process_frame
	var millbrook: Node2D = MILLBROOK_SCENE.instantiate()
	millbrook.set("travels", false)
	tree.root.add_child(millbrook)
	assert_eq(millbrook.get("state"), state, "the same game")
	var area: Area = millbrook.get("area")
	assert_eq(area.sim.player.position, area.entrance, "at the top of the lane")
	went.clear()
	millbrook.connect("leaving", func(to: StringName) -> void: went.append(to))
	area.sim.player.position = area.entrance + Vector2(0, -34)
	await tree.physics_frame
	await tree.physics_frame
	assert_eq(went, [&"farm"] as Array[StringName], "and Millbrook's lane leads home")
	assert_eq(state.arrival, GameState.AT_GATE, "arriving at the gate")
	millbrook.queue_free()
	await tree.process_frame
	GameState.current = null
