# Language notes

`the-noise-next-door` · CSYE 7270 · Assignment 5 · branch `assignment-5`

Project-based draft notes on the Godot shading language: the shader Godot generates for a StandardMaterial3D, read line by line, and the course's eight questions, with line references to the project shaders.

> **Who wrote what.** The headings, questions and tables came from the claude's template.The draft was written by me and vetted and updated using assitance of claude-code but only the formatting was handled by AI all the content was provide by me. 

**How I cite a line:** `file:line`, for example `shaders/cooler_paint.gdshader:20`, or `file:first-last` for a range.

**The shaders this file cites:**

| Shader | What it is | Commit |
|---|---|---|
| `shaders/vision_cone.gdshader` | My shader from code: the campers' vision cones | 53b0087 |
| `shaders/cooler_paint.gdshader` | My textured shader: the cooler's body and lid | c45c97b |
| `shaders/hint_experiment.gdshader` | My hint experiment: one quad, with and without `source_color` | 9d782c3 |
| `shaders/standard_generated.gdshader` | The editor's conversion of a StandardMaterial3D, with my annotations. Not used by the game. | 92e12b8 (the editor's output, unedited: `shaders/new_shader.gdshader`, e58ccb4) |

Part 1 cites only the generated shader. Part 2 cites my three shaders, and question 6 the generated one as well.

---

## Part 1: the generated shader

The line numbers in `shaders/standard_generated.gdshader`. They're the same in `shaders/new_shader.gdshader`, since my annotations are only at the ends of lines.

| # | What | Line(s) | The line, as written |
|---|---|---|---|
| 1.1 | `shader_type` | 3 | `shader_type spatial;` |
| 1.2 | `render_mode` | 4 | `render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;` |
| 1.3 | The uniform for the Inspector's albedo colour | 6 | `uniform vec4 albedo : source_color;` |
| 1.4 | The uniform for the Inspector's normal-map strength | 20 | `uniform float normal_scale : hint_range(-16.0, 16.0);` |
| 1.5 | The albedo sampler, with its hints | 7 | `uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;` |
| 1.6 | The normal-map sampler, with its hints | 19 | `uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;` |
| 1.7 | The line that writes `ALBEDO` | 35 | `ALBEDO = albedo.rgb * albedo_tex.rgb;` |
| 1.8 | The line that writes `ROUGHNESS` | 43 | `ROUGHNESS = roughness_tex * roughness;` |
| 1.9 | The line that writes `NORMAL_MAP` | 46 | `NORMAL_MAP = texture(texture_normal, base_uv).rgb;` |

**Anything that surprised me in it** (optional): The editor generated uniforms such as `point_size` and the UV2 values even though this shader never uses them. It also spells the normal sampler hint `hint_roughness_normal`; I kept the editor's output as generated.

---

## Part 2: the eight questions

In my own words, each with at least one line reference to one of my three shaders.

### Q1. What does `shader_type` decide?

Answer for each type I used, citing the first line of each shader.

| Shader | First line | Its `shader_type` |
|---|---|---|
| `shaders/vision_cone.gdshader` | 1 | `spatial` |
| `shaders/cooler_paint.gdshader` | 1 | `spatial` |
| `shaders/hint_experiment.gdshader` | 1 | `spatial` |

**What it decides:** It tells Godot what kind of shader this is and which built-ins and stages are available. All three are spatial shaders, so they work on 3D materials. The cone also uses `unshaded` in its render mode, so its colour is not lit like the cooler's (`shaders/vision_cone.gdshader:2`; the cooler has no `unshaded` mode).

### Q2. Which processor functions did I write, and when does each run?

| Function | Shader and line | When it runs |
|---|---|---|
| `fragment()` | `shaders/vision_cone.gdshader:9` | Runs for each visible fragment/pixel and computes that pixel's material outputs. |
| `fragment()` | `shaders/cooler_paint.gdshader:17` | Runs for each visible fragment/pixel and computes that pixel's material outputs. |
| `fragment()` | `shaders/hint_experiment.gdshader:7` | Runs for each visible fragment/pixel and computes that pixel's material outputs. |

I wrote no `vertex()` function in these three shaders; they all use `fragment()`.

