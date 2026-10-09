extends Node
## Global window shortcuts (autoload "WindowControls").
##
## Q6d (lead, 2026-10-09): leave and re-enter fullscreen with the shortcuts
## players expect: Alt+Enter on Windows and Linux (action
## "toggle_fullscreen"), Ctrl+Cmd+F on macOS ("toggle_fullscreen_macos").
## Each platform only answers its own shortcut. An options-menu setting comes
## with the first menu.
##
## Uses _input (not _unhandled_input) so the shortcut works even when a menu
## has focus, and marks the event handled.

const ACTION_DEFAULT: StringName = &"toggle_fullscreen"
const ACTION_MACOS: StringName = &"toggle_fullscreen_macos"

## Replaced in tests; in the game this changes the real window.
var set_window_mode: Callable = func(mode: DisplayServer.WindowMode) -> void:
	DisplayServer.window_set_mode(mode)
var get_window_mode: Callable = func() -> DisplayServer.WindowMode:
	return DisplayServer.window_get_mode()
var os_name: String = OS.get_name()


## Fullscreen (either kind) goes to windowed; anything else goes to fullscreen.
static func toggled_mode(current: DisplayServer.WindowMode) -> DisplayServer.WindowMode:
	if current == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or current == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return DisplayServer.WINDOW_MODE_WINDOWED
	return DisplayServer.WINDOW_MODE_FULLSCREEN


## True if the event is this platform's fullscreen shortcut, newly pressed.
static func is_toggle_event(event: InputEvent, platform: String) -> bool:
	var action: StringName = ACTION_MACOS if platform == "macOS" else ACTION_DEFAULT
	return event.is_action_pressed(action, false)


func _input(event: InputEvent) -> void:
	if is_toggle_event(event, os_name):
		set_window_mode.call(toggled_mode(get_window_mode.call()))
		get_viewport().set_input_as_handled()
