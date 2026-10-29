# Materials audit

`the-noise-next-door` · CSYE 7270 · Assignment 5 · 29 Oct 2026 · branch `assignment-5`

An audit of the materials named in CHANGE-BRIEF.md: the textured shader's two cooler materials and the hint experiment's one material. Read from the files as committed at `3603922`, before any change. `tests/test_materials.gd` asserts every table here (`bash scripts/run-test.sh test_materials.gd 60`). The vision cone's material is made in code and is checked by `tests/cone_shader_test.gd`, so it isn't audited here.

## The materials

| Material | Shader | Uniform values it sets | Textures it binds |
|---|---|---|---|
| `materials/cooler_body.tres` (`Cooler_Blue`, the body) | `shaders/cooler_paint.gdshader` | `tint` Color(0.23137255, 0.49019608, 0.7490196, 1) = `#3B7DBF`; `detail` 0.6; `uv_scale` 1.0; `roughness_scale` 1.0; `normal_strength` 1.0; `render_priority` 0 | `albedo_texture` ← `blue_metal_plate_diff_1k.png`; `roughness_texture` ← `blue_metal_plate_rough_1k.png`; `normal_texture` ← `blue_metal_plate_nor_gl_1k.png` |
| `materials/cooler_lid.tres` (`Cooler_White`, the lid) | `shaders/cooler_paint.gdshader` | `tint` Color(0.9490196, 0.9490196, 0.93333334, 1) = `#F2F2EE`; `detail` 0.25; `uv_scale` 1.0; `roughness_scale` 0.6; `normal_strength` 0.5; `render_priority` 0 | the same three textures, to the same samplers |
| `hint_experiment/split_quad.tres` (the one quad) | `shaders/hint_experiment.gdshader` | none; it has no value uniforms; `render_priority` 0 | `with_source_color` ← `hint_experiment/greys_3x1.png`; `without_source_color` ← the same file |

- Every value matches the brief's "two materials" table (material plan, revised 28 Oct). Both cooler materials load `res://shaders/cooler_paint.gdshader` and are two separate resources.
- They reach the cooler through `assets/props/cooler.glb.import`'s `_subresources` (Use External, with `use_external/path` and `use_external/fallback_path` both set). Loaded headless, `cooler.glb` has one surface on each and three on the embedded `Cooler_Grey`, and the asset room's `Cooler` node overrides none of them. At the camp, `campsite.gd` instances the same scene with `_model()` and doesn't recolour it.
- The textured shader's defaults, from its source: `tint` `vec4(1.0)`, `detail` 0.5, `uv_scale` 1.0, `roughness_scale` 1.0, `normal_strength` 1.0. Both materials set every value uniform explicitly, so none falls back to a default.

## The samplers

Hints are copied from the source. Import settings are from each `.import` file: `compress/mode` 0 is Lossless and 2 VRAM Compressed; `compress/normal_map` 1 is Enable and 2 Disable.

| Shader | Sampler | Hints, as written | Group | Bound (both materials) | `compress/mode` | `compress/normal_map` | `mipmaps/generate` |
|---|---|---|---|---|---|---|---|
| `cooler_paint.gdshader` (line 9) | `albedo_texture` | `source_color, filter_linear_mipmap, repeat_enable` | `colour` | `blue_metal_plate_diff_1k.png` | 2 VRAM Compressed | 2 Disable | true |
| `cooler_paint.gdshader` (line 14) | `roughness_texture` | `hint_default_white, filter_linear_mipmap, repeat_enable` | `surface` | `blue_metal_plate_rough_1k.png` | 2 VRAM Compressed | 2 Disable | true |
| `cooler_paint.gdshader` (line 15) | `normal_texture` | `hint_normal, filter_linear_mipmap, repeat_enable` | `surface` | `blue_metal_plate_nor_gl_1k.png` | 2 VRAM Compressed | 1 Enable | true |
| `hint_experiment.gdshader` (line 4) | `with_source_color` | `source_color, filter_nearest` | none | `greys_3x1.png` | 0 Lossless | 2 Disable | false |
| `hint_experiment.gdshader` (line 5) | `without_source_color` | `filter_nearest` | none | `greys_3x1.png` | 0 Lossless | 2 Disable | false |

- All four `.import` files also have `roughness/mode=1` (Disabled) and `process/normal_map_invert_y=false`. `blue_metal_plate_nor_dx_1k.png.import` is `importer="skip"`: only the calibration test reads it, from the source file.
- Read back headless (CLAUDE.md, Headless facts), the diffuse and roughness maps come out BC1 and the normal map BC5 (RGTC_RG).
- `get_shader_uniform_list()` lists `tint` as Color, the four floats as float, and the samplers as Object (`Texture2D`). For the floats its `hint_string` also gives the range (`0.0,1.0,0.001`, and so on), though not the default.
- The normal map (`tests/normal_map_check.gd`, decoded from the source PNG): `curl_ratio` 0.427 with `directx = false` and 1.573 with `directx = true`, under the brief's threshold of 0.7.
- `greys_3x1.png`'s source pixels are 64, 128 and 192.

## Lights and environment

