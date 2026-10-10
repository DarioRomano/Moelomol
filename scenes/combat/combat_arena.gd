extends Node2D
## Combat test arena (docs/design/combat.md, "Suggested first build step").
## Never at the base (ADR-0005): a debug scene reached with F2 or
## `--start-scene combat_arena`.
##
## Reads input into a CombatInput each physics tick (fixed 60 Hz), steps the
## CombatSim, plays haptics for its events, and draws it with CombatDrawer.
## The camera is static and centred, so wider screens show more around the
## arena (ADR-0008); camera movement is a later decision.
##
## Developer keys: F5 render interpolation on/off (Q20), F6 creatures
## passive/active, F7 changes the weapon not in hand (greatsword, hammer,
## bow).

var sim: CombatSim = CombatSim.make_arena()
var haptics: Haptics = Haptics.new()
var render_interpolation: bool = true
var effects: Array[Dictionary] = []

var _hud: CombatHud


func _ready() -> void:
	for weapon: Weapon in sim.player.weapons:
		_apply_settings(weapon)
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(320, 180)
	add_child(camera)
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var frame: UiFrame = UiFrame.new()
	layer.add_child(frame)
	_hud = CombatHud.new()
	frame.add_child(_hud)


func _physics_process(_delta: float) -> void:
	sim.step(read_input())
	for event: Dictionary in sim.events:
		var effect: StringName = Haptics.effect_for_event(event)
		if effect != &"":
			haptics.play(effect)
	CombatDrawer.update_effects(effects, sim.events)


func _process(_delta: float) -> void:
	queue_redraw()
	_hud.show_state(sim, render_interpolation)


func _draw() -> void:
	var alpha: float = Engine.get_physics_interpolation_fraction() if render_interpolation else 1.0
	CombatDrawer.draw(self, sim, alpha, effects)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_toggle_render_interpolation", false):
		render_interpolation = not render_interpolation
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_toggle_creatures_passive", false):
		for creature: Fighter in sim.creatures:
			creature.ai_enabled = not creature.ai_enabled
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_cycle_offhand_weapon", false):
		_apply_settings(sim.cycle_offhand_weapon())
		get_viewport().set_input_as_handled()


## Player settings that change how a weapon plays (accessibility).
static func _apply_settings(weapon: Weapon) -> void:
	if weapon is Hammer:
		(weapon as Hammer).wide_sweet_spot = GameSettings.shared().hammer_wide_sweet_spot


## This tick's input from the InputMap actions (ADR-0013).
static func read_input() -> CombatInput:
	var input: CombatInput = CombatInput.new()
	input.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	input.light_pressed = Input.is_action_just_pressed(&"attack_light")
	input.heavy_pressed = Input.is_action_just_pressed(&"attack_heavy")
	input.heavy_held = Input.is_action_pressed(&"attack_heavy")
	input.skill_pressed = Input.is_action_just_pressed(&"weapon_skill")
	input.dodge_pressed = Input.is_action_just_pressed(&"dodge")
	input.swap_pressed = Input.is_action_just_pressed(&"weapon_swap")
	input.lock_held = Input.is_action_pressed(&"lock_on")
	input.target_next_pressed = Input.is_action_just_pressed(&"target_next")
	input.target_prev_pressed = Input.is_action_just_pressed(&"target_prev")
	return input
