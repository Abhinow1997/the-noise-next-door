extends RefCounted
## The thought icons' art, drawn in code as loose, hand-scribbled lines over the game,
## following the author's reference sheet (shared in chat on 20 Oct 2026): flat colour,
## no shading, no borders, mostly white lines with a little red or yellow.
##   sparkles  three pale four-pointed glints (shiny loot)
##   fish      a scribbled loop with a fish skeleton in it (hungry); apple: an apple core
##   alert     a crooked red "!" with white marks round it
##   zzz       three handwritten z's floating up (hiding)
##   bulb      a flat yellow bulb with short rays (idea)
##   scribble  an angry white spiral with dark scribble clouds (frustrated)
##   bored     a round scribbled thought with a bored face in it, and
##   sigh      a zigzag puff out of his mouth beside it (both from the author's mock-up
##             of the bored raccoon, shared in chat on 20 Oct 2026)
## An icon is a list of strokes in units of the raccoon's height on the screen, with y
## pointing down and (0, 0) at the point it hangs over. Each stroke is wobbled a little
## sideways and runs on past its ends, like a quick pencil line. `frame` picks one of a
## few drawings that differ only in their wobble: cycling through them makes the lines
## "boil" like a hand-animated drawing. `step` (twelfths of a second since the icon
## appeared) moves the parts that move: the glints twinkle, the z's rise, the spiral spins.

## Colours sampled from the reference sheet.
const WHITE := Color("fbfaf3")
const SPARKLE := Color("f2efc8")
const DARK := Color("3c3c3a")
const BONE := Color("ecebe4")
const RED := Color("ec5b55")
const RED_LINE := Color("5c1512")
const BULB := Color("ffef8f")
const BULB_LINE := Color("7d6c2c")
const BASE := Color("4a4a48")
const RAY := Color("f3efc0")
const SCRIBBLE := Color("343432")
## A faint shadow under the white lines, so they still read over pale ground.
const SHADOW := Color(0.08, 0.1, 0.08, 0.16)
const SHADOW_OFFSET := Vector2(0.012, 0.016)
## How far a line wobbles sideways, how far it runs on past its ends, and how finely
## it's sampled, in units.
const WOBBLE := 0.01
const OVERSHOOT := 0.02
const STEP := 0.02
## The motion's steps a second (see `step`).
const STEPS := 12.0
## The glints' twinkle: a cycle of TWINKLE_CYCLE steps; each glint's size on each step
## of it, from when it pops up until it's gone again.
const TWINKLE_CYCLE := 24
const TWINKLE := [0.6, 1.2, 0.95, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.7, 0.4]
## The sigh's cycle, in steps: it puffs out of his mouth over SIGH_GROW steps, hangs,
## fades as it drifts up from SIGH_FADE, is gone by SIGH_GONE, and comes again. Four
## seconds, as long as the bored animation, which starts with him sagging as he sighs
## (raccoon_v2 anim.py), so the puff comes out as he lets his breath out.
const SIGH_CYCLE := 48
const SIGH_GROW := 6
const SIGH_FADE := 18
const SIGH_GONE := 30
## The z's and the spiral: their pop, and the spiral's turns a second.
const POP := [0.55, 1.2, 0.92, 1.0]
const SPIN := 1.0

static var _rng := RandomNumberGenerator.new()
static var _cache := {}


## The strokes of `icon`, drawing number `frame`, `step` twelfths of a second after it
## appeared. Each stroke is {pts, color, width, fill, shadow}.
static func strokes(icon: String, frame: int, step: int) -> Array:
	match icon:
		"sparkles":
			step = step % TWINKLE_CYCLE
		"zzz":
			step = mini(step, 48)
		"scribble":
			step = step % int(STEPS / SPIN)
		"sigh":
			step = step % SIGH_CYCLE
		_:
			step = 0
	var key := "%s/%d/%d" % [icon, frame, step]
	if _cache.has(key):
		return _cache[key]
	if _cache.size() > 400:
		_cache.clear()
	_rng.seed = hash(icon) + frame * 7919
	var t := step / STEPS
	var out := []
	match icon:
		"sparkles":
			_sparkles(out, step)
		"fish", "apple":
			_food(out, icon)
		"alert":
			_alert(out, frame)
		"zzz":
			_zzz(out, t, step)
		"bulb":
			_bulb(out, frame)
		"scribble":
			_scribble(out, t)
		"bored":
			_bored(out)
		"sigh":
			_sigh(out, step)
		_:
			push_warning("There's no thought icon called %s" % icon)
	_cache[key] = out
	return out


