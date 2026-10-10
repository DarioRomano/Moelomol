extends Node2D
## Combat review poses (debug scene). Six panels, each a small CombatSim
## driven by a fixed script of inputs to a telling moment, then frozen, so the
## visual review renders show attacks, impacts and telegraphs rather than an
## idle arena. Deterministic: the same picture every run.

const PANEL: Vector2 = Vector2(200, 150)
const GAP: float = 10.0

var _panels: Array[Dictionary] = []


func _ready() -> void:
	_panels = [
		_pose("Sweep 3 (light chain)", _sweep_three),
		_pose("Overhead cleave: hyper-armour windup", _cleave_windup),
		_pose("Shove into a pillar: impact", _shove_impact),
		_pose("Spin sweep hits all around", _spin),
		_pose("Creature telegraph, locked on", _telegraph),
		_pose("Follow-through on a staggered creature", _follow_through),
	]
	for i: int in range(_panels.size()):
		var label: Label = Label.new()
		label.text = "%d %s" % [i + 1, _panels[i]["title"]]
		label.position = _origin(i) + Vector2(2, PANEL.y + 1)
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Palette.PAPER[1])
		add_child(label)
	queue_redraw()


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
func _pose(title: String, script: Callable) -> Dictionary:
	var sim: CombatSim = CombatSim.new(Rect2(16, 16, PANEL.x - 32, PANEL.y - 32), Vector2(60, 80))
	sim.player.facing = Vector2.RIGHT
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
		for event: Dictionary in sim.events:
			if event["type"] in ["impact", "hit"]:
				effects.append({"kind": event["type"], "position": event["position"], "age": 0})
		for effect: Dictionary in effects:
			effect["age"] = int(effect["age"]) + 1


static func _creature(sim: CombatSim, at: Vector2) -> Fighter:
	var c: Fighter = sim.add_creature(at)
	c.ai_enabled = false
	return c


static func _press_then_recovery(sim: CombatSim, effects: Array[Dictionary], action: StringName) -> void:
	sim.step(CombatInput.press(action))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"recovery")


func _sweep_three(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(84, 76))
	_press_then_recovery(sim, effects, &"light")
	_press_then_recovery(sim, effects, &"light")
	sim.step(CombatInput.press(&"light"))
	_step_until(sim, effects, func() -> bool:
		return sim.player.move != null and sim.player.move.id == &"light_3" \
			and sim.player.attack_phase() == &"active" and sim.hitstop > 0)


func _cleave_windup(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(92, 80))
	sim.step(CombatInput.press(&"heavy"))
	_step_until(sim, effects, func() -> bool: return sim.player.state_tick >= 20)


func _shove_impact(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.obstacles.append(Rect2(128, 56, 20, 50))
	_creature(sim, Vector2(108, 80))
	_press_then_recovery(sim, effects, &"light")
	sim.step(CombatInput.press(&"heavy"))
	var impacted: Array[bool] = [false]
	_step_until(sim, effects, func() -> bool:
		for e: Dictionary in effects:
			if e["kind"] == "impact" and int(e["age"]) >= 3:
				impacted[0] = true
		return impacted[0])


func _spin(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.player.position = Vector2(100, 76)
	sim.player.previous_position = sim.player.position
	_creature(sim, Vector2(126, 74))
	_creature(sim, Vector2(76, 82))
	_creature(sim, Vector2(102, 100))
	_press_then_recovery(sim, effects, &"light")
	_press_then_recovery(sim, effects, &"light")
	sim.step(CombatInput.press(&"heavy"))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"active" and sim.hitstop > 0)


func _telegraph(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = sim.add_creature(Vector2(120, 80))
	var hold: CombatInput = CombatInput.new()
	hold.lock_held = true
	_step_until(sim, effects, func() -> bool: return c.attack_phase() == &"windup" and c.state_tick == 20, hold)


func _follow_through(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(82, 80))
	sim._stagger(c)
	c.state_length = 1000
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool: return sim.player.attack_phase() == &"active" and sim.hitstop > 0)
