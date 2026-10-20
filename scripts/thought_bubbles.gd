extends Node
## Thought icons that tell the player what the raccoon notices, wants or feels, without
## words, drawn as loose hand-scribbled lines over the game (scribbles.gd draws them,
## thought_bubble.gd animates one):
##   shiny       sparkles over loot he could steal while he's within 5 m of it: anything
##               in the "shiny" group he hasn't picked up yet. They sit over the loot,
##               once for loot lying together.
##   hungry      a scribbled thought with a fish skeleton (or an apple core) in it while
##               he faces food or a trash bin up close (the "food" group), and now and
##               again while the level wants him to find food (hungry_objective)
##   alert       a crooked red "!" while an NPC can see him (vision_cone.gd)
##   hiding      z's floating up off a hiding spot (hide_spot.gd) he's just slipped into
##               with an NPC about; they go after 2 seconds
##   idea        a yellow bulb when he picks up the very thing a puzzle near him needs
##               (the "puzzle" group, whose "needs" meta names a group the thing is in),
##               and when a puzzle is solved (its "solved" meta turns true)
##   frustrated  an angry white spiral with dark scribble clouds when something fails:
##               he's stuck pushing against something, a locked door, an NPC took his
##               loot back. Things in the level show it with ThoughtBubbles.notify(self,
##               "frustrated"), as anything that soaks him with water should.
##   bored       a round thought with a bored face in it, and a sigh puffing out of his
##               mouth, while he's bored: standing still long enough for the bored pose
##               (raccoon_model.gd BORED_AFTER)
## Over his head only one shows at a time, the most urgent; when it ends, one still
## wanted shows. The sparkles are over the loot, so they can show alongside.
## Other meta it reads: "found" (set once he's picked a thing up), "bubble_range" (a
## range of a thing's own) and "bubble_icon" (a food's own picture: "fish" or "apple").

## The icon over his head changed: its kind, or "" when there's none.
signal shown(kind: String)
## Some loot has started to glint.
signal glinted(loot: Node3D)

const Player := preload("res://scripts/player.gd")
const Bubble := preload("res://scripts/thought_bubble.gd")
const HideSpot := preload("res://scripts/hide_spot.gd")
const VisionCone := preload("res://scripts/vision_cone.gd")

## The icons over his head: rank (the higher one wins), picture, and how long it stays
## up, in seconds, unless it's asked for again. Frustrated outranks alert, so losing
## his loot to an NPC who's looking at him still shows.
const KINDS := {
	"frustrated": {"rank": 6, "icon": "scribble", "hold": 1.8},
	"alert": {"rank": 5, "icon": "alert", "hold": 0.4},
	"hiding": {"rank": 4, "icon": "zzz", "hold": 2.0},
	"idea": {"rank": 3, "icon": "bulb", "hold": 2.2},
	"hungry": {"rank": 2, "icon": "fish", "hold": 3.0},
	"bored": {"rank": 1, "icon": "bored", "hold": 0.3},
}
## Kinds asked for on every tick while what causes them lasts; asking again doesn't
## pop them once more.
const HELD_UP := ["alert", "hungry", "bored"]
## Loot glints within SHINY_RANGE metres, and keeps glinting until he's RANGE_SLACK
## further away.
const SHINY_RANGE := 5.0
const RANGE_SLACK := 1.0
## Loot this close together (metres) glints as one.
const GLINT_APART := 1.2
## Food counts while it's this close (metres) and no more than FACING degrees to
## either side of straight ahead; the icon stays FOOD_HOLD seconds after he turns away.
const FOOD_RANGE := 2.5
const FACING := 50.0
const FOOD_HOLD := 0.6
## How near a puzzle has to be for its key to give him an idea, and how long before
## picking the same thing up again can give it again.
const IDEA_RANGE := 8.0
const IDEA_AGAIN := 8.0
## Hiding is hiding from someone: it shows only with an NPC this near, or after being
## seen this recently (seconds).
const WATCHER_NEAR := 20.0
const SEEN_RECENTLY := 3.0
## Seconds between reminders while the level wants him to find food.
const HUNGRY_REMIND := 25.0
## Stuck: pushing a move key for this long while getting nowhere (slower than
## STUCK_SPEED, m/s). Once a push.
const STUCK_TIME := 1.2
const STUCK_SPEED := 0.25
## Where his icons hang: over the middle of his back, in his own space, and LIFT above
## it; and his height, which sets their size. All in metres at size 0.8.
const HEAD := Vector3(0, 0.3, -0.1)
const LIFT := 0.42
const HEIGHT := 0.61
## When his head is up (sitting up bored, climbing), they hang at least this far above
## his mouth instead, in metres at size 0.8.
const MOUTH_CLEAR := 0.4
## The sigh comes out of his mouth, but at least this far (units) to the side of where
## his icons hang, on the side he faces, so it never runs across the bored thought.
const SIGH_BESIDE := 0.17
## The icons' size (his height on screen, pixels on a 720-pixel-tall screen) is kept
## between these, so they stay readable however far the camera zooms.
const UNIT_MIN := 60.0
const UNIT_MAX := 150.0
## How far above the loot its sparkles' base is, in metres.
const GLINT_LIFT := 0.03

