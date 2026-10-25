extends CanvasLayer
## The party's sound waves, asked for on 25 Oct 2026 with a picture of a man's shouts
## rolling out in curved strokes: "use the noise waves from this img as reference
## distrubing the raccoon and keep giving these waves that help player to understand
## where to go make it minialistic for the waves in the gameplay let these flow from
## the speaker". Two tries in soft glowing crescents weren't liked ("use the drawing
## style we have"), so they're the thought icons' hand-scribbled lines (scribbles.gd
## "waves": three white pen arcs, small to big, boiling like the icons) and sized to
## him as the icons are.
##   - Every EVERY beats while the speaker plays (campsite.gd `beat`), a set pulses
##     (LIFE), fading in and out and swelling a little, at the edge of the screen
##     exactly the way the music is from him, bowed toward him. It stays there: it
##     doesn't come in across the screen to him. Asked for the same day, one step at a
##     time: "make the waves from the edge of the screen when source is not in the
##     picture", "no need for it flow on the raccoon", "still its flowing just have it
##     on the edge", "from where it is coming from". So the edge shows which way to go,
##     however far off the music is, and moves round it as he turns or walks.
##   - Once the speaker is on the screen, they come out of the speaker itself, growing
##     as they go, toward him (stopping SHORT of him) and away on the far side, as the
##     picture's shouts ring the man.
##   - They don't bother him in his sleep: for a while an angry scribble showed over
##     his z's as they reached him, but the author asked for it to go ("remove the
##     irriting when sleeping even tho listing to song dont make the irritated").
## campsite.gd adds it to the level, under the E and the marks over heads (camp_input.gd).

const Scribbles := preload("res://scripts/scribbles.gd")
const Player := preload("res://scripts/player.gd")
const ThoughtBubbles := preload("res://scripts/thought_bubbles.gd")

## A set every EVERY beats, each out for LIFE seconds.
const EVERY := 2
const LIFE := 1.6
## In units of his height on the screen (as the icons are): how far short of him a set
## out of the speaker stops, and how far in from the edge a set at the edge sits (and
## from the corners), so it's all on the screen.
const SHORT := 0.9
const EDGE_IN := 0.7
## Out of the speaker, a set starts this big and grows to full size by him.
const SMALL := 0.45
## The speaker counts as on the screen this far in from its edges (part of its height).
const ON_SCREEN := 0.04
## Where on him they aim (m above his feet).
const HEIGHT := 0.3
## The lines boil as the icons' do (thought_bubble.gd): drawings a second, how many.
const BOIL := 8.0
const BOILS := 3

## Set before it's added (campsite.gd), and once the raccoon's found.
var camp
var player: Player

## The sets out now: how long each has been out (s).
var sets: Array[float] = []
## How many sets have gone out.
var made := 0

var _overlay: Control
var _counting := false
var _last := 0
var _t := 0.0


class Overlay extends Control:
	var owner_layer: Node

	func _draw() -> void:
		owner_layer._draw_on(self)


func _ready() -> void:
	layer = -1
	_overlay = Overlay.new()
	_overlay.owner_layer = self
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


func _process(delta: float) -> void:
	_t += delta
	if camp == null or player == null:
		return
	for i in range(sets.size() - 1, -1, -1):
		sets[i] += delta
		if sets[i] >= LIFE:
			sets.remove_at(i)
	if camp.party and camp.party.playing:
		# The beat can wobble back a hair at a boundary; going back further than that,
		# the music has looped round.
		var n := floori(camp.beat / EVERY)
		if not _counting or n > _last or n < _last - 2:
			_counting = true
			_last = n
			sets.append(0.0)
			made += 1
	else:
		_counting = false
	_overlay.queue_redraw()


## How far he is from the speaker, along the ground (m).
func _away() -> float:
	if camp.party == null:
		return INF
	var speaker: Vector3 = camp.party.global_position
	var him := player.get_global_transform_interpolated().origin - speaker
	return Vector2(him.x, him.z).length()