## Draws `list` (from strokes()) on `canvas` at `at`, `unit` pixels to a unit, turned
## by `turn` radians, faded to `alpha`, and mirrored left to right if `flip`.
static func draw(canvas: CanvasItem, list: Array, at: Vector2, unit: float, turn := 0.0, alpha := 1.0, flip := false) -> void:
	var xf := Transform2D(turn, Vector2(-unit if flip else unit, unit), 0.0, at)
	var drop := Transform2D(0.0, Transform2D(turn, Vector2(unit, unit), 0.0, Vector2.ZERO).basis_xform(SHADOW_OFFSET))
	# Every shadow first, so none falls across a line drawn before it.
	for s: Dictionary in list:
		if s.shadow:
			var pts: PackedVector2Array = drop * (xf * (s.pts as PackedVector2Array))
			_polyline(canvas, pts, Color(SHADOW, SHADOW.a * alpha * (s.color as Color).a), s.width * unit)
	for s: Dictionary in list:
		var pts: PackedVector2Array = xf * (s.pts as PackedVector2Array)
		var color: Color = s.color
		color.a *= alpha
		if s.fill:
			canvas.draw_colored_polygon(pts, color)
		else:
			_polyline(canvas, pts, color, s.width * unit)


static func _polyline(canvas: CanvasItem, pts: PackedVector2Array, color: Color, width: float) -> void:
	if pts.size() < 2:
		return
	canvas.draw_polyline(pts, color, width, true)
	# Round ends, like a pen's.
	canvas.draw_circle(pts[0], width * 0.5, color, true, -1.0, true)
	canvas.draw_circle(pts[pts.size() - 1], width * 0.5, color, true, -1.0, true)


# --- The icons ------------------------------------------------------------------

## Three glints of different sizes, popping up in turn and twinkling out again.
static func _sparkles(out: Array, step: int) -> void:
	# As on the reference sheet, but 0.45 units lower: from the game's camera, sparkles
	# as high over the loot as the sheet's look as if they belong to nothing.
	var glints := [[Vector2(-0.17, -0.98), Vector2(0.27, 0.39), 0], [Vector2(0.17, -1.3), Vector2(0.135, 0.175), 3],
		[Vector2(0.21, -0.74), Vector2(0.2, 0.215), 6]]
	for i in glints.size():
		var g: Array = glints[i]
		var at := posmod(step - int(g[2]), TWINKLE_CYCLE)
		if at >= TWINKLE.size():
			continue
		_glint(out, g[0], g[1] * float(TWINKLE[at]), i == 0)


## One four-pointed glint, its sides curving in, drawn round in one stroke; the big one
## gets a second, looser pass over two of its arms.
static func _glint(out: Array, c: Vector2, half: Vector2, double: bool) -> void:
	var k := 0.08
	var top := c + Vector2(0, -half.y)
	var right := c + Vector2(half.x, 0)
	var bottom := c + Vector2(0, half.y)
	var left := c + Vector2(-half.x, 0)
	var path := _quad(top, c + Vector2(k * half.x, -k * half.y), right)
	path.append_array(_quad(right, c + Vector2(k * half.x, k * half.y), bottom).slice(1))
	path.append_array(_quad(bottom, c + Vector2(-k * half.x, k * half.y), left).slice(1))
	path.append_array(_quad(left, c + Vector2(-k * half.x, -k * half.y), top).slice(1))
	_line(out, path, SPARKLE, 0.024, true)
	if double:
		var again := _quad(bottom, c + Vector2(-k * half.x, k * half.y), left)
		again.append_array(_quad(left, c + Vector2(-k * half.x, -k * half.y), top).slice(1))
		_line(out, again, WHITE, 0.016, false, WOBBLE * 1.5)