| Scene | Lights | Environment | Tonemap, exposure |
|---|---|---|---|
| `asset_room/asset_room.tscn`, where I judge the cooler (key 2; camera about 1.6 m away, `asset_room.gd:142`) | `Sun`, a DirectionalLight3D: colour `#FFFAF0`, `light_energy` 0.8, rotation (−52°, 35°, 0), shadows on (blur 2.0, opacity 0.6) | Background colour `#8FA58C`; ambient from a colour (`ambient_light_source = 2`), `#E8EEF0` × 0.8; **SSAO on** (radius 1.2, intensity 1.6, power 1.2); depth fog on, 18 to 60 m, density 0.35; no glow | Not set, so the defaults: Linear, exposure 1.0 |
| The camp at night (`scripts/main.gd`, `_build_environment()`, with `NIGHT = true`), where the cooler stands about 2 m from the fire (`COOLER_AT`, `campsite.gd:70`) | The moon (`night.gd`): `#AAB4FF` × 1.8, angles (−38°, 72°, 0), shadows on. The fire (`campsite.gd:542`): an OmniLight3D, `#FF9B4A` × 3.2, flickering ±12 %, range 8 m, attenuation 1.4, shadows on. The string lights: OmniLight3D × 0.7, range 3.2 m | Ambient `#6F78B0` × 0.28; SSAO on as above; depth fog 18 to 60 m in the night haze `#26343F`; glow on (intensity 0.8, bloom 0, HDR threshold 1.0) | Not set: Linear, exposure 1.0 |
| `hint_experiment/hint_experiment.tscn` | None; the shader is `unshaded` | Background black; glow, fog and adjustments off | Set: `tonemap_mode = 0` (Linear), `tonemap_exposure = 1.0` |

Project-wide: Forward+, MSAA 3D 4x (`project.godot`), no debanding set.

## Findings

Nothing here changes a shader, material, scene or `.import` file. The two shader findings are reported for you to decide on.

1. **The asset room still has SSAO on, though the brief judges the cooler with it off.**
   - Evidence: `asset_room/asset_room.tscn:26`, `ssao_enabled = true`; the brief's material plan (28 Oct): "Its SSAO (`asset_room/asset_room.tscn`, line 26) is switched off while I judge".
   - Nothing in `asset_room.gd` switches it, so it's off only if you untick it by hand in the editor and don't save. The test pins it as committed, on.
2. **The colour line can push `ALBEDO` well above 1.**
   - Evidence: `cooler_paint.gdshader:20`, `ALBEDO = tint.rgb * mix(1.0, diffuse_luminance / DIFFUSE_MEAN_LUMINANCE, detail);`. The diffuse's brightest texel has linear luminance 0.2532, 5.6 times the constant 0.0452 (measured by the test from the source PNG).
   - At that texel the lid's `ALBEDO` comes out (1.91, 1.91, 1.84) and the body's (0.16, 0.77, 1.96), in linear. An albedo above 1 reflects more light than reaches it.
   - Only the brightest texels go that far, and the test doesn't count how many do. Whether it shows as blown-out specks on the lid, especially under the camp's glow (threshold 1.0), is for your eyes.
3. **`DIFFUSE_MEAN_LUMINANCE` is a hand-measured constant tied to one texture.**
   - Evidence: `cooler_paint.gdshader:3`, `const float DIFFUSE_MEAN_LUMINANCE = 0.0452;`. The test measures 0.0456 from the source PNG decoded to linear, within 1 %, and asserts within 2 %.
   - It's right for this diffuse. Bound to another texture, the material would brighten or darken by the ratio of the two means, with no error. The test catches that only for the texture it names.
   - The GPU samples a BC1 copy, whose mean may differ slightly from the PNG's; headless, the test can't sample it the way the GPU does.
4. **The roughness map spends a three-channel BC1 block on a grey map, and the shader reads its red channel, BC1's 5-bit one.**
   - Evidence: `cooler_paint.gdshader:21`, `texture(roughness_texture, ...).r`; BC1 on read-back (CLAUDE.md, Headless facts); `compress/channel_pack=0` in its `.import`.
   - BC1's endpoint colours are 5:6:5, so red has the fewest bits. It's small at 1k and at 124 × 77 px on screen; a single-channel format, or reading `.g`, would keep more precision. Not wrong, and not mine to change in this task.
5. **`uv_scale` sits in the `colour` group but scales all three maps.**
   - Evidence: `cooler_paint.gdshader:8` (in `group_uniforms colour;`), used at lines 18, 21 and 22.
   - This matches the brief's uniform table, which puts it in `colour`. In the Inspector it shows under "Colour" only, though it moves the roughness and the scratches too.
6. **The hint experiment's two samplers share one Texture2D resource.** Consistent with the brief (one PNG, two samplers). Godot reads it through an sRGB view for `source_color` and a linear view without, so sharing it is fine. Noted because a check that loads the texture once can't tell the two samplers apart; only the hints in the source can.

Checked and consistent with the brief, with nothing to report: both materials' values and bindings; every sampler's hints; no data texture has `source_color` (the brief's failure 8); `roughness/mode` Disabled on every texture, so the editor's Detect has nothing to rewrite (failure 9, as far as the files go); the GL map, not the DX one, with `normal_map_invert_y` off; tangents built on import; `Cooler_Grey` embedded; the greys PNG lossless with no mipmaps; the hint scene's Linear tonemap at exposure 1.

## Attribution

- **Textures:** Blue Metal Plate, by Rob Tuytel (all roles), from Poly Haven (https://polyhaven.com/a/blue_metal_plate), published 26 Sep 2024. Poly Haven's textures are CC0. All three used are 1k PNGs: the diffuse, the roughness map and the OpenGL normal map, `_nor_gl`. Source, authors, licence and download date are in `assets/textures/blue_metal_plate/ATTRIBUTION.md`.
- **Shaders:** `shaders/cooler_paint.gdshader` and `shaders/hint_experiment.gdshader` are yours, hand-written.
- **The cooler's materials:** their values were picked by you from Claude Code's options on 28 Oct 2026; the paths were Claude Code's suggestion.
- **The hint experiment's scene and material** (`hint_experiment.tscn`, `split_quad.tres`) are Claude Code's.
- **This audit and `tests/test_materials.gd`:** Claude Code, 29 Oct 2026.
