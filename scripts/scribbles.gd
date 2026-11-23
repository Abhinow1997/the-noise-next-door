extends RefCounted
## The thought icons' art, drawn in code as loose, hand-scribbled lines over the game,
## following the author's reference sheet (shared in chat on 20 Oct 2026): flat colour,
## no shading, no borders. The sheet had a little red and yellow; since 25 Oct 2026 the
## moods are white lines, as the author asked ("all the moods should be white"), all but
## the anger mark and the food, which keep their colour ("have the colur for only rage
## and food").
##   sparkles  three four-pointed glints (shiny loot)
##   fish      a scribbled loop with a half-eaten apple in it (hungry; still called
##             "fish" after its first picture, a fish skeleton, which the author swapped
##             for the apple on 25 Oct 2026); apple: an apple core
##   alert     a crooked "!" with marks round it
##   zzz       three handwritten z's floating up (hiding)
##   snooze    z's floating up from him one after another, for as long as he naps (asleep)
##   bulb      a bulb drawn in outline, with short rays (idea)
##   scribble  a red anger mark, four bent strokes round a middle, throbbing (frustrated;
##             from the author's picture of one shared in chat on 25 Oct 2026, in place
##             of the old spiral and then a #)
##   bored     a round scribbled thought with a bored face in it, and
##   sigh      a zigzag puff out of his mouth beside it (both from the author's mock-up
##             of the bored raccoon, shared in chat on 20 Oct 2026)
##   hehehe    his laugh when he chitters: the word written by hand, popping up over his
##             head, with a few white marks and no bubble (from the author's mock-up);
##             hehehe_left is the same, for when he faces left
##   waves     three wavy lines rolling out from a sound, small to big, the biggest at
##             (0, 0), each snaking along an arc about a point to the left and bowing
##             right, the way the sound goes (the party's music, sound_waves.gd; from the
##             shouts in the author's picture shared in chat on 25 Oct 2026)
## An icon is a list of strokes in units of the raccoon's height on the screen, with y
## pointing down and (0, 0) at the point it hangs over. Each stroke is wobbled a little
## sideways and runs on past its ends, like a quick pencil line. `frame` picks one of a
## few drawings that differ only in their wobble: cycling through them makes the lines
## "boil" like a hand-animated drawing. `step` (twelfths of a second since the icon
## appeared) moves the parts that move: the glints twinkle, the z's rise, the anger mark
## throbs.

## Colours sampled from the reference sheet (SPARKLE and DARK are only the E prompt's
## now, camp_input.gd); the anger mark's red, from the author's picture of it; and the
## apple's.
const WHITE := Color("fbfaf3")
const SPARKLE := Color("f2efc8")
const DARK := Color("3c3c3a")
const RAGE := Color("be1930")
const APPLE := Color("d8342c")
const APPLE_LINE := Color("5c1512")
const FLESH := Color("f6eccb")
const STEM := Color("6b4a2b")
const LEAF := Color("7fb24a")
const LEAF_LINE := Color("2f4a1c")
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
## The laugh's size beside the author's mock-up, which the author asked to be smaller.
const LAUGH_SIZE := 0.25
## The z's pop.
const POP := [0.55, 1.2, 0.92, 1.0]
## The anger mark: how wide it is across and where its middle is (units), how thick its
## strokes are, and its throb (its size on each step, round and round).
const ANGER_SIZE := 0.55
const ANGER_AT := Vector2(0.02, -0.6)
const ANGER_WIDTH := 0.05
const THROB := [1.0, 1.0, 1.14, 1.06]
## Asleep, a z pops up by his head every SNOOZE_GAP steps and floats up, growing, until
## it goes SNOOZE_LIFE steps later, so three are always on their way up, small to big,
## like the hiding z's. SNOOZE_GO: a z's size and opacity on its last steps.
const SNOOZE_GAP := 12
const SNOOZE_LIFE := 36
const SNOOZE_GO := [[0.85, 0.85], [0.6, 0.55], [0.35, 0.25]]
## The sound waves' lines snake this far either side of their arcs (asked for on 25 Oct
## 2026: "wavy rather than ((("), in units.
const WAVE_HEIGHT := 0.045

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
		"snooze":
			# Once the stream is full, it comes round again every SNOOZE_GAP steps.
			var full := SNOOZE_LIFE - SNOOZE_GAP
			if step > full:
				step = full + (step - full) % SNOOZE_GAP
		"scribble":
			step = step % THROB.size()
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
		"snooze":
			_snooze(out, step)
		"bulb":
			_bulb(out, frame)
		"scribble":
			_scribble(out, step)
		"bored":
			_bored(out)
		"sigh":
			_sigh(out, step)
		"hehehe", "hehehe_left":
			_laugh(out, frame, icon == "hehehe_left")
		"waves":
			_waves(out)
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
	_line(out, path, WHITE, 0.024, true)
	if double:
		var again := _quad(bottom, c + Vector2(-k * half.x, k * half.y), left)
		again.append_array(_quad(left, c + Vector2(-k * half.x, -k * half.y), top).slice(1))
		_line(out, again, WHITE, 0.016, false, WOBBLE * 1.5)


