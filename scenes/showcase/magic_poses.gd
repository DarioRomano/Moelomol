extends PoseSheet
## Magic review poses (PoseSheet): spells, effect stacks, Frozen, the
## Siphon's tether and beam, the Rot pool (skill, interim) and Wardstep.

const MAGIC: int = 1


func _make_panels() -> Array[Dictionary]:
	return [
		_pose("Ember bolt on a smouldering creature", _ember, MAGIC),
		_pose("Frost shard: five Chill, Frozen", _frozen, MAGIC),
		_pose("Siphon: the tether drains stacks", _siphon_draining, MAGIC),
		_pose("Siphon beam, three effects: Shatter + Blight", _beam_all, MAGIC),
		_pose("Skill (interim): Rot pool", _pool, MAGIC),
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
	sim.step(CombatInput.press(&"skill"))
	_step_until(sim, effects, func() -> bool: return sim.zones[0].age >= 70)


## Holding heavy on a creature carrying all three effects, part-way through:
## the tether, its motes and the drained beads round the lantern.
func _siphon_draining(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(110, 80))
	for kind: StringName in StatusEffects.KINDS:
		sim.apply_effect(c, kind, 4)
	sim.step(CombatInput.press(&"heavy"))
	var magic: Magic = sim.player.weapon() as Magic
	_step_until(sim, effects, func() -> bool: return magic.drained_total() >= 6, CombatInput.hold_heavy())


## The beam on release: the first creature takes the burst, the one behind
## takes half, and the combinations bloom.
func _beam_all(sim: CombatSim, effects: Array[Dictionary]) -> void:
	var c: Fighter = _creature(sim, Vector2(96, 80))
	_creature(sim, Vector2(136, 82))
	_creature(sim, Vector2(110, 104))
	for kind: StringName in StatusEffects.KINDS:
		sim.apply_effect(c, kind, 4)
	sim.step(CombatInput.press(&"heavy"))
	var magic: Magic = sim.player.weapon() as Magic
	_step_until(sim, effects, func() -> bool: return magic.drained_total() >= 9, CombatInput.hold_heavy())
	sim.step(CombatInput.new())
	CombatDrawer.update_effects(effects, sim.events)
	_step_until(sim, effects, func() -> bool: return _effect_age(effects, "blight_bloom") >= 4)


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
