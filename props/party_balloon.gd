extends Node3D
## A party balloon, low-poly 3D (CHANGE-BRIEF.md, revision of 21 Nov 2026, "the balloons are 3D,
## and the moth is the graded sprite clip"; before, a Sprite3D on a sheet). Built in code like
## the camp's other props (scripts/lowpoly.gd: faceted, flat-shaded, matte, vertex-coloured):
## a SIDES-sided egg of a body, fuller above, 0.3 m across, tinted; a small knot in its tint; a
## thin pale string down to just above the ground. No collision.
##   - The node's origin is the body's middle (camp_balloons.gd puts it MIDDLE_UP high, and the
##     bite measures from it). The clips move only its Float node (the body and string), never
##     the balloon itself.
##   - `colour` (red, yellow or blue) picks its tint and where in the bob it starts, so the
##     three don't bob in step.
##   - Its own AnimationPlayer has `bob` (animations/balloon_bob.tres, a 2 s loop) and `pop`
##     (animations/balloon_pop.tres, a quick swell). This script is that player's one
##     authority, the only caller of its play() and seek().
##   - pop() is the bite's (camp_balloons.gd, game code): it sets `popped` and plays `pop` once,
##     then hides the balloon when it's done.
## Written by Claude Code on 21 Nov 2026.

const LowPoly := preload("res://scripts/lowpoly.gd")

## Each colour's tint, from the camp's matte palette: the cooler's red (materials/
## cooler_body.tres), the trail mix's yellow band and the bear bag's blue (camp_bear_bag.gd).
const TINTS := {
	"red": Color("b25d57"),
	"yellow": Color("e2c25a"),
	"blue": Color("2f5d8a"),
}
## Seconds into the 2 s bob each colour starts at: a third of the way apart.
const BOB_OFFSETS := {"red": 0.0, "yellow": 2.0 / 3.0, "blue": 4.0 / 3.0}
## The body: its sides, and its profile from bottom to top, [height from its middle, radius]
## (m): an egg, fuller above, widest 0.15 m out (0.3 m across).
const SIDES := 7
const BODY := [[-0.18, 0.025], [-0.14, 0.09], [-0.07, 0.135], [0.0, 0.15], [0.07, 0.145],
	[0.13, 0.11], [0.17, 0.05], [0.185, 0.012]]
## The knot under it and the string, [height from the middle, sideways, radius]: the string
## ends 0.68 m down, just above the ground (the middle is 0.7 m up).
const TAIL := [[-0.18, 0.0, 0.018], [-0.21, 0.0, 0.011], [-0.22, 0.0, 0.0035], [-0.4, 0.008, 0.0035],
	[-0.55, 0.016, 0.0035], [-0.68, 0.01, 0.0035]]
const STRING := Color("ddd6c6")

@export_enum("red", "yellow", "blue") var colour := "red"
## True once he's bitten it.
var popped := false

@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_build()
	_anim.play("bob")
	_anim.seek(BOB_OFFSETS[colour], true)


## Bitten: it bursts (`pop`, once), then it's gone. Once only.
func pop() -> void:
	if popped:
		return
	popped = true
	_anim.animation_finished.connect(_on_finished)
	_anim.play("pop")


func _on_finished(anim_name: StringName) -> void:
	if anim_name == &"pop":
		hide()


## The body, and the knot and string, as faceted lofts in the camp's one matte material.
func _build() -> void:
	var tint: Color = TINTS[colour]
	var centers: Array = []
	var radii: Array = []
	for p: Array in BODY:
		centers.append(Vector3(0.0, p[0], 0.0))
		radii.append(Vector2(p[1], p[1]))
	($Float/Body as MeshInstance3D).mesh = LowPoly.loft(centers, radii, SIDES, LowPoly.solid(tint))
	centers.clear()
	radii.clear()
	for p: Array in TAIL:
		centers.append(Vector3(p[1], p[0], 0.0))
		radii.append(Vector2(p[2], p[2]))
	# The knot (its first segment and cap) in the tint; the string pale.
	var paint := func(segment: int, _side: int, _normal: Vector3) -> Color:
		return tint if segment <= 0 else STRING
	($Float/String as MeshInstance3D).mesh = LowPoly.loft(centers, radii, 4, paint)
