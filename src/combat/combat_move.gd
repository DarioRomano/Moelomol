class_name CombatMove
extends RefCounted
## One attack: its timing (windup, active, recovery), what it does on hit, and
## what it costs. Hits are tested against a circular sector in front of the
## attacker: within reach and within arc_deg of the facing direction.

var id: StringName
var display_name: String
var windup_ms: int
var active_ms: int
var recovery_ms: int
var damage: float
var poise_damage: float
var push: float  # layout px the target is shoved
var reach: float  # layout px from the attacker's edge
var arc_deg: float  # 360 = all around
var stamina: float
var hyper_armour: bool = false  # cannot be staggered during windup and active
var dash: float = 0.0  # layout px the attacker moves forward during active
var hitstop_ms: int = CombatTuning.HITSTOP_LIGHT_MS
var staggered_damage_multiplier: float = CombatTuning.STAGGERED_DAMAGE_MULTIPLIER
var extend_stagger_ms: int = 0  # added to a staggered target's stagger
var stagger_ms: int = 0  # > 0: every hit staggers for this long, whatever the poise
var breaks_armour: bool = false  # shatters armour before the damage lands
var shockwave_radius: float = 0.0  # > 0: staggers everything this close when it lands
var shockwave_arc_deg: float = 360.0  # < 360: a cone the way the attacker faces
var melee: bool = true  # false: the move itself hits nothing (shots, gestures)
var arrow: CombatMove = null  # fired as a projectile when the active part starts
var pierce: bool = false  # as an arrow: flies on through every creature
var marker: bool = false  # as an arrow: the Volley marker
var projectile_speed: float = 0.0  # as an arrow: px/s; 0 = CombatTuning.ARROW_SPEED
var effect: StringName = &""  # a status effect each hit applies (StatusEffects)
var effect_stacks: int = 0
var releases_effects: bool = false  # consumes every stack on the target into a burst
var spell: bool = false  # a hit during the windup interrupts it
var move_speed: float = 0.0  # > 0: the player can walk this fast (px/s) during the move


static func make(p_id: StringName, p_name: String, timing: Vector3i, p_damage: float,
		p_poise: float, p_push: float, p_reach: float, p_arc: float, p_stamina: float) -> CombatMove:
	var move: CombatMove = CombatMove.new()
	move.id = p_id
	move.display_name = p_name
	move.windup_ms = timing.x
	move.active_ms = timing.y
	move.recovery_ms = timing.z
	move.damage = p_damage
	move.poise_damage = p_poise
	move.push = p_push
	move.reach = p_reach
	move.arc_deg = p_arc
	move.stamina = p_stamina
	return move


func windup_ticks() -> int:
	return CombatTuning.ticks(windup_ms)


func active_ticks() -> int:
	return CombatTuning.ticks(active_ms)


func recovery_ticks() -> int:
	return CombatTuning.ticks(recovery_ms)
