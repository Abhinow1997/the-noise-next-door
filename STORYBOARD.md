# Storyboard: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 2 · Draft v6, 6 Oct 2026 · first committed as draft v3 on 5 Oct 2026 (see [Provenance](#provenance))

The whole story in 15 panels: from the night a party wakes the raccoon to the night it all starts again. There's no dialogue. Every beat comes across through what the player does and what happens next, with big, slapstick, non-verbal reactions.

![All 15 panels](design/storyboard/storyboard-sheet.svg)

## The story in brief

- **Opening (panels 1–2).** Bass from a party vibrates through the raccoon's tree and bounces him awake. He peeks out: a party is in full swing right under his tree, and the grill smells amazing.
- **Level 1: the party (panels 3–8).** Curious, he slides down into the open campsite, and a to-do list of optional pranks appears.
  - He can do the pranks in any order. One of them is music off.
  - Cutting the music works, but in the quiet that follows the party can hear him, and the camper catches him with the marshmallows.
  - He bolts. The fed-up partiers chase him out of the forest, and he swipes the red beanie off the camper's head on the way.
- **The town (panels 9–13).**
  - He comes out of the forest at the edge of town. It's even louder than the party, but there are trash bags everywhere.
  - He raids the diner's dumpster and its raccoon-proof bins, and the neighbours start snapping photos of the masked bandit in the beanie.
  - The neighbourhood dogs chase him. He fools them with a false trail and leaves them barking up the wrong tree, but all the barking brings animal control.
  - His biggest heist is the block party barbecue. But animal control has been watching, and a trail of marshmallows finally catches him.
- **Ending (panels 14–15).**
  - The beanie camper recognises his own beanie in the photos going round. He's the only one who knows where the raccoon lives, so he drives him home and lets him keep the beanie. It's quiet at last.
  - Then a new party starts below.

## How the storyboard tells it

- **Slapstick, cause then effect.** Every beat is a physical gag: tiptoes, freezes, double-takes, trips and chain reactions. Nobody gets hurt.
  - Some causes carry across panels. Cutting the music in panel 6 is what lets the party hear him in panel 7. The dogs' barking in panel 11 brings the animal-control van, and the officer seen waiting in panel 12 springs the trap in panel 13.
- **No dialogue, no speech bubbles.** The humans grumble, gasp, yelp and laugh, and their reactions are big enough to read from the game camera.
- **Text-based ideas from CONCEPT.md became visual events:**
  - The camper's paranoid journal: he gets visibly jumpier instead, with his phone light out in panel 7 and a frying pan in panel 8.
  - His fame in town: neighbours snapping photos from their windows, and a poster with only his picture (panels 10, 11 and 13). These replace CONCEPT.md's group chat, which you cut from the storyboard.
  - "The End?": a cartoon iris-out.
- **The only words on screen** are the to-do list's short labels in panel 4. Every card also has a doodle that works without them, and the in-game cards show only the doodles.

## Continuity

- **The red beanie** is the story's thread, and red is used for nothing else.
  - The camper wears it whenever he's on screen before panel 8 (panels 2, 3, 5 and 7).
  - The raccoon swipes it in panel 8.
  - He wears it from panel 9 on (the trap knocks it up off his head in panel 13), and pulls it on again in panel 15.
- **The camper** (mustard jacket, short beard) is the story's other main character. He looks the same throughout, so he's recognisable when he brings the raccoon home in panel 14.
- **The beanie photo** is the same picture everywhere it appears: the poster (panels 10 and 13) and the camper's phone (14). It's how the camper finds him.
- **The marshmallows** he goes after at the party (panels 5 and 7) are what the officer brings to the block party (12) and the bait in the trap (13).
- **The dogs:** the three dogs in panel 11 keep their looks and collar colours. The sausage dog is the one that leaps for the sausages in panel 12.
- **Animal control:** the van that turns into the lane in panel 11 is the one parked at the block party (13). Its paw logo is also on the carrier that traps him (13) and that the camper opens under his tree (14).
- **The diner's pink neon cup** marks the town, from the edge of town (9) to the alley (10).
- **The block party street** has the same houses, bunting and snack table in panels 12 and 13.
- **The party layout never changes:**
  - his tree at the left edge;
  - the fire in the middle with dancers around it;
  - the speaker and tent on the right;
  - the log, the backpack and the cooler near the fire;
  - string lights at the back;
  - the teal station wagon parked behind. The same car drives him home.
