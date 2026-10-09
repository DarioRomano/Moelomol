# Story

- **Status:** The premise is decided by the lead (Q9, ADR-0010). Everything
  marked **Proposal** is the engineer's suggestion for the lead to accept,
  change or reject.
- **Binding constraints:** ADR-0005 (no human characters, environmental
  storytelling only, lonely tone), ADR-0010 (the pet).

## The premise (decided)

A calamity has emptied the world. The player character is the last person
left, farming alone at a base that is mysteriously untouched. Their pet, a
cat, hangs out with them around the farm.

The pet is an eldritch god. The farm is unharmed because it enjoys the place.
The player is the only one left because they are the only person who knows how
to make the most delicious cat treats, which is the first recipe the player
has.

The player character does not know any of this.

## What the player knows, and what is true

| The player starts out knowing | The truth |
|---|---|
| Everyone is gone. | Everyone is gone because of the pet (exactly how is Q13). |
| The farm somehow escaped. | The pet likes it here. |
| They were lucky to survive. | They were kept, for the treats. |
| Their cat is a comfort. | Their cat is a god. It is also, genuinely, their company. |

## Tone

- **Lonely first.** The world is empty, quiet and beautiful.
- **A thread of dark comedy.** The reason the world ended around you is cat
  treats. This is never played as a punchline in text; the player gets the joke
  themselves when the pieces fit.
- **Cosmic, not cruel.** The god is not malicious. It is indifferent to
  everything except what it enjoys. No gore, no bodies (art direction).
- **The pet stays lovable.** Even after the player suspects, the cat is still
  the cat. The final feeling should be unsettled affection, not betrayal.

## Rules for writing notes and environmental hints

1. Notes are written by people from before the calamity, in their own voices,
   about their own lives. They do not explain the plot.
2. The pet never speaks and there is no text in its voice.
3. Never state the truth outright. Every hint must be explainable innocently
   on its own; only together do they point at the cat.
4. Hints about the pet are rare early and more frequent further from the base.
5. Every note is short enough to read in one screen at 640×360 (exact length
   limit decided when the note UI is built).

## How the truth comes out (Proposal)

Three stages, each tied to how far the player has travelled, so the reveal
follows exploration rather than a script:

1. **Ordinary loss.** Near the base: notes about daily life cut short; a
   vanished village; nothing about cats beyond the normal (a lost-pet poster,
   a child's drawing of a family cat).
2. **The pattern.** Further out: accounts of a stray cat seen in a town shortly
   before it emptied; old carvings and shrines to a small, many-eyed animal
   god; recipe scraps from people trying and failing to make "the treats it
   liked"; a note from someone who noticed that only places a certain cat
   visited were spared.
3. **The recognition.** The furthest areas: a record that the only survivor
   anywhere was a farmer known for their cat treats, and an image or object the
   player can match to their own pet (a marking, a collar, a habit). The game
   never says "your cat is a god"; the player knows.

At the base, in parallel: the pet occasionally does small impossible things
that are easy to miss (sitting somewhere it could not have reached; its shadow
not matching it for a moment; the ambience going briefly silent around it).

## Gameplay facts this creates (decided)

- The cat treats recipe is unlocked from the start (ADR-0010).
- The pet lives at the base and does not join adventures (ADR-0010).

## Open (see `open-questions.md`)

- Q13: what the calamity looked like, and where monsters come from.
- Q14: whether feeding the pet does anything in play.