## Set by the level.
var player: Player
var camera: Camera3D
## Set by the level while one of its tasks is to find food.
var hungry_objective := false: set = set_hungry_objective

var _layer: CanvasLayer
var _bubble: Bubble
## The sigh out of his mouth, while the bored thought is up.
var _sigh: Bubble
## Each icon wanted over his head now, and when it stops being wanted (on _time).
var _until := {}
var _icons := {}
var _shown := ""
var _shown_icon := ""
var _time := 0.0
## The loot glinting now: thing -> its sparkles.
var _glints := {}
var _held: Node3D
var _hidden := false
## The hiding spot the z's float up from.
var _cover: Node3D
var _last_seen := -INF
var _remind := 0.0
var _idea_at := {}
var _solved := {}
var _stuck := 0.0
var _stuck_armed := true
var _unit := 90.0


func _ready() -> void:
	add_to_group("thought_bubbles")
	if player:
		player.add_to_group("player")
	_layer = CanvasLayer.new()
	# Under the level's own UI: the to-do list, the hints and the pause.
	_layer.layer = 0
	add_child(_layer)
	_bubble = Bubble.new()
	_layer.add_child(_bubble)
	_sigh = Bubble.new()
	_layer.add_child(_sigh)


## Shows icon `kind` over his head for `hold` seconds (its own time when left out),
## with picture `icon` instead of its usual one if given. Asked for again while it's
## up, it stays up longer and pops once more.
func pop(kind: String, hold := -1.0, icon := "") -> void:
	if not KINDS.has(kind):
		push_warning("There's no thought icon called %s" % kind)
		return
	var info: Dictionary = KINDS[kind]
	var again: bool = _shown == kind and _until.get(kind, -INF) > _time
	_until[kind] = maxf(_until.get(kind, -INF), _time + (hold if hold >= 0.0 else float(info.hold)))
	_icons[kind] = icon if icon != "" else String(info.icon)
	if again and kind not in HELD_UP and _icons[kind] == _shown_icon:
		_bubble.bump()


## Ends icon `kind` early.
func clear(kind: String) -> void:
	_until.erase(kind)


## The kind of icon over his head, or "" when there's none.
func showing() -> String:
	return _shown


## The loot glinting now.
func glinting() -> Array:
	return _glints.keys()


## The level's thought icons, if it has them.
static func find(from: Node) -> Node:
	if not from.is_inside_tree():
		return null
	return from.get_tree().get_first_node_in_group("thought_bubbles")


## Shows icon `kind` over his head, from anywhere in the level; does nothing if the
## level has no thought icons.
static func notify(from: Node, kind: String) -> void:
	var bubbles := find(from)
	if bubbles:
		bubbles.pop(kind)


func set_hungry_objective(on: bool) -> void:
	if on and not hungry_objective:
		_remind = 0.0
	hungry_objective = on


# The triggers run on physics ticks, with the raccoon and the NPCs.
func _physics_process(delta: float) -> void:
	_time += delta
	if player == null:
		return
	_watch_mouth()
	_watch_loot()
	_watch_food()
	_watch_sight()
	_watch_hiding()
	_watch_puzzles()
	_watch_stuck(delta)
	_watch_hunger(delta)
	_watch_bored()
	_choose()


