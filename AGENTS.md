# CMPM 121 student project agent instructions

Follow the current CMPM 121 syllabus and its AI policy. You may read this repository, answer in prose or pseudocode, use shell and git to help diagnose the environment or organize history, and run diagnostic tools. Do not write or edit project text files, including code, documentation, or configuration, even by shell command. Do not show generated whole lines or blocks of code to the student; a small expression is okay. Quoted external code needs a precise source URL. If you create a git commit, add an `Assisted-by: agent-name/model-id` trailer. The student authors the project files and makes design choices.

Playing the game is diagnosis, not authorship. Following the syllabus, you may operate
diagnostic interfaces without saving changes to project content: you may run, export,
and play the game, including writing throwaway scripts that enact inputs, kept outside
tracked files (for example in the gitignored `playtests/scratch/`). Prefer describing
how the student can run commands themselves; running them directly is acceptable.

## Notes for coding agents (and curious humans)

A Godot 4.7 + Blender (`bpy`) game driven entirely from text and `deno task`.
Read README.md for the task list. Ground answers in this project's files and in
version-matched official docs (Godot 4.7, Blender 5.2 Python API); link them.

### Map

- `core/`: the rules as plain GDScript (`RefCounted`, no Nodes). Tested headless by
  `deno task test`. Keep engine calls out of here. `session.gd` is one run (`Session`):
  it owns the board and the dragon, and rules that involve both belong there.
- `app/`: the engine adapter. `main.gd` keeps the clock, ticks the session, and draws the dragon;
  `stage.gd` builds sky, light, and tiles. It reads core state; it never decides rules.
- `tools/build_art.py`: all 3D art, as code. `art/dragon_kit.glb` is its output:
  regenerate it with `deno task art`, never edit it by hand. It also saves
  `art/dragon_kit.blend` (gitignored, rewritten every run) for `deno task blender`,
  which opens it in an installed Blender app (`scripts/blender.ts`). Godot's own
  `.blend` import is off in `project.godot`; the game reads only the `.glb`.
- `tests/`: `*_test.gd`, run by `tests/run_tests.gd`.
- `scripts/check-boundary.ts` (`deno task boundary`, first in `ci`): fails if a `core/`
  script extends a node or names the scene tree, input, or the screen. Text-based and
  deliberately simple; it does not catch rules drifting into `app/`.

### Conventions that are easy to break

- Godot exits 0 even when scripts fail to parse. Trust `deno task ci` (its wrapper
  fails on script errors), not Godot's exit code.
- Piece names are the contract between Blender and Godot: `PIECES`/`TILES` in
  `build_art.py`, `Kit.Piece` and `Board.TILES` in `core/`. Openings in
  `Kit.OPENINGS` must match how pieces are modeled.
- A new tile kind is three small edits: a row in `Board.TILES` (what it means to the
  rules), a builder in `TILES` (what it looks like), and, if you load levels from
  text, a legend character.
- Run `deno task fmt` before `deno task ci`; gdlint caps lines at 100 characters.

### Where this can go

The course staff keep a fully realized version of this game, with every optional
D4 requirement implemented and PBR art built the same way (`build_art.py` builders,
`pbr_material()` with emission): https://github.com/rndmcnlly/ember-dragon

It is large and its parts lean on each other, so read it for ideas and techniques
rather than lifting files. Its `build_art.py` shows what a builder can do beyond
`voxels()`; its `app/effects.gd` shows juice driven only by core signals.
