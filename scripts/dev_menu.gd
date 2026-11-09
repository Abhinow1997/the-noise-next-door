extends CanvasLayer
## The developer menu, for playtesting a change without playing from the start (the
## author, 8 Nov 2026: "some element of like a developer tool ... rather than me playing
## right from the start"). Only in debug runs (the editor's, and the command line's).
##   - F1 shows or hides it. Each button restarts the level at a point (POINTS); the
##     same points start a run from the command line: `-- --dev-start=<point>`.
##   - While it's up it shows the fire's strength, what the fire keeper's doing and the
##     raccoon's place, and can put the fire out or set it burning (camp_fire.gd).
##   - F9 turns vsync off and on, for the course's frame-rate comparison (Assignment 6,
##     "Use It"); the window's title says which.
## main.gd reads the point (`take_point`) as the level starts, and sets it up.

const CampPerson := preload("res://scripts/camp_person.gd")
const POINTS := [
	["den", "From the den (no title)"],
	["camp", "Arriving at the camp"],
	["roast", "The tutorial: the roasting"],
	["free", "Free play: the fire out"],
	["fire", "Free play: the fire burning"],
]

## The point the level restarts at, kept across the reload.
static var _next := ""

var level: Node

var _panel: PanelContainer
var _status: Label


## The point to start at: one picked here before a restart, else `--dev-start=`.
static func take_point() -> String:
	var point := _next
	_next = ""
	if point == "":
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--dev-start="):
				point = arg.get_slice("=", 1)
	return point


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.position = Vector2(12, 12)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "Dev (F1)  ·  F9: vsync"
	box.add_child(title)
	for point: Array in POINTS:
		var button := Button.new()
		button.text = point[1]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_restart.bind(point[0]))
		box.add_child(button)
	box.add_child(HSeparator.new())
	for fire: Array in [["Fire: out", 0.0], ["Fire: burning", 1.0]]:
		var button := Button.new()
		button.text = fire[0]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_set_fire.bind(fire[1]))
		box.add_child(button)
	_status = Label.new()
	box.add_child(_status)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F1:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F9:
		var off := DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if off else DisplayServer.VSYNC_DISABLED)
		get_window().title = "%s (vsync %s)" % [ProjectSettings.get_setting("application/config/name"),
			"on" if off else "off"]
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	var camp = level.campsite if level else null
	if camp == null or camp.campfire == null:
		_status.text = ""
		return
	var fire = camp.campfire
	var p: Vector3 = level.player.global_position
	_status.text = "fire %.2f%s%s\nkeeper: %s\nraccoon (%.1f, %.1f)" % [fire.strength,
		"  (cycle)" if fire.cycle else "", "  bucket over" if fire.bucket_tipped else "",
		CampPerson.State.keys()[camp.keeper.state], p.x, p.z]


func _restart(point: String) -> void:
	_next = point
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func _set_fire(strength: float) -> void:
	var camp = level.campsite if level else null
	if camp and camp.campfire:
		camp.campfire.start_cycle(strength <= 0.0)
		camp.campfire.dying = false
		if strength > 0.0:
			camp.campfire.strength = strength
			camp.campfire.set_bucket_upright()
