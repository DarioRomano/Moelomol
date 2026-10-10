extends TestCase
## The hammer, armour and the weapon swap (docs/design/combat.md, "Hammer:
## timing is everything" and Q19), in the pure simulation.

const T: GDScript = preload("res://src/combat/combat_tuning.gd")


## Open 400x300 field, player at (100, 150) facing right with the hammer in
## hand, passive creatures where asked.
func _field(creature_positions: Array[Vector2] = []) -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	sim.player.facing = Vector2.RIGHT
	sim.player.weapon_index = 1
	for at: Vector2 in creature_positions:
		sim.add_creature(at).ai_enabled = false
	return sim


func _hammer(sim: CombatSim) -> Hammer:
	return sim.player.weapon() as Hammer


func _run(sim: CombatSim, ticks: int, input: CombatInput = CombatInput.new()) -> void:
	for i: int in range(ticks):
		sim.step(input)


func _until_free(sim: CombatSim, max_ticks: int = 300) -> void:
	for i: int in range(max_ticks):
		if sim.player.state == Fighter.State.FREE and sim.hitstop == 0:
			return
		sim.step(CombatInput.new())


## Presses heavy, holds it for `held` ticks, releases. Returns the events of
## every tick from the press to the release.
func _charge_and_release(sim: CombatSim, held: int) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	sim.step(CombatInput.press(&"heavy"))
	seen.append_array(sim.events)
	for i: int in range(held):
		sim.step(CombatInput.hold_heavy())
		seen.append_array(sim.events)
	sim.step(CombatInput.new())
	seen.append_array(sim.events)
	return seen


## Charge, release and play out the strike; returns every event on the way.
func _strike(sim: CombatSim, held: int) -> Array[Dictionary]:
	var seen: Array[Dictionary] = _charge_and_release(sim, held)
	for i: int in range(300):
		if sim.player.state == Fighter.State.FREE and sim.hitstop == 0:
			break
		sim.step(CombatInput.new())
		seen.append_array(sim.events)
	return seen


func _count(events: Array[Dictionary], type: String) -> int:
	var n: int = 0
	for e: Dictionary in events:
		if e["type"] == type:
			n += 1
	return n


func _perfect_ticks() -> int:
	return T.ticks(Hammer.SWEET_SPOT_START_MS)


# --- Weapon swap (Q19) -------------------------------------------------------------

func test_player_carries_greatsword_and_hammer() -> void:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	assert_eq(sim.player.weapons.size(), 2, "two weapon slots")
	assert_eq(sim.player.weapon().id, &"greatsword", "greatsword in hand at first")
	assert_eq(sim.player.weapons[1].id, &"hammer", "hammer in the second slot")


func test_swap_changes_weapon_then_waits_for_the_cooldown() -> void:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	sim.step(CombatInput.press(&"swap"))
	assert_eq(sim.player.weapon().id, &"hammer", "swapped to the hammer")
	_run(sim, 10)
	sim.step(CombatInput.press(&"swap"))
	assert_eq(sim.player.weapon().id, &"hammer", "a second swap within the cooldown is refused")
	assert_eq(sim.events[0]["type"], "swap_blocked", "the refusal is reported")
	_run(sim, T.ticks(T.SWAP_COOLDOWN_MS))
	sim.step(CombatInput.press(&"swap"))
	assert_eq(sim.player.weapon().id, &"greatsword", "swapped back after 1.5 s")


func test_swap_ends_the_greatsword_chain() -> void:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	sim.step(CombatInput.press(&"light"))
	for i: int in range(60):
		if sim.player.attack_phase() == &"recovery":
			break
		sim.step(CombatInput.new())
	assert_eq(sim.player.chain, 1, "one light swing done")
	sim.step(CombatInput.press(&"swap"))
	assert_eq(sim.player.weapon().id, &"hammer", "a swap cancels the recovery")
	assert_eq(sim.player.chain, 0, "the chain is gone")


# --- Hammer: jab and charge --------------------------------------------------------

func test_light_is_a_quick_jab() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.step(CombatInput.press(&"light"))
	assert_eq(sim.player.move, Hammer.JAB, "jab")
	_until_free(sim)
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH - Hammer.JAB.damage, "the jab lands")


