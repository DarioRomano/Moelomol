class_name PauseMenu
extends CanvasLayer
## The pause menu (Esc / Start): Resume, Back to title, Quit. While it is
## open the whole game stands still (SceneTree.paused): the clock, the
## creatures, the fight (farming.md: the clock pauses in menus). It says when
## the game was last saved, and asks before leaving, since progress since
## then is lost (ADR-0017: no saving from a menu).
##
## Each place's scene adds one. Keyboard, mouse and controller (ADR-0013):
## Esc / Start or B close it.

## Emitted when the player leaves for the title (tests set `travels` false).
signal to_title
signal quitting

const TITLE_SCENE: String = "res://scenes/title/title.tscn"

## False while the scene is leaving (the fade between places).
var enabled: bool = true
var travels: bool = true

var _panel: Control
var _menu: VBoxContainer
var _confirm: VBoxContainer
var _saved_line: Label
var _confirm_line: Label
var _resume: Button
var _confirm_no: Button
var _leaving_to: StringName = &""  # &"title" or &"quit", while asking


func _ready() -> void:
	layer = 80  # over the HUD; the fade (90) and developer overlay above
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	add_child(_panel)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(Palette.SHADOW[0], 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(dim)
	var frame: UiFrame = UiFrame.new()
	_panel.add_child(frame)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 2)
	frame.add_child(column)
	column.add_child(MenuStyle.label("Paused", 16, Palette.WARMTH[3]))
	_saved_line = MenuStyle.label("", 7, Palette.PAPER[0])
	column.add_child(_saved_line)
	column.add_child(MenuStyle.spacer(8))
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 1)
	column.add_child(_menu)
	_resume = MenuStyle.button("Resume", close)
	_menu.add_child(_resume)
	_menu.add_child(MenuStyle.button("Back to title", func() -> void: _ask(&"title")))
	var quit: Button = MenuStyle.button("Quit", func() -> void: _ask(&"quit"))
	quit.visible = not OS.has_feature("web")  # a web page cannot quit
	_menu.add_child(quit)
	_confirm = VBoxContainer.new()
	_confirm.add_theme_constant_override("separation", 1)
	_confirm.visible = false
	column.add_child(_confirm)
	_confirm_line = MenuStyle.label("", 8, Palette.PAPER[1])
	_confirm.add_child(_confirm_line)
	_confirm.add_child(MenuStyle.spacer(4))
	_confirm.add_child(MenuStyle.button("Leave", _leave))
	_confirm_no = MenuStyle.button("Keep playing", _back)
	_confirm.add_child(_confirm_no)


func is_open() -> bool:
	return _panel.visible


func open() -> void:
	if is_open() or not enabled:
		return
	_panel.visible = true
	_menu.visible = true
	_confirm.visible = false
	var state: GameState = GameState.current
	if state == null or state.save_path.is_empty():
		_saved_line.text = "This game is not saved (opened on its own)."
	elif state.last_saved.is_empty():
		_saved_line.text = "Not saved yet."
	else:
		_saved_line.text = "Last saved: %s." % state.last_saved
	get_tree().paused = true
	_resume.grab_focus()


func close() -> void:
	if not is_open():
		return
	_panel.visible = false
	get_tree().paused = false
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()


func _ask(to: StringName) -> void:
	_leaving_to = to
	_confirm_line.text = ("Back to the title?" if to == &"title" else "Quit the game?") \
		+ " Anything since the last save is lost."
	_menu.visible = false
	_confirm.visible = true
	_confirm_no.grab_focus()  # the safe answer first


func _back() -> void:
	_confirm.visible = false
	_menu.visible = true
	_resume.grab_focus()


func _leave() -> void:
	get_tree().paused = false
	if _leaving_to == &"quit":
		quitting.emit()
		if travels:
			get_tree().quit()
		return
	enabled = false
	_panel.visible = false
	GameState.current = null  # the title starts or continues a game afresh
	to_title.emit()
	if travels:
		Fade.to_scene(get_tree(), TITLE_SCENE, Palette.SHADOW[0])


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		if enabled and event.is_action_pressed(&"pause", false):
			open()
			get_viewport().set_input_as_handled()
		return
	if MenuStyle.move_focus_with_keys(event, get_viewport()):
		pass
	elif event.is_action_pressed(&"pause", false) or event.is_action_pressed(&"ui_cancel", false):
		if _confirm.visible:
			_back()
		else:
			close()
	get_viewport().set_input_as_handled()  # nothing reaches the game while paused
