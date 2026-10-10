class_name Zone
extends RefCounted
## An area on the ground that hits every creature inside it in waves: the
## bow's Volley rain (later magic's pools). After `delay` ticks, a wave every
## `period` ticks, `waves` times; then it is gone.

var kind: StringName
var owner: Fighter
var move: CombatMove  # what each wave does to each creature inside
var position: Vector2
var radius: float
var delay: int
var period: int
var waves: int
var age: int = 0  # ticks since it was placed


static func make(p_kind: StringName, p_owner: Fighter, p_move: CombatMove, at: Vector2, p_radius: float,
		delay_ticks: int, period_ticks: int, wave_count: int) -> Zone:
	var z: Zone = Zone.new()
	z.kind = p_kind
	z.owner = p_owner
	z.move = p_move
	z.position = at
	z.radius = p_radius
	z.delay = delay_ticks
	z.period = period_ticks
	z.waves = wave_count
	return z


## True on the ticks a wave lands.
func wave_now() -> bool:
	var since: int = age - delay
	return since >= 0 and since % period == 0 and since / period < waves


func is_finished() -> bool:
	return age > delay + period * (waves - 1)
