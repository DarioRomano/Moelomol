# CLAUDE.md

Read this file before doing anything else in this repository. Then read the
`docs/` files relevant to your task. `docs/` is the project's memory: do not
rediscover what is written there, and do not contradict it silently.

## Project in one paragraph

Moelomol is a 2D farming and adventure RPG in Godot 4.7.2 for Windows, macOS and
Linux. One base where farming happens, peaceful and separate from fighting.
Exploration, foraging and combat happen outside the base and drive the story
forward by fulfilling objectives and unlocking areas. The player is the last
person left after a calamity and never meets another person; the story is
told only through the environment and notes. The one companion is the
player's pet cat, which never speaks and is secretly the eldritch god that
caused the calamity (ADR-0010, `docs/design/story.md`); the player is spared
because they make the best cat treats. The binding constraints are ADR-0005 as
amended by ADR-0010.

## Current status

Combat prototype. Beyond the foundation (test-card title, headless tests,
review renders, PR builds and releases), there is a **combat test arena**
with the shared combat foundation, all four weapons (greatsword, hammer, bow,
magic), the status-effect system, armour and the two-weapon swap
(`docs/design/combat.md`).
There is no other gameplay: no farming, exploration or story. Do not invent
gameplay systems speculatively; build what the task asks for. See
`docs/roadmap.md`.

## Commands

```sh
GODOT="$(tools/install-godot.sh | tail -n 1)"; export GODOT   # editor only
GODOT="$(tools/install-godot.sh --templates | tail -n 1)"     # plus export templates (1.3 GB download)

tools/run-tests.sh                   # full headless suite (GDScript + CI-script tests), no display
tools/run-tests.sh --filter palette  # only tests whose "path::name" contains the text
tools/render-showcase.sh [out_dir]   # renders showcase scenes at 10 screen sizes (needs xvfb-run)
tools/export.sh windows macos linux linux-arm64 web   # runnable zips in dist/ (linux-arm64: test build)
tools/smoke-run.sh dist/Moelomol-dev-linux.zip   # start the exported Linux build for 120 frames
```

All tools use `$GODOT` (default `godot` on PATH) and refuse any engine other
than 4.7.2.stable.official (`tools/check-godot-version.sh`). The GitHub release
*page* returns 403 through this environment's proxy; the release *asset*
downloads used by `install-godot.sh` work.

Querying the engine headlessly (do this to verify any API before relying on it):

```sh
"$GODOT" --headless --path <project_dir> -s probe.gd
```

where `probe.gd` `extends SceneTree`, prints what you need in `_init()`, and
calls `quit()`. The release binary's `--doctool` output has **no descriptions or
deprecation notes**, only signatures and defaults; do not conclude "not
deprecated" from it.

From this environment you can read PRs and check results through the GitHub
REST API (`gh api repos/DarioRomano/Moelomol/...`; `gh pr` commands fail
because GraphQL is blocked), but **not** Actions job logs. That is why every tool
prints failures as `::error` annotations: read them with
`gh api repos/DarioRomano/Moelomol/check-runs/<id>/annotations`.

## Layout

| Path | What |
|---|---|
| `project.godot` | Engine settings (ADR-0008 display, Compatibility renderer, typing as errors) |
| `export_presets.cfg` | Presets `Windows Desktop`, `macOS`, `Linux`, `Web`, `Linux ARM64` (test build); names are used by CI |
| `scenes/boot/` | Main scene: title over the test card (no gameplay yet) |
| `scenes/combat/` | Combat test arena and its HUD |
| `src/combat/` | Combat rules as a deterministic 60 Hz simulation (`CombatSim`), weapons (`Weapon` subclasses), moves, drawing |
| `scenes/showcase/` | Scenes rendered for visual review (test card, renderer feature check); add new ones to `tools/render-showcase.sh` |
| `src/` | Game code (`class_name` scripts). `src/art/palette.gd` is the draft palette; `src/core/dev_tools.gd` is the in-build performance overlay (F3) |
| `tests/runner/` | Test runner and `TestCase` base class |
| `tests/unit/` | Tests: `test_*.gd`, methods `test_*`, extend `TestCase` |
| `tools/` | Scripts above; `tools/ci/` holds CI-only helpers and their Python tests |
| `.github/` | Workflows, the `setup-godot` composite action, PR template |

## Workflow rules (ADR-0006)

- Never commit to `main`. Branch per change, open a PR against `main`, one
  coherent change per PR. (The initial commit was the one sanctioned exception.)
- Merge only when all five CI checks pass: Change notes, Headless tests, Web
  build, Desktop export, Visual review renders (ADR-0009). Branch protection is
  not configured; honour the gate by hand. Never skip, disable or quarantine a
  test to get green.
- Every PR description fills in `## Change notes` (it becomes the release
  notes). Every new feature comes with tests in the same PR.
- Every merge to `main` publishes a release automatically. Do not create
  releases or tags by hand.
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

- Run `tools/run-tests.sh`.
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

- Language: statically typed GDScript (ADR-0003, accepted). The project
  treats untyped declarations as parse errors. Type every variable,
  parameter and return value. Follow the official GDScript style guide: files
  and folders `snake_case`, `class_name` in `PascalCase`, constants
  `CONSTANT_CASE`.
- Line endings LF (enforced by `.gitattributes`).
- Audio, art source files and video go through Git LFS (ADR-0011; patterns in
  `.gitattributes`). Run `git lfs install` once per machine. CI fails any
  tracked file over 1 MiB outside LFS, and any LFS-type file committed raw.
- Commit the `*.import` and `*.uid` sidecar files Godot writes next to assets
  and scripts; never commit `.godot/`. Delete the `.uid` of any script you delete.
- Placeholder art or audio must be labelled as placeholder in the progress note
  and in `docs/design/asset-register.md`. Every asset in the repository is listed there.

## Rules that have caught bugs

When a rule catches a real bug in this project, add it here with a one-line
note of the bug it caught.

- **Look at the renders.** The first renders showed the test card's scale
  readout was wrong (2.13x at 1366×768 when the real scale was 2x) and that the
  darkest palette swatches vanished into the background. Tests had passed.
- **Fail a test on any logged error, not only on assertions.** A GDScript
  runtime error aborts the function silently and the test would otherwise
  pass. The runner hooks the engine's `Logger` for this; keep it.
- **Run the real export, not just the tests.** The first macOS export failed
  (Apple Silicon needs ETC2/ASTC import enabled); nothing else would have
  shown it.
- **Render a scripted pose of every new move.** The combat poses render
  showed the third light swing whiffing (each swing's push carried a standing
  creature out of reach), a design flaw no rule test was written for.
- **Controller bindings made in code must use device -1.** The engine saves
  joypad events with device 0 (first controller only); a test with device 1
  catches it.
- **Use `set_anchors_and_offsets_preset`, not `set_anchors_preset`, to make a
  control fill its parent.** `set_anchors_preset` keeps the control's current
  size (a new control stays 0×0); only the renders showed it (one corner
  marker instead of four on the UI-width test card).
- **Check what a tool actually returns.** `DisplayServer.screen_get_image_rect`
  returns an empty image under Xvfb in 4.7.2; `screen_get_image` works.
