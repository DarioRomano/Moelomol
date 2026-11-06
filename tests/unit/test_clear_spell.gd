extends TestCase
## The Clear spell (Q38; base.md step 3): long grass to grass for 2 Mana.
## The old fields then take Till; long grass elsewhere becomes lawn;
## thicket and short grass are untouched. The farm remembers it.


## Stands the player next to `cell`, facing it, with `spell` selected.
func _face(sim: FarmSim, cell: Vector2i, spell: StringName) -> void:
	for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var stand: Vector2i = cell + step
		if not sim.map.is_solid(stand):
			sim.place_player(sim.cell_centre(stand), Vector2(-step))
			break
	assert_eq(sim.target_cell(), cell, "facing %s" % cell)
	sim.spell_index = sim.spells.find(spell)
	sim.busy = 0


func _cast(sim: FarmSim) -> Dictionary:
	sim.busy = 0
	sim.step(FarmInput.press(&"use"))
	return sim.events[0] if not sim.events.is_empty() else {}


func test_clear_is_a_farm_spell_after_water() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	assert_eq(sim.spells.slice(0, 3), [FarmSim.TILL, FarmSim.WATER, FarmSim.CLEAR] as Array[StringName], "Till, Water, Clear")
	assert_eq(sim.spell_mana(FarmSim.CLEAR), 2.0, "2 Mana (starting value)")
	assert_eq(sim.spell_name(FarmSim.CLEAR), "Clear", "named")
	assert_false(FarmSim.CLEAR in FarmSim.make_test_farm().spells, "not on the test field, which has no long grass")


func test_clearing_an_old_field_makes_it_tillable() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	var cell: Vector2i = sim.map.cells_of(":")[0]
	_face(sim, cell, FarmSim.TILL)
	assert_eq(_cast(sim)["type"], "nothing", "the old field cannot be tilled under its long grass")
	_face(sim, cell, FarmSim.CLEAR)
	var event: Dictionary = _cast(sim)
	assert_eq(event["type"], "clear", "cleared")
	assert_eq(sim.mana.current, 98.0, "for 2 Mana")
	assert_true(sim.cleared.has(cell), "the farm knows")
	assert_eq(Haptics.effect_for_farm_event(event), &"farm_till", "felt like tilling")
	_face(sim, cell, FarmSim.CLEAR)
	assert_eq(_cast(sim)["type"], "nothing", "clearing twice does nothing")
	assert_eq(sim.mana.current, 98.0, "and costs nothing")
	_face(sim, cell, FarmSim.TILL)
	assert_eq(_cast(sim)["type"], "till", "now it tills")
	assert_true(sim.plot.is_tilled(cell), "tilled")


func test_long_grass_elsewhere_becomes_lawn_not_field() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	var cell: Vector2i = sim.map.cells_of(",")[0]
	_face(sim, cell, FarmSim.CLEAR)
	assert_eq(_cast(sim)["type"], "clear", "cleared")
	_face(sim, cell, FarmSim.TILL)
	assert_eq(_cast(sim)["type"], "nothing", "lawn is not for tilling")


func test_clear_leaves_thicket_grass_and_paths_alone() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	# The north gate's top tile looks out at the great fields' thicket.
	var gate: Vector2i = sim.map.cells_of("G")[0]
	sim.place_player(sim.cell_centre(gate), Vector2.UP)
	sim.spell_index = sim.spells.find(FarmSim.CLEAR)
	assert_true(sim.map.char_at(sim.target_cell()) in ["1", "#"], "facing the thicket")
	for cell: Vector2i in [sim.map.cells_of(".")[0], sim.map.cells_of("=")[0], sim.map.cells_of("T")[0]]:
		_face(sim, cell, FarmSim.CLEAR)
		assert_eq(_cast(sim)["type"], "nothing", "%s is not long grass" % sim.map.char_at(cell))
	assert_eq(sim.mana.current, 100.0, "no Mana spent on nothing")
	assert_false(sim.can_clear(Vector2i(70, 60)), "thicket, without a boss's heart")


func test_not_enough_mana_clears_nothing() -> void:
	var sim: FarmSim = FarmSim.make_farm()
	sim.mana.try_spend(99.0)
	var cell: Vector2i = sim.map.cells_of(":")[0]
	_face(sim, cell, FarmSim.CLEAR)
	assert_eq(_cast(sim)["type"], "no_mana", "not enough")
	assert_false(sim.cleared.has(cell), "still long grass")


func test_the_farm_and_the_save_remember_cleared_ground() -> void:
	var state: GameState = GameState.new_game()
	state.travel(GameState.FARM, GameState.AT_DOOR)
	var sim: FarmSim = state.make_farm()
	var old_field: Vector2i = sim.map.cells_of(":")[0]
	var lawn: Vector2i = sim.map.cells_of(",")[0]
	sim.clear_tile(old_field)
	sim.clear_tile(lawn)
	sim.plot.till(old_field)
	sim.plot.plant(old_field, &"radish")
	state.store_farm(sim)
	var loaded: GameState = GameState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	var again: FarmSim = loaded.make_farm()
	assert_true(again.cleared.has(old_field) and again.cleared.has(lawn), "both cleared tiles")
	assert_true(again.plot.is_tilled(old_field), "the tilled old field (cleared before the soil was restored)")
	assert_eq(again.plot.crop_at(old_field), &"radish", "and its radish")
	assert_true(again.plot.is_blocked(lawn), "the lawn still not for tilling")
	# A farm saved before Clear existed has nothing cleared.
	var old: Dictionary = state.farm_state.duplicate(true)
	old.erase("cleared")
	old["cells"] = []
	var before: FarmSim = FarmSim.make_farm()
	before.apply_state(old)
	assert_eq(before.cleared.size(), 0, "nothing cleared")
	# Entries that are not long grass are ignored.
	var forged: FarmSim = FarmSim.make_farm()
	forged.apply_state({"cleared": [[70, 60], [sim.map.cells_of("T")[0].x, sim.map.cells_of("T")[0].y]]})
	assert_eq(forged.cleared.size(), 0, "thicket and the field cannot be 'cleared' by a save")
