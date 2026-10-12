extends Node2D
## The farm (docs/design/base.md): the homestead and the overgrown estate
## around it, the game's base. No combat is loaded here (ADR-0016): no
## creatures, no combat simulation.
##
## Built from the game in play (GameState). Each physics tick (fixed 60 Hz)
## it reads input into a FarmInput, steps the FarmSim, plays haptics for its
## events and moves the camera (ADR-0015). Walking out through the south gate
## goes down the lane to Millbrook. The game saves when the player sleeps
## and when they leave through the gate (ADR-0017).
##
## Developer keys: F8 sleeps now (skips to the next morning), F9 runs time
## 30 times faster, F10 switches to the next watering tier (the upgrades
## that unlock them are not built).

## Emitted when the player leaves for another place; the fade and the scene
## change follow unless `travels` is false (tests).
signal leaving(place: StringName)

const FAST_TIME: float = 30.0

var state: GameState = GameState.ensure()
var sim: FarmSim = state.make_farm()
var camera: FollowCamera = FollowCamera.new()
var haptics: Haptics = Haptics.new()
## False in tests: leaving stores the farm and emits `leaving`, but the scene
## stays.
var travels: bool = true

var _camera_node: Camera2D
var _hud: FarmHud
var _left: bool = false


func _ready() -> void:
	_camera_node = Camera2D.new()
	add_child(_camera_node)
	camera.snap(sim.player_position, view_size(), sim.bounds(), view_scale())
	_camera_node.position = camera.position
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var frame: UiFrame = UiFrame.new()
	layer.add_child(frame)
	_hud = FarmHud.new()
	frame.add_child(_hud)


## The visible area in layout px and the screen's scale (ADR-0008).
func view_size() -> Vector2:
	return Vector2(DisplayMath.expected_view_size(DisplayServer.window_get_size()))


func view_scale() -> float:
	return float(DisplayMath.expected_scale(DisplayServer.window_get_size()))


func _physics_process(delta: float) -> void:
	if _left:
		return
	sim.step(FarmInput.read())
	for event: Dictionary in sim.events:
		var effect: StringName = Haptics.effect_for_farm_event(event)
		if effect != &"":
			haptics.play(effect)
		match event["type"]:
			"slept":
				_slept()
			"exit":
				leave(event["to"])
				return
	camera.update(sim.player_position, view_size(), sim.bounds(), view_scale(), delta)
	_camera_node.position = camera.position


## Out through the south gate: the farm remembers itself and the player goes
## down the lane, arriving at the top of Millbrook's.
func leave(to: StringName) -> void:
	if _left:
		return
	_left = true
	state.store_farm(sim)
	state.travel(to, GameState.AT_GATE)
	state.save()
	leaving.emit(to)
	if travels:
		Fade.to_scene(get_tree(), state.scene_path(), Fade.colour_at(state.clock))


## After sleeping: the camera to the door, and the game saved there, the
## next morning (ADR-0017).
func _slept() -> void:
	camera.snap(sim.player_position, view_size(), sim.bounds(), view_scale())
	state.store_farm(sim)
	state.travel(GameState.FARM, GameState.AT_BED)
	state.save()


func _process(_delta: float) -> void:
	queue_redraw()
	_hud.show_state(sim)


func _draw() -> void:
	var view: Rect2 = Rect2(camera.position - view_size() / 2.0, view_size())
	FarmDrawer.draw(self, sim, Engine.get_physics_interpolation_fraction(), FarmDrawer.world_tint(sim), view)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_farm_sleep", false):
		sim.sleep()
		_slept()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_farm_fast_time", false):
		sim.time_scale = 1.0 if sim.time_scale != 1.0 else FAST_TIME
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_farm_water_tier", false):
		sim.water_tier = (sim.water_tier + 1) % FarmSim.WATER_TIERS.size()
		get_viewport().set_input_as_handled()