**If I moved my colour line into `vertex()`, what would change, and why?** I cannot move this line as written: `ALBEDO` is a fragment output, not a vertex built-in. To calculate it at vertices, I would put the `mix()` result in a `varying` in `vertex()` and assign that varying to `ALBEDO` in `fragment()`. Since `watch_color`, `alarm_color` and `alarm` are uniforms (`shaders/vision_cone.gdshader:4-7`), every vertex gets the same result. Interpolation would keep that same result across the triangle, so the visible colour would not change (`shaders/vision_cone.gdshader:10`; Godot's [spatial shader reference](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html) lists `ALBEDO` as a fragment output, not a vertex built-in).

### Q3. Built-ins I read and wrote

Two distinct built-ins I read, and two I wrote. `UV` appears in two shaders, but it is the same built-in.

| Built-in | Read or written | Where (file:line) | If read: read-only? |
|---|---|---|---|
| `COLOR.a` | read | `shaders/vision_cone.gdshader:11` | Yes in `fragment()`: it is incoming vertex-colour alpha. |
| `UV` | read | `shaders/cooler_paint.gdshader:18`; `shaders/hint_experiment.gdshader:8` | Yes in `fragment()`: it is incoming, interpolated texture coordinates. |
| `ALBEDO` | written | `shaders/vision_cone.gdshader:10` | — |
| `ALPHA` | written | `shaders/vision_cone.gdshader:11` | — |

**Which of the ones I read are read-only, and how I know:** `COLOR` and `UV` are read-only inputs in my `fragment()` functions; the shader reference marks fragment `COLOR` and `UV` as `in`. `UV` is different in `vertex()`: the generated shader changes it at `shaders/standard_generated.gdshader:28`, where it applies a scale and offset. Godot marks vertex `UV` as `inout`, so it can be changed there and then passed to `fragment()`.

### Q4. What each hint I used changes

For each hint: does it change only the Inspector, or also the value the shader receives?

| Hint | Where (file:line) | Inspector only, or the value too? | My evidence |
|---|---|---|---|
| `source_color` | `shaders/vision_cone.gdshader:6-7`; `shaders/cooler_paint.gdshader:6,9`; `shaders/hint_experiment.gdshader:4` | Changes colour-space handling of colour uniforms/samples, so it affects values the shader receives. | With the hint, the captured greys stayed 64, 128, 192; without it they appeared 137, 188, 225 (`TEST-REPORT.md`, “The hint experiment”). |
| `hint_range` | `shaders/vision_cone.gdshader:4-5`; `shaders/cooler_paint.gdshader:7-8,12-13` | Sets an Inspector range; it does not clamp values set from code. | `alarm=2.0` produced output beyond the 0–1 result (`TEST-REPORT.md`, “The controlled-value captures”). |
| `filter_nearest` | `shaders/hint_experiment.gdshader:4-5` | Changes texture sampling to use the nearest texel. | Each grey region samples a flat texel, so the bands stay crisp (`shaders/hint_experiment.gdshader:8-12`). |
| `filter_linear_mipmap` | `shaders/cooler_paint.gdshader:9,14-15` | Changes sampled values by blending nearby texels and using mip levels as the texture appears smaller on screen. | It smooths sampled albedo, roughness and normal maps (`shaders/cooler_paint.gdshader:18,21-22`). |
| `repeat_enable` | `shaders/cooler_paint.gdshader:9,14-15` | Changes sampling: UVs outside 0–1 can repeat the texture. | The shader scales UVs before sampling (`shaders/cooler_paint.gdshader:18,21-22`). |
| `hint_default_white` | `shaders/cooler_paint.gdshader:14` | When no roughness texture is bound, the sampler supplies white (1, 1, 1, 1), so its red value is 1. With a texture bound, this hint does not change its sampled values. | The shader reads red and multiplies by `roughness_scale` (`shaders/cooler_paint.gdshader:21`); Godot documents this hint as an opaque-white fallback. |
| `hint_normal` | `shaders/cooler_paint.gdshader:15` | In the probe, leaving the sampler unbound gave the same flat-normal result as setting `normal_strength` to 0. With the texture bound, removing `hint_normal` did not visibly change the map's result. Whether it changes import detection was not tested. | The unbound pair differed by 0 pixels beyond the 2-step threshold; the bound pair differed only at one anti-aliased edge pixel (`TEST-REPORT.md`, “Claude's `hint_normal` probe”; [`probe.txt`](design/a5/captures/hint-normal/probe.txt)). |

