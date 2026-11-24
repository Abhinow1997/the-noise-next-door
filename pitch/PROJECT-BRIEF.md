# Project brief: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 8: final project pitch · Draft v0, 23 Nov 2026

**Status.** Claude Code's draft, for me to check. The pitch is about the whole game, not one level or one system ("the pitch needs to be about the entire game"). My role, the games I've played and my reasons are my answers of 23 Nov 2026. The comparison, what's out, what comes first and the risk plan are Claude Code's drafts that I confirmed on 23 Nov 2026 ("yea i have checked the scripts its correct interpreations"). By the honesty rule, the past tense is only for what exists and can be shown, with its tag or commit; everything else is "will".

**Stack.** Godot 4.7.2 stable, GDScript, the Forward+ renderer. Export targets: desktop, Windows and macOS.
- It's built and tested on Windows 11. It has never been exported, and never run on a Mac.
- Nothing in the game's code is tied to Windows: only the `.bat` launchers and the test wrapper's search for Godot are.
- Godot 4.7 exports both from the one project, and Forward+ runs on macOS through Metal.
- There's no export preset or export template on this machine yet.

Built with Claude Code at my direction, and Blender 5.2 through the Blender MCP.

## 1. What is it?

The Noise Next Door is a slapstick stealth-puzzle game for desktop. You play a raccoon who pranks the noisy campers partying under his tree, gets chased into town wearing a camper's red beanie, and is driven home by that same camper.

**Today** level 1 runs end to end: from the title screen to the chase out of the camp, ending on "To be continued". Its ending was built on 23 Nov 2026 (`c92a53d`), and the last of its eight tasks, Scare a camper, the same day (`81c1df3`).

**When it's done** it will be a playable desktop build for Windows and macOS, from the title screen to an end screen: the intro, level 1 (the campsite), the chase out of the forest as a cutscene, level 2 (the city), level 3 (the block), the ride home and the epilogue. With it will come the headless test suite and a test report a stranger can rerun.

## 2. Why would anyone care?

- **You're the pest, not the hero.** The humans aren't enemies and there's no losing. Getting caught is slapstick, and it costs only what he's carrying.
- **Every job is solved by reading a person's routine.** You watch for when the camper turns his back, and pick your moment.
- **No dialogue.** The story is told by what you do and how the people react.
- **You see the party's music rather than hear it.** It shows as sound waves at the edge of the screen, and they lead you to the party.

## 3. What does it give the player?

A casual PC player gets the sneaky fun of a heist at night: watching a camp, waiting for the right moment, getting away with the marshmallows. They also get a short story with an ending. How long a play-through of level 1 takes is still to be measured.

## 4. What makes it different?

I've played all four of my GDD's inspirations (Untitled Goose Game, Stray, Overcooked and Cuphead). The two closest are these:
- **Untitled Goose Game** makes you the pest too, working down a to-do list, but you can't see who's watching. This game gives a casual PC player a heist they can plan, because every camper's sight is drawn on the ground and shortens while you sneak.
- **Stray** puts a cat in a city whose people are gone. Here, the people are the puzzle: their routines set the jobs.

Claude Code drafted this comparison; I confirmed it's true to both games as I played them (23 Nov 2026).

## 5. Who opens it, and what do they do?

- **The target role:** gameplay programmer.
- **The reader:** a hiring manager or a lead.
- **The first sixty seconds** will be: open the build, on Windows or a Mac. The title is the game's own world at night. New Game glides the camera down to him asleep in his hollow. A move key wakes him, and a moth buzzes round his head, then flies ahead down the trail toward the party. The only words on screen are one task at the bottom, "Investigate the music". Whether a stranger knows the keys without reading anything is untested.
  - That much runs today from Godot on Windows (tag `a7`). No export exists yet.
- **A lead engineer** will be able to rerun every check with one command per test (`bash scripts/run-test.sh <test> 60`) and compare against the test report.

## 6. What does it prove about me?

Each of the course's skills, with its evidence:

| Skill | Evidence today |
|---|---|
| Shaders and materials | The campers' vision cones, my hand-written shader, and its mutations (tag `a5`) |
| Particle effects | The leaf burst and the campfire smoke, driven by the fire's life (tag `a6`) |
| Animation and state | The raccoon's jump on his Blender rig, with its phase table, 26 pins and edge tests at 30, 60 and 144 fps; the moth's sprite flutter; his seven loops' cycle specs (tag `a7`) |
| Profiling | The two effects' cost, measured on my RTX 4050 Laptop GPU (TEST-REPORT.md at tag `a6`) |
| Verification habits | 31 headless test scripts through one wrapper, all rerun from a fresh clone on 22 Nov (`logs/a7-baseline-final/SUMMARY.txt`); mutations showing each read-back fails when it should; human checks logged apart from them; Claude Code directed by a brief written before the work, with the prompts committed (`design/a7/`) |

