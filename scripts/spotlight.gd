extends Control
## The tutorial's spotlight (camp_tutorial.gd), made on 7 Nov 2026 at the author's
## request: "give like a highlighter, like a black layer over the game". A dark layer
## over the game with a soft round hole where it points, and a line of chalk writing
## (Patrick Hand, chalked as on the title) saying what's there, with a smaller line under
## it saying which key carries on. It runs on real time, so it fades in and out the same
## while the tutorial has the game slowed down behind it.
## The hole follows what it points at: a node or a point in the world (through the
## camera), or a point on the screen. With nothing to point at, the whole screen darkens.
## It sits under the TO DO list and its scraps (main.gd's UI layer), so they show on it.

const TitleMenu := preload("res://scripts/title_menu.gd")

## How dark the layer gets, how long it takes to come and go (real seconds), and how soft
## the hole's edge is (pixels at 720 high).
const DARK := 0.74
const FADE := 0.35
const SOFT := 70.0
const TINT := Color("05081a")
## The writing: its size and its key line's (pixels at 720 high), and the widest it
## runs (a share of the screen).
const LINE_SIZE := 36
const PROMPT_SIZE := 26
const LINE_WIDTH := 0.62

const SHADER := """
shader_type canvas_item;
uniform vec2 size = vec2(1280.0, 720.0);
uniform vec2 hole = vec2(640.0, 360.0);
uniform float radius = 0.0;
uniform float soft = 70.0;
uniform float dark = 0.0;
uniform vec4 tint : source_color = vec4(0.02, 0.03, 0.1, 1.0);
void fragment() {
	float d = distance(UV * size, hole);
	float a = radius > 0.0 ? smoothstep(radius, radius + soft, d) : 1.0;
	COLOR = vec4(tint.rgb, dark * a);
}
"""

## Set before it's added: the camera, to find a point in the world on the screen.
var camera: Camera3D

var _layer: ColorRect
var _material: ShaderMaterial
var _line: Label
var _prompt: Label
## What it points at: a Node3D, a Vector3 in the world, a Vector2 on the screen (in
## pixels at 720 high, from the top left), or null for none; how high above a node, and
## the hole's radius (pixels at 720 high).
var _target = null
var _lift := 0.0
var _radius := 0.0
var _dark := DARK
var _on := false
var _fade := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = Shader.new()
	_material.shader.code = SHADER
	_material.set_shader_parameter("tint", TINT)
	_layer = ColorRect.new()
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.material = _material
	add_child(_layer)
	_line = _label(LINE_SIZE)
	_prompt = _label(PROMPT_SIZE)
	visible = false


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", TitleMenu.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TitleMenu.CHALK)
	label.add_theme_color_override("font_outline_color", Color(TINT, 0.9))
	label.add_theme_constant_override("outline_size", 10)
	label.material = TitleMenu.chalk()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label


## Darkens the game round `target` (see _target), lit `radius` pixels round (at 720
## high; 0 for no hole), with `line` written on it and `prompt` under it; `dark` is how
## dark (0 for just the writing).
func point(target, radius: float, line: String, prompt := "", lift := 0.0, dark := DARK) -> void:
	_target = target
	_radius = radius
	_lift = lift
	_dark = dark
	_line.text = line
	_prompt.text = prompt
	_on = true


## Fades away.
func clear() -> void:
	_on = false


## True from point() until clear(), whether or not it's faded all the way in or out.
func showing() -> bool:
	return _on


## How far it's faded in (0..1), on real time.
func faded_in() -> float:
	return _fade


## What it says now ("" once it's cleared).
func line() -> String:
	return _line.text if _on else ""


func _process(delta: float) -> void:
	# Real time: the frame's time without the game's slowing (under --fixed-fps, a
	# frame's worth, so the checks come out the same on any machine).
	var real := minf(delta / Engine.time_scale if Engine.time_scale > 0.0 else delta, 0.1)
	_fade = move_toward(_fade, 1.0 if _on else 0.0, real / FADE)
	visible = _fade > 0.0
	if not visible:
		return
	var view := get_viewport_rect().size
	var px := view.y / 720.0
	_layer.size = view
	_material.set_shader_parameter("size", view)
	_material.set_shader_parameter("dark", _dark * _fade * _fade * (3.0 - 2.0 * _fade))
	_material.set_shader_parameter("soft", SOFT * px)
	var hole = _screen_point(view)
	_material.set_shader_parameter("radius", _radius * px if hole != null else 0.0)
	if hole != null:
		_material.set_shader_parameter("hole", hole)
	# The writing goes in the half of the screen away from the hole.
	var width := view.x * LINE_WIDTH
	var top := view.y * 0.16 if hole != null and hole.y > view.y * 0.5 else view.y * 0.62
	for label: Label in [_line, _prompt]:
		label.modulate.a = _fade
		label.custom_minimum_size = Vector2(width, 0)
		label.size = Vector2(width, 0)
		label.add_theme_font_size_override("font_size", roundi((LINE_SIZE if label == _line else PROMPT_SIZE) * px))
	_line.position = Vector2((view.x - width) * 0.5, top)
	_prompt.position = Vector2((view.x - width) * 0.5, top + _line.get_combined_minimum_size().y + 8.0 * px)


## Where the hole goes on the screen, or null for none. A point in the world that's off
## the screen is lit at the screen's edge, the way it lies (his home, from the camp).
func _screen_point(view: Vector2):
	if _target is Vector2:
		return _target * (view.y / 720.0)
	var at = null
	if _target is Node3D and is_instance_valid(_target):
		at = (_target as Node3D).global_position + Vector3.UP * _lift
	elif _target is Vector3:
		at = _target
	if at == null or camera == null or camera.is_position_behind(at):
		return null
	var inset := view.y * 0.1
	var p := camera.unproject_position(at)
	return Vector2(clampf(p.x, inset, view.x - inset), clampf(p.y, inset, view.y - inset))
