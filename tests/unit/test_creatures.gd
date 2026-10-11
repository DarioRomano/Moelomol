extends TestCase
## Millbrook's creatures and Grist (docs/design/enemies.md), in the pure
## simulation: each test builds an open field, adds one kind of creature and
## drives CombatSim.step() tick by tick. The player stands still unless moved.

const T: GDScript = preload("res://src/combat/combat_tuning.gd")
const B: GDScript = preload("res://src/combat/creature_brain.gd")


## An open 400x300 field, the player at (100, 150) facing right.
func _field() -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 400, 300), Vector2(100, 150))
	sim.player.facing = Vector2.RIGHT
	return sim


## Steps until `done` is true; returns every event seen. Fails the test if it
## never happens within max_ticks.
func _until(sim: CombatSim, done: Callable, what: String, max_ticks: int = 600,
		input: CombatInput = CombatInput.new()) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(max_ticks):
		if done.call():
			return seen
		sim.step(input)
		seen.append_array(sim.events)
	assert_true(done.call(), "never happened: " + what)
	return seen


func _run(sim: CombatSim, ticks: int, input: CombatInput = CombatInput.new()) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(ticks):
		sim.step(input)
		seen.append_array(sim.events)
	return seen


func _count(events: Array[Dictionary], type: String) -> int:
	return events.filter(func(e: Dictionary) -> bool: return e["type"] == type).size()


## A hit with given damage and poise, from the player (a plain test move).
func _blow(damage: float, poise: float, heavy: bool = false) -> CombatMove:
	var m: CombatMove = CombatMove.make(&"test_blow", "Blow", Vector3i.ZERO, damage, poise, 0.0, 0.0, 0.0, 0.0)
	m.heavy = heavy
	m.hitstop_ms = 0
	return m


func _attacking(c: Fighter, move_id: StringName) -> bool:
	return c.state == Fighter.State.ATTACK and c.move != null and c.move.id == move_id


# --- Kinds ------------------------------------------------------------------------------

func test_each_kind_has_its_starting_values() -> void:
	var mouse: Fighter = Fighter.make_creature(Vector2.ZERO, CreatureKind.field_mouse())
	assert_eq([mouse.max_health, mouse.radius], [18.0, 4.0], "field mouse")
	var grist: Fighter = Fighter.make_creature(Vector2.ZERO, CreatureKind.grist())
	assert_eq([grist.max_health, grist.radius, grist.poise.maximum], [600.0, 14.0, 150.0], "Grist")
	assert_eq(Fighter.make_creature(Vector2.ZERO, CreatureKind.flood_toad()).resists, [StatusEffects.SMOULDER], "toads resist Smoulder")
	assert_eq(Fighter.make_creature(Vector2.ZERO).creature_kind.id, &"training", "the default is the training creature")
	for id: StringName in [&"field_mouse", &"rook", &"hedgehog", &"flood_toad", &"stook", &"moth", &"grist"]:
		assert_eq(CreatureKind.by_id(id).id, id, "by_id finds " + id)


func test_a_lane_zone_hits_only_inside_its_strip() -> void:
	var target: Fighter = Fighter.make_creature(Vector2(50, 0))
	var zone: Dictionary = {"shape": &"lane", "origin": Vector2.ZERO, "facing": Vector2.RIGHT, "reach": 60.0, "width": 8.0}
	assert_true(CombatSim.in_zone(zone, target), "on the lane")
	target.position = Vector2(50, 4.0 + target.radius + 0.5)
	assert_false(CombatSim.in_zone(zone, target), "just beside it")
	target.position = Vector2(60.0 + target.radius + 0.5, 0)
	assert_false(CombatSim.in_zone(zone, target), "just past its end")
	target.position = Vector2(-target.radius - 0.5, 0)
	assert_false(CombatSim.in_zone(zone, target), "just behind its start")


# --- Field mice -------------------------------------------------------------------------

func test_mice_zigzag_in_and_nip() -> void:
	var sim: CombatSim = _field()
	var mouse: Fighter = sim.add_creature(Vector2(220, 150), CreatureKind.field_mouse())
	var off_line: Array[float] = [0.0]
	_until(sim, func() -> bool:
		off_line[0] = maxf(off_line[0], absf(mouse.position.y - 150.0))
		return _attacking(mouse, &"mouse_nip"), "the nip")
	assert_true(off_line[0] > 3.0, "it weaves on the way in (%.1f px off the line)" % off_line[0])
	var health: float = sim.player.health
	_run(sim, 30)
	assert_eq(sim.player.health, health - 4.0, "a nip does 4")


