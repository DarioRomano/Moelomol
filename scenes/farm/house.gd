extends Node2D
## The farmhouse inside (base.md; its own place, ADR-0016): the bed, the
## seed tin, the stove, the table, the cat's basket and window seat. Built
## from the game in play (GameState). The door goes back out to the farm.
## Sleeping saves the game (ADR-0017).
##
## Developer keys: F8 sleeps now, F9 runs time 30 times faster.

## Emitted when the player leaves for another place; the fade and the scene
## change follow unless `travels` is false (tests).
signal leaving(place: StringName)

const FAST_TIME: float = 30.0
const TOAST_TICKS: int = 240

var state: GameState = GameState.ensure()
var sim: HouseSim = state.make_house()
var camera: FollowCamera = FollowCamera.new()
var haptics: Haptics = Haptics.new()
var travels: bool = true
## Esc / Start: Resume, Back to title, Quit.
var pause_menu: PauseMenu

var _camera_node: Camera2D
var _hud: FarmHud
var _left: bool = false
var _toast: String = ""
var _toast_ticks: int = 0


func _ready() -> void:
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
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
	_hud.set_help("Move WASD / stick   Interact F / B (the bed: sleep; the seed tin)   Out: the door   Pause Esc / Start\n"
		+ "F8 sleep now   F9 time x30")


func view_size() -> Vector2:
	return Vector2(DisplayMath.expected_view_size(DisplayServer.window_get_size()))


func view_scale() -> float:
	return float(DisplayMath.expected_scale(DisplayServer.window_get_size()))


func _physics_process(delta: float) -> void:
	if _left:
		return
	if _toast_ticks > 0:
		_toast_ticks -= 1
	sim.step(FarmInput.read())
	for event: Dictionary in sim.events:
		_handle(event)
		if _left:
			return
	camera.update(sim.player_position, view_size(), sim.bounds(), view_scale(), delta)
	_camera_node.position = camera.position


func _handle(event: Dictionary) -> void:
	match event["type"]:
		"slept":
			_slept()
		"seed_tin":
			var parts: PackedStringArray = PackedStringArray()
			var items: Dictionary = event["items"]
			for item: StringName in items:
				parts.append("%d %s" % [items[item], FarmSim.item_name(item).to_lower()])
			show_toast("The seed tin: " + ", ".join(parts) + ".")
			haptics.play(&"farm_harvest")
		"seed_tin_empty":
			show_toast("The seed tin is empty.")
			haptics.play(&"farm_nothing")
		"exit":
			leave(event["to"])


func show_toast(text: String) -> void:
	_toast = text
	_toast_ticks = TOAST_TICKS


## After sleeping: saved beside the bed, the next morning (ADR-0017).
func _slept() -> void:
	state.store_house(sim)
	state.travel(GameState.HOUSE, GameState.AT_BED)
	state.save()


## Out of the door, onto the farm in front of it.
func leave(to: StringName) -> void:
	if _left:
		return
	_left = true
	pause_menu.enabled = false
	state.store_house(sim)
	state.travel(to, GameState.AT_DOOR)
	leaving.emit(to)
	if travels:
		Fade.to_scene(get_tree(), state.scene_path(), Fade.colour_at(state.clock))


func _process(_delta: float) -> void:
	queue_redraw()
	_hud.show_house(sim, _toast if _toast_ticks > 0 else "")


func _draw() -> void:
	var view: Rect2 = Rect2(camera.position - view_size() / 2.0, view_size())
	HouseDrawer.draw(self, sim, Engine.get_physics_interpolation_fraction(), view)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_farm_sleep", false):
		sim.sleep()
		_slept()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_farm_fast_time", false):
		sim.time_scale = 1.0 if sim.time_scale != 1.0 else FAST_TIME
		get_viewport().set_input_as_handled()
