# 2026-11-06: One satchel for the game; the field book

The great fields' trace of the farm's past (`base.md`: "an almanac in the
field shelter") needed notes at the farm, and the satchel (Q37) belonged
to Millbrook's area. This makes the satchel the game's.

## Done

- **One satchel** (`GameState.satchel`): every note found anywhere, in the
  order found. An area being played shares the very same array, so
  Millbrook adds to it directly. Saved at the top of the save
  (`"satchel"`); saves from before take in the notes Millbrook remembered.
  An area's own save entry keeps only its own notes.
- **`Notes`** (`src/core/notes.gd`): every place's book of notes, looked up
  by id; the loose thread (Q37) follows the note's own place's objective,
  wherever it is read.
- **At the farm and in the farmhouse** (`NoteReader`): I / View opens the
  satchel, F / B reads the chosen note and puts it back, as in Millbrook.
  Time stands still while reading (`farming.md`).
- **The field book** (`FarmNotes`, a draft for the lead's taste): Interact
  facing the great fields' shelter, once open, reads it. Several hands over
  the years: the fields worked by nine and more, then by two, then left to
  rest. It lies on a stone by the shelter's doorway (painted with the
  ground).
- Review scene: `field_almanac` (the field book open).

## What broke, and how it was found

- **The render** showed the first field book running onto the paper's
  hint ("F / B: put it back"); `story.md` rule 5 says a note fits one
  screen. A new test lays out every note in the game as the note view
  does and checks it fits above the hint. A first version counted
  characters, which failed a Millbrook note that fits; a second compared
  line counts with the label's height, which never fails because the label
  grows with its text; the third compares the label's minimum height with
  the room left (`NoteView.TEXT_HEIGHT`), and catches the first field book
  exactly (needs 132 px of 126).
- **A deliberate break survived** (ignoring the press that put a note
  back), because the test let the button go on the tick it was pressed:
  `SceneTree.physics_frame` fires *before* the scene's own tick. Holding it
  for two ticks showed the guard itself was not enough (the held press
  read as new a tick later); Interact is now ignored until it is let go.
  A new rule in CLAUDE.md.
- Other deliberate breaks, all caught: the area keeping its own satchel;
  older saves' notes lost; the field book unreadable; time running while
  reading; an area saving every note; the satchel not saved.
- **Q40 verified:** the "Pull request cleanup" workflow ran on the merges
  of #41 and #42 and succeeded; only `main`'s artifacts remain.

## Checked

- `tools/run-tests.sh`: all pass.
- Render of the field book open, looked at.
- Not verifiable here: the field book's voice and reading notes at the
  farm: `docs/playtests/2026-11-06-one-satchel.md`.
