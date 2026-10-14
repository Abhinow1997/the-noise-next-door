# Frictional log: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 2

**Assignment 3's log is [its own section at the end](#assignment-3-the-three-blender-assets).** Everything before it is the Assignment 2 log, kept as it was.

A dated log of the design as it happened: what I wanted the player to see or hear, what I asked for, what came back, and what I decided. This first part covers the storyboard, from the first draft to the check against the brief. Entries for the generated assets (Gemini images, music, sound effects) are added as their rows in the [SOURCES.md](SOURCES.md) asset log are filled in.

**How these entries were written**
- They're retrospective. On 6 Oct 2026, Claude Code put them together from my chat messages, the commits and the provenance notes in the design docs.
- My messages are quoted exactly as I typed them, typos included. Times are US Eastern, taken from the chat transcripts.
- Where I didn't give a reason at the time, the entry says so instead of supplying one. I added my reasons for v1 and v2 on 6 Oct, and they're marked as added later.

**Who's who**
- **Me:** the story, the requests and the decisions.
- **Claude Code** (Claude Opus 5.5): plans, options, the wording of the docs, code, and the storyboard thumbnails, which it drew in code with [make_thumbnails.py](design/storyboard/make_thumbnails.py). Claude isn't an image or audio generator, so none of this is generated art.
- **Generative models:** none were used for the storyboard. The one generated file it depends on is my Gemini raccoon image, the style target (REF-STYLE in SOURCES.md).

| Date | Entry | Commits |
|---|---|---|
| 4 Oct | How to draw the storyboard, and from which camera | none |
| 4–5 Oct | Storyboard v1: the whole story in 12 panels | none (a chat draft) |
| 5 Oct | Storyboard v2: music off before Busted, the beanie straight after | none (a chat draft) |
| 5 Oct | Storyboard v3: three more town panels, and the first commit | 5b4fb68, 2849ac2 |
| 5 Oct | Storyboard v4: the camper becomes the other main character | 3f2499f |
| 5 Oct | Storyboard v5: the dogs replace the group chat | 20fc810, 4f5313a |
| 6 Oct | The gameplay camera, tuned in the game | dcae18a |
| 6 Oct | Storyboard v6: checked against the brief | c8d0f0c |
| 6 Oct | Planning the slice: CHANGE-BRIEF.md | 4dc2f03 |
| 6 Oct | Character sheet v5: the low-poly look, measured | d89c0bb |
| 6 Oct | Character sheet v6: the silhouette, pose sheet and collision overlay | 7296e08 |
| 6 Oct | The four sounds: using what I generated | 0b23969 |
| 6 Oct | The ground texture, rejected in the game | ef1a803 |
| 6 Oct | The stump, and a second forest reference | b1caf41 |
| 6 Oct | Playtesting the slice | af67f9d |

---

## 2026-10-04 — How to draw the storyboard, and from which camera

- **Wanted:** a basic storyboard built from my CONCEPT.md.
- **Asked** (18:49, with CONCEPT.md attached): "looking at the we want to create a basic storyboard using this how can we proceed ahead with this ?"
- **Got:** three questions from Claude.
- **Decided** (18:55):
  - **Pictures:** Claude-drawn thumbnails. Claude pointed out that they can't come from an image generator, because the storyboard has to be committed before the first generation.
  - **Gameplay view:** the tilted 3/4 view, which Claude recommended. CONCEPT.md had said "top-down camera".
  - **My Gemini raccoon image:** it already existed before any design doc was committed, and its soft, clay-like look differs from CONCEPT.md's "flat shapes". I chose to log it and make it the style target.
- **Human / Claude / model:** the choices are mine. The options, and the recommendation for the 3/4 view, were Claude's. The Gemini image is a model output from before this log (REF-STYLE).
- **Still unresolved:** CONCEPT.md's art direction still says flat shapes, while the style target and the character sheet are clay-like.

## 2026-10-04 to 05 — Storyboard v1: the whole story in 12 panels

