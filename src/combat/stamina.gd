class_name Stamina
extends RefCounted
## Stamina: spent by dodges and attacks, refills after a short delay.

var maximum: float
var current: float
var _regen_wait: int = 0


func _init(max_value: float = CombatTuning.STAMINA_MAX) -> void:
	maximum = max_value
	current = max_value


## Spends cost if there is enough; returns false (and spends nothing) if not.
func try_spend(cost: float) -> bool:
	if cost > current:
		return false
	current -= cost
	_regen_wait = CombatTuning.ticks(CombatTuning.STAMINA_REGEN_DELAY_MS)
	return true


## Stops refilling for the regen delay (used while stamina is being drained).
func hold() -> void:
	_regen_wait = CombatTuning.ticks(CombatTuning.STAMINA_REGEN_DELAY_MS)


func tick() -> void:
	if _regen_wait > 0:
		_regen_wait -= 1
		return
	current = minf(maximum, current + CombatTuning.per_tick(CombatTuning.STAMINA_REGEN_PER_S))
