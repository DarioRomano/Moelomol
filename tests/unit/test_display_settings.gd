extends TestCase
## Guards the display decisions of ADR-0008 (Q1) and the pixel-art render
## settings. Changing any of these needs the project lead's approval.


func test_base_resolution_is_640_by_360() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 640, "viewport width")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 360, "viewport height")


func test_scene_renders_at_full_resolution() -> void:
	# Lead, 2026-10-09 (ADR-0008 Amendment 3): drawn at the screen's resolution
	# for readable text and smooth movement; 640x360 stays the layout size.
	# "viewport" would render at 640x360 and scale the picture up.
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "stretch mode")


func test_scaling_is_whole_numbers_only() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer", "stretch scale mode")


func test_wider_screens_show_more_world() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand", "stretch aspect")


func test_game_starts_fullscreen() -> void:
	# Q12, lead 2026-10-09. 3 = Fullscreen (borderless), 4 = Exclusive Fullscreen.
	assert_eq(ProjectSettings.get_setting("display/window/size/mode"), 3, "window mode")


func test_textures_use_nearest_filtering() -> void:
	# 0 = Nearest. The engine default is 1 (Linear), which blurs pixel art.
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0,
		"default canvas texture filter")


func test_fonts_use_readable_defaults() -> void:
	# Full-resolution text reads best with the engine's default font rendering
	# (antialiased, light hinting, subpixel positioning); the low-resolution
	# settings (all off) gave uneven letter spacing. Compared 2026-10-09.
	assert_eq(ProjectSettings.get_setting("gui/theme/default_font_antialiasing"), 1, "font antialiasing (grayscale)")
	assert_eq(ProjectSettings.get_setting("gui/theme/default_font_hinting"), 1, "font hinting (light)")
	assert_eq(ProjectSettings.get_setting("gui/theme/default_font_subpixel_positioning"), 1,
		"font subpixel positioning (auto)")