**What my hint experiment shows:** The same greys are sampled by two uniforms, but only one has `source_color`. With the hint, measured greys stayed 64, 128, 192; without it they appeared brighter at 137, 188, 225. In this Forward+ capture the hint changes the colour-space conversion of sampled values, not just how a control looks in the Inspector (`hint_experiment.gdshader:4-5,11-12`; `TEST-REPORT.md`, “The hint experiment”).

### Q5. Does `hint_range` clamp a value set from code?

**What I predicted:** No. `hint_range` sets the Inspector slider's suggested range; setting the uniform from code can still pass a value outside it (`CHANGE-BRIEF.md`, short answer 6).

**What I observed:** At `alarm = 2.0`, the captured cone became more extreme than at 1.0, so the value was not clamped. The uniform's hint is `hint_range(0.0, 1.0)` (`shaders/vision_cone.gdshader:4`; `TEST-REPORT.md`, “The controlled-value captures,” especially its 2.0 result).

### Q6. Colour and data in the generated shader, and in mine

| | The line that makes the albedo sample as colour | The line that makes the normal map sample as data |
|---|---|---|
| The generated shader | `shaders/standard_generated.gdshader:7` declares the albedo sampler with `source_color`; `:34` samples it. | `shaders/standard_generated.gdshader:19` declares the normal sampler as normal-map data; `:46` samples it into `NORMAL_MAP`. |
| My textured shader, `cooler_paint.gdshader` | `shaders/cooler_paint.gdshader:9` declares `albedo_texture` with `source_color`; `:18` samples it. | `shaders/cooler_paint.gdshader:15` declares `normal_texture` with `hint_normal`; `:22` samples it into `NORMAL_MAP`. |

**Why those lines do it:** Albedo is a colour, so `source_color` tells Godot to handle its sRGB/linear conversion as colour. A normal map stores direction data in channels, so it is sampled as data and passed to `NORMAL_MAP`, without colour correction (`cooler_paint.gdshader:9,18,15,22`; generated shader lines 7,19,34,46).

### Q7. Why can't `fragment()` read its neighbour, and how does game state reach it?

**Why it can't read what the neighbouring pixel's `fragment()` is computing:** Fragments are processed independently and may run in parallel; there is no guaranteed order or shared fragment output for a neighbouring pixel to read. Each fragment instead gets its own interpolated inputs and uniforms.

**How game state reaches it instead:** The cone shader receives `alarm` and `shown` as uniforms (`vision_cone.gdshader:4-5`) and uses them for colour and visibility (`:10-11`). The game's `VisionCone` sets those material parameters with `set_shader_parameter()` (`scripts/vision_cone.gd:129-133`); the driver supplies the state values.

### Q8. Two things the Godot shading language gives me that plain GLSL doesn't

Or that GLSL makes me write myself.

1. Built-in variables save me from declaring standard spatial shader inputs and outputs myself: I read `COLOR.a` and write `ALBEDO` and `ALPHA` (`shaders/vision_cone.gdshader:10-11`).
2. Shader hints connect parameters to Godot's Inspector and texture handling: `hint_range` gives `alarm` an editor range, while `source_color` marks colour data (`shaders/vision_cone.gdshader:4,6`).

---

## Part 3 : the four ideas, for the film

The course asks me to explain these in my own words, each with a line of my own code. They're not part of Step 4, but the film needs them.

| Idea | My explanation | My line |
|---|---|---|
| What a shader does | It calculates how a surface is drawn; this one chooses the cooler's colour, roughness and normal response per fragment. | `shaders/cooler_paint.gdshader:17-23` |
| How a material differs from a shader | The shader is the instructions; a material uses that shader and holds values and textures for one surface. The body and lid share a shader but have separate material resources. | `materials/cooler_body.tres:8-18`; `materials/cooler_lid.tres:8-18` |
| Why a texture is information, not a picture | A texture is sampled data: the cooler reads colour, roughness and normal values from its maps, and each map drives a different surface property. | `shaders/cooler_paint.gdshader:18-23` |
| What the Godot shading language is | Godot's shader language: GLSL-like code with Godot-specific shader types, render modes, built-ins and hints. | `shaders/vision_cone.gdshader:1-2,10-11` |
