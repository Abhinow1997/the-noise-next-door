# Test report: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 8: final project pitch

What Assignment 8's work is tested for, how, and what actually happened: the pitch film's checks, and the game's changes since the `a7` tag. Each run gives its source revision, the Godot version (4.7.2 stable) and the renderer (Forward+ in a window; headless runs use the dummy renderer, which draws nothing). As with CHANGE-BRIEF.md, this file holds only the current assignment. The earlier reports are in history.

## The earlier assignments

| Assignment | What was tested | Where it is |
|---|---|---|
| 2: the asset slice | Startup and controls, the character against its sheet, the storyboard, sound, music, muted play, the playtest and the automated check | `TEST-REPORT.md` at tag `a2` (`2da6991`) |
| 3: the three Blender assets | The s'more, the pizza slice and the cooler in Godot: the asset check and the look in the asset room | `TEST-REPORT.md` at tag `a3` (`c729e53`) |
| 5: shaders and materials | The vision cone's shader, the cooler's materials and the normal-map check, with their mutations | `TEST-REPORT.md` at tag `a5` (`62ee5fb`) |
| 6: particle effects, and the bigger camp | The leaf burst and the campfire smoke (settings, state, price, GPU time, mutations, strips and play), and the camp's game checks | `TEST-REPORT.md` at tag `a6` (`1578035`). The game work after it is at `dc8ff17`, the last commit before Assignment 7 |
| 7: animation | The jump (`jump`, `jump_land`) and the moth's flutter: the baseline, pins, read-backs, mutations, a fresh import cache, the state machine, edges, frame strips, the two clocks and my checks in play | `TEST-REPORT.md` at tag `a7` (`e21bb3a`) |

Their logs stay in `logs/` where those reports cite them: Assignment 7's are in the `logs/a7-*/` folders.

**The last counts before Assignment 8** (22 Nov 2026, `logs/a7-baseline-final/SUMMARY.txt`): a fresh clone of `160c0eb` with no `.godot/`, 31 test scripts through `scripts/run-test.sh`.
- **Every one passes,** except `cost_effects.gd`, which fails 1 of 4 (the fire out), as it has since before Assignment 7.
- **A7's own:** the rig 51, pins 26, the jump's states 89, edges 239/238/238 at 30/60/144, the moth 22, the moths 15, the guide 9, the balloons 35 and 71.

---

## Assignment 8: final project pitch

### The pitch film

The film is built with Brutalist's `godot-gdd` route in [pitch/](pitch/). Its checks are the toolkit's gates and the course's honesty rule. They'll be recorded here once the final is rendered and I've confirmed it.

| Check | Evidence | Status |
|---|---|---|
| GDD coverage and exact excerpts | `./art godot-gdd --check pitch --gdd GDD.md` | Passes on the draft (23 Nov): 11 sections, 5 excerpts, 5 evidence files. To rerun on the final |
| Frames (Gate V), type (Gate T), facts (Gate F), sound and duration | `./art final`, and its `.verified.json` receipt | To do, after the takes |
| The honesty rule | [pitch/FACTCHECK.md](pitch/FACTCHECK.md), claim by claim | Draft. B04's comparison and cutting save states are mine to confirm |
| The footage is real play, from a named commit | The takes' SHA-256s and notes; each clip's label | To do: once level 1's ending is committed |
| The game at the footage's commit | The whole test list, through `scripts/run-test.sh`, in a clean worktree of `370f62d` ([pitch/evidence/370f62d-test-run.txt](pitch/evidence/370f62d-test-run.txt)) | **Done** (23 Nov). Every test at its count: the cake 23 at 30, 60 and 144 fps, box scare 16, pizza 21, the rig 56, tasks 48, tutorial 34, cones 43 and edges 239/238/238 at all three rates. `cost_effects` fails `effect_b` as before (the fire out) |
| HUMAN CHECK: the film as a whole | Watching the final, listening across every cut | To do |

### The game since the `a7` tag

What each change's commit records it was tested with. These are the commits' own reports, not reruns for this report.

| Change | Commit | Tests, as its commit records |
|---|---|---|
| The girl's edges smoothed | `b171123` | The A7 baseline's whole list matches it |
| The two men too, on one thread | `34801ab` | The A7 baseline's list, in a worktree with only this change, matches it |
| The tutorial's wait, the pizza, the drag clip, Eat the pizza | `7adb941` | The rig 56 (was 51, with `drag`); `test_pizza_task.gd` 17, new; every other test at its count. The tutorial test at 30 fps fails "And the bush is open again", as it does at `e21bb3a` |
| The tablecloth, pulled | `ac2148a` | `test_pizza_task.gd` 21; every other test at its count |
| The keeper's box, Raid the supply tent | `ef386f9` | `test_supply_tent.gd` 18, new; camp 31, tutorial 34, tasks 48, bubble 87; the rest at their counts after the tent's stage |
| Scare a camper (replaces the supply tent) | `81c1df3` | `test_box_scare.gd` 16, new; the whole list on this commit alone, in its own worktree, at its counts; `cost_effects` as before |
| Everyone round the cake | `370f62d` | `test_cake_finale.gd` 23 (was 19) at 30, 60 and 144 fps; the whole list matched (its commit message) |
| Level 1's ending: the cake, the laces, the beanie, the chase | `c92a53d` | `test_cake_finale.gd` 19, new, at 30, 60 and 144 fps; the whole list at its counts in the working tree; `cost_effects` as before |
