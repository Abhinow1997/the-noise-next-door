extends Control
## THE PLAN: level 1's to-do list (camp_tasks.gd) as a page torn out of a spiral notebook,
## in faceted brown paper with the tasks chalked on it, made on 24 Oct 2026 from the
## author's picture (design/reference/the-plan.webp) at the author's request: "i want a
## similar UI for tasks listing in the game and as we proceed ahead and pass and get it
## done the tasks get crossed off ... using tab the panel comes up and goes away".
##   - Tab (main.gd) brings the page up over the game, which darkens behind it to the
##     picture's night blue and carries on; Tab again puts it away.
##   - A task that's done is crossed off in chalk and its box stamped with a paw and a
##     tick. One done while the page was away is crossed off as the page comes up.
##   - Along the bottom of the screen, on scraps of the same paper: a task just done comes
##     up crossed off, then goes ("let it come up in the bottom to suggest it was
##     completed"); and the key task, the one to follow now (at the start, the music),
##     stays there until it's done ("let it linger down at the bottom").
##   - Since 26 Oct 2026 the page shows only the tasks revealed so far (camp_tasks.gd
##     `shown`), with a main task's sub-tasks indented under it; and the tutorial at the
##     camp (camp_tutorial.gd) puts its notes on a scrap at the bottom, which stays up
##     while the page is.
## The page is laid out in the picture's own pixels (1024 × 572), turned straight, and
## scaled to fit the window.

const CampTasks := preload("res://scripts/camp_tasks.gd")
const TitleMenu := preload("res://scripts/title_menu.gd")
const FONT := preload("res://assets/fonts/PatrickHand-Regular.ttf")
const PICTURE := Vector2(1024, 572)
## How far the page is turned in the picture (degrees; it leans left).
const TURN := -2.5

## Measured on the picture with the page turned straight. Its edges: along the torn top,
## down the right side and back along the bottom to the spiral's side, where the holes
## (HOLE_*) were torn open between its tabs.
const TOP_EDGE := [Vector2(165, 48), Vector2(200, 46), Vector2(275, 40), Vector2(375, 49), Vector2(500, 44),
	Vector2(575, 49), Vector2(650, 53), Vector2(725, 47), Vector2(854, 48)]
const RIGHT_EDGE := [Vector2(855, 100), Vector2(852, 180), Vector2(864, 285), Vector2(863, 390), Vector2(868, 522)]
const BOTTOM_EDGE := [Vector2(775, 528), Vector2(675, 516), Vector2(600, 524), Vector2(500, 527), Vector2(375, 519),
	Vector2(300, 525), Vector2(148, 527)]
## The holes: the first one's middle, the gap between them, how many, how tall and how
## far into the page; and the ones with a bit of torn tab folded over them.
const HOLE_FIRST := 93.0
const HOLE_GAP := 38.6
const HOLES := 11
const HOLE_HEIGHT := 14.0
const HOLE_DEPTH := 187.0
const FOLDED := [2, 7]
## The paper's facets: about how big, and the darkest and lightest of their browns (the
## picture's paper runs between these); and the folded bits, lighter.
const FACET := 100.0
const PAPER_DARK := Color("7a5b44")
const PAPER_LIGHT := Color("97735a")
const FOLD := Color("9c7c5e")
const LIGHT := Vector3(-0.45, -0.6, 0.66)
## The ruled lines (the first one's height, the gap, how many, where they start and end)
## and the margin, printed on the paper in dark brown.
const RULE_Y := 194.0
const RULE_GAP := 56.8
const RULES := 6
const RULE_X := Vector2(198, 842)
const MARGIN := [Vector2(249, 62), Vector2(242, 516)]
const INK := Color("5f4431")
## The chalk, as warm as the picture's.
const CHALK := Color("f6ece1")
## "THE PLAN": its size, the top of its capitals, its middle across, the gap added
## between its letters, and the chalk line under it. The picture's title is gone round
## in chalk, so it's drawn as its letters' outline, TITLE_RIM wide, over a faint fill.
const TITLE := "THE PLAN"
const TITLE_SIZE := 67
const TITLE_CAP := 75.0
const TITLE_X := 511.5
const TITLE_SPACING := 4
const TITLE_RIM := 2
const TITLE_FILL := 0.8
## The picture's writing is a little thinner than Patrick Hand: this much (its embolden).
const THIN := -0.35
const UNDERLINE := [Vector2(381, 134), Vector2(520, 131.5), Vector2(660, 129)]
## The tasks: their size, how far the writing sits right of the margin and above its
## line, and how much a crossed-off one fades.
const TASK_SIZE := 50
const INDENT := 17.0
## How much further in a sub-task starts than its main task.
const SUB_INDENT := 46.0
const ABOVE_RULE := 4.0
const DONE_FADE := 0.8
## Patrick Hand's capitals are this share of the font size tall (as on the title).
const CAP_HEIGHT := TitleMenu.CAP_HEIGHT
## The box at the end of each line (a square or a circle, by turns, as in the picture):
## across the page, how far its middle is above the line, and its size; the paw-and-tick
## stamp a done task gets in its place; and the chalk paw after the key task.
const BOX_X := 823.0
const BOX_RISE := 19.0
const SQUARE := 28.0
const CIRCLE := 30.0
const STAMP := 37.0
const PAW_GAP := 18.0
const PAW_SIZE := 48.0
## The raccoon's dirty paw prints on the paper (where, and how big), and a scuff.
const SMUDGES := [Vector3(757, 127, 26), Vector3(213, 392, 30), Vector3(212, 452, 32)]
const SMUDGE := Color(0.29, 0.19, 0.105, 0.3)
## The darkening behind the page: the picture's night blue, top to bottom.
const BACKDROP := [Color("141839"), Color("171a3b"), Color("363b60")]
const BACKDROP_ALPHA := 0.82

