extends TestCase
## The art files in assets/ as the engine sees them (their rules are tested
## in tools/ci/test_assets.py): every image imports at its manifest size, and
## the pixel font is a bitmap font on the art-pixel grid.

const MANIFEST: String = "res://assets/art_manifest.json"


func _manifest() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	return parsed if parsed is Dictionary else {}


func test_every_image_in_the_manifest_imports_at_its_size() -> void:
	var manifest: Dictionary = _manifest()
	assert_true(manifest.size() > 250, "the manifest lists the art (%d files)" % manifest.size())
	for path: String in manifest:
		var texture: Texture2D = load("res://" + path)
		assert_true(texture != null, "%s loads" % path)
		if texture == null:
			continue
		var size: Array = manifest[path]["size"]
		assert_eq(Vector2i(texture.get_size()), Vector2i(int(size[0]), int(size[1])), "%s keeps its size" % path)


func test_the_pixel_font_is_ten_pixels_tall_and_not_smoothed() -> void:
	var font: FontFile = load("res://assets/ui/moelomol_font.fnt")
	assert_true(font != null, "the font imports")
	assert_eq(font.fixed_size, 10, "a bitmap font at one size")
	assert_eq(font.get_height(10), 10.0, "line height on the art-pixel grid")
	assert_eq(font.get_ascent(10), 7.0, "capitals seven pixels tall")
	assert_eq(font.antialiasing, TextServer.FONT_ANTIALIASING_NONE, "hard pixels")
	assert_eq(font.get_string_size("Moelomol", HORIZONTAL_ALIGNMENT_LEFT, -1, 10), Vector2(39, 10), "letters as drawn, one pixel apart")
	for code: int in range(32, 127):
		assert_true(font.has_char(code), "has '%s'" % String.chr(code))


func test_the_player_s_sheets_carry_the_frames_the_manifest_names() -> void:
	var manifest: Dictionary = _manifest()
	for weapon: String in ["base", "greatsword", "hammer", "bow", "lantern"]:
		var entry: Dictionary = manifest["assets/player/player_%s.png" % weapon]
		var texture: Texture2D = load("res://assets/player/player_%s.png" % weapon)
		var rows: int = int(texture.get_height()) / 48
		assert_eq((entry["anims"] as Dictionary).size(), rows, "%s: one row per animation and facing" % weapon)
