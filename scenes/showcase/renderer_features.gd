extends Node2D
## Renderer feature check (debug scene, not game content). ADR-0013 chose the
## Compatibility renderer everywhere (Q5); this scene uses each 2D feature the
## game is likely to need, so the visual review renders show at a glance
## whether one stops working. Each panel is labelled; a broken feature shows as
## a panel that looks like its "expected" note does not describe it.
##
## Panels (left to right, top to bottom):
##   1. Point light with a hard shadow from an occluder, under CanvasModulate
##      darkness: a lit cone with a dark shadow wedge behind the block.
##   2. GPU particles: warm specks rising.
##   3. CPU particles: cool specks falling.
##   4. CanvasItem shader: a block whose colours are swapped by a shader
##      (should be violet/teal, not the source orange).
##   5. Screen-reading shader: a strip that inverts what is behind it.
##   6. Additive blend: two overlapping lights brighter where they overlap.

const PANEL: Vector2i = Vector2i(200, 150)
const GAP: int = 10

const SWAP_SHADER: String = """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	// Orange in, violet/teal out: proves custom canvas shaders run.
	COLOR = vec4(c.b + 0.35, c.g * 0.6, c.r * 0.9, c.a);
}
"""

const INVERT_SHADER: String = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
void fragment() {
	vec3 behind = texture(screen_tex, SCREEN_UV).rgb;
	COLOR = vec4(vec3(1.0) - behind, 1.0);
}
"""

const ADD_SHADER: String = """
shader_type canvas_item;
render_mode blend_add;
"""


func _ready() -> void:
	var modulate_node: CanvasModulate = CanvasModulate.new()
	modulate_node.color = Color(0.35, 0.35, 0.45)
	add_child(modulate_node)
	_panel_light(_origin(0))
	_panel_gpu_particles(_origin(1))
	_panel_cpu_particles(_origin(2))
	_panel_swap_shader(_origin(3))
	_panel_screen_shader(_origin(4))
	_panel_additive(_origin(5))


func _origin(index: int) -> Vector2:
	var column: int = index % 3
	var row: int = index / 3
	return Vector2(GAP + column * (PANEL.x + GAP), GAP + row * (PANEL.y + GAP + 10))


func _label(origin: Vector2, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = origin + Vector2(2, PANEL.y - 2)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Palette.PAPER[1])
	# Labels must stay readable under CanvasModulate darkness: own layer.
	var layer: CanvasLayer = CanvasLayer.new()
	layer.add_child(label)
	add_child(layer)


func _backdrop(origin: Vector2, colour: Color) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.position = origin
	rect.size = PANEL
	rect.color = colour
	add_child(rect)


func _block(origin: Vector2, size: Vector2, colour: Color) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.position = origin
	rect.size = size
	rect.color = colour
	add_child(rect)
	return rect


func _light_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture


func _panel_light(origin: Vector2) -> void:
	_backdrop(origin, Palette.WILD[2])
	var light: PointLight2D = PointLight2D.new()
	light.texture = _light_texture()
	light.position = origin + Vector2(40, PANEL.y / 2.0)
	light.color = Palette.WARMTH[3]
	light.energy = 1.6
	light.shadow_enabled = true
	add_child(light)
	var occluder: LightOccluder2D = LightOccluder2D.new()
	var polygon: OccluderPolygon2D = OccluderPolygon2D.new()
	var block_origin: Vector2 = origin + Vector2(90, PANEL.y / 2.0 - 15)
	polygon.polygon = PackedVector2Array([
		block_origin, block_origin + Vector2(20, 0),
		block_origin + Vector2(20, 30), block_origin + Vector2(0, 30)])
	occluder.occluder = polygon
	add_child(occluder)
	_block(block_origin, Vector2(20, 30), Palette.STONE[1])
	_label(origin, "1 light+shadow: lit cone, dark wedge")


func _panel_gpu_particles(origin: Vector2) -> void:
	_backdrop(origin, Palette.SHADOW[1])
	var particles: GPUParticles2D = GPUParticles2D.new()
	particles.position = origin + Vector2(PANEL.x / 2.0, PANEL.y - 20)
	particles.amount = 60
	particles.lifetime = 2.0
	particles.preprocess = 2.0
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 25.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 3.0
	material.color = Palette.WARMTH[2]
	particles.process_material = material
	particles.light_mask = 0
	add_child(particles)
	_label(origin, "2 GPU particles: warm specks rising")


func _panel_cpu_particles(origin: Vector2) -> void:
	_backdrop(origin, Palette.SHADOW[1])
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.position = origin + Vector2(PANEL.x / 2.0, 10)
	particles.amount = 60
	particles.lifetime = 2.0
	particles.preprocess = 2.0
	particles.direction = Vector2(0, 1)
	particles.spread = 25.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.0
	particles.color = Palette.WATER[1]
	add_child(particles)
	_label(origin, "3 CPU particles: cool specks falling")


func _panel_swap_shader(origin: Vector2) -> void:
	_backdrop(origin, Palette.SHADOW[1])
	var block: ColorRect = _block(origin + Vector2(50, 30), Vector2(100, 80), Palette.WARMTH[1])
	var shader: Shader = Shader.new()
	shader.code = SWAP_SHADER
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	block.material = material
	_label(origin, "4 shader: violet/teal, not orange")


func _panel_screen_shader(origin: Vector2) -> void:
	_backdrop(origin, Palette.SHADOW[1])
	for i: int in range(5):
		_block(origin + Vector2(10 + i * 38, 20), Vector2(30, 100), Palette.all_colours()[8 + i * 3])
	# The default copy mode copies only a 200x200 rect around the node's own
	# position (here 0,0), which left this strip reading stale pixels in the
	# first render. Copy the whole view.
	var copy: BackBufferCopy = BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	var strip: ColorRect = _block(origin + Vector2(0, 55), Vector2(PANEL.x, 30), Color.WHITE)
	var shader: Shader = Shader.new()
	shader.code = INVERT_SHADER
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	strip.material = material
	_label(origin, "5 screen shader: strip inverts bars")


func _panel_additive(origin: Vector2) -> void:
	_backdrop(origin, Palette.SHADOW[0])
	var shader: Shader = Shader.new()
	shader.code = ADD_SHADER
	for offset: Vector2 in [Vector2(45, 30), Vector2(95, 50)]:
		var block: ColorRect = _block(origin + offset, Vector2(70, 70), Palette.WATER[0])
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = shader
		block.material = material
	_label(origin, "6 additive: overlap brighter")
