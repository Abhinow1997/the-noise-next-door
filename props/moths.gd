extends Node3D
## The moth over the campfire (CHANGE-BRIEF.md, revision of 22 Nov 2026, "one moth, on my own
## low-poly sheet, over the fire"; first built as four pixel-art moths on 21 Nov): one Sprite3D on
## the author's low-poly sheet (assets/sprites/moth_lowpoly/moth_lowpoly.png, 2 x 2 cells), 0.15 m
## across its spread wings, billboarded with smooth filtering, fluttering to `flutter`
## (animations/moth_flutter.tres) on its own AnimationPlayer. The author's words for it: "an
## indicator of the fire being on, and like surveillance being on."
## This is its driver, presentation only. It reads the fire (camp_fire.gd burning()) and writes
## nothing in the game. One writer to each animated node:
##   - the moth's Sprite3D `frame`: its own AnimationPlayer only;
##   - the AnimationPlayer: this script only, which plays `flutter` on it once, from half a frame
##     in, so at 24 and 60 fps its wrap doesn't land exactly on the clip's length (where the
##     engine shows the last cell: TEST-REPORT.md, the cycle seam);
##   - the pivot above the moth (its circle over the fire), and the root's `visible` (shown while
##     the fire burns, hidden while it doesn't): this script only.
## Built on 21 Nov 2026 by Claude Code; one moth on the new sheet since 22 Nov 2026.

## The moth's circle: how far out from the fire's middle (m), how high its middle (m, with its
## bob), how fast it goes round (rad/s; the sign is which way), where round it starts (rad), and
## where in the flutter it starts (s; the clip is 6/24 s): half a frame, 1/48 s.
const CIRCLES := [
	[0.4, 1.2, 1.4, 0.0, 1.0 / 48.0],
]
## How far it bobs up and down as it circles (m), and how fast (rad/s).
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
