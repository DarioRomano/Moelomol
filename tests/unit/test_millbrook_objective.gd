extends TestCase
## Millbrook's objective, notes and satchel (docs/design/area-millbrook.md,
## "The objective"; Q37), in the Area rules: the player is placed beside
## things and interact() is called, as the F / B button does.


func _area() -> Area:
	var area: Area = Millbrook.make()
	for c: Fighter in area.sim.creatures:
		c.ai_enabled = false  # nothing interrupts
	return area


func _thing(area: Area, thing_id: StringName) -> Dictionary:
	for thing: Dictionary in area.things:
		if thing["id"] == thing_id:
			return thing
	return {}


func _go_to(area: Area, thing_id: StringName) -> void:
	var at: Vector2 = _thing(area, thing_id)["position"]
	area.sim.player.position = at + Vector2(0, 4)
	area.sim.player.previous_position = area.sim.player.position


func _run(area: Area, ticks: int) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(ticks):
		area.step(CombatInput.new())
		seen.append_array(area.events)
	return seen


func test_interact_and_satchel_are_bound_for_keyboard_and_controller() -> void:
	var bindings: Dictionary = {&"interact": [KEY_F, JOY_BUTTON_B], &"satchel": [KEY_I, JOY_BUTTON_BACK]}
	for action: StringName in bindings:
		var key: InputEventKey = InputEventKey.new()
		key.keycode = bindings[action][0]
		key.pressed = true
		assert_true(InputMap.event_is_action(key, action), "%s on the keyboard" % action)
		var button: InputEventJoypadButton = InputEventJoypadButton.new()
		button.button_index = bindings[action][1]
		button.device = 1  # any controller, not just the first (CLAUDE.md)
		button.pressed = true
		assert_true(InputMap.event_is_action(button, action), "%s on any controller" % action)


func test_every_note_is_placed_where_the_player_can_reach_it() -> void:
	var area: Area = _area()
	var placed: Array[StringName] = []
	for thing: Dictionary in area.things:
		var cell: Vector2i = AreaMap.cell_of(thing["position"])
		assert_false(area.map.is_solid(cell), "%s stands on open ground" % thing["id"])
		if thing["kind"] == &"note":
			placed.append(thing["id"])
	for note_id: StringName in MillbrookNotes.NOTES:
		assert_true(note_id in placed, "%s is placed" % note_id)


func test_reading_a_note_keeps_it_in_the_satchel_newest_first() -> void:
	var area: Area = _area()
	_go_to(area, &"lost_pet_poster")
	assert_eq(area.interact(), {"type": "note", "note": &"lost_pet_poster"}, "the poster")
	_go_to(area, &"my_family")
	area.interact()
	_go_to(area, &"lost_pet_poster")
	area.interact()  # read again: not a second copy
	assert_eq(area.satchel_newest_first(), [&"my_family", &"lost_pet_poster"] as Array[StringName], "newest first, once each")


func test_nothing_in_reach_does_nothing() -> void:
	var area: Area = _area()
	area.sim.player.position = Vector2(900, 400)
	assert_eq(area.interact()["type"], "nothing", "nothing near")


func test_the_sluice_will_not_turn_without_the_crank() -> void:
	var area: Area = _area()
	_go_to(area, &"sluice")
	assert_eq(area.interact()["type"], "sluice_stuck", "stuck")
	assert_false(area.objective_done, "still shut")


func test_the_miller_s_note_carries_a_loose_thread_until_the_sluice_opens() -> void:
	var area: Area = _area()
	assert_true(area.has_loose_thread(&"sluice_note"), "the miller's note: a loose thread")
	assert_false(area.has_loose_thread(&"lost_pet_poster"), "the poster: none")
	area.objective_done = true
	assert_false(area.has_loose_thread(&"sluice_note"), "none once the sluice is open")