func test_a_hurt_mouse_flees_then_comes_back() -> void:
	var sim: CombatSim = _field()
	var mouse: Fighter = sim.add_creature(Vector2(130, 150), CreatureKind.field_mouse())
	sim._hit(sim.player, mouse, _blow(1.0, 0.0))
	assert_eq(mouse.ai_state, &"flee", "it flees")
	var before: float = mouse.position.distance_to(sim.player.position)
	_run(sim, T.ticks(B.MOUSE_FLEE_MS) - 1)
	var fled: float = mouse.position.distance_to(sim.player.position)
	assert_true(fled > before + 20.0, "it ran off (%.0f px to %.0f px)" % [before, fled])
	_run(sim, 30)
	assert_true(mouse.position.distance_to(sim.player.position) < fled, "then comes back")


# --- Rooks --------------------------------------------------------------------------------

func test_a_rook_aloft_is_out_of_melee_reach_but_not_of_arrows() -> void:
	var sim: CombatSim = _field()
	var rook: Fighter = sim.add_creature(Vector2(125, 150), CreatureKind.rook())
	sim.step(CombatInput.new())
	assert_true(rook.airborne, "aloft")
	rook.ai_enabled = false
	rook.position = Vector2(125, 150)
	sim.step(CombatInput.press(&"light"))
	_run(sim, 40)
	assert_eq(rook.health, rook.max_health, "the greatsword passes under it")
	sim.player.weapons[1] = Bow.new()
	sim.player.weapon_index = 1
	sim.player.facing = Vector2.RIGHT
	sim.step(CombatInput.press(&"light"))
	_run(sim, 40)
	assert_true(rook.health < rook.max_health, "an arrow hits it")


func test_a_rook_dives_along_a_lane_lands_and_rises() -> void:
	var sim: CombatSim = _field()
	var rook: Fighter = sim.add_creature(Vector2(200, 150), CreatureKind.rook())
	_until(sim, func() -> bool: return _attacking(rook, &"rook_dive"), "the dive", 400)
	assert_eq(rook.move.shape, &"lane", "the dive is a lane")
	assert_false(rook.airborne, "it comes down to dive")
	_until(sim, func() -> bool: return rook.attack_phase() == &"recovery", "the landing")
	var health: float = rook.health
	sim._hit(sim.player, rook, _blow(5.0, 0.0))
	assert_eq(rook.health, health - 5.0, "landed, it can be hit")
	_until(sim, func() -> bool: return rook.state == Fighter.State.FREE, "the end of the landing")
	assert_true(rook.airborne, "and back up")


# --- Hedgehogs --------------------------------------------------------------------------

func test_a_close_hedgehog_curls_and_shrugs_off_light_hits() -> void:
	var sim: CombatSim = _field()
	var hog: Fighter = sim.add_creature(Vector2(140, 150), CreatureKind.hedgehog())
	_until(sim, func() -> bool: return hog.curled, "the curl")
	sim._hit(sim.player, hog, _blow(10.0, 100.0))
	assert_eq(hog.health, hog.max_health - 10.0 * B.HEDGEHOG_CURLED_DAMAGE, "a fifth of a light hit")
	assert_false(hog.is_staggered(), "and no stagger, however much poise damage")
	assert_true(hog.curled, "still curled")


func test_a_heavy_hit_uncurls_and_staggers_a_hedgehog() -> void:
	var sim: CombatSim = _field()
	var hog: Fighter = sim.add_creature(Vector2(140, 150), CreatureKind.hedgehog())
	_until(sim, func() -> bool: return hog.curled, "the curl")
	sim._hit(sim.player, hog, _blow(10.0, 0.0, true))
	assert_eq(hog.health, hog.max_health - 10.0, "full damage")
	assert_false(hog.curled, "uncurled")
	assert_true(hog.is_staggered(), "and staggered")


