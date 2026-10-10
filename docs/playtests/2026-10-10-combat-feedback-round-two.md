# Playtest: combat feedback, round two

**For:** the project lead. **Why:** these are your changes after the second
play (the roll, guard and riposte, the bow stages and Volley, the Siphon).
The rules are tested and the review sheets show the moments, but whether
they *feel* right can only be judged by playing.

**Build:** the PR build of `combat-feedback-round-two`; the combat arena
(F2 from the title). F7 changes the weapon not in hand; F6 makes the
creatures passive for practice.

**Setup:** machine, screen, controller or keyboard.

## Checks

Write a short note for each: fine / problem (what).

1. **The roll (greatsword, hammer, bow):** does it answer the press as
   quickly as magic's blink? It is shorter (0.24 s), goes further (40 px,
   the blink's distance) and is invulnerable from its first frame to
   0.18 s. Does a lunge you roll through at the last moment pass through
   you? Result:
2. **Rolling into an attack:** press light or heavy near the end of a roll.
   Does the attack come out straight away, without a felt pause? Result:
3. **Guard:** with the greatsword, press the skill a little before a lunge
   lands. Is it clear that the guard took most of the hit (a third of the
   damage, a grey ring)? Result:
4. **Perfect brace and Riposte:** press the skill just before the lunge
   lands (the guard's first 0.15 s, its ring drawn white). The creature
   should be thrown back staggered and the riposte should swing at once,
   with a flash and a heavy rumble. Is the window fair: too tight, too
   generous? Is it obvious when you got it? Result:
5. **Follow-through on heavy:** stagger a creature, then press heavy next to
   it. Do you get Follow-through when you expect it, and the chain finisher
   when the creature is too far? Result:
6. **Bow stages:** do stage 1 (an ordinary arrow), stage 2 (slightly
   stronger) and stage 3 (pierces, pushes a little) now feel like one
   weapon getting stronger rather than three different ones? Is stage 3's
   push noticeable? Result:
7. **Volley:** one press looses the arrow and the rain falls where it hits
   the first creature. Does the delay before the rain (0.4 s) feel right,
   and does it land where you meant it? Result:
8. **Siphon (magic, hold heavy):** stack effects on a creature, then hold
   heavy facing it. The tether forms after a quarter second and pulls one
   stack of each effect every 0.2 s; the beads round the lantern show what
   you hold. Is it satisfying to drain and let go? Is 1.5 s too long or
   short? Does it pick the creature you meant (the lock target, else the
   nearest in front)? Result:
9. **The beam:** letting go fires a 160 px beam. The first creature takes
   the burst and the combinations; creatures behind it take half. Does the
   payoff read clearly? Too strong against a group? Result:
10. **Risk of the Siphon:** being hit while holding it loses what was
    drained. Fair, or too punishing? Result:
11. **Siphon rumble (controller):** a pull that grows with what is drained,
    a tug at each pull, a pulse on the beam. Too much, too little? Result:
12. **Interim Rot pool on the skill:** this is a stand-in until you pick its
    rework (Q31). Anything that gets in the way meanwhile? Result:

## Report back

Notes per check; tuning changes come back as a PR with the new values for
your approval. Q31 (the Rot rework) is in `docs/design/open-questions.md`.
