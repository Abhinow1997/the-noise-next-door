extends Sprite3D
## A party balloon (CHANGE-BRIEF.md, "The cycle spec: the balloon's float"): a Sprite3D on one
## of the balloon sheets, bobbing on its string to `float` (animations/balloon_float.tres) on
## its own AnimationPlayer. This script is that player's one authority, the only caller of
## its play() and seek().
##   - `colour` (red, yellow or blue) picks the sheet and where in the float it starts, so
##     the three at the party don't sway in step.
##   - pop() is the bite's (camp_balloons.gd, game code): it sets `popped` and hides the
##     balloon. (The `pop` clip, cells 3-5, is Step 4's.)
## The node's offset puts its origin on the balloon's body: the body sits in the 14 x 19 px
## box at (1, 1) of each 16 x 32 px cell (assets/sprites/balloons/ATTRIBUTION.md), so its
## middle is 5.5 px above the cell's; the scene draws the cell 5.5 px lower. The sheets
## aren't edited.
## Written by Claude Code on 21 Nov 2026.

const SHEETS := {
	"red": preload("res://assets/sprites/balloons/balloon_red_4.png"),
	"yellow": preload("res://assets/sprites/balloons/balloon_yellow.png"),
	"blue": preload("res://assets/sprites/balloons/balloon_blue_4.png"),
}
## Seconds into the 1 s float each colour starts at: a third of the way apart, so at any
## moment no two show the same cell for long.
const FLOAT_OFFSETS := {"red": 0.0, "yellow": 1.0 / 3.0, "blue": 2.0 / 3.0}

@export_enum("red", "yellow", "blue") var colour := "red"
## True once he's bitten it.
var popped := false

@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	texture = SHEETS[colour]
	_anim.play("float")
	_anim.seek(FLOAT_OFFSETS[colour], true)


## Bitten: gone. Once only.
func pop() -> void:
	if popped:
		return
	popped = true
	hide()
