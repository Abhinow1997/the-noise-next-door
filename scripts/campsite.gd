extends Node3D
## Level 1's campsite, right under the raccoon's tree: the party of the GDD's level 1
## and the storyboard's panels 2-8, put together on 23 Oct 2026 from the assets made
## so far, at the author's request: "lets work on creating the 1st level initial
## campsite from the assests we have humans a place for fire pit they are setting
## tents and partying". It's laid out as the storyboard has the party: the fire in the
## middle with people dancing by it, the tents on the right, the logs and the cooler
## near the fire, and string lights at the back. At first it stood right by his tree;
## the same day the author moved it about 20 seconds' walk east (forest.gd CAMP: the
## clearing, the trail to it and the forest round it).
##   - The camper (TiZeta's chubby man, in his red beanie) is pegging out his tent:
##     squatting at a guy rope, knocking its peg in with a mallet (his `hammer` loop,
##     tools/blender/animate_chubby.py).
##   - The low-poly man and the simple girl (TiZeta's too) dance between the fire and
##     the table with the laptop and the speaker (their `dance` loops), on the beat of
##     the level's music while it plays.
##   - The speaker plays the party's music as a sound in the world: loud by the camp,
##     a far-off thump at his tree (added the same day: "make the speaker play the
##     party's music as a sound in the world, loud near the camp and faint at his
##     tree"). main.gd hears the world from the raccoon.
##   - The people react to the raccoon (camp_person.gd: they take fright, the girl
##     cowers behind the low-poly man, the men guard and then chase him off); the camp
##     keeps what they know between them (saw, seen_within, in_camp, frighten).
##   - Built here: the fire pit (a ring of stones, burning logs, flickering flames,
##     sparks and the fire's light), the logs to sit on, the speaker and its cable, the
##     string lights, the mallet and the tent pegs. The tents, the table with the
##     laptop, the cooler, the s'mores, the pizza and the donut are the assets in
##     assets/props and assets/practice.
## main.gd adds it after the forest, which keeps CLEARINGS free of small things.

const LowPoly := preload("res://scripts/lowpoly.gd")
const Forest := preload("res://scripts/forest.gd")
const FireShader := preload("res://scripts/fire.gdshader")
const CampPerson := preload("res://scripts/camp_person.gd")
const Player := preload("res://scripts/player.gd")

const TENT := "res://assets/props/tent.glb"
const TABLE_WITH_LAPTOP := "res://assets/props/table_with_laptop.glb"
const COOLER := "res://assets/props/cooler.glb"
const SMORE := "res://assets/props/smore.glb"
const PIZZA_SLICE := "res://assets/props/pizza_slice.glb"
const DONUT := "res://assets/practice/donut.glb"
const CAMPER := "res://assets/characters/chubby_boy.glb"
const LOWPOLY_MAN := "res://assets/characters/lowpoly_man.glb"
const SIMPLE_GIRL := "res://assets/characters/simple_girl.glb"

