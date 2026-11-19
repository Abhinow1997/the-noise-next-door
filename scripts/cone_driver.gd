extends Node
## Sets the camp's cones' shader (shaders/vision_cone.gdshader, the author's) every frame
## from the game's state, as CHANGE-BRIEF.md's Assignment 5 rules say (with their 28 and
## 29 Oct revisions). It only reads the camp's `clock`, `spotted_at` and `spotters`, and
## whether each cone is drawn, and only writes each cone's `alarm` and `shown`:
##   - `alarm` 1 on the cones of whoever has spotted him, from that moment until the
##     cones have gone (the red, then its fade); 0 on every other cone;
##   - `shown` 1 through the red, then down to 0 over FADE_OUT, from RED_TIME after the
##     latest spotting; when a cone comes back after its BACK_AFTER, up from 0 to 1 over
##     FADE_OUT, from the moment the game shows it again (camp_person.gd). A spotting
##     snaps it back to 1 at once, faded or gone. The cones that show once the tutorial
##     is done (before anyone's spotted him) just appear.
##   - Since 11 Nov 2026, outside the red and its fade, `shown` is also taken down to 0
##     over FADE_OUT while its person is by the fire burning high (campsite.gd
##     `by_fire_up`), and back up over FADE_OUT once they aren't.
##   - And the same day, outside the red and its fade, every cone follows how he moves
##     (the author: "cones should be visiable when he is trying to sneek and hide but fade
##     if he is running around and moving around especially when near the npcs"): up to
##     full over FADE_OUT while he sneaks or is hidden, down to 0 over STEALTH_OUT while
##     he moves about upright (walking, running, jumping), and as it was while he stands
##     still or climbs, so stopping and starting doesn't make them blink. Before he's
##     moved at all they show. A spotting still shows red, whatever he's doing.
## Everything is worked out on the camp's clock, which runs on game time: so it holds
## still while paused and follows Engine.time_scale, with no timer of its own. Added by
## campsite.gd; it runs in _process, after the frame's physics ticks.

const VisionCone := preload("res://scripts/vision_cone.gd")
## Moving upright, the cones fade out over this long (s); and faster than this (m/s along
## the ground) counts as moving.
const STEALTH_OUT := 1.0
const MOVING := 0.3

var camp

## For each person, the camp's clock when their cone came back, or INF while it hasn't.
var _back_since := {}
## For each person, how much (1..0) of their cone the fire leaves showing (by_fire_up);
## and the camp's clock last frame, to fade it by.
var _by_fire := {}
var _last := 0.0
## How much (1..0) of every cone his moving leaves showing, and the raccoon.
var _stealth := 1.0
var _player


func _ready() -> void:
	for person in camp.people:
		person.eyes.driven = true
		_back_since[person] = INF
		_by_fire[person] = 0.0 if camp.by_fire_up(person.global_position) else 1.0
	_last = camp.clock
	_process(0.0)


func _process(_delta: float) -> void:
	var now: float = camp.clock
	var until: float = camp.cones_shown_until()
	var step := now - _last
	_last = now
	_stealth = move_toward(_stealth, _stealth_wanted(), step / (VisionCone.FADE_OUT if _stealth_wanted() > _stealth
		else STEALTH_OUT))
	for person in camp.people:
		var fire: float = 0.0 if camp.by_fire_up(person.global_position) else 1.0
		_by_fire[person] = move_toward(_by_fire[person], fire, step / VisionCone.FADE_OUT)
		var alarm := 0.0
		var shown := 1.0
		if now < until:
			alarm = 1.0 if person in camp.spotters else 0.0
			shown = clampf((until - now) / VisionCone.FADE_OUT, 0.0, 1.0)
			_back_since[person] = INF
		elif not person.eyes.showing():
			shown = 0.0
			_back_since[person] = INF
		elif camp.spotted_at > -INF:
			# Back after its BACK_AFTER: the fade-in, from the moment the game showed it.
			# Only a spotting hides the cones, so before any, a cone that shows is the
			# tutorial's, and just appears.
			if _back_since[person] == INF:
				_back_since[person] = now
			shown = clampf((now - _back_since[person]) / VisionCone.FADE_OUT, 0.0, 1.0)
		if now >= until:
			shown *= _by_fire[person] * _stealth
		person.eyes.set_look(alarm, shown)


## How much of every cone his moving should leave showing: all while he sneaks or is
## hidden, none while he moves about upright, and as much as now otherwise.
func _stealth_wanted() -> float:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return _stealth
	if _player.sneaking or _player.hiding_in != null:
		return 1.0
	var moving := Vector2(_player.velocity.x, _player.velocity.z).length() > MOVING
	if (moving or _player.jumping) and not _player.climbing:
		return 0.0
	return _stealth
