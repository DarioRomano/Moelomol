# Audio prompts for AI music and ambience generation

- **Status:** First set, for the lead to run. Q3 decided 2026-10-09: music and
  ambience come from separate specialised AI tools, run by the lead.
- **Covers:** every area designed so far. Only one area is designed: **the
  base (the farm)**. Plus the cues that are not tied to an area: title,
  discovery, combat. New areas get their prompts here, using the template at
  the end, in the same PR as the area's design.
- **Follows:** `audio-direction.md` (silence first, home sounds warm, no voices)
  and `story.md` (the pet is secretly a god).
- **Cannot be judged by the engineer.** Whether a result sounds right is the
  lead's call; the acceptance notes under each prompt say what to listen for.

## How to use this document

Each cue has an ID (`MUS-…` for music, `AMB-…` for ambience). For each:

1. Paste the **Prompt** into the tool. If the tool has a separate negative or
   "exclude" field, paste the **Avoid** text there; otherwise append it as
   "Avoid: …".
2. Set the **Parameters** if the tool exposes them (length, tempo, key, loop).
   Most tools treat tempo and key as hints; that is fine.
3. Generate several takes, keep the best against the **Listen for** notes.
4. Export and name files as in the delivery spec, and record the asset (see
   "Licence and register").

Prompts are written for text-to-music and text-to-sound tools in general,
without relying on any one tool's syntax. Prompts are deliberately concrete
(instruments, tempo, texture) because "lonely" alone produces generic results.

## Delivery spec (all cues)

| | Music | Ambience |
|---|---|---|
| Format delivered | WAV, 48 kHz, 24-bit (the game converts to Ogg Vorbis) | same |
| Channels | stereo | stereo |
| Loudness target | about −18 LUFS integrated | about −24 LUFS integrated (it sits under everything) |
| Peaks | below −1 dBTP | below −1 dBTP |
| Loops | must loop seamlessly: no fade in or out, matching start and end | same; no single sound that is recognisable when it repeats |
| Stems | where the tool offers them, export separate stems as listed per cue | not needed |
| File name | `mus_<id>_<short-name>_take<N>.wav`, e.g. `mus_01_base-theme_take3.wav` | `amb_<id>_<short-name>_take<N>.wav` |

Loudness and loop points can be fixed after generation; send the best take
even if they are off, and say so.

## Licence and register (needed before anything enters the game)

Before the first file is committed, the lead confirms that the tool's terms
allow use in a commercially sold game, and whether they require credit. This is
a lead decision the engineer cannot check. Each file then gets a row in
`asset-register.md` with: tool and model/version, date, the exact prompt used,
seed if shown, and the licence terms.

## Shared style anchor

Append this sentence to every **music** prompt, after the cue's own text, so
all cues feel like one score:

> Intimate and sparse, recorded close with natural room tone, lots of silence
> between phrases, warm but lonely, like a small farm at the end of the world
> where one person still lives.

Shared **Avoid** list for every music cue (add the cue's own avoid text):

> vocals, choir, lyrics, humming, epic orchestra, cinematic trailer drums,
> EDM, trap hi-hats, electric guitar, bright synth leads, heroic brass,
> busy arrangement, wall-to-wall sound

## The pet's motif

One short melodic idea is shared across the score so that, late in the game,
the player can hear the god where they expected the cat. It is a sound
signature, not a plot statement.

- **The motif:** four notes, playful and slightly wrong: up a fourth, up a
  step, then down a tritone. In D: **D – G – A – E♭**, ending unresolved on the
  E♭ (outside the key).
- Text-to-music tools rarely follow exact notes. If the chosen tool accepts a
  melody or audio as input (humming, MIDI, a reference clip), use the motif that
  way. If not, accept any short four-note figure that ends on a note that feels
  "off", and use the same figure everywhere it is called for.

---

## Base (the farm)

The one warm, safe place. Peaceful: no combat ever happens here. The player
spends most of their time here, so these cues must survive hours of repetition.

### MUS-01 Base theme

- **Prompt:** Slow folk lullaby for solo fingerpicked nylon-string guitar,
  with a soft felt piano answering a few phrases later. Simple, singable
  melody; gentle major key with one borrowed minor chord that adds a touch of
  longing. Short phrases with long rests. No percussion. A quiet, playful
  four-note figure appears once in the piano: up, up, then down to a note that
  sounds slightly off.
- **Avoid:** (shared list) and: strumming, rhythm section, sad minor dirge.
- **Parameters:** 64–72 BPM; D major; 2:30–3:00; seamless loop.
- **Stems (if available):** guitar; piano; room tone.
- **Listen for:** you could leave it on for an hour; it feels like home, not
  like a menu; at least 30% of it is near-silence; the off-note figure is
  audible but not attention-grabbing.

### MUS-02 Base theme, sparse variant

Used when the player has been at the base a long time, so the theme can thin
out instead of repeating.

- **Prompt:** The same folk lullaby reduced to solo felt piano, very sparse:
  single notes and two-note chords, long pauses, a few fragments of the
  melody, as if remembered rather than played.
- **Avoid:** (shared list) and: full chords, continuous playing.
- **Parameters:** 60–66 BPM; D major; 2:00–3:00; seamless loop.
- **Listen for:** fits under the farm ambience without competing; sounds
  related to MUS-01.

### AMB-01 Base ambience

- **Prompt:** Calm outdoor ambience of a small farm in open countryside,
  daytime. Soft wind moving through tall grass and a few trees, a low bed of
  insects, one songbird calling every 10 to 20 seconds, the occasional creak of
  a wooden fence or gate, a faint trickle of water nearby. Close, warm, gentle.
  Completely empty of people.
- **Avoid:** people, voices, footsteps, traffic, cars, aircraft, machinery,
  farm machinery, dogs barking, roosters, music, distant towns, city hum, rain,
  thunder.
- **Parameters:** 3:00; seamless loop; stereo; quiet (−24 LUFS).
- **Listen for:** alive but uncrowded; nothing that tells you other people
  exist; no bird call or creak so distinctive that you notice it repeat.

### AMB-02 Base hearth (close loop for the warm light)

Plays only near the base's fire or lantern (the one warm light prop in the art
plan).

