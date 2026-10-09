extends TestCase
## Guards the display decisions of ADR-0008 (Q1) and the pixel-art render
## settings. Changing any of these needs the project lead's approval.


func test_base_resolution_is_640_by_360() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 640, "viewport width")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 360, "viewport height")


func test_stretch_mode_renders_at_base_resolution() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport", "stretch mode")


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


func test_default_font_is_not_antialiased() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/default_font_antialiasing"), 0, "font antialiasing")
	assert_eq(ProjectSettings.get_setting("gui/theme/default_font_subpixel_positioning"), 0,
		"font subpixel positioning")