## Where things stand on the ground (x, z), from the fire, which is a little west of the
## middle of the camp's clearing; and which way their fronts face in degrees (0 faces
## the camera's side, +Z; -90 faces west, back toward his tree).
const FIRE := Forest.CAMP + Vector2(-1.6, -0.5)
const CAMPER_TENT := [FIRE + Vector2(5.0, -0.4), -90.0]
const OTHER_TENT := [FIRE + Vector2(2.2, 3.6), -148.0]
const TABLE := [FIRE + Vector2(-1.2, -2.6), 0.0]
const SPEAKER := [FIRE + Vector2(0.0, -2.7), 10.0]
const COOLER_AT := [FIRE + Vector2(-1.3, 1.4), 35.0]
## The logs round the fire: middle, which way they lie (degrees), length.
const LOGS := [[FIRE + Vector2(-1.5, 0.2), 80.0, 1.5], [FIRE + Vector2(0.7, 1.4), -35.0, 1.4]]
## The dancers: who and where; they face the fire. The second is two beats behind the
## first, so they step out to opposite sides.
const DANCERS := [[LOWPOLY_MAN, FIRE + Vector2(-0.7, -1.5)], [SIMPLE_GIRL, FIRE + Vector2(0.9, -1.25)]]
const DANCE_OFFSETS := [0.0, 2.0]
## Each one's walk and run at 1x (m/s, from their animate_*.py) and how fast they chase:
## the camper, the low-poly man, the girl (who never chases).
const CAMPER_SPEEDS := [1.02, 3.28, 2.7]
const MAN_SPEEDS := [1.10, 3.56, 3.1]
const GIRL_SPEEDS := [1.04, 3.33, 0.0]
## The camp, as the people see it: within CAMP_ZONE metres of its middle. A chitter
## this near any of them is heard.
const CAMP_ZONE := 9.0
const HEAR_CHITTER := 8.0
## The camper's mallet, put down by the peg while he's away from it (in his own space).
const MALLET_DOWN := Vector3(0.25, 0.04, 0.45)
## The string lights' poles, in the order the string runs.
const POLES := [FIRE + Vector2(-2.4, -3.3), FIRE + Vector2(1.3, -3.7), FIRE + Vector2(4.1, -2.1)]
## Ground the forest keeps clear of rocks and tufts (x, z, radius).
const CLEARINGS: Array[Vector3] = [Vector3(FIRE.x, FIRE.y - 0.6, 3.0), Vector3(FIRE.x + 5.0, FIRE.y - 0.4, 1.6),
	Vector3(FIRE.x + 2.2, FIRE.y + 3.6, 1.6), Vector3(FIRE.x + 5.6, FIRE.y + 1.6, 0.7)]

## The tent's guy ropes reach the ground here, in its own space (measured in
## assets/props/tent.blend); each gets a peg. The camper pegs out the one on its +X
## side, facing CAMPER_FACING: toward the fire, side-on to the camera, so his swing
## shows.
const TENT_ROPE_ENDS := [Vector3(-2.15, 0, 0), Vector3(2.16, 0, 0)]
const CAMPER_FACING := -70.0
## The second tent isn't the camper's: its ochre walls are this green instead.
const OTHER_TENT_COLOR := Color("6f8f62")
const TENT_WALLS := "Tent_Ochre"
## In the camper's own space: the top of the peg his hammer loop strikes
## (animate_chubby.py HAMMER_PEG, in Godot's axes), and the mallet in his right hand
## (mallet_grip there prints these): its bone, the middle of his palm, the head's axis
## in the bone's space, then the handle's length and how much sticks out behind his
## hand, and the head's length and radius (MALLET).
const HAMMER_PEG := Vector3(-0.28, 0.08, 0.52)
const MALLET_BONE := "mano_L"
const MALLET_GRIP := Vector3(-0.0065, 0.0683, 0.0383)
const MALLET_ACROSS := Vector3(0, 0, -1)
const MALLET := {"handle": 0.32, "grip": 0.05, "head": 0.11, "head_r": 0.04}

## The dance loop is four beats in 64 frames at 25 fps (93.75 a minute); the level's
## music (forest-loop.wav, 16 bars in 41.768 s) runs at 91.94, with its first downbeat
## 50 ms in. The dancers are played at the music's speed and kept on its beat.
const DANCE_BPM := 93.75
const MUSIC_BPM := 91.94
const MUSIC_DOWNBEAT := 0.05
const SYNC_SLACK := 0.05
## The party's music (design/music/make_party_beat.py makes it, a stand-in until the
## author's own party track): a loop half as long as the level music's, on the same
## beat, kept there. PARTY_DB is how loud it is PARTY_NEAR metres from the speaker;
## it falls off with distance (6 dB each time the distance doubles), never louder
## than PARTY_MAX_DB, and far off loses its top above PARTY_CUTOFF Hz, so at his
## tree, 40 m away, it's about 22 dB quieter and mostly the kick and the bass.
const PARTY_MUSIC := "res://assets/audio/music/party-beat.wav"
const PARTY_DB := -4.0
const PARTY_NEAR := 3.0
const PARTY_MAX_DB := 0.0
const PARTY_CUTOFF := 2500.0
const PARTY_SLACK := 0.03

