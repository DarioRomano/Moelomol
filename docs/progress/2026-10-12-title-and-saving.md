# 2026-10-12: The title screen and saving

The second of two pull requests for the lead's request (the first built the
farm). The lead chose: save when sleeping and at the gate, and one save
(2026-10-12). Recorded in ADR-0017.

## Done

- **The title screen** (`scenes/title/title.tscn`) is the main scene:
  - **Continue** when there is a save, with a line saying when and where
    ("Day 4, 18:40, in Millbrook"); it is chosen first.
  - **New game** starts at the farm, day 1, 6:00, and saves at once. Over
    an existing save it asks first ("Start a new farm? The saved one will
    be lost."), with "Keep it" chosen first.
  - **Quit** (hidden on the web build, where a page cannot quit).
  - Behind the menu, drawn in code: the farmhouse on its hill at dusk, one
    window lit, the cat on the roof.
  - Keyboard (arrows, W / S, Enter, Space, Escape), mouse (hover chooses)
    and controller (D-pad or stick, A, B).
- **Saving** (`GameState`): one JSON file, `user://save.json`, written
  through a temporary file. Saved on sleeping, on falling (waking in the
  farm bed), and on passing the gate either way. It resumes at the bed or
  at the gate of the place saved in.
- **A broken save** (unreadable, unknown format, unknown place) shows on
  the title as "The save could not be read: ..." with Continue greyed out;
  New game still asks before replacing the file.
- **The old boot scene** (the title text over the test card) is gone; the
  test card stays in the F2 list, and the title is first in it.
- **Review scenes:** the title, and the title with a save to continue.

## What broke, and how it was found

- **A controller could not press anything in a menu.** Godot 4.7.2's
  default `ui_accept` holds only Enter, keypad Enter and Space, and
  `ui_cancel` only Escape (probed). The project now adds A to `ui_accept`
  and B to `ui_cancel` for every controller (ADR-0013: every menu works
  with a controller). Tested with device 1.
- **The first title render** showed dark seams between the sky's bands
  (fractional band edges), a brown slab under the house (the window's
  light on the grass) and a cat lost against the roof. Bands now sit on
  whole layout pixels, the slab is gone, and the cat's eye catches the
  light.
- **Two test mistakes** on the first run: the round-trip test compared `1`
  with `1.0` (JSON keeps numbers as floats); the sleeping test stood the
  player one tile short of the door.
- **A deliberate break written wrongly** (it still renamed the file)
  survived; rewritten as a copy that leaves the temporary file, it was
  caught.

## Left out, and why

- **No pause menu**, so no "save and quit" or "back to the title" in play;
  closing the window quits, and progress since the last sleep or gate is
  lost (ADR-0017). A pause menu comes with the first options menu.
- **No options menu** on the title: no settings menu is designed yet
  (`GameSettings` notes the options menu comes with the first menu; this
  one has nothing to set yet).

## Checked

- `tools/run-tests.sh`: all pass.
- Deliberate breaks, all caught: the temporary file never replacing the
  save; the bag not loaded; the format not checked; the arrival lost;
  sleeping not saving; leaving Millbrook not saving; New game not asking;
  a broken save continuable; a new game not saved at once.
- Renders of the title at 16:9, 32:9, 4:3 and with a save at 16:10, looked
  at.
- Not verifiable here: that renaming over the old save works on Windows
  and macOS (verified on Linux), how the menu feels with each controller,
  and how the title looks on real screens:
  `docs/playtests/2026-10-12-title-and-saving.md`.
