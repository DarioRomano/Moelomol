# Kettlebridge, stage 1: the town and the bridge

**Thread:** 2026-11-07. Builds stage 1 of `docs/design/area-kettlebridge.md`
(accepted by the lead 2026-11-07, "Accept and build").

## What was done

- **The town, walkable.** `KettlebridgeMap` (the accepted 64 × 36 map, kept
  in code and tested against `docs/design/images/kettlebridge.txt`) and
  `Kettlebridge` (its notes, the key, the winch, exits, the church's night
  lights). `AreaMap` now takes each area's solid characters and its barrier
  (Millbrook's floodwater `w`, Kettlebridge's raised bridge `Y`).
- **One area scene.** Millbrook's scene became `scenes/world/area_scene.gd`;
  `millbrook.gd` and `kettlebridge.gd` only name their area. What differed
  per area moved into `Area`: the HUD name, the line said when the objective
  clears, the lines for things taken. `Area.interact` now answers
  `"opened"` / `"stuck"` for any mechanism (the sluice, the winch) instead
  of `sluice_opened` / `sluice_stuck`.
- **The roads.** Millbrook's ford leads to Kettlebridge once the meadow
  drains; Kettlebridge's road north leads back. `GameState.travel` now
  records where the player came from (`came_from`, saved), and an area puts
  the player at the matching entrance (`Area.entrances`): from Millbrook,
  at the top of Kettlebridge's road facing south; from Kettlebridge, at
  Millbrook's ford facing north. The bridge south is an exit once lowered;
  the third area is not built, so it says so in a developer line.
- **The objective.** Arthur's key in the egg stall's cash tin; the winch
  house locked without it; with it, the bridge lowers over ten seconds
  (the same timing as Millbrook's drain), drawn as two leaves coming down.
  Arthur's note carries the loose thread until then.
- **Seven notes** (drafts, in `KettlebridgeNotes`), in the satchel's book.
- **Drawing** (placeholder): cobbles, stalls, sawdust and the rostrum, the
  churchyard and graves, the winch house, the barge, the lifting bridge.
- **Review renders:** the town on arrival, the overview, the bridge half
  down, the churchyard at night. F2 / `--start-scene kettlebridge`.

## What broke, and how it was found

- The barge drew as two boats, one per map row, and the raised north leaf
  covered most of the towpath. Both seen in the renders; the barge is now
  drawn whole, the leaf shorter.
- Three Millbrook tests used the old event names and the old `south` exit;
  updated with the rename.
- Deliberate breaks, all caught: the barrier character, the winch needing
  nothing, Millbrook's ford entrance removed, travel not saying where from,
  the bridge exit open while raised, arriving facing the wrong way, the
  save forgetting where the player came from.

## Left out (later stages)

Creatures (stage 2) and Duke with the herd (stage 3). The buildings have
no insides, so their notes are at their doors, as in Millbrook.
