extends Control
## The title and the menu, written in chalk over the night sky as in the author's picture
## (design/reference/title-screen.webp): "The Noise Next Door" in Patrick Hand, and under
## it Continue, New Game, Settings and Quit, with a chalk paw print beside the line that's
## picked. Up and Down (or W and S, or the mouse) move it; Enter, Space, E or a click
## choose. Settings opens a page of its own in the same place: the music and effects
## volumes (Left and Right change them), full screen, and Back (or Esc). Laid out at
## 1280 × 720 and scaled to fit the window.

signal chosen(item: String)

const GameSettings := preload("res://scripts/game_settings.gd")
const FONT := preload("res://assets/fonts/PatrickHand-Regular.ttf")
const DESIGN := Vector2(1280, 720)
## Measured in the picture and scaled to 1280 × 720: the font sizes, the tops of the
## capitals of the title and of the first line of the menu, and the menu's line spacing.
const TITLE_SIZE := 93
const TITLE_CAP := 45.0
const ITEM_SIZE := 41
const ITEM_CAP := 142.5
const ITEM_GAP := 42.6
## How tall Patrick Hand's capitals are, as a share of the font size.
const CAP_HEIGHT := 0.66
const CHALK := Color("eaedf5")
const ITEMS := ["Continue", "New Game", "Settings", "Quit"]
const SETTINGS_ITEMS := ["Music", "Effects", "Full screen", "Back"]
## Continue waits for save states (GDD §3), which aren't built yet. Until there's a game
## to continue, it's written this faint and passed over.
const FAINT := 0.38
## The paw print beside the picked line: its gap from the text and its size, as in the
## picture. It pops up as the thought icons do (thought_bubble.gd), then rocks a little
## in steps, like a drawing animated by hand.
const PAW_GAP := 15.0
const PAW_SIZE := 26.0
const PAW_POP := [0.55, 1.22, 0.9, 1.05, 1.0]
const PAW_ROCK := [0.0, 3.0, 5.0, 3.0, 0.0, -3.0, -5.0, -3.0]
const STEPS := 12.0
const ROCK_STEPS := 4.0
## The volume ticks on the Settings page: how many, their size and gap, and how faint
## the ones above the volume are.
const TICK := Vector2(4.0, 20.0)
const TICK_GAP := 11.0
const TICK_FAINT := 0.25

var can_continue := false
## Set while the screen fades out, so nothing can be chosen twice.
var locked := false
var _page := ITEMS
var _pick := 1
var _since := 0.0


func _ready() -> void:
	size = DESIGN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = chalk()
	get_viewport().size_changed.connect(_fit)
	_fit()


## A material that makes writing look like chalk (chalk.gdshader), for the title and for
## the level's prompt to wake him (main.gd).
static func chalk() -> ShaderMaterial:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.16
	var grain := NoiseTexture2D.new()
	grain.width = 128
	grain.height = 128
	grain.seamless = true
	grain.noise = noise
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/chalk.gdshader")
	mat.set_shader_parameter("grain", grain)
	return mat


## Opens the Settings page (for the screenshot test).
func open_settings() -> void:
	_page = SETTINGS_ITEMS
	_set_pick(0)


func _fit() -> void:
	var view := get_viewport_rect().size
	var s := minf(view.x / DESIGN.x, view.y / DESIGN.y)
	scale = Vector2(s, s)
	position = (view - DESIGN * s) * 0.5


func _process(delta: float) -> void:
	_since += delta
	queue_redraw()


func _draw() -> void:
	_text("The Noise Next Door", TITLE_SIZE, TITLE_CAP, CHALK)
	for i in _page.size():
		var color := CHALK
		if not _available(i):
			color.a = FAINT
		var line: String = _page[i]
		var cap := ITEM_CAP + i * ITEM_GAP
		var right := 0.0
		if _page == SETTINGS_ITEMS and i < 2:
			right = _volume_line(line, GameSettings.music if i == 0 else GameSettings.effects, cap)
		else:
			if line == "Full screen":
				line += ":  on" if GameSettings.fullscreen else ":  off"
			right = _text(line, ITEM_SIZE, cap, color)
		if i == _pick:
			_paw(Vector2(right + PAW_GAP + PAW_SIZE * 0.5, cap + ITEM_SIZE * CAP_HEIGHT * 0.5))


## Writes `line` centred across the screen with the tops of its capitals at `cap`, and
## returns where it ends on the right.
func _text(line: String, font_size: int, cap: float, color: Color) -> float:
	var width := FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var left := (DESIGN.x - width) * 0.5
	draw_string(FONT, Vector2(left, cap + font_size * CAP_HEIGHT), line, HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size, color)
	return left + width


