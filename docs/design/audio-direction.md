# Audio direction

- **Status:** Draft, for the lead's review.
- **Depends on:** Q3 (where audio comes from), Q9 (the calamity).
- **Binding constraints:** ADR-0005 (lonely tone, no characters, so no voices).
- **Cannot be verified headlessly:** the mix, loudness and how anything feels.
  All of that goes on playtest checklists.

## What the audio must make the player feel

The same four aims as the art: alone but not hopeless; the base is warm; someone
was here; small in a large world.

## Core rules

**Silence is material.** Most of the time there is no music. Ambience (wind,
insects, water, distant creaking) carries the world. Music is an event, so it
means something when it appears.

**No voices.** No dialogue, no humming people, no crowd sounds (ADR-0005). The
one exception worth considering is distant, unexplained sound that hints at the
past (a bell, a music box). Any such sound is a story decision for the lead.

**Home sounds different.** The base has the warmest, closest sounds: a fire,
footsteps on wood, animals, a door. Out in the world, sounds are more distant
and reverberant. Returning home should be audible.

**Distance changes the soundscape.** In step with the art rule, areas further
from the base sound more changed: fewer birds, odder textures. Exact form
depends on Q9.

**Combat is a separate state.** Fighting happens away from the base. Combat may
bring tension sound or sparse percussion, and it ends cleanly back into
ambience. Combat audio never plays at the base.

## Music

- A small set of themes rather than a soundtrack per area: a base theme (warm,
  simple, maybe a single instrument), an exploration motif that appears rarely,
  a discovery sting for notes and artefacts, and combat tension.
- Recommended delivery: layered stems, so the base theme can thin out or fill
  in at runtime instead of hard switching. Godot 4.7.2 has
  `AudioStreamSynchronized` and `AudioStreamInteractive`; their behaviour has
  not yet been verified and will be before the music system is built.
- Who writes it is Q3.

## Proposed bus layout (draft)

`Master` → `Music`, `Ambience`, `SFX`, `UI`. Each has its own volume setting in
the options menu. Reverb sits on `Ambience` and `SFX` so outdoor areas can feel
large and the base can feel close. Built in the first audio milestone; nothing
exists yet.

## Placeholder plan

- If Q3 is answered as recommended: CC0 recorded ambience for the base (wind,
  insects, a fire) and a few footstep and tool sounds, every file listed in the
  asset register with source and licence.
- Until then: no audio at all, which suits the game's tone.