const ASH := Color("3b3735")
const CHAR := Color("2a2522")
const EMBER := Color("ff6a2a")
const FLAMES := [Color("fff0a0"), Color("ffc24a"), Color("ff8a24"), Color("e4501c")]
const FIRE_LIGHT := Color("ff9b4a")
const FIRE_ENERGY := 3.2
const FIRE_RANGE := 8.0
const WIRE := Color("2a2a2c")
const BULBS := [Color("ffd27a"), Color("ffb066"), Color("fff0c4"), Color("ff8c5c")]
const BULB_GLOW := 3.0
const STRING_LIGHT := Color("ffcf8a")
const SPEAKER_BODY := Color("2d2f34")
const SPEAKER_CONE := Color("1c1d20")
const SPEAKER_RIM := Color("4c5058")
const LED := Color("62e0ff")
const HANDLE := Color("c9a26b")
const MALLET_HEAD := Color("2c2d31")
const PEG := Color("b9bcc0")

## Set before it's added: the forest (for its night colours) and the level's music.
var forest: Forest
var music: AudioStreamPlayer
## The people, for the level: the camper (in the "camper" group, so the camera leans
## toward him) and the two dancers.
var camper: CampPerson
var dancers: Array[CampPerson] = []
var people: Array[CampPerson] = []
## What the people know between them: the clock (s), when and where he was last seen,
## and when someone last took fright.
var clock := 0.0
var last_seen := -INF
var last_seen_at := Vector3.ZERO
var frightened := -INF
## Set when the men have given up shooing him down from a tree: they let him be while
## he stays up it.
var gave_up_on_tree := false
## The party's music, playing from the speaker.
var party: AudioStreamPlayer3D

var _t := 0.0
var _fire_light: OmniLight3D
var _flames: Array[Dictionary] = []
var _dance_players: Array[AnimationPlayer] = []
var _woofer: MeshInstance3D
var _mallet_hand: MeshInstance3D
var _mallet_down: MeshInstance3D
var _player: Player


func _ready() -> void:
	_build_fire()
	for seat: Array in LOGS:
		_build_log(seat[0], seat[1], seat[2])
	var tent := _prop(TENT, CAMPER_TENT, Vector3(2.3, 1.2, 2.1))
	_add_pegs(tent)
	var other := _prop(TENT, OTHER_TENT, Vector3(2.3, 1.2, 2.1))
	_add_pegs(other)
	_recolor(other, TENT_WALLS, OTHER_TENT_COLOR)
	var table := _prop(TABLE_WITH_LAPTOP, TABLE, Vector3(1.28, 0.76, 0.83))
	_set_table(table)
	_build_speaker(table)
	var cooler := _prop(COOLER, COOLER_AT, Vector3(0.58, 0.36, 0.36))
	cooler.add_to_group("food")
	for i in 3:
		var smore := _model(SMORE, self)
		var on_log: Array = LOGS[0]
		var along := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(on_log[1]))
		smore.position = _v3(on_log[0], 0.33) + along * (-0.25 + 0.16 * i)
		smore.rotation.y = 0.7 * i
		smore.add_to_group("food")
	_build_string_lights()

	var rope_end: Vector3 = tent.transform * TENT_ROPE_ENDS[1]
	var facing := Basis(Vector3.UP, deg_to_rad(CAMPER_FACING))
	camper = _person(CAMPER, rope_end - facing * Vector3(HAMMER_PEG.x, 0, HAMMER_PEG.z), CAMPER_FACING,
		"hammer", "guy", CAMPER_SPEEDS)
	camper.add_to_group("camper")
	_give_mallet(camper)
	for i in DANCERS.size():
		var at: Vector2 = DANCERS[i][1]
		var to_fire := FIRE - at
		var dancer := _person(DANCERS[i][0], _v3(at), rad_to_deg(atan2(to_fire.x, to_fire.y)), "dance",
			"guy" if i == 0 else "girl", MAN_SPEEDS if i == 0 else GIRL_SPEEDS)
		dancer.work_speed = MUSIC_BPM / DANCE_BPM
		dancers.append(dancer)
		var anim := dancer.anim
		anim.speed_scale = dancer.work_speed
		anim.seek(fposmod(DANCE_OFFSETS[i], 4.0) * 60.0 / DANCE_BPM, true)
		_dance_players.append(anim)
	# The low-poly man looks after the girl, and comes at the raccoon from the other side.
	dancers[1].protector = dancers[0]
	dancers[0].protects = dancers[1]
	dancers[0].flank_side = -1.0
	_bake_walkways()
	_process(0.0)