func test_the_crank_opens_the_sluice_and_the_meadow_drains_over_ten_seconds() -> void:
	var area: Area = _area()
	_go_to(area, &"sluice_crank")
	assert_eq(area.interact(), {"type": "taken", "item": &"sluice_crank"}, "the crank from the hook")
	assert_eq(area.bag.count(&"sluice_crank"), 1, "carried")
	_go_to(area, &"sluice")
	assert_eq(area.interact()["type"], "sluice_opened", "the sluice opens")
	assert_true(area.objective_done, "the objective is done")
	assert_eq(area.bag.count(&"sluice_crank"), 0, "the crank stays on the wheel")
	var flood: Vector2i = area.map.cells_of("w")[0]
	var ticks: int = roundi(Area.DRAIN_SECONDS * Engine.physics_ticks_per_second)
	_run(area, ticks - 2)
	assert_true(area.map.is_solid(flood), "still water just before ten seconds")
	assert_true(area.drain_progress > 0.95, "nearly drained (%.2f)" % area.drain_progress)
	var seen: Array[Dictionary] = _run(area, 3)
	assert_false(area.map.is_solid(flood), "the meadow can be walked")
	assert_eq(seen.filter(func(e: Dictionary) -> bool: return e["type"] == "drained").size(), 1, "reported once")


func test_the_ford_is_an_exit_only_once_the_meadow_drains() -> void:
	var area: Area = _area()
	area.sim.player.position = Vector2(28 * AreaMap.CELL, area.map.rect().end.y - 6)
	var seen: Array[Dictionary] = _run(area, 2)
	assert_eq(seen.filter(func(e: Dictionary) -> bool: return e["type"] == "exit").size(), 0, "not while flooded")
	area.map.drained = true
	seen = _run(area, 5)
	var exits: Array[Dictionary] = seen.filter(func(e: Dictionary) -> bool: return e["type"] == "exit")
	assert_eq(exits.size(), 1, "reported once while standing there")
	assert_eq(exits[0]["to"], &"south", "the way south")


func test_the_lane_s_top_is_the_way_back_to_the_farm() -> void:
	var area: Area = _area()
	area.sim.player.position = Vector2(28 * AreaMap.CELL, 6)
	var seen: Array[Dictionary] = _run(area, 1)
	var exits: Array[Dictionary] = seen.filter(func(e: Dictionary) -> bool: return e["type"] == "exit")
	assert_eq(exits.size(), 1, "an exit")
	assert_eq(exits[0]["to"], &"farm", "to the farm")


func test_grist_leaves_its_heart_and_the_note_for_after_appears() -> void:
	var area: Area = _area()
	var grist: Fighter = null
	for c: Fighter in area.sim.creatures:
		if c.creature_kind.id == &"grist":
			grist = c
	assert_false(_thing(area, &"grist_apples")["shown"], "the note for after is not there yet")
	grist.health = 1.0
	var blow: CombatMove = CombatMove.make(&"test", "Test", Vector3i.ZERO, 10.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	area.sim._hit(area.sim.player, grist, blow)
	area.step(CombatInput.new())
	var heart: Dictionary = _thing(area, &"grist_heart")
	assert_false(heart.is_empty(), "the heart lies where Grist fell")
	assert_true((heart["position"] as Vector2).distance_to(grist.position) < 1.0, "at its place")
	assert_true(_thing(area, &"grist_apples")["shown"], "and the miller's note about Grist appears")
	_go_to(area, &"grist_heart")
	assert_eq(area.interact(), {"type": "taken", "item": &"grist_heart"}, "taken")
	assert_eq([area.bag.count(&"grist_heart"), area.bag.count(&"tusk")], [1, 1], "the heart and the tusk")
	assert_eq(area.interact()["type"], "nothing", "gone from the ground")


func test_no_interacting_mid_attack() -> void:
	var area: Area = _area()
	_go_to(area, &"lost_pet_poster")
	area.sim.start_attack(area.sim.player, Greatsword.LIGHTS[0])
	assert_eq(area.interact()["type"], "nothing", "busy swinging")