## A thought: an uneven loop scribbled round two or three times, with a tail down to his
## head, and a half-eaten apple or an apple core inside.
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
		_bitten_apple(out, c + Vector2(0.0, 0.05))


## A half-eaten apple, red, a big bite out of its right side showing the cream flesh in
## three tooth-mark scallops, with a stem and a green leaf; drawn 1.15 times the size of
## the coordinates here, which are about the old fish's size.
static func _bitten_apple(out: Array, a: Vector2) -> void:
	var place := Transform2D(0.0, Vector2.ONE * 1.15, 0.0, a)
	var bite := [Vector2(0.15, -0.23), Vector2(0.08, -0.08), Vector2(0.08, 0.07), Vector2(0.14, 0.22)]
	# Round from the dip at the top: the right lobe, the bite, the bottom, the left side.
	var skin := _quad(Vector2(0.0, -0.18), Vector2(0.06, -0.27), bite[0], 6)
	var edge := PackedVector2Array([bite[0]])
	for i in 3:
		var mid: Vector2 = (bite[i] + bite[i + 1]) * 0.5 + Vector2(-0.055, 0.0)
		edge.append_array(_quad(bite[i], mid, bite[i + 1], 6).slice(1))
	skin.append_array(edge.slice(1))
	skin.append_array(_quad(bite[3], Vector2(0.07, 0.28), Vector2(0.0, 0.23), 5).slice(1))
	skin.append_array(_quad(Vector2(0.0, 0.23), Vector2(-0.07, 0.29), Vector2(-0.15, 0.24), 5).slice(1))
	skin.append_array(_quad(Vector2(-0.15, 0.24), Vector2(-0.29, 0.17), Vector2(-0.27, -0.04), 8).slice(1))
	skin.append_array(_quad(Vector2(-0.27, -0.04), Vector2(-0.27, -0.24), Vector2(-0.13, -0.25), 8).slice(1))
	skin.append_array(_quad(Vector2(-0.13, -0.25), Vector2(-0.06, -0.27), Vector2(0.0, -0.18), 6).slice(1))
	skin = place * skin
	_fill(out, skin, APPLE)
	# The flesh: a crescent between the bite and a curve a little way in from it, which
	# leaves the bite's corners heading into the apple so it never crosses the bite.
	var inner := _cubic(bite[3], Vector2(-0.04, 0.15), Vector2(-0.05, -0.16), bite[0], 12)
	var flesh := edge.duplicate()
	flesh.append_array(inner.slice(1, inner.size() - 1))
	_fill(out, place * flesh, FLESH)
	_line(out, place * inner, APPLE_LINE, 0.014, false, 0.004)
	skin.append(skin[0])
	_line(out, skin, APPLE_LINE, 0.022, false, 0.004)
	_line(out, place * _quad(Vector2(0.0, -0.17), Vector2(-0.01, -0.25), Vector2(0.03, -0.31), 4), STEM, 0.03, false,
		0.004)
	var leaf := _quad(Vector2(0.02, -0.26), Vector2(0.08, -0.34), Vector2(0.17, -0.3), 5)
	leaf.append_array(_quad(Vector2(0.17, -0.3), Vector2(0.1, -0.23), Vector2(0.02, -0.26), 5).slice(1))
	leaf = place * leaf
	_fill(out, leaf, LEAF)
	_line(out, leaf, LEAF_LINE, 0.016, false, 0.004)


