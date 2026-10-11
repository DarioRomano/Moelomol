class_name NoteView
extends Control
## The paper a note is written on (art-direction.md: notes look like paper
## the character found, not like game windows), centred on screen. Shows one
## note; `thread` draws the satchel's loose-thread mark (Q37). Lives in a
## UiFrame, so it follows the UI width setting.

const PAPER_SIZE: Vector2 = Vector2(300, 170)

var title: String = ""
var text: String = ""
var thread: bool = false

var _title_label: Label
var _text_label: Label
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label = _label(7, Palette.STONE[0])
	_text_label = _label(8, Palette.SHADOW[1])
	_hint = _label(6, Palette.STONE[1])
	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF  # one short line (it wrapped a letter per line in the render)
	_hint.text = "F / B: put it back"
	visible = false


func _label(size: int, colour: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label


## Shows a note.
func open(p_title: String, p_text: String, p_thread: bool) -> void:
	title = p_title
	text = p_text
	thread = p_thread
	_title_label.text = title
	_text_label.text = text
	visible = true
	_layout()
	queue_redraw()


func close() -> void:
	visible = false


func _layout() -> void:
	var paper: Rect2 = paper_rect()
	_title_label.position = paper.position + Vector2(14, 10)
	_title_label.size = Vector2(paper.size.x - 28, 12)
	_text_label.position = paper.position + Vector2(14, 28)
	_text_label.size = Vector2(paper.size.x - 28, paper.size.y - 50)
	_hint.position = paper.position + Vector2(14, paper.size.y - 16)


func paper_rect() -> Rect2:
	return Rect2((size - PAPER_SIZE) / 2.0, PAPER_SIZE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _title_label != null:
		_layout()


func _draw() -> void:
	var paper: Rect2 = paper_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.SHADOW[0], 0.5))
	draw_rect(paper.grow(1), Palette.STONE[1])
	draw_rect(paper, Palette.PAPER[1])
	draw_line(paper.position + Vector2(10, 24), Vector2(paper.end.x - 10, paper.position.y + 24), Color(Palette.STONE[2], 0.5), 1.0)
	if thread:
		# The loose thread: a red thread tied through the corner (Q37).
		var corner: Vector2 = paper.position + Vector2(paper.size.x - 18, 8)
		draw_line(corner, corner + Vector2(10, 14), Palette.DANGER[1], 1.0)
		draw_line(corner + Vector2(10, 14), corner + Vector2(4, 22), Palette.DANGER[1], 1.0)
		draw_circle(corner, 1.5, Palette.DANGER[0])