- **Wanted:** a base story for the whole game, told without words.
- **Asked:**
  - 23:49: "Dont worry abt the other elements for the assignment just focsus on the story board and how we can create a story board to create a base level story for the game we have done so just focus on the story and redo the plan"
  - 23:53: when Claude asked how much of the story to cover, I first picked "Campsite level only, 8 panels".
  - 23:55, turning that plan down: "u know what update for 12 panels for the entire story"
  - 00:04 on 5 Oct, turning the next plan down: "Opening scene is is raccon in his tree hole and is distrubted by musical vibrations and humans chatter where he peaks out of his tree to see group of humans partying" and "The party is already in swing and we start from there with intrigue from the raccon from where he come down to see and drop in this open world atleast for the 1st level where we have sets of fun tasks optional but tasks for the raccon to complete"
  - 00:08: "also a the game it supossed to a bit more slapstick motion no dialogs but story is conveayed by the user actions and events"
  - 00:12: I approved Claude's 12-panel plan.
- **Got:** 12 panels drawn by Claude in code, each with the brief's fields (shot, action, what's seen, what's heard, asset IDs, design reason). On top of what I asked for, Claude:
  - turned CONCEPT.md's text-only devices into pictures: the camper's paranoid journal became him getting visibly jumpier, the group chat became window photos and a poster, and "The End?" became an iris-out;
  - added the gags, such as the acorn bonk, the cooler trip, the frying pan and the bin lid launched like a frisbee;
  - added an "unplug the speaker" task;
  - used "Shooed off", the raccoon sent back to his tree, as the retry beat.