## An apple core: red skin top and bottom, the cream core bitten in at both sides, a
## stem and a green leaf.
static func _apple(out: Array, a: Vector2) -> void:
	var core := _quad(a + Vector2(-0.12, -0.11), a + Vector2(-0.16, -0.2), a + Vector2(0.0, -0.18), 6)
	for seg: Array in [[Vector2(0.16, -0.2), Vector2(0.12, -0.11)], [Vector2(0.03, -0.03), Vector2(0.05, 0.03)],
			[Vector2(0.03, 0.08), Vector2(0.11, 0.12)], [Vector2(0.12, 0.21), Vector2(0.0, 0.2)],
			[Vector2(-0.12, 0.21), Vector2(-0.11, 0.12)], [Vector2(-0.03, 0.08), Vector2(-0.05, 0.03)],
			[Vector2(-0.03, -0.03), Vector2(-0.12, -0.11)]]:
		core.append_array(_quad(core[core.size() - 1], a + seg[0], a + seg[1], 6).slice(1))
	_fill(out, core, FLESH)
	# The skin left on: the top and bottom of the outline, closed straight across.
	var top := _quad(a + Vector2(-0.12, -0.11), a + Vector2(-0.16, -0.2), a + Vector2(0.0, -0.18), 6)
	top.append_array(_quad(a + Vector2(0.0, -0.18), a + Vector2(0.16, -0.2), a + Vector2(0.12, -0.11), 6).slice(1))
	_fill(out, top, APPLE)
	var bottom := _quad(a + Vector2(0.11, 0.12), a + Vector2(0.12, 0.21), a + Vector2(0.0, 0.2), 6)
	bottom.append_array(_quad(a + Vector2(0.0, 0.2), a + Vector2(-0.12, 0.21), a + Vector2(-0.11, 0.12), 6).slice(1))
	_fill(out, bottom, APPLE)
	_line(out, core, APPLE_LINE, 0.026)
	_line(out, _quad(a + Vector2(0.0, -0.18), a + Vector2(0.0, -0.25), a + Vector2(0.03, -0.29), 4), STEM, 0.026)
	var leaf := _quad(a + Vector2(0.02, -0.25), a + Vector2(0.09, -0.32), a + Vector2(0.14, -0.26), 5)
	leaf.append_array(_quad(a + Vector2(0.14, -0.26), a + Vector2(0.08, -0.22), a + Vector2(0.02, -0.25), 5).slice(1))
	_fill(out, leaf, LEAF)
	_line(out, leaf, LEAF_LINE, 0.02)


## A crooked white "!", wide at the top and narrow at the bottom, with four marks
## radiating out round it, which flick outward every other drawing.
static func _alert(out: Array, frame: int) -> void:
	var bar := _quad(Vector2(-0.085, -0.84), Vector2(0.0, -0.93), Vector2(0.09, -0.85), 6)
	bar.append_array(_quad(Vector2(0.09, -0.85), Vector2(0.07, -0.6), Vector2(0.04, -0.4), 5).slice(1))
	bar.append_array(_quad(Vector2(0.04, -0.4), Vector2(0.0, -0.36), Vector2(-0.035, -0.4), 4).slice(1))
	bar.append_array(_quad(Vector2(-0.035, -0.4), Vector2(-0.06, -0.62), Vector2(-0.085, -0.84), 5).slice(1))
	var lean := Transform2D(0.0, Vector2(0.0, -0.6)) * Transform2D(deg_to_rad(5.0), Vector2.ZERO) * Transform2D(0.0, Vector2(0.0, 0.6))
	bar = lean * bar
	_fill(out, bar, WHITE)
	_line(out, bar, WHITE, 0.018, true, 0.004)
	var dot := _ellipse(Vector2(-0.005, -0.235), Vector2(0.06, 0.058), 0.0, 360.0, 14)
	_fill(out, dot, WHITE)
	_line(out, dot, WHITE, 0.018, true, 0.004)
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


