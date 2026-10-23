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
## Draws the cone on the ground: pale while it watches, red while it sees him.
@export var show_cone := true
## The heights on him it looks for (his back, his head), in metres: seeing either is enough.
const LOOK_AT := [0.25, 0.45]
const WATCHING := Color(1.0, 0.93, 0.62, 0.5)
const SEEING := Color(1.0, 0.33, 0.27, 0.65)

## Who it looks for: the node in the "player" group, unless the level sets it.
var target: Node3D
## True while it sees the target.
var seeing := false
## Bodies its sight passes through, such as its own NPC's collider.
var ignore: Array[RID] = []

var _material: StandardMaterial3D
var _cone: MeshInstance3D
var _drawn_reach := 1.0


func _ready() -> void:
	add_to_group("watcher")
	if show_cone:
		_build_cone()


func _physics_process(_delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node3D
	var now := target != null and can_see(target)
	if now != seeing:
		seeing = now
		if now:
			spotted.emit(target)
		else:
			lost.emit(target)
	if _material:
		_material.albedo_color = SEEING if seeing else WATCHING
		# Drawn as far as it sees now: the level may change `reach` as it goes.
		_cone.scale = Vector3.ONE * (reach / _drawn_reach)


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
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.vertex_color_use_as_albedo = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.disable_fog = true
	_material.albedo_color = WATCHING
	_cone = MeshInstance3D.new()
	_cone.mesh = st.commit()
	_cone.material_override = _material
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drawn_reach = reach
	add_child(_cone)