func _physics_process(delta: float) -> void:
	clock += delta
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player:
			_player.chittered.connect(_on_chitter)
	if _player and not _player.climbing:
		gave_up_on_tree = false


## True while the men are letting him be up a tree (gave_up_on_tree).
func let_be() -> bool:
	return gave_up_on_tree and _player != null and _player.climbing


## Someone has just seen him at `at`.
func saw(at: Vector3) -> void:
	last_seen = clock
	last_seen_at = at


## True if someone has seen him within the last `seconds`.
func seen_within(seconds: float) -> bool:
	return clock - last_seen <= seconds


## True if `at` is in the camp, give or take `margin` metres.
func in_camp(at: Vector3, margin := 0.0) -> bool:
	return Vector2(at.x, at.z).distance_to(Forest.CAMP) < CAMP_ZONE + margin


## Someone has just taken fright: the others catch it (camp_person.gd).
func frighten() -> void:
	frightened = clock


func _on_chitter() -> void:
	for person in people:
		if person.global_position.distance_to(_player.global_position) < HEAR_CHITTER:
			person.hear()


func _process(delta: float) -> void:
	_t += delta
	var n := sin(_t * 7.3) * 0.5 + sin(_t * 13.1 + 1.7) * 0.3 + sin(_t * 23.7 + 0.4) * 0.2
	_fire_light.light_energy = FIRE_ENERGY * (1.0 + 0.12 * n)
	for flame: Dictionary in _flames:
		var ph: float = flame.phase
		var node: MeshInstance3D = flame.node
		var lick := 1.0 + 0.22 * sin(_t * flame.rate + ph) + 0.1 * sin(_t * 17.0 + ph * 2.0)
		var width := 1.0 + 0.08 * sin(_t * 9.0 + ph)
		node.scale = Vector3(flame.size * width, flame.height * lick, flame.size * width)
		node.rotation = Vector3(0.14 * sin(_t * 3.1 + ph), flame.yaw, 0.14 * sin(_t * 2.7 + ph * 1.3))
	_keep_the_beat()
	if _mallet_hand:
		# In his hand while he's hammering, down by the peg while he's not.
		_mallet_hand.visible = camper.anim.current_animation == "hammer"
		_mallet_down.visible = not _mallet_hand.visible


## Keeps the party's music on the level music's beat, the dancers on that beat, and
## the speaker thumping. With the level music stopped, the party keeps its own time.
func _keep_the_beat() -> void:
	var beats := _t * MUSIC_BPM / 60.0
	var heard := -1.0
	if music and music.playing:
		heard = music.get_playback_position()
		if party and party.playing:
			var length := party.stream.get_length()
			if absf(_wrapped(fposmod(heard, length) - party.get_playback_position(), length)) > PARTY_SLACK:
				party.seek(fposmod(heard, length))
	elif party and party.playing:
		heard = party.get_playback_position()
	if heard >= 0.0:
		heard += AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		beats = (heard - MUSIC_DOWNBEAT) * MUSIC_BPM / 60.0
		for i in _dance_players.size():
			var anim := _dance_players[i]
			if anim.current_animation != "dance":
				continue
			var want := fposmod(beats + DANCE_OFFSETS[i], 4.0) * 60.0 / DANCE_BPM
			if absf(_wrapped(want - anim.current_animation_position, anim.current_animation_length)) > SYNC_SLACK:
				anim.seek(want, true)
	var thump := pow(1.0 - fposmod(beats, 1.0), 6.0)
	_woofer.scale = Vector3(1.0 + 0.06 * thump, 1.0 + 0.06 * thump, 1.0 + 0.5 * thump)


# --- The fire ----------------------------------------------------------------

