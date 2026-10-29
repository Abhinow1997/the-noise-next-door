extends Node
## Sets the camp's cones' shader (shaders/vision_cone.gdshader, the author's) every frame
## from the game's state, as CHANGE-BRIEF.md's Assignment 5 rules say (with their 28 and
## 29 Oct revisions). It only reads the camp's `clock`, `spotted_at` and `spotters` and
## each person's `cone_back_at()`, and only writes each cone's `alarm` and `shown`:
##   - `alarm` 1 on the cones of whoever has spotted him, from that moment until the
##     cones have gone (the red, then its fade); 0 on every other cone;
##   - `shown` 1 through the red, then down to 0 over FADE_OUT, from RED_TIME after the
##     latest spotting; when a cone comes back after its BACK_AFTER, up from 0 to 1 over
##     FADE_OUT, from the moment the game shows it again (camp_person.gd). A spotting
##     snaps it back to 1 at once, faded or gone. The cones that show once the tutorial
##     is done (before anyone's spotted him, so no `cone_back_at()`) just appear.
## Everything is worked out on the camp's clock, which runs on game time: so it holds
## still while paused and follows Engine.time_scale, with no timer of its own. Added by
## campsite.gd; it runs in _process, after the frame's physics ticks.

const VisionCone := preload("res://scripts/vision_cone.gd")

var camp

## For each person, the camp's clock when their cone came back, or INF while it hasn't.
var _back_since := {}


func _ready() -> void:
	for person in camp.people:
		person.eyes.driven = true
		_back_since[person] = INF
	_process(0.0)


func _process(_delta: float) -> void:
	var now: float = camp.clock
	var until: float = camp.cones_shown_until()
	for person in camp.people:
		var alarm := 0.0
		var shown := 1.0
		if now < until:
			alarm = 1.0 if person in camp.spotters else 0.0
			shown = clampf((until - now) / VisionCone.FADE_OUT, 0.0, 1.0)
			_back_since[person] = INF
		elif not person.eyes.showing():
			shown = 0.0
			_back_since[person] = INF
		elif person.cone_back_at() > -INF:
			# Back after its BACK_AFTER: the fade-in, from the moment the game showed it.
			if _back_since[person] == INF:
				_back_since[person] = now
			shown = clampf((now - _back_since[person]) / VisionCone.FADE_OUT, 0.0, 1.0)
		person.eyes.set_look(alarm, shown)