## A volume line: its name and a row of chalk ticks, as many bright as the volume, the
## two together centred. Returns where it ends on the right.
func _volume_line(line: String, volume: int, cap: float) -> float:
	var steps := GameSettings.STEPS
	var name_width := FONT.get_string_size(line + "   ", HORIZONTAL_ALIGNMENT_LEFT, -1, ITEM_SIZE).x
	var ticks := steps * TICK_GAP
	var left := (DESIGN.x - name_width - ticks) * 0.5
	draw_string(FONT, Vector2(left, cap + ITEM_SIZE * CAP_HEIGHT), line, HORIZONTAL_ALIGNMENT_LEFT, -1,
		ITEM_SIZE, CHALK)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(line)
	for k in steps:
		var color := CHALK
		if k >= volume:
			color.a = TICK_FAINT
		var x := left + name_width + k * TICK_GAP + TICK_GAP * 0.5
		var bottom := cap + ITEM_SIZE * CAP_HEIGHT
		var lean := rng.randf_range(-1.5, 1.5)
		draw_line(Vector2(x - lean, bottom), Vector2(x + lean, bottom - TICK.y), color, TICK.x, true)
	return left + name_width + ticks


## The paw print, centred on `at`: a pad and four toes in an arc above it.
func _paw(at: Vector2) -> void:
	var step := int(_since * STEPS)
	var grow: float = PAW_POP[step] if step < PAW_POP.size() else 1.0
	var rock: float = PAW_ROCK[int(_since * ROCK_STEPS) % PAW_ROCK.size()]
	paw(self, at, PAW_SIZE * grow, deg_to_rad(rock + 12.0), CHALK)


## Draws a paw print on `item`, `size` across, centred on `at` and turned `angle`: a pad
## and four toes in an arc above it. The plan's paws are the same (plan_note.gd).
static func paw(item: CanvasItem, at: Vector2, size: float, angle: float, color: Color) -> void:
	item.draw_set_transform(at, angle, Vector2.ONE * size)
	item.draw_colored_polygon(_oval(Vector2(0, 0.2), Vector2(0.3, 0.24), 0.25), color)
	for toe: Vector3 in [Vector3(-0.36, -0.08, -0.5), Vector3(-0.14, -0.34, -0.15), Vector3(0.14, -0.34, 0.15),
			Vector3(0.36, -0.08, 0.5)]:
		var turned := _oval(Vector2.ZERO, Vector2(0.095, 0.13), 0.0)
		item.draw_colored_polygon(Transform2D(toe.z, Vector2(toe.x, toe.y)) * turned, color)
	item.draw_set_transform(Vector2.ZERO)


## An oval round `c`, flattened a little along its bottom by `flat`, like a paw's pad.
static func _oval(c: Vector2, r: Vector2, flat: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		var p := Vector2(cos(a) * r.x, sin(a) * r.y)
		if p.y > 0.0:
			p.y *= 1.0 - flat
		pts.append(c + p)
	return pts


func _available(i: int) -> bool:
	return can_continue or _page != ITEMS or ITEMS[i] != "Continue"


func _set_pick(i: int) -> void:
	if i != _pick:
		_since = 0.0
	_pick = i


func _move(by: int) -> void:
	var i := _pick
	for k in _page.size():
		i = posmod(i + by, _page.size())
		if _available(i):
			break
	_set_pick(i)


func _choose() -> void:
	if not _available(_pick):
		return
	var item: String = _page[_pick]
	match item:
		"Continue":
			chosen.emit("continue")
		"New Game":
			chosen.emit("new_game")
		"Settings":
			_page = SETTINGS_ITEMS
			_set_pick(0)
		"Quit":
			chosen.emit("quit")
		"Full screen":
			_adjust(1)
		"Back":
			_back()


func _back() -> void:
	_page = ITEMS
	_set_pick(2)


## Left or Right on the Settings page: a volume one step down or up, or full screen on or off.
func _adjust(by: int) -> void:
	if _page != SETTINGS_ITEMS:
		return
	match _pick:
		0:
			GameSettings.music = clampi(GameSettings.music + by, 0, GameSettings.STEPS)
		1:
			GameSettings.effects = clampi(GameSettings.effects + by, 0, GameSettings.STEPS)
		2:
			GameSettings.fullscreen = not GameSettings.fullscreen
		_:
			return
	GameSettings.apply()
	GameSettings.save_settings()


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_UP, KEY_W:
				_move(-1)
			KEY_DOWN, KEY_S:
				_move(1)
			KEY_LEFT, KEY_A:
				_adjust(-1)
			KEY_RIGHT, KEY_D:
				_adjust(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
				if not event.echo:
					_choose()
			KEY_ESCAPE:
				if _page == SETTINGS_ITEMS and not event.echo:
					_back()
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		var line := _line_at(get_global_transform_with_canvas().affine_inverse() * event.position)
		if line == -1 or not _available(line):
			return
		_set_pick(line)
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_choose()


## The menu line under `p` (in the 1280 × 720 layout), or -1.
func _line_at(p: Vector2) -> int:
	if absf(p.x - DESIGN.x * 0.5) > 220.0:
		return -1
	var i := floori((p.y - ITEM_CAP + ITEM_GAP * 0.3) / ITEM_GAP)
	return i if i >= 0 and i < _page.size() else -1