- **His tree** has the same trunk and hole in panels 3 and 14. Panels 1, 2 and 15 are inside it or at its hole, and panel 15 mirrors panel 2's framing exactly.
- **Light:**
  - party: blue-violet moonlight, amber firelight, warm string lights;
  - town: harsher white street lights, the diner's neon, the block party's string lights;
  - ending: calm moonlight and headlights.

## Legend

- **Gameplay view:** what the game camera shows.
  - *As planned in drafts v3–v5:* a tilted 3/4 view, about 50° down, following the raccoon. *Wide* is the start-of-level view and *medium* is the normal follow distance. The gameplay thumbnails (panels 3, 5, 6 and 10–12) are drawn for this camera.
  - *Revised in v6 (6 Oct 2026):* you picked the camera in the running game with the Tab camera panel (commit dcae18a). It looks down 27° instead of about 50°, turned 14°, through a narrow 15° lens from 19.2 m, so the scene reads like a tabletop diorama. It still follows the raccoon. The mouse wheel zooms it, so *wide* now means zoomed out and *medium* the default zoom, but the player can't turn it. Compared with the thumbnails, the ground looks flatter and people and props are seen more from the side. The thumbnails are kept as drawn, as the record of the plan, and TEST-REPORT.md will put them next to in-game screenshots.
- **Design view:** something outside normal play (the intro, cutscenes, the ending), or a shot that sets how a moment should feel.
- **Frame:** 16:9 throughout (1600 × 900).

## Coverage

| Requirement | Panels |
|---|---|
| First thing the player sees | 1 |
| Core action | 5 |
| Success | 6 |
| Failure | 7 |
| Recovery or retry | 8 (the getaway after the bust) |
| End of a play session | 15 (level 1 ends at 8, the town at 13) |
| Shot sizes | close-up 1, 4 · medium 5, 6, 7, 12, 13 · wide 2, 3, 8, 9, 10, 11, 14, 15 |
| Angles | eye level 1, 4, 8, 13, 14 · high 3/4 3, 5, 6, 10, 11, 12 · high over the shoulder 2, 15 · low 7, 9 |
| Views | gameplay 3, 4, 5, 6, 10, 11, 12 · design 1, 2, 7, 8, 9, 13, 14, 15 |

---

## Opening

## Panel 1 — Good vibrations
![Panel 1](design/storyboard/01-good-vibrations.svg)
- **Shot:** close-up · eye level · design view (intro)
- **Player action:** none yet; the intro plays (any key skips). Each bass thump from the party bounces the sleeping raccoon and his acorn stash into the air. On the third thump an acorn bonks him on the head and his eyes pop open.
- **See:** the raccoon curled up in his tree hole, mid-bounce; acorns in the air; party lights and dancing silhouettes glowing through the opening; vibration lines on the walls.
- **Hear:** muffled bass thumps, chatter and laughter through the wood, crickets underneath; a bonk. *Music:* none yet, only the party's muffled beat.
- **Assets:** CHAR-SLEEP, ENV-HOLE-INSIDE, PROP-ACORNS, SFX-BASS-THUMP, SFX-BONK, AMB-FOREST
- **Design reason (pillar 3, Home should be quiet):** his cosy, quiet home is literally shaken by the party's noise.

## Panel 2 — Party below
![Panel 2](design/storyboard/02-party-below.svg)
- **Shot:** wide · high angle over his shoulder from the hole · design view (intro)
- **Player action:** none; the intro continues. He pops his head out of the hole and looks down. The smell from the grill drifts up and his nose twitches.
- **See:**
  - In the foreground: the back of his head and ears.
  - Below, the party in full swing under his tree: string lights, the speaker, people dancing around the campfire, the grill, the cooler, the tent and the teal station wagon.
  - The camper in the red beanie roasting marshmallows on a log.
  - A dotted smell trail from the grill to his nose.
- **Hear:** the music suddenly clear and loud; chatter and laughter; the crickets drowned out. *Music:* the party's track, playing from the speaker.
- **Assets:** CHAR-PEEK, ENV-CAMPSITE, PROP-STRING-LIGHTS, PROP-SPEAKER, PROP-FIRE, PROP-GRILL, PROP-TENT, PROP-COOLER, PROP-BACKPACK, PROP-CAR, NPC-CAMPER-ROAST, NPC-PARTIER-DANCE, MUS-PARTY
- **Design reason (pillar 3, and curiosity):** the noise invaded his home, but the smell makes him curious. That's why he goes down instead of hiding.

## Level 1: the party

