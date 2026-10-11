extends Node2D
## Millbrook, the first area (docs/design/area-millbrook.md), walkable:
## reached with F2 or `--start-scene millbrook`. The farm is not built yet, so
## the player starts at the top of the lane and wakes there after falling.
##
## Each physics tick (fixed 60 Hz) it reads input, steps the Area (clock,
## roster, combat), plays haptics and moves the camera (ADR-0015). It draws the
## map (AreaDrawer), then everything that moves (CombatDrawer), under the time
## of day's tint, with the night's sight ring around the player.
##
## Interact (F / B) reads notes, takes things and turns the sluice; the
## satchel (I / View) holds every note found (Q37). Time pauses while a note or
## the satchel is open (farming.md).
##
## Developer keys: F6 creatures passive, F7 the other weapon, F8 skips to the
## next 20:00 or 6:00, F9 time 30 times faster.

const FAST_TIME: float = 30.0
## Night sight (world.md, Proposal): clear within about 7 tiles.
const SIGHT_RADIUS: float = 112.0
const SIGHT_FADE: float = 64.0
const SIGHT_DARK: float = 0.85  # how dark it is beyond the fade

var area: Area = Millbrook.make()
var camera: FollowCamera = FollowCamera.new()
var haptics: Haptics = Haptics.new()
var effects: Array[Dictionary] = []

var _camera_node: Camera2D
var _tint: CanvasModulate
var _hud: CombatHud
var _note: NoteView
var _satchel: SatchelView
var _toast: String = ""  # a quiet line in the HUD: what was just taken
var _toast_ticks: int = 0


func _ready() -> void:
	_camera_node = Camera2D.new()
	add_child(_camera_node)
	camera.snap(area.sim.player.position, view_size(), area.map.rect(), view_scale())
	_camera_node.position = camera.position
	_tint = CanvasModulate.new()
	add_child(_tint)
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var frame: UiFrame = UiFrame.new()
	layer.add_child(frame)
	_hud = CombatHud.new()
	frame.add_child(_hud)
	_hud.set_help("Move WASD / stick   Light J / X   Heavy (hold) K / RT   Skill L / Y   Dodge Space / A   Swap Tab / RB\n"
		+ "Lock Shift / LT   Switch Q E / right stick   Interact F / B   Satchel I / View   F6-F9 developer keys")
	_satchel = SatchelView.new()
	frame.add_child(_satchel)
	_note = NoteView.new()
	frame.add_child(_note)


## True while a note or the satchel is open: time stands still.
func is_paused() -> bool:
	return _note.visible or _satchel.visible


## The visible area in layout px and the screen's scale (ADR-0008).
func view_size() -> Vector2:
	return Vector2(DisplayMath.expected_view_size(DisplayServer.window_get_size()))


func view_scale() -> float:
	return float(DisplayMath.expected_scale(DisplayServer.window_get_size()))


func _physics_process(delta: float) -> void:
	if is_paused():
		return
	if _toast_ticks > 0:
		_toast_ticks -= 1
	area.step(CombatInput.read())
	for event: Dictionary in area.sim.events:
		var effect: StringName = Haptics.effect_for_event(event)
		if effect != &"":
			haptics.play(effect)
	haptics.sustain(area.sim.player_rumble())
	CombatDrawer.update_effects(effects, area.sim.events)
	for event: Dictionary in area.events:
		match event["type"]:
			"woke":
				camera.snap(area.sim.player.position, view_size(), area.map.rect(), view_scale())
			"drained":
				show_toast("The meadow has drained.")
			"exit":
				# The farm and the second area are not built yet: a developer
				# line, not the game's voice.
				var to: StringName = event["to"]
				show_toast("[not built yet] " + ("the way back up to the farm" if to == &"farm" else "the road south"))
	camera.update(area.sim.player.position, view_size(), area.map.rect(), view_scale(), delta)
	_camera_node.position = camera.position


func _process(_delta: float) -> void:
	queue_redraw()
	_tint.color = area.clock.sky_tint()
	_hud.show_state(area.sim, true, "Millbrook   day %d   %s%s%s" % [area.clock.day(), area.clock.time_text(),
		"   (time x30)" if area.time_scale != 1.0 else "", ("\n" + _toast) if _toast_ticks > 0 else ""])


func _draw() -> void:
	var view: Rect2 = Rect2(camera.position - view_size() / 2.0, view_size())
	draw_rect(view.grow(64.0), Palette.WILD[0])  # beyond the map's edge: more woods
	AreaDrawer.draw(self, area.map, view, area.sim.tick_count, area.drain_progress)
	_draw_things(view)
	CombatDrawer.draw(self, area.sim, Engine.get_physics_interpolation_fraction(), effects, false)
	_draw_prompt()
	if area.is_night():
		_draw_sight(view)


## The night's sight: clear around the player, fading into the dark; lights
## glow through it.
func _draw_sight(view: Rect2) -> void:
	var centre: Vector2 = area.sim.player.position + Vector2(0, -10)
	var far: float = view.size.length()
	# A soft edge: eight thin rings, each a little darker.
	var steps: int = 8
	var band: float = SIGHT_FADE / steps
	for i: int in range(steps):
		var alpha: float = SIGHT_DARK * float(i + 1) / (steps + 1)
		draw_arc(centre, SIGHT_RADIUS + band * (i + 0.5), 0, TAU, 64, Color(Palette.SHADOW[0], alpha), band + 0.5)
	var outer: float = SIGHT_RADIUS + SIGHT_FADE
	draw_arc(centre, outer + far * 0.5, 0, TAU, 64, Color(Palette.SHADOW[0], SIGHT_DARK), far)
	for light: Vector2 in area.sim.lights:
		if view.grow(32.0).has_point(light):
			draw_circle(light, 20.0, Color(Palette.CHANGED[2], 0.18))
			draw_circle(light, 6.0, Color(Palette.CROPS[1], 0.5))


