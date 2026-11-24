extends Area3D
## A place the raccoon can hide in: a bush, a dumpster, a patch of shadow. While he's
## inside one, NPCs can't see him (vision_cone.gd), and slipping into one with an NPC
## about floats z's up off its top (thought_bubbles.gd). Give it a CollisionShape3D
## the size of the hiding place. In a shadow he only counts as hidden while he sneaks,
## so set `needs_sneak` there.
## Since 7 Nov 2026, when the author found hiding "clunky", a spot can have `dive` on
## (the camp's bush, campsite.gd): walking into it, he dives right in (player.gd
## `dive_into`) and vanishes; its `leaves` rustle as he goes in and out, and his eyes
## peek out of it, blinking, while he's in.

## He's dived in (true) or come out (false), from `dived()`: for presentation to follow
## (the leaf burst, leaf_bursts.gd; CHANGE-BRIEF.md, revised 7 Nov 2026). Nothing in the
## game listens to it.
signal hiding_changed(inside: bool)

@export var needs_sneak := false
## How tall the hiding place is, in metres: the z's float up from its top.
@export var height := 1.0
## He dives right into it (above).
@export var dive := false
## How far from its middle, straight toward the camera, his eyes peek out (m): just
## outside its leaves on the side the player sees.
@export var peek_out := 0.9
## For the keeper's box (keeper_box.gd, 23 Nov 2026, after play: "the eyes look off when he is in
## it"), whose eyes peek out of the gap under its lifted edge:
##   - `own_eyes`: what it belongs to places his eyes (`eyes()`), not this;
##   - `hold_eyes`: while true they stay in (while the gap's shut, or the box is carried);
##   - `eye_scale`: how big they are against the bush's.
var own_eyes := false
var hold_eyes := false
var eye_scale := 1.0
## He's in it: dived in and not out again.
var occupied := false

## What rustles as he dives in and out (set before it's added).
var leaves: Node3D

## The physics layer a closed spot's wall is on: the raccoon alone runs into it
## (player.gd), so the people and loose things go about as ever. Nothing else uses it.
const CLOSED_LAYER := 1 << 9
## The wall stands a little outside the spot, so he can't be touching the spot itself
## when it opens again.
const WALL_SCALE := 1.1

## While true, it takes nobody in: walking into it doesn't dive him in, it doesn't hide
## him, and a wall the shape of it keeps him out. Added 11 Nov 2026: the tutorial at the
## camp closes the camp's bush while the campers chase him (camp_tutorial.gd).
var closed := false:
	set(value):
		closed = value
		if closed and _wall == null:
			_wall = _make_wall()
		if _wall:
			_wall.collision_layer = CLOSED_LAYER if closed else 0
var _wall: StaticBody3D

## How long the rustle lasts and how hard it shakes; how big his eyes are, how far apart,
## and how high up the spot; and how often they blink, and for how long (seconds).
const RUSTLE := 0.45
const SHAKE := 0.13
const EYE := 0.045
const EYE_GAP := 0.065
const EYE_UP := 0.42
const BLINK_EVERY := Vector2(1.8, 3.4)
const BLINK := 0.12
const EYE_WHITE := Color("f6f2e6")
const PUPIL := Color("1a1410")

var _rustle_t := -1.0
var _leaves_scale := Vector3.ONE
var _eyes: Node3D
var _blink := 2.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("hide_spot")
	monitorable = false
	if leaves:
		_leaves_scale = leaves.scale
	if dive:
		body_entered.connect(_on_body_entered)
	_rng.seed = hash(name)


## True while `body` is inside this spot, and sneaking if it needs that.
func covers(body: Node3D) -> bool:
	if closed or not monitoring or not body is PhysicsBody3D:
		return false
	# Hiding in it, he's in it, whether or not his collider's on (23 Nov 2026).
	if body.get("hiding_in") == self:
		return true
	return overlaps_body(body) and (not needs_sneak or body.get("sneaking") == true)


## The top of the hiding place, in world space.
func top() -> Vector3:
	return global_position + Vector3.UP * height