## Timings (seconds): the page coming up or going, a task being crossed off, and how long
## a done task's scrap stays at the bottom once crossed off.
const OPEN_TIME := 0.35
const STRIKE_TIME := 0.45
const STRIKE_WAIT := 0.3
const HOLD := 2.6
## Chalk line widths: the underline and crossings-off, and the boxes.
const STROKE := 3.5
const BOX_STROKE := 3.0
## The scraps at the bottom, in the picture's pixels: the writing's size, their height,
## the padding at their ends, the gap between two, and how far up the screen the lowest
## sits.
const SCRAP_SIZE := 30
const SCRAP_HEIGHT := 50.0
const SCRAP_PAD := 20.0
const SCRAP_GAP := 8.0
const SCRAP_BOTTOM := 30.0
const SCRAP_MOVE := 0.3

## Set before it's added.
var tasks: CampTasks
## True while the page is up (or coming up).
var open := false

var _clock := 0.0
## How far (0..1) the page is up.
var _up := 0.0
## When each task's crossing-off starts, by id, on _clock; tasks not yet crossed off on
## the page aren't in it.
var _struck := {}
var _page: Layer
var _page_chalk: Layer
var _scraps: Array[Scrap] = []
## Whether the key task has its scrap at the bottom now (from when he's up and about).
var _key_on := false
var _key_wait := 0.0
var _title_font: FontVariation
var _hand: FontVariation


## A Control that draws with a function of its owner's.
class Layer extends Control:
	var paint: Callable

	func _init(with: Callable) -> void:
		paint = with
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		paint.call(self)


## A scrap of the page at the bottom of the screen with one task on it: the key task to
## follow, or a task just done. Its paper and its chalk are drawn on two layers, the chalk
## through the chalk material.
class Scrap extends Layer:
	var task: Dictionary
	var key := false
	## A note from the tutorial rather than a task: no box, and up even while the page is.
	var note := false
	var born := 0.0
	## When it's crossed off, and when it goes, on the plan's clock (INF: not yet).
	var struck := INF
	var leaves := INF
	var width := 0.0
	var outline: PackedVector2Array
	var facets: Array
	var chalk: Layer
	## Where it's headed, and where it is (its bottom middle, in the picture's pixels up
	## from the lowest scrap's place).
	var slot := 0.0
	var at := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_font = FontVariation.new()
	_title_font.base_font = FONT
	_title_font.spacing_glyph = TITLE_SPACING
	_title_font.variation_embolden = THIN
	_hand = FontVariation.new()
	_hand.base_font = FONT
	_hand.variation_embolden = THIN
	_page = Layer.new(_paint_page.bind(facets(_outline(), 11, FACET)))
	_page.size = PICTURE
	_page.pivot_offset = PICTURE * 0.5
	_page.visible = false
	add_child(_page)
	_page_chalk = Layer.new(_paint_page_chalk)
	_page_chalk.size = PICTURE
	_page_chalk.material = TitleMenu.chalk()
	_page.add_child(_page_chalk)
	tasks.ticked.connect(_on_ticked)
	get_viewport().size_changed.connect(_fit)
	_fit()


