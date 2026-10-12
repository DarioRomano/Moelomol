# ADR-0017: One save, written when sleeping, falling and at the gate

- **Status:** Accepted
- **Date:** 2026-10-12
- **Decided by:** Project lead (2026-10-12: "sleep and passing the gate",
  "one save"; the format and file are the engineer's call)

## Context

The lead asked for a title screen that starts at the farm or at the last
save, and for saving. A save format is expensive to change once players
have saves: every later build must read it or convert it. ADR-0016 already
says saving records which place the player is in and what each place
remembers.

## Decision

1. **One save.** The title offers Continue (when there is a save), New game
   and Quit. A new game over an existing save asks first; the safe answer
   is chosen by default.
2. **When:** quietly, with no save menu, when the player
   - sleeps (the farmhouse door, for now the bed);
   - falls in an area (Q36: waking in the farm bed is a night's sleep);
   - passes the farm's south gate either way.
   A new game is saved at once, so Continue finds it.
3. **What it resumes:** the place and how the player arrives there: the
   bed (after sleeping or falling) or the gate (after travelling). A save
   never holds a position in the middle of a place, so a loaded game always
   starts at a safe, known spot.
4. **Format:** one JSON file, `user://save.json`, with a `"format"` number
   (1). It holds the clock, Mana, the bag, the place and arrival, the
   farm's changed tiles and what each area remembers
   (`GameState.to_dict()`). JSON because it is readable when a save needs
   checking by hand, and it reads the same on every platform.
5. **Safety:** the save is written to `save.json.tmp` and then renamed over
   the old one, so a crash mid-write leaves the previous save. A save that
   cannot be read, has an unknown format, or names an unknown place is
   reported on the title and never loaded or overwritten without asking.
6. **Places opened on their own** (F2, `--start-scene`, tests) play an
   unsaved game and never touch the save.

## Consequences

- Progress since the last sleep or gate is lost if the game is quit; a
  trip to Millbrook is never lost.
- Every change to what the game remembers must keep loading format 1
  saves, or raise the format and convert old saves when reading them.
- Creatures' health and positions are not saved: arriving at a place
  builds it fresh from what it remembers (ADR-0016).
- Reversing to several slots means a slot list on the title and one file
  per slot; the format would not change.

## Verification

`tests/unit/test_saving.gd`: a played game comes back exactly; the old save
is replaced with no temporary file left; an unsaved game never writes;
broken, unknown-format and unknown-place saves are refused with a reason;
sleeping, the developer sleep key, leaving either way and falling each save
with the right place and arrival; the title's Continue, New game, the
confirmation and a broken save.
