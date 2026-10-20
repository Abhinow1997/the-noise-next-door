# GDD change log: The Noise Next Door

The version history of [GDD.md](GDD.md). Every change to the GDD gets an entry here, newest first.

**Current version: 1.0** (19 Oct 2026), the version I'm submitting. Not committed yet.

## How versions work

- **0.x** is a draft, while we fill in the sections. **1.0** is the version I submit.
- **Minor (0.1 → 0.2):** a new section, or a change to a design decision.
- **Patch (0.2 → 0.2.1):** wording, fixes or layout only. No design changes.
- The version line at the top of GDD.md always matches the newest entry here. Both are changed in the same edit.
- Each entry records:
  - the date and time (US Eastern);
  - the sections that changed and what changed;
  - the decisions behind it and whose they were, quoting my words where I gave them;
  - who made the edit;
  - the commit, once there is one.

## Still open after 1.0

Every section the brief asks for is now in the GDD. These are the known gaps to settle in later versions:

- 6 Story still calls level 1's tasks "optional pranks", but 7.4 says the tasks unlock the next stage.
- 7.4, level 1: are all six campsite tasks required? In the storyboard the bust comes right after "music off"; is that still the order?
- 7.4, level 2: whether any city task other than "Shake off the dogs" is required.
- 7.4, level 3: the block's tasks (Claude sent ideas), and whether the marshmallow trail ends the level.
- 7.1 Goal: what drives him on the block; an example of a task that updates (a rough idea for now).
- 7.3: more detail on his abilities (the brief asks this section to elaborate on the mechanics), e.g. how running and sneaking affect noise.
- 7.5: where he ends up after being shooed away.
- 8: the style and mood in my own words; there are no reference images for the city or the block yet.
- What I'm taking from each inspiration.

---

## 1.0 — 19 Oct 2026, about 20:15 · the version I'm submitting

- **Added (drafted by Claude Code at my request):**
  - **4 Game elements and assets:** characters, props for each level, environments and UI, each marked Made, In progress or Planned, with a picture of the 3D assets made so far.
  - **10 Technical description:** the platform and engine, how the game is built, the systems still to build, and the tools.
- **Changed:** **9,** the lullaby is now in the prototype as the nap music ([assets/audio/music/lullaby-loop.wav](assets/audio/music/lullaby-loop.wav), added at 19:20). This was the audio I'd said I'd added; it hadn't been made yet when Claude checked for 0.11.
- **Decisions (mine):**
  - "Subitting the current version now"
  - After Claude pointed out that sections 4 and 10 were missing, I asked "what are section 4 and 10 ?", then "do that for me".
- **Edited by:** Claude Code. Sections 4 and 10 are its wording, drawn from the repo's files, scripts and project settings, and from this GDD's plans. I didn't answer questions for them.
- **Commit:** not committed.

---

## 0.11 — 19 Oct 2026, about 18:35

- **Added:**
  - **7.6 Player skills.**
  - **8 Graphics and styling:** the look, the camera, and pictures of the raccoon, the world, the NPCs, the prototype and the storyboard.
  - **9 Music and sound effects:** tables of the music and the sound effects, and how the prototype plays them.
  - Two new screenshots of the current prototype, design/gdd/game-start.png and game-den.png.
- **Changed:** **7.5,** nothing reloads; only the failed task resets.
- **Decisions (mine, about 18:30):**
  - Restarting: "update this it doesnt reload but the puzzle or the task the usr fails on will be reset"
  - Player skills: "puzzle solving ablity and understanding the environment assest on how to interact with them"
  - Graphics: "we have the reference imgs and the prototyping game"
  - Sound: "I have added more will be updated as the development goes on and the stages progresses it will be developed"
- **Edited by:** Claude Code. It chose the pictures, took the two screenshots with the game's `--screenshot` mode (the den one with `--rest-test`), and wrote the captions and tables. The track and sound details come from SOURCES.md, and the low-poly look and the camera from my earlier decisions.
- **Commit:** not committed.

## 0.10 — 19 Oct 2026, 18:17

- **Changed:** **7.1 Goal,** the city line. It was "he wants two things: food first, and underneath it all, to get home". It's now "first survival,food second,curiosity third and underneath it all, to get home".
- **Why:** my own edit, made directly in GDD.md.
- **Edited by:** me. At 18:19 Claude Code logged it here, bumped the version line, and added a provenance line. My text is left as I typed it.
- **Commit:** not committed.

## 0.9 — 19 Oct 2026, about 17:51

- **Added:**
  - **7.3 Abilities and power-ups:** no power-ups.
  - **7.5:** what getting caught costs him.
