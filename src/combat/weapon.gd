class_name Weapon
extends RefCounted
## One of the player's weapons (docs/design/combat.md). The simulation handles
## what every weapon shares (dodge, swap, charging movement, hits, poise); a
## weapon decides what the light, heavy and skill buttons do, and keeps its own
## state (the hammer's Rhythm, later the bow's Flow).

var id: StringName
var display_name: String


## Starts the player's light, heavy or skill action if possible; returns true
## if something started. `action` is &"light", &"heavy" or &"skill".
func try_action(_sim: CombatSim, _action: StringName, _input: CombatInput) -> bool:
	return false


## Called every tick while the player is in Fighter.State.CHARGE with this
## weapon, before the charge's tick count advances. Releasing is up to the
## weapon.
func step_charge(_sim: CombatSim, _input: CombatInput) -> void:
	pass


## The player was hit while holding this weapon.
func on_owner_hit(_sim: CombatSim) -> void:
	pass


## A short status line for the arena HUD.
func status_text(_p: Fighter) -> String:
	return ""
