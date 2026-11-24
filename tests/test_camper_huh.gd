extends SceneTree
## The campers' "huh?" (camp_person.gd `_say_huh`, SFX-HUH), through the real level: main.tscn at the
## developer menu's "free" point, the campers' sight off (as `--dev-unseen` has it), so a noise makes
## them wonder rather than spot him. It checks:
##   - each camper has their "huh?": the sound, on the effects bus, heard from where they stand
##     (HUH_NEAR, HUH_FAR), in a voice of their own (HUH_PITCH; the girl's times HUH_GIRL);
##   - his laugh (Space, through Input.parse_input_event) beside them: one "huh?" for all who wonder ("?"
##     up), said by one of them (since 24 Nov 2026; it was one each),
##     HUH_DELAY after the laugh is heard, never on the same tick, and nobody else does;
##   - a second laugh while they're still wondering: no second "huh?" (the "?" stays up);
##   - losing him while they wonder (`lose_him`, as the tutorial does): confused, still "?", no more;
##   - called to look somewhere once calm again (`called`, as the girl's call does): confused at once,
##     and a "huh?" again.
## A headless run mixes no sound: this checks when it's played, not how it sounds.
## Run it from the project folder:
##   bash scripts/run-test.sh test_camper_huh.gd 60
## It prints PASS or FAIL per check and quits with exit code 1 if any check fails.
## Written by Claude Code on 24 Nov 2026.

const DevMenu := preload("res://scripts/dev_menu.gd")
const CampPerson := preload("res://scripts/camp_person.gd")

var level: Node
var camp: Node
var player: Node3D
var _checks := 0
var _failed := 0
var _tick := 0
## Each camper's ticks of their "huh?", and of the "?" coming up (into INVESTIGATE or SEARCH).
var _huhs := {}
var _ups := {}
var _was := {}


func _initialize() -> void:
	DevMenu._next = "free"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	physics_frame.connect(func() -> void: _tick += 1)
	print("The campers' \"huh?\": the real level at the developer menu's \"free\" point")
	_run()


func _check(what: String, ok: bool, got: Variant = "") -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("%s  %s  (got %s)" % ["PASS" if ok else "FAIL", what, str(got)])


func _wait(ticks: int) -> void:
	for i in ticks:
		await physics_frame


func _laugh() -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SPACE
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await physics_frame


## Until nobody has the "?" up, and none said "huh?" within HUH_AGAIN (at most 30 s).
func _settle(people: Array) -> void:
	for i in 60 * 30:
		var quiet := true
		for person: CampPerson in people:
			var said: Array = _huhs[person]
			if person.state in CampPerson.PUZZLED \
					or not said.is_empty() and _tick - int(said.back()) <= int(CampPerson.HUH_AGAIN * 60.0) + 1:
				quiet = false
		if quiet:
			return
		await physics_frame


func _count(d: Dictionary, after: int) -> int:
	var n := 0
	for person in d:
		n += (d[person] as Array).filter(func(t: int) -> bool: return t > after).size()
	return n


