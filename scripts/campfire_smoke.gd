extends Node3D
## Effect B, the campfire smoke (CHANGE-BRIEF.md, "Revised 8 Nov 2026: Effect B, the campfire
## smoke", and "Effect B's wiring, for Step 3"): one copy of effects/campfire_smoke.tscn at
## the fire pit, driven by the fire's `strength` (camp_fire.gd). Presentation only: it reads
## `strength` and `burning()`, writes nothing but its own copy, and nothing in the game reads
## it. main.gd adds it after the developer start points have set the fire.
##   - The feedback: every frame, amount_ratio = strength (0 out, 0.3 a log, 1 at full).
##     `amount` and every other setting are the scene's and are never touched (the brief's
##     predicted failure 4 is a loop that changes `amount`).
##   - Start and stop: emitting = burning(). Turned off, no new puffs come; those already in
##     the air should rise away and finish (a headless run can't show it: the strip does).
##   - The copy's state is set before it enters the tree, so the scene's 3.5 s preprocess
##     builds a column only over a burning fire, and none over a cold one.
##   - Paused, it doesn't process (it inherits the tree's pause), so nothing changes; hidden,
##     it keeps following `strength`, so there's no jump when it's shown again.
## Written by Claude Code on 8 Nov 2026.

const CampfireSmoke := preload("res://effects/campfire_smoke.tscn")

## The fire it follows (campsite.gd `campfire`). Set before it's added.
var fire: Node3D
## The copy's root (moved and hidden as a whole), and its one emitter.
var root: Node3D
var smoke: GPUParticles3D


func _ready() -> void:
	root = CampfireSmoke.instantiate() as Node3D
	smoke = root.get_node("Smoke") as GPUParticles3D
	_follow()
	add_child(root)
	root.global_position = fire.global_position


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	smoke.amount_ratio = fire.strength
	var burning: bool = fire.burning()
	if smoke.emitting != burning:
		smoke.emitting = burning