## Tab: the page comes up, or goes away.
func toggle() -> void:
	open = not open
	if open:
		# Tasks done while it was away are crossed off now, one after another.
		var next := _clock + OPEN_TIME
		for task: Dictionary in tasks.list:
			if task.done and not _struck.has(task.id):
				_struck[task.id] = next
				next += STRIKE_TIME * 0.6


## From when he's up and about (main.gd): the key task comes up at the bottom, after
## `wait` seconds.
func show_key(wait := 0.0) -> void:
	_key_on = true
	_key_wait = wait


## Whether the key task's scrap is up at the bottom (for the tests).
func key_showing() -> String:
	for scrap in _scraps:
		if scrap.key and scrap.leaves == INF:
			return scrap.task.id
	return ""


## The tutorial's note (camp_tutorial.gd): `line` on a scrap at the bottom, in place of
## the one up before; "" takes it away.
func note(line: String) -> void:
	for scrap in _scraps:
		if scrap.note and scrap.leaves == INF:
			scrap.leaves = _clock
	if line != "":
		_add_scrap({"id": "note", "text": line}, false, true)


## The note up at the bottom now, or "" (for the tests).
func note_showing() -> String:
	for scrap in _scraps:
		if scrap.note and scrap.leaves == INF:
			return scrap.task.text
	return ""


## The scraps at the bottom, as the tests see them: each one's task, whether it's the key
## task's and whether it's crossed off.
func scraps() -> Array:
	return _scraps.map(func(s: Scrap) -> Array: return [s.task.id, s.key, s.struck <= _clock])


## How far the page is up (0..1).
func up() -> float:
	return _up


func _on_ticked(id: String) -> void:
	if open:
		_struck[id] = _clock
	for scrap in _scraps:
		if scrap.task.id == id and scrap.key:
			# The key task's own scrap is crossed off where it is, then goes.
			scrap.struck = _clock
			scrap.leaves = _clock + STRIKE_TIME + HOLD
			return
	for task: Dictionary in tasks.list:
		if task.id == id:
			var scrap := _add_scrap(task, false)
			scrap.struck = _clock + STRIKE_WAIT
			scrap.leaves = scrap.struck + STRIKE_TIME + HOLD


func _process(delta: float) -> void:
	_clock += delta
	_up = move_toward(_up, 1.0 if open else 0.0, delta / OPEN_TIME)
	_page.visible = _up > 0.0
	if _page.visible:
		_place_page()
		_page_chalk.queue_redraw()
	queue_redraw()

	if _key_on:
		_key_wait -= delta
		var key := tasks.key_task()
		if _key_wait <= 0.0 and not key.is_empty() and key_showing() == "" and not _scraps.any(
				func(s: Scrap) -> bool: return s.task.id == key.id):
			_add_scrap(key, true)
	# Gone ones go; the rest settle into their places, the tutorial's note lowest, then
	# the key task's.
	for scrap in _scraps.duplicate():
		if _clock > scrap.leaves + SCRAP_MOVE:
			_scraps.erase(scrap)
			scrap.queue_free()
	var order := _scraps.duplicate()
	order.sort_custom(func(a: Scrap, b: Scrap) -> bool:
		var ra := 0 if a.note else 1 if a.key else 2
		var rb := 0 if b.note else 1 if b.key else 2
		return ra < rb or ra == rb and a.born < b.born)
	var slot := 0.0
	for scrap: Scrap in order:
		scrap.slot = slot
		slot += SCRAP_HEIGHT + SCRAP_GAP
		scrap.at = lerpf(scrap.at, scrap.slot, 1.0 - exp(-12.0 * delta))
		_place_scrap(scrap)
		scrap.chalk.queue_redraw()


func _fit() -> void:
	if _page:
		_place_page()


## The scale from the picture's pixels to the window's.
func _scale() -> float:
	var view := get_viewport_rect().size
	return minf(view.x / PICTURE.x, view.y / PICTURE.y)


