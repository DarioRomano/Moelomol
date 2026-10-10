class_name PoseSheet
extends Node2D
## A sheet of six combat review poses (debug scenes). Each panel is a small
## CombatSim driven by a fixed script of inputs to a telling moment, then
## frozen, so the visual review renders show attacks, impacts and telegraphs
## rather than an idle arena. Deterministic: the same picture every run.
## Subclasses list their panels in _make_panels().

const PANEL: Vector2 = Vector2(200, 150)
const GAP: float = 10.0

var _panels: Array[Dictionary] = []


func _ready() -> void:
	_panels = _make_panels()
	for i: int in range(_panels.size()):
		var label: Label = Label.new()
		label.text = "%d %s" % [i + 1, _panels[i]["title"]]
		label.position = _origin(i) + Vector2(2, PANEL.y + 1)
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Palette.PAPER[1])
		add_child(label)
	queue_redraw()


## The six panels: each from _pose().
func _make_panels() -> Array[Dictionary]:
	return []


func _origin(index: int) -> Vector2:
	return Vector2(GAP + (index % 3) * (PANEL.x + GAP), GAP + (index / 3) * (PANEL.y + GAP + 10))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Palette.SHADOW[0])
	for i: int in range(_panels.size()):
		draw_set_transform(_origin(i))
		var sim: CombatSim = _panels[i]["sim"]
		var effects: Array[Dictionary] = _panels[i]["effects"]
		CombatDrawer.draw(self, sim, 1.0, effects)
	draw_set_transform(Vector2.ZERO)


## Runs a script on a fresh panel-sized sim and keeps the frozen result.
## `weapon_index` picks the player's weapon (0 greatsword, 1 hammer).
func _pose(title: String, script: Callable, weapon_index: int = 0) -> Dictionary:
	var sim: CombatSim = CombatSim.new(Rect2(16, 16, PANEL.x - 32, PANEL.y - 32), Vector2(60, 80))
	sim.player.facing = Vector2.RIGHT
	sim.player.weapon_index = weapon_index
	var effects: Array[Dictionary] = []
	script.call(sim, effects)
	return {"title": title, "sim": sim, "effects": effects}


## Steps the sim, collecting hit and impact effects, until `done` is true.
static func _step_until(sim: CombatSim, effects: Array[Dictionary], done: Callable,
		input: CombatInput = CombatInput.new(), max_ticks: int = 300) -> void:
	for i: int in range(max_ticks):
		if done.call():
			return
		sim.step(input)
		CombatDrawer.update_effects(effects, sim.events)


static func _creature(sim: CombatSim, at: Vector2) -> Fighter:
	var c: Fighter = sim.add_creature(at)
	c.ai_enabled = false
	return c


static func _press_then_recovery(sim: CombatSim, effects: Array[Dictionary], action: StringName) -> void:
	sim.step(CombatInput.press(action))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"recovery")