func test_the_greatsword_finishers_and_hammer_strikes_are_heavy() -> void:
	for move: CombatMove in Greatsword.FINISHERS:
		assert_true(move.heavy, move.display_name)
	assert_true(Greatsword.FOLLOW_THROUGH.heavy, "Follow-through")
	assert_true(Greatsword.BRACE_COUNTER.heavy, "the Riposte")
	assert_false(Greatsword.LIGHTS[0].heavy, "a light swing is not")
	var hammer: Hammer = Hammer.new()
	assert_true(hammer.strike_for(0).heavy, "a tapped hammer strike")
	assert_false(Hammer.JAB.heavy, "the jab is not")


func test_a_hedgehog_that_rolls_into_a_wall_is_dazed() -> void:
	var sim: CombatSim = _field()
	var hog: Fighter = sim.add_creature(Vector2(140, 150), CreatureKind.hedgehog())
	sim.obstacles.append(Rect2(118, 100, 4, 100))  # a low wall between it and the player
	_until(sim, func() -> bool: return _attacking(hog, &"hedgehog_roll"), "the roll")
	_until(sim, func() -> bool: return hog.state != Fighter.State.ATTACK, "the roll's end")
	assert_true(hog.is_staggered(), "dazed")
	assert_eq(hog.state_length, T.ticks(B.HEDGEHOG_DAZE_MS), "for 0.8 s")
	assert_false(hog.curled, "and uncurled")


# --- Flood toads ------------------------------------------------------------------------

func test_a_toad_lobs_at_where_the_player_stood() -> void:
	var sim: CombatSim = _field()
	sim.add_creature(Vector2(210, 150), CreatureKind.flood_toad())
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return not sim.zones.is_empty(), "the lob")
	assert_eq(_count(seen, "lob"), 1, "one lob")
	var glob: Zone = sim.zones[0]
	assert_eq(glob.kind, &"glob", "a glob")
	assert_true(glob.position.distance_to(Vector2(100, 150)) < 0.01, "marked where the player stands")
	sim.player.position = Vector2(100, 100)  # step away before it lands
	_run(sim, T.ticks(B.GLOB_FLIGHT_MS) + 2)
	assert_eq(sim.player.health, sim.player.max_health, "it lands on nothing")


func test_a_glob_on_the_player_hurts_and_its_slick_slows() -> void:
	var sim: CombatSim = _field()
	var toad: Fighter = sim.add_creature(Vector2(210, 150), CreatureKind.flood_toad())
	_until(sim, func() -> bool: return not sim.zones.is_empty(), "the lob")
	toad.ai_enabled = false
	assert_eq(sim.ground_speed_factor(sim.player), 1.0, "no slick before it lands")
	_run(sim, T.ticks(B.GLOB_FLIGHT_MS) + 1)
	assert_eq(sim.player.health, sim.player.max_health - 8.0, "the glob does 8")
	assert_eq(sim.ground_speed_factor(sim.player), B.SLICK_SLOW, "the slick slows")
	_run(sim, T.ticks(B.SLICK_MS) + 2)
	assert_eq(sim.ground_speed_factor(sim.player), 1.0, "for 3 s")


func test_a_toad_hops_back_when_approached() -> void:
	var sim: CombatSim = _field()
	var toad: Fighter = sim.add_creature(Vector2(150, 150), CreatureKind.flood_toad())
	_run(sim, T.ticks(B.TOAD_HOP_MS))
	assert_true(toad.position.x > 165.0, "it hopped away (x = %.0f)" % toad.position.x)


# --- Stooks -------------------------------------------------------------------------------

func test_a_stook_hides_from_lock_on_until_it_rises_and_lashes() -> void:
	var sim: CombatSim = _field()
	var stook: Fighter = sim.add_creature(Vector2(200, 150), CreatureKind.stook())
	assert_true(stook.disguised, "a sheaf like any other")
	var hold: CombatInput = CombatInput.new()
	hold.lock_held = true
	sim.step(hold)
	assert_eq(sim.lock_target, null, "no lock-on")
	_run(sim, 60)
	assert_true(stook.disguised, "it waits")
	sim.player.position = Vector2(200 - 7 - 6 - 20, 150)
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return _attacking(stook, &"stook_lash"), "the lash")
	assert_eq(_count(seen, "reveal"), 1, "it rose")
	assert_eq(stook.move.arc_deg, 360.0, "the lash goes all round")


