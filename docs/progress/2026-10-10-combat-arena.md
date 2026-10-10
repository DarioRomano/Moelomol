# 2026-10-10: Combat test arena with the greatsword

## What was done

The lead approved the combat design recommendations (Q18 top-down ¾ →
ADR-0014; Q19 two weapons with a swap) and the first build step.

- **Combat simulation** (`src/combat/`): deterministic, stepped at 60 Hz,
  with movement and collision, dodge with invulnerable frames, stamina,
  poise and stagger, hyper-armour, a 100 ms input buffer, hit-stop, soft aim,
  lock-on with target switching, push with impacts (walls, pillars, other
  creatures), and the full greatsword: light chain, four position-dependent
  finishers, Follow-through, Brace and its instant counter. Two training
  creatures approach, telegraph and lunge; defeated ones fade and return.
- **Arena scene** (`scenes/combat/`): input from new InputMap actions (the
  ADR-0013 default bindings, any controller), drawing with placeholder
  shapes, HUD in the UI frame, static centred camera, rumble through a new
  haptics service. F5 render interpolation, F6 passive creatures. Reachable
  with F2 and `--start-scene combat_arena`.
- **Review render scene** `combat_poses`: six scripted moments; plus the arena
  at all ten screen sizes.
- 46 rule tests, 8 arena, binding and haptics tests (109 in the suite).
- ADR-0014; Q18 and Q19 resolved; new **Q20** (smoothing movement at 120 fps);
  combat design, architecture, CLAUDE.md, asset register, roadmap updated;
  playtest checklist `docs/playtests/2026-10-10-combat-arena.md`.

**Placeholder:** all combat visuals are shapes drawn in code (asset register).

This PR is built on the five open PRs #12–#16 (full resolution, ARM64 build,
overlay, decisions, combat design). Merge those first.

## What broke, and how it was found

- **Design flaw: the third light swing missed a standing creature.** Each
  swing's push carried it out of reach. Found in the combat poses render
  (panel 1 showed no swing). A test reproduced it (2 hits of 3); fixed by a
  6 px step forward per light swing, a new starting value.
- **Joypad bindings saved by the engine listened to controller 0 only**
  (`"device":0`). Found by reading the generated file; set to -1, and the
  binding test sends events from device 1.
- **Three of my first tests set up the wrong situation** (poise refilling
  during a windup; a creature out of the first swing's reach). Fixed the
  tests; the rules were right.
- **A one-degree gap behind 360° attacks** in the drawing (thin line in the
  spin-sweep render); full circles are drawn now.
- **`event_is_action()` ignores deadzones** (probed); the trigger test checks
  `is_action_pressed()` instead.
- My first engine probe of this session printed nothing: an untyped loop
  variable broke the project's typing rule.

## Test mutations (each confirmed to fail, then reverted)

Hyper-armour ignored; whole dodge invulnerable; finisher ignoring the chain;
chain never ending; buffer never expiring; no staggered bonus; no wall
impacts; no creature-to-creature impacts; soft-aim cone ignored; lock-on not
nearest; no hit-stop; Follow-through at any range; attack arc ignored; Brace
never readying; creatures never returning; attacks free; no combos from
recovery; endless creature stagger (first missed; a stagger-duration test was
added and catches it); no forward step; arena not stepping; F6 doing nothing;
haptics intensity ignored; rumble on controller 0 only; cleave mapped to the
light rumble; dodge button bound to controller 0 only; light bound to K.

## Not verified

How any of it feels, rumble, and Q20 on a 120 Hz screen: playtest checklist.
Performance with more creatures (two only so far).
