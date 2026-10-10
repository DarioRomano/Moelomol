class_name Mana
extends RefCounted
## The player's Mana (docs/design/farming.md, "Mana"; Q27, decided by the
## lead 2026-10-10): spent by every farming spell and, later, by enhanced
## weapon skills; refilled fully by sleep and partly by food. There is no
## passive refill.
##
## Starting values; tuning needs the lead's approval.

const STARTING_MAXIMUM: float = 100.0

var maximum: float
var current: float


func _init(max_value: float = STARTING_MAXIMUM) -> void:
	maximum = max_value
	current = max_value


## Spends cost if there is enough; returns false (and spends nothing) if not.
func try_spend(cost: float) -> bool:
	if cost > current:
		return false
	current -= cost
	return true


## Sleep: back to full.
func refill() -> void:
	current = maximum


## Food (later): some back, never above the maximum.
func restore(amount: float) -> void:
	current = minf(maximum, current + maxf(amount, 0.0))


func ratio() -> float:
	return current / maximum
