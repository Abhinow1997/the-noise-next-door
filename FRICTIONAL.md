# Frictional log: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 7: animation

A dated log of Assignment 7's work as it happened: what I tried and expected, what I asked for, what came back, what I checked, and what I decided or learned, including what's still unresolved. Each entry says who did what: me, or Claude Code. Tuning revisions are in [TUNING.md](TUNING.md), pointed to from here, not copied. As with CHANGE-BRIEF.md, this file holds only the current assignment. The earlier logs are in history.

## The earlier assignments

| Section | Dates | Where it is |
|---|---|---|
| Assignment 2: the asset slice | 4 to 6 Oct 2026 | `FRICTIONAL.md` at tag `a2` |
| Assignment 3: the three Blender assets | 13 and 14 Oct 2026, with the Blender MCP's setup from 3 to 5 Oct | `FRICTIONAL.md` at tag `a3` |
| After Assignment 3: the title screen, the night and level 1's camp | 21 to 25 Oct 2026 | `FRICTIONAL-EARLIER.md` at tag `a6` |
| Assignment 5: shaders and materials | 25 Oct 2026 on | `FRICTIONAL.md` at tag `a5`, and at tag `a6` |
| Assignment 6: particle effects, and the bigger camp | 6 Nov 2026 on | `FRICTIONAL.md` at tag `a6` |

---

## Assignment 7: animation

`the-noise-next-door` · CSYE 7270 · Assignment 7 · branch `assignment-7`

**How these entries were written:**
- **The outline:** organized by Claude Code on 22 Nov 2026 from my chat messages, the commits, the prompts in `design/a7/` and the test logs. My messages are quoted exactly as I typed them, typos included. The chat doesn't show times, so only dates are given.
- **The facts** (what I asked, what came back, what was checked and decided) are the record.
- **The "At the time" lines** are my own words from the chat, quoted as I typed them, at that point in the work: what I expected, objected to or decided. Claude Code added no reflection of its own. Filled in on 22 Nov 2026 at my request ("update from the memory we have made many changes for the assignment accept the ideas and updated chanes"). Anything I add afterwards, looking back, is marked as written later.
- **Did I change games since Assignment 2?** No.

### 21 Nov 2026: reading the assignment, and setting up

- **Asked:** I pasted the assignment ("this for assignement 7 understand the rquirements"), then: "update the run-test.sh wrapper first ... They should be only for assignment 7, so we don't need any references."
- **Came back:** Claude Code added "Failed loading resource" to the test wrapper (`3e0266c`), and reset FRICTIONAL, TEST-REPORT and TUNING to Assignment 7 only, with the earlier ones by tag (`6a0ec38`).
- **Decided:** "create a branch, assignment 7, as well as the tag, but no need to make commits ... I don't want to commit just for the sake of it." So the branch `assignment-7`, and `a7` as a placeholder tag at `dc8ff17`, to be moved to the final commit.
- **At the time:** I first wanted it narrowed to the animation work: "Focusing on the animations, what is required here for assignment 7? Can you narrow down and give me a summarized version?" I expected to reuse what we had: "Animations, we had created like running and eating and couple of other animations", then "Can we reuse most of this or no?"

### 21 Nov 2026: choosing the two clips, and the brief

- **Picked from Claude Code's options:** the jump as the committing action, with a crouch added; a found sprite sheet; then the balloons as the graded loop. I turned down its first task ideas: "These are all bad, man. Come up with something really good." Then: "Pop the balloons, find a licensed balloon sheet".
- **The moth, an extra:** Claude Code proposed it, and I questioned it ("i still dont understand what is the use of the moth why did u add it"). I kept it after seeing it in the game.
- **My job lines:**
  - for the jump, "the jump tells the player the raccoon is airborne to reach things not Generally reachable";
  - for the balloons and the moth, "Balloon is one of the tasks that enables user to spoil the party ... We can also add in the moth details as a indicator of the fire being on, and like surveillance being on."
