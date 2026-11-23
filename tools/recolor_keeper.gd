extends SceneTree
## Makes the fire keeper's clothes (campsite.gd KEEPER_TEXTURE): a copy of the low-poly
## man's texture (TiZeta's "Lowpoly man", CC BY 3.0) with his shirt and trousers in new
## colours, so the camp's second low-poly man doesn't dress like the first. Asked for on
## 7 Nov 2026: "a guy is fine but update the colours of clothes of the new guy".
## Run once from the project folder, then import:
##   godot --headless --path . --script res://tools/recolor_keeper.gd
##   godot --headless --path . --import
## The texture is a 1024 px atlas: the head and hair fill the top half, the shirt the
## bottom-left quarter and the jeans the bottom-right. Each garment keeps its own shading
## (the shirt's stripes, the denim's fades): every pixel takes the new colour scaled by
## how much brighter or darker it is than its garment's average. The hands (skin) and
## anything near black (the shoes, the eyes' and brows' pieces) are left as they are.

const SOURCE := "res://assets/characters/lowpoly_man_OMO1.png"
const OUT := "res://assets/characters/lowpoly_man_keeper.png"
## A mustard work shirt and dark brown trousers (the first man wears a grey-green shirt
## and blue jeans).
const SHIRT := Color("c99a3b")
const TROUSERS := Color("4e3f2e")
## Darker than this (luminance) is left alone.
const DARK := 0.16


func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if img == null:
		push_error("Can't read %s" % SOURCE)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var half_x := w / 2
	var half_y := h / 2
	# First, each garment's average brightness over the pixels that will change.
	var sums := [0.0, 0.0]
	var counts := [0, 0]
	for y in range(half_y, h):
		for x in w:
			var c := img.get_pixel(x, y)
			if _keep(c):
				continue
			var g := 0 if x < half_x else 1
			sums[g] += _lum(c)
			counts[g] += 1
	var means := [sums[0] / maxi(counts[0], 1), sums[1] / maxi(counts[1], 1)]
	# Then the new colours.
	for y in range(half_y, h):
		for x in w:
			var c := img.get_pixel(x, y)
			if _keep(c):
				continue
			var g := 0 if x < half_x else 1
			var target: Color = SHIRT if g == 0 else TROUSERS
			var k: float = _lum(c) / means[g]
			img.set_pixel(x, y, Color(minf(target.r * k, 1.0), minf(target.g * k, 1.0), minf(target.b * k, 1.0), c.a))
	var err := img.save_png(ProjectSettings.globalize_path(OUT))
	print("Wrote %s (%d x %d): shirt mean %.3f over %d px, trousers mean %.3f over %d px, error %d" % [
		OUT, w, h, means[0], counts[0], means[1], counts[1], err])
	quit(0 if err == OK else 1)


func _lum(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b


## Skin (warm: red well above blue) and near-black stay as they are.
func _keep(c: Color) -> bool:
	if _lum(c) < DARK:
		return true
	return c.r - c.b > 0.12 and c.r > c.g