## Panel 3 — Dropping in
![Panel 3](design/storyboard/03-dropping-in.svg)
- **Shot:** wide · high 3/4 · gameplay view (level start)
- **Player action:** first control. He slides down the trunk headfirst and lands in a puff of dust. From here the player can walk anywhere in the campsite, and the to-do cards slide in at the top right.
- **See:** his tree at the left edge; the whole party laid out in the game camera; five to-do cards arriving in the corner.
- **Hear:** a slide and a soft landing thump; party music from the speaker. *Music:* the party track in the world, with the sneaky piano loop starting underneath.
- **Assets:** CHAR-CLIMB, ENV-TREE, ENV-CAMPSITE, UI-TODO-CARDS, SFX-SLIDE, SFX-LAND, MUS-PARTY, MUS-PIANO-LOOP
- **Design reason (pillar 1, Outsmart the humans):** the whole party is visible from the first frame, so the player can read who's doing what before choosing where to strike.

## Panel 4 — Things to do
![Panel 4](design/storyboard/04-things-to-do.svg)
- **Shot:** close-up · eye level, straight on · gameplay view (UI)
- **Player action:** opens the to-do list and picks any task, in any order. His paw taps "music off".
- **See:** the to-do list as doodle cards with short labels: steal the marshmallows · spill the cocoa · a sock for a marshmallow · music off (an unplugged speaker and a crossed-out note) · collapse the tent. The party is blurred behind it.
- **Hear:** a paper rustle and a tap. *Music:* the piano loop continues; the party music is muffled while the list is open.
- **Assets:** UI-TODO-LIST, SFX-PAPER, MUS-PIANO-LOOP
- **Design reason (pillar 4, Every prank lands):** each task is a joke the player can picture from its doodle alone, so they choose pranks, not chores.

## Panel 5 — Paws on the zipper
![Panel 5](design/storyboard/05-paws-on-the-zipper.svg)
- **Shot:** medium · high 3/4 · gameplay view
- **Player action:** holds Interact at the backpack while the camper roasts marshmallows with his back to the raccoon, and the zipper opens tooth by tooth. A dancer's elbow swings past the raccoon's head and he freezes mid-pose.
- **See:** the raccoon up on his hind legs with his paws in the backpack and marshmallows peeking out; a sweat drop and freeze marks; the camper in the red beanie facing the fire; the marshmallow card highlighted.
- **Hear:** zipper ticks under the party music; a whoosh as the elbow swings by. *Music:* the piano loop, steady.
- **Assets:** CHAR-FIDDLE, PROP-BACKPACK, PROP-MARSHMALLOWS, NPC-CAMPER-ROAST, NPC-PARTIER-DANCE, UI-TODO-CARDS, SFX-ZIP, SFX-WHOOSH, MUS-PIANO-LOOP
- **Design reason (pillar 1):** the opening exists because everyone is busy with their routine, roasting and dancing. Reading that is the whole skill.

## Panel 6 — Music off
![Panel 6](design/storyboard/06-music-off.svg)
- **Shot:** medium · high 3/4 · gameplay view
- **Player action:** grabs the speaker's plug in his teeth, yanks it out and slinks away dragging the cord.
- **See:** the plug popping out with an impact star; music notes falling upside down; the dancers frozen mid-move in silly poses; a marshmallow dropping off someone's stick; crickets back in the grass; the music-off card crossed off with a sparkle.
- **Hear:** the music winds down to silence, the crickets return, then a short piano flourish. *Music:* the party track stops; piano flourish.
- **Assets:** CHAR-DRAG, PROP-SPEAKER, PROP-PLUG, NPC-PARTIER-FREEZE, UI-TODO-CARDS, SFX-PLUG-POP, SFX-MUSIC-WINDDOWN, SFX-FLOURISH, AMB-FOREST
- **Design reason (pillars 4 and 3):** the prank lands with a big, readable reaction, and for a moment his home sounds the way it should.

## Panel 7 — Busted
![Panel 7](design/storyboard/07-busted.svg)
- **Shot:** medium · low angle · design view (how being caught should feel; in game this plays in the 3/4 camera)
- **Player action:** goes back for the marshmallows. With the music off the party has gone quiet, and the bag's crinkle carries. The camper spins round with his phone light. The raccoon does a double-take with his fur on end, and the bag flies out of his mouth. The camper lunges and catches his foot on the cooler.
- **See:** the camper in the red beanie looming with his phone light on the raccoon; the raccoon mid-jump with spiky fur and a double-take; the marshmallow bag flying with crinkle marks round it, and marshmallows everywhere; the camper's foot hooked on the cooler.
- **Hear:** no music to hide under, so the crinkle sounds huge; a gasp, a yelp, and a soft thud as the camper trips, unhurt. *Music:* the piano cuts out for a beat.
- **Assets:** CHAR-STARTLED, NPC-CAMPER-LUNGE, PROP-PHONE, PROP-MARSHMALLOWS, PROP-COOLER, SFX-CRINKLE, SFX-GASP-YELP, SFX-THUD
- **Design reason (pillar 2, Mischief, not malice):** getting caught is a pratfall for both of them, never a punishment. And it was his own prank, the silence, that gave him away.

