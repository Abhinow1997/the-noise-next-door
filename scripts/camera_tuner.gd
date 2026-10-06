extends PanelContainer
## Live camera settings, for finding the right view while playing. Tab shows or
## hides it. "Copy numbers" puts the settings on the clipboard, ready to paste into
## a chat, so they can become the defaults in main.gd.

## [setting on main.gd, name, lowest, highest, step, unit]
const SETTINGS := [
	["camera_pitch", "Looks down", 5.0, 89.0, 1.0, "°"],
	["camera_yaw", "Turned round", -180.0, 180.0, 1.0, "°"],
	["camera_fov", "Field of view", 10.0, 75.0, 1.0, "°"],
	["camera_distance", "Distance", 1.0, 40.0, 0.5, " m"],
	["camera_ahead", "Looks past him", 0.0, 8.0, 0.1, " m"],
]
const TEXT := Color("3b3630")

## main.gd, whose camera settings the sliders change. Untyped, since the settings
## are its own properties.
var main

var _labels := {}
var _sliders := {}
var _defaults := {}
var _info: Label
var _note: Label


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4eedc")
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 6
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	add_child(box)
	box.add_child(_text("Camera   (Tab hides this)", 18))
	for setting: Array in SETTINGS:
		var label := _text("", 15)
		box.add_child(label)
		var slider := HSlider.new()
		slider.min_value = setting[2]
		slider.max_value = setting[3]
		slider.step = setting[4]
		slider.value = main.get(setting[0])
		slider.custom_minimum_size = Vector2(280, 22)
		# Keys stay with the game, so the raccoon can be moved while tuning.
		slider.focus_mode = Control.FOCUS_NONE
		slider.value_changed.connect(_on_changed.bind(setting))
		box.add_child(slider)
		_labels[setting[0]] = label
		_sliders[setting[0]] = slider
		_defaults[setting[0]] = slider.value
		_show(setting)
	_info = _text("", 13)
	box.add_child(_info)

	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	for b: Array in [["Copy numbers", _copy], ["Reset", _reset]]:
		var button := Button.new()
		button.text = b[0]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(b[1])
		buttons.add_child(button)
	_note = _text("", 13)
	box.add_child(_note)


func _process(_delta: float) -> void:
	if not visible:
		return
	var lens := 12.0 / tan(deg_to_rad(main.camera_fov) * 0.5)
	_info.text = "Camera %.1f m up, %.1f m away with zoom ×%.2f.\nLike a %d mm lens on a full-frame camera." % [
		main.camera.global_position.y, main.camera_distance * main.zoom, main.zoom, roundi(lens)]


## The settings as one line, with the wheel's zoom folded into the distance.
func numbers() -> String:
	return "Camera: looks down %d°, turned %d°, field of view %d°, distance %.1f m, looks past him %.1f m" % [
		roundi(main.camera_pitch), roundi(main.camera_yaw), roundi(main.camera_fov),
		main.camera_distance * main.zoom, main.camera_ahead * main.zoom]


func _on_changed(value: float, setting: Array) -> void:
	main.set(setting[0], value)
	_show(setting)
	_note.text = ""


func _show(setting: Array) -> void:
	var value: float = main.get(setting[0])
	var shown := ("%d" % roundi(value)) if setting[4] >= 1.0 else ("%.1f" % value)
	_labels[setting[0]].text = "%s: %s%s" % [setting[1], shown, setting[5]]


func _copy() -> void:
	DisplayServer.clipboard_set(numbers())
	print(numbers())
	_note.text = "Copied. Paste it into the chat."


func _reset() -> void:
	main.zoom = 1.0
	for key: String in _sliders:
		_sliders[key].value = _defaults[key]
	_note.text = ""


func _text(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", size)
	return label
