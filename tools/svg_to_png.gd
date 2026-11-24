extends SceneTree
## Rasterizes SVG files to PNGs at a set width, with Godot's own SVG reader (ThorVG). Headless:
##   godot --headless --path . --script res://tools/svg_to_png.gd -- <width> <out_dir> <file.svg>...
## Made on 23 Nov 2026 for the Assignment 8 NotebookLM pack's storyboard panels
## (design/a8/notebooklm/make_images.py); there's no other SVG renderer on this machine.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var width := int(args[0])
	var out_dir: String = args[1]
	DirAccess.make_dir_recursive_absolute(out_dir)
	for path in args.slice(2):
		var bytes := FileAccess.get_file_as_bytes(path)
		var probe := Image.new()
		probe.load_svg_from_buffer(bytes, 1.0)
		var img := Image.new()
		var err := img.load_svg_from_buffer(bytes, float(width) / probe.get_width())
		var out := out_dir.path_join(path.get_file().get_basename() + ".png")
		img.save_png(out)
		print(path.get_file(), " -> ", out, " ", img.get_size(), " err ", err)
	quit()
