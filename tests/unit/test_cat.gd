extends TestCase
## The cat (Q41 A): in one of its places by the time of day, moving only
## where the player cannot see, stroked with Interact, on the blanket after
## a fall, remembered in the save.

const FARM_SCENE: PackedScene = preload("res://scenes/farm/farm.tscn")
const HOUSE_SCENE: PackedScene = preload("res://scenes/farm/house.tscn")


func _never(_p: StringName) -> bool:
	return false


func test_its_day_by_the_clock() -> void:
	assert_eq(Cat.wanted_at(6 * 60.0, 1), Cat.BASKET, "the basket in the early morning")
	assert_eq(Cat.wanted_at(9 * 60.0, 2), Cat.PORCH, "the porch step on an even morning")
	assert_eq(Cat.wanted_at(9 * 60.0, 1), Cat.APPLE_TREE, "the apple tree on an odd one")
	assert_eq(Cat.wanted_at(14 * 60.0, 2), Cat.APPLE_TREE, "the apple tree on an even afternoon")
	assert_eq(Cat.wanted_at(14 * 60.0, 3), Cat.ROOF, "the workshop roof on an odd one")
	assert_eq(Cat.wanted_at(18 * 60.0 + 30.0, 1), Cat.BENCH, "the bench at dusk")
	assert_eq(Cat.wanted_at(23 * 60.0, 1), Cat.WINDOW_SEAT, "the window seat at night")
	assert_eq(Cat.wanted_at(3 * 60.0, 1), Cat.WINDOW_SEAT, "and after midnight")


func test_it_only_moves_where_it_cannot_be_seen() -> void:
	var cat: Cat = Cat.new()
	var clock: GameClock = GameClock.new()
	clock.total_minutes += 3 * 60.0  # 9:00 on day 1: the apple tree
	assert_false(cat.settle(clock, func(p: StringName) -> bool: return p == Cat.BASKET), "seen where it is: stays")
	assert_eq(cat.place, Cat.BASKET, "still in the basket")
	assert_false(cat.settle(clock, func(p: StringName) -> bool: return p == Cat.APPLE_TREE), "where it is going is seen: stays")
	assert_true(cat.settle(clock, _never), "neither seen: it goes")
	assert_eq(cat.place, Cat.APPLE_TREE, "and is simply there")
	assert_false(cat.settle(clock, _never), "already where it wants to be")


func test_it_sits_where_the_player_can_reach_it() -> void:
	var farm: FarmSim = FarmSim.make_farm()
	for p: StringName in [Cat.PORCH, Cat.APPLE_TREE]:
		var at: Vector2 = Cat.farm_position(p, farm.map)
		assert_false(farm.map.is_solid(farm.cell_at(at)), "%s is on open ground" % p)
	var bench: Vector2 = Cat.farm_position(Cat.BENCH, farm.map)
	assert_eq(farm.map.char_at(farm.cell_at(bench)), "n", "on the bench")
	var roof: Vector2 = Cat.farm_position(Cat.ROOF, farm.map)
	assert_true(farm.map.char_at(farm.cell_at(roof)) in ["B", "b"], "up on the workshop")
	var house: HouseSim = HouseSim.new()
	assert_eq(house.map.char_at(house.cell_at(Cat.house_position(Cat.BASKET, house.map))), "k", "in its basket")
	assert_eq(house.map.char_at(house.cell_at(Cat.house_position(Cat.WINDOW_SEAT, house.map))), "S", "on the window seat")
	assert_eq(house.map.char_at(house.cell_at(Cat.house_position(Cat.BLANKET, house.map))), "B", "on the bed")
	assert_eq(Cat.farm_position(Cat.BASKET, farm.map), Vector2.INF, "the basket is not at the farm")


