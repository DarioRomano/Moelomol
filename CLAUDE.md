# CLAUDE.md

Read this file before doing anything else in this repository. Then read the
`docs/` files relevant to your task. `docs/` is the project's memory: do not
rediscover what is written there, and do not contradict it silently.

## Project in one paragraph

Moelomol is a 2D farming and adventure RPG in Godot 4.7.2 for Windows, macOS and
Linux. One base where farming happens, peaceful and separate from fighting.
Exploration, foraging and combat happen outside the base and drive the story
forward by fulfilling objectives and unlocking areas. The player is the last
person left after a calamity and never meets another character; the story is
told only through the environment and notes. The binding version of these
constraints is ADR-0005 (`docs/decisions/0005-core-design-constraints.md`).

## Current status

Milestone 0 (foundation). There is **no Godot project, no gameplay, no tests and
no CI yet**. Do not invent gameplay systems speculatively; build what the task
asks for. See `docs/roadmap.md`.

## Commands

These do not exist yet. They are created in Milestone 1 and this section must be
updated when they land:

- `tools/run-tests.sh`: full headless test suite, needs no display.
- `tools/render-showcase.sh`: renders the visual review scenes to images.

Getting Godot 4.7.2 in a fresh Linux session (verified 2026-10-09; the GitHub
release page itself returns 403 through the session proxy, the asset download
works):

```sh
GODOT_DIR=/tmp/godot   # any directory outside the repository
mkdir -p "$GODOT_DIR" && cd "$GODOT_DIR"
curl -sSL -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -oq g.zip
./Godot_v4.7.2-stable_linux.x86_64 --version   # expect 4.7.2.stable.official.ed1daf0bf
```

Querying the engine headlessly (use this to verify any API before relying on it):

```sh
./Godot_v4.7.2-stable_linux.x86_64 --headless --path <project_dir> -s probe.gd
```

where `probe.gd` `extends SceneTree`, prints what you need in `_init()`, and
calls `quit()`. The release binary's `--doctool` output has **no descriptions or
deprecation notes**, only signatures and defaults; do not conclude "not
deprecated" from it.

## Workflow rules (ADR-0006)

- Never commit to `main`. Branch per change, open a PR against `main`, one
  coherent change per PR. (The initial commit was the one sanctioned exception.)
- Merge only when all four CI checks pass: Headless tests, Web build, Desktop
  export, Visual review renders. Branch protection is not configured; honour the
  gate by hand. Never skip, disable or quarantine a test to get green.
- Never force-push or rewrite history. Never rename the default branch.

## Ask the project lead before

- changing or superseding an ADR in `docs/decisions/`;
- changing level layout, balance, or the input model (incl. controller vs
  mouse/keyboard);
- changing base resolution, stretch mode, pixel/art scale or camera behaviour;
- adding an external dependency, addon, or commissioned art or audio;
- anything that alters the performance budget (ADR-0007);
- renaming the default branch, force-pushing, rewriting history.

When you hit a genuine fork, write it up in `docs/design/open-questions.md`
with pros and cons per option **and your recommendation**, then ask.

## Checking your work

- Run `tools/run-tests.sh` (once it exists).
- Touched anything visual: run `tools/render-showcase.sh` and **look at the
  images**, at more than one window size and aspect ratio.
- Wrote a test: break the code it covers on purpose and confirm the test fails.
- Used a Godot API: verify it against the running 4.7.2 engine, not memory or
  the web. Much published material is Godot 3 / early Godot 4 (KinematicBody2D,
  TileMap vs TileMapLayer, renamed settings). Record what you verified in the
  appendix of `docs/architecture.md`.
- Feel, input responsiveness, controller behaviour, audio mix and real-machine
  performance cannot be verified headlessly. Do not claim them; add them to a
  checklist in `docs/playtests/`.

## Documenting as you go

Every thread that changes something adds a note to `docs/progress/` (what was
done, what broke, how it was found). ADR for anything expensive to reverse.
Design doc for the consequences. Update `docs/roadmap.md` when a milestone moves.

## Conventions

- Language: statically typed GDScript (ADR-0003). Type every variable,
  parameter and return value. Follow the official GDScript style guide: files
  and folders `snake_case`, `class_name` in `PascalCase`, constants
  `CONSTANT_CASE`.
- Line endings LF (enforced by `.gitattributes`).
- Commit the `*.import` sidecar files; never commit `.godot/`.
- Placeholder art or audio must be labelled as placeholder in the progress note
  and in `docs/design/asset-register.md` (to be created with the first asset).

## Rules that have caught bugs

None yet. When a rule catches a real bug in this project, add it here with a
one-line note of the bug it caught.
