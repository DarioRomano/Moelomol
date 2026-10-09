# ADR-0010: The pet companion

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (answer to open question Q9, 2026-10-09)
- **Amends:** ADR-0005, point 4 ("No characters to meet"), which listed
  companions among the things that do not exist.

## Context

ADR-0005 says the player never meets another character and lists companions
as excluded. The lead's answer to Q9 (what was the calamity) introduces a pet
that lives on the farm and is, unknown to the player, an eldritch god. This is
a change to the game's core constraints, so it is recorded here.

## Decision

1. **There is one companion: the player's pet.** It is there from the start,
   lives at the base, and hangs out with the player and around the farm.
2. **It looks and behaves like a pet cat.** (The lead's answer centres on cat
   treats; the outward form is taken to be a cat.)
3. **It is secretly an eldritch god.** The player character does not know.
4. **It is why the base survived:** it enjoys the place.
5. **It is why the player survived:** the player is the only person who knows
   how to make the most delicious cat treats.
6. **The cat treats recipe is the first recipe,** unlocked from the start.
7. **It never speaks.** It is not a dialogue character. The rest of ADR-0005
   point 4 stands: there are no human characters, NPCs, merchants, quest
   givers or dialogue partners.
8. **Its true nature is learned only the ADR-0005 way:** through environmental
   hints and notes (point 5 is unchanged).
9. **It stays at the base.** Adventuring remains solitary.

## Consequences

- The game is lonely, but not alone: the player has a pet whose company is
  real and whose nature is the central mystery. The tone gains a thread of
  dark comedy (the world ended; you were spared for your cat treats).
- The base needs a pet: art (idle, wandering, sleeping, reacting), simple
  wandering behaviour, and reactions to the player. Nothing is built until a
  task asks for it.
- A recipe or cooking system must exist at least far enough to make cat
  treats from the start. How it relates to equipment crafting is not decided.
- Story hints about the pet must be woven into notes and environments across
  the whole game; `docs/design/story.md` holds the plan.
- Open questions created: what the calamity looked like and where monsters
  come from (Q13); whether feeding the pet does anything in play (Q14).
- Reversing this would remove the story's central secret; it would need a
  superseding ADR.
