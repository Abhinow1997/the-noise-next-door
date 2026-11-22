extends Node3D
## A close-up of the moth's flutter, for the Registration check (the course's "Use It" table: "The
## frame strip of the cycle: the character does not drift within its cells"). A fixture, not the
## game: the moth sliced and keyed exactly as in play (assets/sprites/moth_lowpoly/moth_lowpoly.png,
## hframes 2 x vframes 2, smooth filtering, animations/moth_flutter.tres, started half a frame in
## as props/moths.gd starts it), shown face on, a cell 4 m across, without its circling, so its
## four cells (wings raised, halfway up, spread flat, angled down) can be compared.
##   - Behind it, a grey square exactly one cell in size, so the cell's bounds show, and a darker
##     cross through the cell's middle, so drift shows against it.
##   - This script is the clip's only player here: it plays `flutter` once, at the start.
##   - Every frame it writes a line to logs/moth_preview_frames.log: the frame, the clip's
##     position and the cell shown, so frame N of the capture reads against line N.
## The author's capture, windowed, with Movie Maker, from the project folder:
##   ..\Godot\Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720
##     res://previews/moth_preview.tscn --write-movie captures/moth/r0/frame.png --fixed-fps 24
##     --quit-after 12
## At 24 fps, the clip's own rate, each captured frame is one frame of the clip: cells 0, 1, 2, 3,
## 2, 1, then again. Keep frames 0-5 (one cycle) and delete the rest.
## Written by Claude Code on 22 Nov 2026; on the new sheet the same day.

const LOG := "res://logs/moth_preview_frames.log"
const FPS := 24.0
## Metres per sheet pixel here: a 512 px cell 4 m across, the grey square's size.
const PIXEL := 4.0 / 512.0
## Where in the flutter it starts (s): half a frame, as props/moths.gd starts the game's moth.
const START := 1.0 / 48.0

@onready var moth: Sprite3D = $Moth
@onready var anim: AnimationPlayer = $Moth/AnimationPlayer
var _frame := -1
var _log: FileAccess


func _ready() -> void:
	moth.pixel_size = PIXEL
	anim.play("flutter")
	anim.seek(START, true)
	_log = FileAccess.open(LOG, FileAccess.WRITE)
	_line("Moth preview: the moth's cell 4 m across, flutter at rate 1 from %.4f s; frame | position s | cell" % START)


func _process(_delta: float) -> void:
	_frame += 1
	_line("%5d | %.4f | %d" % [_frame, anim.current_animation_position, moth.frame])


func _line(text: String) -> void:
	print(text)
	if _log:
		_log.store_line(text)
		_log.flush()
