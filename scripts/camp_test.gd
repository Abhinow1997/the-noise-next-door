extends Node
## The automated check for the campers' reactions to the raccoon (camp_person.gd): it
## puts him near the campsite in turn sneaking, in plain sight, lingering, up a tree,
## gone again and chittering out of sight, and checks how each of them takes it. Since
## the routines came in (23 Oct 2026), "back at work" means back on their routine, and
## a noise makes them wonder (INVESTIGATE) before anything else. Run it
## headless from the project folder:
##   godot --headless --path . --audio-driver Dummy -- --camp-test
## It prints a table and quits with exit code 0 if every check passes, 1 if not.
## Run it in a window with `--camp-shots=<folder>` as well, and it saves pictures of
## the encounter as the game's camera sees it.

const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")
const S := CampPerson.State

## Set by the level (main.gd).
var level: Node
var shots := ""
## The pictures: when, and what of.
const SHOTS := [[3.9, "01_they_take_fright"], [7.4, "02_she_cowers_behind_him"], [10.6, "03_chase"],
	[11.6, "04_caught_shooed"], [12.6, "05_shooed_again"], [70.0, "06_up_a_tree"]]

var _t := 0.0
var _steps: Array = []
var _results: Array[Array] = []
var _failed := false
var _camp: Campsite
var _camper: CampPerson
var _man: CampPerson
var _girl: CampPerson
var _player: Node3D
## What happened between steps: whether he leapt away, and every state each one was in.
var _hopped := false
var _lowest := INF
var _seen_states := {}


func _ready() -> void:
	_camp = level.campsite
	_camper = _camp.camper
	_man = _camp.dancers[0]
	_girl = _camp.dancers[1]
	_player = level.player

	_at(1.0, func() -> void:
		_check("At first: the camper hammers", "hammer", _camper.anim.current_animation)
		_check("At first: the two dance", "dance dance", _man.anim.current_animation + " " + _girl.anim.current_animation)
		_check("At first: the mallet is in his hand", true, _camp._mallet_hand.visible))

	# Sneaking, 5 m in front of the camper: out of his sight, which sneaking shortens.
	# Straight ahead of him the other tent's in the way (since 23 Oct 2026 the dancers,
	# lost in the music, no longer see that far to make up for it), so a little to the
	# side, where he can see.
	_at(1.4, func() -> void: Input.action_press("sneak"))
	_at(1.5, func() -> void: _player.place(_in_view(_camper, 5.0)))
	_at(3.0, func() -> void:
		_check("Sneaking 5 m in front of him: unseen", "WORK WORK WORK", _states()))
	# Standing up there: he's seen.
	_at(3.1, func() -> void:
		Input.action_release("sneak")
		_mark())
	_at(3.7, func() -> void:
		_check("In plain sight 5 m off: the camper takes fright", true, S.STARTLED in _seen(_camper)))
	_at(4.6, func() -> void:
		_check("The other two catch his fright", true,
			S.STARTLED in _seen(_man) and S.STARTLED in _seen(_girl))
		_check("All three flinch with their hands up", true, _ever_played("scared")))
	_at(7.5, func() -> void:
		_check("The girl hides and cowers", "cower", _girl.anim.current_animation)
		_check("The camper stands guard", S.GUARD, _camper.state)
		_check("The low-poly man stands guard", S.GUARD, _man.state)
		var toward: Vector3 = _flat(_camp.last_seen_at - _girl.global_position).normalized()
		var shield: Vector3 = _girl.global_position + toward * CampPerson.SHIELD
		_check("He stands between her and the raccoon", true, _flat(_man.global_position - shield).length() < 0.6)
		_check("She's behind him, away from the raccoon", true,
			_flat(_girl.global_position - _camp.last_seen_at).length()
				> _flat(_man.global_position - _camp.last_seen_at).length())
		_mark())
	# Lingering: the men chase him, and reach him while he stands still.
	_at(10.5, func() -> void:
		_check("Lingering, the camper chases him", true, S.CHASE in _seen(_camper))
		_check("Lingering, the low-poly man chases him", true, S.CHASE in _seen(_man))
		_check("The girl never chases", false, S.CHASE in _seen(_girl) or S.GUARD in _seen(_girl)))
	_at(13.0, func() -> void:
		_check("Caught standing still: he's shooed", true, S.SHOO in _seen(_camper) or S.SHOO in _seen(_man))
		_check("Shooed, he leaps away", true, _hopped)
		_check("Leaping away, he never sinks into the ground", true, _lowest > -0.05))

	# Gone: well out of the camp. They stop, go back and get on with it.
	_at(13.5, func() -> void: _player.place(Vector3(20.0, 0.02, 6.5)))
	_at(17.0, func() -> void:
		_check("Gone: the men head back", true, _camper.state in [S.SHOO, S.RETURN, S.WORK] and _man.state in [S.SHOO, S.RETURN, S.WORK]))
	_at(36.0, func() -> void:
		_check("Calm again: all three back at their routines", "WORK WORK WORK", _states())
		_check("Calm again: each at their activity or on the way", true, _on_routine())
		_check("Calm again: the mallet's in his hand only while he pegs", _camper.anim.current_animation == "hammer",
			_camp._mallet_hand.visible))

	# Heard, not seen: a chitter behind the camper, out of his sight.
	_at(36.5, func() -> void:
		_player.place(_behind(_camper, 130.0, 4.0))
		_mark())
	_at(37.5, func() -> void:
		_check("Behind him and quiet: unseen", "WORK", S.keys()[_camper.state])
		_player.chitter())
	_at(38.4, func() -> void:
		_check("A chitter behind him: he turns to see what it was", true, S.INVESTIGATE in _seen(_camper)))
	_at(39.2, func() -> void:
		_check("Turned round, he sees him and takes fright", true, S.STARTLED in _seen(_camper)))
	_at(39.5, func() -> void: _player.place(Vector3(20.0, 0.02, 6.5)))

	_at(60.0, func() -> void:
		_check("Calm again after the chitter", "WORK WORK WORK", _states()))

	# Up a tree at the edge of the camp, heard there: they chase him to the foot of it,
	# shoo up at him a while, and give up.
	for shot: Array in SHOTS:
		_at(shot[0], _shot.bind(shot[1]))
	var tree := _camp_tree()
	_at(60.5, func() -> void:
		_check("There's a tree to climb at the edge of the camp", true, not tree.is_empty())
		if tree.is_empty():
			return
		var base: Vector3 = tree.base
		var toward: Vector3 = _flat(Vector3(Campsite.FIRE.x, 0, Campsite.FIRE.y) - base).normalized()
		_player.place(base + toward * (tree.clear + 0.3) + Vector3(0, 0.02, 0))
		_player._start_climb(tree)
		Input.action_press("move_forward"))
	_at(61.6, func() -> void:
		Input.action_release("move_forward")
		_mark()
		_player.chitter())
	_at(80.0, func() -> void:
		_check("Up a tree: he's still up it", true, _player.climbing)
		_check("Up a tree: a man shoos at the foot of it", true,
			S.SHOO in _seen(_camper) or S.SHOO in _seen(_man))
		_check("Up a tree: they can't catch him", false, _hopped))
	_at(88.0, func() -> void:
		_check("Up a tree: they give up and head back", true, S.RETURN in _seen(_camper) and S.RETURN in _seen(_man))
		for music: AudioStreamPlayer in [level._music, level._sleep_music]:
			if music:
				music.stop()
		if _camp.party:
			_camp.party.stop())
	_at(88.5, _finish)