## The hiding spot `body` is in, or null.
static func cover_for(body: Node3D) -> Node3D:
	for spot in body.get_tree().get_nodes_in_group("hide_spot"):
		if spot.covers(body):
			return spot
	return null


## True while `body` is in any hiding spot in the level.
static func is_hidden(body: Node3D) -> bool:
	return cover_for(body) != null


func _on_body_entered(body: Node3D) -> void:
	# A frame later: this comes while the physics is being worked out, when his
	# collider can't be switched off for the hop.
	if not closed and body.has_method("dive_into"):
		body.dive_into.call_deferred(self)


## The wall a closed spot puts up: its own shapes, a little bigger, on CLOSED_LAYER.
func _make_wall() -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.collision_mask = 0
	for shape: CollisionShape3D in find_children("*", "CollisionShape3D", false, false):
		var copy := CollisionShape3D.new()
		copy.shape = shape.shape
		copy.transform = shape.transform.scaled_local(Vector3.ONE * WALL_SCALE)
		wall.add_child(copy)
	add_child(wall)
	return wall


## He's dived in (true) or come out (false): it rustles, and his eyes peek out or go.
func dived(inside: bool) -> void:
	_rustle_t = 0.0
	occupied = inside
	if inside and _eyes == null:
		_eyes = _make_eyes()
	if _eyes:
		_eyes.visible = inside and not hold_eyes
		_blink = _rng.randf_range(BLINK_EVERY.x, BLINK_EVERY.y)
	hiding_changed.emit(inside)


## It shakes, as when he dives in (the keeper's box, with him in it: keeper_box.gd `rustle`).
func rustle() -> void:
	_rustle_t = 0.0


## True while his eyes are peeking out of it (for the tests).
func peeking() -> bool:
	return _eyes != null and _eyes.visible


## His eyes, or null till he's first dived in.
func eyes() -> Node3D:
	return _eyes


func _process(delta: float) -> void:
	if leaves and _rustle_t >= 0.0:
		_rustle_t += delta
		var f := _rustle_t / RUSTLE
		if f >= 1.0:
			_rustle_t = -1.0
			leaves.rotation.x = 0.0
			leaves.rotation.z = 0.0
			leaves.scale = _leaves_scale
		else:
			var a := sin(f * TAU * 2.5) * (1.0 - f) * SHAKE
			leaves.rotation.x = a
			leaves.rotation.z = -a * 0.7
			leaves.scale = _leaves_scale * Vector3(1.0 + a * 0.6, 1.0 - a * 0.9, 1.0 + a * 0.6)
	if _eyes:
		_eyes.visible = occupied and not hold_eyes
	if _eyes and _eyes.visible:
		var camera := get_viewport().get_camera_3d()
		if camera:
			if not own_eyes:
				var middle := global_position + Vector3.UP * height * EYE_UP
				_eyes.global_position = middle + (camera.global_position - middle).normalized() * peek_out
			_eyes.look_at(camera.global_position)
		_blink -= delta
		if _blink <= 0.0:
			_blink = _rng.randf_range(BLINK_EVERY.x, BLINK_EVERY.y)
		_eyes.scale = Vector3(1.0, 0.12 if _blink < BLINK else 1.0, 1.0) * eye_scale


## Two round eyes with dark pupils, looking out at the camera (its -Z), unshaded so they
## show at night.
func _make_eyes() -> Node3D:
	var root := Node3D.new()
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = EYE_WHITE
	var dark := StandardMaterial3D.new()
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.albedo_color = PUPIL
	for side: float in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = EYE
		ball.height = EYE * 2.0
		ball.radial_segments = 10
		ball.rings = 5
		ball.material = white
		eye.mesh = ball
		eye.position = Vector3(side * EYE_GAP, 0.0, 0.0)
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(eye)
		var pupil := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = EYE * 0.5
		dot.height = EYE
		dot.radial_segments = 8
		dot.rings = 4
		dot.material = dark
		pupil.mesh = dot
		pupil.position = Vector3(side * EYE_GAP, -EYE * 0.1, -EYE * 0.75)
		pupil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(pupil)
	add_child(root)
	return root
