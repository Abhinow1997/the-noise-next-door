extends Node3D
## An NPC's eyes. It sees the raccoon when he's in a cone in front of it, within
## `reach`, with nothing solid in between, and not hidden (in a hiding spot, or curled
## up in his den). Put it on the NPC at eye height, looking along its -Z. While any of
## these sees him, thought_bubbles.gd shows the alert bubble.

signal spotted(body: Node3D)
signal lost(body: Node3D)

const HideSpot := preload("res://scripts/hide_spot.gd")

## How far it sees, in metres, and how wide its cone is, in degrees from side to side.
@export var reach := 6.0
@export var angle := 70.0
## Which physics layers block its sight.
@export_flags_3d_physics var blocked_by := 1
## Draws the cone on the ground: pale while it watches, red for a while once it spots him.
@export var show_cone := true
## Since 26 Oct 2026 (CHANGE-BRIEF.md, Assignment 5): the moment it spots him its cone
## snaps red and stays so for RED_TIME (the author: "When spotted the color should snape
## to red for a 2 seconds"); then every cone at the camp fades out over FADE_OUT, and
## each comes back BACK_AFTER seconds after its NPC starts walking back (the author:
## "after like 5 seconds bring the vision cone back"). FADE_OUT is Claude Code's choice.
## When each cone shows is camp_person.gd's; the colour and the fades are the author's
## shader's (shaders/vision_cone.gdshader), its `alarm` and `shown` set at the camp by
## cone_driver.gd. A cone nothing drives (the bubble demo's) just turns red from red().
const RED_TIME := 2.0
const FADE_OUT := 0.5
const BACK_AFTER := 5.0
## The heights on him it looks for (his back, his head), in metres: seeing either is enough.
const LOOK_AT := [0.25, 0.45]
const WATCHING := Color(1.0, 0.93, 0.62, 0.5)
const SEEING := Color(1.0, 0.33, 0.27, 0.65)
const SHADER := preload("res://shaders/vision_cone.gdshader")

## Who it looks for: the node in the "player" group, unless the level sets it.
var target: Node3D
## True while it sees the target.
var seeing := false
## While true it sees nothing (at the camp, until the tutorial's done).
var blind := false
## When it last spotted him, on its own clock (`clock`).
var spotted_at := -INF
var clock := 0.0
## While above 0, the cone is drawn this long instead of as far as it sees (`reach`):
## camp_person.gd keeps it at its length from before they took fright.
var held_length := -1.0
## Bodies its sight passes through, such as its own NPC's collider.
var ignore: Array[RID] = []
## True once something else (cone_driver.gd) sets its look: then it doesn't from red().
var driven := false

var _material: ShaderMaterial
var _cone: MeshInstance3D
var _drawn_reach := 1.0


func _ready() -> void:
	add_to_group("watcher")
	if show_cone:
		_build_cone()


func _physics_process(delta: float) -> void:
	clock += delta
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node3D
	var now := not blind and target != null and can_see(target)
	if now != seeing:
		seeing = now
		if now:
			spotted_at = clock
			spotted.emit(target)
		else:
			lost.emit(target)
	if _material:
		if not driven:
			_material.set_shader_parameter("alarm", 1.0 if red() else 0.0)
		# Drawn as far as it sees now (the level may change `reach` as it goes), and
		# stretched across the ground only: stretched up and down as well, as it was
		# until 26 Oct 2026, it sank into the ground when longer and rose off it when
		# shorter, since it hangs below the eyes.
		var length := held_length if held_length > 0.0 else reach
		_cone.scale = Vector3(length / _drawn_reach, 1.0, length / _drawn_reach)


## True from the moment it spots him until its red and the fade after it are over.
func red() -> bool:
	return clock < spotted_at + RED_TIME + FADE_OUT


## True if it can see `body` right now.
func can_see(body: Node3D) -> bool:
	if hidden(body):
		return false
	var eye := global_position
	var forward := -global_basis.z
	forward.y = 0.0
	var flat := body.global_position - eye
	flat.y = 0.0
	if flat.length() > reach or forward.length_squared() < 1e-6:
		return false
	if flat.length() > 0.05 and rad_to_deg(forward.angle_to(flat)) > angle * 0.5:
		return false
	var exclude := ignore.duplicate()
	if body is CollisionObject3D:
		exclude.append((body as CollisionObject3D).get_rid())
	var space := get_world_3d().direct_space_state
	for height: float in LOOK_AT:
		var ray := PhysicsRayQueryParameters3D.create(eye, body.global_position + Vector3.UP * height, blocked_by, exclude)
		if space.intersect_ray(ray).is_empty():
			return true
	return false


## True while `body` can't be seen by anyone: in a hiding spot, or curled up in his den.
static func hidden(body: Node3D) -> bool:
	return HideSpot.is_hidden(body) or body.get("resting") == true


## Shows or hides the cone on the ground (it still sees either way).
func show_on_ground(on: bool) -> void:
	if _cone:
		_cone.visible = on


## Sets the shader's `alarm` (0 the yellow, 1 the red) and `shown` (0 gone, 1 shown).
func set_look(alarm: float, shown: float) -> void:
	if _material:
		_material.set_shader_parameter("alarm", alarm)
		_material.set_shader_parameter("shown", shown)


## The cone's own material (for the tests).
func material() -> ShaderMaterial:
	return _material


## True while the cone's drawn on the ground.
func showing() -> bool:
	return _cone != null and _cone.visible


## How long the cone's drawn, and where it is in the world (for the tests).
func drawn_length() -> float:
	return _cone.scale.x * _drawn_reach if _cone else 0.0


func drawn_box() -> AABB:
	return _cone.global_transform * _cone.get_aabb() if _cone else AABB()


## The cone, as a fan on the ground under the eyes, fading toward its edge.
func _build_cone() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ground := Vector3(0.0, 0.03 - global_position.y, 0.0)
	var steps := 24
	var half := deg_to_rad(angle * 0.5)
	for i in steps:
		var a0 := lerpf(-half, half, float(i) / steps)
		var a1 := lerpf(-half, half, float(i + 1) / steps)
		st.set_color(Color(1, 1, 1, 0.55))
		st.add_vertex(ground)
		st.set_color(Color(1, 1, 1, 0.12))
		st.add_vertex(ground + Vector3(-sin(a1), 0.0, -cos(a1)) * reach)
		st.set_color(Color(1, 1, 1, 0.12))
		st.add_vertex(ground + Vector3(-sin(a0), 0.0, -cos(a0)) * reach)
	# One material per cone, so each has its own values (CHANGE-BRIEF.md, Assignment 5).
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_cone = MeshInstance3D.new()
	_cone.mesh = st.commit()
	_cone.material_override = _material
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drawn_reach = reach
	add_child(_cone)