## Panel 8 — The red beanie
![Panel 8](design/storyboard/08-the-red-beanie.svg)
- **Shot:** wide · eye level, side-on · design view (how the getaway should feel; in game the player steers it in the 3/4 camera)
- **Player action:** runs for it. Being caught isn't game over: the player steers the getaway.
  - The fed-up partiers give chase: one trips over a tent rope, two bonk heads, and the camper's frying pan swings and misses.
  - As the raccoon zips past the camper, he snatches the red beanie right off the camper's head and vanishes into the trees with it. Reaching the trees ends level 1.
- **See:** the chase under the moon; impact stars; the pan's missed swing; a dotted trail from the camper's bare head to the beanie in the raccoon's mouth; dark trees swallowing him.
- **Hear:** crashes, boings and yelps. *Music:* a loud, fast piano chase that ends on a playful sting.
- **Assets:** CHAR-RUN-BEANIE, NPC-CAMPER-CHASE, NPC-PARTIER-TRIP, NPC-PARTIER-REEL, PROP-PAN, PROP-BEANIE, SFX-CRASH, SFX-BOING, MUS-PIANO-CHASE
- **Design reason (pillar 2):** this is the recovery. The bust turns into a getaway he wins, the humans fall over each other, and he leaves with a trophy.

## The town

## Panel 9 — Edge of town
![Panel 9](design/storyboard/09-edge-of-town.svg)
- **Shot:** wide · low angle, at his height · design view (the start of the town)
- **Player action:** none; a short intro, then the player takes control. He comes out of the trees at the edge of town and stops dead. The noise rolls over him, and then the smell: trash bags everywhere. He grins.
- **See:**
  - On the left, the last dark trees of the forest, with fireflies.
  - On the right, the town lit up: the diner's pink neon cup on its roof, streetlights, houses, a water tower and a siren's blue glow.
  - A car coming down the road with its headlights on.
  - Trash bags and a bungee-corded bin along the road.
  - Noise lines rolling in towards him, and a smell trail from the nearest bags to his nose.
- **Hear:** the forest's crickets fade under traffic, a horn, a distant siren and the neon's buzz; a long sniff. *Music:* the piano loop changes into its town version.
- **Assets:** CHAR-SNIFF, ENV-TOWN-EDGE, PROP-TRASH-BAGS, PROP-BIN, PROP-BUNGEE, PROP-TOWN-CAR, SFX-HORN, SFX-SNIFF, AMB-FOREST, AMB-TOWN, MUS-PIANO-TOWN
- **Design reason (pillar 3, Home should be quiet):** the town is even louder than the party he fled, but it smells like dinner, so in he goes.

## Panel 10 — The masked bandit
![Panel 10](design/storyboard/10-the-masked-bandit.svg)
- **Shot:** wide · high 3/4 · gameplay view
- **Player action:** works through the town's jobs, the three from CONCEPT.md: raid the diner dumpster · beat the bungee-corded bin · steal from the block party barbecue. Here the dumpster is done, and he wrestles a bungee cord off a raccoon-proof bin. The cord twangs back and launches the lid like a frisbee.
- **See:**
  - An alley behind the diner, under its buzzing neon cup sign.
  - The raided dumpster with its bags pulled out; dented bins with yellow bungee cords; the raccoon in the red beanie on one of them; the lid spinning away.
  - People leaning out of windows snapping phone photos.
  - A lamppost poster showing only his picture in the beanie.
  - The town's to-do cards: the dumpster crossed off, the bungee bin highlighted.
- **Hear:** traffic, a distant siren, neon buzz, a bungee twang, camera clicks. *Music:* the town version of the piano loop.
- **Assets:** CHAR-BEANIE-FIDDLE, ENV-TOWN-ALLEY, PROP-BIN, PROP-BUNGEE, PROP-POSTER, NPC-WATCHER, UI-TODO-CARDS, SFX-TWANG, SFX-CAMERA-CLICK, AMB-TOWN, MUS-PIANO-TOWN
- **Design reason (pillar 4, Every prank lands):** each job pays off twice, once with the gag and once with the town noticing him: phones out, and his face on a poster.

