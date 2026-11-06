# 2026-11-06: One interact button in every place (Q39)

The lead chose Q39 A on 2026-11-06: Interact is F / B everywhere.

## Done

- The farm's own `farm_interact` action (Space / A) is gone; the farm and
  the farmhouse read the same `interact` action as Millbrook (F / B,
  device -1). Harvesting, the farmhouse door, the bed and the seed tin are
  all F / B now. Space / A stays the dodge in areas and does nothing at
  the farm.
- `farming.md`'s controls table and the help lines say so.
- CLAUDE.md's status paragraph, garbled by two earlier edits ("Next, The
  Clear spell..."), is put right.

## Checked

- `tools/run-tests.sh`: all pass. A new test presses `interact` at the
  farmhouse door through the InputMap and checks Space and A no longer
  interact; a deliberate break (the farm reading another action) failed it.
- Not verifiable here: whether F / B feels natural for farming:
  `docs/playtests/2026-11-06-interact-everywhere.md`.
