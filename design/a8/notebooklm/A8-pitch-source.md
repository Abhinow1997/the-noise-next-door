# The Noise Next Door: the whole game, pitched

A source for NotebookLM's Video Overview of Assignment 8, the final project pitch. Drafted by Claude Code on 23 Nov 2026 from the repo at commit `c92a53d`, plus the uncommitted work named below. **Where this file and GDD.md differ, this file is current:** the GDD is version 1.0 of 19 Oct 2026, and much has been built since.

**The honesty rule this pitch follows.** What exists, and can be shown, is in the past or present tense, with the commit or tag where it can be seen. Everything else is "will". Nothing here is invented: no players, playtest quotes, downloads, wishlists or measurements that weren't taken. Every picture says on its caption bar whether it's the real game, a fixture capture, generated art or a constructed plan.

---

## The game in one sentence

The Noise Next Door is a slapstick stealth-puzzle game for desktop, made in Godot. You play a raccoon who pranks the noisy campers partying under his tree, is chased into town wearing a camper's red beanie, and is driven home by that same camper.

**When it's done** it will be a playable desktop game for Windows and macOS, played from the title screen to an end screen through three levels: the campsite, the city and the block. The ride home and an epilogue come after them.

## What exists today

All of it runs in Godot 4.7.2 on Windows 11. No export exists yet.

**The way in** (tag `a7`):
- the title screen, the game's own world at night;
- New Game glides the camera down to the raccoon asleep in his hollow, and a move key wakes him;
- a moth buzzes round his head, then flies ahead down the trail to the party, about 20 seconds' walk away;
- the party's music shows as waves at the edge of the screen.

**Level 1, the campsite, end to end:**
- **The campers:** four of them (the camper in his red beanie, the low-poly man, the girl and the fire keeper), each on a looping routine.
- **Their sight** is drawn on the ground as cones, which shorten while he sneaks. Seen, they take fright, chase him and search. Caught carrying their things, he has them snatched back, and only that job resets. There's no losing, no health and no lives.
- **The tutorial:** the hide in the bush, the roasted marshmallow, the TO DO list.
- **The camp's eight tasks:**
  - Steal the marshmallows, Turn the music off, Raid the cooler, Dismantle the tent, Raid the bear bag and Let the balloons go (by tag `a7`);
  - Eat the pizza (`7adb941` and `ac2148a`, 23 Nov);
  - Scare a camper (`81c1df3`, 23 Nov): hide in the keeper's box, rustle it, and burst out at whoever comes to look.
- **Level 1's ending** (`c92a53d`, 23 Nov 2026):
  - Once 5 of the camp's tasks are done, the camper fetches a cake from his tent to a folding table, and the whole camp gathers round it (`370f62d`).
  - **Tie his laces:** sneak behind him and hold E for 2.5 s. His next step trips him. The cake lands on his face, and his red beanie slips off.
  - **Swipe his red beanie:** grabbing it starts a 10.2-second cutscene. He gets up and stamps, the girl takes fright, and the men go after the raccoon.
  - **Get away with it:** the camper and the two men chase him out of the camp, with the moth leading the way, to the forest's north-east edge. There the screen says "To be continued", and the game returns to the title.
  - **The new location isn't built.**
  - **In play,** the author said: "yea feels good for now."

**Under the hood:**
- **The raccoon:** a Blender rig with ten clips, among them a jump designed frame by frame (Assignment 7, tag `a7`). The camper gained three clips for the ending: carrying, tripping, getting up.
- **The shaders:** the campers' vision cones, the author's own hand-written shader (Assignment 5, tag `a5`).
- **The particle effects:** the leaves bursting from the bush and the campfire's smoke, with their cost measured on the author's RTX 4050 laptop (Assignment 6, tag `a6`).
- **The tests:**
  - 31 headless test scripts, all rerun from a fresh clone on 22 Nov 2026. All pass except one check of `cost_effects.gd`, a known open issue;
  - since then, the ending's test: 19 checks, passing at 30, 60 and 144 frames a second.

**Not done yet:**
- No stranger has played it. No one outside the project has.
- No build has been exported.

## What will exist

All of this is proposed: none of it is built.
- **Level 2, the city:**
  - he arrives lost in the suburbs;
  - the jobs: crossing the road, the diner's dumpster, a raccoon-proof bin, stealing a slice, and shaking off three dogs;
  - neighbours snap photos of "the masked bandit in the beanie".
- **Level 3, the block:** the block party's barbecue heist, and the animal-control officer's marshmallow trap.
- **The ending:** the camper recognises his beanie in the photos and drives him home. **The epilogue:** a new party starts under his tree.
- **The exports:**
  - a desktop build for Windows and one for macOS. The macOS build will be untested, because the author has no Mac;
  - with them, a headless test that plays from New Game to the end, and a test report a stranger can rerun.

---

## The pitch, in order: the seven questions

This is the order the pitch takes, and the points each part makes. The quoted lines are the author's script for the film, in the first person.

### 1. What is it?
- **The game:** a slapstick stealth-puzzle game for desktop, for Windows and macOS.
- **What exists:** level 1 runs from the title screen to the chase out of the camp, ending on "To be continued".
- **What doesn't:** the city, the block and the ride home.
- **Done,** it's a desktop game played from title screen to end screen.

