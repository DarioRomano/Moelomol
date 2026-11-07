# 2026-11-07: Kettlebridge, the second area: design proposal

The lead chose Q43 A (a market town on the river) on 2026-11-07. This is
the design pass that follows: `docs/design/area-kettlebridge.md`. The lead
accepted it as proposed on 2026-11-07, Duke's herd included.

## Done

- The town: 128 x 72 tiles; the road in from Millbrook's ford; the market
  square with its stalls; the chandler's (the lantern, Q35 C); the coaching
  inn (the first note of `story.md`'s stage 2); the drovers' auction ring
  (the boss, Duke); the church and churchyard; the river with its lifting
  bridge drawn up (the objective), the barge and the island (places to come
  back to).
- The objective: lower the bridge with the bridge-keeper's key from his
  egg stall on the square. The boss is not on the way (`world.md`).
- Four new creatures from the archetypes `enemies.md` set aside for later
  areas (splitting rats, jackdaws that drop rats, river pike that spit from
  the water, Lichen-backs among the gravestones), and Duke, whose idea
  (running the round ring, the herd in phase two) differs from Grist's.
- Draft notes, and what the area gives.
- `docs/design/images/make_kettlebridge.py` draws the sketch and walks the
  map breadth-first before anyone looks at it.

## What broke, and how it was found

- The walk failed on the first draft: the island's marker sat in the river
  instead of on the towpath it is seen from, and both field hedges were two
  columns thick with a gap in only one, so the fields beyond them were shut
  in. Both fixed before the sketch was drawn. Looking at the sketch then
  showed the winch house fused into the corn exchange and the wharf drawn
  over the churchyard wall; both fixed.
- The map pasted into the doc by hand differed from the sketch by one row;
  it is now pasted from the generated text and compared.
