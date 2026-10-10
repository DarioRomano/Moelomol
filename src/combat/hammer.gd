class_name Hammer
extends Weapon
## The hammer (docs/design/combat.md, "Hammer: timing is everything").
##
## Light: quick jabs. Heavy: hold to charge (the player walks slowly) through
## three levels, release to strike. Levels 1 and 2 are weaker strikes; level 3
## is the sweet spot: releasing in it is a perfect strike (full damage, a
## cone-shaped shockwave forward that staggers what it reaches, armour break,
## and it cashes in magic's stacks). Holding past level 3 overcharges it:
## Overstrain, a weak strike and extra stamina, and the hold drains stamina
## until the hammer comes down on its own. Each consecutive perfect strike adds
## Rhythm (max 3): more damage, a longer shockwave, a narrower sweet spot.
## Skill: Ground stamp, a short stagger for creatures right next to the player.
##
## Three levels and the cone shockwave: the lead's change of 2026-10-10.
## Starting values; tuning needs the lead's approval.

## Held time to reach charge levels 1, 2 and 3. Level 3 is the sweet spot.
const LEVEL_MS: Array[int] = [300, 600, 900]
const SWEET_SPOT_START_MS: int = 900  # = LEVEL_MS[2]
const SWEET_SPOT_MS: int = 150
const SWEET_SPOT_NARROWING_MS: int = 25  # per Rhythm stack
## Accessibility setting: a wider sweet spot that does not narrow.
const WIDE_SWEET_SPOT_MS: int = 300
const MAX_RHYTHM: int = 3
const RHYTHM_DAMAGE_BONUS: float = 0.25  # per stack, on a perfect strike

const CHARGE_STAMINA: float = 15.0  # paid when the charge starts
const OVERSTRAIN_STAMINA: float = 15.0  # extra, when an overcharged strike lands
const OVERSTRAIN_DRAIN_PER_S: float = 25.0  # while held past the sweet spot

const STRIKE_DAMAGE: float = 40.0
const STRIKE_POISE: float = 70.0
## Share of full damage and poise by grade.
const TAP_SHARE: float = 0.2  # released before level 1
const LEVEL_1_SHARE: float = 0.35
const LEVEL_2_SHARE: float = 0.6
const OVERSTRAIN_SHARE: float = 0.4
## The perfect strike's shockwave: a cone forward from the player's centre.
const SHOCKWAVE_REACH: float = 64.0
const SHOCKWAVE_REACH_PER_RHYTHM: float = 8.0
const SHOCKWAVE_ARC_DEG: float = 70.0

const STRIKE_TAP: StringName = &"hammer_strike_tap"
const STRIKE_LEVEL_1: StringName = &"hammer_strike_level_1"
const STRIKE_LEVEL_2: StringName = &"hammer_strike_level_2"
const STRIKE_PERFECT: StringName = &"hammer_strike_perfect"
const STRIKE_LATE: StringName = &"hammer_strike_late"  # overcharged: Overstrain

static var JAB: CombatMove = _jab()
static var GROUND_STAMP: CombatMove = _ground_stamp()

var rhythm: int = 0
## Accessibility (docs/design/combat.md): widens the sweet spot and turns off
## the Rhythm narrowing. Set from GameSettings by the scene.
var wide_sweet_spot: bool = false


func _init() -> void:
	id = &"hammer"
	display_name = "Hammer"


func try_action(sim: CombatSim, action: StringName, _input: CombatInput) -> bool:
	var p: Fighter = sim.player
	match action:
		&"light":
			return sim.start_attack(p, JAB)
		&"heavy":
			if not p.stamina.try_spend(CHARGE_STAMINA):
				sim.events.append({"type": "no_stamina"})
				return false
			p.move = null
			p.enter(Fighter.State.CHARGE)
			sim.events.append({"type": "charge_start", "fighter": p})
			return true
		&"skill":
			return sim.start_attack(p, GROUND_STAMP)
	return false


func step_charge(sim: CombatSim, input: CombatInput) -> void:
	var p: Fighter = sim.player
	var held: int = p.state_tick  # ticks the button has been held since the press
	var window: Vector2i = sweet_spot_ticks()
	var level: int = level_ticks().find(held)
	if level >= 0:
		sim.events.append({"type": "charge_level", "fighter": p, "level": level + 1})
	if held == window.y:
		sim.events.append({"type": "overcharge", "fighter": p})
	if not input.heavy_held:
		release(sim, held)
		return
	if held >= window.y:
		var drain: float = CombatTuning.per_tick(OVERSTRAIN_DRAIN_PER_S)
		if p.stamina.current < drain:
			release(sim, held)  # out of stamina: the hammer comes down by itself
			return
		p.stamina.current -= drain
		p.stamina.hold()


