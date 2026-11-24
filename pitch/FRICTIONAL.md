# Frictional log: The Noise Next Door, final project pitch

`pitch/` · CSYE 7270 · Assignment 8 · Draft v0, 23 Nov 2026

A dated log of making the pitch film: what I asked for, what came back, what was checked, and what I decided, including what's still open. Each entry says who did what: me, or Claude Code (Claude Opus 5.5).

**How these entries were written.** Claude Code drafted them on 23 Nov 2026 from the session as it went. My messages are quoted exactly as I typed them, typos included. The chat doesn't show times, so only dates are given. The "At the time" lines are my own words from the chat; Claude Code added no reflection of its own.

---

### 23 Nov 2026: reading the assignment, and choosing the project

- **Asked:** I pasted the assignment, with no words of my own.
- **Came back:** Claude Code surveyed the repo (the tags `a2`–`a7`, the GDD, the tests) and Brutalist's docs. It offered four project options: level 1 as a vertical slice, the campers' stealth system, the raccoon's controller, or a technical-art pack.
- **Decided:** "No, the pitch needs to be about the entire game, not about just one section or like one thing. It needs to be about the entire game."
- **Came back:** PROJECT-BRIEF.md, drafted for the whole game. What exists is in the past tense with its tags; the chase, the city, the block and the ride home are "will".

### 23 Nov 2026: with Brutalist or without

- **Asked:** "I dont wanna use brutalist waht is the video we wanna make ?"
- **Came back:** Claude Code laid out a film without it: about 3 minutes, one beat per question, my own captures and voice. It said the assignment asks for the film to be made with Brutalist, and that its only stated exception is Brutalist not running on my machine.
- **Decided:** "unknow what install tht tool lets see what it does"

### 23 Nov 2026: installing Brutalist on Windows 11

- **What was installed:**
  - Brutalist, a shallow clone at `3a6d397`: 14,611 files, 946 MB;
  - FFmpeg 9.1 from winget. It showed only its licence notice; Claude Code passed no flag that accepts agreements;
  - its Python packages in their own environment, 615 MB, so my system Python wasn't touched;
  - Remotion's npm packages, 261 MB;
  - the Kokoro voice model, 338 MB.
- **What broke, and what was done:**
  - **`python3`.** The toolkit's scripts are bash, written for macOS, and call `python3`. On this machine that name is the Microsoft Store stub. Claude Code added a `python3` shim for the environment (`tools/windows/`).
  - **Smart App Control.** manim and faster-whisper failed: "An Application Control policy has blocked this file." Windows' Smart App Control (on: `VerifiedAndReputablePolicyState` 1) refused PyAV 18.1.1's DLL. Claude Code didn't touch the setting, since turning it off can't be undone without resetting Windows. PyAV 18.0.0 loads, and it's within the toolkit's `av<19`.
  - **The smoke test's compile.** It failed on a Windows path: the review timecode's font, `C:\…`, inside an ffmpeg filter, which ffmpeg's parser splits at the drive colon. Claude Code patched one line in `runtime/scripts/compile.py`.
  - **The smoke test's QC.** It still fails: Gate V calls the review timecode "edge-bleed". The toolkit draws that timecode only when FFmpeg has `drawtext`, which the author's Homebrew FFmpeg lacks (its own comment says so) and the gyan.dev build has. Not patched: the clean final doesn't draw it.
  - **The smoke test's final.** It was refused by Gate F for want of a FACTCHECK.md. That's by design.
- **Checked:** the doctor showed every feature ready except Manim equation beats (LaTeX, not needed). The smoke fixture rendered: two narrated slates, 13.9 s.

### 23 Nov 2026: the godot-gdd route, and my answers