## A thought: an uneven loop scribbled round two or three times, with a tail down to his
## head, and a fish skeleton or an apple core inside.
static func _food(out: Array, inside: String) -> void:
	var c := Vector2(0.42, -0.73)
	var r := Vector2(0.66, 0.53)
	for i in 3:
		var start := _rng.randf_range(195.0, 250.0)
		var size := r * _rng.randf_range(0.95, 1.05)
		var middle := c + Vector2(_rng.randf_range(-0.02, 0.02), _rng.randf_range(-0.015, 0.015))
		_line(out, _ellipse(middle, size, start, 360.0 + _rng.randf_range(15.0, 50.0), 64), WHITE,
			0.02 if i == 0 else 0.015, i == 0)
	var tip := Vector2(0.03, -0.03)
	for at: float in [118.0, 102.0]:
		var base := c + Vector2(cos(deg_to_rad(at)) * r.x, sin(deg_to_rad(at)) * r.y)
		_line(out, _quad(base, base.lerp(tip, 0.5) + Vector2(-0.01, 0.01), tip, 8), WHITE, 0.02, true)
	if inside == "apple":
		_apple(out, c + Vector2(0.0, 0.03))
	else:
		_fish(out, c + Vector2(-0.02, 0.03))


## A fish skeleton: a rounded head with a cross for an eye, a spine with four ribs,
## and a triangle of a tail.
static func _fish(out: Array, f: Vector2) -> void:
	var head := PackedVector2Array([f + Vector2(-0.11, -0.15)])
	head.append_array(_quad(f + Vector2(-0.11, -0.15), f + Vector2(-0.38, -0.13), f + Vector2(-0.37, 0.0), 6).slice(1))
	head.append_array(_quad(f + Vector2(-0.37, 0.0), f + Vector2(-0.38, 0.13), f + Vector2(-0.11, 0.15), 6).slice(1))
	_fill(out, head, BONE)
	head.append(head[0])
	_line(out, head, DARK, 0.022)
	_line(out, PackedVector2Array([f + Vector2(-0.29, -0.05), f + Vector2(-0.25, -0.01)]), DARK, 0.016, false, 0.004)
	_line(out, PackedVector2Array([f + Vector2(-0.25, -0.05), f + Vector2(-0.29, -0.01)]), DARK, 0.016, false, 0.004)
	_line(out, PackedVector2Array([f + Vector2(-0.11, 0.0), f + Vector2(0.23, 0.0)]), DARK, 0.024)
	for x: float in [-0.075, 0.03, 0.13, 0.22]:
		_line(out, PackedVector2Array([f + Vector2(x + 0.01, -0.12), f + Vector2(x - 0.006, 0.12)]), DARK, 0.02)
	var tail := PackedVector2Array([f + Vector2(0.23, 0.0), f + Vector2(0.37, -0.12), f + Vector2(0.36, 0.12)])
	_fill(out, tail, BONE)
	tail.append(tail[0])
	_line(out, tail, DARK, 0.022)