## Strikes after the charge was held `held` ticks.
func release(sim: CombatSim, held: int) -> void:
	var p: Fighter = sim.player
	var grade: StringName = grade_for(held)
	var strike: CombatMove = strike_for(held)
	match grade:
		STRIKE_PERFECT:
			rhythm = mini(rhythm + 1, MAX_RHYTHM)
		STRIKE_LATE:
			rhythm = 0
			p.stamina.current = maxf(0.0, p.stamina.current - OVERSTRAIN_STAMINA)
			p.stamina.hold()
		_:
			rhythm = 0
	sim.events.append({"type": "strike", "fighter": p, "grade": grade})
	sim.start_attack(p, strike)


func on_owner_hit(_sim: CombatSim) -> void:
	rhythm = 0


func status_text(p: Fighter) -> String:
	var text: String = "rhythm %d" % rhythm
	if p.state == Fighter.State.CHARGE:
		text += "   charge level %d%s" % [level_for(p.state_tick),
			"  OVERCHARGED" if p.state_tick >= sweet_spot_ticks().y else ""]
	return text


## Held ticks at which levels 1, 2 and 3 are reached.
func level_ticks() -> Array[int]:
	var result: Array[int] = []
	for ms: int in LEVEL_MS:
		result.append(CombatTuning.ticks(ms))
	return result


## The charge level after `held` ticks: 0 (none yet) to 3.
func level_for(held: int) -> int:
	var level: int = 0
	for threshold: int in level_ticks():
		if held >= threshold:
			level += 1
	return level


## The sweet spot (level 3) as [first tick, first tick after it] of held
## time; from its end on, the charge is overcharged.
func sweet_spot_ticks() -> Vector2i:
	var width_ms: int = WIDE_SWEET_SPOT_MS if wide_sweet_spot \
		else SWEET_SPOT_MS - SWEET_SPOT_NARROWING_MS * rhythm
	var start: int = CombatTuning.ticks(SWEET_SPOT_START_MS)
	return Vector2i(start, start + CombatTuning.ticks(width_ms))


## The grade of a release after `held` ticks.
func grade_for(held: int) -> StringName:
	if held >= sweet_spot_ticks().y:
		return STRIKE_LATE
	var grades: Array[StringName] = [STRIKE_TAP, STRIKE_LEVEL_1, STRIKE_LEVEL_2, STRIKE_PERFECT]
	return grades[level_for(held)]


## The strike for a release after `held` ticks, at the current Rhythm.
func strike_for(held: int) -> CombatMove:
	var grade: StringName = grade_for(held)
	var shares: Dictionary = {STRIKE_TAP: TAP_SHARE, STRIKE_LEVEL_1: LEVEL_1_SHARE, STRIKE_LEVEL_2: LEVEL_2_SHARE,
		STRIKE_PERFECT: 1.0 + RHYTHM_DAMAGE_BONUS * rhythm, STRIKE_LATE: OVERSTRAIN_SHARE}
	var names: Dictionary = {STRIKE_TAP: "Strike (tap)", STRIKE_LEVEL_1: "Strike (level 1)",
		STRIKE_LEVEL_2: "Strike (level 2)", STRIKE_PERFECT: "Perfect strike", STRIKE_LATE: "Overcharged"}
	var share: float = shares[grade]
	var m: CombatMove = CombatMove.make(grade, names[grade], Vector3i(100, 100, 450),
		STRIKE_DAMAGE * share, STRIKE_POISE * minf(share, 1.0), 10.0, 42.0, 100.0, 0.0)
	m.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	if grade == STRIKE_PERFECT:
		m.hitstop_ms = CombatTuning.HITSTOP_BIG_MS
		m.breaks_armour = true
		m.releases_effects = true  # a perfect strike cashes in magic's stacks
		m.shockwave_radius = SHOCKWAVE_REACH + SHOCKWAVE_REACH_PER_RHYTHM * rhythm
		m.shockwave_arc_deg = SHOCKWAVE_ARC_DEG
	return m


## Controller rumble while charging: rising through the levels, a steady
## hum in the sweet spot, a rough pulse when overcharged.
func charge_rumble(p: Fighter) -> Vector2:
	var held: int = p.state_tick
	var window: Vector2i = sweet_spot_ticks()
	if held >= window.y:
		return Vector2(0.5, 0.6) if (held / 4) % 2 == 0 else Vector2(0.2, 0.1)
	if held >= window.x:
		return Vector2(0.45, 0.25)
	return Vector2(0.05 + 0.3 * float(held) / window.x, 0.0)


static func _jab() -> CombatMove:
	return CombatMove.make(&"hammer_jab", "Jab", Vector3i(150, 80, 200), 6.0, 12.0, 4.0, 34.0, 70.0, 5.0)


static func _ground_stamp() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"ground_stamp", "Ground stamp", Vector3i(100, 80, 300),
		4.0, 0.0, 12.0, 17.0, 360.0, 12.0)
	m.stagger_ms = 400  # a short, certain stagger
	return m
