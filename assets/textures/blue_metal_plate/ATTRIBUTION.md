# Blue Metal Plate

| | |
|---|---|
| Asset | Blue Metal Plate |
| Source | Poly Haven, https://polyhaven.com/a/blue_metal_plate |
| Author | Rob Tuytel (all roles, per Poly Haven) |
| Published | 26 Sep 2024 |
| Licence | CC0 (https://polyhaven.com/license), checked by me on Poly Haven's asset page and licence page on 29 Oct 2026 |
| Downloaded | 29 Oct 2026, the 1k PNGs |

| File | Bytes | MD5 | Used for |
|---|---|---|---|
| `blue_metal_plate_diff_1k.png` | 5611054 | `4a8d23e669c51e6bd11193d8de10072f` | The cooler's colour (`albedo_texture`, sampled with `source_color`) |
| `blue_metal_plate_rough_1k.png` | 1694099 | `4508681759a8f3ef926c86c6ee2b3ce8` | The cooler's roughness (`roughness_texture`, data) |
| `blue_metal_plate_nor_gl_1k.png` | 4125323 | `6fcde97d9970fbccfa443c3efe9e53ae` | The cooler's normal map (`normal_texture`, `hint_normal`), OpenGL convention, as Godot expects |
| `blue_metal_plate_nor_dx_1k.png` | 4124590 | `b8bf6c82ad769c6527708a33afd1fbae` | Only to calibrate `tests/normal_map_check.gd`; its import is set to Skip, so the game never loads it |

The sizes and MD5s match Poly Haven's own file list (api.polyhaven.com/files/blue_metal_plate), checked on 29 Oct 2026. The files are unchanged; their import settings are in the `.import` files beside them.

(Written by Claude Code on 29 Oct 2026 from my licence check, with the author and date from Poly Haven's API.)