- **Changed:** **7.4,** "Shake off the dogs" is now the required city task.
- **Decisions (mine, about 17:50):**
  - Costs: "yes thts how it works the puzzle resest or u the tasks needs to be redone". This was my answer to Claude's two questions, which asked whether the humans take back what he's carrying and whether a half-done job resets.
  - Power-ups: "no power ups". That answered a question that also asked whether the red beanie does anything, so 7.3 says it's part of the story, not a power-up.
  - The required city task: "yes tht makes sense", agreeing with Claude's suggestion of "Shake off the dogs".
- **Edited by:** Claude Code, from my words, tidied.
- **Commit:** not committed.

## 0.8 — 19 Oct 2026, about 17:50

- **Added:** **7.5 Losing or restarting.**
- **Changed:** **7.2,** the search stage now says what happens if they find him.
- **Decision (mine, about 17:45):** "there is no losing or energy like mechanics the npcs just try and sho you away and the dogs sorta chase u away"
- **Edited by:** Claude Code, from my words, tidied.
- **Commit:** not committed.

## 0.7 — 19 Oct 2026, about 17:10

- **Added:**
  - **7.4:** level 1's six tasks and level 2's five tasks, in tables, and how each level hands over to the next.
  - **7.2:** the neighbours' photos.
  - **7.1:** what he wants in the city.
- **Changed:** in **3 Game flow** and **7.4**, the chase and the highway are now a cutscene, and control comes back in the suburbs. The line "The player walks on to the next area" was removed.
- **Decisions (mine, about 17:00–17:08):**
  - The city tasks: of Claude's six ideas, I removed "Find a bed for the night" ("no remove this"). The other five stay: "other things look good for now we go ahead with them". Taken with them were Claude's other two ideas: the dogs' barking as the trigger for the block, and the neighbours' photos.
  - Picked from Claude's options:
    - some city tasks are required and the rest optional ("Some required");
    - in the city he wants food and home ("Both");
    - the highway is a "Cutscene";
    - level 1 is "Storyboard + cooler".
- **Edited by:** Claude Code. The task descriptions are its wording, from its own ideas, the storyboard and CONCEPT.md.
- **Commit:** not committed.

## 0.6 — 19 Oct 2026, about 16:45

- **Changed:**
  - **3 Game flow,** steps 4 and 5: the chase now runs through the forest and past a busy highway, which is the point of no return, and he arrives lost in the suburbs.
  - **6 Story,** levels 1 and 2, the same way.
  - **7.4 Levels and challenges:** the same, plus the city row now starts in the suburbs.
- **Decision (mine, about 16:40):** "like the stage 1 campsite completes with the fed up people who go after him and with benie raccoon runs thrugh the forest franticatlly into the city passing a busy highway goin past it now no goin back and we can trigger city stage where he is lost and now the subrab or start of the city campsite closes behind him only stright ahead to go in the city now this is where we need to think abt tasks and game here"
- **Not decided yet:** the city's tasks. Claude sent task ideas in chat; nothing goes in the GDD until I choose.
- **Edited by:** Claude Code, from my words, tidied.
- **Commit:** not committed.

## 0.5 — 19 Oct 2026, about 16:30

- **Added:**
  - **3 Game flow:** a title screen and main menu as step 1, and a Saving note (save states, no stage select).
  - **7.2 Game mechanics:** keys for holding to interact (hold E) and for dragging (hold E on something heavy, then walk), plus a line that E is the one action key.
- **Changed:**
  - **3 Game flow, step 4,** and **7.4:** the partiers' chase is now named as the NPC change that opens the way to the city.
  - **7.1 Goal:** notes that tasks which update are a rough idea for now.
- **Decisions (mine, about 16:25):**
  - Menus and saving: "yes there would be a menu and a title screen. Save states will be there and no user cannot select stage"
  - Keys: "no dont wanna complicate the game with many actions just E for the action". Holding E for slow jobs and for dragging was Claude's suggested way to do it.
  - The chase: "yes thts correct", confirming Claude's reading that finishing the campsite tasks gets the partiers fed up and their chase opens the city.
  - Tasks that update: "Cant think of one honestly thats a rough idea of something to implement"
  - The city and the block: "Need to think on this more give me senarios of what we can do". Claude sent scenarios in chat; nothing goes in the GDD until I choose.
- **Edited by:** Claude Code, from my answers.
- **Commit:** not committed.

## 0.4 — 19 Oct 2026, about 16:00

- **Added:**
  - **3 Game flow:** the six steps from the intro to the ending.
  - **7.1 Goal.**
  - **7.2 Game mechanics:** a table of the player's actions and keys, and how the NPCs notice him.
  - **7.4 Levels and challenges:** how a level ends and unlocks the next, and which areas stay open.