## A quiet line in the HUD for a few seconds (art-direction.md: progress is
## shown quietly).
func show_toast(text: String) -> void:
	_toast = text
	_toast_ticks = 180


## The F / B button: put a note back, read from the satchel, or interact.
func press_interact() -> void:
	if _note.visible:
		_note.close()
		return
	if _satchel.visible:
		var chosen: StringName = _satchel.chosen()
		if chosen != &"":
			_open_note(chosen)
		return
	var result: Dictionary = area.interact()
	match result["type"]:
		"note":
			_open_note(result["note"])
		"taken":
			var names: Dictionary = {&"sluice_crank": "Taken: the sluice crank.", &"grist_heart": "Taken: Grist's heart, and a tusk."}
			show_toast(names.get(result["item"], "Taken."))
			haptics.play(&"farm_harvest")
		"sluice_stuck":
			haptics.play(&"no_stamina")  # a dull buzz: the wheel has no crank
		"sluice_opened":
			haptics.play(&"farm_rain")  # a long soft roll: the water turns


## The I / View button: open or close the satchel.
func press_satchel() -> void:
	if _note.visible:
		_note.close()
	if _satchel.visible:
		_satchel.close()
	else:
		_satchel.open(area)


func _open_note(note_id: StringName) -> void:
	var note: Dictionary = area.notes[note_id]
	_note.open(note["title"], note["text"], area.has_loose_thread(note_id))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact", false):
		press_interact()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"satchel", false):
		press_satchel()
		get_viewport().set_input_as_handled()
		return
	if _satchel.visible and not _note.visible:
		if event.is_action_pressed(&"move_up", false):
			_satchel.move_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"move_down", false):
			_satchel.move_selection(1)
			get_viewport().set_input_as_handled()
		return
	if is_paused():
		return
	if event.is_action_pressed(&"dev_toggle_creatures_passive", false):
		for creature: Fighter in area.sim.creatures:
			creature.ai_enabled = not creature.ai_enabled
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_cycle_offhand_weapon", false):
		area.sim.cycle_offhand_weapon()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_farm_sleep", false):
		area.skip_to_next_change()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_farm_fast_time", false):
		area.time_scale = 1.0 if area.time_scale != 1.0 else FAST_TIME
		get_viewport().set_input_as_handled()


## Notes (warm paper: art-direction.md, warm colours out in the world mean
## something), the crank on its hook, the sluice wheel, Grist's heart.
func _draw_things(view: Rect2) -> void:
	for thing: Dictionary in area.things:
		var at: Vector2 = thing["position"]
		if not thing["shown"] or thing["taken"] or not view.grow(32.0).has_point(at):
			continue
		match thing["kind"]:
			&"note":
				var glint: float = 0.5 + 0.5 * sin(area.sim.tick_count * 0.08 + at.x)
				draw_circle(at + Vector2(0, -6), 7.0, Color(Palette.WARMTH[2], 0.12 + 0.1 * glint))
				draw_rect(Rect2(at + Vector2(-4, -11), Vector2(8, 10)), Palette.PAPER[1])
				draw_line(at + Vector2(-2, -8), at + Vector2(2, -8), Palette.STONE[1], 1.0)
				draw_line(at + Vector2(-2, -5), at + Vector2(2, -5), Palette.STONE[1], 1.0)
				draw_rect(Rect2(at + Vector2(-1, -12), Vector2(2, 2)), Palette.WARMTH[1])  # the pin
			&"crank":
				draw_line(at + Vector2(-5, -12), at + Vector2(5, -12), Palette.STONE[0], 2.0)
				draw_line(at + Vector2(0, -12), at + Vector2(0, -4), Palette.STONE[2], 2.0)
				draw_line(at + Vector2(0, -4), at + Vector2(6, -4), Palette.STONE[2], 2.0)
			&"sluice":
				draw_circle(at + Vector2(0, -8), 7.0, Palette.CHANGED[0])
				draw_arc(at + Vector2(0, -8), 7.0, 0, TAU, 16, Palette.STONE[2], 1.0)
				if area.objective_done:
					draw_line(at + Vector2(0, -8), at + Vector2(6, -14), Palette.STONE[2], 2.0)  # the crank, fitted
			&"heart":
				var beat: float = 1.0 + 0.15 * absf(sin(area.sim.tick_count * 0.1))
				draw_circle(at + Vector2(0, -6), 5.0 * beat, Palette.CHANGED[0])
				draw_circle(at + Vector2(-1, -7), 2.0 * beat, Palette.DANGER[0])
				for i: int in range(4):
					var d: Vector2 = Vector2.from_angle(i * TAU / 4.0 + 0.4)
					draw_line(at + Vector2(0, -6) + d * 4.0, at + Vector2(0, -6) + d * 9.0, Palette.WILD[1], 1.0)


## The button to press, above whatever is in reach (placeholder for the
## device's prompt art; ADR-0013).
func _draw_prompt() -> void:
	var thing: Dictionary = area.thing_in_reach()
	if thing.is_empty() or area.sim.player.state != Fighter.State.FREE:
		return
	var at: Vector2 = (thing["position"] as Vector2) + Vector2(0, -26)
	draw_rect(Rect2(at - Vector2(9, 5), Vector2(18, 10)), Color(Palette.SHADOW[0], 0.8))
	draw_rect(Rect2(at - Vector2(9, 5), Vector2(18, 10)), Palette.PAPER[0], false, 1.0)
	draw_string(ThemeDB.fallback_font, at + Vector2(-7, 3), "F/B", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Palette.PAPER[1])
