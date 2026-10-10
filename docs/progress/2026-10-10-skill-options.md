# 2026-10-10: Options for the magic and greatsword weapon skills

**Asked:** the magic weapon skill "is not quite satisfying, as it is too
similar to the ice AoE left by blinking", and the greatsword skill "is hard
to understand: does it even work? What other options do we have?"

## Done

- Checked both skills in the simulation with a probe (a creature lunging
  at the player, the player bracing at eight different moments; Release on
  a creature with no stacks). Findings:
  - **Brace works:** ticks 20–40 of the 42-tick telegraph catch the lunge
    and arm the counter.
  - **But Brace changes nothing visible:** full damage either way; the
    stagger protection never matters against one lunge; the armed counter
    is shown only as debug text.
  - **Release on a creature without stacks** does 0 damage.
- Wrote up **Q29** (magic: Unravel chain detonation, Siphon, thrown orb;
  recommended Unravel) and **Q30** (greatsword: guard and riposte, bull
  rush, keep but show; recommended guard and riposte) in
  `open-questions.md`, with pros, cons and the probe's numbers.

## What broke and how it was found

Nothing changed in the game. The probe confirmed the lead's impression:
Brace's effect is real but has no feedback, and the button's two meanings
depend on a hidden condition.

## Not done (and why)

Nothing is built: replacing a weapon skill is the lead's design call
(Q29, Q30).
