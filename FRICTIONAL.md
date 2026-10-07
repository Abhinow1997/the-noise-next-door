# Frictional log: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 2

A dated log of the design as it happened: what I wanted the player to see or hear, what I asked for, what came back, and what I decided. This first part covers the storyboard, from the first draft to the check against the brief. Entries for the generated assets (Gemini images, music, sound effects) are added as their rows in the [SOURCES.md](SOURCES.md) asset log are filled in.

**How these entries were written**
- They're retrospective. On 6 Oct 2026, Claude Code put them together from my chat messages, the commits and the provenance notes in the design docs.
- My messages are quoted exactly as I typed them, typos included. Times are US Eastern, taken from the chat transcripts.
- Where I didn't give a reason at the time, the entry says so instead of supplying one.

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
- **Decided:** I kept the story and the 12 panels, and changed the middle (next entry). Why I switched from the campsite alone to the whole story wasn't written down.
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
- **Decided:** I kept all of it, and it's still in the board. My reasons for the new order weren't written down.
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