func _run() -> void:
	await _wait(30)
	camp = level.get("campsite")
	player = level.get("player")
	camp.cones_on = false
	var people: Array = camp.people
	for person: CampPerson in people:
		_huhs[person] = []
		_ups[person] = []
		_was[person] = person.state
		person.sound_started.connect(func(id: String) -> void:
			if id == "SFX-HUH":
				_huhs[person].append(_tick))
		person.state_changed.connect(func(to: int) -> void:
			if to in CampPerson.PUZZLED and _was[person] not in CampPerson.PUZZLED:
				_ups[person].append(_tick)
			_was[person] = to)

	# Each has their "huh?".
	var ready := 0
	var voices := []
	for person: CampPerson in people:
		var sfx: AudioStreamPlayer3D = person.get("_huh_sfx")
		var low: float = CampPerson.HUH_PITCH.x * (CampPerson.HUH_GIRL if person.role == "girl" else 1.0)
		var high: float = CampPerson.HUH_PITCH.y * (CampPerson.HUH_GIRL if person.role == "girl" else 1.0)
		if sfx and sfx.stream and sfx.stream.resource_path == CampPerson.HUH_SOUND and sfx.bus == "SFX" \
				and sfx.attenuation_model == AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE \
				and is_equal_approx(sfx.unit_size, CampPerson.HUH_NEAR) and is_equal_approx(sfx.max_distance, CampPerson.HUH_FAR) \
				and sfx.pitch_scale >= low - 0.0001 and sfx.pitch_scale <= high + 0.0001:
			ready += 1
		voices.append("%s %.3f" % [person.role, sfx.pitch_scale if sfx else 0.0])
	_check("each of the %d campers has their \"huh?\", heard from where they stand, in a voice of their own" % people.size(),
		ready == people.size() and people.size() > 0, voices)

	# His laugh beside the first of them.
	# (Put there, he may land with a noise of his own: everyone's let calm down, and past HUH_AGAIN.)
	var first: CampPerson = people[0]
	var at := first.global_position + Vector3(2.0, 0.0, 0.0)
	player.global_position = Vector3(at.x, player.global_position.y, at.z)
	await _wait(10)
	await _settle(people)
	var t0 := _tick
	await _laugh()
	await _wait(30)
	var ups := _count(_ups, t0 - 1)
	var huhs := _count(_huhs, t0)
	var soonest := INF
	var latest := 0
	# Since 24 Nov 2026 one "huh?" for all who wonder at once (camp_person.gd HUH_TOGETHER; the author:
	# "one hhuh sound is fine ven if multiple npcs see u"): it was one from each. Said by one who
	# wonders, once.
	var once := true
	for person in people:
		var mine: Array = (_huhs[person] as Array).filter(func(t: int) -> bool: return t > t0)
		var up: Array = (_ups[person] as Array).filter(func(t: int) -> bool: return t >= t0)
		once = once and mine.size() <= 1 and (mine.is_empty() or not up.is_empty())
		if not mine.is_empty():
			soonest = minf(soonest, mine[0] - up[0])
			latest = maxi(latest, mine[0] - up[0])
	_check("laugh: one \"huh?\" for all who wonder, from one of them (%d wondering, %d said it)" % [ups, huhs],
		ups > 0 and huhs == 1 and once, "%d / %d" % [huhs, ups])
	var delay_from := int(CampPerson.HUH_DELAY.x * 60.0)
	var delay_to := int(ceil(CampPerson.HUH_DELAY.y * 60.0)) + 1
	_check("laugh: each a moment after the \"?\" comes up, never on its tick (%s-%d ticks after)" % [str(soonest), latest],
		soonest >= delay_from and latest <= delay_to, "%s-%d, allowed %d-%d" % [str(soonest), latest, delay_from, delay_to])

	# Laughing again while they still wonder.
	var wondering := people.filter(func(p: CampPerson) -> bool: return p.state == CampPerson.State.INVESTIGATE)
	var t1 := _tick
	await _laugh()
	await _wait(30)
	var again := 0
	for person in wondering:
		again += (_huhs[person] as Array).filter(func(t: int) -> bool: return t > t1).size()
	_check("laugh again while %d still wonder: no second \"huh?\" from them" % wondering.size(),
		wondering.size() > 0 and again == 0, again)

	# Lost him while they wonder: confused, the "?" still up.
	var t2 := _tick
	for person: CampPerson in wondering:
		if person.state == CampPerson.State.INVESTIGATE:
			person.lose_him()
	await _wait(30)
	var confused := wondering.filter(func(p: CampPerson) -> bool: return p.state == CampPerson.State.SEARCH).size()
	again = 0
	for person in wondering:
		again += (_huhs[person] as Array).filter(func(t: int) -> bool: return t > t2).size()
	_check("lost him while they wonder: %d confused, no more \"huh?\"" % confused, confused > 0 and again == 0, again)

	# Calm again, a while on: called to look somewhere, they're confused at once, and say it again.
	var calm: CampPerson = null
	for i in 60 * 30:
		await physics_frame
		for person: CampPerson in wondering:
			var last: int = (_huhs[person] as Array).back() if not (_huhs[person] as Array).is_empty() else -100000
			if person.state in [CampPerson.State.WORK, CampPerson.State.RETURN] \
					and _tick - last > int(CampPerson.HUH_AGAIN * 60.0) + 1:
				calm = person
		if calm:
			break
	var t3 := _tick
	if calm:
		calm.called(calm.global_position + Vector3(2.0, 0.0, 0.0))
	await _wait(30)
	var said := 0 if calm == null else (_huhs[calm] as Array).filter(func(t: int) -> bool: return t > t3).size()
	_check("calm again, then called to look: confused (%s), and \"huh?\" once more" %
		("none calm" if calm == null else CampPerson.State.keys()[calm.state]),
		calm != null and calm.state == CampPerson.State.SEARCH and said == 1, said)

	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)