- **Checked:** Claude Code downloaded the two sheets and checked their slicing (`d878213`). It drafted the brief, and I kept it before the first prompt (`599da06`). It caught its own mistake in the phase table before I'd written anything: a 3-frame crouch would put takeoff between two physics ticks.
- **At the time:** on the moth, "Okay, I like the moth. Mm, But we need to find a way to add it in. So let's see it in the game." On the task ideas, "These are all bad, man. Come up with something really good. No, don't have to stick to just mods. Give me an idea. Maybe I can get you the asset as well."

### 21 Nov 2026: Step 1, CLAUDE.md

- **Came back:** the agent's draft, unedited, from `design/a7/prompt-1.txt` (`f87aaf1`).
- **My review** was a separate commit (`21867cb`): the course's headless facts, each confirmed on this machine; the names read back on 4.7.2; and the baseline.
- **At the time:** I approved Claude Code's proposed edits to the draft: "Yes, make them".

### 21 Nov 2026: Step 2, the pins

- **Came back:** `tests/jump_pins.gd`, 26/26, before any clip was wired (`1232706`).
- **What they found:** four of the brief's worked-out numbers were wrong. A held jump lands 25 ticks after takeoff, not 26; a tap peaks at 0.228 m, not 0.183 m; a kept press takes off the tick after landing; and the pins' "tick after F" is the brief's frame 0. I kept the brief revision ("Keep and commit", `0f0de36`).
- **At the time:** "Yes, write pins". Then, on the brief revision from what they measured, "Keep and commit".

### 21 Nov 2026: Steps 3 to 5, building the clips

- **Built by agent sessions,** each committed unedited, then reviewed:
  - the balloon's float (`b2bdf3f`, `prompt-3.txt`);
  - the jump (`ce74242`, `prompt-4.txt`);
  - Step 5's plan and its steps (`16ee0fe` to `94bb565`, `prompt-5*.txt`).
- **A mistake caught in review:** the balloon read-back compared `step` within half a frame, which would have passed the default 1/30 s. It was fixed to compare exactly (`86e22ed`), and proved in a worktree.
- **Step 5's findings, settled in a revision** (`1730f86`):
  - F while asleep: "F wakes him into the leap out".
  - F up a tree: "The hop off uses the jump clips".
  - The five tests the new task touches.
- **At the time:** on Step 5's findings, "Make F jump there too", then "F wakes him into the leap out" and "The hop off uses the jump clips".

### 21 Nov 2026: the balloons, three times over

- **The pixel-art balloons:** "wtf the ballons we have look aboslute trash / dont suit the game at all". I generated a low-poly sheet with Gemini from Claude Code's prompt (`7bd4aea`, `da90cfd`), and moved the balloons out of the camp, with the girl minding them ("have the girl use somewhere in the out side of the camp area").
- **A stop, as the brief said:** the tasks test expected the girl's old routine. Her new step went after warming her hands (`a579cc6`). Then the fire keeper's timing broke 3 checks, and the test settles him too (`1defa67`, `5ec3b37`).
- **The 2D balloons:** "it looks werid in the game we have". So "3D balloons, moth graded" (`5879f5b`, `0ee0b18`): the moth became the graded sprite clip.
- **At the time:** "wtf the ballons we have look aboslute trash / dont suit the game at all", then "give me a prompt u need i will create the assest for u". On where they were: "also why are the ballons randomly kept in the middle of the camp ?" On the 2D sheet in the game: "thw ballons are 2D?", then "it looks werid in the game we have".

### 21 Nov 2026: the jump goes back to the game's own; the balloon task is redesigned

- **The jump:** "remodel the jump for the assignements requirement but it cannt be just a jump and bite it will be like it was previouslty". The crouch and the bite came out, and the phase table came from the game's own jump (`c0190b0`, `4044bf3`, `prompt-6.txt`).
- **The balloon task:** "the ballons can be blown up by the girl maybe tie somewhere a bit outside on something near the camp and we can get it off and float them away to annoy the campers". That became "Let the balloons go": a chair, E at the knot, and the girl calling the others.
- **Every raccoon animation:** "do requirements for all the animations / not just jumo / jump*" (`23dd8f6`, `d2a306b`, `prompt-7.txt`).
- **At the time:** "no update the jump to what we had previously the jump cant be be just a working to pop the ballons", and for the task, "we have ballons and a girl we need a more better version of task integrated give me a pplan for the task for ballon than just poping".

