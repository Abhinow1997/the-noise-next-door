extends Area3D
## A place the raccoon can hide in: a bush, a dumpster, a patch of shadow. While he's
## inside one, NPCs can't see him (vision_cone.gd), and slipping into one with an NPC
## about floats z's up off its top (thought_bubbles.gd). Give it a CollisionShape3D
## the size of the hiding place. In a shadow he only counts as hidden while he sneaks,
## so set `needs_sneak` there.

@export var needs_sneak := false
## How tall the hiding place is, in metres: the z's float up from its top.
@export var height := 1.0


func _ready() -> void:
	add_to_group("hide_spot")
	monitorable = false


## True while `body` is inside this spot, and sneaking if it needs that.
func covers(body: Node3D) -> bool:
	if not monitoring or not body is PhysicsBody3D:
		return false
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