func test_heavy_starts_a_charge_that_costs_stamina() -> void:
	var sim: CombatSim = _field()
	sim.step(CombatInput.press(&"heavy"))
	assert_eq(sim.player.state, Fighter.State.CHARGE, "charging")
	assert_eq(sim.player.stamina.current, T.STAMINA_MAX - Hammer.CHARGE_STAMINA, "charge stamina paid")
	_run(sim, _perfect_ticks(), CombatInput.hold_heavy())
	assert_eq(sim.player.stamina.current, T.STAMINA_MAX - Hammer.CHARGE_STAMINA,
		"no refill while holding (and no drain before the sweet spot ends)")


func test_charging_walks_slowly() -> void:
	var sim: CombatSim = _field()
	sim.step(CombatInput.press(&"heavy"))
	var start: Vector2 = sim.player.position
	_run(sim, 30, CombatInput.hold_heavy(Vector2.DOWN))
	var moved: float = sim.player.position.distance_to(start)
	assert_true(absf(moved - T.CHARGE_MOVE_SPEED / 2.0) < 0.5, "half a second at charge speed (moved %.1f px)" % moved)
	assert_eq(sim.player.state, Fighter.State.CHARGE, "still charging while moving")
	assert_eq(sim.player.facing, Vector2.DOWN, "turns with the movement")


func test_each_charge_level_is_announced_as_it_is_reached() -> void:
	var sim: CombatSim = _field()
	sim.step(CombatInput.press(&"heavy"))
	var levels: Array[int] = []
	var at: Array[int] = []
	var overcharged_at: int = -1
	for i: int in range(80):
		sim.step(CombatInput.hold_heavy())
		for e: Dictionary in sim.events:
			if e["type"] == "charge_level":
				levels.append(int(e["level"]))
				at.append(i)
			elif e["type"] == "overcharge":
				overcharged_at = i
	assert_eq(levels, [1, 2, 3] as Array[int], "three levels, in order")
	assert_eq(at, [T.ticks(300), T.ticks(600), T.ticks(900)] as Array[int], "after 300, 600 and 900 ms")
	assert_eq(overcharged_at, _hammer(sim).sweet_spot_ticks().y, "overcharge when the sweet spot ends")


# --- Hammer: release grades --------------------------------------------------------

func test_release_grades_follow_the_three_levels() -> void:
	var hammer: Hammer = Hammer.new()
	var levels: Array[int] = hammer.level_ticks()
	var window: Vector2i = hammer.sweet_spot_ticks()
	assert_eq(window, Vector2i(54, 63), "level 3 at 900 ms, 150 ms wide at 60 Hz")
	assert_eq(levels[2], window.x, "level 3 is the sweet spot")
	assert_eq(hammer.grade_for(levels[0] - 1), Hammer.STRIKE_TAP, "before level 1: a tap")
	assert_eq(hammer.grade_for(levels[0]), Hammer.STRIKE_LEVEL_1, "level 1")
	assert_eq(hammer.grade_for(levels[1] - 1), Hammer.STRIKE_LEVEL_1, "still level 1")
	assert_eq(hammer.grade_for(levels[1]), Hammer.STRIKE_LEVEL_2, "level 2")
	assert_eq(hammer.grade_for(window.x - 1), Hammer.STRIKE_LEVEL_2, "one tick before level 3")
	assert_eq(hammer.grade_for(window.x), Hammer.STRIKE_PERFECT, "first tick of level 3: perfect")
	assert_eq(hammer.grade_for(window.y - 1), Hammer.STRIKE_PERFECT, "last tick of the sweet spot")
	assert_eq(hammer.grade_for(window.y), Hammer.STRIKE_LATE, "one tick later: overcharged")


func test_lower_levels_do_less_damage() -> void:
	var hammer: Hammer = Hammer.new()
	var levels: Array[int] = hammer.level_ticks()
	var tap: float = hammer.strike_for(0).damage
	var one: float = hammer.strike_for(levels[0]).damage
	var two: float = hammer.strike_for(levels[1]).damage
	var perfect: float = hammer.strike_for(levels[2]).damage
	assert_true(tap < one and one < two and two < perfect, "tap < 1 < 2 < perfect (%.0f %.0f %.0f %.0f)" % [tap, one, two, perfect])
	assert_eq(tap, Hammer.STRIKE_DAMAGE * Hammer.TAP_SHARE, "a tap")
	assert_eq(one, Hammer.STRIKE_DAMAGE * Hammer.LEVEL_1_SHARE, "level 1")
	assert_eq(two, Hammer.STRIKE_DAMAGE * Hammer.LEVEL_2_SHARE, "level 2")
	assert_eq(hammer.strike_for(levels[1] - 1).damage, one, "damage steps by level, not by tick")
	assert_true(hammer.strike_for(hammer.sweet_spot_ticks().y).damage < perfect, "overcharged is weaker")
	for held: int in [0, levels[0], levels[1], hammer.sweet_spot_ticks().y]:
		assert_eq(hammer.strike_for(held).shockwave_radius, 0.0, "no shockwave below a perfect level 3")