### 21 Nov 2026: Step 6, edges, re-pins and mutations

- **The re-pin,** in its own commit (`1c858ed`): only the four pins the brief said would change.
- **The edge tests,** from the agent unedited (`5c06182`, `prompt-8.txt`), found three places where the brief promised more than the jump does: air control from the tick after takeoff, a press kept only within 5 ticks of landing, and the peak on tick 13. I chose "Revise the brief" over changing the game (`9e214ec`).
- **The mutations,** each in a git worktree: every one failed its test (`6161ecf`, `logs/a7-mutations/`).
- **An interruption:** once, a `claude -p` run couldn't start (exit 127) after the desktop app updated Claude Code. Claude Code found the new path and ran it again.
- **At the time:** "is it done ?", then, on the edge findings, "Revise the brief".

### 21 Nov 2026: Step 7, the jump's strip and tuning

- **The strip:** Claude Code built the preview (`b428f01`). I ran the capture and kept the brief's ten frames.
- **My verdicts and the r1 revision:** both are in [TUNING.md](TUNING.md), "r0: my first verdict" and "r1: what I saw in play, and the change". In short:
  - my strip verdict said the push read;
  - Claude's reading said frame 10 barely showed it;
  - in play I saw "The hind legs don't particularly move", so r1 bunched the push-off;
  - "Yes, keep r1" (`437e482`, `ab5de2b`).
- **What changed with it:** the rig read-back failed one check, because the importer had dropped a key the stronger push made redundant. I chose "Yes, 0.1° tolerance".
- **At the time:** on strip r0, "it feels like better as compared to the version one which we created"; after play, "The takeoff seems a little off, not quite there. The hind legs don't particularly move, so we can update the frames on those if possible." Then "Yes, make r1" and "Yes, keep r1".

### 22 Nov 2026: the raccoon's loops get strips too

- **Asked:** "the thing we did for jump u havent done for other animations of the raccoon". Claude Code drafted a revision, which I kept, and built a frame log for the loops preview and a crop tool (`74297f9`).
- **My verdict on each loop:** dictated, in [TUNING.md](TUNING.md), "Loops r0". All seven kept; climb is for later. Claude Code found that `sleep` holds one pose. I kept it: "there's no movement in that particular sleep, which is fine".
- **At the time:** "Okay, I'm gonna dictate you what I'm seeing." On climb, "Maybe we'll need to work on climb in the future, but for now, I'm just gonna go ahead and we'll move ahead with climb."

### 22 Nov 2026: the records, the short answers, and the baseline again

- **The short answers,** rewritten for the clips as built (`4d59d51`). Answer 2 was measured, not guessed.
- **The baseline:** the "before" logs had been overwritten, so Claude Code reran it in clean worktrees before and after (`82c9fc1`). Every count was the same; `cost_effects.gd` was 3/4 on both sides.
- **At the time:** "Draft short answers", then "Keep it"; and for the report, "Draft TEST-REPORT".

### 22 Nov 2026: my checks in play, the dev flag, and a new moth

- **The seam:** "them moths are fine they move in same loop irrespective of the players". It needed "a dev flag to disable the human npcs" (`f74ad90`).
- **The jump in play:** "Feels fine, even for different distinct workflows ... Maybe we can increase the distance ... Or maybe keep it." The distance is noted, not changed.
- **The moth:** "Why do you keep on going about the moth?" Claude Code explained that I had made it the graded sprite clip. I then generated a new low-poly moth with Gemini from Claude Code's prompt ("take this moth and update it just have one moth in the game over the fire", `b1736e3`). Its registration was measured, and its mutations rerun.
- **At the time:** "Moth is not a very important component within the game, to be honest. Like, it's just like a loop that we tried, like a tested loop ... I've tested it, it looks fine on me." Then: "You know what? Let's recreate the moth. I'll give you a updated moth."

