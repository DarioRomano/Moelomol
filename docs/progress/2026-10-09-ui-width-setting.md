# 2026-10-09: UI width setting (Q15)

## What was done

Lead's decision on Q15: 32:9 screens show the whole world (option A), and UI
elements can be held to 21:9 or 16:9 widths through a setting.

- `GameSettings`: player settings saved in `user://settings.cfg`; `ui_width`
  is `full` (default), `21:9` or `16:9`.
- `UiFrame`: HUD and menus go inside it; it narrows to the chosen width,
  centred, full height. "21:9" is defined as 43:18 (3440×1440), the widest
  common 21:9 panel, so the setting changes nothing on any real 21:9 monitor
  and on 32:9 matches what a 3440×1440 player sees.
- The test card's HUD (labels, corner markers, a teal frame outline) now sits
  in a UiFrame; the world (checkerboard, yellow edge) fills the screen.
- The render tool takes `--ui-width`; four extra renders per PR show the 21:9
  and 16:9 settings on 32:9 and 21:9 screens.
- 12 tests.

**Left out:** the options menu where the player changes the setting. No menu
exists yet; it comes with the first menu (Q6 decisions say how menus take
input). Until then the setting can only be changed by editing
`settings.cfg` or in the review renders.

## What broke, and how it was found

- **Only one corner marker showed in the renders**, at every UI width; the
  frame maths tests all passed. Probed the engine: `set_anchors_preset()`
  keeps a control's current size by rewriting its offsets, so a newly added
  control stays 0×0; `set_anchors_and_offsets_preset()` stretches it. Fixed in
  all four places that used it, added a test that puts the real test card in
  a 1280×360 viewport (seen to fail with the old call), and added the rule to
  CLAUDE.md.
- **My first viewport test was wrong**, not the frame: setting a size on a
  control already anchored to fill its parent adds to it (2560×720).

## Test mutations (each confirmed to fail, then reverted)

Setting ignored; "21:9" taken as 21/9 (840 px); frame not centred; change
announced on every set; settings file ignored; frame not listening for
changes; unknown file value keeping the previous setting; the
`set_anchors_preset` bug itself.

## Not verified

How the UI widths feel on a real 32:9 monitor (the lead has the decision;
renders only).