## Asleep: z's floating up from him one after another for as long as he naps. Each pops
## up small by his head, grows as it drifts up and away, rocking a little as it goes,
## and shrinks away about where the hiding z's stop.
static func _snooze(out: Array, step: int) -> void:
	var born := step - step % SNOOZE_GAP
	while born >= 0 and step - born < SNOOZE_LIFE:
		var age := step - born
		var s := float(age) / SNOOZE_LIFE
		var size := lerpf(0.22, 0.52, s)
		var color := WHITE
		if age < POP.size():
			size *= float(POP[age])
		var going := age - (SNOOZE_LIFE - SNOOZE_GO.size())
		if going >= 0:
			size *= float(SNOOZE_GO[going][0])
			color.a = float(SNOOZE_GO[going][1])
		# Up the hiding z's slope from the reference sheet, far enough apart that the
		# three never run into each other, bobbing a little as they go.
		var at := Vector2(0.1 + 1.3 * s, -0.25 - 0.72 * s + sin(s * TAU * 1.5) * 0.03)
		_z(out, at, size, color, sin(s * TAU * 1.5) * 0.1)
		born -= SNOOZE_GAP


## One z, `s` tall and tipped `tilt` radians: a top bar rising a little to the right,
## the diagonal, and a bottom bar, with its corners rounded off.
static func _z(out: Array, c: Vector2, s: float, color := WHITE, tilt := 0.0) -> void:
	var place := Transform2D(tilt, c)
	var tl := place * (Vector2(-0.48, -0.4) * s)
	var tr := place * (Vector2(0.48, -0.48) * s)
	var bl := place * (Vector2(-0.43, 0.44) * s)
	var br := place * (Vector2(0.52, 0.37) * s)
	var cut := 0.1 * s
	var tr_in := tr - (tr - tl).normalized() * cut
	var tr_out := tr + (bl - tr).normalized() * cut
	var bl_in := bl - (bl - tr).normalized() * cut
	var bl_out := bl + (br - bl).normalized() * cut
	var path := _quad(tl, (tl + tr_in) * 0.5 + place.basis_xform(Vector2(0, -0.04 * s)), tr_in, 5)
	path.append_array(_quad(tr_in, tr, tr_out, 3).slice(1))
	path.append_array(_quad(tr_out, (tr_out + bl_in) * 0.5, bl_in, 5).slice(1))
	path.append_array(_quad(bl_in, bl, bl_out, 3).slice(1))
	path.append_array(_quad(bl_out, (bl_out + br) * 0.5 + place.basis_xform(Vector2(0, 0.03 * s)), br, 5).slice(1))
	_line(out, path, color, 0.044, true, 0.006)


