# The Noise Next Door: Assignment 7 code excerpts (for the explainer)

Exact excerpts from the repository at the branch `assignment-7`, copied by Claude Code on 22 Nov 2026 and still the same at commit `8bf28c9`, so that NotebookLM can read them; it can't open `.gd`, `.tres` or `.import` files. Each excerpt names its file and first line.

## The moth's clip, the whole file

The sprite clip, saved as a resource: one value track on the sprite's `frame`, discrete updates, six keys out and back, 6/24 s, `step` 1/24, `LOOP_LINEAR` (`loop_mode = 1`).

`animations/moth_flutter.tres`:

```
[gd_resource type="Animation" format=3]

; The moth's flutter (CHANGE-BRIEF.md, revision of 22 Nov 2026, "one moth, on my own low-poly sheet,
; over the fire"): cells 0-3 of assets/sprites/moth_lowpoly/moth_lowpoly.png (wings raised, halfway
; up, spread flat, angled down; hframes 2, vframes 2) on the moth's Sprite3D frame, out and back:
; 0, 1, 2, 3, 2, 1, each held 1 frame at 24 fps, keys at frames 0-5 (0 to 5/24 s), length 6/24 s,
; step 1/24 s, discrete updates, LOOP_LINEAR. The seam: the last key is cell 1, the first cell 0,
; and the last gap (5/24 to 6/24 s) is the key interval, 1/24 s. The track's path is relative to
; the moth's AnimationPlayer's root_node (its Sprite3D, in props/moths.tscn).

[resource]
resource_name = "flutter"
length = 0.25
loop_mode = 1
step = 0.041666668
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath(".:frame")
tracks/0/interp = 0
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.041666668, 0.083333336, 0.125, 0.16666667, 0.20833333),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1, 1),
"update": 1,
"values": [0, 1, 2, 3, 2, 1]
}
```

## Where the rig's loop modes live

The importer's per-animation settings, so a reimport from an empty cache keeps them. For the nine clips, `settings/loop_mode` is 1 (`LOOP_LINEAR`) for idle, walk, run, sneak, bored, sleep and climb, and 0 (`LOOP_NONE`) for jump and jump_land. This is the first clip's entry.

`assets/characters/raccoon_v2.glb.import`, from line 42:

```ini
_subresources={
"animations": {
"bored": {
"save_to_file/enabled": false,
"save_to_file/fallback_path": "",
"save_to_file/keep_custom_tracks": "",
"save_to_file/path": "",
"settings/loop_mode": 1,
```

## The rig's clips keyed in Blender, from the phase table

The seven loops sampled over their frames, and the two one-shots keyed at the phase table's frames: `jump` at 0, 3, 6 and 10, and `jump_land` at 0 and 4.

`design/character/raccoon_v2/anim.py`, from line 624:

```python
make("idle", 96, idle)
make("walk", 24, walk)
make("run", 16, run, steady=0.25)
make("sneak", 48, sneak)
make("bored", 96, bored)
make("sleep", 96, sleep)
make("climb", 24, climb)
# The one-shots. jump (revision of 21 Nov 2026), 10 frames at 24 fps; each key's time:
#   frame 0  = 0.0 s     the push-off
#   frame 3  = 0.125 s   stretched up, snout first
#   frame 6  = 0.25 s    gathered at the top
#   frame 10 = 0.4167 s  front paws reaching down (the landing, a held jump's tick 25)
# Out of the push (r1: the bunch) fast and slowing into the stretch (0-3), as the rise slows;
# easing over the top (3-6); falling into the reach, slow then faster (6-10). jump_land: out
# of the squash, settling (0-4).
make_oneshot("jump", [(0, jump_push), (3, jump_stretch), (6, jump_gather), (10, jump_reach)],
             {0: ("QUAD", "EASE_OUT"), 3: ("SINE", "EASE_IN_OUT"), 6: ("QUAD", "EASE_IN")})
make_oneshot("jump_land", [(0, land_squash), (4, stance)], {0: ("QUAD", "EASE_OUT")})
```

## The jump's movement: takeoff on the physics tick

The game reads the jump here, on the physics tick, not from the clip. `model.jump_id` starts a new `jump` clip for each takeoff.

`scripts/player.gd`, from line 364:

```gdscript
	# Jumping: off at once (or as soon as he can, for a press just before he lands, which
	# also cuts a landing short), up under a snappy pull that's stronger still if F is let
	# go, down faster still. Each takeoff is a new jump for the model's clips (jump_id).
	_jump_press = maxf(_jump_press - delta, 0.0)
	_coyote = JUMP_COYOTE if is_on_floor() and not jumping else maxf(_coyote - delta, 0.0)
	if _jump_press > 0.0 and _coyote > 0.0:
		_jump_press = 0.0
		_coyote = 0.0
		jumping = true
		jump_from_y = global_position.y
		_air_t = 0.0
		_land_tick = -1
		velocity.y = sqrt(2.0 * JUMP_GRAVITY * JUMP_HEIGHT)
		model.jump_id += 1
	if jumping:
		var pull := JUMP_GRAVITY if velocity.y > 0.0 else FALL_GRAVITY
		if velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			pull *= JUMP_CUT
		velocity.y -= pull * delta
```

## The one authority: the state machine picks the clip

The only script that plays, seeks or speeds the rig's `AnimationPlayer` (`_anim`). The jump comes first, from takeoff until it's soaked up.

`scripts/raccoon_model.gd`, from line 543:

