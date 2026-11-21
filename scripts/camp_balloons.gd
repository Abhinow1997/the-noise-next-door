extends Node3D
## Pop the balloons, a level 1 task at the camp (camp_tasks.gd "balloons"; CHANGE-BRIEF.md,
## "Boundaries: named changes" and "The phase table: the jump"). Game code: the bite and the
## pops are decided here, on the physics tick, never from the clips.
##   - Three balloons (props/party_balloon.tscn), red, yellow and blue, tied low at the party
##     by the speaker beside the table (SPOTS, from the speaker), each 0.3 m across, their
##     middles MIDDLE_UP high. They have no collision.
##   - Each physics tick after the player's: while his bite is open (player.gd bite_open(),
##     ticks 5-14 of a jump, once a jump), the first balloon not yet popped whose middle is
##     within REACH of his mouth (player.gd mouth_point()) pops. That uses the jump's bite,
##     the pop is heard HEAR_CHITTER round as his laugh is (campsite.gd noise), and once all
##     three are popped the task is ticked off.
##   - Only once the tutorial has revealed the camp's tasks, as the bear bag and the tent.
## Built on 21 Nov 2026 by Claude Code, from the brief and its revision of the same day.

const Balloon := preload("res://props/party_balloon.tscn")
const Player := preload("res://scripts/player.gd")

## Each balloon's colour and where it's tied, from the speaker (x, z): on the fire's side
## of it and the table, clear of the table's top (which ends 0.52 m on that side of the
## speaker) so he can jump at them.
const SPOTS := [["red", Vector2(-0.55, 0.85)], ["yellow", Vector2(0.05, 1.0)], ["blue", Vector2(0.65, 0.85)]]
## How high each balloon's middle is (m), and how near his mouth it must be to pop.
const MIDDLE_UP := 0.7
const REACH := 0.25

## Set before it's added (campsite.gd): the camp.
var camp
## The balloons, in SPOTS's order.
var balloons: Array[Sprite3D] = []

var _player: Player


func _ready() -> void:
	# After the player's own tick (priority 0), so his jump's state is this tick's.
	process_physics_priority = 1
	for spot: Array in SPOTS:
		var balloon := Balloon.instantiate() as Sprite3D
		balloon.set("colour", spot[0])
		balloon.position = Vector3(spot[1].x, MIDDLE_UP, spot[1].y)
		add_child(balloon)
		balloons.append(balloon)


## How many are popped.
func popped_count() -> int:
	return balloons.filter(func(b: Sprite3D) -> bool: return b.get("popped")).size()


func _physics_process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
	if camp.tasks == null or not camp.tasks.revealed or not _player.bite_open():
		return
	var mouth := _player.mouth_point()
	for balloon in balloons:
		if balloon.get("popped") or balloon.global_position.distance_to(mouth) > REACH:
			continue
		balloon.call("pop")
		_player.use_bite()
		camp.noise(balloon.global_position, camp.HEAR_CHITTER, 0.0, true)
		if popped_count() == balloons.size():
			camp.tasks.done("balloons")
		return
