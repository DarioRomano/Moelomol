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


## How fast the player walks while charging with this weapon.
func charge_move_speed() -> float:
	return CombatTuning.CHARGE_MOVE_SPEED


## `action` was pressed during a dodge. Return true to take it (the bow's
## dodge shot); otherwise it waits in the input buffer as usual.
func dodge_action(_sim: CombatSim, _action: StringName) -> bool:
	return false


## The player's dodge just ended.
func on_dodge_end(_sim: CombatSim) -> void:
	pass


## The player was hit. Every weapon in the loadout hears it, not only the
## one in hand (getting hit costs Rhythm and Flow either way).
func on_owner_hit(_sim: CombatSim) -> void:
	pass


## A hit by the player (with this weapon in hand) landed.
func on_hit_landed(_sim: CombatSim, _target: Fighter, _move: CombatMove) -> void:
	pass


## One of the player's projectiles stopped (hit, wall, or out of range).
func on_projectile_stopped(_sim: CombatSim, _projectile: Projectile) -> void:
	pass


## Every simulation tick, for every weapon in the loadout (timers).
func tick(_sim: CombatSim) -> void:
	pass


## A short status line for the arena HUD.
func status_text(_p: Fighter) -> String:
	return ""
