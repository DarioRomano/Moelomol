class_name FarmInput
extends RefCounted
## The player's input at the base for one simulation tick ("pressed" =
## newly pressed this tick). The farm scene fills it from the InputMap
## actions (ADR-0013); tests fill it directly.

var move: Vector2 = Vector2.ZERO
var use_pressed: bool = false
var interact_pressed: bool = false
var tool_next_pressed: bool = false
var tool_prev_pressed: bool = false


static func with_move(direction: Vector2) -> FarmInput:
	var input: FarmInput = FarmInput.new()
	input.move = direction
	return input


static func press(action: StringName) -> FarmInput:
	var input: FarmInput = FarmInput.new()
	match action:
		&"use": input.use_pressed = true
		&"interact": input.interact_pressed = true
		&"tool_next": input.tool_next_pressed = true
		&"tool_prev": input.tool_prev_pressed = true
		_: push_error("FarmInput.press: unknown action %s" % action)
	return input
