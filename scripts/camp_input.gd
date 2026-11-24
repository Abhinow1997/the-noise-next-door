extends CanvasLayer
## The campsite's E and the marks over heads, added on 23 Oct 2026 with level 1's
## first tasks. campsite.gd adds it to the level after the raccoon, so it hears an E
## press before he does: next to something he can use (interactable.gd), the press goes
## to that instead of grabbing or dropping.
## It also draws, in the thought bubbles' ink (scribbles.gd):
##   - a chalk E over the nearest thing he can use, and a ring round it filling while he
##     holds E at it (and running back while he doesn't);
##   - since 23 Nov 2026, while he's in the keeper's box, its two keys over it, each a chalk key in a
##     ring with what it does beside it (camp_box.gd `prompts`): F to make a noise, E to jump out;
##   - over the campers' heads (camp_person.gd): a "?" while one is wondering about a
##     noise or confused after he's got away (it was "??" for that till 10 Nov 2026: the
##     author, "with the '?' sign over the head"), and the "!" when one has just spotted
##     him or is chasing him.

const Scribbles := preload("res://scripts/scribbles.gd")
const Interactable := preload("res://scripts/interactable.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const KeeperBox := preload("res://scripts/keeper_box.gd")
const Player := preload("res://scripts/player.gd")
const FONT := preload("res://assets/fonts/PatrickHand-Regular.ttf")

## Sizes, as parts of the screen's height: the E's ring, and the marks.
const RING := 0.022
const MARK := 0.03
## How high over their feet the marks float (m), and how long the "!" stays after a fright.
const OVER_HEAD := 2.05
const ALERT_FOR := 1.6
## The keeper's box's keys: how high over its top they show (m), how far apart their rows are (in
## rings), how big their words are against the key, and how faint a key is till it can be used again.
const BOX_KEYS_UP := 0.35
const BOX_KEY_ROWS := 2.7
const BOX_KEY_WORDS := 1.05
const BOX_KEY_DIM := 0.4

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
	_draw_box_keys(canvas, camera, unit)
	for person: CampPerson in camp.people:
		var head := person.global_position + Vector3.UP * OVER_HEAD
		if camera.is_position_behind(head):
			continue
		var p := camera.unproject_position(head)
		if person.state in [CampPerson.State.INVESTIGATE, CampPerson.State.SEARCH]:
			var mark := "?"
			var size := int(unit * MARK * 1.6)
			var bob := sin(_t * 4.0 + person.get_instance_id()) * unit * 0.004
			var line := FONT.get_string_size(mark, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
			var at := p + Vector2(-line.x * 0.5, bob)
			canvas.draw_string_outline(FONT, at, mark, HORIZONTAL_ALIGNMENT_LEFT, -1, size, int(size * 0.18),
				Scribbles.DARK)
			canvas.draw_string(FONT, at, mark, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Scribbles.WHITE)
		elif person.alarmed_for() < ALERT_FOR or person.state == CampPerson.State.CHASE:
			Scribbles.draw(canvas, Scribbles.strokes("alert", int(_t * 8.0) % 3, 0), p, unit * MARK * 1.6)


## While he's in the keeper's box (camp_box.gd `prompts`): its keys over it, a row each, centred on
## it: the key in its ring as the E's, and what it does beside it.
func _draw_box_keys(canvas: Control, camera: Camera3D, unit: float) -> void:
	var task = camp.get("box_task")
	if task == null:
		return
	var rows: Array = task.prompts()
	if rows.is_empty():
		return
	var at: Vector3 = task.box.global_position + Vector3.UP * (KeeperBox.SIZE.y + BOX_KEYS_UP)
	if camera.is_position_behind(at):
		return
	var r := unit * RING
	var key_size := int(r * 1.4)
	var word_size := int(key_size * BOX_KEY_WORDS)
	var top := camera.unproject_position(at) - Vector2(0.0, r * BOX_KEY_ROWS * (rows.size() - 1))
	for i in rows.size():
		var row: Dictionary = rows[i]
		var fade: float = 1.0 if row.ready else BOX_KEY_DIM
		var words := FONT.get_string_size(row.text, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size)
		var width := r * 2.0 + r * 0.6 + words.x
		var p := top + Vector2(-width * 0.5 + r, r * BOX_KEY_ROWS * i)
		canvas.draw_circle(p, r * 1.15, Color(Scribbles.SHADOW, Scribbles.SHADOW.a * fade))
		canvas.draw_circle(p, r, Color(Scribbles.DARK, 0.75 * fade))
		var key := FONT.get_string_size(row.key, HORIZONTAL_ALIGNMENT_CENTER, -1, key_size)
		canvas.draw_string(FONT, p + Vector2(-key.x * 0.5, key_size * 0.33), row.key, HORIZONTAL_ALIGNMENT_LEFT, -1,
			key_size, Color(Scribbles.WHITE, fade))
		var word_at := p + Vector2(r * 1.6, word_size * 0.33)
		canvas.draw_string_outline(FONT, word_at, row.text, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size,
			int(word_size * 0.18), Color(Scribbles.DARK, fade))
		canvas.draw_string(FONT, word_at, row.text, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size, Color(Scribbles.WHITE, fade))
