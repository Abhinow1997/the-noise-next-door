extends SceneTree
# Calibrates tests/normal_map_check.gd on this texture set's own pair, as CHANGE-BRIEF.md's
# material plan (28 Oct 2026) says: Blue Metal Plate's _nor_gl and _nor_dx, decoded from
# the source files. The GL file should come out low with directx = false and near 2 with
# directx = true, and the DX file the other way round. Run it with:
#   bash scripts/run-test.sh normal_map_calibration.gd 60
# It prints the four ratios and asserts nothing: the threshold the material test trusts
# comes from these numbers. Written by Claude Code on 29 Oct 2026.

const NormalMapCheck := preload("res://tests/normal_map_check.gd")
const PAIR := [
	["GL", "res://assets/textures/blue_metal_plate/blue_metal_plate_nor_gl_1k.png"],
	["DX", "res://assets/textures/blue_metal_plate/blue_metal_plate_nor_dx_1k.png"],
]


func _initialize() -> void:
	print("Normal-map check, calibrated on Blue Metal Plate's pair, %s" % Time.get_datetime_string_from_system())
	for entry: Array in PAIR:
		var img := Image.load_from_file(entry[1])
		if img == null or img.is_empty():
			print("  %s: couldn't decode %s" % [entry[0], entry[1]])
			continue
		var gl := NormalMapCheck.curl_ratio(img, false)
		var dx := NormalMapCheck.curl_ratio(img, true)
		print("  %s (%s, %d x %d): directx = false %.3f, directx = true %.3f" % [entry[0], entry[1].get_file(),
			img.get_width(), img.get_height(), gl, dx])
	quit()
