# Kettlebridge, stage 2: its creatures

**Thread:** 2026-11-07. Builds stage 2 of `docs/design/area-kettlebridge.md`
("Creatures, zone by zone", accepted with the design). Each kind is one of
`enemies.md`'s archetypes with one new idea; starting values, as Millbrook's
were (balance is the lead's call after the playtest).

## What was done

- **Market rats** (Swarmer that splits): a heavy hit that does not kill
  splits one into two **rat runts**, which scatter, then come back at you.
  A split counts as a defeat (back the next morning); runts never come
  back and never split again.
- **Jackdaws** (Flyer that drops creatures): circle like rooks; at their
  first dive they let go of a runt instead, beside the player on the bird's
  side, never inside a wall; then they dive as rooks do.
- **River pike** (Artillery from water): under the river they cannot be
  hit or locked on to. With the player in sight they surface and spit a
  jet at the marked spot, then lie at the surface 1.5 s, where arrows, and
  a light swing from the towpath's edge, reach them. Nothing moves a pike:
  no push from hits or ripostes, no shoving by other fighters
  (`CreatureBrain.rooted`).
- **Lichen-backs** (Ambusher among gravestones): stooks' rules, drawn as a
  gravestone until they rise; the churchyard's real gravestones are drawn
  by the same function, so the disguise is exact.
- **Moths** at night at the church end of the high street and at the lit
  windows.
- **The roster** by the zone table. By day: 16 market rats in four packs,
  2 jackdaws, 4 Lichen-backs, 2 pike: 24 on the roster. The doc says "about
  35 by day"; I read that as counting what the rats split into and the
  jackdaws drop (up to 34 runts). At night: 8 rats, 6 Lichen-backs, 3 pike,
  5 moths.
- **Review renders:** a pose sheet of the new kinds
  (`kettlebridge_creature_poses`); the overview with the day roster.

## What broke, and how it was found

- One rat of the square's first pack stood on a stall; the reachability
  test found it.
- A deliberate break (a jackdaw's drop not kept out of walls) survived the
  first wall test, which put the player where the unresolved spot was open
  ground anyway. The test now stands the player against a house front and
  first asserts the unresolved spot is inside the house. All nine breaks
  are now caught.

## Left out

- Duke and the herd (stage 3).
- Two things the accepted doc puts in town that neither stage 1 nor stage 2
  built: the lantern at the chandler's (place 4, Q35 C) and the seed
  merchant's stall (G, new crop kinds). Both touch other systems (magic's
  weapon being found, farming's crop list), so they are their own pieces of
  work; listed in the roadmap.