## A bulb in white outline, a looped filament, a screw base of three short lines, and
## short rays that flicker in and out.
static func _bulb(out: Array, frame: int) -> void:
	var g := Vector2(0.04, -0.7)
	var r := 0.21
	var glass := _ellipse(g, Vector2(r, r * 1.02), 130.0, 280.0, 30)
	glass.append_array(_quad(glass[glass.size() - 1], g + Vector2(0.085, 0.19), g + Vector2(0.085, 0.25), 4).slice(1))
	glass.append(g + Vector2(-0.085, 0.25))
	glass.append_array(_quad(g + Vector2(-0.085, 0.25), g + Vector2(-0.085, 0.19), glass[0], 4).slice(1))
	_line(out, glass, WHITE, 0.034, true, 0.005)
	var filament := PackedVector2Array([g + Vector2(-0.035, 0.24), g + Vector2(-0.035, 0.08)])
	filament.append_array(_ellipse(g + Vector2(0.0, 0.04), Vector2(0.04, 0.04), 160.0, 220.0, 12))
	filament.append_array(PackedVector2Array([g + Vector2(0.035, 0.08), g + Vector2(0.035, 0.24)]))
	_line(out, filament, WHITE, 0.018, false, 0.004)
	for k in 3:
		var half: float = [0.085, 0.078, 0.065][k]
		var y := 0.29 + 0.045 * k
		_line(out, PackedVector2Array([g + Vector2(-half, y), g + Vector2(half, y + 0.005)]), WHITE, 0.03, true, 0.004)
	_line(out, PackedVector2Array([g + Vector2(-0.03, 0.42), g + Vector2(0.03, 0.42)]), WHITE, 0.035, true, 0.004)
	var rays := [270.0, 220.0, 320.0, 180.0, 0.0, 140.0, 40.0]
	for i in rays.size():
		var dir := Vector2.from_angle(deg_to_rad(rays[i]))
		var flick := 0.02 if (i + frame) % 2 == 0 else -0.01
		_line(out, PackedVector2Array([g + dir * (0.44 + flick), g + dir * (0.6 + flick)]), WHITE, 0.034, true, 0.006)


## Frustrated: a red anger mark, as in the author's picture: four strokes round a middle,
## each bowing in toward it with its ends flicking out, turned like a pinwheel, and the
## whole mark throbbing (THROB). The top stroke is measured from the picture (pixels
## from its middle; the mark is 940 across) and turned a quarter at a time for the rest.
static func _scribble(out: Array, step: int) -> void:
	var size := ANGER_SIZE / 940.0 * float(THROB[step])
	var stroke := [Vector2(-115, -432), Vector2(27, -176), Vector2(99, -189), Vector2(320, -342)]
	for k in 4:
		var place := Transform2D(k * PI / 2.0, Vector2.ONE * size, 0.0, ANGER_AT)
		_line(out, _cubic(place * stroke[0], place * stroke[1], place * stroke[2], place * stroke[3], 16), RAGE,
			ANGER_WIDTH, true, 0.006)


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


## Three wavy lines along arcs about a point to the left, small to big, the biggest
## across (0, 0) and about as tall as he is. Each snakes WAVE_HEIGHT either side of its
## arc in an odd number of half waves, so it starts and ends on the arc and all three
## bulge out together in the middle, where the sound's heading.
static func _waves(out: Array) -> void:
	var c := Vector2(-0.92, 0.0)
	for arc: Array in [[0.4, 42.0, 3], [0.66, 38.0, 5], [0.92, 34.0, 7]]:
		var half := deg_to_rad(arc[1])
		var humps: int = arc[2]
		var steps := humps * 10
		var path := PackedVector2Array()
		for i in steps + 1:
			var t := float(i) / steps
			var a := lerpf(-half, half, t)
			path.append(c + Vector2(cos(a), sin(a)) * (arc[0] + WAVE_HEIGHT * cos((t - 0.5) * humps * PI)))
		_line(out, path, WHITE, 0.04, true)


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


