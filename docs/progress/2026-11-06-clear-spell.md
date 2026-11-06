# 2026-11-06: The Clear spell

The lead asked for the house and the pause menu, then for the engineer to
pick further steps from the roadmap. The next step in `base.md`'s build
order is step 3: the Clear spell and the homestead's old fields. Clear is
fully decided (Q38; `farming.md`: 2 Mana, long grass to grass).

## Done

- **Clear**, a farming spell at the farm, after Till and Water in the spell
  list (Q / E, LB / RB). 2 Mana per tile, cast on the tile in front.
  - **The old fields** (`:`, about 180 tiles west and east of the path):
    cleared ground is ready to till. The first growth beyond the first
    field without leaving home (`base.md`).
  - **Long grass elsewhere** (`,`): it becomes lawn, which is not for
    tilling.
  - Short grass, paths, the first field and thicket: nothing happens and no
    Mana is spent, as with every spell. Opening thicket with a boss's heart
    is step 5, not built.
- The farm remembers cleared tiles, between visits and in the save (a
  `"cleared"` list in the farm's entry; older saves have none).
- Drawing: cleared ground is short grass over the painted long grass; on
  the old fields a faint line of the old furrows still shows. The cast
  lifts bits of cut grass from the target.
- Review scene: `farm_cleared` (10:00, a strip of old field cleared, part
  tilled and sown, Clear mid-cast).

## A reading of the design, to confirm

`farming.md` says Clear turns "long grass" into "grass, ready to till".
The homestead map has two kinds: the old fields under long grass (`:`) and
plain long grass (`,`) along the hedges and the pen. The engineer read "ready to till" as meaning the
old fields only, so the lawn stays lawn and the farmable land is the fields
`base.md` describes. If the lead wants every patch of long grass tillable,
it is one line (`FarmSim.clear_tile`).

## What broke, and how it was found

- Nothing broke. Deliberate breaks, all caught: cleared ground not
  tillable; clearing the same tile twice charging again; thicket and grass
  clearable; Clear missing from the spells; lawn tillable; cleared tiles
  not saved; Clear free of Mana.

## Checked

- `tools/run-tests.sh`: all pass.
- Render of the cleared old fields, looked at.
- Not verifiable here: how clearing a patch feels, and whether 2 Mana a
  tile paces the old fields well: `docs/playtests/2026-11-06-clear-spell.md`.