func test_perfect_level_three_sends_a_cone_shockwave_forward() -> void:
	# Ahead in the cone (beyond the strike's reach), behind, to the side, and
	# ahead but past the cone's reach.
	var reach: float = Hammer.SHOCKWAVE_REACH
	var sim: CombatSim = _field([Vector2(125, 150), Vector2(100 + reach - 2, 150), Vector2(75, 150),
		Vector2(100, 190), Vector2(100 + reach + 14, 150)])
	var target: Fighter = sim.creatures[0]
	var ahead: Fighter = sim.creatures[1]
	var behind: Fighter = sim.creatures[2]
	var side: Fighter = sim.creatures[3]
	var beyond: Fighter = sim.creatures[4]
	_charge_and_release(sim, _perfect_ticks() + 1)
	assert_eq(sim.player.move.id, Hammer.STRIKE_PERFECT, "perfect strike")
	var seen: Array[Dictionary] = []
	for i: int in range(20):
		sim.step(CombatInput.new())
		seen.append_array(sim.events)
		if _count(seen, "shockwave") > 0:
			break
	assert_eq(_count(seen, "shockwave"), 1, "one shockwave when the hammer lands")
	assert_eq(target.health, T.CREATURE_HEALTH - Hammer.STRIKE_DAMAGE, "full damage on the target")
	assert_true(target.is_staggered(), "target staggered")
	assert_true(ahead.is_staggered(), "a creature far ahead in the cone is staggered")
	assert_eq(ahead.health, T.CREATURE_HEALTH, "the shockwave itself does no damage")
	assert_false(behind.is_staggered(), "not behind the player")
	assert_false(side.is_staggered(), "not to the side")
	assert_false(beyond.is_staggered(), "not past the cone's reach")
	assert_eq(sim.hitstop, T.ticks(T.HITSTOP_BIG_MS), "the biggest hit-stop")


func test_level_two_strike_has_no_shockwave() -> void:
	var sim: CombatSim = _field([Vector2(125, 150), Vector2(150, 150)])
	var seen: Array[Dictionary] = _strike(sim, _hammer(sim).level_ticks()[1] + 2)
	assert_eq(_count(seen, "shockwave"), 0, "no shockwave")
	assert_false(sim.creatures[1].is_staggered(), "nothing beyond the strike is touched")
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH - Hammer.STRIKE_DAMAGE * Hammer.LEVEL_2_SHARE, "level 2 damage")


func test_late_release_is_overstrain() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var window: Vector2i = _hammer(sim).sweet_spot_ticks()
	_charge_and_release(sim, window.y)
	assert_eq(sim.player.move.id, Hammer.STRIKE_LATE, "Overstrain")
	assert_eq(sim.player.stamina.current, T.STAMINA_MAX - Hammer.CHARGE_STAMINA - Hammer.OVERSTRAIN_STAMINA,
		"extra stamina lost")
	_until_free(sim)
	assert_eq(sim.creatures[0].health, T.CREATURE_HEALTH - Hammer.STRIKE_DAMAGE * Hammer.OVERSTRAIN_SHARE,
		"a weak strike")
	assert_false(sim.creatures[0].is_staggered(), "no shockwave")