func _build_fire() -> void:
	var pit := StaticBody3D.new()
	pit.position = _v3(FIRE)
	add_child(pit)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.62
	shape.height = 0.6
	col.shape = shape
	col.position = Vector3(0, 0.3, 0)
	pit.add_child(col)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Scorched ground, the ash bed, and a ring of stones, sooty and darker than the
	# forest's rocks.
	var ground := LowPoly.loft([Vector3(0, 0.0, 0), Vector3(0, 0.008, 0)], [Vector2(0.95, 0.95), Vector2(0.95, 0.95)],
		12, LowPoly.solid(CHAR.lerp(Forest.GRASS, 0.45)))
	st.append_from(ground, 0, Transform3D.IDENTITY)
	var ash := LowPoly.loft([Vector3(0, 0.0, 0), Vector3(0, 0.03, 0)], [Vector2(0.44, 0.44), Vector2(0.4, 0.4)],
		10, LowPoly.solid(ASH))
	st.append_from(ash, 0, Transform3D.IDENTITY)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var stones := 11
	for i in stones:
		var a := TAU * (i + rng.randf_range(-0.15, 0.15)) / stones
		var r := rng.randf_range(0.11, 0.15)
		var shade := rng.randf_range(0.25, 0.4)
		LowPoly.add_icosphere(st, Vector3(cos(a) * 0.55, r * 0.55, sin(a) * 0.55), Vector3(r * 1.25, r, r), 1, 0.18,
			i, func(_n: Vector3) -> Color: return Forest.ROCK.darkened(shade), -0.3)
	# Burning logs, leaning in to the middle like a tent, charred, glowing at the ends.
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		var from := Vector3(cos(a) * 0.4, 0.05, sin(a) * 0.4)
		var to := Vector3(cos(a) * 0.06, 0.34, sin(a) * 0.06)
		var burnt := LowPoly.loft([from, from.lerp(to, 0.7), to], [Vector2(0.055, 0.055), Vector2(0.05, 0.05),
			Vector2(0.035, 0.035)], 6,
			func(segment: int, _side: int, _n: Vector3) -> Color: return EMBER if segment >= 1 else CHAR)
		st.append_from(burnt, 0, Transform3D.IDENTITY)
	_mesh(LowPoly.commit(st), pit, true)

	# The flames: a tall one in the middle and smaller ones round it, flickering.
	var flame_mesh := _flame_mesh()
	var material := ShaderMaterial.new()
	material.shader = FireShader
	for f: Array in [[Vector3(0, 0.06, 0), 0.62, 1.0], [Vector3(0.1, 0.06, 0.05), 0.42, 0.75],
			[Vector3(-0.09, 0.06, 0.07), 0.38, 0.7], [Vector3(0.02, 0.06, -0.11), 0.45, 0.8],
			[Vector3(-0.08, 0.06, -0.06), 0.33, 0.65]]:
		var flame := MeshInstance3D.new()
		flame.mesh = flame_mesh
		flame.material_override = material
		flame.position = f[0]
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		pit.add_child(flame)
		_flames.append({"node": flame, "height": f[1], "size": f[2] * 0.11, "phase": rng.randf() * TAU,
			"rate": rng.randf_range(6.0, 9.0), "yaw": rng.randf() * TAU})

	_fire_light = OmniLight3D.new()
	_fire_light.light_color = FIRE_LIGHT
	_fire_light.light_energy = FIRE_ENERGY
	_fire_light.omni_range = FIRE_RANGE
	_fire_light.omni_attenuation = 1.4
	_fire_light.shadow_enabled = true
	_fire_light.position = Vector3(0, 0.7, 0)
	_fire_light.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pit.add_child(_fire_light)

	var sparks := CPUParticles3D.new()
	sparks.amount = 14
	sparks.lifetime = 1.6
	sparks.position = Vector3(0, 0.35, 0)
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 0.12
	sparks.direction = Vector3.UP
	sparks.spread = 20.0
	sparks.gravity = Vector3(0, 0.25, 0)
	sparks.initial_velocity_min = 0.45
	sparks.initial_velocity_max = 0.9
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.75, 0.35, 1.0))
	ramp.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
	sparks.color_ramp = ramp
	var dot := QuadMesh.new()
	dot.size = Vector2(0.025, 0.025)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.vertex_color_use_as_albedo = true
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dot.material = glow
	sparks.mesh = dot
	pit.add_child(sparks)


## One flame, 1 m tall and 1 m round, scaled by each: a bulb that licks up to a point,
## pale at the root and red at the tip.
func _flame_mesh() -> ArrayMesh:
	return LowPoly.loft([Vector3(0, 0, 0), Vector3(0, 0.22, 0), Vector3(0, 0.55, 0), Vector3(0, 1.0, 0)],
		[Vector2(0.7, 0.7), Vector2(1.0, 1.0), Vector2(0.55, 0.55), Vector2(0.02, 0.02)], 6,
		func(segment: int, _side: int, _n: Vector3) -> Color: return FLAMES[clampi(segment, 0, FLAMES.size() - 1)])


