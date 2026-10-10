class_name Hammer
extends Weapon
## The hammer (docs/design/combat.md, "Hammer: timing is everything").
##
## Light: quick jabs. Heavy: hold to charge (the player walks slowly), release
## to strike. Releasing in the sweet spot is a perfect strike: full damage, a
## shockwave that staggers everything nearby, and armour break. Early is
## partial damage scaled by the charge; late is Overstrain: a weak strike and
## extra stamina, and holding past the sweet spot drains stamina until the
## hammer comes down on its own. Each consecutive perfect strike adds Rhythm
## (max 3): more damage, a bigger shockwave, a narrower sweet spot. Skill:
## Ground stamp, a short stagger for creatures right next to the player.
##
## Starting values; tuning needs the lead's approval.

## The charge reaches the sweet spot after this long.
const SWEET_SPOT_START_MS: int = 900
const SWEET_SPOT_MS: int = 150
const SWEET_SPOT_NARROWING_MS: int = 25  # per Rhythm stack
## Accessibility setting: a wider sweet spot that does not narrow.
const WIDE_SWEET_SPOT_MS: int = 300
const MAX_RHYTHM: int = 3
const RHYTHM_DAMAGE_BONUS: float = 0.25  # per stack, on a perfect strike

const CHARGE_STAMINA: float = 15.0  # paid when the charge starts
const OVERSTRAIN_STAMINA: float = 15.0  # extra, when a late strike lands
const OVERSTRAIN_DRAIN_PER_S: float = 25.0  # while held past the sweet spot

const STRIKE_DAMAGE: float = 40.0
const STRIKE_POISE: float = 70.0
const EARLY_MIN: float = 0.2  # share of full damage for a release at once
const EARLY_MAX: float = 0.6  # share just before the sweet spot
const OVERSTRAIN_SHARE: float = 0.4
const SHOCKWAVE_RADIUS: float = 36.0  # from the player's centre
const SHOCKWAVE_RADIUS_PER_RHYTHM: float = 8.0

const STRIKE_EARLY: StringName = &"hammer_strike_early"
const STRIKE_PERFECT: StringName = &"hammer_strike_perfect"
const STRIKE_LATE: StringName = &"hammer_strike_late"

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
	if held == window.x:
		sim.events.append({"type": "sweet_spot", "fighter": p})
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
		text += "   charge %d ms" % roundi(p.state_tick * 1000.0 / CombatTuning.TICK_RATE)
	return text


## The sweet spot as [first tick, first tick after it] of held time.
func sweet_spot_ticks() -> Vector2i:
	var width_ms: int = WIDE_SWEET_SPOT_MS if wide_sweet_spot \
		else SWEET_SPOT_MS - SWEET_SPOT_NARROWING_MS * rhythm
	var start: int = CombatTuning.ticks(SWEET_SPOT_START_MS)
	return Vector2i(start, start + CombatTuning.ticks(width_ms))


## Early, perfect or late (Overstrain) for a release after `held` ticks.
func grade_for(held: int) -> StringName:
	var window: Vector2i = sweet_spot_ticks()
	if held < window.x:
		return STRIKE_EARLY
	if held < window.y:
		return STRIKE_PERFECT
	return STRIKE_LATE


## The strike for a release after `held` ticks, at the current Rhythm.
func strike_for(held: int) -> CombatMove:
	var grade: StringName = grade_for(held)
	var share: float = OVERSTRAIN_SHARE
	if grade == STRIKE_EARLY:
		share = lerpf(EARLY_MIN, EARLY_MAX, float(held) / sweet_spot_ticks().x)
	elif grade == STRIKE_PERFECT:
		share = 1.0 + RHYTHM_DAMAGE_BONUS * rhythm
	var names: Dictionary = {STRIKE_EARLY: "Strike (early)", STRIKE_PERFECT: "Perfect strike",
		STRIKE_LATE: "Overstrain"}
	var m: CombatMove = CombatMove.make(grade, names[grade], Vector3i(100, 100, 450),
		STRIKE_DAMAGE * share, STRIKE_POISE * minf(share, 1.0), 10.0, 30.0, 100.0, 0.0)
	m.hitstop_ms = CombatTuning.HITSTOP_HEAVY_MS
	if grade == STRIKE_PERFECT:
		m.hitstop_ms = CombatTuning.HITSTOP_BIG_MS
		m.breaks_armour = true
		m.shockwave_radius = SHOCKWAVE_RADIUS + SHOCKWAVE_RADIUS_PER_RHYTHM * rhythm
	return m


static func _jab() -> CombatMove:
	return CombatMove.make(&"hammer_jab", "Jab", Vector3i(150, 80, 200), 6.0, 12.0, 4.0, 24.0, 70.0, 5.0)


static func _ground_stamp() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"ground_stamp", "Ground stamp", Vector3i(100, 80, 300),
		4.0, 0.0, 12.0, 12.0, 360.0, 12.0)
	m.stagger_ms = 400  # a short, certain stagger
	return m
