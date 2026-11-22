extends Node3D
## The moth over the campfire (CHANGE-BRIEF.md, revision of 22 Nov 2026, "one moth, on my own
## low-poly sheet, over the fire"; first built as four pixel-art moths on 21 Nov): one Sprite3D on
## the author's low-poly sheet (assets/sprites/moth_lowpoly/moth_lowpoly.png, 2 x 2 cells), 0.15 m
## across its spread wings, billboarded with smooth filtering, fluttering to `flutter`
## (animations/moth_flutter.tres) on its own AnimationPlayer. Its job, in the author's words (22 Nov
## 2026): "he helps user navigate to the main area" (guide(), below). Over the fire afterwards it
## still shows the fire's on, a side effect (its first job, 21 Nov: "an indicator of the fire being
## on, and like surveillance being on").
## This is its driver, presentation only. It reads the fire (camp_fire.gd burning()) and writes
## nothing in the game. One writer to each animated node:
##   - the moth's Sprite3D `frame`: its own AnimationPlayer only;
##   - the AnimationPlayer: this script only, which plays `flutter` on it once, from half a frame
##     in, so at 24 and 60 fps its wrap doesn't land exactly on the clip's length (where the
##     engine shows the last cell: TEST-REPORT.md, the cycle seam);
##   - the pivot above the moth (its circle over the fire), the root's place while it's on its
##     own, and the root's `visible`: this script only.
## Since 22 Nov 2026, at the author's request, it's also his guide on a New Game: "let the moth be
## the one who guides the raccoon to the particular campsite, and it can be like an annoying, like
## a fly ... it can come to the raccoon, but it should be always like away from it. Raccoon should
## not be able to catch it, if just trying to sit on his head or something. But as soon as the
## raccoon moves, we can take it away and guide it towards the campsite." main.gd calls guide()
## until he first reaches the camp ("Investigate the music"). Still presentation only: it reads
## where he is, the trail and the task, and writes nothing in the game.
##   - Once he's out of the hollow, it flutters in from the trees.
##   - While he's still, it buzzes round his head and every so often dips as if to land on it,
##     then darts off. It never comes within MIN_REACH of his head.
##   - As soon as he moves, it flies ahead of him along the trail (forest.gd TRAIL_POINTS) toward
##     the camp, LEAD metres on from where he is, never more than LEASH from him.
##   - Once he's reached the camp, it flies to the fire and is the fire's moth from then on: over
##     the flames while it burns, gone while it's out.
## Built on 21 Nov 2026 by Claude Code; one moth on the new sheet, and the guide, since 22 Nov 2026.

const Forest := preload("res://scripts/forest.gd")

## The moth's circle: how far out from the fire's middle (m), how high its middle (m, with its
## bob), how fast it goes round (rad/s; the sign is which way), where round it starts (rad), and
## where in the flutter it starts (s; the clip is 6/24 s): half a frame, 1/48 s.
const CIRCLES := [
	[0.4, 1.2, 1.4, 0.0, 1.0 / 48.0],
]
## How far it bobs up and down as it circles (m), and how fast (rad/s).
const BOB := 0.05
const BOB_SPEED := 5.0

## The guide: where the way starts (by his tree, x and z; then the trail), how far ahead of him it
## leads (m), how far from him it lets itself get (m), how close to his head it ever comes (m),
## where his head is (m above his feet), and how fast it can fly (m/s; he runs at 4).
const WAY_START := Vector2(0.0, 3.4)
const LEAD := 3.0
const LEASH := 4.5
const MIN_REACH := 0.25
const HEAD := 0.42
const MAX_SPEED := 6.5
## Buzzing round his head: how far out (m), how high over it (m), how fast round (rad/s), how often
## it dips as if to land (s) and for how long, and how far out it darts after (m).
const BUZZ_RADIUS := 0.42
const BUZZ_HIGH := 0.18
const BUZZ_SPIN := 3.2
const DIP_EVERY := 2.4
const DIP_TIME := 0.45
const DART_RADIUS := 0.8
## Leading: how high over the ground (m). He counts as moving above MOVING m/s.
const LEAD_HIGH := 0.95
const MOVING := 0.4
## Where it flutters in from, off to the side in the trees (m from him).
const COMES_FROM := Vector3(2.5, 1.6, -3.0)

## Set before it's added (main.gd): the campfire it reads.
var fire: Node3D

enum Mode { FIRE, GUIDE, TO_FIRE }

var _pivots: Array[Node3D] = []
var _t := 0.0
var _mode := Mode.FIRE
var _player: Node3D
var _tasks: Object
var _way := PackedVector2Array()
var _out := false
var _pos := Vector3.ZERO
var _vel := Vector3.ZERO
var _last_at := Vector3.ZERO
var _speed := 0.0
var _moving := false
var _since := 0.0
var _orbit := 0.0
var _dip_clock := 0.0


func _ready() -> void:
	# Placed every frame in _process, so not interpolated between physics ticks.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for i in CIRCLES.size():
		var pivot := get_node("Pivot%d" % i) as Node3D
		_pivots.append(pivot)
		var anim := pivot.get_node("Moth/AnimationPlayer") as AnimationPlayer
		anim.play("flutter")
		anim.seek(CIRCLES[i][4], true)
	_follow(0.0)


func _process(delta: float) -> void:
	match _mode:
		Mode.FIRE:
			_follow(delta)
		Mode.GUIDE:
			_guide(delta)
		Mode.TO_FIRE:
			_to_fire(delta)


