# 2026-11-06: The pause menu

The lead asked for a pause menu, and chose Esc / Start to open it
(2026-11-06).

## Done

- **`PauseMenu`** (`src/core/pause_menu.gd`), in the farm, the farmhouse
  and Millbrook.
  - **Esc / Start** opens it: Resume, Back to title, Quit (Quit hidden on
    the web build).
  - The whole game stands still while it is open (`SceneTree.paused`): the
    clock, creatures, a fight in progress (`farming.md`: the clock pauses
    in menus).
  - It says when the game was last saved ("Last saved: Day 3, 06:00, in the
    farmhouse."), or that a place opened on its own is not saved.
  - Back to title and Quit ask first ("Anything since the last save is
    lost."), with "Keep playing" chosen first. There is no saving from the
    menu (ADR-0017).
  - Esc / Start or B closes it, or steps back out of the question; W / S,
    the arrows, D-pad and stick move; the mouse chooses by hovering.
  - It cannot open during the fade between places.
- **New input action `pause`:** Esc and the controller's Start (Menu)
  button, every controller (device -1).
- **`MenuStyle`** (`src/core/menu_style.gd`): the title's quiet menu lines,
  now shared by the title and the pause menu.
- `GameState.last_saved` records when and where the game was last saved or
  loaded.
- The help lines in every place show "Pause Esc / Start".
- Review scene: `pause_menu` (over the farm at dusk).

## What broke, and how it was found

- **The whole test run was left paused.** The new pause tests passed on
  their own, but the full suite then failed in the combat arena's tests
  ("about one tick per physics frame (got 0)"). The test that loads every
  scene once had loaded the pause review scene, which opens its menu,
  pauses the game and was freed still paused. A pause menu now unpauses
  the game when it leaves the tree, and a test covers it. A new rule in
  CLAUDE.md.
- **A deliberate break survived**: removing the "not while leaving" guard
  inside `open()` (input had its own guard); the test now calls `open()`
  directly too.
- Deliberate breaks, all caught: not pausing; leaving without asking; the
  game not put down on the way to the title; the last-saved line empty;
  Millbrook without the menu; B not closing it; not unpausing when freed.

## Checked

- `tools/run-tests.sh`: all pass.
- Renders of the pause menu at 16:9 and 32:9, looked at.
- Not verifiable here: the Start button on each controller, how pausing
  mid-fight feels: `docs/playtests/2026-11-06-pause-menu.md`.
