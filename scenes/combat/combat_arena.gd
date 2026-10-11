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
## bow, magic), F11 the next creature set (docs/design/enemies.md: the
## training creatures, then each of Millbrook's kinds, then Grist's yard), F12
## night on/off.

## The night colour over the arena (F12): the clock's midnight tint.
static var NIGHT_TINT: Color = GameClock.sky_tint_at(0.0)

var sim: CombatSim = CombatSim.make_arena()
var creature_set: int = 0  # index into CombatSim.ARENA_SETS
var haptics: Haptics = Haptics.new()
var render_interpolation: bool = true
var effects: Array[Dictionary] = []

var _hud: CombatHud
var _night: CanvasModulate


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
	_night = CanvasModulate.new()
	add_child(_night)
	_night.color = Color.WHITE


func _physics_process(_delta: float) -> void:
	sim.step(read_input())
	for event: Dictionary in sim.events:
		var effect: StringName = Haptics.effect_for_event(event)
		if effect != &"":
			haptics.play(effect)
	haptics.sustain(sim.player_rumble())
	CombatDrawer.update_effects(effects, sim.events)


func _process(_delta: float) -> void:
	queue_redraw()
	_hud.show_state(sim, render_interpolation, "creatures: %s (F11)%s" % [
		String(CombatSim.ARENA_SETS[creature_set]).replace("_", " "), "   night (F12)" if sim.night else ""])


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
	elif event.is_action_pressed(&"dev_next_creature_set", false):
		next_creature_set()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_toggle_night", false):
		sim.night = not sim.night
		_night.color = NIGHT_TINT if sim.night else Color.WHITE
		get_viewport().set_input_as_handled()


## Swaps in the next creature set, keeping the player's weapons.
func next_creature_set() -> void:
	creature_set = (creature_set + 1) % CombatSim.ARENA_SETS.size()
	var weapons: Array[Weapon] = sim.player.weapons
	var index: int = sim.player.weapon_index
	sim = CombatSim.make_arena_set(CombatSim.ARENA_SETS[creature_set])
	sim.player.weapons = weapons
	sim.player.weapon_index = index
	effects.clear()
	_night.color = NIGHT_TINT if sim.night else Color.WHITE


## Player settings that change how a weapon plays (accessibility).
static func _apply_settings(weapon: Weapon) -> void:
	if weapon is Hammer:
		(weapon as Hammer).wide_sweet_spot = GameSettings.shared().hammer_wide_sweet_spot


## This tick's input from the InputMap actions (ADR-0013).
static func read_input() -> CombatInput:
	return CombatInput.read()
