class_name Bow
extends Weapon
## The bow (docs/design/combat.md, "Bow: movement and flow").
##
## Light: a quick shot. Heavy: hold to draw through three stages (lead,
## 2026-10-10): stage 1 an ordinary arrow, stage 2 slightly stronger, stage 3
## pierces and pushes a little back. Release at any time; releasing within a
## moment of reaching a stage is a clean release with a bonus. Holding at
## stage 3 costs stamina. Heavy during a dodge looses a stage-3 arrow as the
## roll ends (dodge shot). Arrow hits build Flow (max 5, each stack draws 8%
## faster); getting hit loses it all. Skill: Volley, an arrow loosed at once;
## arrows rain where it hits the first creature (or where it stops), wider
## for every Flow stack spent. Arrows are unlimited.
##
## Starting values; tuning needs the lead's approval.

## Held time to reach stages 1, 2 and 3, at no Flow.
const STAGE_MS: Array[int] = [300, 700, 1200]
const CLEAN_RELEASE_MS: int = 80
const CLEAN_RELEASE_BONUS: float = 0.25  # extra damage share
const MAX_FLOW: int = 5
const FLOW_DRAW_SPEEDUP: float = 0.08  # draw time saved per Flow stack
const DRAW_STAMINA: float = 8.0  # paid when the draw starts (and for a dodge shot)
const STAGE_3_DRAIN_PER_S: float = 15.0
const DRAW_MOVE_SPEED: float = 48.0  # layout px/s while drawing (60%)
const DODGE_SHOT_STAGE: int = 3  # the piercing arrow, as before the rework

const VOLLEY_STAMINA: float = 15.0
const VOLLEY_RADIUS: float = 20.0
const VOLLEY_RADIUS_PER_FLOW: float = 6.0
const VOLLEY_DELAY_MS: int = 400
const VOLLEY_PERIOD_MS: int = 300
const VOLLEY_WAVES: int = 3

## Arrow ids by stage (0 = released before stage 1: the quick-shot arrow).
const ARROW_IDS: Array[StringName] = [&"arrow_quick", &"arrow_normal", &"arrow_strong", &"arrow_piercing"]

static var QUICK_SHOT: CombatMove = _shot(&"quick_shot", "Quick shot", 80, 4.0, arrow(0, false))
static var VOLLEY_SHOT: CombatMove = _shot(&"volley_shot", "Volley", 120, VOLLEY_STAMINA, _marker_arrow())
static var RAIN: CombatMove = _rain()

var flow: int = 0
var dodge_shot_queued: bool = false


func _init() -> void:
	id = &"bow"
	display_name = "Bow"


func try_action(sim: CombatSim, action: StringName, _input: CombatInput) -> bool:
	var p: Fighter = sim.player
	match action:
		&"light":
			return sim.start_attack(p, QUICK_SHOT)
		&"heavy":
			if not p.stamina.try_spend(DRAW_STAMINA):
				sim.events.append({"type": "no_stamina"})
				return false
			p.move = null
			p.enter(Fighter.State.CHARGE)
			sim.events.append({"type": "draw_start", "fighter": p})
			return true
		&"skill":
			return sim.start_attack(p, VOLLEY_SHOT)
	return false


func charge_move_speed() -> float:
	return DRAW_MOVE_SPEED


## The string's tension: a little more at each stage, a strain at stage 3.
func charge_rumble(p: Fighter) -> Vector2:
	var stage: int = stage_for(p.state_tick)
	return Vector2(0.04 + 0.07 * stage, 0.12 if stage == 3 else 0.0)


func step_charge(sim: CombatSim, input: CombatInput) -> void:
	var p: Fighter = sim.player
	var held: int = p.state_tick
	var stages: Array[int] = stage_ticks()
	var reached: int = stages.find(held)
	if reached >= 0:
		sim.events.append({"type": "draw_stage", "fighter": p, "stage": reached + 1})
	if not input.heavy_held:
		release(sim, held)
		return
	if held >= stages[2]:
		var drain: float = CombatTuning.per_tick(STAGE_3_DRAIN_PER_S)
		if p.stamina.current < drain:
			release(sim, held)  # cannot hold any longer
			return
		p.stamina.current -= drain


## Looses the drawn arrow after `held` ticks of drawing.
func release(sim: CombatSim, held: int) -> void:
	var stage: int = stage_for(held)
	var clean: bool = is_clean(held)
	sim.events.append({"type": "shot", "fighter": sim.player, "stage": stage, "clean": clean})
	sim.start_attack(sim.player, release_move(stage, clean))


func dodge_action(_sim: CombatSim, action: StringName) -> bool:
	if action == &"heavy":
		dodge_shot_queued = true
		return true
	return false