# --- Logs, props and pegs ------------------------------------------------------

## A log to sit on: its bark the forest's LOG, its cut ends WOOD, with a collider.
func _build_log(at: Vector2, deg: float, length: float) -> void:
	var body := StaticBody3D.new()
	body.position = _v3(at)
	body.rotation.y = deg_to_rad(deg)
	add_child(body)
	var r := 0.17
	var mesh := LowPoly.loft([Vector3(-length * 0.5, r, 0), Vector3(-length * 0.15, r * 1.04, 0),
		Vector3(length * 0.2, r * 0.98, 0), Vector3(length * 0.5, r, 0)],
		[Vector2(r, r), Vector2(r * 1.04, r * 1.04), Vector2(r * 0.98, r * 0.98), Vector2(r * 0.95, r * 0.95)], 8,
		func(segment: int, _side: int, _n: Vector3) -> Color: return Forest.WOOD if segment < 0 or segment > 2 else Forest.LOG)
	_mesh(mesh, body, true)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, r * 2.0, r * 2.0)
	col.shape = shape
	col.position = Vector3(0, r, 0)
	body.add_child(col)


## One of the assets, standing at `place` ([x, z], degrees), with a box collider of
## `size` on the ground under it.
func _prop(path: String, place: Array, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = _v3(place[0])
	body.rotation.y = deg_to_rad(place[1])
	add_child(body)
	_model(path, body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)
	return body


func _model(path: String, parent: Node) -> Node3D:
	var model: Node3D = (load(path) as PackedScene).instantiate()
	parent.add_child(model)
	return model


## Gives every surface of `node` whose material is called `material` the colour `c`
## instead, in a copy of that material.
func _recolor(node: Node, material: String, c: Color) -> void:
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if mat and mat.resource_name == material:
				var copy := mat.duplicate() as BaseMaterial3D
				copy.albedo_color = c
				mi.set_surface_override_material(s, copy)


## Pegs where the tent's guy ropes reach the ground.
func _add_pegs(tent: Node3D) -> void:
	for end: Vector3 in TENT_ROPE_ENDS:
		_mesh(_peg_mesh(), tent).position = end


func _peg_mesh() -> ArrayMesh:
	return LowPoly.loft([Vector3(0, 0, 0), Vector3(0, HAMMER_PEG.y, 0)], [Vector2(0.012, 0.012),
		Vector2(0.016, 0.016)], 5, LowPoly.solid(PEG))


## The table's food: five slices of the pizza left (the pizza-slice asset five times,
## as in the asset room) and the donut, beside the laptop.
func _set_table(table: Node3D) -> void:
	var pizza := Node3D.new()
	pizza.position = Vector3(-0.38, 0.742, 0.12)
	table.add_child(pizza)
	for k in 5:
		var slice := _model(PIZZA_SLICE, pizza)
		slice.rotation.y = k * PI / 4.0
		slice.position = -(Basis(Vector3.UP, k * PI / 4.0) * Vector3(0, 0, 0.1))
	var donut := _model(DONUT, table)
	donut.position = Vector3(0.46, 0.742, 0.22)


# --- The people ----------------------------------------------------------------

## Where the people can walk round the camp, so they go round the tents, the fire and
## the trees rather than into them: a navigation mesh baked over the camp and a little
## beyond it from the level's static colliders (the forest's trunks and walls, the
## campsite's props), on a flat floor.
func _bake_walkways() -> void:
	var map := get_world_3d().navigation_map
	var nav := NavigationMesh.new()
	nav.cell_size = NavigationServer3D.map_get_cell_size(map)
	nav.cell_height = NavigationServer3D.map_get_cell_height(map)
	# Whole cells, as the bake rounds them up anyway.
	nav.agent_radius = nav.cell_size * 2.0
	nav.agent_height = nav.cell_height * 7.0
	nav.agent_max_climb = nav.cell_height
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = 1
	var reach := CAMP_ZONE + 6.0
	nav.filter_baking_aabb = AABB(Vector3(Forest.CAMP.x - reach, -1.0, Forest.CAMP.y - reach),
		Vector3(reach * 2.0, 4.0, reach * 2.0))
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav, source, get_parent())
	var a := Vector3(Forest.CAMP.x - reach, 0.0, Forest.CAMP.y - reach)
	var b := Vector3(Forest.CAMP.x + reach, 0.0, Forest.CAMP.y + reach)
	source.add_faces(PackedVector3Array([a, Vector3(b.x, 0, a.z), b, a, b, Vector3(a.x, 0, b.z)]),
		Transform3D.IDENTITY)
	NavigationServer3D.bake_from_source_geometry_data(nav, source)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	add_child(region)


