class_name NoteReader
extends Control
## Reading notes at the farm and in the farmhouse: the note view and the
## satchel (Q37; one satchel for the whole game), with the same buttons as
## in Millbrook. F / B puts a note back or reads the chosen one; I / View
## opens and closes the satchel; up and down choose. While either is open
## the place stands still (farming.md: the clock pauses while reading).
##
## The scene passes its input events to handle() first.

var state: GameState
var _note: NoteView
var _satchel: SatchelView
## Set when a note or the satchel closes; the scene's next physics tick
## takes it (just_closed) and ignores Interact, so the press that closed it
## does not interact again.
var _just_closed: bool = false


func _init(p_state: GameState) -> void:
	state = p_state


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_satchel = SatchelView.new()
	add_child(_satchel)
	_note = NoteView.new()
	add_child(_note)


func is_open() -> bool:
	return _note.visible or _satchel.visible


## A note found here: into the satchel, and open to read.
func found(note_id: StringName) -> void:
	if not (note_id in state.satchel):
		state.satchel.append(note_id)
	show_note(note_id)


func show_note(note_id: StringName) -> void:
	var note: Dictionary = Notes.find(note_id)
	if note.is_empty():
		return
	_note.open(note["title"], note["text"], Notes.loose_thread(note_id, state))


## Handles reading's buttons; true if the event was used.
func handle(event: InputEvent) -> bool:
	if event.is_action_pressed(&"satchel", false):
		if _note.visible:
			_note.close()
		if _satchel.visible:
			_close_satchel()
		else:
			_satchel.open(state)
		return true
	if not is_open():
		return false
	if event.is_action_pressed(&"interact", false):
		if _note.visible:
			_note.close()
			if not _satchel.visible:
				_just_closed = true
		else:
			var chosen: StringName = _satchel.chosen()
			if chosen != &"":
				show_note(chosen)
		return true
	if _satchel.visible and not _note.visible:
		if event.is_action_pressed(&"move_up", false):
			_satchel.move_selection(-1)
			return true
		if event.is_action_pressed(&"move_down", false):
			_satchel.move_selection(1)
			return true
	return false


func _close_satchel() -> void:
	_satchel.close()
	_just_closed = true


## True once after a note or the satchel closed (see `_just_closed`).
func just_closed() -> bool:
	var was: bool = _just_closed
	_just_closed = false
	return was
