# D4 dev starter (proof of concept)

A voxel dragon on a grid, snake rules: Godot and Blender, driven from text, with the same task
habits as D3. The dragon moves and turns; food, growth, and collisions are yours to add,
in `core/session.gd`.

| You want to | Run | What happens |
| --- | --- | --- |
| Get the tools | `deno task setup` | Downloads pinned Godot 4.7.2 and only its web export template into `.tools/` |
| Make the art | `deno task art` | Runs `tools/build_art.py` with Blender as a Python library (`bpy`), writes `art/dragon_kit.glb` and `art/dragon_kit.blend` |
| Make the art on an Intel Mac | `deno task art:lts` | Same script, Blender 4.5 LTS |
| Check this computer | `deno task doctor` | Tries every step and prints a report to paste into Canvas |
| See the kit in the game's lighting | `deno task kit` | Every piece in a row, plus a sample dragon bending through turns |
| Play it | `deno task dev` | Runs the game in a native window |
| Open the editor | `deno task edit` | The graphical editor is still there when you want it |
| Look at the kit in Blender | `deno task blender` | Opens `art/dragon_kit.blend` in the Blender app, if installed (optional) |
| Check before commit | `deno task ci` | Boundary check, format check, lint, import, tests, web export into `dist/` |
| Check that `core/` stays engine-free | `deno task boundary` | Fails if a `core/` script extends a node or uses input, the scene tree, or the screen |
| See the web build | `deno task preview` | Serves `dist/` locally |

Once, before your first push: in your repository's **Settings > Pages**, set **Source** to
**GitHub Actions** (a repository made from a template does not inherit this). Then every
push to `main` runs `.github/workflows/deploy.yml`: the same `deno task ci` on GitHub, and a
deploy of `dist/` to Pages. The optional review bot
(`.github/workflows/review-bot.yml`, guided by `REVIEWBOT.md`) comments on each push
once you set it up; until then it shows a red X that says nothing about your code.

## Editor

Open this folder in VS Code and accept the recommended extensions
(`.vscode/extensions.json`):

- **godot-tools:** GDScript completion, hover docs, and go-to-definition. It starts a
  windowless Godot from `.tools/godot` (made by `deno task setup`), so no editor needs
  to be open. Format GDScript with `deno task fmt`, not this extension.
- **Python:** completion for `bpy` and `bmesh` in `tools/build_art.py`, from Blender 5.2
  stubs that `deno task setup` installs into `.tools/python-stubs`.
- **GLB Viewer:** click `art/dragon_kit.glb` to orbit the kit. `build_art.py` lays the
  pieces out in rows (dragon pieces, then tile kinds) just for viewers like this; the
  game uses only each piece's mesh, so the layout never affects play.
- **Deno:** for the TypeScript in `scripts/`.

### Blender's own window (optional)