## One of the humans at `at`, facing `deg`, at work playing `clip` (looped on import),
## a "guy" or the "girl" (camp_person.gd), with their `speeds` (walk, run, chase), and a
## capsule to stop the raccoon.
func _person(path: String, at: Vector3, deg: float, clip: String, role: String, speeds: Array) -> CampPerson:
	var body := CampPerson.new()
	body.name = path.get_file().get_basename()
	body.position = at
	body.rotation.y = deg_to_rad(deg)
	body.post = Transform3D(Basis(Vector3.UP, deg_to_rad(deg)), at)
	body.role = role
	body.work_clip = clip
	body.walk_natural = speeds[0]
	body.run_natural = speeds[1]
	body.chase_speed = speeds[2]
	body.camp = self
	body.model = _model(path, body)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.6
	col.shape = shape
	col.position = Vector3(0, 0.8, 0)
	body.add_child(col)
	add_child(body)
	people.append(body)
	return body


## The camper's mallet, in his right hand: its handle runs from his palm toward his
## fingers, its rubber head across the end of it.
func _give_mallet(person: Node3D) -> void:
	var skeletons := person.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var hand := BoneAttachment3D.new()
	hand.bone_name = MALLET_BONE
	skeletons[0].add_child(hand)
	var up := Vector3.UP
	var tip: Vector3 = MALLET_GRIP + up * (MALLET.handle - MALLET.grip)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(LowPoly.loft([MALLET_GRIP - up * MALLET.grip, tip], [Vector2(0.014, 0.014), Vector2(0.014, 0.014)],
		6, LowPoly.solid(HANDLE)), 0, Transform3D.IDENTITY)
	var half: Vector3 = MALLET_ACROSS * MALLET.head * 0.5
	st.append_from(LowPoly.loft([tip - half, tip + half], [Vector2(MALLET.head_r, MALLET.head_r),
		Vector2(MALLET.head_r, MALLET.head_r)], 8, LowPoly.solid(MALLET_HEAD)), 0, Transform3D.IDENTITY)
	var mallet := LowPoly.commit(st)
	_mallet_hand = _mesh(mallet, hand)
	# And lying by the peg, for while he's away from it: its handle along the ground.
	_mallet_down = _mesh(mallet, self)
	_mallet_down.transform = person.transform * Transform3D(Basis.from_euler(Vector3(0, 0.4, PI / 2)), MALLET_DOWN)
	_mallet_down.visible = false


# --- The music corner and the lights --------------------------------------------

