# 2026-10-10: Combat design draft and AI art prompts

## What was done

- **Q17** recorded (keep whole-number scaling), on the open decisions PR's
  branch, which this PR builds on.
- `docs/design/combat.md`: first combat design from the lead's brief:
  - shared foundation: default controls under ADR-0013, aiming without a
    mouse (soft aim, lock-on), stamina, dodge, poise and stagger, hit
    feedback, timing on 60 Hz ticks, a shared stacking-effect system;
  - **greatsword** (light chain with four position-dependent finishers, push
    and wall impacts, Follow-through on staggered creatures, Brace);
  - **hammer** (charge with a sweet spot, Overstrain, Rhythm stacks narrowing
    the window, armour break, triple-signalled sweet spot fitting the
    DualSense trigger prototype);
  - **bow** (quick shot, three-stage draw with clean releases, dodge shot,
    Flow stacks, multi-stage Volley, crafted arrowheads applying effects);
  - **magic** (Smoulder, Chill, Rot; one delivery per button; Release cashes
    in all stacks with multipliers per effect type and three combinations;
    Wardstep and Focus reward avoiding damage while applying);
  - weapon combinations, enemy roles, progression hooks, haptics table,
    proposed starting values, a suggested first build step.
- `docs/design/combat-art-prompts.md`: workflow (concepts, then assets at 8×
  downscaled and palette-mapped, then key poses), delivery spec, licence
  rule, style anchor and avoid list, design rules, and 17 prompts (4
  concept sheets, 9 asset sheets, 5 key-pose sheets).
- New open questions: **Q18** (camera perspective) and **Q19** (one or two
  weapons equipped). The draft assumes the recommended answers.
- Art direction, asset register, roadmap and docs index updated.

No code. Nothing is built.

## Interpretations (lead to confirm)

- "Applying caching in multiple stacks" read as **cashing in** stacks (the
  Release mechanic).
- Magic's source is the god's influence through changed materials, so it is
  the only player-side thing in violet. A story proposal, not decided.
- Basic arrows unlimited; crafted arrowheads are the limited extra.

## What broke, and how it was found

Nothing broke. One gap found: **the camera perspective was never decided**
(Q18), although art and combat depend on it.

## Not covered

Combat sound effects (the sound-effects source is still open), creature
designs and their art (with each area), healing, death, skill trees.