## Panel 11 — Barking up the wrong tree
![Panel 11](design/storyboard/11-barking-up-the-wrong-tree.svg)
- **Shot:** wide · high 3/4 · gameplay view
- **Player action:** shakes off the neighbourhood dogs.
  - The big shaggy dog wakes in the back alley with one huge bark. The tiny dog yaps after him, and the sausage dog follows his scent.
  - They're all faster than him, so he uses his head. He runs rings round a tree to lay a false trail, slips behind the bins, and hops up onto the fence.
  - The dogs follow the trail to the tree and end up barking up it, while he grins down at them from the fence.
- **See:**
  - The back alley at night: the backs of the houses, a wooden fence, the bins and the tree.
  - The three dogs piled up at the tree: the big shaggy one up on its hind legs against the trunk, barking up it; the tiny one bouncing and yapping; the sausage dog sniffing round in circles.
  - His dotted trail: round and round the tree, then behind the bins and up onto the fence.
  - The raccoon in the beanie on top of the fence.
  - A neighbour leaning out of a window to snap a photo.
  - The animal-control van turning into the lane, its headlights on.
  - The town's to-do cards: the dumpster and the bungee bin crossed off.
- **Hear:** one big "woof", nonstop yapping, sniffing and skidding paws; a window opening and a camera click; the van's engine. *Music:* the town piano loop speeds up into a chase, then drops to a sly pluck as the dogs bark at the empty tree.
- **Assets:** CHAR-RUN, CHAR-PERCH, ENV-BACK-ALLEY, PROP-FENCE, PROP-BIN, NPC-DOG-BIG-BARK, NPC-DOG-TINY-YAP, NPC-DOG-SAUSAGE-SNIFF, NPC-WATCHER, PROP-ANIMAL-VAN, UI-TODO-CARDS, SFX-BARK, SFX-YAP, SFX-SKID, SFX-CAMERA-CLICK, AMB-TOWN, MUS-PIANO-TOWN
- **Design reason (pillar 1, Outsmart the humans, and their dogs):** the dogs are faster than him, so he wins with his head, not his legs. And all their barking is what brings animal control.

## Panel 12 — The barbecue heist
![Panel 12](design/storyboard/12-the-barbecue-heist.svg)
- **Shot:** medium · high 3/4 · gameplay view
- **Player action:** his biggest heist. As the grill master flips a burger sky-high and every head turns to watch, he grabs the end of a string of sausages and runs. It pays out behind him across the block party: a kid limbos under it, and the sausage dog from panel 11 leaps for it.
- **See:**
  - The block party street: bunting, string lights, chalk drawings and confetti.
  - The burger mid-flip and the neighbours staring up at it.
  - The string of sausages from the grill to the raccoon's mouth, with the kid and the dog.
  - At the back, the animal-control officer peeking over the snack table with a bag of marshmallows.
  - The town's to-do cards: the dumpster and the bungee bin crossed off, the barbecue highlighted.
- **Hear:** sizzling, the crowd's "ooh" at the flip, a happy bark, and the sausages zipping off the grill. *Music:* the town piano loop picks up speed.
- **Assets:** CHAR-RUN, ENV-BLOCK-PARTY, PROP-GRILL, PROP-SAUSAGES, PROP-BURGER, PROP-MARSHMALLOWS, NPC-GRILL-MASTER, NPC-NEIGHBOUR-WATCH, NPC-KID-LIMBO, NPC-DOG-SAUSAGE-LEAP, NPC-OFFICER-LURK, UI-TODO-CARDS, SFX-SIZZLE, SFX-CROWD-OOH, SFX-BARK, SFX-WHOOSH, MUS-PIANO-TOWN
- **Design reason (pillar 1, Outsmart the humans):** the campsite's lesson pays off, because everyone is watching the flip and not him. Only the player spots the officer waiting at the back.

