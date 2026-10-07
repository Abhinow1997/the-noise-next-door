extends SceneTree
## Cuts the generated environment props out of their green screens, for the game,
## with the same colour key as the raccoon's poses. Writes each one to
## assets/environment/<prop>.png, and props.json with its ground point.
##
## Run it from the project folder:
##   godot --headless --path . --script res://design/environment/make_props.gd

const Sheet := preload("res://design/character/make_character_sheet.gd")
const OUT := "res://assets/environment/"

## Prop name, generated original.
const PROPS := [
	["stump", "res://design/reference/stump.jpg"],
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var metrics := {}
	for p in PROPS:
		var c: Dictionary = Sheet.cut_out(p[1])
		c.image.save_png(OUT + p[0] + ".png")
		metrics[p[0]] = {"feet_row": c.feet, "anchor_x": snappedf(c.anchor, 0.1), "height_px": c.h, "width_px": c.w}
		print("%s: %d x %d px, %s, feet row %d, anchor %.1f" % [p[0], c.w, c.h, c.kind, c.feet, c.anchor])
	var f := FileAccess.open(OUT + "props.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(metrics, "  ", false))
	f.close()
	quit()