func test_holding_past_the_sweet_spot_drains_stamina_until_the_hammer_falls() -> void:
	var sim: CombatSim = _field()
	var window: Vector2i = _hammer(sim).sweet_spot_ticks()
	sim.step(CombatInput.press(&"heavy"))
	_run(sim, window.y + 60, CombatInput.hold_heavy())
	var expected: float = T.STAMINA_MAX - Hammer.CHARGE_STAMINA - 60 * T.per_tick(Hammer.OVERSTRAIN_DRAIN_PER_S)
	assert_true(absf(sim.player.stamina.current - expected) < 0.01,
		"drained for a second past the sweet spot (%.2f, expected %.2f)" % [sim.player.stamina.current, expected])
	sim.player.stamina.current = 0.5
	_run(sim, 3, CombatInput.hold_heavy())
	assert_eq(sim.player.state, Fighter.State.ATTACK, "out of stamina: the strike comes by itself")
	assert_eq(sim.player.move.id, Hammer.STRIKE_LATE, "and it is Overstrain")


# --- Rhythm ------------------------------------------------------------------------

func test_consecutive_perfect_strikes_build_rhythm_up_to_three() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var hammer: Hammer = _hammer(sim)
	var damages: Array[float] = []
	for i: int in range(4):
		sim.player.stamina.current = T.STAMINA_MAX
		var held: int = hammer.sweet_spot_ticks().x
		_charge_and_release(sim, held)
		damages.append(sim.player.move.damage)
		_until_free(sim)
		sim.creatures[0].health = T.CREATURE_HEALTH
	assert_eq(hammer.rhythm, Hammer.MAX_RHYTHM, "Rhythm stops at 3")
	assert_true(damages[0] < damages[1] and damages[1] < damages[2] and damages[2] < damages[3],
		"each perfect strike hits harder (%s)" % [damages])
	assert_eq(damages[3], Hammer.STRIKE_DAMAGE * (1.0 + Hammer.RHYTHM_DAMAGE_BONUS * 3), "+75% at Rhythm 3")


func test_rhythm_narrows_the_sweet_spot() -> void:
	var hammer: Hammer = Hammer.new()
	var widths: Array[int] = []
	for stacks: int in range(4):
		hammer.rhythm = stacks
		var window: Vector2i = hammer.sweet_spot_ticks()
		widths.append(window.y - window.x)
	assert_eq(widths, [9, 8, 6, 5] as Array[int], "150, 125, 100, 75 ms in ticks")


func test_a_non_perfect_strike_resets_rhythm() -> void:
	var sim: CombatSim = _field()
	_hammer(sim).rhythm = 2
	_charge_and_release(sim, 10)
	assert_eq(_hammer(sim).rhythm, 0, "early strike resets Rhythm")


func test_jabs_keep_rhythm() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	_hammer(sim).rhythm = 2
	sim.step(CombatInput.press(&"light"))
	_until_free(sim)
	assert_eq(_hammer(sim).rhythm, 2, "a jab neither builds nor breaks Rhythm")


func test_getting_hit_resets_rhythm() -> void:
	var sim: CombatSim = _field([Vector2(120, 150)])
	var creature: Fighter = sim.creatures[0]
	creature.facing = Vector2.LEFT
	_hammer(sim).rhythm = 2
	sim.start_attack(creature, sim._creature_lunge)
	_run(sim, creature.move.windup_ticks() + creature.move.active_ticks() + 10)
	assert_true(sim.player.health < T.PLAYER_HEALTH, "the lunge landed")
	assert_eq(_hammer(sim).rhythm, 0, "Rhythm lost")


func test_wide_sweet_spot_setting_widens_and_never_narrows() -> void:
	var hammer: Hammer = Hammer.new()
	hammer.wide_sweet_spot = true
	for stacks: int in range(4):
		hammer.rhythm = stacks
		var window: Vector2i = hammer.sweet_spot_ticks()
		assert_eq(window.y - window.x, T.ticks(Hammer.WIDE_SWEET_SPOT_MS), "300 ms at Rhythm %d" % stacks)


# --- Armour ------------------------------------------------------------------------

func test_armour_reduces_damage_and_is_chipped_away() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.player.weapon_index = 0  # greatsword
	var shell: Fighter = sim.creatures[0]
	shell.give_armour(T.ARMOURED_CREATURE_ARMOUR)
	sim.step(CombatInput.press(&"light"))
	_until_free(sim)
	var light: float = Greatsword.LIGHTS[0].damage
	assert_eq(shell.health, T.CREATURE_HEALTH - light * T.ARMOUR_DAMAGE_TAKEN, "40% gets through")
	assert_eq(shell.armour, T.ARMOURED_CREATURE_ARMOUR - light, "the full hit chips the shell")


