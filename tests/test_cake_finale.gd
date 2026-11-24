extends SceneTree
## The cake and the end of level 1 at the camp (scripts/camp_finale.gd, 23 Nov 2026): the camper fetches
## a cake, his laces are tied, he falls, the cake lands on him, his beanie slips off, the raccoon grabs
## it, the cutscene, the chase and "To be continued".
##
## In the real level (main.tscn at the developer menu's "cake" point: five of the camp's tasks done, the
## fire burning), with the campers blind to him (campsite.gd `cones_on` off, as `--dev-unseen` has them);
## driven through the game loop with real key presses (Input.parse_input_event, and the move keys through
## Input.action_press), read each physics tick after the game's. It checks:
##   - the camper's three new clips: carry looping, trip and get_up one-shots;
##   - with five tasks done, he goes into his tent for the cake and carries it out in both hands
##     (`carry`) to its table, sets it down, and stands at it, facing it;
##   - (23 Nov 2026) everyone's there: the others come round the table, facing the cake, watching it
##     (their sight CAKE_SIGHT); they go back to their routines when he leaves it, and come again when he's
##     back at it;
##   - "Tie his laces" is the key task, its hint 5 words at most; E held at his heels ties them;
##   - he moves on, and falls (`trip`), the others round him; the cake lands on his face; his beanie is hidden on his head and
##     a loose one lies behind him; "Swipe his red beanie" is the key task;
##   - E takes the beanie: the cutscene (the keys held, between 10 and 20 s): he gets up (`get_up`),
##     stamps and goes after him; the girl takes fright; the men go after him; the raccoon runs off on
##     his own; then the keys are his, "Get away with it" is the key task and the moth leads the way;
##   - they chase him out of the camp, never giving up; caught, he drops the beanie;
##   - with the beanie at the forest's north-east edge: "To be continued", the keys held, the chase over.
## Run it from the project folder:
##   bash scripts/run-test.sh test_cake_finale.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 23 Nov 2026.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
const CampFinale := preload("res://scripts/camp_finale.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const Forest := preload("res://scripts/forest.gd")
const S := CampPerson.State
const MOVES := ["move_left", "move_right", "move_forward", "move_back"]

var level: Node
var camp: Node
var player: CharacterBody3D
var finale: CampFinale
var camper: CampPerson

var _checks := 0
var _failed := 0
var _tick := 0


func _initialize() -> void:
	var probe := Probe.new()
	probe.test = self
	probe.process_physics_priority = 1000
	root.add_child(probe)
	DevMenu._next = "cake"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	print("The cake and the end of level 1: the real level at the developer menu's \"cake\" point, %d physics"
		% Engine.physics_ticks_per_second + " ticks a second")
	_run()


class Probe extends Node:
	var test: Object

	func _physics_process(_delta: float) -> void:
		test.call("step")


func step() -> void:
	_tick += 1
	if player == null and level and level.get("player") and level.get("finale"):
		camp = level.campsite
		finale = level.finale
		camper = camp.camper
		player = level.player
	ticked.emit()


func _check(what: String, ok: bool, got: Variant = "") -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("%s  %s  (got %s)" % ["PASS" if ok else "FAIL", what, str(got)])


func _key(keycode: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode as Key
	ev.physical_keycode = keycode as Key
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _tap(keycode: int) -> void:
	_key(keycode, true)
	await _wait(2)
	_key(keycode, false)
	await _wait(2)


func _wait(n: int) -> void:
	for i in n:
		await ticked


func _until(cond: Callable, most: int) -> bool:
	for i in most:
		if cond.call():
			return true
		await ticked
	return cond.call()


func _secs(s: float) -> int:
	return int(round(s * Engine.physics_ticks_per_second))


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Puts him at `from`, facing `at` (he faces his -Z).
func _stand(from: Vector3, at: Vector3) -> void:
	player.call("place", Vector3(from.x, 0.02, from.z))
	player.rotation.y = atan2(-(at.x - from.x), -(at.z - from.z))
	player.velocity = Vector3.ZERO


## Holds the move keys that point him along `way` on the ground (turned by the camera's yaw).
func _move(way: Vector3) -> void:
	for action: String in MOVES:
		Input.action_release(action)
	if way == Vector3.ZERO:
		return
	var keys := way.normalized().rotated(Vector3.UP, -level.camera.global_rotation.y)
	if keys.x > 0.01:
		Input.action_press("move_right", keys.x)
	elif keys.x < -0.01:
		Input.action_press("move_left", -keys.x)
	if keys.z > 0.01:
		Input.action_press("move_back", keys.z)
	elif keys.z < -0.01:
		Input.action_press("move_forward", -keys.z)


func _task(id: String) -> Dictionary:
	for t: Dictionary in level.tasks.list:
		if t.id == id:
			return t
	return {}


func _key_task_is(id: String) -> bool:
	return level.tasks.key_task().get("id", "") == id


func _hint_ok(t: Dictionary) -> bool:
	var hint: String = t.get("hint", "")
	return hint != "" and hint.split(" ", false).size() <= 5


## The campers other than the camper, in the camp's order.
func _others() -> Array:
	return camp.people.filter(func(p: CampPerson) -> bool: return p != camper)


## Every one of the others round the cake, at their place, facing it.
func _all_gathered() -> bool:
	var i := 0
	for person: CampPerson in _others():
		var place: Vector3 = finale.gather_spot(i)
		var to := finale.table_at() - person.global_position
		var off := rad_to_deg(absf(angle_difference(person.rotation.y, atan2(to.x, to.z))))
		if not person.gathered() or _flat(person.global_position, place) > 0.35 or off > 20.0:
			return false
		i += 1
	return true


func _gather_text() -> String:
	var bits := []
	var i := 0
	for person: CampPerson in _others():
		var to := finale.table_at() - person.global_position
		bits.append("%s state %d, %.2f m from place, %.0f degrees off" % [person.name, person.state,
			_flat(person.global_position, finale.gather_spot(i)),
			rad_to_deg(absf(angle_difference(person.rotation.y, atan2(to.x, to.z))))])
		i += 1
	return "; ".join(bits)


func _clip() -> String:
	return camper.anim.assigned_animation if camper.anim else ""


func _run() -> void:
	await _until(func() -> bool: return player != null, 60)
	camp.set("cones_on", false)
	await _wait(5)

	# The clips.
	var anim: AnimationPlayer = camper.anim
	var modes := []
	for clip: String in ["carry", "trip", "get_up"]:
		modes.append(anim.get_animation(clip).loop_mode if anim.has_animation(clip) else -1)
	_check("his new clips: carry looping, trip and get_up one-shots", modes == [Animation.LOOP_LINEAR,
		Animation.LOOP_NONE, Animation.LOOP_NONE], modes)

	# The cake fetched.
	_check("five of the camp's tasks done: the cake's next (and no cake task on the list yet)",
		level.tasks.camp_done() >= CampFinale.UNLOCK_AFTER and finale.phase in [CampFinale.Phase.READY,
		CampFinale.Phase.FETCHING] and _task("laces").is_empty(), "%d done, phase %d" % [level.tasks.camp_done(),
		finale.phase])
	var went := await _until(func() -> bool: return camper.state == S.CAKE, _secs(3.0))
	var carried := await _until(func() -> bool: return _clip() == "carry" and finale.cake.visible \
		and finale.cake.get_parent() is BoneAttachment3D, _secs(40.0))
	_check("he goes into his tent for it, and carries it out in both hands (carry)", went and carried,
		"state %d, clip %s, cake under %s" % [camper.state, _clip(), finale.cake.get_parent().name])
	var out := await _until(func() -> bool: return finale.phase == CampFinale.Phase.OUT, _secs(30.0))
	await _until(func() -> bool: return camper.at_activity() and camper.activity() == "cake", _secs(5.0))
	await _wait(_secs(0.6))
	var to_table := finale.table_at() - camper.global_position
	var facing := rad_to_deg(absf(angle_difference(camper.rotation.y, atan2(to_table.x, to_table.z))))
	_check("he sets it down on its table and stands at it, facing it", out and finale.cake.get_parent() == finale.table
		and camper.activity() == "cake" and camper.at_activity() and facing < 15.0,
		"out %s, cake under %s, activity %s, %.0f degrees off" % [out, finale.cake.get_parent().name,
			camper.activity(), facing])
	var laces_task := _task("laces")
	_check("\"Tie his laces\" is the key task, its hint 5 words at most: \"%s\"" % laces_task.get("hint", ""),
		laces_task.get("text", "") == "Tie his laces" and _key_task_is("laces") and _hint_ok(laces_task)
		and level.tasks.shown().has(laces_task),
		"key task %s" % level.tasks.key_task().get("id", "(none)"))
	_check("the camp's tasks still decide all_done(): the cake's aren't counted",
		level.tasks.all_done() == level.tasks.list.all(func(t: Dictionary) -> bool: return t.done \
			or t.get("finale", false)), level.tasks.all_done())

	# Everyone's there (23 Nov 2026). He's kept at the cake while the others come (they come once they're at
	# their routine: the keeper may be tending the fire).
	camper.set("_step_left", 240.0)
	var round := await _until(_all_gathered, _secs(60.0))
	_check("the cake out, the others come round its table, each at their place, facing it", round,
		_gather_text())
	var reach_ok := true
	for person: CampPerson in _others():
		if absf(person.eyes.reach - CampPerson.SIGHT * CampPerson.CAKE_SIGHT) > 0.01:
			reach_ok = false
	_check("watching it, they see only %.2f m (CAKE_SIGHT of their sight)" % (CampPerson.SIGHT
		* CampPerson.CAKE_SIGHT), reach_ok, ", ".join(_others().map(func(p: CampPerson) -> String:
			return "%.2f" % p.eyes.reach)))
	# He leaves the cake (his time at it up): they go back to their routines; back at it, they come again.
	var cake_step: int = camper.get("_step")
	camper.set("_step_left", 0.01)
	var left := await _until(func() -> bool: return _others().all(func(p: CampPerson) -> bool:
		return p.state != S.GATHER), _secs(3.0))
	_check("he leaves the cake: they go back to their routines", left and camper.activity() != "cake",
		"camper at %s; %s" % [camper.activity(), _gather_text()])
	camper.set("_step", cake_step)
	camper.set("_step_left", 240.0)
	camper.set("_arrived", false)
	await _until(func() -> bool: return camper.at_activity() and camper.activity() == "cake", _secs(15.0))
	var again := await _until(_all_gathered, _secs(60.0))
	_check("back at it, they come round again", again and camper.at_activity(), _gather_text())

	# Tie his laces: behind him, facing his heels, E held.
	var back := -camper.global_basis.z
	back.y = 0.0
	back = back.normalized()
	var heels := camper.global_position + back * 0.2
	_stand(camper.global_position + back * 0.75, heels)
	await _wait(3)
	var usable: bool = finale.laces.usable_by(player)
	_key(KEY_E, true)
	var tied := await _until(func() -> bool: return camper.laces_tied, _secs(CampFinale.LACE_TIME + 1.0))
	_key(KEY_E, false)
	_check("E held at his heels ties his laces: Tie his laces is done", usable and tied
		and level.tasks.is_done("laces"), "usable %s, tied %s, done %s" % [usable, tied, level.tasks.is_done("laces")])
	_stand(camper.global_position + back * 2.4 + camper.global_basis.x * 1.2, camper.global_position)
	await _wait(2)

	# He falls.
	var fell := await _until(func() -> bool: return camper.state == S.FALLEN, _secs(CampFinale.LEAVE_AFTER + 1.5))
	_check("he moves on, and falls (trip), the others round him", fell and _clip() == "trip" and _all_gathered(),
		"state %d, clip %s; %s" % [camper.state, _clip(), _gather_text()])
	await _wait(_secs(CampFinale.TRIP_LANDS + 0.15))
	var worn: MeshInstance3D = finale.get("_worn")
	var beanie: RigidBody3D = finale.beanie
	_check("the cake lands on his face (on his head bone), and his beanie slips off: hidden on his head, a loose "
		+ "one thrown off", finale.cake.get_parent() is BoneAttachment3D
		and (finale.cake.get_parent() as BoneAttachment3D).bone_name == "testa" and worn != null and not worn.visible
		and beanie != null and beanie.is_in_group("grabbable"), "cake under %s, worn shown %s, loose %s" % [
			finale.cake.get_parent().name, worn.visible if worn else "-", beanie != null])
	await _wait(_secs(1.5))
	var head := camper.model.global_transform * CampFinale.CAKE_FACE_LANDED
	var off := _flat(beanie.global_position, head) if beanie else INF
	var beanie_task := _task("beanie")
	_check("it lies on the ground by his head; \"Swipe his red beanie\" is the key task, its hint 5 words at most",
		beanie != null and beanie.global_position.y < 0.3 and off < 1.5 and _key_task_is("beanie")
		and _hint_ok(beanie_task), "%.2f m up, %.2f m from his head, key task %s" % [
			beanie.global_position.y if beanie else -1.0, off, level.tasks.key_task().get("id", "(none)")])

	# E takes it: the cutscene.
	var by := beanie.global_position + (beanie.global_position - head).normalized() * 0.32
	_stand(by, beanie.global_position)
	await _wait(3)
	var cut_from := _tick
	await _tap(KEY_E)
	_check("E takes the beanie in his mouth: Swipe his red beanie is done, and the cutscene starts, the keys held",
		player.get("held") == beanie and level.tasks.is_done("beanie") and finale.phase == CampFinale.Phase.CUTSCENE
		and player.get("input_locked"), "held %s, done %s, phase %d, locked %s" % [player.get("held") == beanie,
			level.tasks.is_done("beanie"), finale.phase, player.get("input_locked")])
	await _wait(_secs(CampFinale.CUT_GET_UP + 0.3) - (_tick - cut_from))
	_check("he gets up (get_up)", camper.state == S.RISE and _clip() == "get_up", "state %d, clip %s" % [
		camper.state, _clip()])
	await _wait(_secs(CampFinale.CUT_OTHERS + 0.4) - (_tick - cut_from))
	var girl: CampPerson = null
	var men_after := true
	for person: CampPerson in camp.people:
		if person.role == "girl":
			girl = person
		elif person.state != S.PURSUE:
			men_after = false
	_check("up, bare-headed, he stamps and goes after him; so do the other men; the girl takes fright",
		camper.state == S.PURSUE and worn and not worn.visible and men_after and girl != null
		and girl.state in [S.STARTLED, S.FLEE, S.COWER], "camper %d, men after %s, girl %d" % [camper.state,
			men_after, girl.state if girl else -1])
	await _wait(_secs(CampFinale.CUT_RUN + 0.5) - (_tick - cut_from))
	_check("the raccoon runs off on his own, the beanie in his mouth", player.call("running_off")
		and player.get("held") == beanie, "running off %s" % player.call("running_off"))
	await _until(func() -> bool: return finale.phase == CampFinale.Phase.CHASE, _secs(12.0))
	var cut_len := float(_tick - cut_from) / Engine.physics_ticks_per_second
	var getaway := _task("getaway")
	_check("after the cutscene (between 10 and 20 s): the keys are his, \"Get away with it\" is the key task, "
		+ "and the moth leads the way", finale.phase == CampFinale.Phase.CHASE and cut_len >= 10.0 and cut_len <= 20.0
		and not player.get("input_locked") and _key_task_is("getaway") and _hint_ok(getaway)
		and level.moths.call("guiding"), "%.1f s, locked %s, key task %s, moth guiding %s" % [cut_len,
			player.get("input_locked"), level.tasks.key_task().get("id", "(none)"), level.moths.call("guiding")])

	# The chase: out of the camp, and on.
	var outside := Vector3(62.0, 0.0, -8.0)
	_stand(outside, Vector3(CampFinale.EXIT.x, 0, CampFinale.EXIT.y))
	var gap_before := _flat(camper.global_position, outside)
	await _wait(_secs(3.0))
	var gap_after := _flat(camper.global_position, player.global_position)
	_check("they chase him out of the camp and on, not giving up", camper.state == S.PURSUE
		and not camp.in_camp(player.global_position, 3.0) and gap_after < gap_before - 4.0,
		"camper %d, %.1f m off, then %.1f" % [camper.state, gap_before, gap_after])
	var ahead := camper.global_position + camper.global_basis.z * 0.6
	_stand(ahead, camper.global_position)
	var dropped := await _until(func() -> bool: return player.get("held") == null, _secs(1.5))
	_check("caught, he drops the beanie (and leaps away)", dropped and beanie.is_in_group("grabbable"),
		"held %s" % player.get("held"))
	# Got back: away from the chasers, near the edge, once he's down from his leap; the beanie in his mouth
	# again, and on to the edge.
	var near_exit := Vector3(CampFinale.EXIT.x - 4.0, 0.0, CampFinale.EXIT.y + 3.0)
	_stand(near_exit, near_exit + Vector3(0, 0, -1))
	await _until(func() -> bool: return not player.call("is_hopping"), _secs(3.0))
	_stand(near_exit, near_exit + Vector3(0, 0, -1))
	await _wait(_secs(0.3))
	beanie.global_transform = Transform3D(Basis(), near_exit + Vector3(0, 0.1, -0.35))
	beanie.linear_velocity = Vector3.ZERO
	beanie.angular_velocity = Vector3.ZERO
	await _wait(10)
	await _tap(KEY_E)
	var regrabbed: bool = player.get("held") == beanie
	_move(Vector3(CampFinale.EXIT.x, 0, CampFinale.EXIT.y) - near_exit)
	var away := await _until(func() -> bool: return finale.phase == CampFinale.Phase.DONE, _secs(4.0))
	_move(Vector3.ZERO)
	var stood_down := true
	for person: CampPerson in camp.people:
		if person.state == S.PURSUE:
			stood_down = false
	_check("the beanie at the forest's north-east edge: Get away with it is done, the keys held, the chase over",
		regrabbed and away and level.tasks.is_done("getaway") and player.get("input_locked") and stood_down,
		"regrabbed %s, done %s, locked %s, stood down %s" % [regrabbed, level.tasks.is_done("getaway"),
			player.get("input_locked"), stood_down])
	await _wait(_secs(CampFinale.FADE_TIME + 0.3))
	var card: Label = finale.get("_card")
	var fade: ColorRect = finale.get("_fade")
	_check("then the screen fades to \"To be continued\"", card.visible and card.text == "To be continued"
		and fade.color.a > 0.99, "card %s \"%s\", fade %.2f" % [card.visible, card.text, fade.color.a])

	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)
