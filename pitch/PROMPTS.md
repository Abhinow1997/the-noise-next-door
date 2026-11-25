# Prompts: The Noise Next Door, final project pitch

`pitch/` · Assignment 8 · Draft v1, 24 Nov 2026

What was asked for, and what generated anything in the film.

## Generation in the film

- **The narration** is the only generated media. Kokoro-82M (`am_onyx`, local, through Brutalist's `runtime/scripts/generate_audio_kokoro.py`) reads each beat's `narration_text` from `beat_sheet.json` as written. There's no other prompt: the text is the input.
- **No images, video or music were generated for the film.** The boards are Brutalist's `GodotDesignBoard`, filled with props from `beat_sheet.json`. The gameplay is real play. The storyboard panel was drawn in code in Oct 2026 (STORYBOARD.md).
- **In the game the film shows,** the moth's sprite sheet is one I generated with Google Gemini, for Assignment 7 (CHANGE-BRIEF.md, the 22 Nov revision, has its prompt and file). It's on screen in B05, B01E and B09. B05's label says so, and so does the end card.
- **No Claude response is shown in the film.**

## My directions to Claude Code (23 Nov 2026)

Quoted as I typed them, in order. Claude Code's drafts in between are summarized, not quoted.

1. I pasted the assignment, with no words of my own. Claude Code read the repo and the toolkit's docs, and asked which project to pitch.
2. "No, the pitch needs to be about the entire game, not about just one section or like one thing. It needs to be about the entire game."
   Claude Code drafted PROJECT-BRIEF.md for the whole game.
3. "I dont wanna use brutalist waht is the video we wanna make ?"
   Claude Code laid out a film without Brutalist, and said the assignment asks for it.
4. "unknow what install tht tool lets see what it does"
   Claude Code installed Brutalist and rendered its smoke fixture (FRICTIONAL.md has what it took).
5. "Yes, use godot-gdd"
6. My answers to Claude Code's questions:
   - the role, "Gameplay programmer";
   - the games I've played, "Untitled Goose Game, Stray, Overcooked, Cuphead";
   - why, "Mostly learning";
   - the skills new to me this term: "Godot and GDScript, Blender modelling and rigging, Shaders and particles, Game animation and tests".

   Claude Code drafted the beat sheet, the boards and the shot list.
7. "What is needed for this? What is needed for the assignment apart from the movie?"
8. "The ending for the first phase is done almost. I'm working on the side for it, so we can claim, like we can say that it's on the first level is almost done. And it's not just a Windows game. I don't know why you're claiming that. It's a game in general. Would this not work in Mac?"
   Claude Code rewrote B01, B05, B07 and the brief: a desktop game for Windows and macOS, with level 1's ending in progress.
9. "Wait for the ending"
   The takes wait until the ending is committed.
10. "can u give me a script for notebookllm for this ? along with visial imgs tht can help help the model ?"
   Claude Code made the NotebookLM pack in `design/a8/notebooklm/` (an extra, not the course's film), and found that level 1's ending had been committed.
11. "Yes, update them"
    Claude Code updated B01 and B07 for the built ending, added B01E to show it, and updated the brief, FACTCHECK.md and SHOTLIST.md.
12. "Commit Scare first"
    Claude Code committed Scare a camper alone (`81c1df3`), apart from another session's cake gathering, after the whole test list passed on that commit in its own worktree.
13. "its done i have updated it", then "commited"
    The camp round the cake was committed (`370f62d`), and it's the revision the takes are recorded at. Claude Code ran the whole test list on it, added B01E's "the whole camp gathers round", and kept Godot from importing `pitch/` and `design/a8/` (`.gdignore`).
14. "yea i have checked the scripts its correct interpreations"
    The script's comparison, what's out, what comes first and the risk plan are confirmed.
15. "2 have done do u see the recording ?", then my console's output from run-02
    Neither take had been saved (no `pitch\capture\` folder), and Movie Maker had run the game at 2.5× real speed. The takes became screen recordings of the game at real speed.

## My directions to Claude Code (24 Nov 2026)

16. "Takes recorded", "only taken one", then "all 3 recordings have been saved"
    run-01 was the 23 Nov recording. run-02 and run-03 were recorded on 24 Nov (17:13 and 17:29), on game work that wasn't committed yet.
17. Two choices of Claude Code's, its recommendations: "Commit it now", for the day's game work the takes show; and "Use what's recorded", for B02 and B09
    Claude Code ran the whole test list on exactly the day's work, in its own worktree, and committed it (`263ac50`). It left out the brief's revision and code that take the cutscene out, which came after the takes. B02 became Scare a camper, re-voiced, and B09's footage became run-03's getaway.
18. "whats taking soo long for commiting man ?"
    The whole test list on the commit alone took about 20 minutes, the check that the commit holds what the takes show.
19. "also dont update the recorded vids in the repo"
    The takes, the clips, the voice and the film stay out of GitHub (`.gitignore`). The copies in `capture/` are byte for byte the recordings.
20. "if u need i will updated them in onedrive and get u the links"
    The takes aren't needed there. A link to the finished film may be, beside the Canvas ZIP.
21. "Looks good, commit", after watching the final
    B02's new line and the film are kept. Claude Code committed `pitch/` and the A8 records, and tagged it `a8`.
22. "Yes, push then", for pushing `main` and `a8` once the film's link is in the README
23. "remove the previous assignement names if u see them"
    The film's boards name commits and dates in place of the tags `a5`–`a7`, and B06's and B09's lines no longer say "tagged assignment". Re-voiced, re-rendered and rebuilt; the records keep the tags the assignment asks for.
24. "ok lets submit", then "what all vids we nned to upload give me all the paths", then the five OneDrive links
25. "People in Northeastern", the links' sharing setting
    The links went into README.md, with a note that they need a Northeastern sign-in.