- **Prompt:** Close recording of a small wood fire in an iron stove: soft
  steady crackle, occasional gentle pop, a low warm rumble of the flame. Cosy,
  intimate, indoors-feeling.
- **Avoid:** roaring bonfire, wind, people, cooking sounds, music.
- **Parameters:** 1:00–2:00; seamless loop; stereo.
- **Listen for:** comforting at low volume; no loud pops that would startle.

### AMB-03 Near the pet (Proposal: subliminal layer)

A barely audible layer that plays only close to the pet. The player should not
consciously notice it at first; once they suspect the truth, they may realise
it was always there. Needs the lead's approval as a story device.

- **Prompt:** Very low, soft drone around 40–60 Hz, slowly breathing in and
  out over about 8 seconds, with a faint texture like a distant purr played
  slowed down, and an almost inaudible shimmer high above it. Calm, deep, not
  threatening. It should be felt more than heard.
- **Avoid:** melody, rhythm, horror stings, screams, growls, distortion,
  anything sudden.
- **Parameters:** 1:00–2:00; seamless loop; mixed far below AMB-01.
- **Listen for:** with AMB-01 playing at normal level, you cannot tell it is
  there unless you listen for it; on headphones alone it feels vast.

---

## Cues not tied to an area

### MUS-10 Title screen

- **Prompt:** Solo felt piano playing a slow, simple folk melody, very sparse,
  with soft wind in the background. The last phrase is a quiet four-note figure
  that ends on a note that feels slightly wrong, left unresolved before the
  loop.
- **Avoid:** (shared list).
- **Parameters:** 60 BPM; D major; 1:30–2:00; seamless loop.
- **Listen for:** sets the tone in ten seconds: alone, gentle, a little uneasy
  only at the very end.

### MUS-11 Discovery sting (a note or artefact found)

- **Prompt:** A short music-box or celesta phrase of three or four notes with a
  soft reverb tail, curious and a little melancholy, ending on an unresolved
  note.
- **Avoid:** (shared list) and: fanfare, triumphant, game "level up" sound,
  bright chimes.
- **Parameters:** 3–5 seconds; not looped; D major; quiet start, natural decay.
- **Stems:** not needed. Generate 5–8 variations so it does not repeat
  identically.
- **Listen for:** feels like finding something someone left behind, not like
  winning a prize.

### MUS-12 Combat tension (until adventure areas are designed)

Fights happen away from the base only. Generic until the first adventure area
is designed; then each area may get its own version.

- **Prompt:** Tense, restrained combat loop: low muted cello playing a short
  repeating ostinato, sparse frame drum hits, a few dissonant string harmonics
  above. Driving but small, like one person fighting alone in a quiet world,
  not a battle.
- **Avoid:** (shared list) and: epic, heroic, full orchestra, rock drums,
  metal, choirs.
- **Parameters:** 100–110 BPM; D minor; 1:00–1:30; seamless loop.
- **Stems (if available):** cello; percussion; harmonics, so intensity can be
  layered.
- **Listen for:** tension without bombast; stops cleanly into silence or
  ambience when the fight ends.

### MUS-13 The motif, wrong (later; not needed until the story's later areas exist)

For the late game, when the truth is close. Listed now so the motif is kept
consistent from the start.

- **Prompt:** The same playful four-note figure from the base theme, played on
  felt piano very slowly, then echoed by a deep, enormous, distant sound like a
  bowed metal sheet or a whale call, so the small tune seems to come from
  something huge.
- **Avoid:** (shared list) and: horror jump scares, screaming strings.
- **Parameters:** 40–60 seconds; not looped.
- **Listen for:** the player recognises the base's little tune, and it is
  unsettling, not scary.

---

## Template for a new area

Copy into this document when an area is designed (in the same PR as its design
document). Follow `audio-direction.md`: areas further from the base sound more
changed, with fewer living sounds.

```markdown
## <Area name>

<One paragraph: what the area is, how far from the base, what the player does
there, and what changed there in the calamity (see Q13).>

### AMB-<nn> <Area> ambience
- **Prompt:** <environment, time, weather, 3–6 specific sound sources with how
  often each occurs, distance and space (close, open, cave-like), the mood>
- **Avoid:** people, voices, traffic, machinery, music, <area-specific>
- **Parameters:** <length>; seamless loop; stereo; −24 LUFS
- **Listen for:** <what makes it right for this area>

### MUS-<nn> <Area> exploration motif (optional: most areas have no music)
- **Prompt:** <instrument, tempo, texture>, then the shared style anchor
- **Avoid:** shared list, plus <...>
- **Parameters:** <BPM; key; length; loop or one-shot>
- **Listen for:** <...>
```
