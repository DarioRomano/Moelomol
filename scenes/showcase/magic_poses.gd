extends PoseSheet
## Magic review poses (PoseSheet): spells, effect stacks, Frozen, the Rot
## pool, Release with its combinations, and Wardstep.

const MAGIC: int = 1


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("Ember bolt on a smouldering creature", _ember, MAGIC),
		_pose("Frost shard: five Chill, Frozen", _frozen, MAGIC),
		_pose("Rot pool: creatures in it gain Rot", _pool, MAGIC),
		_pose("Release, three effects: Shatter + Blight", _release_all, MAGIC),
		_pose("Release, Chill + Rot: Brittle", _brittle, MAGIC),
		_pose("Wardstep: blink, leave a Chill pool", _wardstep, MAGIC),
	]


func _pose(title: String, script: Callable, weapon_index: int = 0) -> Dictionary:
	# Every magic panel carries the greatsword and the lantern.
	var wrapped: Callable = func(sim: CombatSim, effects: Array[Dictionary]) -> void:
		sim.player.weapons[1] = Magic.new()
		script.call(sim, effects)
	return super(title, wrapped, weapon_index)


func _ember(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(150, 80))
	sim.apply_effect(c, StatusEffects.SMOULDER, 2)
	sim.step(CombatInput.press(&"light"))
	_step_until(sim, effects, func() -> bool:
		return not sim.projectiles.is_empty() and sim.projectiles[0].position.x > 105)


func _frozen(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(120, 80))
	sim.apply_effect(c, StatusEffects.CHILL, 3)
	sim.step(CombatInput.press(&"heavy"))
	sim.step(CombatInput.new())  # a tap: Frost shard
	_step_until(sim, effects, func() -> bool: return _effect_age(effects, "frozen") >= 4)


func _pool(sim: CombatSim, effects: Array[Dictionary]) -> void:
	_creature(sim, Vector2(100, 74))
	_creature(sim, Vector2(110, 92))
	sim.step(CombatInput.press(&"heavy"))
	_step_until(sim, effects, func() -> bool: return not sim.zones.is_empty(), CombatInput.hold_heavy())
	_step_until(sim, effects, func() -> bool: return sim.zones[0].age >= 70)


func _release_all(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(84, 80))
	var near: Fighter = _creature(sim, Vector2(108, 66))
	_creature(sim, Vector2(104, 100))
	for kind: StringName in StatusEffects.KINDS:
		sim.apply_effect(c, kind, 4)
	sim.apply_effect(near, StatusEffects.CHILL, 1)
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool: return _effect_age(effects, "blight_bloom") >= 6)


func _brittle(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(84, 80))
	sim.apply_effect(c, StatusEffects.CHILL, 3)
	sim.apply_effect(c, StatusEffects.ROT, 3)
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool: return _effect_age(effects, "brittle") >= 5)


func _wardstep(sim: CombatSim, effects: Array[Dictionary]) -> void:
	sim.player.position = Vector2(110, 80)
	sim.player.previous_position = sim.player.position
	var c: Fighter = sim.add_creature(Vector2(138, 80))
	c.ai_enabled = false
	c.facing = Vector2.LEFT
	sim.start_attack(c, sim._creature_lunge)
	_step_until(sim, effects, func() -> bool: return c.attack_phase() == &"active")
	var blink: CombatInput = CombatInput.press(&"dodge")
	blink.move = Vector2.LEFT
	sim.step(blink)
	CombatDrawer.update_effects(effects, sim.events)
	_step_until(sim, effects, func() -> bool: return _effect_age(effects, "wardstep") >= 3)


## Age of the newest effect of `kind`, or -1.
static func _effect_age(effects: Array[Dictionary], kind: String) -> int:
	var age: int = -1
	for e: Dictionary in effects:
		if e["kind"] == kind:
			age = int(e["age"])
	return age