## Panel 13 — The marshmallow trap
![Panel 13](design/storyboard/13-the-marshmallow-trap.svg)
- **Shot:** medium · eye level, side-on · design view (the cutscene that ends the town)
- **Player action:** follows a trail of marshmallows across the block party and into an open carrier. Taking the last one springs the trap: the animal-control officer, waiting behind the snack table, yanks a string, the stick propping the door open flies out, and the door slams shut. This ends the town.
- **See:**
  - The carrier hopping as the door slams, with impact marks.
  - His face behind the bars: eyes wide, a marshmallow in his teeth, the beanie knocked up off his head.
  - The stick flying off on its string to the officer, who pops up behind the snack table, laughing, net held high.
  - The trail of marshmallows leading in.
  - The block party: bunting, string lights, balloons, a pie, a cake and a punch bowl; neighbours snapping photos from their windows; the animal-control van with the carrier's paw logo; his poster on the lamppost.
- **Hear:** block-party chatter; munching; a snap and a clang as the door shuts; a gasp, then laughter, cheers and camera clicks. *Music:* the town piano loop stops dead on the clang, and a sad trombone goes "wah-wah".
- **Assets:** CHAR-TRAPPED, ENV-BLOCK-PARTY, PROP-CARRIER, PROP-MARSHMALLOWS, PROP-TRAP-STICK, PROP-NET, PROP-ANIMAL-VAN, PROP-POSTER, PROP-STRING-LIGHTS, NPC-OFFICER-YANK, NPC-WATCHER, SFX-SLAM, SFX-CROWD-CHEER, SFX-CAMERA-CLICK, SFX-SAD-TROMBONE, AMB-TOWN, MUS-PIANO-TOWN
- **Design reason (pillar 1, turned around):** for once the humans outsmart him, using the weakness the player saw at the party, so the capture feels fair and funny, not cruel.

## Ending

## Panel 14 — Home at last
![Panel 14](design/storyboard/14-home-at-last.svg)
- **Shot:** wide · eye level · design view (ending cutscene)
- **Player action:** none; this cutscene follows the capture.
  - The beanie camper, the only person who knows where the raccoon lives, kneels under the raccoon's tree and opens the animal-control carrier, with the bandit's beanie photo on his phone.
  - The raccoon tumbles out, straightens the beanie and scurries up to his hole. The camper lets him keep it.
  - The camper's friend shrugs, and they drive off.
- **See:** the raccoon's tree and hole in moonlight; the teal station wagon's headlights; the open carrier; the camper kneeling with the beanie photo on his phone; the raccoon mid-tumble in the beanie; a dotted arrow up the trunk to his hole; crickets in the grass.
- **Hear:** the engine idling, a car door, the car fading away, then only crickets. *Music:* the theme, slow and gentle.
- **Assets:** CHAR-TUMBLE, ENV-TREE, PROP-CARRIER, PROP-CAR, PROP-PHONE, NPC-CAMPER-KNEEL, NPC-FRIEND-SHRUG, SFX-ENGINE, SFX-CAR-DOOR, AMB-FOREST, MUS-THEME-SLOW
- **Design reason (pillars 2 and 3):** the camper he pranked all night turns out kind, and for the first time in the game the raccoon's home is quiet.