func test_a_struck_stook_reveals_itself() -> void:
	var sim: CombatSim = _field()
	var stook: Fighter = sim.add_creature(Vector2(300, 150), CreatureKind.stook())
	sim._hit(sim.player, stook, _blow(5.0, 0.0))
	assert_false(stook.disguised, "revealed")
	assert_eq(stook.ai_state, &"rising", "rising")


func test_smoulder_spreads_from_a_stook_at_three_stacks() -> void:
	var sim: CombatSim = _field()
	var stook: Fighter = sim.add_creature(Vector2(300, 150), CreatureKind.stook())
	var neighbour: Fighter = sim.add_creature(Vector2(310, 160), CreatureKind.stook())
	sim.apply_effect(stook, StatusEffects.SMOULDER, 3)
	assert_eq(_count(sim.events, "spread"), 1, "dry straw spreads at 3")
	assert_eq(neighbour.effects.count(StatusEffects.SMOULDER), 1, "to the stook beside it")


func test_a_stook_goes_home_and_hides_when_the_player_leaves() -> void:
	var sim: CombatSim = _field()
	var stook: Fighter = sim.add_creature(Vector2(200, 150), CreatureKind.stook())
	B.reveal(sim, stook)
	_run(sim, 60)
	sim.player.position = Vector2(20, 20)  # far beyond its patch
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return stook.disguised, "the disguise", 800)
	assert_eq(_count(seen, "disguise"), 1, "it stood still again")
	assert_true(stook.position.distance_to(Vector2(200, 150)) <= 4.0, "at home")


# --- Moths --------------------------------------------------------------------------------

func test_moths_swirl_round_a_light_and_dart_when_the_player_comes_near() -> void:
	var sim: CombatSim = _field()
	sim.lights = [Vector2(250, 150)]
	var moth: Fighter = sim.add_creature(Vector2(250, 140), CreatureKind.moth())
	_run(sim, 120)
	assert_true(moth.position.distance_to(Vector2(250, 150)) < B.MOTH_ORBIT_RADIUS + 4.0, "it swirls round the light")
	assert_ne(moth.state, Fighter.State.ATTACK, "the player is far off")
	sim.player.position = Vector2(215, 150)
	_until(sim, func() -> bool: return _attacking(moth, &"moth_dart"), "the dart", 120)


func test_a_moth_is_spent_on_its_hit() -> void:
	var sim: CombatSim = _field()
	var moth: Fighter = sim.add_creature(Vector2(115, 150), CreatureKind.moth())
	sim._hit(moth, sim.player, CreatureKind.moth().moves[&"attack"])
	assert_eq(sim.player.health, sim.player.max_health - 3.0, "3 damage")
	assert_eq(moth.state, Fighter.State.DOWN, "and the moth is gone")


# --- Grist ---------------------------------------------------------------------------------

## Grist's yard in a 300x260 field: Grist at (150, 70), the player at
## (150, 200), the wallow in the north-west corner.
func _yard() -> CombatSim:
	var sim: CombatSim = CombatSim.new(Rect2(0, 0, 300, 260), Vector2(150, 200))
	sim.add_prop(&"wallow", Rect2(10, 10, 40, 30), false)
	return sim


func test_grist_gores_when_close() -> void:
	var sim: CombatSim = _yard()
	var grist: Fighter = sim.add_creature(Vector2(150, 160), CreatureKind.grist())
	_until(sim, func() -> bool: return _attacking(grist, &"grist_gore"), "the gore", 120)
	assert_eq(grist.move.arc_deg, 120.0, "a 120 degree gore")


func test_grist_charges_to_the_first_obstacle_and_is_stunned_there() -> void:
	var sim: CombatSim = _yard()
	var grist: Fighter = sim.add_creature(Vector2(150, 70), CreatureKind.grist())
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return _attacking(grist, &"grist_charge"), "the charge", 120)
	var lane: float = grist.move.dash
	var to_fence: float = 260.0 - 14.0 - 70.0
	assert_true(absf(lane - (to_fence + B.CHARGE_OVERRUN)) < 3.0, "the lane runs to the fence (%.0f px)" % lane)
	sim.player.position = Vector2(40, 200)  # sidestep
	seen = _until(sim, func() -> bool: return grist.state != Fighter.State.ATTACK, "the end of the charge", 200)
	assert_true(grist.is_staggered(), "stunned against the fence")
	assert_eq(grist.state_length, T.ticks(B.GRIST_STUN_MS), "for 1.5 s")
	assert_eq(_count(seen, "impact"), 1, "an impact")
	assert_eq(sim.player.health, sim.player.max_health, "the sidestep worked")