func on_dodge_end(sim: CombatSim) -> void:
	if not dodge_shot_queued:
		return
	dodge_shot_queued = false
	var p: Fighter = sim.player
	if not p.stamina.try_spend(DRAW_STAMINA):
		sim.events.append({"type": "no_stamina"})
		return
	var shot: CombatMove = release_move(DODGE_SHOT_STAGE, false)
	shot.id = &"dodge_shot"
	shot.display_name = "Dodge shot"
	sim.events.append({"type": "shot", "fighter": p, "stage": DODGE_SHOT_STAGE, "clean": false})
	sim.start_attack(p, shot)


func on_owner_hit(_sim: CombatSim) -> void:
	flow = 0
	dodge_shot_queued = false


func on_hit_landed(_sim: CombatSim, _target: Fighter, move: CombatMove) -> void:
	if move.id in ARROW_IDS:
		flow = mini(flow + 1, MAX_FLOW)


## The Volley arrow stopped (in the first creature it hit, a wall, or at
## the end of its range): the rain starts there.
func on_projectile_stopped(sim: CombatSim, projectile: Projectile) -> void:
	if projectile.marker:
		_rain_at(sim, projectile.position)


func status_text(p: Fighter) -> String:
	var text: String = "flow %d" % flow
	if p.state == Fighter.State.CHARGE:
		text += "   stage %d" % stage_for(p.state_tick)
	return text


## Held ticks at which stages 1, 2 and 3 are reached, at the current Flow.
func stage_ticks() -> Array[int]:
	var scale: float = 1.0 - FLOW_DRAW_SPEEDUP * flow
	var result: Array[int] = []
	for ms: int in STAGE_MS:
		result.append(CombatTuning.ticks(roundi(ms * scale)))
	return result


## The stage reached after `held` ticks (0 = not even stage 1).
func stage_for(held: int) -> int:
	var stage: int = 0
	for threshold: int in stage_ticks():
		if held >= threshold:
			stage += 1
	return stage


## True when `held` is within the clean-release moment after a stage.
func is_clean(held: int) -> bool:
	var stage: int = stage_for(held)
	if stage == 0:
		return false
	return held - stage_ticks()[stage - 1] < CombatTuning.ticks(CLEAN_RELEASE_MS)


## The shot that looses a stage's arrow: no windup, a short recovery.
static func release_move(stage: int, clean: bool) -> CombatMove:
	var names: Array[String] = ["Loose (undrawn)", "Arrow", "Strong arrow", "Piercing arrow"]
	return _shot(StringName("loose_%d" % stage), names[stage], 0, 0.0, arrow(stage, clean))


## The arrow for a stage (0 = the quick shot's arrow).
static func arrow(stage: int, clean: bool) -> CombatMove:
	# [damage, poise, push]: stage 1 is an ordinary arrow (the quick shot's),
	# stage 2 slightly stronger, stage 3 pierces and pushes a little back.
	var values: Array[Vector3] = [Vector3(5, 8, 2), Vector3(5, 8, 2), Vector3(8, 14, 3), Vector3(12, 20, 12)]
	var v: Vector3 = values[stage]
	var bonus: float = 1.0 + (CLEAN_RELEASE_BONUS if clean else 0.0)
	var m: CombatMove = CombatMove.make(ARROW_IDS[stage], "Arrow", Vector3i.ZERO, v.x * bonus, v.y, v.z, 0.0, 0.0, 0.0)
	m.pierce = stage == 3
	var hitstops: Array[int] = [0, 0, CombatTuning.HITSTOP_LIGHT_MS, CombatTuning.HITSTOP_LIGHT_MS]
	m.hitstop_ms = hitstops[stage]
	return m


## Starts the rain at `at`, sized by the Flow spent.
func _rain_at(sim: CombatSim, at: Vector2) -> void:
	var radius: float = VOLLEY_RADIUS + VOLLEY_RADIUS_PER_FLOW * flow
	sim.zones.append(Zone.make(&"volley", sim.player, RAIN, at, radius, CombatTuning.ticks(VOLLEY_DELAY_MS),
		CombatTuning.ticks(VOLLEY_PERIOD_MS), VOLLEY_WAVES))
	sim.events.append({"type": "volley", "position": at, "radius": radius, "flow_spent": flow})
	flow = 0


static func _shot(p_id: StringName, p_name: String, windup_ms: int, stamina: float, payload: CombatMove) -> CombatMove:
	var m: CombatMove = CombatMove.make(p_id, p_name, Vector3i(windup_ms, 17, 200), 0.0, 0.0, 0.0, 0.0, 0.0, stamina)
	m.melee = false
	m.arrow = payload
	return m


static func _marker_arrow() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"arrow_marker", "Volley arrow", Vector3i.ZERO, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	m.marker = true
	m.hitstop_ms = 0
	return m


## One wave of the rain, for each creature inside: it pins (poise) more than
## it hurts.
static func _rain() -> CombatMove:
	var m: CombatMove = CombatMove.make(&"volley_rain", "Volley rain", Vector3i.ZERO, 6.0, 20.0, 0.0, 0.0, 0.0, 0.0)
	m.hitstop_ms = 0
	return m