- **Decisions (mine, about 15:50–15:57):**
  - Holding to interact and dragging, from the storyboard: "Yeah tht would be added in along with dragging things would be added not the freezing in place"
  - The goal: "there will be a set of tasks in the world to progress ahead into the game for user in each stage they would be defined or how he interacts with the world these would be updated in the game"
  - How a level ends: "completion of the defined tasks in the level would sorta of unlock the world to the next stage along with the changing of the damnaics with the npcs in the stages triggereing the chnage"
  - The prototype's actions: I kept all four groups Claude listed (run and sneak, climbing, grab, carry and drop, chitter and nap).
  - Getting noticed: "its a combination of coming in sight of npcs and noise and triggering a search stage"
  - Travel between areas: on foot, picked from Claude's options.
  - Going back: "campsite closes cthe city would remain open"
  - On the process: "keep askin me whats missing". The Still open list above is what's missing.
- **Edited by:** Claude Code. It tidied my answers and placed them in the sections above. It assembled 3 Game flow from them and from 6 Story, and filled in 7.2's controls from the prototype's current keys.
- **Commit:** not committed.

## 0.3 — 19 Oct 2026, about 15:15

- **Added:**
  - **1 Name:** the tagline.
  - **2 Concept:** Inspirations and Target player rows. The World row now says the areas are connected into one world, but not all of it is open at once.
  - **5 Main character:** the raccoon's name (none) and his personality.
  - **7 Gameplay:** started, with **7.4 Levels and challenges**: the three levels and what each is for.
- **Changed:** 6 Story now names levels 2 and 3 "the city" and "the block", after my answer, with the storyboard places in brackets.
- **Decisions (mine, from my answers at about 15:05):**
  - Name: "No name its just a raccoon"
  - Personality: "is defined well from the charater-sheet and it aligns well no cganges can be - borrowed from the same". It's taken from CHARACTER-SHEET.md's "Who he is". The line "scared and curious at the same time" is added from my level 1 answer.
  - Tagline: "Tagline as well", so it's the README's line.
  - Inspirations: "Overcooked,Stray,Cuphead and untitled goose game"
  - Target player: "Casual PC gamers"
  - Levels: "the current draft of the game I have 3 levels". On the city: "The city is sort of divided into two sections. What would be the the city, and then one would be like a block." On the world: "I imagine all of this world to be interconnected, while not completely accessible throughout the world, but connected through the game."
- **Edited by:** Claude Code. It tidied my answers and placed them in the sections above. My level answer described how the levels build on each other rather than the theme, so it went into 7.4 instead of 6 Story.
- **Commit:** not committed.

## 0.2.1 — 19 Oct 2026, about 14:10

- **Changed:** the version line at the top of GDD.md. It was "Draft v1, 18 Oct 2026"; it's now "Version 0.2.1" with a link to this log.
- **Design changes:** none.
- **Why:** I asked for it (14:08): "create a versioning and update log for the GDD as well a seprate file". The 0.x numbering is Claude's proposal.
- **Edited by:** Claude Code, at my request. This log was also created in this change.
- **Commit:** not committed.

## 0.2 — 18 Oct 2026, 12:34

- **Added:**
  - **5 Main character:** the raccoon (his look, his home in the pine, the red beanie), plus an NPC table: the camper (main NPC), the partiers, the neighbours, the three town dogs and the animal-control officer.
  - **6 Story:** the storyboard v6 story, split into three levels (the campsite party, the back alley, the block party), plus the opening, the ending and the epilogue.
  - **Provenance:** my choices, and what Claude condensed from earlier docs.
- **Decisions (mine, about 12:30–12:34):**
  - The story follows storyboard v6. I picked it from Claude's options.
  - The town is two levels. I picked it from Claude's options; it was Claude's recommendation.
  - The main character, in my words: "The camper is not a main charater he is NPC only the raccoon is the main charater all others are NPCs the camper is one of the main NPCs"
  - The camper's look, in my words: "I am still trying to get the look right woking on the belnder to make the camper"
- **Edited by:** Claude Code. It condensed the story summary from STORYBOARD.md v6 and the NPC table from CHARACTER-SHEET.md.
- **Commit:** not committed.

## 0.1 — 18 Oct 2026, 12:30

- **Created:** GDD.md, with:
  - **1 Name:** the game's existing title. My answer on keeping it and adding a tagline is still open.
  - **2 Concept:** what the game is, the theme, and an at-a-glance table;
  - **Provenance.**
- **Decisions:**
  - Before this version, picked from Claude's options: the GDD is for The Noise Next Door; we work by Claude asking and me answering; it's GDD.md in the repo.
  - From my answers at 12:26 and 12:29:
    - the theme, "even tho they don't have a bad intention but just their existence affects the wild life around them";
    - the genre, "I would best describe it as slapstick comedy puzzle game";
    - the platform: PC, keyboard now, "keyboard as well as the controller on PC" later.
- **Edited by:** Claude Code, from my answers, with spelling and grammar tidied and the meaning unchanged. The layout and the at-a-glance table are Claude's.
- **Commit:** not committed.
