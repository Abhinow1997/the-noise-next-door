# Test report: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 7: animation

What Assignment 7's work is tested for, how, and what actually happened. Each run gives its source revision, the Godot version (4.7.2 stable) and the renderer (Forward+ in a window; headless runs use the dummy renderer, which draws nothing). As with CHANGE-BRIEF.md, this file holds only the current assignment. The earlier reports are in history.

## The earlier assignments

| Assignment | What was tested | Where it is |
|---|---|---|
| 2: the asset slice | Startup and controls, the character against its sheet, the storyboard, sound, music, muted play, the playtest and the automated check | `TEST-REPORT.md` at tag `a2` (`2da6991`) |
| 3: the three Blender assets | The s'more, the pizza slice and the cooler in Godot: the asset check and the look in the asset room | `TEST-REPORT.md` at tag `a3` (`c729e53`) |
| 5: shaders and materials | The vision cone's shader, the cooler's materials and the normal-map check, with their mutations | `TEST-REPORT.md` at tag `a5` (`62ee5fb`) |
| 6: particle effects, and the bigger camp | The leaf burst and the campfire smoke (settings, state, price, GPU time, mutations, strips and play), and the camp's game checks | `TEST-REPORT.md` at tag `a6` (`1578035`). The game work after it (Raid the bear bag, the music from the speaker, the run back, calmer cones) is at `dc8ff17`, the last commit before Assignment 7 |

Their logs stay in `logs/` where those reports cite them: Assignment 6's are in the `logs/a6-*/` folders.

**The last counts before Assignment 7** (11 Nov 2026, `logs/a6-run-scribe-cones/`), through Assignment 6's wrapper: bubbles 87, camp 31, tasks 48, plan 22, tutorial 34; cones 43 at 30, 60 and 144; cone shader 93 at 60 (and at 30 and 144 on 10 Nov, `logs/a6-bearbag/`); fire 25, tent 16, bear bag 41, leaf burst state 37, smoke 20 and 8; sound 30; waves 14/14 and title 53/53 in realtime. Their `--fixed-fps` runs fail one check each (13/14, 52/53), which is expected. Assignment 7's baseline reruns every test through its own wrapper.

---

## Assignment 7: animation

Nothing has been run yet (21 Nov 2026). These are the checks the assignment asks for (its "Use It" table), each recorded here once it has been run and confirmed:

| Check | Evidence | Status |
|---|---|---|
| Baseline | Every earlier test through Assignment 7's wrapper, before and after the change, in its pinned mode, with counts | Not run |
| Pins | The behaviour pins before the change and after, with what changed and why the brief predicted it | Not written |
| Read-back | Both clips' read-back tests: track, key-time, step, loop-mode, update-mode and frame-range assertions, named | Not written |
| Mutations | The four mutations exiting 1, each from its own worktree | Not run |
| Fresh cache | The rig's read-back after deleting `.godot/` and reimporting; for an imported rig, that its loop mode survived | Not run |
| State machine | The structure test against the resource, and the state test driving real input through `Input.parse_input_event` | Not written |
| Edges | Every phase boundary, with an interrupt one frame before, on and one frame after each | Not written |
| Frame strips (fixture) | The strips behind every revision in TUNING.md, labelled as fixture captures | Not captured |
| The cycle seam (HUMAN CHECK) | The looping clip through at least five wraps at normal speed: no stutter, no duplicated frame, no jump | Not done |
| The action in play (HUMAN CHECK) | The committing action in normal play many times, with an interrupt in each phase; the three phases read as distinct | Not done |
| Registration (HUMAN CHECK) | The cycle's strip: the character doesn't drift within its cells | Not done |
| Against the background (HUMAN CHECK) | Both clips over the darkest and lightest level art they can appear on | Not done |
| Two clocks | The tick each clip advances on and the tick gameplay reads, measured, with the largest disagreement in seconds | Not measured |
| Claude against me | Each of Claude's strip readings beside my verdict, with at least one point where I disagreed, or "none" | Not done |
