# 2026-10-10: Combat feedback, round two

**Asked (the lead, after playing):**
- Accept the guard-and-riposte rework of the greatsword's skill (Q30 A).
- Magic: the Siphon, but on the heavy button's hold instead of the skill;
  the Rot pool that was there is "rather boring" and needs a different
  mechanic: what are the options?
- Dodging with the other weapons must feel as responsive as magic's blink:
  a quick roll, or the blink for all.
- Bow stages: stage 1 like a normal attack, stage 2 slightly stronger,
  stage 3 pushes a little back and pierces. Volley fires at once and rains
  where it hits the first creature.

## Done

Details and values are in `docs/design/combat.md`.

- **Quick roll** (chosen over a shared blink, which would make magic's
  Wardstep the same as everyone's dodge): 240 ms, 40 px, cubic ease-out so
  most of the distance comes in the first frames, moving on the press tick,
  invulnerable from the first frame to 180 ms; its last 80 ms cancels into
  any action.
- **Guard and riposte:** Brace takes 30% of a hit; a hit in its first
  150 ms is a perfect brace (no damage, the attacker staggered and thrown
  back, the Riposte at once). Follow-through moved to heavy on a staggered
  creature in reach. The guard pose, a white ring in the perfect window, a
  flash and a heavier rumble are drawn and mapped.
- **Bow:** stages 1/2/3 as asked; the dodge shot is the stage-3 piercing
  arrow. Volley is one press: the arrow flies at once and the rain falls
  where it stops (a Volley that hits nothing rains where its arrow lands).
- **Siphon on heavy hold**, with a beam on release that carries the old
  Release burst and combinations, plus what each drained effect adds.
  Release is gone; the old Rot pool sits on the skill button as an interim.
- **Q31** written: four options for a new Rot mechanic, recommending a Rot
  seed that jumps when its host dies or is drained.
- Q29 and Q30 marked resolved.

## What broke, and how it was found

- **Objects leaked at exit.** After the riposte, the suite ended with
  "28 ObjectDB instances leaked". A player and a creature that had hit each
  other held each other in their hit lists, a reference cycle. Hit lists
  now hold instance ids. The message printed after the test runner had
  finished, so nothing failed; `tools/run-tests.sh` now fails the run on
  it, and a reintroduced cycle was confirmed to fail. Added to CLAUDE.md.
- **The beam killed its target and nothing bloomed.** In the magic review
  render, a beam with three full effects killed the first creature and
  skipped the Shatter and Blight bloom, unlike the old Release. The
  combinations now run even on a kill; a test covers it and fails on the
  old order. Added to CLAUDE.md under "Look at the renders".
- **The riposte panel showed nothing:** the panel's player stands
  elsewhere than the tests', so the lunge missed. The creature is now
  placed relative to the player.
- **Lost work, recovered:** checking the leak guard, I reverted two
  uncommitted files with `git checkout` and lost the sim and fighter
  changes. I redid them from the design and confirmed the same 266 tests
  passed; the branch is now committed at each step.
- Earlier on the branch: the first roll curve covered too little ground in
  its first ticks (made cubic, and moving on the press tick); the bow
  review sheet still used the removed mark.

## Checked

- Full suite: 276 passed, 0 failed, no leaks at exit.
- 24 deliberate breaks of the new rules, each failing its test (the
  roll's press-tick move, curve and cancel; first-frame iframes; guard
  damage, perfect window and its edge, riposte, stagger and Follow-through;
  each Siphon rule; the beam's combinations on a kill).
- Review renders at all ten sizes, checked at 1280×800, 1366×768,
  1920×1080 and 2560×1080: greatsword (guard and riposte), bow (stages,
  Volley) and magic (tether, beam with Shatter and Blight).

## Not done

- **Feel:** roll responsiveness, the perfect-brace window, the Siphon's
  rhythm and rumble can only be judged by playing:
  `docs/playtests/2026-10-10-combat-feedback-round-two.md`.
- **The Rot rework** waits for the lead's answer to Q31.
- Placeholder shapes only (as before); no new assets.