## The page in the middle of the window, as in the picture, rising into place from below
## as it comes up, and turning straight a little.
func _place_page() -> void:
	var view := get_viewport_rect().size
	var s := _scale()
	var e := _up * _up * (3.0 - 2.0 * _up)
	_page.scale = Vector2(s, s)
	# It's scaled and turned about its middle, which goes in the middle of the window.
	_page.position = view * 0.5 - _page.pivot_offset + Vector2(0.0, (1.0 - e) * view.y * 0.9)
	_page.rotation = deg_to_rad(TURN - (1.0 - e) * 6.0)


## The darkening behind the page.
func _draw() -> void:
	if _up <= 0.0:
		return
	var view := get_viewport_rect().size
	var colors := []
	for c: Color in BACKDROP:
		colors.append(Color(c, BACKDROP_ALPHA * _up))
	var mid := view.y * 0.35
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(view.x, 0), Vector2(view.x, mid), Vector2(0, mid)]),
		PackedColorArray([colors[0], colors[0], colors[1], colors[1]]))
	draw_polygon(PackedVector2Array([Vector2(0, mid), Vector2(view.x, mid), view, Vector2(0, view.y)]),
		PackedColorArray([colors[1], colors[1], colors[2], colors[2]]))


# --- The page ------------------------------------------------------------------

## The page's outline: the measured edges, and down the spiral's side its tabs with the
## holes between them.
func _outline() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p: Vector2 in TOP_EDGE + RIGHT_EDGE + BOTTOM_EDGE:
		pts.append(p)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in range(HOLES - 1, -1, -1):
		var y := HOLE_FIRST + k * HOLE_GAP
		var x := _tab_x(y)
		var h := HOLE_HEIGHT * 0.5
		pts.append(Vector2(x + rng.randf_range(-2.0, 2.0), y + h + 1.0))
		pts.append(Vector2(HOLE_DEPTH + rng.randf_range(-2.0, 2.0), y + h))
		pts.append(Vector2(HOLE_DEPTH + rng.randf_range(-2.0, 2.0), y - h))
		pts.append(Vector2(x + rng.randf_range(-2.0, 2.0), y - h - 1.0))
	return pts


## How far left the spiral's tabs reach at height `y`.
func _tab_x(y: float) -> float:
	var top: Vector2 = TOP_EDGE[0]
	var bottom: Vector2 = BOTTOM_EDGE[-1]
	return lerpf(bottom.x, top.x, inverse_lerp(bottom.y, top.y, y))


func _paint_page(item: CanvasItem, paper: Array) -> void:
	for facet: Array in paper:
		item.draw_colored_polygon(facet[0], facet[1])
	# The bits of torn tab bent down over a hole, catching the light.
	for k: int in FOLDED:
		var y := HOLE_FIRST + k * HOLE_GAP
		var x := _tab_x(y)
		item.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, y - 10), Vector2(x + 20, y - 8),
			Vector2(HOLE_DEPTH - 2, y + 3), Vector2(x + 1, y + 8)]), FOLD)
	for i in RULES:
		var y := RULE_Y + i * RULE_GAP
		item.draw_line(Vector2(RULE_X.x, y), Vector2(RULE_X.y, y - 1.0), INK, 2.2, true)
	item.draw_line(MARGIN[0], MARGIN[1], INK, 2.0, true)