func test_a_charge_into_grain_sacks_bursts_them_and_brings_mice() -> void:
	var sim: CombatSim = _yard()
	sim.add_prop(&"sacks", Rect2(135, 225, 30, 20), true)
	var grist: Fighter = sim.add_creature(Vector2(150, 70), CreatureKind.grist())
	_until(sim, func() -> bool: return _attacking(grist, &"grist_charge"), "the charge", 120)
	sim.player.position = Vector2(40, 200)
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return grist.state != Fighter.State.ATTACK, "the end of the charge", 200)
	assert_eq(_count(seen, "sacks_burst"), 1, "the sacks burst")
	assert_true(sim.prop_of(&"sacks").is_empty(), "and are gone")
	var mice: int = sim.creatures.filter(func(c: Fighter) -> bool: return c.creature_kind.id == &"field_mouse").size()
	assert_eq(mice, B.GRIST_SACK_MICE, "three mice come for the grain")
	assert_false(grist.is_staggered(), "sacks are soft: no stun")


func test_at_half_health_grist_wallows_untouchable_and_comes_out_armoured() -> void:
	var sim: CombatSim = _yard()
	var grist: Fighter = sim.add_creature(Vector2(150, 70), CreatureKind.grist())
	grist.health = 299.0
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return grist.ai_state == &"wallowing", "the wallow", 400)
	assert_eq(grist.phase, 2, "phase two")
	sim._hit(sim.player, grist, _blow(50.0, 0.0))
	assert_eq(grist.health, 299.0, "nothing hurts it in the mud")
	seen = _until(sim, func() -> bool: return grist.ai_state != &"wallowing", "the end of the wallow", 200)
	assert_eq(grist.armour, B.GRIST_MUD_ARMOUR, "caked in mud")
	assert_eq(_count(seen, "mud_armour"), 1, "reported")


func test_in_phase_two_grist_shrugs_off_the_fence_and_charges_again() -> void:
	var sim: CombatSim = _yard()
	var grist: Fighter = sim.add_creature(Vector2(150, 70), CreatureKind.grist())
	grist.phase = 2
	_until(sim, func() -> bool: return _attacking(grist, &"grist_charge"), "the first charge", 120)
	sim.player.position = Vector2(40, 200)  # sidestep: the charge runs on to the fence
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return _count(sim.events, "shrug") > 0, "the shrug", 200)
	sim.player.position = Vector2(260, 40)  # and sidestep the second charge too
	seen.append_array(_until(sim, func() -> bool: return grist.is_staggered(), "the stun", 400))
	assert_eq(_count(seen, "shrug"), 1, "the first charge's fence is shrugged off")
	var charges: int = seen.filter(func(e: Dictionary) -> bool:
		return e["type"] == "attack" and e["move"] == &"grist_charge").size()
	assert_eq(charges, 1, "a second charge followed at once")
	assert_eq(_count(seen, "impact"), 1, "and that one ended in a stun")


func test_in_phase_two_a_charge_into_a_millstone_still_stuns() -> void:
	var sim: CombatSim = _yard()
	sim.add_prop(&"millstone_flat", Rect2(140, 230, 20, 20), true)
	var grist: Fighter = sim.add_creature(Vector2(150, 70), CreatureKind.grist())
	grist.phase = 2
	_until(sim, func() -> bool: return _attacking(grist, &"grist_charge"), "the charge", 120)
	sim.player.position = Vector2(40, 200)
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return grist.state != Fighter.State.ATTACK, "the end", 300)
	assert_true(grist.is_staggered(), "stunned on the first charge")
	assert_eq(_count(seen, "shrug"), 0, "no shrug against stone")