### 2. Why would anyone care?
- **You're the pest, not the hero.** Every job comes from reading someone's routine: the camper roasts with his back to his backpack, so that's when you unzip it.
- **No game over.** Getting caught is slapstick. A man snatches the bag back, and that's the whole cost.
- **No dialogue.** The story is told by what you do and how the people react.

### 3. What does it give the player?
- The sneaky fun of a heist at night, for a casual PC player.
- You can see who's watching: each camper's sight is drawn on the ground, and it shrinks while you sneak.
- When a job lands, it's crossed off the list.

### 4. What makes it different?
- The author has played Untitled Goose Game and Stray.
- **Untitled Goose Game** makes you the pest too, working down a to-do list, but you can't see who's watching. Here you can, so you plan the job around it.
- **Stray** puts a cat in a city whose people are gone. Here, the people are the puzzle.

### 5. Who opens it, and what do they do?
- **The role:** the author is aiming at gameplay programmer roles.
- **The reader:** a hiring manager or a lead.
- **What they'll do:** open the build on Windows or a Mac. From New Game, a moth buzzes round the raccoon's head, then leads him to the party, with one task on screen.
- **A lead engineer** can rerun every test with one command each.

### 6. What does it prove about the author?
- **The comparison:** in October the design document said the game had no humans yet. Now it has four, with routines and sight.
- **The skills, each with a tagged assignment:** shaders (`a5`), particles (`a6`), and the jump's animation and state (`a7`).
- **The verification habits:**
  - headless tests a stranger can rerun;
  - tests pinned before a change and edge tests at every boundary;
  - mutations that prove a test can fail;
  - the human checks written down beside them.
- **What it can't prove yet** is whether people enjoy it. Nobody outside the project has played it.

### 7. What's in, what's out, what comes first?
- **Out: save states.** The design document plans them; the author is cutting them so the game plays in one sitting.
- **First (Claude Code's proposal, confirmed by the author):** the Windows and macOS builds of level 1, with a headless test that plays from New Game to "To be continued".
- **How you'd know it ran:** that test, and the Windows build run outside the editor. The Mac build stays untested.

### 8. What could sink it?
- **Scope.** It's three levels for one person, and level 1 alone has taken about a month, from 23 Oct to 23 Nov 2026.
- **The town needs a cast that doesn't exist yet:** three dogs, an animal-control officer, the neighbours.
- **What the author will do:** level 1 is finished and exported first, so there's always a whole game to show. Each new level starts only once the last one exports and passes its tests.

### 9. Why this project?
- **Mostly to learn.** Godot and GDScript, Blender modelling and rigging, shaders and particles, and game animation with its tests were all new to the author this term.
- **Each has its own tagged assignment,** from `a2` to `a7`.
- **Finishing the game** is how the author will find out whether they can carry them all through to the end.

---

## The pictures, and what each one is

Each picture carries a caption bar saying what it is. Please keep to it.

| Picture | What it is |
|---|---|
| 01 The title screen | **Real game:** a screenshot from 23 Oct 2026, an older build |
| 02 Waves at the edge | **Real game,** 25 Oct 2026, an older build, before the moth guide |
| 03 The heist | **Real game,** 25 Oct 2026: unzipping the backpack behind the camper's back |
| 04 Caught | **Real game,** 25 Oct 2026: a man snatches the bag back |
| 05 Their sight | **Real game,** 28 Oct 2026: the cones on the ground, red when he's spotted |
| 06 The camp at night | **Fixture capture,** 8 Nov 2026: the campfire's smoke (Assignment 6) |
| 07 The jump | **Fixture capture,** 21 Nov 2026: the top of a jump (Assignment 7) |
| 08 The jump, frame by frame | **Fixture capture,** 22 Nov 2026: the jump on his rig |
| 09 The moth's sheet | **Generated** by the author with Google Gemini: the moth's four sprite cells |
| 10 The storyboard | **Constructed:** the plan in 15 panels, drawn in code by Claude Code in Oct 2026. Panels 1–8 are built, in their own way; 9–15 aren't |
| 11 Panel 8, the red beanie | **Constructed:** the plan for level 1's end, since built differently (the cake and the chase) |
| 12 Panel 11, the dogs | **Constructed:** level 2's dogs. Not built |
| 13 Panel 14, home at last | **Constructed:** the ride home. Not built |
| 14 A dog | **Generated** reference art for level 2, not in the game |

"Fixture capture" means a recorded run of a preview scene in the game's own level, made for testing, not a player's play. There's no picture of level 1's ending yet; it will come from the author's recording.

## Who did what

- **The author:**
  - the game, its story, its design and every decision in it;
  - the target role, the comparison games and the reasons for the project;
  - the generated art (Google Gemini) and music (Suno);
  - playing it and judging how it feels.
- **Claude Code** (Anthropic's coding agent), at the author's direction:
  - much of the code, and the Blender builds through the Blender MCP;
  - the tests;
  - drafts of the documents, this one included.
- **Third-party models:** the campers are TiZeta's figures from Blend Swap, under CC BY 3.0.

## Limits

- **No export exists yet,** and the Mac build will be untested.
- **No outside player has played it.**
- **Level 1's ending and its last task were built on 23 Nov 2026.**
- **The city, the block and the ending are plans:** the storyboard and the design document.
- **One test check still fails:** `cost_effects.gd`'s smoke case, since before Assignment 7.
