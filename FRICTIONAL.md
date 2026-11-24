# Frictional log: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 8: final project pitch

A dated log of Assignment 8's work as it happened: what I tried and expected, what I asked for, what came back, what I checked, and what I decided or learned, including what's still unresolved. It covers the game's work since the `a7` tag, and points to the pitch film's own log. Each entry says who did what: me, or Claude Code. As with CHANGE-BRIEF.md, this file holds only the current assignment. The earlier logs are in history.

## The earlier assignments

| Section | Dates | Where it is |
|---|---|---|
| Assignment 2: the asset slice | 4 to 6 Oct 2026 | `FRICTIONAL.md` at tag `a2` |
| Assignment 3: the three Blender assets | 13 and 14 Oct 2026, with the Blender MCP's setup from 3 to 5 Oct | `FRICTIONAL.md` at tag `a3` |
| After Assignment 3: the title screen, the night and level 1's camp | 21 to 25 Oct 2026 | `FRICTIONAL-EARLIER.md` at tag `a6` |
| Assignment 5: shaders and materials | 25 Oct 2026 on | `FRICTIONAL.md` at tag `a5`, and at tag `a6` |
| Assignment 6: particle effects, and the bigger camp | 6 Nov 2026 on | `FRICTIONAL.md` at tag `a6` |
| Assignment 7: animation | 21 to 22 Nov 2026 | `FRICTIONAL.md` at tag `a7` |

---

## Assignment 8: final project pitch

`the-noise-next-door` · CSYE 7270 · Assignment 8 · branch `main`

**How these entries were written:**
- **Organized** by Claude Code on 23 Nov 2026, from the commits since `a7` and their messages, CHANGE-BRIEF.md's revisions after the tag, and the pitch session.
- **My words** are quoted exactly as I typed them, typos included, from where those records quote them. The chat doesn't show times, so only dates are given.
- **Where a commit records only what changed,** the entry gives only that. My words from those sessions weren't in front of Claude Code; any I add later are marked as written later.

**The pitch film** has its own log, where the assignment asks for it: [pitch/FRICTIONAL.md](pitch/FRICTIONAL.md). It isn't copied here.

### 23 Nov 2026: the girl's edges smoothed (`b171123`, after the `a7` tag)

- **Asked:** "The humans model we need to work on can we use blender and make the edges on them smother for the models take the girl 1st lets work on it and then we can move to others", then "Smooth twice".
- **Came back:** a two-level Subdivision Surface ahead of her rig. Her outline went from 2,132 triangles to 37,584. Her nine clips, skin and bones are byte for byte the old `.glb`'s.
- **Checked:** the A7 baseline's whole test list matches it. My eyes on her in play are listed in the brief's revision.
- **Merged** onto `main` (`aa34eaf`), so new work goes on there.

### 23 Nov 2026: the two men too, the beanie with them, on one thread (`34801ab`)

- **Asked:** "Yes, both men", and for the chubby man's beanie, "Smooth it too".
- **Came back:** the same Subdivision Surface on both men (so the fire keeper too), and his beanie smooth-shaded.
- **Learned:** Blender's subdivision differs in its last bits from run to run on several threads. The girl's `.glb` came out three ways in four rebuilds. So the figures' scripts now need `-t 1`, and every rebuild repeats byte for byte. The girl's revision's hash claim was corrected in CHANGE-BRIEF.md.
- **Checked:** the A7 baseline's list, in a worktree with only this change, matches it.

### 23 Nov 2026: the tutorial's wait, the girl bringing the pizza, a drag clip, and Eat the pizza (`7adb941`)

- **Came back:**
  - **The tutorial's wait:** from his dive into the bush, the low-poly man, the girl and the fire keeper go off the campsite, and the first marshmallow isn't served till they're gone.
  - **The pizza:** the girl brings two pizza boxes to the table.
  - **Steal the marshmallows** is ticked as he eats it.
  - **A `drag` clip on his rig:** a 1 s loop of two tugs; the other nine clips are unchanged key for key.
  - **Eat the pizza:** a new task. Drag the cloth, the boxes clatter down, eat a slice.
- **Checked:**
  - the rig's read-back is 56 checks (was 51), and the new `tests/test_pizza_task.gd` has 17;
  - every other test passes at its count;
  - the tutorial test at 30 fps fails "And the bush is open again", as it does at `e21bb3a`.

### 23 Nov 2026: the tablecloth, pulled (`ac2148a`)

- **After play:** "the cloth needs to be pulled like the natrual movement e grab and pull the cloth also seems like a box texture not good", then "the fabric and pizza fall syc is off".
- **Came back:**
  - E at the hem takes the cloth in his jaws, and the move keys drag it, the boxes riding on it;
  - one smooth gingham sheet replaces the checked boxes;
  - when the boxes tip over the edge, the cloth comes down with them.
- **Checked:** `tests/test_pizza_task.gd` 21 checks; every other test at its count.

### 23 Nov 2026: the keeper's box, and Raid the supply tent (`ef386f9`)

