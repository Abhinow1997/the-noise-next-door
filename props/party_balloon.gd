extends Sprite3D
## A party balloon (CHANGE-BRIEF.md, "The cycle spec: the balloon's float"): a Sprite3D on the
## low-poly balloon sheet, bobbing on its string to `float` (animations/balloon_float.tres) on
## its own AnimationPlayer. This script is that player's one authority, the only caller of
## its play() and seek().
##   - `colour` (red, yellow or blue) picks its tint and where in the float it starts, so
##     the three don't sway in step. All three share one off-white sheet, the low-poly balloon
##     (assets/sprites/balloon_lowpoly/balloon_lowpoly.png, CHANGE-BRIEF.md's revision of 21 Nov
##     2026), tinted with the Sprite3D's modulate.
##   - pop() is the bite's (camp_balloons.gd, game code): it sets `popped` and plays `pop`
##     (animations/balloon_pop.tres, cells 3-5) once, then hides the balloon when it's done.
## The node's offset puts its origin on the balloon's body: the body sits in the 163 x 204 px
## box at (45, 41) of each 255 x 512 px cell (tools/make_balloon_sheet.gd), so its middle,
## (126.5, 143), is 1 px left of the cell's and 113 px above it; the scene draws the cell 1 px
## right and 113 px lower (offset (1, -113); a Sprite3D's +y offset is up). 0.3 m across the
## body: pixel_size 0.3 / 163. The sheet isn't edited.
## Written by Claude Code on 21 Nov 2026.

## Each colour's tint, from the camp's matte palette: the cooler's red (materials/
## cooler_body.tres), the trail mix's yellow band and the bear bag's blue (camp_bear_bag.gd).
const TINTS := {
	"red": Color("b25d57"),
	"yellow": Color("e2c25a"),
	"blue": Color("2f5d8a"),
}
## Seconds into the 1 s float each colour starts at: a third of the way apart, so at any
## moment no two show the same cell for long.
const FLOAT_OFFSETS := {"red": 0.0, "yellow": 1.0 / 3.0, "blue": 2.0 / 3.0}

@export_enum("red", "yellow", "blue") var colour := "red"
## True once he's bitten it.
var popped := false

@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	modulate = TINTS[colour]
	_anim.play("float")
	_anim.seek(FLOAT_OFFSETS[colour], true)


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
