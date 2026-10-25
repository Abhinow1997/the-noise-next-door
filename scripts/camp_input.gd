extends CanvasLayer
## The campsite's E and the marks over heads, added on 23 Oct 2026 with level 1's
## first tasks. campsite.gd adds it to the level after the raccoon, so it hears an E
## press before he does: next to something he can use (interactable.gd), the press goes
## to that instead of grabbing or dropping.
## It also draws, in the thought bubbles' ink (scribbles.gd):
##   - a chalk E over the nearest thing he can use, and a ring round it filling while he
##     holds E at it (and running back while he doesn't);
##   - over the campers' heads (camp_person.gd): a "?" while one is wondering about a
##     noise, and the red "!" when one has just spotted him or is chasing him.

const Scribbles := preload("res://scripts/scribbles.gd")
const Interactable := preload("res://scripts/interactable.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const Player := preload("res://scripts/player.gd")
const FONT := preload("res://assets/fonts/PatrickHand-Regular.ttf")

## Sizes, as parts of the screen's height: the E's ring, and the marks.
const RING := 0.022
const MARK := 0.03
## How high over their feet the marks float (m), and how long the "!" stays after a fright.
const OVER_HEAD := 2.05
const ALERT_FOR := 1.6

## Set before it's added.
var camp: Node
var player: Player

var _overlay: Control
var _t := 0.0


class Overlay extends Control:
	var owner_layer: Node

	func _draw() -> void:
		owner_layer._draw_on(self)


func _ready() -> void:
	layer = 0
	_overlay = Overlay.new()
	_overlay.owner_layer = self
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


func _unhandled_input(event: InputEvent) -> void:
	if player == null or not event.is_action_pressed("grab") or event.is_echo():
		return
	var spot := _nearest()
	if spot:
		spot.press(player)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_t += delta
	_overlay.queue_redraw()


## The nearest thing he can use right now, or null.
func _nearest() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	if player == null:
		return null
	for node in get_tree().get_nodes_in_group("interactable"):
		var spot := node as Interactable
		if spot == null or not spot.usable_by(player):
			continue
		var d := spot.global_position.distance_to(player.model.mouth.global_position)
		if d < best_d:
			best_d = d
			best = spot
	return best


func _draw_on(canvas: Control) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or player == null:
		return
	var unit := canvas.size.y
	var near := _nearest()
	for node in get_tree().get_nodes_in_group("interactable"):
		var spot := node as Interactable
		if spot == null:
			continue
		var showing := spot == near or (spot.progress > 0.0 and spot.progress < 1.0)
		var at := spot.global_position + Vector3.UP * spot.prompt_height
		if not showing or camera.is_position_behind(at):
			continue
		var p := camera.unproject_position(at)
		var r := unit * RING
		canvas.draw_circle(p, r * 1.15, Scribbles.SHADOW)
		canvas.draw_circle(p, r, Color(Scribbles.DARK, 0.75))
		if spot.hold_time > 0.0 and spot.progress > 0.0:
			canvas.draw_arc(p, r * 1.05, -PI / 2, -PI / 2 + TAU * spot.progress, 32, Scribbles.SPARKLE, r * 0.28)
		if spot == near:
			var size := int(r * 1.4)
			var line := FONT.get_string_size("E", HORIZONTAL_ALIGNMENT_CENTER, -1, size)
			canvas.draw_string(FONT, p + Vector2(-line.x * 0.5, size * 0.33), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, size,
				Scribbles.WHITE)
	if camp == null:
		return
	for person: CampPerson in camp.people:
		var head := person.global_position + Vector3.UP * OVER_HEAD
		if camera.is_position_behind(head):
			continue
		var p := camera.unproject_position(head)
		if person.state == CampPerson.State.INVESTIGATE:
			var size := int(unit * MARK * 1.6)
			var bob := sin(_t * 4.0 + person.get_instance_id()) * unit * 0.004
			var line := FONT.get_string_size("?", HORIZONTAL_ALIGNMENT_CENTER, -1, size)
			var at := p + Vector2(-line.x * 0.5, bob)
			canvas.draw_string_outline(FONT, at, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, size, int(size * 0.18),
				Scribbles.DARK)
			canvas.draw_string(FONT, at, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Scribbles.WHITE)
		elif person.alarmed_for() < ALERT_FOR or person.state == CampPerson.State.CHASE:
			Scribbles.draw(canvas, Scribbles.strokes("alert", int(_t * 8.0) % 3, 0), p, unit * MARK * 1.6)
