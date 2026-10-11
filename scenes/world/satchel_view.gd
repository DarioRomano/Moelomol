class_name SatchelView
extends Control
## The satchel (Q37): every note found, newest first, to re-read. Up and down
## choose, F / B reads, I / View closes. Notes about an unfinished objective
## carry the loose-thread mark. Lives in a UiFrame.

const PANEL_SIZE: Vector2 = Vector2(260, 190)
const ROW: float = 13.0

var entries: Array[StringName] = []
var titles: Dictionary = {}  # note id -> title
var threads: Dictionary = {}  # note id -> bool
var selected: int = 0

var _labels: Array[Label] = []
var _heading: Label
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heading = _label(8, Palette.PAPER[1])
	_heading.text = "Satchel"
	_hint = _label(6, Palette.STONE[2])
	_hint.text = "Up / down: choose   F / B: read   I / View: close"
	visible = false


func _label(size: int, colour: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	add_child(label)
	return label


## Opens on `area`'s notes, newest first.
func open(area: Area) -> void:
	entries = area.satchel_newest_first()
	titles.clear()
	threads.clear()
	for note_id: StringName in entries:
		titles[note_id] = (area.notes[note_id] as Dictionary)["title"]
		threads[note_id] = area.has_loose_thread(note_id)
	selected = 0
	visible = true
	_refresh()


func close() -> void:
	visible = false


func move_selection(step_by: int) -> void:
	if entries.is_empty():
		return
	selected = posmod(selected + step_by, entries.size())
	_refresh()


## The chosen note, or &"" when the satchel is empty.
func chosen() -> StringName:
	return entries[selected] if not entries.is_empty() else &""


func panel_rect() -> Rect2:
	return Rect2((size - PANEL_SIZE) / 2.0, PANEL_SIZE)


func _refresh() -> void:
	for label: Label in _labels:
		label.queue_free()
	_labels.clear()
	var panel: Rect2 = panel_rect()
	_heading.position = panel.position + Vector2(12, 8)
	_hint.position = panel.position + Vector2(12, panel.size.y - 16)
	if entries.is_empty():
		var empty: Label = _label(7, Palette.STONE[2])
		empty.text = "Nothing yet."
		empty.position = panel.position + Vector2(20, 30)
		_labels.append(empty)
	for i: int in range(mini(entries.size(), 11)):
		var label: Label = _label(7, Palette.PAPER[1] if i == selected else Palette.STONE[2])
		label.text = titles[entries[i]]
		label.position = panel.position + Vector2(24, 26 + i * ROW)
		_labels.append(label)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _heading != null and visible:
		_refresh()


func _draw() -> void:
	var panel: Rect2 = panel_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.SHADOW[0], 0.5))
	draw_rect(panel.grow(1), Palette.CHANGED[0])  # worn leather
	draw_rect(panel, Palette.SHADOW[1])
	for i: int in range(mini(entries.size(), 11)):
		var row_y: float = panel.position.y + 26 + i * ROW
		if i == selected:
			draw_rect(Rect2(panel.position.x + 8, row_y - 1, panel.size.x - 16, ROW), Color(Palette.PAPER[1], 0.12))
		# A scrap of paper for each note; a red thread on the unfinished ones.
		draw_rect(Rect2(panel.position.x + 12, row_y + 2, 7, 8), Palette.PAPER[0])
		if threads[entries[i]]:
			draw_line(Vector2(panel.position.x + 18, row_y + 2), Vector2(panel.position.x + 21, row_y + 9), Palette.DANGER[1], 1.0)
