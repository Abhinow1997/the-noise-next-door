# Shot list: The Noise Next Door, final project pitch

`pitch/` · Assignment 8 · Draft v2, 24 Nov 2026 (Claude Code's, for me to check)

The film's gameplay is real play: the game run normally, at real speed, and its window recorded by me with Windows' Snipping Tool. Every other beat is a Brutalist `GodotDesignBoard` or the end card. This file lists what each take must show, how to record it, and which beat uses which stretch of it.

## Before recording

- **The revision.** I waited for level 1's ending ("Wait for the ending"). It's committed: `c92a53d`, 23 Nov 2026. Each take is recorded from a committed revision, named in `beat_sheet.json` (`metadata.footage.revision`), `capture/clips.json`, FACTCHECK.md, each clip's label and the end card. Scare a camper is `81c1df3` ("Commit Scare first"), and the camp round the cake is `370f62d` ("commited").
  - **run-01** was recorded at `370f62d` on 23 Nov. This folder differed from it only in the pitch's own files: Markdown records, `tools/svg_to_png.gd` (a tool the game never loads), and `pitch/` and `design/a8/`, which each carry a `.gdignore` so Godot doesn't import them.
  - **run-02 and run-03** were recorded on 24 Nov, on the day's game work before it was committed. It was then committed as `263ac50` ("Commit it now"), with the whole test list run on that commit alone. Every game file in it was last changed by 16:41, before either take (17:13 and 17:29).
  - Left out of `263ac50`: the brief's revision and code that take the cake's cutscene out (17:34–17:36). They came after the takes, and run-03 has the cutscene.
- **What the ending changed in the film** (done 23 Nov):
  - B01 now says level 1 runs end to end, and its board shows the ending as built;
  - B01E is new, the ending as real play (run-03);
  - B07's "first" is now the exports: Claude Code's proposal, which I confirmed.
- **How it's recorded** (since 23 Nov 2026; see "Why not Movie Maker" below):
  - start the game with the take's command below. It's the console build, so any error shows in PowerShell;
  - press **Win + Shift + R** (Snipping Tool's screen recording), drag a box tightly round the game's picture (not its title bar), and press Start;
  - play the take, then stop the recording, and save it as `pitch\capture\run-0N.mp4`.
  - The window is the game's own 1280 × 720. The cutter fits whatever size the box is into 1080p without stretching it.
- **Why not Movie Maker:** in Movie Maker mode Godot runs the game as fast as it can, and `--max-fps` doesn't hold it back. The first run-02 "recorded in 00:01:35 (250% of real-time speed)", too fast to play. That run also saved nothing: `pitch\capture\` didn't exist, and Movie Maker doesn't create its folder.
- **The game's sound** is muted under the narration in the film, so the music can be on or off.
- **Labels.** Each clip in the film carries a label at its bottom left, in two lines: "REAL PLAY · screen recording · human input", then its take's revision and date. A take started from the developer menu also carries "STAGED START" above it, with the start it used where that's known.

## The takes

### run-01: from the title screen to the end of the tutorial (normal start, about 3 min)

```powershell
& "C:\Users\Dotbix\Work\Gamedev\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "C:\Users\Dotbix\Work\Gamedev\the-noise-next-door"
```

1. Wait about 3 s on the title screen, then choose New Game.
2. Let the camera glide down to him asleep. Wait 2–3 s, then press W to wake him.
3. Stand still about 3 s while the moth buzzes round his head. Then follow it down the trail to the camp.
4. Play the tutorial through: the pan, the laugh, the dive into the bush (his eyes peeking out), the marshmallow on the plate, and the TO DO list.
5. Stop the recording, save it as `run-01.mp4`, and close the game.

### run-02: the heist, getting caught, a job done, and home (staged free-play start, about 4 min)

```powershell
& "C:\Users\Dotbix\Work\Gamedev\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "C:\Users\Dotbix\Work\Gamedev\the-noise-next-door" -- --dev-start=free
```

1. Sneak (Ctrl) near the campers for a few seconds, so their cones shorten.
2. Wait for the camper to roast with his back to his backpack. Hold E at it until the bag tumbles out.
3. Get seen on purpose, and let a man snatch the bag back. Get away.
4. Pull the plug under the table (hold E) so Turn the music off is crossed off.
5. Run home, walk into the home pine, climb to the top and into the hollow.
6. Stop the recording, save it as `run-02.mp4`, and close the game.

**As recorded** (24 Nov 2026, 80.6 s; `capture/run-02-notes.md`): not the plan above. It's the bear bag's tree, Dismantle the tent, then Scare a camper: spotted, into the keeper's box, the campers searching round it, and bursting out at them. There's no backpack and no climb home. It starts in the camp with the fire burning, so it's a developer-menu start, though not "free", which starts with the fire out. So B02 was rewritten to what it shows, and B09 uses run-03 ("Use what's recorded").

### run-03: level 1's ending (staged cake start, about 2 min)

The developer menu's cake point starts with five tasks done and the camper going straight for his cake (`--dev-start=cake`, `c92a53d`). Reaching it in normal play takes five tasks, so this take is labelled "STAGED START".

```powershell
& "C:\Users\Dotbix\Work\Gamedev\Godot\Godot_v4.7.2-stable_win64_console.exe" --path "C:\Users\Dotbix\Work\Gamedev\the-noise-next-door" -- --dev-start=cake
```

1. Let the camper fetch the cake from his tent and set it on his folding table. The others come round it.
2. While he stands at it, sneak behind him and hold E at his heels until his laces are tied (2.5 s).
3. Let him take his step: he trips, the cake lands on his face, his beanie slips off.
4. Press E on the beanie. The 10.2 s cutscene plays: he gets up, the girl takes fright, the men give chase.
5. At "RUN!", follow the moth out of the camp and through the forest, to "To be continued".
6. Once the title is back, stop the recording, save it as `run-03.mp4`, and close the game.

**As recorded** (24 Nov 2026, 115.9 s; `capture/run-03-notes.md`): the cake already on the table by 6 s, the laces, the fall, the beanie, the cutscene, then "RUN!" and the chase through the forest. A man catches him at 34 s and again at 113.5 s, and the game is closed at 115 s, before the forest's edge. So "To be continued" isn't in it; `tests/test_cake_finale.gd` checks the end.

## Which beat uses what

| Beat | Narration | Take | What the clip must show, start to end |
|---|---|---|---|
| B00 | 14.4 s | run-01 (recorded) | The title screen, New Game, the glide down, him asleep, waking him. **Cut:** 0.00–14.36 s |
| B01E | 13.1 s | run-03 (recorded) | The camp round the cake and the laces tied; the trip and the cake on his face; the beanie grabbed; "RUN!" with the men behind and the moth ahead; two men after him on the path. **Cut:** 7.50–14.10, 15.20–17.60, 21.20–22.50, 32.25–33.95, 36.40–37.52 s (the cutscene and the catch at 34 s left out) |
| B02 | 14.4 s | run-02 (recorded) | Spotted, into the keeper's box; the campers searching round it; bursting out, Scare a camper crossed off, running off. **Cut:** 48.60–54.60, 57.00–60.00, 63.00–68.42 s |
| B03 | 12.05 s | run-01 (recorded) | Spotted and into the bush, "He lost you"; sneaking out under the cones; "Steal the marshmallows" crossed off. **Cut:** 37.50–42.50, 54.50–58.50, 98.00–101.05 s |
| B05 | 16.8 s | run-01 (recorded) | The trail, the moth flying ahead of him, "Investigate the music" at the bottom, the waves. **Cut:** 13.00–29.81 s |
| B09 | 15.5 s | run-03 (recorded) | The getaway: out of a bush, over the bridge, past the cabin with two men after him, on through the trees. **Cut:** 96.00–111.47 s. (Planned: climbing home, from run-02, which doesn't have it) |

The start and end of each clip are picked from the takes, then written here and in `beat_sheet.json`. A clip runs at its real speed and isn't retimed. If the action is shorter than the narration, the last frame is held, and the hold is labelled.

## After recording

- **Each take's notes:** what was pressed and when, written from the take into `capture/run-0N-notes.md`. That's the input log for a human-input take.
- **Each clip:** cut from the take by `tools/cut_clips.py` at the source times in `capture/clips.json`, cropped to the game, scaled from 1280 × 720 to 1920 × 1080, with its label, into `media/<beat>.mp4`.
- **Gate V:** a gameplay beat fills the frame with the game's night scene, which the toolkit's checks read as edge-bleed and low contrast. Each gameplay beat says so in `beat_sheet.json` (`qc.full_bleed`, with its reason). Its label's box is declared too (`qc.contrast_regions`), so the label's contrast is still checked.
- **In the final:** Brutalist compiles at 24 fps, so the clips' 30 fps frames are resampled to 24 there. Their timing isn't changed: each clip is cut to its narration's length, so nothing is slowed or stretched to fit.
- **The hashes:** each recording's SHA-256 goes in FACTCHECK.md. The recordings and clips stay out of GitHub (the repo keeps `*.mp4` out).