**What a reviewer could fairly conclude:** that I can build a game system and show that it works, with checks a stranger can rerun, across code, shaders, effects and animation.

**What they couldn't:** whether strangers enjoy it. No one outside this project has played it yet (my confirmation, 23 Nov 2026).

## 7. What's in, what's out, what comes first?

- **Deliberately out:** save states, with the game sized to play in one sitting (Claude Code's proposal, confirmed by me on 23 Nov 2026). The GDD plans save states, and the title's Continue waits for them, so this changes the GDD.
- **First** (Claude Code's proposal, confirmed by me on 23 Nov 2026): level 1 exported for Windows and macOS. Its end, the cake and the chase, is built (`c92a53d`).
- **How someone would know it ran:**
  - a headless test that plays from New Game to "To be continued" and checks each step;
  - the Windows build started outside the editor, with its log kept;
  - the macOS build can't be run here: I don't have a Mac.

## 8. What could sink it?

**Scope.** The whole game is three levels for one person. Level 1's camp has taken from 23 Oct to now. The town needs things that don't exist at all:
- three dogs;
- an animal-control officer and the neighbours;
- the diner, the alley and the block;
- the cutscenes.

**What I'd do about it** (Claude Code's proposal; the first two confirmed by me on 23 Nov 2026, as the film's B08 says them):
- Level 1 is finished and exported first, so there's always a whole, playable game to show.
- Each later level starts only after the one before it exports and passes its tests.
- The cutscenes are simple in-engine shots (Claude Code's addition, not in the film).

**Also unverified: the macOS build.** Nothing in the code should stop it, but it has never been exported or run on a Mac, and I don't have a Mac to test it on. Until someone runs it on one, it's an untested build, and it's called that.

## 9. Why this project?

Mostly to learn. Every skill this course covers was new to me this term:
- Godot and GDScript;
- Blender modelling and rigging;
- shaders and particles;
- game animation and its tests.

Each has its own tagged assignment, from `a2` to `a7`. Finishing the whole game is how I'll find out whether I can carry them all through to the end.

---

## Exists today

At tag `a7` (`e21bb3a`) unless another commit is named.
- **The way in:** the title screen over the game's own world at night; New Game into his hollow; the moth guiding him to the camp.
- **Level 1's camp:**
  - four campers on looping routines, with vision cones, frights, chases and searches;
  - the tutorial;
  - the tasks: Investigate the music, Steal the marshmallows, Turn the music off, Raid the cooler, Dismantle the tent, Raid the bear bag and Let the balloons go;
  - Eat the pizza (`7adb941`); Raid the supply tent (`ef386f9`), replaced the same day by Scare a camper (`81c1df3`): hide in the keeper's box, rustle it, burst out at whoever comes to look;
  - **level 1's ending** (`c92a53d`, 23 Nov 2026):
    - once 5 tasks are done, the camper brings out a cake;
    - his laces are tied, and he falls;
    - his red beanie is swiped, and a 10.2 s cutscene plays;
    - then the chase out of the camp, with the moth leading, to "To be continued";
    - its test, `tests/test_cake_finale.gd`, passes 19 checks at 30, 60 and 144 fps.
- **The raccoon:** rigged in Blender, with nine clips, the jump among them. The campers were smoothed at `34801ab`.
- **The shaders:** the vision cones (tag `a5`). **The effects:** the leaves and the smoke (tag `a6`).
- **The music and sounds:** generated with Suno and ElevenLabs, with the reference art from Gemini (tag `a2`). The Blender props are at tag `a3`.
- **The tests:** the baseline of 22 Nov at `160c0eb` (`logs/a7-baseline-final/`). `cost_effects.gd` fails 1 of its 4 checks, as it has since before Assignment 7.

## Will exist

- Where the chase out of the camp leads: the run past the highway into the city (the new location isn't built).
- **Level 2, the city:**
  - Cross the road, the diner's dumpster, the raccoon-proof bin, Steal a slice, and Shake off the dogs;
  - the three dogs;
  - the neighbours' photos.
- **Level 3, the block:** the barbecue heist, the animal-control officer and the marshmallow trap.
- The ride home, the epilogue and an end screen.
- **The exports:** their presets, the export templates, a Windows build and a macOS build.
- A play-through test, and a test report for the whole game that a stranger can rerun.

---

**Provenance.** The game, its story and its design are mine (CONCEPT.md, GDD.md, STORYBOARD.md). That the pitch covers the whole game is my decision (23 Nov 2026). This draft's wording, its proposals (what's out, what comes first, what to do about the risk) and the lists are Claude Code's, from the repo as at `ef386f9`, then `c92a53d` (level 1's ending), and the working tree on 23 Nov 2026.