func test_chipped_armour_breaks_and_then_takes_full_damage() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	sim.player.weapon_index = 0
	var shell: Fighter = sim.creatures[0]
	shell.give_armour(5.0)
	sim.step(CombatInput.press(&"light"))
	var broke: bool = false
	for i: int in range(60):
		sim.step(CombatInput.new())
		broke = broke or _count(sim.events, "armour_break") > 0
	assert_true(broke, "armour_break reported")
	assert_eq(shell.armour, 0.0, "shell gone")
	var before: float = shell.health
	sim._hit(sim.player, shell, Greatsword.LIGHTS[0])
	assert_eq(shell.health, before - Greatsword.LIGHTS[0].damage, "full damage without the shell")


func test_perfect_strike_shatters_armour() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var shell: Fighter = sim.creatures[0]
	shell.give_armour(T.ARMOURED_CREATURE_ARMOUR)
	var seen: Array[Dictionary] = _strike(sim, _perfect_ticks())
	assert_eq(_count(seen, "armour_break"), 1, "armour_break reported once")
	assert_eq(shell.armour, 0.0, "shell shattered")
	assert_eq(shell.health, T.CREATURE_HEALTH - Hammer.STRIKE_DAMAGE, "the strike lands at full damage")


func test_early_strike_only_chips_armour() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var shell: Fighter = sim.creatures[0]
	shell.give_armour(T.ARMOURED_CREATURE_ARMOUR)
	_strike(sim, _perfect_ticks() - 1)
	assert_true(shell.armour > 0.0, "shell still there")


func test_armour_returns_when_the_creature_respawns() -> void:
	var sim: CombatSim = _field([Vector2(125, 150)])
	var shell: Fighter = sim.creatures[0]
	shell.give_armour(T.ARMOURED_CREATURE_ARMOUR)
	shell.armour = 0.0
	sim._respawn(shell)
	assert_eq(shell.armour, T.ARMOURED_CREATURE_ARMOUR, "a new shell")


# --- Ground stamp and cancelling ---------------------------------------------------

func test_ground_stamp_briefly_staggers_creatures_right_next_to_you() -> void:
	var sim: CombatSim = _field([Vector2(114, 150), Vector2(88, 156), Vector2(132, 150)])
	sim.step(CombatInput.press(&"skill"))
	assert_eq(sim.player.move, Hammer.GROUND_STAMP, "Ground stamp")
	for i: int in range(20):
		sim.step(CombatInput.new())
		if sim.creatures[0].is_staggered():
			break
	assert_true(sim.creatures[0].is_staggered(), "adjacent creature in front staggered")
	assert_true(sim.creatures[1].is_staggered(), "adjacent creature behind staggered")
	assert_false(sim.creatures[2].is_staggered(), "a creature a step away is not")
	assert_eq(sim.creatures[0].state_length, T.ticks(Hammer.GROUND_STAMP.stagger_ms), "a short stagger")


func test_dodge_cancels_a_charge() -> void:
	var sim: CombatSim = _field()
	sim.step(CombatInput.press(&"heavy"))
	_run(sim, 20, CombatInput.hold_heavy())
	var dodge: CombatInput = CombatInput.press(&"dodge")
	dodge.heavy_held = true
	sim.step(dodge)
	assert_eq(sim.player.state, Fighter.State.DODGE, "dodged out of the charge")


func test_skill_cancels_a_charge_into_ground_stamp() -> void:
	var sim: CombatSim = _field()
	sim.step(CombatInput.press(&"heavy"))
	_run(sim, 20, CombatInput.hold_heavy())
	var skill: CombatInput = CombatInput.press(&"skill")
	skill.heavy_held = true
	sim.step(skill)
	assert_eq(sim.player.move, Hammer.GROUND_STAMP, "stamped out of the charge")


func test_light_during_a_charge_is_ignored() -> void:
	var sim: CombatSim = _field()
	sim.step(CombatInput.press(&"heavy"))
	var light: CombatInput = CombatInput.press(&"light")
	light.heavy_held = true
	sim.step(light)
	_run(sim, 5, CombatInput.hold_heavy())
	assert_eq(sim.player.state, Fighter.State.CHARGE, "still charging")


# --- Feedback ----------------------------------------------------------------------