- **Decided:** "Yes, use godot-gdd"
- **Found:**
  - **The persona.** Every Godot skill in the toolkit is locked to "Liam, in for Bear" and an @NikBearBrown end card. The assignment forbids the instructor's name, persona and credit line. The outro lock applies "to claude-liam reels ONLY", so the reel has its own slug, and the narration speaks as me.
  - **The board's credit.** `GodotDesignBoard` hard-coded "@NikBearBrown" in its corner. Claude Code added a `handle` prop that defaults to the old text, so other reels are unchanged; this one passes my name.
  - **`npx`.** On Windows it's `npx.cmd`, which Python can't launch by its bare name. Claude Code patched `remotion_scenes.py`.
  - All three patches are in `tools/brutalist-local.patch`, with two more from 24 Nov (the board's heading size and footer, below).
- **My answers** to Claude Code's questions:
  - the role, "Gameplay programmer";
  - the games I've played, "Untitled Goose Game, Stray, Overcooked, Cuphead";
  - why, "Mostly learning";
  - new this term, "Godot and GDScript, Blender modelling and rigging, Shaders and particles, Game animation and tests".
- **Came back:**
  - the beat sheet: 11 beats, narration in my voice, five boards quoting my GDD exactly;
  - the shot list;
  - Kokoro narration of 164 s;
  - a review cut with slates where my gameplay goes.
- **Checked:**
  - the godot-gdd check passes: all 11 sections, the 5 excerpts and the 5 evidence files;
  - Claude Code read a frame of each board.
- **Fixed while checking:**
  - **B06 overflowed** its board: two cards now, not three.
  - **B06 said "33 headless test scripts".** That was a count of test files at `ef386f9`. The fresh-clone run it cites ran 31.
  - **B01 said level 1 "exists".** It has no ending yet.
  - **The word timing.** `align.py` would have downloaded a Whisper model, so the cards' timing is estimated from where each phrase falls in the narration.
- **Seen, not fixed:**
  - **The serif.** EB Garamond isn't installed where Windows looks, so the boards' headings fall back to Georgia.
  - **The board's footer.** Its source line and corner credit sit 4–4.5 % from the bottom, just inside the toolkit's 5 % title-safe margin. To be checked by the final's frame gate.

### 23 Nov 2026: what's needed, the ending, and the Mac

- **Asked:** "What is needed for this? What is needed for the assignment apart from the movie?" Claude Code listed the deliverables and their status.
- **Corrected:** "The ending for the first phase is done almost. I'm working on the side for it, so we can claim, like we can say that it's on the first level is almost done. And it's not just a Windows game. I don't know why you're claiming that. It's a game in general. Would this not work in Mac?"
- **Came back:**
  - **The Mac.** It should work: Godot 4.7 exports macOS from the same project, Forward+ runs on Macs through Metal, and nothing in the game's code is tied to Windows. "Windows" had come from the GDD ("A Windows PC") and this machine. It's never been exported or run on a Mac, so the film says "will".
  - **The ending.** It isn't in this checkout, so the film says level 1 is "nearly done", with the ending "In progress · not shown".
  - B01, B05, B07 and the brief were rewritten, re-voiced and re-rendered.
- **Decided:** "Wait for the ending". The takes wait until it's committed, so the film can show it as real play.

### 23 Nov 2026: my confirmations, no Mac, and the root records

- **Confirmed:** on "Nobody outside the project has played it", "That's true."
- **On a Mac to test on:** "I don't have it." So B07 now says the Windows build will be run outside the editor and the Mac build stays untested. B07 was re-voiced and re-rendered, and the brief and FACTCHECK.md say the same.
- **On the root records moving on to Assignment 8:** "Yes, they have. Constantly updates have been made to the game for different tasks and levels and further development processes." Claude Code found that the root FRICTIONAL.md, TEST-REPORT.md and TUNING.md still held only Assignment 7, last changed at `e21bb3a`, and moved them on to Assignment 8, with the game's work since `a7`.

### 23 Nov 2026: the review cut, my first name, and the end card's hold

- **Asked:** "let me see the vid". Claude Code rebuilt the review cut from the current beats, with the draft end card, and sent it: 2 min 49 s.
- **Decided,** on how Kokoro says my surname: "You can just say first name. It's fine." B00 now says "I'm Abhinav", and B10 "by Abhinav". My full name stays on screen.
- **Came back:**
  - **The end card's hold.** It stopped on the last word. Brutalist's compiler won't let a beat outlast its audio by more than 0.15 s, and its narration step has no tail option. So `tools/set_timing.py` now appends `tail_hold_s` (1.0 s) of silence to B10's narration file, and the card holds past "by Abhinav": 5.08 s.
  - B00 and B10 were re-voiced and the review cut rebuilt: 2 min 49 s.

### 23 Nov 2026: a NotebookLM pack, and the film updated for the ending

- **Asked:** "can u give me a script for notebookllm for this ? along with visial imgs tht can help help the model ?"
- **Came back:** `design/a8/notebooklm/`:
  - a read-me with the sources to upload, a prompt to paste, and the facts to check the video against;
  - a guide source laid out in the seven questions;
  - 14 pictures, each with a caption bar saying what it is (REAL GAME, FIXTURE CAPTURE, GENERATED, CONSTRUCTED). They come from `make_images.py`, and the storyboard panels were converted by `tools/svg_to_png.gd`.
  - It's an extra, as Assignment 7's explainer was, not the course's film.
- **Found:** level 1's ending was committed in the meantime (`c92a53d`): the cake, the laces, the beanie, a 10.2 s cutscene and the chase out of the camp. Its test passes 19 checks at 30, 60 and 144 fps.
- **Decided:** "Yes, update them", the film and the brief.
- **Came back:**
  - **B01** says level 1 runs end to end, and its board shows the ending as built (`c92a53d`).
  - **B01E** is new: the ending as real play, from a staged cake start (run-03).
  - **B07's "first"** is now level 1 exported for Windows and macOS with a headless play-through test. That's Claude Code's proposal.
  - All were re-voiced and re-rendered, and the godot-gdd check still passes. The brief, FACTCHECK.md and SHOTLIST.md match, with run-03's command.

### 23 Nov 2026: Scare a camper committed, for the recording

- **Decided:** "Commit Scare first", so the takes show the camp as it is.
- **Found:** a peer session ("Trigger the next phase: the camper's beanie") had a change in progress beside it: everyone gathering round the cake. It was in `camp_person.gd`, `camp_finale.gd`, the cake test and a brief revision not yet kept, changed minutes before. `camp_person.gd` held both changes.
- **Came back:** Claude Code staged only Scare's files and its five hunks of `camp_person.gd`, leaving the gathering where it was.
  - **The check:** it ran the whole test list on exactly that staged state, in its own worktree, and everything passed at its counts (`cost_effects` as before).
  - **Then it committed:** `81c1df3`.
  - B07's "First" card no longer lists Scare a camper. The brief, FACTCHECK.md, the records and the NotebookLM pack say it's committed.
- **Found:** the working tree isn't `81c1df3`. It still holds the uncommitted gathering, so a take from this folder wouldn't match a named commit.

### 23 Nov 2026: the recording revision, 370f62d

- **Said:** "its done i have updated it", then "commited". The camp round the cake went in from the other session as `370f62d`.
- **Came back:**
  - **The recording revision** is `370f62d`, in `beat_sheet.json`, SHOTLIST.md and FACTCHECK.md.
  - **B01E** now says "the whole camp gathers round" and "the men chase me out". It was re-voiced: 13.1 s.
  - **The whole test list** was run on `370f62d` itself, in a worktree (TEST-REPORT.md).
- **Found:** Godot had imported 56 of the reel's media files (its narration MP3s and WAVs, its PNGs), writing `.import` files into `pitch/`. They were deleted, and `pitch/` and `design/a8/` each got a `.gdignore`, so the editor skips them. That makes this folder `370f62d` for the game, with only the pitch's own files beside it.

### 23 Nov 2026: the script confirmed

- **Confirmed:** "yea i have checked the scripts its correct interpreations". That covers B04's comparison with Untitled Goose Game and Stray, cutting save states, B07's "first" (the exports and a play-through test), and the risk plan B08 says.
- **Marked confirmed** in the beat sheet, the brief, FACTCHECK.md and the NotebookLM pack. The brief's third risk bullet (simple in-engine cutscenes) isn't in the film, so it stays marked as Claude Code's.

### 23 Nov 2026: two takes lost, and the takes now screen-recorded

- **Asked:** "2 have done do u see the recording ?" I'd recorded run-01 and run-02 with the Movie Maker commands in SHOTLIST.md.
- **Found:** no AVI anywhere. Then my console's output (run-02):
  - `ERROR: Condition "f.is_null()" is true` at `write_frame`, for every frame;
  - "Done recording movie at path: …\pitch\capture\run-02.avi … 7159 frames at 30 FPS (movie length: 00:03:58:19), recorded in 00:01:35 (250% of real-time speed)".
- **Two mistakes in Claude Code's commands:**
  - **The folder didn't exist.** They wrote into `pitch\capture\`, which hadn't been made, and Movie Maker doesn't create its folder. They also used the windowed exe, which shows no console, so the error wasn't seen. Claude Code confirmed the cause with a headless run into a missing folder: `ERR_CANT_OPEN` at `write_begin`.
  - **The cap didn't hold.** `--max-fps 30` doesn't hold Movie Maker to real time. It ran the game 2.5× fast, too fast to play a take by hand.
- **Came back:** the takes are now the game run normally, at real speed, from the console exe, and its window recorded with Windows' Snipping Tool (Win + Shift + R).
  - `pitch\capture\` now exists.
  - `tools/cut_clips.py` reads MP4 takes, fits any recorded size into 1080p without stretching, and labels each clip "REAL PLAY · screen recording". It was tested on a 1604 × 906 MP4.
  - SHOTLIST.md, the beat sheet's labels, FACTCHECK.md, SOURCES.md and BUILD-PROMPT.md match.
- **Also found:** `Gamedev\Pitching_The_Noise_Next_Door.mp4` (8 min 17 s, 1280 × 720, 22:45), not a take. Mine to say what it is.

### 23 Nov 2026: run-01 recorded, and its clips cut

- **Said:** "Takes recorded", then "only taken one".
- **Found:** four Snipping Tool recordings, in `Videos\Screen Recordings`. One is run-01 (23:16): title screen to the TO DO list. The other three are partial tries:
  - free play with the tent and a chase;
  - a walk to the table;
  - the cake start, spotted before the laces were tied.
- **Came back:**
  - **The take:** run-01 is in `pitch/capture/` with its notes. Its box took in the window's title bar, so the cutter crops each take (1280 × 715 at (2, 39) for run-01).
  - **The clips:** B00, B03 (three cuts) and B05 are cut, at real speed, labelled bottom-left in two lines, clear of the game's title and task notes.
  - **B05's line** now says "a moth flies ahead of him down the trail". The take shows it leading, not buzzing round his head, which it does only while he stands still.
  - **B03's lines** follow the take's order: spotted and into the bush, then sneaking out, then the task crossed off. Both beats were re-voiced.
- **For the next takes:** keep the mouse pointer off the game window; it shows in run-01.

### 24 Nov 2026: run-02 and run-03, and the day's game work committed for them

- **Said:** "all 3 recordings have been saved". Two new Snipping Tool recordings: 17:13 (80.6 s) and 17:29 (115.9 s).
- **Found:**
  - Both were played on the day's game work, which wasn't committed: the pot on a crossbar, the push, the campers' "huh?", the plug at the speaker, the chair moved, and more. No named revision held what they show.
  - The takes aren't the shot list's plan:
    - **17:13** has the tent and Scare a camper, not the backpack heist, and no climb home.
    - **17:29** has the cake to the chase, but he's caught twice and the game is closed before "To be continued".
- **Two choices** of Claude Code's, its recommendations, both kept: "Commit it now" and "Use what's recorded".
- **Came back:**
  - **The commit.** A peer session was changing the same files, so Claude Code staged only the work from before the takes. The brief was staged up to the chair's revision. The cutscene's removal (the brief's next revision, and `camp_finale.gd` with its test) came after the takes, so it was left out.
  - The whole test list ran on exactly that staged commit, in its own worktree, from an empty import, and passed (cost_effects 3 of 4, as at the baseline). It's `263ac50`, and every game file in it predates both takes.
  - **The takes** are `capture/run-02.mp4` and `run-03.mp4`, unchanged, each with notes.
  - **B02** is now Scare a camper, re-voiced: "Spotted, I hop into the keeper's box, and they lose me. They search right round it, so I burst out and scare them."
  - **B09** is run-03's getaway, past the cabin. **B01E** is five cuts of run-03, leaving out the cutscene and the catch at 34 s.
  - Each clip's label carries its own take's revision and date, and the end card names both.
- **Corrected along the way:** run-02 was first labelled as the developer menu's "free" start. The fire burns from its first frame, and "free" starts with it out, so the label now says only "from the developer menu".
- **Asked:** "whats taking soo long for commiting man ?" The 20-minute test run, on the commit alone.
- **Said:** "also dont update the recorded vids in the repo". None of the recordings or clips is in git: the root `.gitignore` keeps `*.mp4` out, and `pitch/.gitignore` keeps out `media/`, `mp3/` and `exports/`.

### 24 Nov 2026: the final's gates, and what they found

- **Gate V on the review cut** failed every frame. On the boards, it was the review cut's own timecode and beat strip. On gameplay, it was the game's picture filling the frame at night (edge-bleed, low contrast).
- **The fact check's gate** (`runtime/qc/factcheck_check.py`) found no claims table: it wants a Verdict column. FACTCHECK.md was rewritten as one, with 39 rows, each PASS or EXEMPT, for the takes as recorded.
- **Gate T** stopped the final, in nine beats:
  - **The label was too small.** At 22 px, its small letters were 11–15 px tall, under the toolkit's 20 px floor at 1080p. The label is now 40 px.
    - At 40 px it can't sit on the picture without covering the game's own task notes. So each gameplay clip now uses the toolkit's documented presentation (the godot-trailer skill's "Traps already met"): the game at 80 %, inside the title-safe box, on a dark matte, with the label in the band under it.
    - With the picture inside the safe box, no edge-bleed exemption is needed.
  - **The game's picture was read as type:** its grass, stripes and HUD. Each gameplay beat now declares its label's lines as its typography (`qc.typography_regions`, with a written reason), measured from the font the cutter draws with. Gate V still inspects the whole frame.
  - **B06's jump strip** was read as unreadable type: grey on blue-grey, 1.4:1. It's ten frames of the raccoon and has no text. B06 declares every region of the board except the strip.
  - **The boards' section headings**, on B01, B06 and B07: their small letters were 37–38 px at 4K, under the 41 px floor. `GodotDesignBoard`'s heading goes from 40 to 46 units. B04 and B08 passed only because their headings' words happen to have tall letters.
- **Gate V on the final's candidate** then passed every gameplay beat and refused the five boards. Their footer, the source line and my name, sat 4–4.5 % from the bottom, under the 5 % title-safe line, as the component draws it for every reel. It's now 5.8 % up, inside the line, and still clear of the panel above it, which ends 12 % up.
- **Also found:** `remotion_scenes.py` writes the beat sheet back from the copy it read at its start. So a change made to the sheet while it renders is lost, as B06's declaration was once. B06's declaration now lives in `tools/set_timing.py`, which runs before it, and the gameplay beats' in `tools/cut_clips.py`, which runs after.
- **The toolkit patch** has two more changes, the heading and the footer, so it's renamed `tools/brutalist-local.patch`.

- **The final** then passed, and its receipt says "ready". It was 3 min 0.8 s, SHA-256 `3f792689…` (replaced below). Its gates:
  - `art final` ran Gate T, the compiler's beat lint and shape gates, and Gate V on the candidate (0 blockers, 0 major);
  - run beside it: the fact-check gate (clean, 39 rows), the godot-gdd check before and after (PASS), and the loudness gate, which `art final` doesn't run (PASS, −24.7 LUFS, true peak −2.9 dBTP).


### 24 Nov 2026: the earlier assignments' names out of the film

- **Asked,** after "Looks good, commit" (`d9f2403`, tagged `a8` but not pushed): "remove the previous assignement names if u see them".
- **Found** in the film: two boards and two lines named earlier assignments.
  - **B01's board:** "tag a7", twice.
  - **B06's board:** "built by tag a7", "Tagged: a5 shaders · a6 particles · a7 animation" and "(tag a7)".
  - **B06's narration:** "…each have a tagged assignment". **B09's:** "…each has its own tagged assignment".
- **Came back:**
  - **The boards** name the commits and dates instead: "Built · e21bb3a, 22 Nov", "built by 22 Nov (e21bb3a)", "Built and tested: shaders · particles · animation".
  - **B06** now says "…are each built and tested, with headless tests a stranger can rerun", and **B09** "…and I've used every one of them in this game". Both were re-voiced, and B01 and B06 re-rendered.
  - **The final** was rebuilt: 3 min 0.7 s, SHA-256 `087666b3…`. Every gate passed again: T, V (0 blockers), loudness (−24.7 LUFS), the fact check and godot-gdd.
  - **PROJECT-BRIEF.md's** line that matched B09 changed with it.
- **Kept:** the tags in the records (PROJECT-BRIEF.md's "exists today", FACTCHECK.md), as the assignment asks for "the tag or commit where each thing can be seen". The end card's course line stays.

---

## Still open (24 Nov 2026)

- **The film's link,** once I've uploaded it, for the README and the Canvas note.
- **Pushing** `main` and the `a8` tag, then the Canvas ZIP and note, on my word.

Kept on 24 Nov 2026, after watching the final: "Looks good, commit". That covers B02's new line and the film.
