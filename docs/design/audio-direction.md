# Audio direction

- **Status:** Draft, for the lead's review.
- **Decided inputs:** Q3: music and ambience come from separate specialised AI
  tools, run by the lead, from the prompts in `audio-prompts.md`. Q9 → ADR-0010
  (the pet is secretly a god).
- **Still open:** sound effects source. (Q13 decided: monsters are wildlife
  changed by the god's presence, more so further from the base.)
- **Binding constraints:** ADR-0005 as amended by ADR-0010 (lonely tone, no
  human characters, so no voices).
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
from the base sound more changed: fewer birds, odder textures, and the
changed wildlife (monsters) more often heard than seen.

**The pet has a sound signature.** A short four-note motif that ends on an
"off" note lives quietly inside the base theme and the title music. Late in
the game it returns sounding enormous (`audio-prompts.md`, MUS-13), so the
player can hear the god where they expected the cat. **Proposal:** a
subliminal low drone plays only near the pet (AMB-03).

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
- Generated with AI tools by the lead from `audio-prompts.md`.

## Proposed bus layout (draft)

`Master` → `Music`, `Ambience`, `SFX`, `UI`. Each has its own volume setting in
the options menu. Reverb sits on `Ambience` and `SFX` so outdoor areas can feel
large and the base can feel close. Built in the first audio milestone; nothing
exists yet.

## Getting the audio

- The lead generates music and ambience from `audio-prompts.md` and hands over
  the files with the tool, prompt and licence terms; each goes in the asset
  register.
- Until files arrive: no audio at all, which suits the game's tone.
- Sound effects (footsteps, tools, UI) are not covered by the Q3 decision and
  will be raised when sound work starts.
