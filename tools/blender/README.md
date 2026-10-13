# Blender build scripts

For Assignment 3, every piece of Python that Claude Code runs in Blender through the MCP is copied here, so Git shows how each asset was built.

- **One file per asset:** `build_smore.py`, `build_pizza_slice.py` and `build_cooler.py`.
- **Inside each file:** the `execute_blender_code` calls, in the order they ran.
  - Each call is headed by a comment giving its number and what it did.
  - Calls that failed or were undone stay in the file, commented out and marked.
- **The export:** the code that writes the `.glb` goes at the end of the same file.
- **Not in these scripts:** my hand edit in Blender's window isn't Python, so it's described in [BLENDER-NOTES.md](../../BLENDER-NOTES.md). Re-running a script rebuilds the asset as it was before that edit.

The `.blend` sources and the exported `.glb` files live in `assets/props/`.

## Running a script without the window

On this machine (Windows, Git Bash):

```bash
"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python-exit-code 1 --python tools/blender/build_smore.py
```

`--python-exit-code 1` makes Blender exit with an error when the script raises one. Without it, Blender exits 0 even when the script fails.