## The speaker beside the table, its woofer thumping on the beat, and its cable to
## the table.
func _build_speaker(table: Node3D) -> void:
	var body := StaticBody3D.new()
	body.position = _v3(SPEAKER[0])
	body.rotation.y = deg_to_rad(SPEAKER[1])
	add_child(body)
	var size := Vector3(0.36, 0.6, 0.3)
	_mesh(LowPoly.box(size, SPEAKER_BODY), body).position = Vector3(0, size.y * 0.5, 0)
	for ring: Array in [[0.21, 0.12], [0.47, 0.055]]:
		_mesh(LowPoly.loft([Vector3(0, 0, 0), Vector3(0, 0, 0.012)], [Vector2(ring[1], ring[1]),
			Vector2(ring[1], ring[1])], 10, LowPoly.solid(SPEAKER_RIM)), body).position = Vector3(0, ring[0], size.z * 0.5)
	_woofer = _mesh(LowPoly.loft([Vector3(0, 0, 0), Vector3(0, 0, 0.025)], [Vector2(0.095, 0.095), Vector2(0.03, 0.03)],
		10, LowPoly.solid(SPEAKER_CONE)), body)
	_woofer.position = Vector3(0, 0.21, size.z * 0.5 + 0.01)
	_woofer.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var led := MeshInstance3D.new()
	var dot := SphereMesh.new()
	dot.radius = 0.012
	dot.height = 0.024
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = _glow_material(LED, 2.5)
	led.mesh = dot
	led.position = Vector3(0.13, 0.56, size.z * 0.5)
	body.add_child(led)
	if ResourceLoader.exists(PARTY_MUSIC):
		party = AudioStreamPlayer3D.new()
		party.stream = load(PARTY_MUSIC)
		party.bus = "SFX"
		party.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		party.unit_size = PARTY_NEAR
		party.volume_db = PARTY_DB
		party.max_db = PARTY_MAX_DB
		party.attenuation_filter_cutoff_hz = PARTY_CUTOFF
		party.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		party.position = Vector3(0, 0.3, size.z * 0.5)
		body.add_child(party)
		party.play()
	else:
		push_warning("The party's music isn't imported yet: %s" % PARTY_MUSIC)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)

	# The cable, along the ground from the back of the speaker to the table's leg.
	var from := body.transform * Vector3(-0.1, 0.012, -size.z * 0.5)
	var to := table.transform * Vector3(0.6, 0.012, -0.36)
	var mid := from.lerp(to, 0.5) + Vector3(0, 0, -0.25)
	var points := []
	var radii := []
	for i in 9:
		var s := i / 8.0
		points.append(from.lerp(mid, s).lerp(mid.lerp(to, s), s))
		radii.append(Vector2(0.008, 0.008))
	_mesh(LowPoly.loft(points, radii, 4, LowPoly.solid(WIRE)), self)


## String lights at the back: a wire sagging between wooden poles, with warm bulbs
## hanging from it that glow, and a soft light under each span.
func _build_string_lights() -> void:
	var top := 2.15
	var meshes := []
	for c: Color in BULBS:
		var bulb := SphereMesh.new()
		bulb.radius = 0.03
		bulb.height = 0.07
		bulb.radial_segments = 6
		bulb.rings = 3
		bulb.material = _glow_material(c, BULB_GLOW)
		meshes.append(bulb)
	var count := 0
	for i in POLES.size():
		var p := _v3(POLES[i])
		_mesh(LowPoly.loft([p, p + Vector3(0, top + 0.08, 0)], [Vector2(0.04, 0.04), Vector2(0.035, 0.035)], 6,
			LowPoly.solid(Forest.LOG)), self, true)
		if i == POLES.size() - 1:
			break
		var a := p + Vector3(0, top, 0)
		var b := _v3(POLES[i + 1]) + Vector3(0, top, 0)
		var span := a.distance_to(b)
		var sag := 0.12 * span
		var points := []
		var radii := []
		for k in 13:
			var s := k / 12.0
			points.append(a.lerp(b, s) - Vector3(0, sag * 4.0 * s * (1.0 - s), 0))
			radii.append(Vector2(0.006, 0.006))
		_mesh(LowPoly.loft(points, radii, 4, LowPoly.solid(WIRE)), self)
		var bulbs := int(span / 0.32)
		for k in range(1, bulbs):
			var s := float(k) / bulbs
			var bulb := MeshInstance3D.new()
			bulb.mesh = meshes[count % meshes.size()]
			bulb.position = a.lerp(b, s) - Vector3(0, sag * 4.0 * s * (1.0 - s) + 0.05, 0)
			bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(bulb)
			count += 1
		var glow := OmniLight3D.new()
		glow.light_color = STRING_LIGHT
		glow.light_energy = 0.7
		glow.omni_range = 3.2
		glow.position = a.lerp(b, 0.5) - Vector3(0, sag + 0.3, 0)
		add_child(glow)


# --- Helpers -------------------------------------------------------------------

func _mesh(mesh: Mesh, parent: Node, at_night := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = forest.night_mesh(mesh) if at_night and forest else mesh
	parent.add_child(mi)
	return mi


func _glow_material(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


## `x` moved by whole `length`s to within half a length of 0: how far apart two
## places in a loop are, the short way round.
func _wrapped(x: float, length: float) -> float:
	return fposmod(x + length * 0.5, length) - length * 0.5


func _v3(p: Vector2, y := 0.0) -> Vector3:
	return Vector3(p.x, y, p.y)
