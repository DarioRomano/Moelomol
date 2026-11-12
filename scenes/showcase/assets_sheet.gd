extends Node2D
## For review renders: the art files drawn by the engine itself, on the game's
## 640 x 360 canvas, with the pixel font. Shows that the files import crisp
## (nearest filter), sit on one pixel grid at every window size, and read
## together. Not a game screen: the game is not wired to these files yet.

const A: String = "res://assets/"

var font: FontFile = load(A + "ui/moelomol_font.fnt")
## Every texture drawn, kept here: a draw command holds only the texture's
## RID, so a texture loaded inside _draw() and dropped is freed, and the
## engine draws its white stand-in instead.
var _held: Dictionary = {}


func _tex(path: String) -> Texture2D:
	if not _held.has(path):
		_held[path] = load(A + path + ".png")
	return _held[path]


func _frame(path: String, frame: Vector2i, column: int, row: int, at: Vector2, flip: bool = false) -> void:
	var source: Rect2 = Rect2(Vector2(column * frame.x, row * frame.y), Vector2(frame))
	var size: Vector2 = Vector2(-frame.x if flip else frame.x, frame.y)
	draw_texture_rect_region(_tex(path), Rect2(at + (Vector2(frame.x, 0) if flip else Vector2.ZERO), size), source)


func _stand(path: String, feet: Vector2) -> void:
	var texture: Texture2D = _tex(path)
	draw_texture(texture, feet - Vector2(floorf(texture.get_width() / 2.0), texture.get_height()))


func _text(at: Vector2, text: String, colour: Color = Palette.PAPER[1]) -> void:
	draw_string(font, at + Vector2(0, 7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, colour)


func _draw() -> void:
	for y: int in range(23):
		for x: int in range(40):
			var mood: String = "tiles/grass_farm" if x < 20 else "tiles/grass_changed"
			_frame(mood, Vector2i(16, 16), (x * 7 + y * 3) % 4, 0, Vector2(x * 16, y * 16))
	for x: int in range(40):
		_frame("tiles/path", Vector2i(16, 16), x % 4, 0, Vector2(x * 16, 208))
		_frame("tiles/cobbles" if x >= 20 else "tiles/soil_dry", Vector2i(16, 16), x % 2, 0, Vector2(x * 16, 224))
		_frame("tiles/water", Vector2i(16, 16), x % 4, 0, Vector2(x * 16, 320))
	for i: int in range(8):
		_frame("props/farm/crop_catmint" if i < 4 else "props/farm/crop_radish", Vector2i(16, 16), i % 4, 0, Vector2(32 + i * 16, 224))
	_stand("buildings/farmhouse_lit", Vector2(80, 200))
	_stand("buildings/workshop", Vector2(200, 200))
	_stand("nature/apple_tree", Vector2(270, 204))
	_stand("buildings/church_lit", Vector2(450, 200))
	_stand("buildings/tower", Vector2(560, 200))
	_stand("props/kettlebridge/stall_eggs", Vector2(400, 250))
	_stand("props/kettlebridge/stall_seeds", Vector2(450, 250))
	_stand("props/kettlebridge/barge", Vector2(500, 352))
	for i: int in range(3):
		_frame("props/kettlebridge/gravestones", Vector2i(14, 20), i * 2 + 1, 0, Vector2(590 + i * 16, 180))
	# The player: each weapon's first attack frame, facing south, then east.
	var sets: Array[String] = ["base", "greatsword", "hammer", "bow", "lantern"]
	for i: int in range(sets.size()):
		_frame("player/player_" + sets[i], Vector2i(48, 48), 0, 0, Vector2(20 + i * 44, 250))
		_frame("player/player_" + sets[i], Vector2i(48, 48), 1, 8 if i > 0 else 5, Vector2(20 + i * 44, 284))
	_frame("creatures/cat", Vector2i(16, 12), 0, 0, Vector2(240, 290))
	_frame("creatures/cat", Vector2i(16, 12), 4, 0, Vector2(262, 290))
	_frame("creatures/grist", Vector2i(52, 36), 2, 0, Vector2(330, 268))
	_frame("creatures/duke", Vector2i(56, 40), 0, 0, Vector2(560, 268))
	_frame("creatures/market_rat", Vector2i(20, 11), 0, 0, Vector2(410, 262))
	_frame("creatures/market_rat", Vector2i(20, 11), 4, 0, Vector2(436, 268), true)
	_frame("creatures/lichen_back", Vector2i(22, 28), 4, 0, Vector2(520, 250))
	_frame("effects/slash", Vector2i(64, 64), 1, 0, Vector2(52, 236))
	# The interface, top left as in play.
	draw_texture(_tex("ui/bar_frame"), Vector2(8, 8))
	draw_texture_rect_region(_tex("ui/bar_health"), Rect2(9, 9, 46, 4), Rect2(0, 0, 46, 4))
	draw_texture(_tex("ui/bar_frame"), Vector2(8, 16))
	draw_texture(_tex("ui/bar_stamina"), Vector2(9, 17))
	_text(Vector2(8, 26), "Assets, drawn by the engine   day 3   07:40")
	draw_texture(_tex("ui/title"), Vector2(250, 6))
	draw_texture(_tex("ui/key_f"), Vector2(8, 40))
	draw_texture(_tex("ui/pad_b"), Vector2(22, 40))
	_text(Vector2(38, 42), "Read the note", Palette.WARMTH[3])
	var icons: Array[String] = ["greatsword", "hammer", "bow", "lantern", "catmint", "radish", "cat_treat", "winch_key", "note", "satchel"]
	for i: int in range(icons.size()):
		draw_texture(_tex("icons/" + icons[i]), Vector2(8 + i * 18, 58))
