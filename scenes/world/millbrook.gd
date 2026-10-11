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
		+ "Lock Shift / LT   Switch Q E / right stick   F6 creatures passive   F7 other weapon   F8 dusk / dawn   F9 fast time")


## The visible area in layout px and the screen's scale (ADR-0008).
func view_size() -> Vector2:
	return Vector2(DisplayMath.expected_view_size(DisplayServer.window_get_size()))


func view_scale() -> float:
	return float(DisplayMath.expected_scale(DisplayServer.window_get_size()))


func _physics_process(delta: float) -> void:
	area.step(CombatInput.read())
	for event: Dictionary in area.sim.events:
		var effect: StringName = Haptics.effect_for_event(event)
		if effect != &"":
			haptics.play(effect)
	haptics.sustain(area.sim.player_rumble())
	CombatDrawer.update_effects(effects, area.sim.events)
	for event: Dictionary in area.events:
		if event["type"] == "woke":
			camera.snap(area.sim.player.position, view_size(), area.map.rect(), view_scale())
	camera.update(area.sim.player.position, view_size(), area.map.rect(), view_scale(), delta)
	_camera_node.position = camera.position


func _process(_delta: float) -> void:
	queue_redraw()
	_tint.color = area.clock.sky_tint()
	_hud.show_state(area.sim, true, "Millbrook   day %d   %s%s" % [area.clock.day(), area.clock.time_text(),
		"   (time x30)" if area.time_scale != 1.0 else ""])


func _draw() -> void:
	var view: Rect2 = Rect2(camera.position - view_size() / 2.0, view_size())
	draw_rect(view.grow(64.0), Palette.WILD[0])  # beyond the map's edge: more woods
	AreaDrawer.draw(self, area.map, view, area.sim.tick_count)
	CombatDrawer.draw(self, area.sim, Engine.get_physics_interpolation_fraction(), effects, false)
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


func _unhandled_input(event: InputEvent) -> void:
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