## Where the sets go on the screen now, or {} if he's not on it:
##   him      where he is
##   from     where they start: the speaker, if it's on the screen, or the edge of the
##            screen the way the speaker is from him
##   way      which way they roll (a unit vector), toward him
##   reach    how far they roll out of the speaker, to SHORT of him (pixels)
##   speaker  true if they come from the speaker itself
func route(camera: Camera3D) -> Dictionary:
	if camp.party == null:
		return {}
	var him_at := player.get_global_transform_interpolated().origin + Vector3.UP * HEIGHT
	if camera.is_position_behind(him_at):
		return {}
	var speaker: Vector3 = camp.party.global_position
	var him := camera.unproject_position(him_at)
	var view := get_viewport().get_visible_rect()
	var unit := _unit()
	var from := Vector2.ZERO
	var on_screen := false
	if not camera.is_position_behind(speaker):
		from = camera.unproject_position(speaker)
		on_screen = view.grow(-view.size.y * ON_SCREEN).has_point(from)
	if not on_screen:
		from = _edge(view, him.clamp(view.position, view.end), _toward(camera, him_at, speaker, him))
	var out := him - from
	var way := out.normalized() if out.length() > 1.0 else -_toward(camera, him_at, speaker, him)
	return {"him": him, "from": from, "way": way, "reach": maxf(out.length() - SHORT * unit, 0.0),
		"speaker": on_screen}


## Which way the speaker is from him on the screen (a unit vector).
func _toward(camera: Camera3D, him_at: Vector3, speaker: Vector3, him: Vector2) -> Vector2:
	var way := Vector3(speaker.x - him_at.x, 0.0, speaker.z - him_at.z)
	if way.length() > 0.01 and not camera.is_position_behind(him_at + way.normalized()):
		var step := camera.unproject_position(him_at + way.normalized()) - him
		if step.length() > 0.001:
			return step.normalized()
	return Vector2.UP


## Where a line from `at`, inside `view`, going `dir`, leaves it.
static func _edge(view: Rect2, at: Vector2, dir: Vector2) -> Vector2:
	var t := INF
	if dir.x > 0.0001:
		t = minf(t, (view.end.x - at.x) / dir.x)
	elif dir.x < -0.0001:
		t = minf(t, (view.position.x - at.x) / dir.x)
	if dir.y > 0.0001:
		t = minf(t, (view.end.y - at.y) / dir.y)
	elif dir.y < -0.0001:
		t = minf(t, (view.position.y - at.y) / dir.y)
	return at + dir * (t if t < INF else 0.0)


## His height on the screen, as the thought icons are sized.
func _unit() -> float:
	var bubbles := ThoughtBubbles.find(self)
	if bubbles:
		return bubbles._unit
	return 90.0 * get_viewport().get_visible_rect().size.y / 720.0


func _draw_on(canvas: Control) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or player == null or camp == null or sets.is_empty():
		return
	var way := route(camera)
	if way.is_empty():
		return
	var unit := _unit()
	var list := Scribbles.strokes("waves", int(_t * BOIL) % BOILS, 0)
	var from: Vector2 = way.from
	var dir: Vector2 = way.way
	for age: float in sets:
		var f := age / LIFE
		var alpha := pow(sin(PI * f), 0.7)
		if way.speaker:
			# Out of the speaker, growing as it goes: toward him, and away on the far side.
			var gone: float = way.reach * f
			var grow := lerpf(SMALL, 1.0, f)
			Scribbles.draw(canvas, list, from + dir * gone, unit * grow, dir.angle(), alpha)
			Scribbles.draw(canvas, list, from - dir * gone, unit * grow, dir.angle() + PI, alpha)
		else:
			# At the edge of the screen the music's coming from, pulsing where it is.
			var view := canvas.get_rect()
			var at := (from + dir * EDGE_IN * unit).clamp(view.position + Vector2.ONE * EDGE_IN * unit,
				view.end - Vector2.ONE * EDGE_IN * unit)
			Scribbles.draw(canvas, list, at, unit * lerpf(0.85, 1.05, f), dir.angle(), alpha)