## The chalk on the page: the dirty paws, the title, and each task on its line.
func _paint_page_chalk(item: CanvasItem) -> void:
	for print: Vector3 in SMUDGES:
		smudge(item, Vector2(print.x, print.y), print.z, 0.3 - print.x * 0.001)
	stroke(item, [Vector2(770, 492), Vector2(776, 486), Vector2(779, 489)], 2.0, SMUDGE)

	var title_width := _title_font.get_string_size(TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE).x
	var title_at := Vector2(TITLE_X - title_width * 0.5, TITLE_CAP + TITLE_SIZE * CAP_HEIGHT)
	item.draw_string(_title_font, title_at, TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, Color(CHALK, TITLE_FILL))
	item.draw_string_outline(_title_font, title_at, TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, TITLE_RIM, CHALK)
	stroke(item, UNDERLINE, STROKE, CHALK, 1.0, 3)

	var shown := tasks.shown()
	var gap := RULE_GAP * minf(1.0, float(RULES) / shown.size())
	for i in shown.size():
		var task: Dictionary = shown[i]
		var rule := RULE_Y + i * gap
		var left := lerpf(MARGIN[0].x, MARGIN[1].x, inverse_lerp(MARGIN[0].y, MARGIN[1].y, rule)) + INDENT
		if task.has("parent"):
			left += SUB_INDENT
		var struck: float = _struck.get(task.id, INF)
		var done := clampf((_clock - struck) / STRIKE_TIME, 0.0, 1.0)
		var right := write(item, task.text, Vector2(left, rule - ABOVE_RULE), TASK_SIZE,
			Color(CHALK, lerpf(1.0, DONE_FADE, done)))
		if task.get("key", false):
			TitleMenu.paw(item, Vector2(right + PAW_GAP + PAW_SIZE * 0.5, rule - TASK_SIZE * CAP_HEIGHT * 0.55),
				PAW_SIZE, deg_to_rad(12.0), CHALK)
		var box := Vector2(BOX_X, rule - BOX_RISE)
		if done > 0.0:
			cross_off(item, left, right, rule - ABOVE_RULE, TASK_SIZE, done, hash(task.id))
		if done >= 1.0:
			stamp(item, box, STAMP, _clock - struck - STRIKE_TIME)
		else:
			empty_box(item, box, i, hash(task.id))


# --- The scraps ------------------------------------------------------------------

func _add_scrap(task: Dictionary, key: bool, note := false) -> Scrap:
	var scrap := Scrap.new(_paint_scrap)
	scrap.task = task
	scrap.key = key
	scrap.note = note
	scrap.born = _clock
	var text := _hand.get_string_size(task.text, HORIZONTAL_ALIGNMENT_LEFT, -1, SCRAP_SIZE).x
	var paw := SCRAP_SIZE * 1.1 if key or note else 0.0
	scrap.width = SCRAP_PAD * 2.0 + paw + text + (0.0 if note else SCRAP_SIZE * 1.4)
	scrap.outline = _scrap_outline(scrap.width, hash(task.id))
	scrap.facets = facets(scrap.outline, hash(task.id), SCRAP_HEIGHT * 0.9)
	scrap.at = -SCRAP_HEIGHT * 1.5
	scrap.chalk = Layer.new(_paint_scrap_chalk.bind(scrap))
	scrap.chalk.material = TitleMenu.chalk()
	scrap.add_child(scrap.chalk)
	add_child(scrap)
	_scraps.append(scrap)
	return scrap