`deno task art` needs no Blender app, but each run also saves `art/dragon_kit.blend` so
you can orbit, inspect, and try ideas in Blender itself: `deno task blender` opens it.
Install [Blender 5.2](https://www.blender.org/download/) (4.5 LTS on an Intel Mac), or
set `BLENDER=/path/to/blender`. The script looks in `/Applications` on a Mac, in
`Program Files\Blender Foundation` on Windows, and for `blender` on your PATH. If Blender
warns the file was written by a newer version, update to the newest 5.2.

The game reads only the `.glb`, and **`deno task art` overwrites both files**, so hand
edits to `art/dragon_kit.blend` vanish on the next run (that file is gitignored for the
same reason). To edit by hand, first **File > Save As** a copy such as
`art/my_kit.blend` (commit it if you like; `deno task blender art/my_kit.blend` reopens it),
then **File > Export > glTF 2.0** with: Format glTF Binary, file `art/dragon_kit.glb`,
no Limit to boxes ticked, Cameras and Punctual Lights unticked, +Y Up and Apply Modifiers
ticked. Keep the object names. The tradeoff: from then on the kit lives in that file, not
in the code, so later changes to `build_art.py` stop reaching it and reviewers cannot read
your edits in a diff. Do not run `deno task art` afterwards unless you mean to go back
to the code's kit. The docstring at the top of `build_art.py` repeats these steps.

`Cmd/Ctrl+Shift+B` runs `deno task ci`.

## Layout

- `DESIGN.md`: your target, your two menu choices, and the words your project uses. Your
  partner and the optional review bot read it to learn where you are headed.

- `project.godot`, `main.tscn`, `export_presets.cfg`: Godot's own config, plain text, editable by hand.
  `project.godot` is Godot's project settings file (INI-like: `[section]` and `key=value`). It
  is kept in the exact layout Godot's editor writes, so opening the editor changes nothing;
  the editor drops comments and any setting equal to Godot's default, so explanations live
  here instead. `import/blender/enabled=false` stops Godot from importing `art/*.blend`
  (the game loads only `art/dragon_kit.glb`, and that import would need the Blender app).
- `core/session.gd`: one run at the game. It owns the board and the dragon and ticks them; rules that
  involve more than the dragon (food, score, collisions) go here. No Nodes; tested headless.
- `core/dragon.gd`: the dragon's movement on the grid (heading, a turn queue). No Nodes; tested headless.
- `core/kit.gd`: which piece (head, straight, turn, tail) goes in each cell and how far to rotate it.
- `core/board.gd`: the tile vocabulary: which kind of tile is in each cell, and what each kind
  means to the rules (`Board.TILES`).
- `app/main.gd`: the engine adapter. Keeps the clock, ticks the session, draws the dragon with four
  shared meshes, and follows it with the camera.
- `app/stage.gd`: sky, sun, glow, fog, and one instanced mesh per tile kind.
- `tools/build_art.py`: Blender as code. The dragon kit is drawn as ASCII voxel layers; edit, run
  `deno task art`, replay. Its output: `art/dragon_kit.glb` (committed; the game loads it) and
  `art/dragon_kit.blend` (gitignored; for looking around in Blender).
- `tests/`: `*_test.gd` files, run by `tests/run_tests.gd` (a tiny runner, no plugin).
- `scripts/godot.ts`: finds Godot, and fails the task when Godot prints script errors.
- `scripts/check-boundary.ts`: the `core/` boundary gate (`deno task boundary`, part of `ci`).
- `scripts/blender.ts`: finds the Blender app and opens a `.blend` in it.

## Where this can go

The voxel art and plain rules are a starting point. The course staff keep a fully
realized version with every optional requirement implemented, glowing PBR art from
the same `build_art.py` structure, and effects driven by game events:
https://github.com/rndmcnlly/ember-dragon. Read it for ideas; AGENTS.md says more.

## Why `scripts/godot.ts` is strict

Godot exits with code 0 even when a script fails to parse, so a plain
`godot --headless ...` would let a broken commit pass CI. The wrapper watches
Godot's output for script errors and fails instead, and the test runner treats
an unloadable test file or zero tests run as failure.

## Why `core/` has a boundary check

Same gate as D3's `deno task boundary`, for GDScript. Every script in `core/` must
extend `RefCounted` (or `Object`, `Resource`, or another `core/` class) and must not
name nodes, the scene tree, input, or the screen (`Node`, `Node3D`, `get_tree`,
`Input`, `DisplayServer`, a `$Path`, and a few more; the list is at the top of
`scripts/check-boundary.ts`). Comments and strings are ignored, and reading files
with `FileAccess` is allowed, since levels and replays are data. The check reads text,
so it is simple rather than complete: it keeps the obvious leaks out, and review keeps
the subtle ones (rules drifting into `app/`) out. To see it work, add `extends Node3D`
to a file in `core/`, run `deno task boundary`, read what it says, and undo it. The
list is yours to tighten.

## First time on a new computer

You probably have git and Deno from earlier assignments; uv is new.

- **Mac:** run `xcode-select --install` first if `git --version` offers to install Apple's
  Command Line Tools (about 2 GB, about 5 minutes; if no window appears, click the
  installer icon in the Dock). Install [uv](https://docs.astral.sh/uv/getting-started/installation/),
  then **open a new Terminal window** so the shell finds it.
- **Windows (PowerShell):** `winget install Git.Git Microsoft.VCRedist.2015+.x64` (Blender's
  Python package needs the Visual C++ runtime), install [uv](https://docs.astral.sh/uv/getting-started/installation/),
  then **open a new terminal**: git and uv are not found in the one that installed them.
- **Linux:** see the table and packages below.

Check `git --version`, `deno --version`, and `uv --version`, then in your clone run
`deno task setup` and `deno task doctor`. The first `deno task dev` can sit on Godot's splash
screen for up to a minute while it prepares shaders. If macOS asks whether Terminal may
use the microphone, choose Don't Allow: the game does not need it.

## Requirements

Deno and uv.

**Downloads: about half a gigabyte, once per computer** (Godot 80 to 170 MB, Blender's `bpy`
package 250 to 400 MB; about 1.5 GB on disk). Use Wi-Fi such as eduroam or ResWiFi, not a phone
hotspot, for the first `deno task setup` and `deno task art`.
Set `GODOT=/path/to/godot` to use your own Godot 4.7.2 instead of `.tools/`.

| Platform | Godot tasks | `deno task art` |
| --- | --- | --- |
| Mac (Apple Silicon), Windows (x64 or ARM) | yes | yes |
| Mac (Intel) | yes | use `deno task art:lts` (Blender 5 dropped Intel Macs) |
| Linux x86_64, including x86 Chromebooks | yes | yes, after installing the libraries below |
| Linux ARM, including ARM Chromebooks | yes | no: Blender's Python package has no ARM Linux build |

On Linux (Debian, Ubuntu, Chromebook), install what minimal systems lack:

    sudo apt install libfontconfig1                       # quiets harmless Godot font errors
    sudo apt install libx11-6 libxrender1 libxfixes3 libxi6 libxkbcommon0 libsm6 libgl1   # for art

Run `deno task doctor` to try every step and print a report of what works on your computer.