# The icons follow where things are drawn, between ticks, so they stay put on a fast
# screen; and they're sized to him.
func _process(_delta: float) -> void:
	if player == null or camera == null:
		return
	var k := player.size / 0.8
	var drawn := player.get_global_transform_interpolated()
	var mouth := drawn * (player.global_transform.affine_inverse() * player.model.mouth.global_position)
	var head := drawn * (HEAD * k) + Vector3.UP * LIFT * k
	head.y = maxf(head.y, mouth.y + MOUTH_CLEAR * k)
	var screen := get_viewport().get_visible_rect().size.y
	var away := maxf(camera.global_position.distance_to(head), 0.1)
	var per_metre := screen / (2.0 * away * tan(deg_to_rad(camera.fov) * 0.5))
	_unit = clampf(HEIGHT * k * per_metre, UNIT_MIN * screen / 720.0, UNIT_MAX * screen / 720.0)
	var over := head
	if _shown == "hiding" and is_instance_valid(_cover):
		over = _cover.top()
	_place(_bubble, over)
	# Bored, his thought and his sigh face the way he faces on the screen.
	var left := camera.unproject_position(drawn.origin - drawn.basis.z).x < camera.unproject_position(drawn.origin).x
	_bubble.flip = left and _shown == "bored"
	_sigh.flip = left
	_place(_sigh, mouth)
	var side := -1.0 if left else 1.0
	if (_sigh.anchor.x - _bubble.anchor.x) * side < SIGH_BESIDE * _unit:
		_sigh.anchor.x = _bubble.anchor.x + side * SIGH_BESIDE * _unit
	# Untyped, as a bit of loot may have been freed since the last tick.
	for loot in _glints:
		if is_instance_valid(loot):
			_place(_glints[loot], (loot as Node3D).get_global_transform_interpolated().origin + Vector3.UP * GLINT_LIFT)


func _place(icon: Bubble, point: Vector3) -> void:
	icon.visible = not camera.is_position_behind(point)
	icon.anchor = camera.unproject_position(point)
	icon.unit = _unit


## Something new in his mouth: he's found it, and if it's what a puzzle near him needs,
## he has an idea.
func _watch_mouth() -> void:
	var held: Node3D = player.held
	if held == _held:
		return
	_held = held
	if held == null:
		return
	held.set_meta("found", true)
	if _time < float(_idea_at.get(held.get_instance_id(), -INF)) + IDEA_AGAIN:
		return
	for node: Node in get_tree().get_nodes_in_group("puzzle"):
		var puzzle := node as Node3D
		var needs: String = puzzle.get_meta("needs", "")
		if needs == "" or puzzle.get_meta("solved", false) or not held.is_in_group(needs):
			continue
		if puzzle.global_position.distance_to(player.global_position) <= float(puzzle.get_meta("bubble_range", IDEA_RANGE)):
			_idea_at[held.get_instance_id()] = _time
			pop("idea")
			return


## Sparkles over the loot he's near and hasn't found, until he's well away. Loot lying
## together glints once, over whichever bit of it he came near first.
func _watch_loot() -> void:
	var here := player.global_position
	var wanted: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group("shiny"):
		var loot := node as Node3D
		if loot == null or player.resting or loot == player.held or loot.get_meta("found", false) or not loot.is_visible_in_tree():
			continue
		var reach := float(loot.get_meta("bubble_range", SHINY_RANGE)) + (RANGE_SLACK if _glints.has(loot) else 0.0)
		if loot.global_position.distance_to(here) <= reach:
			wanted.append(loot)
	# Untyped, as a bit of loot may have been freed since the last tick.
	for loot in _glints.keys():
		if not is_instance_valid(loot) or not loot in wanted:
			_glints[loot].hide_icon()
			_glints.erase(loot)
	wanted.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(here) < b.global_position.distance_squared_to(here))
	for loot: Node3D in wanted:
		if _glints.has(loot) or _glint_near(loot.global_position):
			continue
		var sparkles := Bubble.new()
		sparkles.free_when_gone = true
		_layer.add_child(sparkles)
		_place(sparkles, loot.global_position + Vector3.UP * GLINT_LIFT)
		sparkles.show_icon("sparkles")
		_glints[loot] = sparkles
		glinted.emit(loot)