## Over the fire, shown while it burns, the moth on its circle.
func _follow(delta: float) -> void:
	if fire == null:
		visible = false
		return
	global_position = fire.global_position
	visible = fire.call("burning")
	_t += delta
	for i in _pivots.size():
		var c: Array = CIRCLES[i]
		var a: float = c[3] + c[2] * _t
		_pivots[i].position = Vector3(cos(a) * c[0], c[1] + BOB * sin(BOB_SPEED * _t + c[3]), sin(a) * c[0])


## From main.gd on a New Game, before he's first reached the camp: guide him there. It waits
## while he's in the hollow, and starts once he's out.
func guide(player: Node3D, tasks: Object) -> void:
	_player = player
	_tasks = tasks
	_way = PackedVector2Array([WAY_START])
	for p: Vector2 in Forest.TRAIL_POINTS:
		_way.append(p)
	_mode = Mode.GUIDE
	_out = false
	visible = false


## True while it's guiding him (waiting for him to leave the hollow, or out with him).
func guiding() -> bool:
	return _mode == Mode.GUIDE


func _guide(delta: float) -> void:
	_t += delta
	if _tasks.call("is_done", "investigate"):
		_mode = Mode.TO_FIRE
		return
	var at := _player.global_position
	if bool(_player.get("resting")):
		visible = false
		_last_at = at
		return
	if not _out:
		# Out of the hollow: it flutters in from the trees.
		_out = true
		_pos = at + COMES_FROM
		_vel = Vector3.ZERO
		_last_at = at
	# How fast he's going, from where he's been (so a raccoon put somewhere counts as moving).
	var step := Vector2(at.x - _last_at.x, at.z - _last_at.z).length() / maxf(delta, 0.0001)
	_last_at = at
	_speed = lerpf(_speed, step, 1.0 - exp(-8.0 * delta))
	var now_moving := _speed > (MOVING * 0.5 if _moving else MOVING)
	_since = _since + delta if now_moving != _moving else 0.0
	if _since > (0.15 if now_moving else 0.6):
		_moving = now_moving
		_since = 0.0
	var head := at + Vector3.UP * HEAD
	var target: Vector3
	var stiff := 14.0
	if _moving:
		target = _ahead(at)
		stiff = 18.0
	else:
		_orbit += BUZZ_SPIN * delta
		_dip_clock += delta
		var radius := BUZZ_RADIUS
		var high := BUZZ_HIGH + 0.06 * sin(_t * 5.0)
		var cycle := fmod(_dip_clock, DIP_EVERY)
		if cycle > DIP_EVERY - DIP_TIME:
			# Down as if to land on his head; MIN_REACH keeps it just off.
			radius = 0.08
			high = 0.1
		elif cycle < 0.4:
			# Then darting off.
			radius = lerpf(DART_RADIUS, BUZZ_RADIUS, cycle / 0.4)
		target = head + Vector3(cos(_orbit) * radius, high, sin(_orbit) * radius)
	# A moth's wobble.
	target += Vector3(sin(_t * 7.3) * 0.05, sin(_t * 9.1) * 0.04, cos(_t * 6.7) * 0.05)
	_steer(target, stiff, delta)
	# Never within reach of his head.
	var off := _pos - head
	if off.length() < MIN_REACH:
		_pos = head + (off.normalized() if off.length() > 0.001 else Vector3.UP) * MIN_REACH
	_place_alone()


## The point on the way LEAD metres on from the nearest point to him, never more than LEASH from him.
func _ahead(at: Vector3) -> Vector3:
	var here := Vector2(at.x, at.z)
	var best := INF
	var best_s := 0.0
	var run := 0.0
	for i in _way.size() - 1:
		var a := _way[i]
		var ab := _way[i + 1] - a
		var f := clampf((here - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d := here.distance_to(a + ab * f)
		if d < best:
			best = d
			best_s = run + ab.length() * f
		run += ab.length()
	var goal := _at_length(best_s + LEAD)
	var to := goal - here
	if to.length() > LEASH:
		goal = here + to.normalized() * LEASH
	return Vector3(goal.x, at.y + LEAD_HIGH + 0.08 * sin(_t * 4.0), goal.y)


## The point s metres along the way (its end, beyond its length).
func _at_length(s: float) -> Vector2:
	var run := 0.0
	for i in _way.size() - 1:
		var seg := _way[i].distance_to(_way[i + 1])
		if run + seg >= s:
			return _way[i].lerp(_way[i + 1], (s - run) / seg)
		run += seg
	return _way[-1]


## A damped spring toward `target`, no faster than MAX_SPEED.
func _steer(target: Vector3, stiff: float, delta: float) -> void:
	_vel += ((target - _pos) * stiff * stiff - _vel * 2.0 * stiff) * delta
	if _vel.length() > MAX_SPEED:
		_vel = _vel.normalized() * MAX_SPEED
	_pos += _vel * delta


## The moth on its own at _pos, out of its circle over the fire.
func _place_alone() -> void:
	visible = true
	global_position = _pos
	for p in _pivots:
		p.position = Vector3.ZERO


## He's reached the camp: off to the fire, then the fire's moth (over it while it burns).
func _to_fire(delta: float) -> void:
	_t += delta
	if fire == null:
		visible = false
		return
	var c: Array = CIRCLES[0]
	var centre := fire.global_position + Vector3(0, c[1], 0)
	var dir := Vector3(_pos.x - centre.x, 0, _pos.z - centre.z)
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.RIGHT
	var target: Vector3 = centre + dir * float(c[0])
	_steer(target, 6.0, delta)
	_place_alone()
	if _pos.distance_to(target) < 0.15:
		# On the circle where it arrives, the circle's clock set so it carries on from there.
		_t = (atan2(dir.z, dir.x) - c[3]) / c[2]
		_mode = Mode.FIRE
		_follow(0.0)
