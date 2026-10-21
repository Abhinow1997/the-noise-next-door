extends Control
## One thought icon on the screen, drawn by scribbles.gd as loose, hand-scribbled lines.
## It pops in over a few jerky frames, hovers with a stepped bob as if animated by hand
## while its lines boil (it cycles through BOILS slightly different drawings), and
## shrinks away. thought_bubbles.gd says what to draw, where it hangs (`anchor`) and how
## big the raccoon is on the screen (`unit`), every frame.

const Scribbles := preload("res://scripts/scribbles.gd")

## Its motion moves in steps, Scribbles.STEPS a second, held in between like a drawing
## animated by hand; its lines boil at BOIL drawings a second, round BOILS drawings.
const BOIL := 8.0
const BOILS := 3
## The pop: its size on each step as it appears. Going: its size and opacity on each step.
const POP := [0.55, 1.22, 0.9, 1.05, 1.0]
const GO := [[0.85, 0.85], [0.6, 0.55], [0.35, 0.25]]
## The hover, in units of his height on screen: up and down BOB, BOB_RATE times a
## second; a slow sway of SWAY degrees; and a little unsteadiness on every step.
const BOB := 0.03
const BOB_RATE := 0.55
const SWAY := 2.0
const SWAY_RATE := 0.43
const UNSTEADY := 0.006
## The alert shakes instead, on every step: up to SHAKE units and SHAKE_TURN degrees,
## more as it pops in.
const SHAKE := 0.022
const SHAKE_TURN := 3.0
## Icons that move by themselves rather than bobbing: the glints twinkle in place over
## the loot, the z's float up, and the sigh puffs out of his mouth.
const STILL := ["sparkles", "zzz", "snooze", "sigh"]

enum Phase { HIDDEN, UP, LEAVING }

## The screen point it hangs over, and the raccoon's height on screen in pixels.
var anchor := Vector2.ZERO
var unit := 90.0
## Freed once it has gone (the glints over loot).
var free_when_gone := false
## Drawn mirrored, left to right (the sigh, when he faces left).
var flip := false

var _phase := Phase.HIDDEN
var _icon := ""
var _age := 0.0
var _gone := 0.0
## Steps since a second ask for the icon that's up, or -1.
var _bump := -1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Pops `icon` up (see scribbles.gd), straight away: one that's up or going is simply
## replaced, as a hand-drawn frame would be. The same one again just pops once more.
func show_icon(icon: String) -> void:
	if _phase == Phase.UP and icon == _icon:
		bump()
		return
	_pop(icon)


## Shrinks the icon away.
func hide_icon() -> void:
	if _phase == Phase.UP:
		_leave()


## Pops the icon that's up once more, when it's asked for again.
func bump() -> void:
	if _phase == Phase.UP and _age * Scribbles.STEPS >= POP.size():
		_bump = 0.0


## The icon that's up, or "" when there's none or it's on its way out.
func current() -> String:
	return _icon if _phase == Phase.UP else ""


## True while it's popping in.
func popping() -> bool:
	return _phase == Phase.UP and _age * Scribbles.STEPS < POP.size()


func _pop(icon: String) -> void:
	_icon = icon
	_phase = Phase.UP
	_age = 0.0
	_bump = -1.0
	queue_redraw()


func _leave() -> void:
	_phase = Phase.LEAVING
	_gone = 0.0


func _process(delta: float) -> void:
	if _phase == Phase.HIDDEN:
		return
	_age += delta
	if _bump >= 0.0:
		_bump += delta
		if _bump * Scribbles.STEPS >= POP.size() - 1:
			_bump = -1.0
	if _phase == Phase.LEAVING:
		_gone += delta
		if _gone * Scribbles.STEPS >= GO.size():
			_phase = Phase.HIDDEN
			queue_redraw()
			if free_when_gone:
				queue_free()
			return
	queue_redraw()


func _draw() -> void:
	if _phase == Phase.HIDDEN:
		return
	var step := int(_age * Scribbles.STEPS)
	var held := step / Scribbles.STEPS
	var list := Scribbles.strokes(_icon, int(_age * BOIL) % BOILS, step)
	var grow: float = POP[step] if step < POP.size() else 1.0
	var alpha := 1.0
	if _bump >= 0.0:
		grow *= float(POP[mini(int(_bump * Scribbles.STEPS) + 1, POP.size() - 1)])
	if _phase == Phase.LEAVING:
		var go: Array = GO[mini(int(_gone * Scribbles.STEPS), GO.size() - 1)]
		grow *= go[0]
		alpha = go[1]
	# The hover and the shake both move in steps, with a different wobble each step.
	var jitter := RandomNumberGenerator.new()
	jitter.seed = step * 92821 + hash(_icon)
	var offset := Vector2(jitter.randf_range(-1.0, 1.0), jitter.randf_range(-1.0, 1.0)) * UNSTEADY
	var turn := 0.0
	if _icon == "alert":
		var shake := 1.0 + 1.5 * exp(-_age * 4.0)
		offset = Vector2(jitter.randf_range(-1.0, 1.0), jitter.randf_range(-1.0, 1.0)) * SHAKE * shake
		turn = deg_to_rad(jitter.randf_range(-1.0, 1.0) * SHAKE_TURN * shake)
	elif _icon not in STILL:
		offset += Vector2(sin(held * TAU * 0.31) * 0.015, sin(held * TAU * BOB_RATE) * BOB)
		turn = deg_to_rad(sin(held * TAU * SWAY_RATE) * SWAY)
	Scribbles.draw(self, list, anchor + offset * unit, unit * grow, turn, alpha, flip)
