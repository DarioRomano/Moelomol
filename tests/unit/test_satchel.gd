extends TestCase
## One satchel for the whole game (Q37): notes found in Millbrook and at the
## farm, re-read anywhere; the great fields' field book; saves from before.

const FARM_SCENE: PackedScene = preload("res://scenes/farm/farm.tscn")
const HOUSE_SCENE: PackedScene = preload("res://scenes/farm/house.tscn")


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _press(scene: Node, action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	scene.call("_unhandled_input", event)


func test_notes_from_every_place_go_in_one_satchel() -> void:
	var state: GameState = GameState.new_game()
	var area: Area = state.make_area(GameState.MILLBROOK)
	area.satchel.append(&"lost_pet_poster")
	assert_eq(state.satchel, [&"lost_pet_poster"] as Array[StringName], "Millbrook's notes are the game's")
	state.store_area(area)
	state.satchel.append(&"field_almanac")
	var again: Area = state.make_area(GameState.MILLBROOK)
	assert_eq(again.satchel, [&"lost_pet_poster", &"field_almanac"] as Array[StringName], "and the farm's are with them")
	state.store_area(again)
	assert_eq(state.area_states[GameState.MILLBROOK]["satchel"], ["lost_pet_poster"], "an area remembers only its own")
	var view: SatchelView = SatchelView.new()
	_tree().root.add_child(view)
	view.open(state)
	assert_eq(view.entries, [&"field_almanac", &"lost_pet_poster"] as Array[StringName], "newest first")
	assert_eq(view.titles[&"field_almanac"], "A field book in the shelter", "titled from the farm's notes")
	view.free()


func test_the_loose_thread_follows_millbrooks_objective_wherever_it_is_read() -> void:
	var state: GameState = GameState.new_game()
	state.satchel.append(&"sluice_note")
	assert_true(Notes.loose_thread(&"sluice_note", state), "the miller's note, the sluice still shut")
	state.area_states[GameState.MILLBROOK] = {"objective_done": true}
	assert_false(Notes.loose_thread(&"sluice_note", state), "none once Millbrook's sluice is open")
	var area: Area = Millbrook.make()
	assert_true(Notes.loose_thread(&"sluice_note", state, area), "in Millbrook, the live area decides")
	assert_false(Notes.loose_thread(&"field_almanac", state), "the field book is no objective")


func test_the_save_keeps_the_satchel_and_takes_in_older_ones() -> void:
	var state: GameState = GameState.new_game()
	state.satchel.append_array([&"my_family", &"field_almanac"] as Array[StringName])
	var loaded: GameState = GameState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(loaded.satchel, [&"my_family", &"field_almanac"] as Array[StringName], "in the order found")
	var old: Dictionary = GameState.new_game().to_dict()
	old.erase("satchel")
	old["areas"] = {"millbrook": {"satchel": ["lost_pet_poster", "nonsense"], "objective_done": false}}
	var before: GameState = GameState.from_dict(JSON.parse_string(JSON.stringify(old)))
	assert_eq(before.satchel, [&"lost_pet_poster"] as Array[StringName], "a save from before: Millbrook's notes, unknown ones dropped")


func test_the_field_book_is_read_in_the_shelter_and_time_stands_still() -> void:
	var state: GameState = GameState.new_game()
	state.travel(GameState.FARM, GameState.AT_DOOR)
	state.farm_state = {"parcels_open": [1]}
	GameState.current = state
	var farm: Node2D = FARM_SCENE.instantiate()
	farm.set("travels", false)
	_tree().root.add_child(farm)
	var sim: FarmSim = farm.get("sim")
	var shelter: Rect2i = sim.map.bounds_of("F")
	assert_true(shelter.size != Vector2i.ZERO, "the shelter stands in the opened fields")
	sim.place_player(sim.cell_centre(Vector2i(shelter.position.x + 1, shelter.end.y)), Vector2.UP)
	Input.action_press(&"interact")
	await _tree().physics_frame
	await _tree().physics_frame
	Input.action_release(&"interact")
	var reader: NoteReader = farm.get("reader")
	assert_true(reader.is_open(), "the field book opens")
	assert_eq(state.satchel, [&"field_almanac"] as Array[StringName], "into the satchel")
	var minutes: float = state.clock.total_minutes
	for i: int in range(5):
		await _tree().physics_frame
	assert_eq(state.clock.total_minutes, minutes, "time stands still while reading")
	_press(farm, &"interact")
	assert_false(reader.is_open(), "F / B puts it back")
	Input.action_press(&"interact")  # still held from the press that closed it
	await _tree().physics_frame
	Input.action_release(&"interact")
	assert_false(reader.is_open(), "and does not open it again at once")
	_press(farm, &"satchel")
	assert_true(reader.is_open(), "I / View opens the satchel at the farm")
	_press(farm, &"satchel")
	assert_false(reader.is_open(), "and closes it")
	farm.queue_free()
	await _tree().process_frame
	GameState.current = null


func test_the_satchel_opens_in_the_farmhouse_too() -> void:
	var state: GameState = GameState.new_game()
	state.satchel.append(&"my_family")
	GameState.current = state
	var house: Node2D = HOUSE_SCENE.instantiate()
	house.set("travels", false)
	_tree().root.add_child(house)
	var reader: NoteReader = house.get("reader")
	_press(house, &"satchel")
	assert_true(reader.is_open(), "open")
	_press(house, &"interact")
	assert_true(reader.is_open(), "reading the chosen note")
	_press(house, &"interact")
	_press(house, &"satchel")
	assert_false(reader.is_open(), "closed")
	house.queue_free()
	await _tree().process_frame
	GameState.current = null


func test_every_note_fits_its_paper() -> void:
	# story.md rule 5: one screen. Laid out as the note view lays it out
	# (wrapped to the paper), every note's lines fit above the hint; the
	# first field book ran onto the hint (the render).
	var view: NoteView = NoteView.new()
	_tree().root.add_child(view)
	view.size = Vector2(640, 360)
	var text_label: Label = view.get("_text_label")
	for place: StringName in Notes.BOOKS:
		var book: Dictionary = Notes.BOOKS[place]
		for note_id: StringName in book:
			var note: Dictionary = book[note_id]
			view.open(note["title"], note["text"], false)
			await _tree().process_frame
			# The label grows to fit its text, so its minimum height is what
			# the text needs.
			var needed: float = text_label.get_minimum_size().y
			assert_true(needed <= NoteView.TEXT_HEIGHT, "%s: %d lines need %.0f px of %.0f" % [note_id,
				text_label.get_line_count(), needed, NoteView.TEXT_HEIGHT])
	view.queue_free()
	await _tree().process_frame