### 22 Nov 2026: the moth guides him to the camp

- **Asked:** "let the moth be the one who guides the like raccoon to the particular campsite", with the waves "like a vibration, zing, zing, zing, not constantly".
- **The order:** "Do the development first, let me play it, and then we can do the draft". So the build came first, then I played it ("Feels right"), then the revision, with my job line: "he helps user navigate to the main area" (`b1865bf`).
- **At the time:** "I don't think the moth is being utilized. It's just roaming around the fire. We can see the fire flames as well if we think about it ... So enough indicators about the fire. So let's utilize the moth a bit better." After playing it: "Feels right".

### 22 Nov 2026: CLAUDE.md under 120 lines, and the README

- **CLAUDE.md** had grown to 153 lines; Claude Code trimmed it to 119 (`9e5fd21`).
- **The README** got its Assignment 7 section (`2c28950`).

### 22 Nov 2026: contact sheets, Rock the party out, the task sounds, and the chair by the table

- **Contact sheets:** "do we have the sprint sheets for the animations of the raccons we did ?", then "Yes, make them". One sheet for each strip, the jump's r0 and r1 and each of the seven loops; no sheet for the moth ("No, commit these", `e96486a`).
- **Rock the party:** "Rock the party remove this it should be just tasks", then "Remove it from code". The camp's tasks are a plain list now (`c8a01ab`).
- **The task sounds:** "use the sound effect when u complete a task replace it with the current vesrion", with two Pixabay sounds I picked. After listening: "Sounds good, commit" (`1d8d479`).
- **The chair by the table:** "can u move the chair near the table we have at camp ? and make the girl dance and come and sit on the chair for some time", "so we can use the ballons". Claude Code keyed her a `sit` clip in Blender, moved the chair, knot and balloons, and changed the balloon task's test to match. Kept: "Keep and commit".

### What I accepted, changed or turned down

From the record of what I chose in the chat; each brief revision says the same in its own line.
- **Accepted from Claude Code:**
  - the numbers in the phase tables and cycle specs, and the jump's key poses;
  - the drafts of the brief and its revisions, each kept by me;
  - the tests, the previews and the tool scripts (the sheet maker and the strip cutter);
  - the 3D balloons' build and timings, and the hint "Untie them, let them fly.";
  - the new moth's size, filtering and half-frame start;
  - the guide's distances and timings, and the waves' bursts;
  - the 0.1° tolerance in the rig read-back;
  - the dev flag as the campers' sight turned off;
  - the trimmed CLAUDE.md.
- **Changed, by my direction:**
  - **The jump:** the crouch and the bite out, back to the game's own jump.
  - **The balloons:** pixel sheets, then my Gemini sheet, then 3D; out of the camp with the girl; popping replaced by "Let the balloons go".
  - **The moth:** an extra, then the graded sprite clip, then my Gemini sheet, one moth instead of four, then its job as the guide: "he helps user navigate to the main area".
  - **The scope:** the requirements met for all seven raccoon loops, and strips for them, not only the jump.
  - **r1:** from my play, not from Claude's reading.
  - **The order:** the guide built first and played, then drafted.
- **Turned down:**
  - Claude Code's first four task ideas;
  - the CC-BY-SA pixel balloons;
  - my own 2D balloon sheet in the game;
  - the crouch and the bite;
  - four moths, for one;
  - breathing for `sleep` ("there's no movement in that particular sleep, which is fine").
  - The jump's distance: not now ("Or maybe keep it. I will let you know.").

### Still unresolved

- **Climb** needs more work ("Maybe we'll need to work on climb in the future").
- **The jump's distance:** maybe a little more, not decided.
- **`tests/cost_effects.gd`** fails 1 of 4 (its smoke case finds the fire out). It failed the same way before this assignment's first change, and it's still open.
- **Two of my checks are still to do:** both clips over the darkest and lightest ground, and the new moth's registration by eye.
- **The moth's exact-wrap quirk:** at 144 fps it still drops one frame in 48.
- **Not done yet:** the film, SUBMISSION.md, and moving the `a7` tag to the final commit.