func _physics_process(delta: float) -> void:
	_t += delta
	if _player.is_hopping():
		_hopped = true
	_lowest = minf(_lowest, _player.global_position.y)
	for person: CampPerson in [_camper, _man, _girl]:
		if not _seen_states.has(person):
			_seen_states[person] = {}
		_seen_states[person][person.state] = true
		if person.anim and person.anim.current_animation != "":
			_seen_states[person]["clip " + person.anim.current_animation] = true
	while not _steps.is_empty() and _t >= _steps[0][0]:
		var step: Callable = _steps.pop_front()[1]
		step.call()


func _at(t: float, step: Callable) -> void:
	_steps.append([t, step])
	_steps.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


## Forgets the states seen so far, so the next checks see only what happens after.
func _mark() -> void:
	_seen_states.clear()
	_hopped = false
	_lowest = INF


func _seen(person: CampPerson) -> Array:
	return _seen_states.get(person, {}).keys()


func _ever_played(clip: String) -> bool:
	for person: CampPerson in [_camper, _man, _girl]:
		if not ("clip " + clip) in _seen(person):
			return false
	return true


func _states() -> String:
	return " ".join([_camper, _man, _girl].map(func(p: CampPerson) -> String: return S.keys()[p.state]))


## True if each of them is at their activity's place or walking to it.
func _on_routine() -> bool:
	for person: CampPerson in [_camper, _man, _girl]:
		if person.at_activity() and _flat(person.global_position - person.activity_spot()).length() > 0.2:
			return false
	return true


## The climbable tree nearest the camp's middle within its bounds, or {}.
func _camp_tree() -> Dictionary:
	var best := {}
	var middle := Vector3(Campsite.FIRE.x, 0, Campsite.FIRE.y)
	for tree: Dictionary in level.forest.climbable:
		var base: Vector3 = tree.base
		if _camp.in_camp(base) and (best.is_empty() or _flat(base - middle).length() < _flat(best.base - middle).length()):
			best = tree
	return best


## `metres` in front of where `person`'s activity is done, on the ground, as near
## straight ahead as they can see it with nothing in the way, and out of the dancers'
## sight while they dance.
func _in_view(person: CampPerson, metres: float) -> Vector3:
	var space := person.get_world_3d().direct_space_state
	var at := Vector3.ZERO
	for degrees: float in [0.0, -15.0, 15.0, -30.0, 30.0, -45.0, 45.0]:
		var yaw := person.activity_facing() + deg_to_rad(degrees)
		at = person.activity_spot() + Vector3(sin(yaw), 0, cos(yaw)) * metres + Vector3(0, 0.02, 0)
		var ray := PhysicsRayQueryParameters3D.create(person.eyes.global_position, at + Vector3.UP * 0.45, 1,
			[person.get_rid(), _player.get_rid()])
		var dancers_far := [_man, _girl].all(func(d: CampPerson) -> bool:
			return _flat(d.global_position - at).length() > CampPerson.SIGHT * CampPerson.DANCE_SIGHT + 0.3)
		if dancers_far and space.intersect_ray(ray).is_empty():
			return at
	return at


## `metres` from `person` as they stand now, `degrees` round from the way they face.
func _behind(person: CampPerson, degrees: float, metres: float) -> Vector3:
	var way := person.global_basis.z.rotated(Vector3.UP, deg_to_rad(degrees))
	way.y = 0.0
	return person.global_position + way.normalized() * metres + Vector3(0, 0.02, 0)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _shot(name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(shots)
	get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))


func _check(name: String, expected, actual) -> void:
	var ok: bool = str(expected) == str(actual)
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _finish() -> void:
	print("")
	print("Camp reactions check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-58s expected %-16s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