## An apple core: skin top and bottom, bitten in at both sides, a stem and a leaf.
static func _apple(out: Array, a: Vector2) -> void:
	var core := _quad(a + Vector2(-0.12, -0.11), a + Vector2(-0.16, -0.2), a + Vector2(0.0, -0.18), 6)
	for seg: Array in [[Vector2(0.16, -0.2), Vector2(0.12, -0.11)], [Vector2(0.03, -0.03), Vector2(0.05, 0.03)],
			[Vector2(0.03, 0.08), Vector2(0.11, 0.12)], [Vector2(0.12, 0.21), Vector2(0.0, 0.2)],
			[Vector2(-0.12, 0.21), Vector2(-0.11, 0.12)], [Vector2(-0.03, 0.08), Vector2(-0.05, 0.03)],
			[Vector2(-0.03, -0.03), Vector2(-0.12, -0.11)]]:
		core.append_array(_quad(core[core.size() - 1], a + seg[0], a + seg[1], 6).slice(1))
	_fill(out, core, BONE)
	_line(out, core, DARK, 0.026)
	_line(out, _quad(a + Vector2(0.0, -0.18), a + Vector2(0.0, -0.25), a + Vector2(0.03, -0.29), 4), DARK, 0.026)
	var leaf := _quad(a + Vector2(0.02, -0.25), a + Vector2(0.09, -0.32), a + Vector2(0.14, -0.26), 5)
	leaf.append_array(_quad(a + Vector2(0.14, -0.26), a + Vector2(0.08, -0.22), a + Vector2(0.02, -0.25), 5).slice(1))
	_line(out, leaf, DARK, 0.02)


## A crooked red "!", wide at the top and narrow at the bottom, with four white marks
## radiating out round it, which flick outward every other drawing.
static func _alert(out: Array, frame: int) -> void:
	var bar := _quad(Vector2(-0.085, -0.84), Vector2(0.0, -0.93), Vector2(0.09, -0.85), 6)
	bar.append_array(_quad(Vector2(0.09, -0.85), Vector2(0.07, -0.6), Vector2(0.04, -0.4), 5).slice(1))
	bar.append_array(_quad(Vector2(0.04, -0.4), Vector2(0.0, -0.36), Vector2(-0.035, -0.4), 4).slice(1))
	bar.append_array(_quad(Vector2(-0.035, -0.4), Vector2(-0.06, -0.62), Vector2(-0.085, -0.84), 5).slice(1))
	var lean := Transform2D(0.0, Vector2(0.0, -0.6)) * Transform2D(deg_to_rad(5.0), Vector2.ZERO) * Transform2D(0.0, Vector2(0.0, 0.6))
	bar = lean * bar
	_fill(out, bar, RED)
	_line(out, bar, RED_LINE, 0.018, false, 0.004)
	var dot := _ellipse(Vector2(-0.005, -0.235), Vector2(0.06, 0.058), 0.0, 360.0, 14)
	_fill(out, dot, RED)
	_line(out, dot, RED_LINE, 0.018, false, 0.004)
	var flick := 0.025 if frame % 2 == 1 else 0.0
	for mark: Array in [[Vector2(-0.36, -0.3), Vector2(-0.27, -0.17)], [Vector2(-0.51, -0.03), Vector2(-0.38, 0.01)],
			[Vector2(0.34, -0.3), Vector2(0.27, -0.18)], [Vector2(0.5, -0.09), Vector2(0.37, -0.04)]]:
		var away: Vector2 = (mark[0] - mark[1]).normalized() * flick
		_line(out, PackedVector2Array([mark[0] + away, mark[1] + away]), WHITE, 0.04, true, 0.006)


## Three handwritten z's, small to big, each popping up a little after the last and all
## drifting up and swaying.
static func _zzz(out: Array, t: float, step: int) -> void:
	var sizes := [0.27, 0.34, 0.48]
	var places := [Vector2(0.0, -0.2), Vector2(0.42, -0.45), Vector2(0.92, -0.68)]
	for i in 3:
		var since := step - i * 2
		if since < 0:
			continue
		var grow: float = POP[mini(since, POP.size() - 1)]
		var at: Vector2 = places[i] + Vector2(sin(t * 2.6 + i * 1.7) * 0.03, -0.12 * t)
		_z(out, at, float(sizes[i]) * grow)