func test_charge_rumble_rises_then_hums_then_turns_rough() -> void:
	var sim: CombatSim = _field()
	var hammer: Hammer = _hammer(sim)
	var window: Vector2i = hammer.sweet_spot_ticks()
	assert_eq(sim.player_rumble(), Vector2.ZERO, "nothing while standing")
	sim.step(CombatInput.press(&"heavy"))
	var weak: Array[float] = []
	for i: int in range(window.x):
		weak.append(sim.player_rumble().x)
		sim.step(CombatInput.hold_heavy())
	for i: int in range(1, weak.size()):
		assert_true(weak[i] >= weak[i - 1], "rises with the charge (tick %d)" % i)
	assert_true(weak[0] > 0.0, "from the first tick")
	var hum: Vector2 = sim.player_rumble()
	assert_true(hum.y > 0.0 and hum.x > weak[weak.size() - 1] * 0.9, "both motors in the sweet spot (%s)" % hum)
	_run(sim, window.y - window.x, CombatInput.hold_heavy())
	var rough: Array[Vector2] = []
	for i: int in range(8):
		rough.append(sim.player_rumble())
		sim.step(CombatInput.hold_heavy())
	assert_true(rough.count(rough[0]) < rough.size(), "overcharged: a pulsing, uneven rumble (%s)" % [rough])
	sim.step(CombatInput.new())
	assert_eq(sim.player_rumble(), Vector2.ZERO, "stops with the release")

func test_hammer_events_map_to_haptic_effects() -> void:
	var p: Fighter = Fighter.make_player(Vector2.ZERO)
	var c: Fighter = Fighter.make_creature(Vector2.ZERO)
	assert_eq(Haptics.effect_for_event({"type": "charge_start", "fighter": p}), &"hammer_charge", "charge")
	assert_eq(Haptics.effect_for_event({"type": "charge_level", "fighter": p, "level": 1}), &"hammer_level", "level 1 click")
	assert_eq(Haptics.effect_for_event({"type": "charge_level", "fighter": p, "level": 2}), &"hammer_level", "level 2 click")
	assert_eq(Haptics.effect_for_event({"type": "charge_level", "fighter": p, "level": 3}), &"hammer_sweet_spot",
		"a sharper click at level 3")
	assert_eq(Haptics.effect_for_event({"type": "overcharge", "fighter": p}), &"hammer_overcharge", "overcharge jolt")
	assert_eq(Haptics.effect_for_event({"type": "shockwave", "fighter": p}), &"hammer_perfect", "perfect strike")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": c, "move": Hammer.STRIKE_PERFECT}), &"",
		"no second pulse for the perfect strike's hit")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": c, "move": Hammer.STRIKE_LATE}), &"hammer_hit", "strike")
	assert_eq(Haptics.effect_for_event({"type": "hit", "target": c, "move": &"hammer_jab"}), &"hammer_jab", "jab")
	for effect: StringName in [&"hammer_charge", &"hammer_level", &"hammer_sweet_spot", &"hammer_overcharge",
			&"hammer_perfect", &"hammer_hit", &"hammer_jab"]:
		assert_true(Haptics.EFFECTS.has(effect), "%s is defined" % effect)
	# Heaviest: the strongest motor setting for the longest time (the charge
	# hum lasts longer but is faint).
	var heaviest: float = _pulse_weight(Haptics.EFFECTS[&"hammer_perfect"])
	for effect: StringName in Haptics.EFFECTS:
		if effect != &"hammer_perfect":
			assert_true(_pulse_weight(Haptics.EFFECTS[effect]) < heaviest,
				"the perfect strike is the heaviest pulse (vs %s)" % effect)


func _pulse_weight(values: Array) -> float:
	return maxf(float(values[0]), float(values[1])) * float(values[2])


func test_shockwave_and_armour_break_leave_effects() -> void:
	var effects: Array[Dictionary] = []
	var events: Array[Dictionary] = [
		{"type": "shockwave", "position": Vector2(10, 10), "radius": 36.0},
		{"type": "armour_break", "position": Vector2(20, 20)},
		{"type": "swap"},
	]
	CombatDrawer.update_effects(effects, events)
	assert_eq(effects.size(), 2, "two effects, nothing for the swap")
	assert_eq(effects[0]["radius"], 36.0, "the ring knows its size")
	for i: int in range(30):
		CombatDrawer.update_effects(effects, [] as Array[Dictionary])
	assert_true(effects.is_empty(), "effects end")
