extends Node3D
## Effect A, the leaf burst (CHANGE-BRIEF.md, "Effect A: leaf burst"): leaves burst out of
## the bush as he dives into it, and fewer as he hops out. Presentation only: it listens to
## the bush's `hiding_changed` (hide_spot.gd), reads where the bush is, and writes no game
## state; nothing in the game reads it. main.gd adds it beside the camp's bush (the brief's
## revision of 7 Nov 2026 allows that wiring).
## The retrigger rule is overlap: every event gets a fresh copy of the effect's scene, and
## a copy already playing is never touched, so a dive in and a hop straight out give two
## bursts alive at once (the brief's predicted failure 3 is a reused one-shot node).
## Each copy is freed on a timer once its longer emitter's lifetime, read from the copy,
## has passed, plus FREE_AFTER: a one-shot GPUParticles3D never emits `finished` on 4.7.2
## (CLAUDE.md, "Headless facts"). The timer pauses with the game and follows time_scale,
## as the particles do. Every setting is the scene's; this sets only where a copy stands,
## its amount_ratio for the hop-out, and emitting.
## Written by Claude Code on 7 Nov 2026.

const LeafBurst := preload("res://effects/leaf_burst.tscn")
## The hop-out's smaller burst (CHANGE-BRIEF.md, "The settings": "Hopping out").
const OUT_RATIO := 0.5
## How long past the longer emitter's lifetime a copy is kept before it's freed (seconds),
## as the preview does (previews/leaf_burst_preview.gd).
const FREE_AFTER := 0.1

## The hiding spot it follows (campsite.gd `bush`). Set before it's added.
var bush: Node3D


func _ready() -> void:
	if bush:
		bush.hiding_changed.connect(_on_hiding_changed)


func _on_hiding_changed(inside: bool) -> void:
	var burst := LeafBurst.instantiate() as Node3D
	add_child(burst)
	burst.global_position = bush.global_position
	var longest := 0.0
	for p: GPUParticles3D in burst.get_children():
		if not inside:
			p.amount_ratio = OUT_RATIO
		p.emitting = true
		longest = maxf(longest, p.lifetime)
	get_tree().create_timer(longest + FREE_AFTER, false).timeout.connect(burst.queue_free)
