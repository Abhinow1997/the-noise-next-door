# The NotebookLM explainer for Assignment 8: what to upload, and what to ask for

Drafted by Claude Code on 23 Nov 2026 for the author's NotebookLM Video Overview of the final project pitch, as was done for Assignments 6 and 7. It describes the repo at `c92a53d`, with level 1's ending built.

> **Not the course's required film.** The assignment asks for a pitch film made with Brutalist; that's `pitch/`. A NotebookLM video is an extra, as Assignment 7's was. It's NotebookLM's summary of these files, and it may simplify or misstate details; the repo is the record. If it goes beside the pitch, it's labelled as an AI explainer made by NotebookLM.

## 1. Upload these sources, in this order

**Text: these give it the whole picture.**

| # | File | Why |
|---|---|---|
| 1 | `design/a8/notebooklm/A8-pitch-source.md` | **Start here.** The game in one sentence, what exists (with commits and tags), what will, the pitch in the order of the course's seven questions, what each picture is, who did what, and the limits. |
| 2 | `GDD.md` | The design document, version 1.0 of 19 Oct 2026. It's older than the game in places (it says "no humans", "a Windows PC"), so the prompt below says source 1 wins. |

Leave out the rest:
- **`CONCEPT.md`** is Assignment 2's page (6 Oct), from before the game's low-poly look and its campers. Source 1 has what it says that's still true.
- **`CHANGE-BRIEF.md`, TEST-REPORT.md, TUNING.md and FRICTIONAL.md** are Assignment 7's and the game's detailed records, and would pull the video into animation detail.
- **`pitch/PROJECT-BRIEF.md`** still has level 1's ending as in progress, until it's updated.

**Pictures,** if NotebookLM accepts images: the 14 PNGs in `design/a8/notebooklm/images/` (not the `raw/` folder). Each carries a caption bar saying what it is:
- **REAL GAME:** a screenshot of the running game;
- **FIXTURE CAPTURE:** a recorded preview run in the game's level;
- **GENERATED:** the author's Gemini art;
- **CONSTRUCTED:** a storyboard panel, a plan, not the game.

| # | Picture | Kind |
|---|---|---|
| 01 | The title screen | Real game, 23 Oct (an older build) |
| 02 | The waves at the screen's edge | Real game, 25 Oct |
| 03 | The heist: unzipping the backpack | Real game, 25 Oct |
| 04 | Caught: the bag snatched back | Real game, 25 Oct |
| 05 | Their sight on the ground, red when spotted | Real game, 28 Oct |
| 06 | The camp at night, the smoke | Fixture capture, 8 Nov |
| 07 | The top of a jump | Fixture capture, 21 Nov |
| 08 | The jump, frame by frame | Fixture capture, 22 Nov |
| 09 | The moth's sprite sheet | Generated (Gemini) |
| 10 | The storyboard, 15 panels | Constructed |
| 11 | Panel 8, the red beanie | Constructed |
| 12 | Panel 11, the town's dogs | Constructed |
| 13 | Panel 14, the ride home | Constructed |
| 14 | The sausage dog, reference art | Generated (Gemini) |

**There's no picture of level 1's ending yet.** Once it's recorded (`pitch/SHOTLIST.md`, run-03), a frame of the cake, the fall or the chase can be added the same way.

`make_images.py` remakes them; its docstring has the two commands.

## 2. The Video Overview's settings

Choose **Video Overview**, then **Customize**: the Explainer format, English. Paste one of these into "What should the AI hosts focus on?".

### The full prompt

> Make a pitch for The Noise Next Door, a slapstick stealth-puzzle game made in Godot 4.7.2 by one student, as their final project. Treat A8-pitch-source.md as the guide; where GDD.md differs, A8-pitch-source.md is current.
>
> Follow its seven questions, in order:
> 1. What it is, and what exists when it's done.
> 2. Why anyone would care.
> 3. What it gives the player.
> 4. What makes it different: Untitled Goose Game and Stray, games the author has played.
> 5. Who opens it: a hiring manager or lead, for a gameplay programmer role, and their first minute.
> 6. What it proves, skill by skill, with its tagged assignment as evidence, and what it can't prove yet.
> 7. What's out (save states), what comes first, what could sink it (scope, and an untested Mac build), and why the author picked it (mostly to learn).
>
> Be strict about tense. Built things are described as built, with their commit or tag: level 1 from the title screen to the chase out of the camp, ending on "To be continued". Everything else is "will": the city, the block, the ride home, the exports. Don't invent players, playtests, reviews, downloads or numbers. Nobody outside the project has played it. When you show a picture, keep to its caption: real game, fixture capture, generated, or constructed (a plan, not the game). Speak of the author in the third person. Keep it clear and friendly, for a game-development class.

### The short prompt (if the box is small)

> Pitch The Noise Next Door as A8-pitch-source.md does, through its seven questions in order. Built things in the past tense with their commit: level 1 runs from the title screen to the chase out of the camp. Everything else is "will". Invent nothing: no players or numbers. Keep each picture to its caption (real game, fixture capture, generated, constructed).

## 3. Before generating

The two lines that were the author's to confirm are confirmed (23 Nov 2026): the comparison with Untitled Goose Game and Stray, and what comes first (the Windows and macOS builds of level 1, and a headless play-through test).

## 4. Check the video against these facts

NotebookLM can get these wrong, so check each one:

| Fact | Correct |
|---|---|
| What exists | Level 1, from the title screen to the chase out of the camp and "To be continued". The ending was built on 23 Nov 2026 (`c92a53d`) |
| What doesn't | The city (level 2), the block (level 3), the ride home and the epilogue; any exported build |
| Platform | A desktop game for Windows and macOS (planned). It runs today in Godot on Windows. The Mac build will be untested: no Mac |
| The ending | After 5 of the camp's tasks: the camper fetches a cake, you tie his laces (hold E 2.5 s), he trips, the cake lands on his face, you swipe his red beanie, a 10.2 s cutscene, then the chase, with the moth leading |
| The campers | Four: the camper in the red beanie, the low-poly man, the girl, the fire keeper |
| Losing | There's none. Caught, he loses what he carries, and only that job resets |
| The tests | 31 headless test scripts rerun from a fresh clone on 22 Nov (all pass but one check of `cost_effects.gd`); the ending's 19 checks pass at 30, 60 and 144 fps |
| The skills' tags | Shaders `a5`, particles `a6`, animation `a7` |
| Players | Nobody outside the project has played it. No playtests, no numbers |
| The role | Gameplay programmer |
| Out | Save states |
| The risk | Scope: three levels, one person, level 1 took about a month |
| The pictures | Storyboard panels are plans (constructed); the dog and the moth's sheet are the author's Gemini art (generated); screenshots from Oct are older builds |
| The author's name | Not needed in the video; if it's used, it's the author's, never anyone else's |

If a claim isn't in the sources, regenerate, or note it where the video is linked: "It may simplify or misstate details."

## 5. Once it's made

Send me the video's link, filename and SHA-256. I'll add them to `pitch/README.md` and `pitch/SOURCES.md`, beside the pitch film, labelled as NotebookLM's.