```gdscript
func _change_animation(anim_name: String) -> void:
	var from := _anim.current_animation
	var phase := -1.0
	if from in GAITS and anim_name in GAITS and "climb" not in [from, anim_name] and leap < 0.0:
		phase = _anim.current_animation_position / maxf(_anim.current_animation_length, 0.001)
	var blend := GAIT_BLEND if from in LOCOMOTION and anim_name in LOCOMOTION else RIGGED_BLEND
	if anim_name in ONE_SHOTS:
		blend = JUMP_BLEND
	_anim.play(anim_name, blend)
	if anim_name == "jump":
		_played_jump = jump_id
	if phase >= 0.0:
		_anim.seek(phase * _anim.current_animation_length, true)


func _rigged_state(delta: float) -> String:
	# The jump first (CHANGE-BRIEF.md, "The state machine"): from takeoff (or a hop off a
	# tree) until `landed`, then the landing until it's soaked up.
	if jumping:
		_still = 0.0
		return "jump_land" if landing else "jump"
```

## The course's track check, branching on track type

Why a misnamed track is caught: a bone track's subname must be a bone of the `Skeleton3D`, and a value track's must be a property of its node.

`tests/track_check.gd`, from line 10:

```gdscript
static func track_problems(player: AnimationPlayer) -> Array[String]:
	var problems: Array[String] = []
	var root := player.get_node_or_null(player.root_node)
	if root == null:
		problems.append("root_node %s resolves to nothing" % player.root_node)
		return problems
	for clip_name in player.get_animation_list():
		var clip := player.get_animation(clip_name)
		for t in clip.get_track_count():
			var path := clip.track_get_path(t)
			var node := root.get_node_or_null(NodePath(path.get_concatenated_names()))
			if node == null:
				problems.append("%s track %d: no node at %s" % [clip_name, t, path])
				continue
			if path.get_subname_count() == 0:
				continue
			var sub := path.get_subname(0)
			match clip.track_get_type(t):
				Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D:
					var skeleton := node as Skeleton3D
					if skeleton == null or skeleton.find_bone(sub) == -1:
						problems.append("%s track %d: no bone %s on %s" % [clip_name, t, sub, node.name])
				Animation.TYPE_BLEND_SHAPE:
					var mesh := node as MeshInstance3D
					if mesh == null or mesh.find_blend_shape_by_name(sub) == -1:
						problems.append("%s track %d: no blend shape %s on %s" % [clip_name, t, sub, node.name])
				_:
					if not (sub in node):
						problems.append("%s track %d: %s has no property %s" % [clip_name, t, node.name, sub])
	return problems
```

## The one-authority check in the state test

Every `play()`, `seek()` and `speed_scale` in `raccoon_model.gd` is on the rig's player, and no other script reaches it.

`tests/test_jump_states.gd`, from line 268:

```gdscript
	var calls := RegEx.create_from_string("([A-Za-z_][A-Za-z0-9_]*)\\.(play|seek)\\(|([A-Za-z_][A-Za-z0-9_]*)\\.speed_scale\\s*=")
	var off: Array = []
	var on_anim := 0
	for m in calls.search_all(model_src):
		var who := m.get_string(1) if m.get_string(1) != "" else m.get_string(3)
		if who == "_anim":
			on_anim += 1
		else:
			off.append(m.get_string(0))
	_check("raccoon_model.gd: every play(), seek() and speed_scale is on _anim, the rig's player (%d)" % on_anim,
		off.is_empty() and on_anim > 0, off)
	var reach: Array = []
	for path: String in files:
		if path != "res://scripts/raccoon_model.gd" and (files[path].contains("._anim") or files[path].contains("\"_anim\"")):
			reach.append(path)
	_check("no other game script reaches the rig's player (_anim)", reach.is_empty(), reach)
	_check("player.gd has no AnimationPlayer and no _anim (it writes the model's inputs only)",
```

## The seam rule for the moth's frame track, in its read-back

The last key's cell differs from the first's, and the gap from the last key to the length equals the key interval.

`tests/test_moth_flutter.gd`, from line 127:

```gdscript
	if cells.size() >= 2 and times.size() == cells.size():
		_check(cells[-1] != cells[0], "the seam: the last key's cell differs from the first's", "last %s, first %s" % [cells[-1], cells[0]])
		var interval: float = times[1] - times[0]
		var gap: float = clip.length - times[-1]
		_check(_near(gap, interval), "the seam: the gap from the last key to the length equals the key interval",
			"gap %.6f, interval %.6f" % [gap, interval])
```

## The moth's guide: its distances and timings

Presentation only: it reads where he is, the trail and the task, and writes nothing in the game.

`props/moths.gd`, from line 46:

```gdscript
## The guide: where the way starts (by his tree, x and z; then the trail), how far ahead of him it
## leads (m), how far from him it lets itself get (m), how close to his head it ever comes (m),
## where his head is (m above his feet), and how fast it can fly (m/s; he runs at 4).
const WAY_START := Vector2(0.0, 3.4)
const LEAD := 3.0
const LEASH := 4.5
const MIN_REACH := 0.25
const HEAD := 0.42
const MAX_SPEED := 6.5
## Buzzing round his head: how far out (m), how high over it (m), how fast round (rad/s), how often
## it dips as if to land (s) and for how long, and how far out it darts after (m).
const BUZZ_RADIUS := 0.42
const BUZZ_HIGH := 0.18
const BUZZ_SPIN := 3.2
const DIP_EVERY := 2.4
const DIP_TIME := 0.45
const DART_RADIUS := 0.8
## Leading: how high over the ground (m). He counts as moving above MOVING m/s.
const LEAD_HIGH := 0.95
const MOVING := 0.4
## Where it flutters in from, off to the side in the trees (m from him).
const COMES_FROM := Vector3(2.5, 1.6, -3.0)
```