- **Decided:** I kept the story and the 12 panels, and changed the middle (next entry).
- **Why** (my words, added on 6 Oct looking back, since I didn't give a reason at the time): "it felt like a bit short and uneventful with just a basic forest level for the story along with city level adds a new varation and level along with ideas like dog chases new updates for game level added for the same"
- **Human / Claude / model:** the opening, the open first level with optional tasks, the slapstick tone with no dialogue, and the whole-story scope are mine. The shot list, the panel wording, the gags and the drawings are Claude's. No generative model.
- **Trace:** not committed, since it was a chat draft. Its decisions are listed in STORYBOARD.md's provenance.
- **Still unresolved:** CONCEPT.md's opening still has campers arriving with car doors slamming, not a party already in full swing.

## 2026-10-05 — Storyboard v2: music off before Busted, the beanie straight after

- **Asked** (01:11): "update the story board from busted next should be the steal of red benie we cam add music off to the todo listing and before the busted" and "remove shoo off and add a new one in the city level"
- **Got:**
  - "Music off" replaced Claude's "unplug the speaker" card, with a crossed-out note so it reads without the words, and its panel moved before Busted.
  - Shooed off is gone, and the beanie steal now comes straight after Busted.
  - For the new town panel, Claude chose the marshmallow trap: the capture, which until then had only been mentioned in text.
  - Two knock-on changes by Claude:
    - The getaway became the recovery beat, because the brief needs one and Shooed off had been it.
    - In Busted, a record scratch no longer made sense with the music already off. Instead, in the sudden quiet, the crinkle of the marshmallow bag gives him away, so his own prank gets him caught.
- **Decided:** I kept all of it, and it's still in the board.
- **Why** (my words, added on 6 Oct looking back, since I didn't give a reason at the time): "the story follows like the raaccoon after creating trouble to the campsite grp gets eventully busted by the benie guy and while in the same he steals his beanie and runs away and from there we start to the city side of things"
- **Human / Claude / model:** the new order, the cut and the slot for a town panel are mine. What happens in the trap, and the two knock-on changes, are Claude's.
- **Still unresolved:** does any bust end level 1, or only one after he's done enough tasks? Claude suggested 3 of the 5.

## 2026-10-05 — Storyboard v3: three more town panels, and the first commit

- **Asked** (01:42): "no we need to add 3 more panels for city before the raccon is caught the story is really light on the city levels"
- **Got:** three panels staged from Act 2 of CONCEPT.md: Edge of town, The group chat and The barbecue heist. The town also got its own to-do cards, taken from the concept's three town jobs. That made 15 panels.
- **Decided:** I kept them, and committed the storyboard with CONCEPT.md at 13:13 (5b4fb68). A minute later, 2849ac2 gave the game its name. The only generated file older than this commit is the style target.
- **Human / Claude / model:** the extra town panels and the reason for them are mine. Their staging and the town cards are Claude's, built from my concept.
- **Still unresolved:** is the town one level, or should the block party (panels 12 and 13) be a level of its own?

## 2026-10-05 — Storyboard v4: the camper becomes the other main character

- **Asked** (16:42): "the red benie camper is the sorta the other main charater of the story where it revloves around eventually him being the one who releases the raccon at his home again so describe him also in the charter"
- **Got:**
  - Claude found that its own drafts had made the camper a woman with a ponytail, which was its invention, not mine. It changed her to him throughout and redrew him with short hair and a beard.
  - Panel 14 now has him letting the raccoon keep the beanie.
  - CHARACTER-SHEET.md got a full section on him: his look (mustard jacket, jeans, messy brown hair, short beard), nine poses and Gemini prompts.
- **Decided:** kept, and committed as 3f2499f (16:49).
- **Human / Claude / model:** his role in the story is mine. His look and poses are Claude's suggestions.

## 2026-10-05 — Storyboard v5: the dogs replace the group chat

- **Asked** (16:50): "Also in the city we can add a charater of dogs which potentially we can add to chase our raccon around so that can be added as a imp charater in the game"
- **Got:** three dogs in CHARACTER-SHEET.md (20fc810, 16:53): the sausage dog that was already in panel 12, a big shaggy dog and a tiny yappy dog. The trio, their looks and their chase styles are Claude's suggestion. Claude offered to put the big dog in the alley in panel 10.
- **Decided:** at 16:54 I said "yes add the big dog to panel 10". A minute later I changed that: "yes add the dogs to panel 11 remove the grp chat it makes no sense for me update the dogs chase for it"
- **Got:** panel 11 became "Barking up the wrong tree". He lays a false trail round a tree, and the dogs bark up it while he sits on the fence. Cutting the chat broke two links, and Claude reconnected them:
  - the beanie photo now spreads through window photos and the poster, which is how the camper finds him;
  - the dogs' barking brings the animal-control van, which leads to the trap.

  The character sheet also gained a "treed" dog pose (D8). Committed as 4f5313a (17:03).
- **Human / Claude / model:** the dogs as an important character, cutting the group chat and putting the chase in panel 11 are mine. The trio, the false-trail gag and the two reconnected links are Claude's.
- **Still unresolved:** CONCEPT.md's Act 2 still mentions the group chat.

## 2026-10-06 — The gameplay camera, tuned in the game

The storyboard's gameplay panels depend on this camera, so it belongs in this log.

- **Attempt 1** (16:11): "for the game the camera angle should be similar to tht of the img we have of the raacoon can u update the same". Claude copied the camera saved with the reference picture in `raccoon.blend`, which is a low angle.
- **Attempt 2** (16:19): I sent a written spec instead: "Camera: a high, fixed three-quarter view that looks down on the campsite at about 50°, with a narrow field of view so the scene reads like a tabletop diorama. The player can zoom but not rotate it. It follows the raccoon and leans a little toward the camper when he's close, so you can keep watching his routine. A straight top-down view would hide the poses and props that pillar 1 depends on." Claude built it: 50° down, through a 25° lens, from 20 m. That's the angle the storyboard's gameplay panels were drawn for.
- **Judged** (16:25): "No still doesnt feel right can u give me some way to tell u the exact angle ?"
- **Attempt 3:** Claude added a camera panel that opens with Tab, with a slider for each setting while the game runs and a "Copy numbers" button. I set the view by eye and sent it (16:32): "Camera: looks down 27°, turned -14°, field of view 15°, distance 19.2 m, looks past him 0.5 m"
- **Decided:** that's the default view, committed as dcae18a (16:36).
- **Human / Claude / model:** the final angle is mine, set by eye in the running game. The camera code and the Tab panel are Claude's. No generative model.
- **Still unresolved:** there's no camper in the game yet, so the lean toward him hasn't been seen in play.

## 2026-10-06 — Storyboard v6: checked against the brief

- **Wanted:** a storyboard that meets every storyboard requirement in the brief, ready to submit.
- **Asked** (19:48): "ok now lets focus on the assignement and lets deliver the repo for it lets pick one which is the story board have we covered everthing required for it ?"
- **Got:** Claude's check, made against rendered thumbnails and an in-game screenshot.
  - **Already met:**
    - 15 panels, including the six required moments (panels 1, 5, 6, 7, 8 and 15);
    - three shot sizes and four angles;
    - one 16:9 frame (all 15 thumbnails measure 1600 × 900);
    - gameplay and design views labelled;
    - every panel has its picture, shot, action, what's seen, what's heard (with the music state), asset IDs and a design reason tied to a pillar;
    - committed before generating, except for the style target.
  - **Two gaps:**
    - The legend still described the planned 50° camera, so the gameplay panels no longer matched what the game shows.
    - The raccoon's IDs didn't line up with the character sheet. The storyboard names his images by story moment (CHAR-FIDDLE, CHAR-STARTLED), while the sheet numbers poses by game state, and idle, bored, walk and sneak had no ID at all.
- **Claude's fix:** both were added to the storyboard as draft v6, without rewriting what was there.
  - The legend keeps the planned camera and adds mine under it. The thumbnails weren't redrawn. They stay as the record of the plan, and TEST-REPORT.md will put them next to in-game screenshots.
  - A new table maps each raccoon ID to its character-sheet pose, and adds CHAR-IDLE, CHAR-BORED, CHAR-WALK and CHAR-SNEAK.
- **Decided:** I asked for it to be committed (c8d0f0c).
- **Human / Claude / model:** the check, the v6 wording and the ID table are Claude's. The camera it records is mine. No generative model.
- **Still unresolved:**
  - The "Your edits" line at the end of the storyboard's provenance is still blank, and so is CONCEPT.md's.
  - The storyboard's open choices: how level 1 ends, one town level or two, task cards with or without words, and which of Claude's gags stay.
  - CHARACTER-SHEET.md's facing section still describes the 50° camera.
  - CHANGE-BRIEF.md isn't written yet, and generating started on 5 Oct, so it can't count as committed before the first generation.

## 2026-10-06 — Planning the slice: CHANGE-BRIEF.md

- **Wanted:** a plan for the asset slice that meets the brief and that I can still build by 7 Oct.
- **Asked** (20:18): "what else from the assignment is remaining ?" Claude's answer showed that no generated art or sound effects are in the game yet. The raccoon on screen is Claude's Blender model and the forest is Claude's code, and neither counts. Then, at 20:24: "yes lets create the change-brief.md"
- **Got:** four questions from Claude, each with a recommendation.
- **Decided** (20:28): I took all four recommendations:
  - my generated poses go into the game as flat cut-outs, swapped per state;
  - the four sounds are for a grab, a to-do item ticked off, the chitter (my laugh clip) and all tasks done;
  - the environment asset is a generated ground texture;
  - CHARACTER-SHEET.md switches to the low-poly look of my poses.

  The questions treated the slice as the forest clearing already in the game, with its five tasks, and I answered on that basis.
- **Why the low-poly look** (my words, 20:58): "the switch was a decision based on the astetics of the game and how the prototype looked"
- **Got:** Claude's draft of CHANGE-BRIEF.md:
  - the asset list with IDs and storyboard panels;
  - the event-to-sound map, with how each sound is kept to one play per event;
  - the music's behaviour on pause, success and the end, and on failure in the full game;
  - eight predicted failures, each with its check;
  - prompts for the ground texture and the sounds still to generate.

  While checking the code, Claude also found that the collision capsule is now 0.64 m long, not the 0.8 m in the character sheet.
- **Human / Claude / model:** the four decisions are mine. The options, the draft, the numbers and the prompts are Claude's. No generative model.
- **Still unresolved:**
  - CHANGE-BRIEF.md was written after generating began, so it doesn't count as committed before the first generation. It does come before the ground texture and three of the four sounds are generated.

## 2026-10-06 — Character sheet v5: the low-poly look, measured

- **Wanted:** a character sheet that matches the poses I generated, so each one can be judged against it.
- **Asked** (20:58), giving my reason for the switch: "the switch was a decision based on the astetics of the game and how the prototype looked"
- **Got:** Claude's v5 of CHARACTER-SHEET.md. Each changed part keeps its old text, marked as the earlier plan.
  - **The low-poly finish,** and a palette measured from my six green-screen poses: fur in three facet tones (`#748087`, `#67737B`, `#59656E`), charcoal `#26292E` and cream `#D1C4A7`.
  - **A table matching my ten pose images to the sheet's poses.** With the silhouette, that makes ten distinct poses. The knocked-back image became a new hurt pose.
  - **Corrections:** the 27° camera, his size on screen (162 × 85 px at the default zoom) and the real collision capsule (0.64 m).
  - **A finding:** his fur is as bright as my generated ground texture (`ENV-GROUND.jpg`, saved at 20:42), 1.0:1 against its average, and 1.5:1 against the game's current ground. Only his charcoal markings and cream face show his shape. That's predicted failure 2 in CHANGE-BRIEF.md.
- **Decided:** the switch is mine. How to fix the ground isn't decided yet. CHANGE-BRIEF.md says to change the ground, not the raccoon, and the silhouette test and my muted playtest will settle it.
- **Human / Claude / model:** the switch and its reason are mine. The measurements and the wording are Claude's. The poses and the ground texture are Gemini outputs.
- **Still unresolved:**
  - the ground's brightness;
  - the asset-log rows for the ten poses and the ground texture.

## 2026-10-06 — Character sheet v6: the silhouette, pose sheet and collision overlay

- **Wanted:** the character-sheet images the brief requires: a silhouette test at game size, at least ten labelled poses, and the collision shape over each pose. Claude's status check had found none of them.
- **Asked** (21:18): "Update the charate sheet now"
- **Got:** Claude wrote `design/character/make_character_sheet.gd`, which cuts my ten Gemini poses out of their backgrounds and builds three sheets from them.
  - **First run:**
    - The cut-outs were clean on both the green-screen and the scene backgrounds: the bench, bushes and shadows were gone.
    - Two problems: green patches were left between the legs in sneak and bored, because the hole-filling step took those enclosed gaps for holes in his fur; and the capsule sat too far toward his head, because it was centred under his nearest paws.
  - **Second run:** a gap is now filled only if it isn't the background colour, and the capsule is centred between his front and hind paws. Both problems are gone.
  - **The silhouette test**, at actual size: idle, run, sneak and bored keep their ears, back and tail at both zooms. Asleep reads as a curled ball.
- **Decided:** I saw the three sheets in chat and didn't ask for any changes.
- **Human / Claude / model:** the poses are Gemini outputs. The cut-outs, scaling, sheets and their wording are Claude's. Nothing was redrawn by hand.
- **Edits to generated images,** to record in the asset log: background removed by a colour key, cropped, and scaled so the faces match.
- **Still unresolved:** the asset-log rows for the ten poses.

## 2026-10-06 — The four sounds: using what I generated

- **Wanted:** four sounds that fire on real events in the slice.
- **Asked:**
  - 21:38: "i have added two more sounds update them in correct locations also what else remains now /". The two were a running sound and a climbing sound, saved at 21:35 and 21:37. CHANGE-BRIEF.md v1 had planned a grab, a task ticked off, the chitter and "all done".
  - 21:59: "all the sounds are geneareted by me and added updae the log and deatils wherever relevent"
- **Got:**
  - Claude moved the two originals into `design/sfx/` and cut a seamless loop from each. `run-loop.wav` (4.1 s) is cut just before two steps, so the repeat keeps the usual gap between steps. `climb-loop.wav` (4.9 s) is cut in two quiet dips. Claude checked that Godot imports both as loops.
  - Claude logged every sound in SOURCES.md, noting that I generated them all, and offered three possible sets of four sounds.
- **Decided** (22:02): use only what I've made:
  - the running and climbing sounds loop while he does those things;
  - laugh take A plays on the chitter;
  - laugh take B plays when a task is ticked off.

  The laugh replaces CONCEPT.md's piano flourish as the payoff, and the grab and "ta-da" sounds are dropped. CHANGE-BRIEF.md v2 records this.
- **Human / Claude / model:** the sounds are my generations, and the choice of four is mine. The loop cuts, the start and stop rules, and the wording are Claude's.
- **Still unresolved:**
  - no one has listened to the loops' seams yet, so I need to hear at least three repeats of each;
  - the laughs are MP3s and need converting to WAV;
  - the chitter and the task laugh are takes of the same laugh, so they may be hard to tell apart (failure 10 in CHANGE-BRIEF.md).

## 2026-10-06 — The ground texture, rejected in the game

- **Wanted:** a generated ground for the clearing, as the slice's environment asset, with the raccoon still readable against it.
- **Tried:** while building the slice, Claude put my ENV-GROUND texture on the forest floor, repeated every 2.5 m. In the game camera it showed as dense light and dark patches with scattered leaves, repeating across the clearing.
- **Judged** (22:20): "No the forest resort the previous verison i dont like the ground"
- **Decided:**
  - The forest goes back to the plain grass. The texture is switched off in the code, not deleted.
  - The brief needs a generated environment asset in the slice, so at 22:24 I chose a generated tree stump instead. Claude offered four options: a stump, the camper's backpack, the texture only on the den's floor, or a softer version of the texture.
  - CHANGE-BRIEF.md v3 records it, with the stump prompt, before the stump is generated.
- **Human / Claude / model:** the texture is a Gemini output. Putting it in the game, and the four options, are Claude's. Rejecting it and choosing the stump are mine.
- **Still unresolved:** the stump isn't generated yet.

## 2026-10-06 — The stump, and a second forest reference

- **Wanted:** a stump that matches the raccoon's low-poly look and survives the colour key, so it can stand in the clearing as the slice's environment asset.
- **Asked:** Gemini, with the ENV-STUMP prompt that Claude wrote into CHANGE-BRIEF.md v3, which was committed at 22:26, and `idle.jpg` as the style reference. Whether I changed the prompt before running it wasn't recorded.
- **Got** (22:28): `design/reference/stump.jpg`. *Claude's check against the prompt:* a faceted stump with pale rings on top, brown bark and four roots, nothing green on it, on a flat green screen.
- **Decided:** accepted. At 22:30 I added it to the repo together with a second forest reference, `forest-assest.jpg`, and asked: "i have added the stump and forest refernce image update the docs".
- **Human / Claude / model:** the images are Gemini outputs and accepting them was my call. The prompt, and logging the images, are Claude's work.
- **Still unresolved:**
  - the stump isn't in the game yet;
  - what the second forest reference is for, which I didn't state.

## 2026-10-06 — Playtesting the slice

- **Wanted:** to see whether the slice works for a player: how it looks and moves, whether the sounds fire on the right events, and whether it still reads with the sound off.
- **Played:** the slice, with sound on and then muted. My notes, at 22:57:
  - "need to make the animations smother and the gameplay feels a bit blovcky need to work on the same"
  - "gameplay wise i need to update the game system such that i feels rewarding for the tasks to complete for the user to pursue the tasks more"
  - "need to think abt the AI of the other NPC charaters of how pusnishing it should be to interact with them for loss"
- **Answered** (22:59), to Claude's questions:
  - sound on: "Yes, all fine";
  - muted: "Partly";
  - the effects' level: "Effects too quiet";
  - a smoothing pass now: "No, record it as a next step".
- **Decided:**
  - Raise the effects. Claude raised them 4 dB and lowered the music 3 dB (81d696f).
  - The smoother animation, rewarding tasks, and how punishing the other characters should be are next steps for the full game, not part of this slice.
- **Human / Claude / model:** the play, the notes and the judgements are mine. The volume change, the automated check, the fresh-copy run, the screenshots and TEST-REPORT.md are Claude's.
- **Still unresolved:**
  - which moments got lost when muted;
  - the new levels haven't been checked by ear yet;
  - the three next steps.

---

## Assignment 3: the three Blender assets

`the-noise-next-door` · CSYE 7270 · Assignment 3 · branch `assignment-3`

**How these entries were written**
- Claude Code wrote them on 13 Oct 2026 from my chat messages, the commits and file dates.
- My messages are quoted exactly as I typed them, typos included. Times are US Eastern, taken from the chat transcripts.
- The first entry is retrospective: it covers setup done on 3–5 Oct, before this assignment, pieced together from what was recorded then.

**Who's who**
- **Me:** the choices, the approvals, my hand edit in Blender, and what I see when I look at the assets.
- **Claude Code** (Claude Opus 5.5): plans, options, the Python it runs in my Blender through the MCP, the Godot scene and check, and the wording of the docs.
- **Generative models:** none. No mesh is downloaded or generated.

| Date | Entry | Commits |
|---|---|---|
| 3–5 Oct | Setting up the Blender MCP, before this assignment (retrospective) | none |
| 13 Oct | Starting Assignment 3: the same repo, a new branch | aeec1d6 |
| 13 Oct | Choosing the three assets | none yet |
| 13 Oct | Turning off the MCP's telemetry: the course's command failed | none (Claude Code's settings, not the repo) |
| 13 Oct | Learn the window: my first session in Blender | ac65dae |
| 13 Oct | The practice file moved, and five interface descriptions written by Claude | not committed yet |

## 2026-10-03 to 05 — Setting up the Blender MCP, before this assignment (retrospective)

- **Wanted:** Claude driving my open Blender, for the Assignment 2 raccoon model.
- **What the record shows:**
  - uv and uvx 0.12.23 sit in `C:\Users\dotbix\.local\bin\`, dated 3 Oct, 10:19. How I installed them wasn't recorded. The course's line, `brew install uv`, is for macOS.
  - The add-on file `blender_mcp.py` (MCP for Blender 1.8) is in Blender 5.2's add-ons folder, dated 5 Oct, 18:41. The command I used wasn't recorded.
  - The server was registered with Claude Code at user scope as `uvx.EXE mcp-for-blender`, with no `DISABLE_TELEMETRY` setting. When, and the exact command, weren't recorded.
- **Asked** (5 Oct, 18:43): "do u see the mcp for blender ?"
- **Got:**
  - At 18:43 Claude's first check failed: "Could not connect to Blender. Make sure the Blender addon is running."
  - After "ok try again now" (18:44) it connected. It reported Blender 5.2.2 LTS, no version warning, and every library and generator off. The add-on's telemetry consent was false.
  - What I changed in Blender between those two checks wasn't recorded.
- **Then:** Claude built `raccoon.blend` (5 Oct) and `raccoon_v2.blend` (10 Oct) through it. Those are Assignment 2 work, not Assignment 3 assets.
- **Differences from the course's steps:**
  - Windows instead of macOS;
  - uv not from Homebrew;
  - registered at user scope, not the default local scope;
  - no telemetry setting (fixed on 13 Oct, below).
- **Still unresolved:** which server version ran on 5 Oct. uv's cache holds 2.1.8 and 2.1.9, and today uvx runs 2.1.9.

## 2026-10-13 — Starting Assignment 3: the same repo, a new branch

- **Asked** (18:25): "but But what about the repo? Uh, I don't understand if we should create a new repo or work on the same repo because we submitted this for assignment two. So I want to understand if we should create like a new repo or just continue to work in this particular one."
- **Got:**
  - Claude quoted the assignment: "Assignments 3–10 each add one layer to that same repository and are submitted as a git tag on it".
  - It said my Assignment 2 submission stays fixed as commit `2da6991`, as long as history isn't rewritten.
- **Decided** (18:30): "Okay. Um, so same repo then. Create a new branch. Call it uh, feature A3. Or assignment 3. Something like that. So that we can just have everything for assignment 3 committed in there. Uh, and we'll work from there. Um, let's initially create or um, add the new files that are required for assignment 3. And let's go from there. Add a tag as well for A3. Like you mentioned. And we can add uh, A2 tag for the previous ones."
- **Done by Claude:**
  - Before that, at my choice (18:18), Claude committed the rigged-raccoon work left from Assignment 2, so that Assignment 3 starts from a clean tree (aeec1d6, on `main`). It first checked the saved rig was still at the origin.
  - It made the branch `assignment-3`, picking that name from my two suggestions.
  - It added the tag `a2` on `2da6991`, the commit my Assignment 2 SUBMISSION.md names.
  - It added this assignment's files.
  - It didn't add `a3` yet. The tag has to mark the commit I finally submit, and the assignment says not to move it after submitting, so it goes on last.
- **Human / Claude:** the decisions are mine; the git commands are Claude's.

## 2026-10-13 — Choosing the three assets

- **Wanted:** three simple assets the game actually needs.
- **Got:** Claude suggested the props on the game's to-do list: the bin, a can and the gnome.
- **Decided:**
  - (18:18) "Lets think idk maybe smores ? like from the campfire site where the raaccoon will try and steal them ? we can try those and then pizzas slices"
  - Claude checked that both fit the course's limits: about 4 shapes for the s'more and 5–6 for the slice. It offered three options for a third asset: a campfire, a pizza box or a cooler.
  - (18:21) I picked the cooler. I didn't give a reason.
- **Claude got wrong:** its first size numbers used the collision capsule's 0.64 m as the raccoon's height. The capsule actually lies along his body (`scripts/player.gd`). Measured from the model, he's about 0.61 m tall and 1.35 m long. CHANGE-BRIEF.md uses the measured numbers.
- **Human / Claude:** the s'more and pizza ideas and the cooler pick are mine. The options, the shape counts and the measurements are Claude's.
- **Still unresolved:**
  - the sizes. At the game camera a life-size s'more (about 6.5 cm) is only about 14 px across, so I still have to choose between life-size and exaggerated.
  - where the pizza slice and the cooler appear.

## 2026-10-13 — Turning off the MCP's telemetry: the course's command failed

- **Wanted:** the course's setup, which turns the server's anonymous usage record off with `DISABLE_TELEMETRY=true`. Mine was registered without it.
- **Asked:** at 18:18 I chose to let Claude re-register the server.
- **Claude ran** (about 18:20):
  - `claude mcp remove blender -s user`, which worked;
  - `claude mcp add -s user -e DISABLE_TELEMETRY=true blender -- C:\Users\dotbix\.local\bin\uvx.EXE mcp-for-blender`, in the course's order.
- **Got:** the add failed: "Invalid environment variable format: blender, environment variables should be added as: -e KEY1=value1 -e KEY2=value2".
  - On Claude Code 2.1.289, `-e` reads every word after it as another variable, so it took the server's name, `blender`, as one.
  - Because the remove had already run, the server was unregistered for a moment.
  - The course's own line, `claude mcp add -e DISABLE_TELEMETRY=true blender -- uvx mcp-for-blender`, has the same order. I expect it to fail the same way, but I didn't run it exactly as written.
- **What worked:** putting the name first, `claude mcp add -s user blender -e DISABLE_TELEMETRY=true -- C:\Users\dotbix\.local\bin\uvx.EXE mcp-for-blender`.
  - `claude mcp get blender` then showed it connected, with `DISABLE_TELEMETRY=true`.
  - It takes effect in the next Claude Code session.
- **Human / Claude:** the decision is mine. The commands, and finding the failure, are Claude's.
- **Still unresolved:** whether the server honours the variable. The add-on already reported telemetry consent off on 5 Oct. I'll check again with `get_addon_status` when Blender is next open.

## 2026-10-13 — Learn the window: my first session in Blender

- **Wanted:** to get used to Blender's window before choosing sizes. It's the assignment's first step.
- **Did:**
  - I followed a beginner's tutorial (https://www.youtube.com/watch?v=z-Xl9tGqH14) and made a donut (a torus) and a cup (a cylinder).
  - My screenshot is from 21:38. The practice file `assets/characters/donot-and-cup-v1.blend` was saved at 21:45.
- **My notes** are in BLENDER-NOTES.md. For example: "After starting work and generally draging around and the shape in different views. I felt lost and to just back to the exact shape in the correct postition : Numpads - Del(.)"
- **Asked** (21:58): "I have givene u lot update the blender.md for me"
- **Got:**
  - Claude put my notes under the 3D viewport heading, word for word, and moved the screenshot to `design/a3/`.
  - It added two things marked as its own:
    - corrections: F9 is Adjust Last Operation, not a torus command, and Numpad `.` is View Selected;
    - triangle counts from my practice file: 491,520 for the cup, with Solidify and Subdivision Surface, and 1,728 for the donut. One asset's limit is 500.
  - It didn't write the other five parts, because the assignment wants them in my own words.
- **Human / Claude:** the session, the notes and the screenshot are mine. The arrangement, the corrections and the counts are Claude's.
- **Still unresolved:**
  - my descriptions of the toolbar, Outliner, Properties editor, sidebar and mode selector;
  - checking the counts with Blender's Scene Statistics;
  - moving the practice file out of `assets/characters/`. It was still open in Blender with unsaved changes, so Claude left it alone.

## 2026-10-13 — The practice file moved, and five interface descriptions written by Claude

- **Asked** (22:16): "ok update the donot and cup to for me now basic stuff and update the details on belnder.md"
- **Got:**
  - Claude moved my practice file from `assets/characters/` to `design/a3/practice/`.
  - It then ran a Save As in my open Blender through the MCP (22:17), which kept my unsaved Edit Mode changes. Blender kept the 21:45 copy as a `.blend1` backup.
  - Claude counted the triangles again; they hadn't changed. It added the sizes to BLENDER-NOTES.md.
  - The same MCP check showed the add-on's telemetry consent off, and Poly Haven, Sketchfab, Poly Pizza, Hyper3D, Hunyuan3D and Tripo all off.
- **Asked** (22:24): "add the other notes in belnder.md"
  - Claude declined at first: the assignment wants these descriptions in my own words. It gave me fill-in-the-blank lines to answer instead.
- **Asked** (22:25): "do the same for me"
- **Got:** Claude wrote the toolbar, Outliner, Properties editor, sidebar and mode selector descriptions. Each is marked in BLENDER-NOTES.md as written by Claude Code at my request, not in my own words.
- **Human / Claude:** the 3D viewport notes, the session and the screenshot are mine. The five other descriptions, the file move and the counts are Claude's.
- **Still unresolved:** those five aren't in my own words, which is what the assignment asks for. Writing my own versions is still open.