## One z, `s` tall: a top bar rising a little to the right, the diagonal, and a bottom
## bar, with its corners rounded off.
static func _z(out: Array, c: Vector2, s: float) -> void:
	var tl := c + Vector2(-0.48, -0.4) * s
	var tr := c + Vector2(0.48, -0.48) * s
	var bl := c + Vector2(-0.43, 0.44) * s
	var br := c + Vector2(0.52, 0.37) * s
	var cut := 0.1 * s
	var tr_in := tr - (tr - tl).normalized() * cut
	var tr_out := tr + (bl - tr).normalized() * cut
	var bl_in := bl - (bl - tr).normalized() * cut
	var bl_out := bl + (br - bl).normalized() * cut
	var path := _quad(tl, (tl + tr_in) * 0.5 + Vector2(0, -0.04 * s), tr_in, 5)
	path.append_array(_quad(tr_in, tr, tr_out, 3).slice(1))
	path.append_array(_quad(tr_out, (tr_out + bl_in) * 0.5, bl_in, 5).slice(1))
	path.append_array(_quad(bl_in, bl, bl_out, 3).slice(1))
	path.append_array(_quad(bl_out, (bl_out + br) * 0.5 + Vector2(0, 0.03 * s), br, 5).slice(1))
	_line(out, path, WHITE, 0.044, true, 0.006)


## A flat yellow bulb with a thin outline, a looped filament, a screw base of three
## short dark lines, and short pale rays that flicker in and out.
static func _bulb(out: Array, frame: int) -> void:
	var g := Vector2(0.04, -0.7)
	var r := 0.21
	var glass := _ellipse(g, Vector2(r, r * 1.02), 130.0, 280.0, 30)
	glass.append_array(_quad(glass[glass.size() - 1], g + Vector2(0.085, 0.19), g + Vector2(0.085, 0.25), 4).slice(1))
	glass.append(g + Vector2(-0.085, 0.25))
	glass.append_array(_quad(g + Vector2(-0.085, 0.25), g + Vector2(-0.085, 0.19), glass[0], 4).slice(1))
	_fill(out, glass, BULB)
	_line(out, glass, BULB_LINE, 0.018, false, 0.005)
	var filament := PackedVector2Array([g + Vector2(-0.035, 0.24), g + Vector2(-0.035, 0.08)])
	filament.append_array(_ellipse(g + Vector2(0.0, 0.04), Vector2(0.04, 0.04), 160.0, 220.0, 12))
	filament.append_array(PackedVector2Array([g + Vector2(0.035, 0.08), g + Vector2(0.035, 0.24)]))
	_line(out, filament, BULB_LINE, 0.015, false, 0.004)
	for k in 3:
		var half: float = [0.085, 0.078, 0.065][k]
		var y := 0.28 + 0.04 * k
		_line(out, PackedVector2Array([g + Vector2(-half, y), g + Vector2(half, y + 0.005)]), BASE, 0.03, false, 0.004)
	_line(out, PackedVector2Array([g + Vector2(-0.03, 0.4), g + Vector2(0.03, 0.4)]), BASE, 0.035, false, 0.004)
	var rays := [270.0, 220.0, 320.0, 180.0, 0.0, 140.0, 40.0]
	for i in rays.size():
		var dir := Vector2.from_angle(deg_to_rad(rays[i]))
		var flick := 0.02 if (i + frame) % 2 == 0 else -0.01
		_line(out, PackedVector2Array([g + dir * (0.44 + flick), g + dir * (0.6 + flick)]), RAY, 0.034, true, 0.006)


## An angry spiral whirling down to a squiggle, with dark scribble clouds beside it.
static func _scribble(out: Array, t: float) -> void:
	var spin := t * TAU * SPIN
	var spiral := PackedVector2Array()
	for i in 121:
		var s := i / 120.0
		var a := s * 4.5 * TAU + spin
		var rx := lerpf(0.45, 0.07, s)
		var cx := 0.02 + 0.05 * sin(s * 5.0)
		spiral.append(Vector2(cx + cos(a) * rx, lerpf(-1.0, -0.42, s) + sin(a) * rx * 0.3))
	spiral.append_array(PackedVector2Array([Vector2(0.03, -0.35), Vector2(-0.02, -0.26), Vector2(0.03, -0.17), Vector2(-0.01, -0.08)]))
	_line(out, spiral, WHITE, 0.028, true)
	_line(out, spiral, WHITE, 0.016, false, WOBBLE * 2.0)
	for cloud: Array in [[Vector2(-0.63, -1.05), 0.3, 0.0], [Vector2(0.75, -0.97), 0.46, 1.3], [Vector2(0.71, -0.44), 0.26, 2.1]]:
		_cloud(out, cloud[0] + Vector2(0.0, sin(t * 3.0 + cloud[2]) * 0.02), cloud[1], cloud[2])


