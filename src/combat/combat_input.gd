class_name CombatInput
extends RefCounted
## The player's input for one simulation tick. "pressed" means newly pressed
## this tick; "held" means held down. The arena fills this from the InputMap
## actions (ADR-0013); tests fill it directly.

var move: Vector2 = Vector2.ZERO
var light_pressed: bool = false
var heavy_pressed: bool = false
var skill_pressed: bool = false
var dodge_pressed: bool = false
var lock_held: bool = false
var target_next_pressed: bool = false
var target_prev_pressed: bool = false


static func with_move(direction: Vector2) -> CombatInput:
	var input: CombatInput = CombatInput.new()
	input.move = direction
	return input


static func press(action: StringName) -> CombatInput:
	var input: CombatInput = CombatInput.new()
	match action:
		&"light": input.light_pressed = true
		&"heavy": input.heavy_pressed = true
		&"skill": input.skill_pressed = true
		&"dodge": input.dodge_pressed = true
		_: push_error("CombatInput.press: unknown action %s" % action)
	return input