## True if some loot within GLINT_APART of `point` is glinting already.
func _glint_near(point: Vector3) -> bool:
	for other in _glints:
		if is_instance_valid(other) and (other as Node3D).global_position.distance_to(point) < GLINT_APART:
			return true
	return false


## Facing food or a trash bin up close, he thinks of food.
func _watch_food() -> void:
	if player.resting or player.climbing:
		return
	var here := player.global_position
	var ahead := -player.global_basis.z
	ahead.y = 0.0
	for node: Node in get_tree().get_nodes_in_group("food"):
		var food := node as Node3D
		if food == null or food == player.held or food.get_meta("found", false) or not food.is_visible_in_tree():
			continue
		var to := food.global_position - here
		to.y = 0.0
		if to.length() > float(food.get_meta("bubble_range", FOOD_RANGE)):
			continue
		if to.length() > 0.3 and rad_to_deg(ahead.angle_to(to)) > FACING:
			continue
		pop("hungry", FOOD_HOLD, food.get_meta("bubble_icon", ""))
		return


## The alert stays up while any NPC sees him (vision_cone.gd), and a moment after.
func _watch_sight() -> void:
	if VisionCone.hidden(player):
		return
	for watcher: Node in get_tree().get_nodes_in_group("watcher"):
		if watcher.seeing and watcher.target == player:
			_last_seen = _time
			pop("alert")
			return


## Slipping into a hiding spot with an NPC about, or just after being seen, ends the
## alert and floats z's up off the spot.
func _watch_hiding() -> void:
	var cover := HideSpot.cover_for(player)
	var hidden := cover != null
	if hidden and not _hidden and (_time - _last_seen < SEEN_RECENTLY or _watcher_near()):
		clear("alert")
		_cover = cover
		pop("hiding")
	_hidden = hidden


func _watcher_near() -> bool:
	for watcher: Node in get_tree().get_nodes_in_group("watcher"):
		if (watcher as Node3D).global_position.distance_to(player.global_position) < WATCHER_NEAR:
			return true
	return false


## A puzzle solved: a bright idea.
func _watch_puzzles() -> void:
	for node: Node in get_tree().get_nodes_in_group("puzzle"):
		var solved: bool = node.get_meta("solved", false)
		var id := node.get_instance_id()
		if solved and not _solved.get(id, false):
			pop("idea")
		_solved[id] = solved


## Pushing against something and getting nowhere.
func _watch_stuck(delta: float) -> void:
	var pushing := Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.5
	var walking := not (player.resting or player.climbing or player.is_hopping())
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	if pushing and walking and speed < STUCK_SPEED:
		_stuck += delta
		if _stuck >= STUCK_TIME and _stuck_armed:
			_stuck_armed = false
			pop("frustrated")
		return
	_stuck = 0.0
	if not pushing or speed > 2.0 * STUCK_SPEED:
		_stuck_armed = true


## Bored: the same wait for it as the model's bored pose.
func _watch_bored() -> void:
	if not player.resting and player.model._still > player.model.BORED_AFTER:
		pop("bored")


func _watch_hunger(delta: float) -> void:
	if not hungry_objective:
		return
	_remind -= delta
	if _remind <= 0.0:
		_remind = HUNGRY_REMIND
		if not player.resting:
			pop("hungry")


## Puts the most urgent icon that's still wanted over his head, or none.
func _choose() -> void:
	var best := ""
	for kind: String in _until.keys():
		if _until[kind] <= _time:
			_until.erase(kind)
		elif best == "" or KINDS[kind].rank > KINDS[best].rank:
			best = kind
	var icon: String = _icons.get(best, "")
	if best == _shown and icon == _shown_icon:
		return
	_shown = best
	_shown_icon = icon
	if best == "":
		_bubble.hide_icon()
	else:
		_bubble.show_icon(icon)
	if best == "bored":
		_sigh.show_icon("sigh")
	else:
		_sigh.hide_icon()
	shown.emit(best)