## A dark scribble cloud `size` across: a line looping round and round a wide oval,
## and a tighter tangle in the middle.
static func _cloud(out: Array, c: Vector2, size: float, phase: float) -> void:
	var round_path := PackedVector2Array()
	for i in 161:
		var a := i / 160.0 * TAU
		var b := a * 8.0 + phase
		round_path.append(c + Vector2(cos(a) * 0.42, sin(a) * 0.24) * size + Vector2(cos(b), sin(b)) * size * 0.17)
	_line(out, round_path, SCRIBBLE, 0.016, false, WOBBLE)
	var core := PackedVector2Array()
	for i in 121:
		var a := i / 120.0 * TAU * 2.5
		var b := a * 5.0 + phase
		core.append(c + Vector2(cos(a) * 0.24, sin(a) * 0.12) * size + Vector2(cos(b), sin(b)) * size * 0.11)
	_line(out, core, SCRIBBLE, 0.016, false, WOBBLE * 0.8)


## Bored: a round scribbled loop with a short V of a tail down to his head, and a
## bored face in it, all in white: heavy lids drawn right across half-moon eyes, the
## pupils glancing aside under them, and a flat mouth. Measured from the mock-up.
static func _bored(out: Array) -> void:
	var c := Vector2(0.12, -1.07)
	var r := Vector2(0.8, 0.56)
	# One loop round, starting and ending by the tail, and a second pass down the left.
	_line(out, _ellipse(c, r, _rng.randf_range(100.0, 112.0), 338.0, 72), WHITE, 0.038, true)
	_line(out, _ellipse(c + Vector2(-0.01, 0.01), r * 0.985, 140.0, 75.0, 16), WHITE, 0.02, false, WOBBLE * 1.5)
	var tip := c + Vector2(-0.12, 0.8)
	_line(out, PackedVector2Array([c + Vector2(-0.19, 0.545), tip]), WHITE, 0.03, true)
	_line(out, PackedVector2Array([c + Vector2(0.03, 0.555), tip]), WHITE, 0.03, true)
	var face := c + Vector2(-0.15, 0.02)
	for side: float in [-1.0, 1.0]:
		var eye := face + Vector2(0.285 * side, -0.11)
		_line(out, PackedVector2Array([eye + Vector2(-0.2, 0.0), eye + Vector2(0.2, -0.005)]), WHITE, 0.042, true)
		_line(out, _ellipse(eye + Vector2(0.0, 0.005), Vector2(0.16, 0.13), 180.0, -180.0, 16), WHITE, 0.038, true)
		_fill(out, _ellipse(eye + Vector2(0.075, 0.01), Vector2(0.055, 0.055), 0.0, 180.0, 10), WHITE)
	_line(out, PackedVector2Array([face + Vector2(-0.12, 0.17), face + Vector2(0.14, 0.165)]), WHITE, 0.042, true)