## Panel 15 — Here we go again
![Panel 15](design/storyboard/15-here-we-go-again.svg)
- **Shot:** wide · high angle over his shoulder from the hole · design view (ending; mirrors panel 2)
- **Player action:** none. A new party starts thumping below. He pulls on the red beanie, turns to grin at us and rubs his paws together as the picture irises out on him.
- **See:** the same framing as panel 2, with a new group, an orange van and a new roaster on the log; the raccoon in the beanie with half-closed, scheming eyes; the iris closing in.
- **Hear:** the bass thump and chatter return. *Music:* the playful piano kicks back in and ends on a flourish.
- **Assets:** CHAR-GRIN-BEANIE, ENV-CAMPSITE, PROP-VAN, NPC-PARTIER-DANCE, SFX-BASS-THUMP, MUS-PIANO-LOOP, SFX-FLOURISH
- **Design reason (pillar 1, and the story's loop):** the first shot comes back with the beanie on, so the ending promises more mischief without a single word.

---

## Open choices (not decided yet)

- **Opening vs. CONCEPT.md.** This storyboard uses your new opening, where the party is already in full swing when he wakes. CONCEPT.md still describes campers arriving with car doors slamming.
- **How level 1 ends.** On the board, the bust in panel 7 leads straight into the getaway that ends the level. Still open: does any bust end level 1, or only one after he's done enough tasks? Claude's suggestion is 3 of the 5. If you choose that, earlier busts need a smaller consequence.
- **One town level or two?** You call them the city levels. The board treats the town as one level, with CONCEPT.md's three town jobs as its to-do cards. The block party (panels 12 and 13) could be a level of its own.
- **The music.** Claude's suggestion:
  - the party's music plays from the speaker in the world, with the sneaky piano loop underneath;
  - cutting the music leaves only crickets and piano, which is also why the party can hear him in panel 7.
- **Gags Claude added:**
  - the acorn bonk;
  - the sniffing nose;
  - the elbow near-miss;
  - the bag's crinkle giving him away;
  - the cooler trip;
  - the frying pan;
  - the noise and the smell hitting him at once at the edge of town;
  - the bungee frisbee;
  - the window photos and the poster;
  - the dogs' chase: the false trail round the tree, the dogs barking up it, and their racket bringing the van;
  - the burger flip, the sausage string, the limbo and the sausage dog;
  - the officer waiting with marshmallows, the trail, the stick on a string and the sad trombone;
  - the iris-out.
- **Task cards.** Doodles with short labels, as drawn, or doodles only.

## Asset IDs used above

| Group | IDs |
|---|---|
| Raccoon | CHAR-SLEEP, CHAR-PEEK, CHAR-CLIMB, CHAR-FIDDLE, CHAR-DRAG, CHAR-STARTLED, CHAR-RUN-BEANIE, CHAR-SNIFF, CHAR-BEANIE-FIDDLE, CHAR-RUN, CHAR-PERCH, CHAR-TRAPPED, CHAR-TUMBLE, CHAR-GRIN-BEANIE |
| People and animals | NPC-CAMPER-ROAST, NPC-PARTIER-DANCE, NPC-PARTIER-FREEZE, NPC-CAMPER-LUNGE, NPC-CAMPER-CHASE, NPC-PARTIER-TRIP, NPC-PARTIER-REEL, NPC-WATCHER, NPC-DOG-BIG-BARK, NPC-DOG-TINY-YAP, NPC-DOG-SAUSAGE-SNIFF, NPC-GRILL-MASTER, NPC-NEIGHBOUR-WATCH, NPC-KID-LIMBO, NPC-DOG-SAUSAGE-LEAP, NPC-OFFICER-LURK, NPC-OFFICER-YANK, NPC-CAMPER-KNEEL, NPC-FRIEND-SHRUG |
| Places | ENV-HOLE-INSIDE, ENV-CAMPSITE, ENV-TREE, ENV-TOWN-EDGE, ENV-TOWN-ALLEY, ENV-BACK-ALLEY, ENV-BLOCK-PARTY |
| Props | PROP-ACORNS, PROP-STRING-LIGHTS, PROP-SPEAKER, PROP-FIRE, PROP-GRILL, PROP-TENT, PROP-COOLER, PROP-BACKPACK, PROP-CAR, PROP-MARSHMALLOWS, PROP-PLUG, PROP-PHONE, PROP-PAN, PROP-BEANIE, PROP-TRASH-BAGS, PROP-BIN, PROP-BUNGEE, PROP-TOWN-CAR, PROP-POSTER, PROP-FENCE, PROP-ANIMAL-VAN, PROP-SAUSAGES, PROP-BURGER, PROP-CARRIER, PROP-TRAP-STICK, PROP-NET, PROP-VAN |
| UI | UI-TODO-CARDS, UI-TODO-LIST |
| Sound | SFX-BASS-THUMP, SFX-BONK, SFX-SLIDE, SFX-LAND, SFX-PAPER, SFX-ZIP, SFX-WHOOSH, SFX-PLUG-POP, SFX-MUSIC-WINDDOWN, SFX-FLOURISH, SFX-CRINKLE, SFX-GASP-YELP, SFX-THUD, SFX-CRASH, SFX-BOING, SFX-HORN, SFX-SNIFF, SFX-TWANG, SFX-CAMERA-CLICK, SFX-BARK, SFX-YAP, SFX-SKID, SFX-SIZZLE, SFX-CROWD-OOH, SFX-SLAM, SFX-CROWD-CHEER, SFX-SAD-TROMBONE, SFX-ENGINE, SFX-CAR-DOOR |
| Music and ambience | MUS-PARTY, MUS-PIANO-LOOP, MUS-PIANO-CHASE, MUS-PIANO-TOWN, MUS-THEME-SLOW, AMB-FOREST, AMB-TOWN |

The slice won't need all of these. Which ones it builds is decided later, in CHANGE-BRIEF.md.

### The raccoon's IDs and the character sheet's poses (added in v6)

The panels name the raccoon's images by story moment, while CHARACTER-SHEET.md numbers his poses by game state. This table lines the two up, so each row in the asset log can use one ID that matches both.

| Storyboard ID | Panels | Character-sheet pose |
|---|---|---|
| CHAR-SLEEP | 1 | 12, Asleep |
| CHAR-PEEK | 2 | None: design view only |
| CHAR-CLIMB | 3 | None in the sheet yet (the game has had tree climbing since 6 Oct) |
| CHAR-FIDDLE | 5 | 8, Interact |
| CHAR-DRAG | 6 | 9, Carrying, with the plug instead of the bag |
| CHAR-STARTLED | 7 | 10, Busted |
| CHAR-RUN-BEANIE | 8 | 7, Run, with the beanie in his mouth |
| CHAR-SNIFF | 9 | None: design view only |
| CHAR-BEANIE-FIDDLE | 10 | 8, Interact, plus the beanie (prompt B) |
| CHAR-RUN | 11, 12 | 7, Run, plus the beanie |
| CHAR-PERCH | 11 | None in the sheet yet |
| CHAR-TRAPPED | 13 | None: design view only |
| CHAR-TUMBLE | 14 | None: design view only |
| CHAR-GRIN-BEANIE | 15 | 11, Job done, plus the beanie |

Four of the sheet's states have no storyboard ID, because no panel is about them. They're what the player sees between actions in every gameplay panel (3, 5, 6 and 10–12). Their IDs:

| ID | Character-sheet pose |
|---|---|
| CHAR-IDLE | 3, Idle |
| CHAR-BORED | 4, Bored |
| CHAR-WALK | 5, Walk |
| CHAR-SNEAK | 6, Sneak |

## Provenance

- **Your story and decisions.** The story comes from CONCEPT.md; see its provenance note. In chat on 4–5 Oct 2026 you decided:
  - the party is already in full swing when he wakes;
  - he comes down out of curiosity into an open first level with optional fun tasks;
  - the game is slapstick, with no dialogue, told through actions and events;
  - the storyboard covers the whole story (12 panels at first, 15 since draft v3);
  - gameplay panels use a tilted 3/4 camera;
  - Claude draws the thumbnails;
  - the raccoon's look follows your Gemini image.
- **Your changes for draft v2 (5 Oct 2026):**
  - music off stays on the to-do list (Claude first suggested it as "unplug the speaker"), and its panel comes before Busted;
  - the beanie steal comes straight after Busted;
  - Shooed off is cut;
  - one more panel in the town.
- **Your change for draft v3 (5 Oct 2026):** three more town panels before he's caught, because the town was too light. Draft v3 is the first committed version (5b4fb68, 13:13), and 2849ac2 renamed it to The Noise Next Door a minute later.
- **Your change for draft v4 (5 Oct 2026, 3f2499f):** the beanie camper is a man and the story's other main character, the one who brings the raccoon home and lets him go.
- **Your change for draft v5 (5 Oct 2026, 4f5313a):** the group chat is cut, because it made no sense to you. Panel 11 is now the neighbourhood dogs chasing him.
- **Committed before generating.** Drafts v3–v5 were all committed on 5 Oct, by 17:03. The only file in `design/reference/` or `design/music/` dated earlier is the style target (REF-STYLE in SOURCES.md, 4 Oct). The next one, `design/reference/raccoon/picking-items.jpg`, is dated 5 Oct, 17:09.
- **Your camera choice, recorded in draft v6 (6 Oct 2026):** the camera you picked in the running game (dcae18a) replaces the planned 50° view. See the legend. No panel or thumbnail changed. Earlier drafts stay in the git history: `git show 5b4fb68:STORYBOARD.md` prints the first committed version.
- **Claude's contributions:**
  - the shot list and the wording of every panel;
  - the specific gags and choices listed under Open choices, including what happens in the marshmallow trap and the crinkle that links panels 6 and 7;
  - making panel 8 the recovery beat once Shooed off was cut, since the brief asks for one;
  - the camper's look: the short hair and beard that replaced the ponytail of earlier drafts;
  - staging the three new town panels from CONCEPT.md's Act 2 (the edge of town, the group chat, the block party barbecue), and the town's to-do cards from its town jobs;
  - the dogs' chase that replaced the group chat in panel 11;
  - the thumbnails, drawn in code by `design/storyboard/make_thumbnails.py`. Run `python design/storyboard/make_thumbnails.py` to redraw them after edits;
  - in v6: the legend's camera note, the commit references in this section, and the table lining up the raccoon's IDs with the character sheet's poses, including the four new IDs CHAR-IDLE, CHAR-BORED, CHAR-WALK and CHAR-SNEAK.
- **Generative models:** none. No panel was made with an image generator.
