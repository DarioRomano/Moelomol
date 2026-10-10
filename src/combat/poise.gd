class_name Poise
extends RefCounted
## Poise: a hidden bar worn down by poise damage. At zero the owner is
## staggered (docs/design/combat.md, "Poise and stagger"); the bar then refills
## completely. With hyper-armour the bar cannot drop below 1, so the owner
## keeps going.

var maximum: float
var current: float
var _regen_wait: int = 0


func _init(max_value: float) -> void:
	maximum = max_value
	current = max_value


## Applies poise damage. Returns true if this broke poise (a stagger).
func damage(amount: float, hyper_armour: bool) -> bool:
	if amount <= 0.0:
		return false
	_regen_wait = CombatTuning.ticks(CombatTuning.POISE_REGEN_DELAY_MS)
	current -= amount
	if hyper_armour:
		current = maxf(current, 1.0)
		return false
	if current <= 0.0:
		current = maximum
		return true
	return false


## `scale` slows the refill (Rot).
func tick(scale: float = 1.0) -> void:
	if _regen_wait > 0:
		_regen_wait -= 1
		return
	current = minf(maximum, current + CombatTuning.per_tick(CombatTuning.POISE_REGEN_PER_S) * scale)


func ratio() -> float:
	return current / maximum