## A strip torn off the page: ragged all round, its bottom middle at (0, 0).
func _scrap_outline(width: float, seed: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pts := PackedVector2Array()
	var steps := ceili(width / 26.0)
	for i in steps + 1:
		pts.append(Vector2(-width * 0.5 + width * i / steps, -SCRAP_HEIGHT + rng.randf_range(-2.5, 2.5)))
	pts.append(Vector2(width * 0.5 + rng.randf_range(-2.0, 3.0), -SCRAP_HEIGHT * 0.5))
	for i in range(steps, -1, -1):
		pts.append(Vector2(-width * 0.5 + width * i / steps, rng.randf_range(-2.5, 2.5)))
	pts.append(Vector2(-width * 0.5 + rng.randf_range(-3.0, 2.0), -SCRAP_HEIGHT * 0.5))
	return pts


## A scrap at its place along the bottom, sliding up into it as it comes and down out of
## sight as it goes; and out of the way while the page is up, unless it's the tutorial's.
func _place_scrap(scrap: Scrap) -> void:
	var view := get_viewport_rect().size
	var s := _scale()
	var come := clampf((_clock - scrap.born) / SCRAP_MOVE, 0.0, 1.0)
	var go := clampf((_clock - scrap.leaves) / SCRAP_MOVE, 0.0, 1.0)
	var shown := smoothstep(0.0, 1.0, come) * (1.0 - smoothstep(0.0, 1.0, go))
	scrap.scale = Vector2(s, s)
	scrap.position = Vector2(view.x * 0.5, view.y - (SCRAP_BOTTOM + scrap.at - (1.0 - shown) * 30.0) * s)
	scrap.rotation = deg_to_rad(sin(float(hash(scrap.task.id) % 100)) * 1.2)
	scrap.modulate.a = shown * (1.0 if scrap.note else 1.0 - _up)


func _paint_scrap(item: CanvasItem) -> void:
	for facet: Array in (item as Scrap).facets:
		item.draw_colored_polygon(facet[0], facet[1])


## The key task: a chalk paw (rocking, as the title's does), the task and its box; a task
## done: the task crossed off and stamped; the tutorial's note: the paw and the note.
func _paint_scrap_chalk(item: CanvasItem, scrap: Scrap) -> void:
	var left := -scrap.width * 0.5 + SCRAP_PAD
	var base := -SCRAP_HEIGHT * 0.5 + SCRAP_SIZE * CAP_HEIGHT * 0.5
	if scrap.key or scrap.note:
		var rock: float = TitleMenu.PAW_ROCK[int(_clock * TitleMenu.ROCK_STEPS) % TitleMenu.PAW_ROCK.size()]
		TitleMenu.paw(item, Vector2(left + SCRAP_SIZE * 0.4, -SCRAP_HEIGHT * 0.5), SCRAP_SIZE * 0.8,
			deg_to_rad(rock + 12.0), CHALK)
		left += SCRAP_SIZE * 1.1
	if scrap.note:
		write(item, scrap.task.text, Vector2(left, base), SCRAP_SIZE, CHALK)
		return
	var done := clampf((_clock - scrap.struck) / STRIKE_TIME, 0.0, 1.0)
	var right := write(item, scrap.task.text, Vector2(left, base), SCRAP_SIZE, Color(CHALK, lerpf(1.0, DONE_FADE, done)))
	var box := Vector2(scrap.width * 0.5 - SCRAP_PAD - SCRAP_SIZE * 0.35, -SCRAP_HEIGHT * 0.5)
	if done > 0.0:
		cross_off(item, left, right, base, SCRAP_SIZE, done, hash(scrap.task.id))
	if done >= 1.0:
		stamp(item, box, SCRAP_SIZE * 0.85, _clock - scrap.struck - STRIKE_TIME)
	else:
		empty_box(item, box, tasks.list.find(scrap.task), hash(scrap.task.id), SCRAP_SIZE * 0.6)


# --- Drawing in chalk -------------------------------------------------------------

## Writes `line` with its baseline starting at `at`, and returns where it ends on the right.
func write(item: CanvasItem, line: String, at: Vector2, font_size: int, color: Color) -> float:
	item.draw_string(_hand, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	return at.x + _hand.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## A chalk line through the middle of the writing from `left` to `right`, drawn as far as
## `upto` (0..1).
static func cross_off(item: CanvasItem, left: float, right: float, base: float, font_size: int, upto: float,
		seed: int) -> void:
	var y := base - font_size * CAP_HEIGHT * 0.42
	stroke(item, [Vector2(left - 6.0, y + 2.0), Vector2((left + right) * 0.5, y - 1.0), Vector2(right + 6.0, y - 2.0)],
		STROKE * font_size / TASK_SIZE + 0.5, CHALK, upto, seed)


## A task's empty box, `size` across, centred on `at`: a square on every other line, a
## circle on the rest, as in the picture.
static func empty_box(item: CanvasItem, at: Vector2, line: int, seed: int, size := 0.0) -> void:
	var pts: Array[Vector2] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	if line % 2 == 1:
		var h := (size if size > 0.0 else SQUARE) * 0.5
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
			pts.append(at + corner * h + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)))
		pts.append(pts[-1] + Vector2(h * 0.25, -1.0))
	else:
		var r := (size if size > 0.0 else CIRCLE) * 0.5
		for k in 25:
			var a := deg_to_rad(-110.0 + 375.0 * k / 24.0)
			pts.append(at + Vector2(cos(a), sin(a)) * r * (1.0 + rng.randf_range(-0.04, 0.04)))
	stroke(item, pts, BOX_STROKE * (size / SQUARE if size > 0.0 else 1.0) + 0.3, CHALK, 1.0, seed)


