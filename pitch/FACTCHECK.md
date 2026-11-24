# Fact check: The Noise Next Door, final project pitch

`pitch/` · Assignment 8 · Draft v1, 24 Nov 2026 (Claude Code's, for me to check)

Status: checked by Claude Code on 24 Nov 2026 against the sources named, with the takes as recorded. Signed off by me the same day, after watching the final: "Looks good, commit".

Every claim the film makes, where it comes from, and its verdict. The course's honesty rule applies to all of them: the past tense is only for what exists and can be shown, and everything else is "will".
- **PASS** means Claude Code read the source named, or watched the take at the times given, and the claim holds.
- **CORRECTED** means the line was changed until it held (see "Fixed while drafting").
- **EXEMPT** means it isn't a claim of fact: a plan, said as "will", or my own answer about myself.

## The sources

- **The design document:** `GDD.md` v1.0, 19 Oct 2026, SHA-256 `8dcc1ba00fbd180bf4f581c81a129eeb6417dfc17eb59b21bb67c85e78081737`. Every excerpt on a board is copied from its lines by `tools/build_ledger.py`, and Brutalist's `godot-gdd --check` confirms each is exact.
- **The game as built:**
  - tag `a7` (`e21bb3a`);
  - `c92a53d` (23 Nov 2026) for level 1's ending;
  - `81c1df3` for Scare a camper;
  - `370f62d` for the camp round the cake;
  - `263ac50` (24 Nov 2026) for the day's work the second and third takes were recorded on.
- **The takes, as recorded** (each with its notes in `capture/`; the recordings stay out of GitHub):

| Take | Recorded | Revision | SHA-256 |
|---|---|---|---|
| `capture/run-01.mp4`: title screen to the tutorial's end, from New Game | 23 Nov 2026 | `370f62d` | `ac65a4fe5f0567cfdfb383269df12ef595f1ed07d77636f9ff3497d06712e0c0` |
| `capture/run-02.mp4`: the tent, Scare a camper (developer-menu start) | 24 Nov 2026, 17:13 | `263ac50` | `bec67e6135a18165165c5162bf5da2b6c7b9363782c2ebdbfaa768e80cb64a03` |
| `capture/run-03.mp4`: the cake to the chase (developer menu's cake point) | 24 Nov 2026, 17:29 | `263ac50` | `8f0b700c1aaae41a5c060a858c246fba4f95fa828932059d71b8df2b47521660` |

- **Each revision passes the whole test list:**
  - `370f62d`: `evidence/370f62d-test-run.txt`, 23 Nov 2026;
  - `263ac50`: `evidence/263ac50-test-run.txt`, 24 Nov 2026, on that commit alone, in its own worktree, from an empty import. That covers cake 23 and huh 6 at 30, 60 and 144 fps, box 16 and rig 61. `cost_effects` fails 3 of 4 as at the A7 baseline (the fire out).
- **Its game files** were last changed by 16:41, before either take.

## Claims, beat by beat

| # | Beat | Claim (as spoken / shown) | Verdict | Source / derivation | Note |
|---|---|---|---|---|---|
| 1 | B00 | "Everything you see playing is real play" | PASS | The three takes: the game played by me at real speed, its window screen-recorded with Snipping Tool (SHOTLIST.md); every clip is labelled with its take's revision and date | Clips from a developer-menu start are labelled STAGED START |
| 2 | B00 | "When something isn't built yet, I'll say so" | PASS | B01 and B08 name what's still to build; boards mark it Proposed | |
| 3 | B01 | "A slapstick stealth-puzzle game for desktop" | PASS | GDD §2: "a story-driven slapstick comedy puzzle game". "Stealth" names its sneaking and the campers' sight cones (README) | |
| 4 | B01 | The story: pester the campers, chased into town in the red beanie, driven home by that camper | PASS | GDD §6, Story | Said as the plan; the board marks it Proposed |
| 5 | B01 | "Level one now runs end to end, from the title screen to the chase out of the camp" | PASS | The camp at `a7`; its ending at `c92a53d`; `tests/test_cake_finale.gd` 23 of 23 at 30, 60 and 144 fps on `263ac50`, through its end ("To be continued"). In play, "yea feels good for now" (CHANGE-BRIEF.md, the cake's revision) | |
| 6 | B01 | "The city, the block and the ride home are still to build" | PASS | README, GDD §4 and §7.4: planned. The chase's new location isn't built (CHANGE-BRIEF.md, the cake's revision) | |
| 7 | B01, B05, B07 | "On Windows or a Mac" | EXEMPT | The game has no Windows-only code (only the `.bat` launchers and `scripts/run-test.sh`'s search for Godot), and Godot 4.7 exports to macOS | Said as what the finished game will be; it's never been exported or run on a Mac |
| 8 | B01E | "Five jobs in, the camper brings out a cake" | PASS | `scripts/camp_finale.gd`: unlocked once 5 of the camp's tasks are done (`c92a53d`); `tests/test_cake_finale.gd` checks the fetch, the carry and the table | The take is from the developer menu's cake point (five tasks done), labelled STAGED START. By its 6 s the cake is already on the table, so the fetch is the test's evidence, not the clip's |
| 9 | B01E | "the whole camp gathers round" | PASS | run-03, 7.5–14.1 s: the low-poly man, the girl and the fire keeper round the table, leaning in (`370f62d`) | |
| 10 | B01E | "I tie his laces, he trips, the cake lands on his face, and I grab his red beanie" | PASS | run-03: the ring at his heels 11.5–13.5 s, "Tie his laces" crossed off at 14; the fall 15–17; the beanie taken at 22–22.5 | |
| 11 | B01E | "Then the men chase me out, and the moth leads the way" | PASS | run-03, 32.25–33.95 s: "RUN!", the men right behind, the moth just ahead of him; 36.4–37.5: two men after him on the path | A man catches him at 34 s, and that stretch is cut. The take ends before the forest's edge |
| 12 | B02 | "Every job comes from reading the campers" | PASS | README, level 1's tasks: "The people keep to looping routines, which tell you when each one is busy"; jobs make noise, and they "come to look" | |
| 13 | B02 | "Spotted, I hop into the keeper's box, and they lose me" | PASS | run-02, 48.6–54.6 s: spotted (red) at 47–48, into the box at about 54; the "?" over them from 55 | Scare a camper is `81c1df3` |
| 14 | B02 | "They search right round it, so I burst out and scare them" | PASS | run-02: round the box 57–60 s, "E Scare!" showing; he bursts out at 63.5, and "Scare a camper" is crossed off at 64.5–65. `tests/test_box_scare.gd` 16 of 16 on `263ac50` | |
| 15 | B02 | "The worst they can do is shoo me off: no health, no lives, no game over" | PASS | GDD §7.5 (line 209); built as described. Caught, he's shooed and leaps away (CHANGE-BRIEF.md, the cake's revision); run-03 shows it at 34 s: he drops the beanie, leaps away, and the chase goes on | |
| 16 | B03 | "When a camper spots me, I dive into a bush and they lose me" | PASS | run-01, 37.5–42.5 s: spotted, into the bush, "He lost you" | |
| 17 | B03 | "Their sight is drawn on the ground, and it shrinks while I sneak" | PASS | README, the cones: "pale yellow while they watch, shorter while he sneaks" (tag `a5`); run-01, 54.5–58.5 s, sneaking out under them | |
| 18 | B03 | "When a job lands, it's crossed off the list" | PASS | run-01, 98.0–101.05 s: "Steal the marshmallows" crossed off; run-02 and run-03 show it for three more | |
| 19 | B04 | "I've played Untitled Goose Game and Stray" | EXEMPT | My answer, 23 Nov 2026: I've played all four of the GDD's inspirations | |
| 20 | B04 | Goose Game: "you can't see who's watching"; Stray: "a city whose people are gone" | PASS | Claude Code's draft of the comparison, confirmed by me as I played them (23 Nov 2026, "yea i have checked the scripts its correct interpreations") | |
| 21 | B05 | "I'm aiming at gameplay programmer roles" | EXEMPT | My answer, 23 Nov 2026 | |
| 22 | B05 | From New Game, "a moth flies ahead of him down the trail to the party, with one task on screen" | PASS | run-01, 13.0–29.81 s: the moth just ahead of him at 11, 13 and 17 s, "Investigate the music" at the bottom; CHANGE-BRIEF.md, 22 Nov revision; `tests/test_moth_guide.gd` 9 of 9 | It buzzes round his head only while he stands still, which he didn't |
| 23 | B05 | "A lead can also rerun every test, one command each" | PASS | CLAUDE.md: `bash scripts/run-test.sh <test> <fps>` | |
| 24 | B06 | "In October my design document said the game had no humans yet" | PASS | GDD line 315 | |
| 25 | B06 | "Now it has four, with routines and sight" | PASS | README: the camper, the low-poly man, the girl and the fire keeper (tag `a7`) | |
| 26 | B06 | "Shaders, particles, and the jump's animation are each built and tested" | PASS | The tags `a5` (`62ee5fb`), `a6` (`1578035`) and `a7` (`e21bb3a`), and each one's TEST-REPORT.md | The film names the commits and dates, not the assignments |
| 27 | B06 | "Effects' cost measured on my RTX 4050 laptop" | PASS | TEST-REPORT.md at `a6`: Windows 11 Home, RTX 4050 Laptop GPU, 16 GB | On the board |
| 28 | B06 | "26 pins, edge tests at 30, 60 and 144 fps" | PASS | `evidence/jump_pins_60fps.log`, `evidence/test_jump_edges_60fps.log`, `evidence/a7-baseline-SUMMARY.txt` | On the board |
| 29 | B06 | "31 headless test scripts, all rerun from a fresh clone on 22 Nov" | PASS | `evidence/a7-baseline-SUMMARY.txt`: 31 scripts, a fresh clone of `160c0eb` with an empty import cache. All pass except `cost_effects.gd` (1 of 4 checks), which has failed since before Assignment 7 | The card says "rerun", not "all pass" |
| 30 | B06 | "Nobody outside the project has played it" | PASS | My confirmation, 23 Nov 2026: "That's true." (TEST-REPORT.md at `a2`: "No one else played or listened"; nothing since records another player) | |
| 31 | B07 | "My design document plans" save states | PASS | GDD line 44 | |
| 32 | B07 | "First: level one exported for Windows and macOS, with a headless test that plays it from New Game to the chase out of the camp" | EXEMPT | Claude Code's proposal, 23 Nov 2026, confirmed by me ("yea i have checked the scripts its correct interpreations") | A plan, said as "will" |
| 33 | B07 | "I don't have a Mac, so the Mac build stays untested" | EXEMPT | My answer, 23 Nov 2026: "I don't have it." | |
| 34 | B08 | "Three levels for one person" | PASS | GDD §7.4 (line 172) | |
| 35 | B08 | "Level one alone has taken about a month" | PASS | README: level 1's campsite from 23 Oct 2026; this is 24 Nov 2026 | |
| 36 | B08 | The town's cast "doesn't exist yet: three dogs, an animal-control officer, the neighbours" | PASS | GDD §4: "Planned" | |
| 37 | B08 | The storyboard panel | PASS | `design/storyboard/11-barking-up-the-wrong-tree.svg`, drawn in code by Claude Code | Labelled CONSTRUCTED on the board |
| 38 | B09 | "Mostly to learn"; the skills "were all new to me this term" | EXEMPT | My answers, 23 Nov 2026 | The footage is run-03's getaway, 96.0–111.47 s |
| 38b | B09 | "I've used every one of them in this game" | PASS | The raccoon, modelled and rigged in Blender (`assets/characters/raccoon_v2.blend`); the campers' sight cones' shaders (`a5`); the fire's particles (`a6`); the jump's animation and its tests (`a7`); all in Godot (README) | |
| 39 | B10 | The end card's credits and revisions | PASS | SOURCES.md; the takes' revisions and dates above | |

## Fixed while drafting

- **B01** first said level 1 "exists". It had no ending yet, so it said "nearly done". Once the ending was committed (`c92a53d`, 23 Nov), it says level 1 runs end to end, and B01E shows the ending.
- **B06** first said "33 headless test scripts". That was a count of test files at `ef386f9`. The fresh-clone run it cites ran 31, so it now says 31.
- **B01, B05, B07** first said "Windows" only. I corrected it: it's a desktop game, and macOS is a planned export.
- **B07** then said "both builds" would be run outside the editor. I don't have a Mac, so it now says the Windows build will be, and the Mac build stays untested.
- **B07's "first"** was level 1's ending until it was committed. It's now the exports.
- **B02** was the backpack heist: unzip it while the camper roasts, get caught, and a man snatches the bag back. The day's takes don't have it, so B02 now says what run-02 shows, Scare a camper ("Use what's recorded", 24 Nov 2026). Its line is Claude Code's, from the take, and I kept it ("Looks good, commit").
- **B09** was to show him climbing home to his hollow. That isn't in a take either, so it shows run-03's getaway.
- **run-02's start** was first labelled as the developer menu's free point. The fire burns from its first frame, and free starts with the fire out, so its label says only that it's from the developer menu.

## Pronunciation

Kokoro read "Gangurde" as /ɡˈæŋɡɜːd/ (`generate_audio_kokoro.py --phonemize`). The narration now says only my first name ("You can just say first name. It's fine.", 23 Nov 2026). My full name stays on screen: in the boards' corner and on the end card.