- **Asked:** "the guy will carry the box ... the pot will be inside the box ... we can hide into the box, and then it can be carried inside ... tent".
- **My picks:** the box comes at the tutorial's end, the pot gets tipped, the box goes inside the green tent, and it's a free CC0 model ("Use the closed cube").
- **Came back:**
  - the fire keeper carries a cardboard box in and puts a pot on three sticks over the fire. Tipping the pot douses the fire;
  - **Raid the supply tent:** hide in the box, ride into the tent with the keeper, eat a cookie from the crate;
  - the box is Viktor Sano's CC0 "Free Cardboard Boxes" (SOURCES.md).
- **After play:** "maybe the upper flap peaking from there not from the botttom ... we are basicially inside the box". So his eyes now peek from a crack in the top flap.
- **Checked:** the new `tests/test_supply_tent.gd` has 18 checks; camp 31, tutorial 34, tasks 48 and bubble 87; the rest at their counts.

### 23 Nov 2026: the cake, his laces, his beanie, and the chase out of the camp (`c92a53d`)

- **Asked:** "after some time maybe the fat guy can like go in the tent, maybe bring out a cake ... and then we come up and tie his lace ... when he walks away, he falls, and the cake falls on him, and the beanie sort of slips out, and we will grab it ... we'll start a cutscene ... and then eventually we'll start a chase that will lead on to a new location." Then: "Let's build that right now".
- **Came back:** level 1's ending.
  - Once 5 of the camp's tasks are done, the camper fetches a cake to a folding table.
  - **Tie his laces** (hold E 2.5 s at his heels): he trips, the cake lands on his face, and his red beanie slips off.
  - **Swipe it:** a 10.2 s cutscene, then **Get away with it.** The camper and the two men chase him out of the camp, with the moth leading, to "To be continued".
  - **The camper gained three clips:** `carry`, `trip` and `get_up`.
  - **A developer start, `cake`,** begins at that point.
  - **The new location isn't built.**
- **Checked:** `tests/test_cake_finale.gd` passes 19 checks at 30, 60 and 144 fps. The whole list matched its counts in the working tree; `cost_effects` fails as before.
- **At the time:** "yea feels good for now", then "Keep and commit" for its brief revision.

### 23 Nov 2026: Scare a camper, in place of the supply tent (`81c1df3`)

- **Asked,** after riding the box into the green tent didn't work in play ("everything beyond hiding in the box looks wrong ... something other we need to think"): "It can be just like scare a person ... when they come to check the box, we can jump out to scare them, and then that would be a task ... can we give the ability for the raccoon to like drag the box around?"
- **Came back:**
  - **Scare a camper** replaces Raid the supply tent.
  - **In the box,** F rustles it, and the nearest camper comes to look. E bursts him out at them, and they take fright.
  - **Out of it,** E with the move keys drags it about.
- **After play:** "give me option when inside the box make noise and F option", and "the box seems difficult to move around its should be free object it feels heavy ... E needs to be along with direction keys for it to move around".
- **Committed** by Claude Code at my word ("Commit Scare first"), apart from the cake's gathering that another session has in progress, with only Scare's hunks of `camp_person.gd`.
- **Checked:** the whole list on that commit alone, in a worktree of `c92a53d` with only its files, passed at its counts: box scare 16, pizza 21, the cake 19 at 30, 60 and 144. `cost_effects` fails as before.

### 23 Nov 2026: everyone round the cake (`370f62d`)

- **Asked:** "when the cake comes he is doing it all alone everyone should be there when it is happening".
- **Came back:**
  - while the camper's at his cake, the low-poly man, the girl and the fire keeper come round its table and lean in to look at it. They stay through his fall, and are there for the cutscene;
  - watching it, they see only 0.35 of their sight, so sneaking up to tie his laces works and walking up doesn't.
- **Checked:** `tests/test_cake_finale.gd` has 23 checks (was 19), passing at 30, 60 and 144 fps; the whole list matched (its commit message).
- **Committed** in the other session; my word here: "commited". It's the revision the pitch's takes are recorded at.

### 23 Nov 2026: the pitch film

- In [pitch/FRICTIONAL.md](pitch/FRICTIONAL.md):
  - the project, chosen as the whole game;
  - Brutalist installed on Windows, and what it took;
  - the godot-gdd route;
  - my answers;
  - a desktop game for Windows and macOS, with no Mac to test on;
  - waiting for the ending before recording.
- **The root records:** "Yes, they have. Constantly updates have been made to the game for different tasks and levels and further development processes." So this file, TEST-REPORT.md and TUNING.md moved on to Assignment 8. Assignment 7's are at tag `a7`.

### Still unresolved

- **The tutorial test at 30 fps** fails "And the bush is open again", as it has since `e21bb3a` (noted in `7adb941`).
- **`tests/cost_effects.gd`** fails 1 of 4 (its smoke case finds the fire out), as it has since before Assignment 7.
- **Carried over from Assignment 7:**
  - climb needs more work ("Maybe we'll need to work on climb in the future");
  - the jump's distance, not decided.
- **The pitch film's own open items** are at the end of [pitch/FRICTIONAL.md](pitch/FRICTIONAL.md).
