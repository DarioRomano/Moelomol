extends Node2D
## Farm test scene (docs/design/farming.md): the farming slice on a test
## field, not the base's design (level layout is the lead's decision).
## Reached with F2 or `--start-scene farm_test`.
##
## Reads input into a FarmInput each physics tick (fixed 60 Hz), steps the
## FarmSim, plays haptics for its events, and draws it with FarmDrawer under
## the time of day's tint. The camera is static and centred, like the arena.
##
## Developer keys: F8 sleeps now (skips to the next morning), F9 runs time
## 30 times faster, F10 switches to the next watering tier (the upgrades
## that unlock them are not built).

const FAST_TIME: float = 30.0

var sim: FarmSim = FarmSim.make_test_farm()
var haptics: Haptics = Haptics.new()

var _hud: FarmHud


func _ready() -> void:
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(320, 180)
	add_child(camera)
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var frame: UiFrame = UiFrame.new()
	layer.add_child(frame)
	_hud = FarmHud.new()
	frame.add_child(_hud)


func _physics_process(_delta: float) -> void:
	sim.step(read_input())
	for event: Dictionary in sim.events:
		var effect: StringName = Haptics.effect_for_farm_event(event)
		if effect != &"":
			haptics.play(effect)


func _process(_delta: float) -> void:
	queue_redraw()
	_hud.show_state(sim)


func _draw() -> void:
	# The area outside the field is drawn too, so wide screens see the night.
	var tint: Color = FarmDrawer.world_tint(sim)
	draw_rect(Rect2(-2000, -2000, 4640, 4360), Palette.SHADOW[0] * tint)
	FarmDrawer.draw(self, sim, Engine.get_physics_interpolation_fraction(), tint)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_farm_sleep", false):
		sim.sleep()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_farm_fast_time", false):
		sim.time_scale = 1.0 if sim.time_scale != 1.0 else FAST_TIME
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_farm_water_tier", false):
		sim.water_tier = (sim.water_tier + 1) % FarmSim.WATER_TIERS.size()
		get_viewport().set_input_as_handled()


## This tick's input from the InputMap actions (ADR-0013).
static func read_input() -> FarmInput:
	var input: FarmInput = FarmInput.new()
	input.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	input.use_pressed = Input.is_action_just_pressed(&"farm_use_tool")
	input.interact_pressed = Input.is_action_just_pressed(&"farm_interact")
	input.tool_next_pressed = Input.is_action_just_pressed(&"farm_tool_next")
	input.tool_prev_pressed = Input.is_action_just_pressed(&"farm_tool_prev")
	return input