func test_interact_facing_it_strokes_it() -> void:
	var farm: FarmSim = FarmSim.make_farm()
	farm.cat_position = Cat.farm_position(Cat.PORCH, farm.map)
	farm.place_player(farm.cat_position + Vector2(10, 0), Vector2.LEFT)
	farm.step(FarmInput.press(&"interact"))
	assert_eq(farm.events[0]["type"], "stroke", "stroked")
	assert_eq(Haptics.effect_for_farm_event(farm.events[0]), &"cat_purr", "a purr on the controller")
	farm.place_player(farm.cat_position + Vector2(10, 0), Vector2.RIGHT)
	farm.step(FarmInput.press(&"interact"))
	assert_true(farm.events.is_empty() or farm.events[0]["type"] != "stroke", "not when facing away")
	var house: HouseSim = HouseSim.new()
	house.cat_position = Cat.house_position(Cat.BASKET, house.map)
	house.place_player(house.cat_position + Vector2(0, 12), Vector2.UP)
	house.interact()
	assert_eq(house.events[0]["type"], "stroke", "in the house too")
	var cat: Cat = Cat.new()
	cat.stroke()
	assert_true(cat.purr_ticks > 0, "its eyes close a while")


func test_after_a_fall_it_is_on_the_blanket_and_stays_while_the_player_is_in() -> void:
	var state: GameState = GameState.new_game()
	state.cat.place = Cat.APPLE_TREE
	state.fell()
	assert_eq(state.cat.place, Cat.BLANKET, "curled on the blanket (Q36)")
	GameState.current = state
	var house: Node2D = HOUSE_SCENE.instantiate()
	house.set("travels", false)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(house)
	var sim: HouseSim = house.get("sim")
	for i: int in range(5):
		await tree.physics_frame
	assert_eq(state.cat.place, Cat.BLANKET, "still there: the whole room is in view")
	assert_true(sim.cat_curled, "curled up")
	assert_eq(sim.cat_position, Cat.house_position(Cat.BLANKET, sim.map), "on the bed")
	house.queue_free()
	await tree.process_frame
	# Out of the house, it goes where it wants (the basket at 6:00), unseen.
	assert_true(state.cat.settle(state.clock, _never), "leaves the blanket once unseen")
	assert_eq(state.cat.place, Cat.BASKET, "the basket")
	GameState.current = null


func test_at_the_farm_it_moves_only_out_of_view() -> void:
	var state: GameState = GameState.new_game()
	state.travel(GameState.FARM, GameState.AT_GATE)  # arriving up the lane, far from the house
	state.clock.total_minutes += GameClock.MINUTES_PER_DAY + 3 * 60.0  # day 2, 9:00: the porch step
	GameState.current = state
	var farm: Node2D = FARM_SCENE.instantiate()
	farm.set("travels", false)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(farm)
	var sim: FarmSim = farm.get("sim")
	await tree.physics_frame
	await tree.physics_frame
	assert_eq(state.cat.place, Cat.PORCH, "came out to the porch step while unseen")
	assert_eq(sim.cat_position, Cat.farm_position(Cat.PORCH, sim.map), "the farm knows where it sits")
	# By the door, the porch step in view; the afternoon comes (the apple tree).
	sim.place_player(sim.wake_position, Vector2.DOWN)
	var camera: FollowCamera = farm.get("camera")
	camera.snap(sim.player_position, farm.call("view_size"), sim.bounds(), farm.call("view_scale"))
	state.clock.total_minutes += 4 * 60.0  # 13:00
	await tree.physics_frame
	assert_eq(state.cat.place, Cat.PORCH, "watched, it stays")
	sim.place_player(sim.gate_position, Vector2.UP)
	camera.snap(sim.player_position, farm.call("view_size"), sim.bounds(), farm.call("view_scale"))
	await tree.physics_frame
	await tree.physics_frame
	assert_eq(state.cat.place, Cat.APPLE_TREE, "out of sight, it has gone to the apple tree")
	farm.queue_free()
	await tree.process_frame
	GameState.current = null


func test_the_save_remembers_where_it_is() -> void:
	var state: GameState = GameState.new_game()
	state.cat.place = Cat.BENCH
	var loaded: GameState = GameState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(loaded.cat.place, Cat.BENCH, "on the bench")
	var odd: Dictionary = state.to_dict()
	odd["cat"] = {"place": "the moon"}
	assert_eq(GameState.from_dict(odd).cat.place, Cat.BASKET, "an unknown place is not trusted")
	odd.erase("cat")
	assert_eq(GameState.from_dict(odd).cat.place, Cat.BASKET, "a save from before the cat: the basket")