## A done task's stamp, `size` across, centred on `at`: a chalk paw with a tick through
## it, popping up as the title's paw does, `since` seconds after it's stamped.
static func stamp(item: CanvasItem, at: Vector2, size: float, since: float) -> void:
	var step := int(since * TitleMenu.STEPS)
	var grow: float = TitleMenu.PAW_POP[step] if step < TitleMenu.PAW_POP.size() else 1.0
	TitleMenu.paw(item, at + Vector2(-0.1, 0.06) * size, size * grow, deg_to_rad(-12.0), CHALK)
	stroke(item, [at + Vector2(-0.3, 0.1) * size, at + Vector2(-0.08, 0.32) * size, at + Vector2(0.5, -0.5) * size],
		STROKE * 1.2 * size / STAMP, CHALK, clampf(since * 4.0, 0.0, 1.0))


## A dirty paw print, `size` across, centred on `at`: the paw pressed down three times, a
## little apart and faint each time, so it smudges.
static func smudge(item: CanvasItem, at: Vector2, size: float, angle: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 31.0 + at.y)
	for k in 3:
		var shift := Vector2(rng.randf_range(-0.07, 0.07), rng.randf_range(-0.07, 0.1)) * size
		TitleMenu.paw(item, at + shift, size * rng.randf_range(0.9, 1.05), angle + rng.randf_range(-0.2, 0.2), SMUDGE)


## A chalk line through `pts`, wavering a little (by `seed`, so it's the same every
## frame), drawn as far as `upto` (0..1) of its length.
static func stroke(item: CanvasItem, pts: Array, width: float, color: Color, upto := 1.0, seed := 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var line := PackedVector2Array([pts[0]])
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var steps := maxi(1, ceili(a.distance_to(b) / 7.0))
		var across := (b - a).orthogonal().normalized()
		for k in range(1, steps + 1):
			var wobble := across * rng.randf_range(-0.7, 0.7) if k < steps else Vector2.ZERO
			line.append(a.lerp(b, float(k) / steps) + wobble)
	var length := 0.0
	for i in range(1, line.size()):
		length += line[i - 1].distance_to(line[i])
	var left := length * upto
	var drawn := PackedVector2Array([line[0]])
	for i in range(1, line.size()):
		var d := line[i - 1].distance_to(line[i])
		if d >= left:
			drawn.append(line[i - 1].lerp(line[i], left / d))
			break
		left -= d
		drawn.append(line[i])
	if drawn.size() > 1 and upto > 0.0:
		item.draw_polyline(drawn, color, width, true)


## Faceted paper inside `outline`, as [polygon, colour] pairs: the outline's box cut into
## triangles about `step` across, each tipped a little at random (by `seed`) and shaded by
## how it faces the light, between PAPER_DARK and PAPER_LIGHT; each one is trimmed to the
## outline.
static func facets(outline: PackedVector2Array, seed: int, step: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var box := Rect2(outline[0], Vector2.ZERO)
	for p in outline:
		box = box.expand(p)
	box = box.grow(2.0)
	var cols := maxi(1, roundi(box.size.x / step))
	var rows := maxi(1, roundi(box.size.y / step))
	var points := PackedVector2Array()
	var heights := PackedFloat32Array()
	for j in rows + 1:
		for i in cols + 1:
			var p := box.position + box.size * Vector2(float(i) / cols, float(j) / rows)
			if i > 0 and i < cols:
				p.x += rng.randf_range(-0.35, 0.35) * box.size.x / cols
			if j > 0 and j < rows:
				p.y += rng.randf_range(-0.35, 0.35) * box.size.y / rows
			points.append(p)
			heights.append(rng.randf_range(-0.2, 0.2) * step)
	var tris := Geometry2D.triangulate_delaunay(points)
	var shades := PackedFloat32Array()
	for t in range(0, tris.size(), 3):
		var corners: Array[Vector3] = []
		for k in 3:
			var p := points[tris[t + k]]
			corners.append(Vector3(p.x, p.y, heights[tris[t + k]]))
		var n := (corners[1] - corners[0]).cross(corners[2] - corners[0]).normalized()
		if n.z < 0.0:
			n = -n
		shades.append(n.dot(LIGHT.normalized()))
	var lo := Array(shades).min() as float
	var hi := Array(shades).max() as float
	var out := []
	for k in shades.size():
		var t := k * 3
		var tri := PackedVector2Array([points[tris[t]], points[tris[t + 1]], points[tris[t + 2]]])
		var color := PAPER_DARK.lerp(PAPER_LIGHT, inverse_lerp(lo, hi, shades[k]) if hi > lo else 0.5)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(tri, outline):
			out.append([piece, color])
	return out