## A sigh: a zigzag puff out of his mouth, going wider as it rises, as in the mock-up
## (drawn for a raccoon facing right, from his mouth; the icon mirrors it). It puffs
## out from the bottom, hangs, then fades as it drifts up (SIGH_CYCLE).
static func _sigh(out: Array, step: int) -> void:
	if step >= SIGH_GONE:
		return
	var going := clampf(float(step - SIGH_FADE) / (SIGH_GONE - SIGH_FADE), 0.0, 1.0)
	var lift := Vector2(0.0, -0.15 * going)
	var corners := PackedVector2Array([Vector2(0.27, -0.18), Vector2(0.5, -0.27), Vector2(0.23, -0.37), Vector2(0.68, -0.5),
		Vector2(0.14, -0.66), Vector2(0.86, -0.81), Vector2(0.07, -0.97), Vector2(0.95, -1.1)])
	var path := _rounded(corners, 0.3)
	# Puffing out: only as much of it as has come out yet.
	var shown := clampi(int(path.size() * float(step + 1) / SIGH_GROW), 2, path.size())
	path = Transform2D(0.0, lift) * path.slice(0, shown)
	_line(out, path, Color(WHITE, 1.0 - going), 0.036, true)


# --- Lines ----------------------------------------------------------------------

## `corners` joined by straight runs, each corner rounded off by `cut` of the runs
## either side of it.
static func _rounded(corners: PackedVector2Array, cut: float) -> PackedVector2Array:
	var path := PackedVector2Array([corners[0]])
	for i in range(1, corners.size() - 1):
		var into := corners[i].lerp(corners[i - 1], cut)
		var out_of := corners[i].lerp(corners[i + 1], cut)
		path.append_array(_quad(into, corners[i], out_of, 6))
	path.append(corners[corners.size() - 1])
	return path


static func _line(out: Array, path: PackedVector2Array, color: Color, width: float, shadow := false, wobble := WOBBLE) -> void:
	out.append({"pts": _sketch(path, wobble), "color": color, "width": width * _rng.randf_range(0.9, 1.1),
		"fill": false, "shadow": shadow})


## Flat colour, unwobbled, so it sits a little off its sketched outline as a quick
## colouring-in does.
static func _fill(out: Array, path: PackedVector2Array, color: Color) -> void:
	out.append({"pts": path, "color": color, "width": 0.0, "fill": true, "shadow": false})


## `path` as a hand-drawn line: sampled every STEP, pushed sideways by a smooth wobble,
## shifted a touch as a whole, and run on a little past its ends.
static func _sketch(path: PackedVector2Array, wobble: float) -> PackedVector2Array:
	var pts := _resample(path, STEP)
	var n := pts.size()
	if n < 2:
		return pts
	var p1 := _rng.randf() * TAU
	var p2 := _rng.randf() * TAU
	var shift := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * wobble * 0.6
	var out := PackedVector2Array()
	out.resize(n)
	var s := 0.0
	for i in n:
		if i > 0:
			s += pts[i].distance_to(pts[i - 1])
		var along := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var d := wobble * (0.65 * sin(s * TAU / 0.35 + p1) + 0.35 * sin(s * TAU / 0.13 + p2))
		out[i] = pts[i] + Vector2(-along.y, along.x) * d + shift
	var start := (out[0] - out[1]).normalized() * OVERSHOOT * _rng.randf_range(0.2, 1.0)
	var end := (out[n - 1] - out[n - 2]).normalized() * OVERSHOOT * _rng.randf_range(0.2, 1.0)
	out.insert(0, out[0] + start)
	out.append(out[out.size() - 1] + end)
	return out


## Points along `path`, `step` apart, keeping its first and last.
static func _resample(path: PackedVector2Array, step: float) -> PackedVector2Array:
	if path.size() < 2:
		return path
	var out := PackedVector2Array([path[0]])
	var carry := 0.0
	for i in range(1, path.size()):
		var a := path[i - 1]
		var b := path[i]
		var length := a.distance_to(b)
		var d := step - carry
		while d < length:
			out.append(a.lerp(b, d / length))
			d += step
		carry = length - (d - step)
	out.append(path[path.size() - 1])
	return out


static func _ellipse(c: Vector2, r: Vector2, from_deg: float, sweep_deg: float, steps := 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var a := deg_to_rad(from_deg + sweep_deg * i / steps)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


static func _quad(a: Vector2, ctrl: Vector2, b: Vector2, steps := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts
