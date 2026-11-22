extends Node3D
## The moths round the campfire (CHANGE-BRIEF.md, revision of 21 Nov 2026, "The extras' timings
## and places"; not graded): four, each a Sprite3D on bugs.png's cells 4 and 5, 0.1 m across,
## billboarded with nearest filtering, fluttering to `flutter` (animations/moth_flutter.tres) on
## its own AnimationPlayer. The author's words for them: "an indicator of the fire being on,
## and like surveillance being on."
## This is their driver, presentation only. It reads the fire (camp_fire.gd burning()) and
## writes nothing in the game. One writer to each animated node:
##   - each moth's Sprite3D `frame`: its own AnimationPlayer only;
##   - each AnimationPlayer: this script only, which plays `flutter` on it once, from its own
##     offset, so they don't flap in step;
##   - each pivot above a moth (its circle round the fire), and the root's `visible` (shown
##     while the fire burns, hidden while it doesn't): this script only.
## Built on 21 Nov 2026 by Claude Code.

## Each moth's circle: how far out from the fire's middle (m, 0.55-0.9), how high its middle
## (m, kept within 0.85-1.5 with its bob), how fast it goes round (rad/s; the sign is which
## way), where round it starts (rad), and where in the flutter it starts (s; the clip is 4/24 s).
const CIRCLES := [
	[0.55, 0.95, 2.2, 0.0, 0.0],
	[0.7, 1.25, -1.7, 1.6, 1.0 / 24.0],
	[0.8, 1.05, 1.4, 3.3, 2.0 / 24.0],
	[0.9, 1.4, -2.0, 4.8, 3.0 / 24.0],
]
## How far each bobs up and down as it circles (m), and how fast (rad/s).
const BOB := 0.05
const BOB_SPEED := 5.0

## Set before it's added (main.gd): the campfire it reads.
var fire: Node3D

var _pivots: Array[Node3D] = []
var _t := 0.0


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
	_follow(delta)


## Over the fire, shown while it burns, each moth on its circle.
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