## His laugh when he chitters: "hehehe" written by hand over his head, at (0, 0) like
## the other icons, with a few white marks flicking at its far end. It pops up whole, as
## the other icons do (thought_bubble.gd). No bubble, as the author asked. It sits a
## little toward the way he faces on the screen (`left` when that's left), tipped up a
## touch that way, and always reads left to right. Letters as measured from the mock-up
## (the word 1.8 units long, the h's 0.56 tall, the e's 0.32, leaning a little right),
## drawn at LAUGH_SIZE of that. (By his mouth instead, the author said it looked bad.)
static func _laugh(out: Array, frame: int, left: bool) -> void:
	var word := "hehehe"
	var length := 0.31 * (word.length() - 1) + 0.25
	# The word's own space: its line from (0, 0) to (length, 0), its middle set over his
	# head, a little toward the way he faces.
	var place := Transform2D(deg_to_rad(4.0 if left else -4.0), Vector2.ONE * LAUGH_SIZE, 0.0,
		Vector2(-0.12 if left else 0.12, -0.1)) * Transform2D(0.0, Vector2(-length * 0.5, 0.0))
	# Each letter's own slant, size and height off the line, the same in every drawing.
	var hand := RandomNumberGenerator.new()
	hand.seed = 4242
	for i in word.length():
		var size := hand.randf_range(0.94, 1.06)
		var slant := 0.1 + hand.randf_range(-0.05, 0.05)     # leaning a little right
		var off := hand.randf_range(-0.025, 0.025)
		var letter := place * Transform2D(slant, Vector2(size, size), 0.0, Vector2(0.31 * i, off))
		for stroke: PackedVector2Array in _letter(word[i]):
			_line(out, letter * stroke, WHITE, 0.024, true, 0.003)
	# The marks, at the far end of the word: dashes flicking outward, and a tiny glint.
	var far := Vector2(-0.22, 0.0) if left else Vector2(length + 0.22, 0.0)
	var side := -1.0 if left else 1.0
	var flick := 0.04 if frame % 2 == 1 else 0.0
	for mark: Array in [[Vector2(0.0, -0.42), Vector2(0.1, -0.54)], [Vector2(0.04, -0.24), Vector2(0.18, -0.28)],
			[Vector2(0.02, -0.06), Vector2(0.16, -0.01)]]:
		var a: Vector2 = far + Vector2(mark[0].x * side, mark[0].y)
		var b: Vector2 = far + Vector2(mark[1].x * side, mark[1].y)
		var away := (b - a).normalized() * flick
		_line(out, place * PackedVector2Array([a + away, b + away]), WHITE, 0.02, true, 0.003)
	var glint := place * (far + Vector2(0.06 * side, -0.68))
	var r := 0.025 if frame % 2 == 0 else 0.017
	_line(out, PackedVector2Array([glint + Vector2(0, -r), glint + Vector2(0, r)]), WHITE, 0.012, false, 0.0)
	_line(out, PackedVector2Array([glint + Vector2(-r, 0), glint + Vector2(r, 0)]), WHITE, 0.012, false, 0.0)


static var _letters := {}


## A handwritten letter (h or e) as its strokes, its line's left end at the origin: an h
## is a tall stem, then a round arch out of it and down; an e is a bar across its middle
## that runs on round anticlockwise and ends with a little flick up.
static func _letter(ch: String) -> Array:
	if _letters.has(ch):
		return _letters[ch]
	var strokes := []
	if ch == "h":
		strokes.append(PackedVector2Array([Vector2(0.03, -0.56), Vector2(0.0, 0.0)]))
		var arch := _quad(Vector2(0.004, -0.15), Vector2(0.04, -0.34), Vector2(0.14, -0.33), 8)
		arch.append_array(_quad(Vector2(0.14, -0.33), Vector2(0.245, -0.32), Vector2(0.24, -0.17), 6).slice(1))
		arch.append(Vector2(0.245, 0.0))
		strokes.append(arch)
	else:
		var e := PackedVector2Array([Vector2(0.02, -0.15), Vector2(0.245, -0.16)])
		e.append_array(_ellipse(Vector2(0.13, -0.16), Vector2(0.125, 0.16), -5.0, -310.0, 26).slice(1))
		strokes.append(e)
	_letters[ch] = strokes
	return strokes


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


static func _cubic(a: Vector2, c1: Vector2, c2: Vector2, b: Vector2, steps := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		pts.append(a.bezier_interpolate(c1, c2, b, float(i) / steps))
	return pts