func test_grist_heaves_a_millstone_that_bounces_once_and_comes_to_rest() -> void:
	var sim: CombatSim = _yard()
	sim.add_prop(&"millstone_leaning", Rect2(140, 12, 20, 12), true)
	var grist: Fighter = sim.add_creature(Vector2(150, 70), CreatureKind.grist())
	grist.phase = 2
	grist.ai_timer = 3  # due a millstone
	sim.player.position = Vector2(150, 200)
	var seen: Array[Dictionary] = _until(sim, func() -> bool: return not sim.projectiles.is_empty(), "the millstone", 600)
	assert_eq(_count(seen, "millstone"), 1, "heaved")
	assert_true(sim.prop_of(&"millstone_leaning").is_empty(), "the leaning stone is gone")
	seen = _until(sim, func() -> bool: return sim.projectiles.is_empty(), "the millstone at rest", 600)
	var hits: int = seen.filter(func(e: Dictionary) -> bool:
		return e["type"] == "hit" and e["move"] == &"millstone").size()
	assert_eq(hits, 2, "a player standing in its lane is hit there and back")
	assert_true(sim.player.health <= sim.player.max_health - 25.0, "25 damage or more")
	assert_eq(_count(seen, "bounce"), 1, "it bounced once")
	assert_false(sim.prop_of(&"millstone_flat").is_empty(), "and lies flat, something hard to charge into")


func test_grist_sleeps_at_night_and_wakes_when_hit() -> void:
	var sim: CombatSim = _yard()
	sim.night = true
	var grist: Fighter = sim.add_creature(Vector2(30, 25), CreatureKind.grist())
	sim.player.position = Vector2(200, 200)
	_until(sim, func() -> bool: return grist.ai_state == &"asleep", "sleep", 120)
	_run(sim, 120)
	assert_eq(grist.ai_state, &"asleep", "it sleeps while the player keeps away")
	assert_eq(grist.state, Fighter.State.FREE, "and does not attack")
	sim._hit(sim.player, grist, _blow(1.0, 0.0))
	assert_ne(grist.ai_state, &"asleep", "a hit wakes it")
	assert_true(grist.alerted, "for the rest of the night")


func test_grist_wakes_when_the_player_comes_too_close() -> void:
	var sim: CombatSim = _yard()
	sim.night = true
	var grist: Fighter = sim.add_creature(Vector2(30, 25), CreatureKind.grist())
	sim.player.position = Vector2(200, 200)
	_until(sim, func() -> bool: return grist.ai_state == &"asleep", "sleep", 120)
	sim.player.position = Vector2(30 + 14 + 6 + B.GRIST_WAKE_GAP + 2.0, 25)
	_run(sim, 10)
	assert_eq(grist.ai_state, &"asleep", "just outside the gap it sleeps on")
	sim.player.position = Vector2(30 + 14 + 6 + B.GRIST_WAKE_GAP - 2.0, 25)
	var seen: Array[Dictionary] = _run(sim, 2)
	assert_eq(_count(seen, "wake"), 1, "just inside, it wakes")


func test_grist_is_defeated_once_and_leaves_its_heart() -> void:
	var sim: CombatSim = _yard()
	var grist: Fighter = sim.add_creature(Vector2(150, 70), CreatureKind.grist())
	grist.ai_enabled = false
	grist.health = 5.0
	sim._hit(sim.player, grist, _blow(10.0, 0.0))
	var defeated: Array[Dictionary] = sim.events.filter(func(e: Dictionary) -> bool: return e["type"] == "boss_defeated")
	assert_eq(defeated.size(), 1, "a boss defeated")
	assert_true(&"grist_heart" in (defeated[0]["drops"] as Array), "it leaves its heart")
	_run(sim, 600)
	assert_eq(grist.state, Fighter.State.GONE, "and does not come back")


func test_a_charge_that_meets_the_fence_at_an_angle_still_ends_in_a_stun() -> void:
	# Sliding along a fence is not headway: the charge is over (found when a
	# phase-two charge slid along the fence instead of stopping, 2026-10-11).
	var sim: CombatSim = _yard()
	var grist: Fighter = sim.add_creature(Vector2(250, 70), CreatureKind.grist())
	# Heading (-0.6, 0.8) into the bottom fence, well clear of the corners: it
	# would slide along the fence at 60% speed, more than half, while gaining
	# only 36% along its lane.
	sim.player.position = Vector2(130, 230)
	_until(sim, func() -> bool: return _attacking(grist, &"grist_charge"), "the charge", 120)
	sim.player.position = Vector2(40, 60)  # out of the lane
	_until(sim, func() -> bool: return grist.state != Fighter.State.ATTACK, "the end of the charge", 300)
	assert_true(grist.is_staggered(), "stunned where it met the fence at an angle")
