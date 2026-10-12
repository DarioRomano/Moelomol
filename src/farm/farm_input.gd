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


## This tick's input from the InputMap actions (ADR-0013).
static func read() -> FarmInput:
	var input: FarmInput = FarmInput.new()
	input.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	input.use_pressed = Input.is_action_just_pressed(&"farm_use_tool")
	input.interact_pressed = Input.is_action_just_pressed(&"farm_interact")
	input.tool_next_pressed = Input.is_action_just_pressed(&"farm_tool_next")
	input.tool_prev_pressed = Input.is_action_just_pressed(&"farm_tool_prev")
	return input
