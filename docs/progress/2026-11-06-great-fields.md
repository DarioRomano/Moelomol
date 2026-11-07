# 2026-11-06: The great fields open with Grist's heart (Q42 A)

`base.md`'s build step 5. The lead accepted the great fields' structure as
sketched (Q42 A, 2026-11-06), with the render to be shown before merging.

## Done

- **The inside** (`FarmLayout.GREAT_FIELDS`, `opened_tiles`; the sketch now
  in `base.md`): nine strips of old field under long grass between
  hedgerows (`r`, a 1-tile hedge), the old track from the north gate as a
  4-tile path (moved 2 tiles east to meet the gate), the ruined field
  shelter (3 x 2 tiles of broken stone walls), and long grass where the two
  rows of thicket ran above the homestead's hedge. 2,800-odd tiles.
- **Opening** (Q38 C): Clear cast on any of the great fields' thicket (the
  buried old track included) with Grist's heart in the bag. The heart is
  used up and Clear's 2 Mana spent. The thicket withers back over 3 s,
  outward from the tile cast on, browning a band ahead of the front; the
  player stands and watches; the camera follows the front out to its
  farthest reach and comes back. A long, faint rumble. Without the heart,
  thicket is "too thick": nothing happens and nothing is spent. The heart
  opens only its own parcel, once.
- **The cat is already in the shelter** when it begins (`Cat.SHELTER`), and
  leaves later, unseen, as it does everywhere.
- Inside, Clear and Till work as on the homestead's old fields.
- **Remembered:** `"parcels_open"` in the farm's save entry; loading opens
  them at once. A game stored mid-withering counts the parcel as open (the
  heart is spent).
- **Drawing:** the farm's ground image is painted again only around the
  tiles that changed (`FarmGround.paint_cells`), and sent to the texture
  ten times a second while the thicket withers (`flush`), not the whole
  2560 x 1536 image every tick.
- Review scenes: `great_fields_withering` (halfway, from the north gate)
  and `great_fields_open` (the shelter, the cat, a strip begun).

## Left out, and why

- **The almanac** in the shelter: the farm has no way to show notes yet,
  and the satchel belongs to Millbrook's area (`Area.satchel`). It needs
  the satchel moved to the game and a note view at the farm; next.
- The other five parcels' insides are not designed.

## What broke, and how it was found

- **A haptics rule caught a design slip:** the first opening rumble (strong
  motor 0.2 for 3 s) outweighed the hammer's perfect strike, which a test
  keeps as the heaviest pulse in the game. It is now a faint 0.07 roll,
  which suits the farm better.
- **A deliberate break survived:** the old track buried under the thicket
  (`-`) not counted as the great fields, so Clear cast on it would never
  open them; the test now casts there too.
- Other deliberate breaks, all caught: the heart not used up; opening
  without the heart; the player free to walk during the withering; a game
  stored mid-withering losing the parcel; opened parcels not loaded; the
  track not path; the shelter's surroundings solid; the cat not in the
  shelter; the camera not following.

## Checked

- `tools/run-tests.sh`: all pass. A breadth-first walk of the opened
  fields from the farmhouse door reaches every strip, the track and the
  shelter, and never into another parcel or the woods.
- Renders of the withering and of the opened fields at 16:9 and 32:9,
  looked at.
- Not verifiable here: how the 3 s withering and the camera feel, the
  rumble, and the frame time while the texture updates on real machines:
  `docs/playtests/2026-11-06-great-fields.md`.
