# The game's art and sound, made in code

**Thread:** 2026-11-12. The lead asked: "Create full assets (visual and
sound) for the game. Make sure they are consistent, but detailed." This
reverses Q2 and Q3 (art and music provisioned by the lead with AI tools), so
three things were asked first and answered: the assets count as **game art,
replaceable**; **assets first, then wire in**; sound covers **effects,
ambience and music**. Recorded in `open-questions.md` (Q2, Q3 amended).

Nothing in the game uses these files yet. The game still draws itself in
code; wiring in follows in separate pull requests.

## What was done

**Art: 288 images in `assets/`, 1.3 MB, made by `tools/art/build.py`.**

- One drawing library (`px.py`): an image is a grid of palette keys, so a
  colour outside the 27-colour palette cannot be written. Standard library
  only. Everything that stands on the ground gets the same one-pixel dark
  outline; grounds have none and stay low in contrast.
- **Ground** (`ground.py`): grass in four moods (farm, wild, changed,
  churchyard), paths, soils, cobbles, sawdust, wheat, mud, animated water;
  fringe and bank overlays so any two grounds can meet.
- **Nature** (`nature.py`): trees per mood, apple trees, willow, hedge,
  thicket, woods and wall blocks, fences and gates in warm and grey wood.
- **Buildings** (`buildings.py`): seven styles from the same 19 pieces, and
  composed landmarks. Warm styles are the farm's; the world's windows are
  dark, except the church's.
- **Props** (`props.py`): the farm, the farmhouse inside, crops in four
  stages, and each area's objects (the sluice, the stalls, the barge, the
  bridge).
- **The player** (`player.py`): a posed rig. Each pose is written once in
  the character's own terms (forward, right, up) and drawn facing south,
  north and east, so the figure is identical in every frame: 39 animations
  across unarmed, greatsword, hammer, bow and lantern.
- **Creatures** (`creatures.py`): the cat (with violet eyes at night),
  Millbrook's and Kettlebridge's creatures, Grist, and Duke with his herd
  (drawn ahead of being built). Eyes turn danger red in wind-up and attack.
- **Effects, icons, interface** and a **pixel font** drawn for the project
  (`effects.py`, `icons.py`, `ui.py`, `font.py`).
- `assets/art_manifest.json` gives every file's size, frame size and
  animations, for the wiring work and for replacing a piece later.
- Review sheets and two mock screens at the real 640 × 360 in
  `docs/design/images/assets/`; an engine-drawn showcase,
  `scenes/showcase/assets_sheet.tscn`, in the review renders.

**Sound: 159 files, 31 MB, made by `tools/audio/build.py`** (numpy, scipy
and ffmpeg at build time only; the game ships the rendered files).

- 134 effects (mono WAV): footsteps on four surfaces, every weapon and
  spell, the farm's spells, the cat, every creature, both bosses, each
  area's objective, the interface.
- 9 ambience loops (stereo Ogg): the farm by day and night, the hearth, the
  house, the layer near the cat (AMB-03), Millbrook and Kettlebridge by day
  and night. Fewer living sounds further from the farm.
- Music to the cue sheet in `audio-prompts.md`: MUS-01 base theme (with
  guitar and piano stems), MUS-02 sparse variant, MUS-10 title, MUS-11 six
  discovery stings, MUS-12 combat (three stems), MUS-13 the motif, wrong.
  The cat's motif is D, G, A, E flat.

**Not in this pull request: the audio files themselves** (Q44, open).
ADR-0011 puts audio through Git LFS and this environment's proxy refuses
LFS uploads. The generators are here; the rendered files were handed to
the lead as a zip to commit.

## How it was checked

- **Looked at**: every review sheet, both mock screens, and the engine's
  own render at 1920×1080, 1366×768 and 2560×1080.
- **Tests** (`tools/ci/test_assets.py`, `tests/unit/test_assets.gd`): every
  pixel is a palette colour; pure black and white only in the interface;
  the manifest matches the files; frames and animations fit their images;
  every creature kind has a sprite; the art rebuilds pixel for pixel from
  source; every folder is in the register; every image imports at its size;
  the font is a 10 px bitmap font.
- **Nine deliberate breaks**, all caught (an off-palette pixel, pure white
  in an icon, an image deleted, a generator edited without rebuilding, a
  wrong frame size, a creature without a sprite, the font's line height,
  an image resized, an import setting shrinking a texture).
- **Sound, measured (it cannot be heard here)**: loudness on the spec's
  targets (music −18 LUFS, ambience −24, peaks under −1 dB); every loop's
  seam smaller than the largest ordinary step in the file; the motif reads
  D5 G5 A5 E♭5 within a cent in MUS-01's piano stem and D4 G4 A4 E♭4 in the
  title; every effect checked for silence, clipping, DC offset and clicks
  at the ends.

## What broke, and how it was found

- **Every texture drew as a white block** in the first engine render. A
  texture loaded inside `_draw()` and not kept is freed when the function
  returns; the draw command holds only its RID, and the engine draws its
  white stand-in. Only the render showed it. The showcase now holds its
  textures; rule added to `CLAUDE.md`.
- **The first CI run failed with no detail.** The rebuild test compared
  PNG files byte for byte; the same pixels compress to different bytes
  under a different zlib build, so it passed here and failed in CI. It now
  compares pixels, and prints what differs as an annotation (the only CI
  output this environment can read).
- **The font's PNG page flips its import state.** Importing the `.fnt`
  re-marks the page as `importer="skip"`. A deliberate break that
  re-imported showed the engine test then failing to load it; the settled
  sidecar is committed and the test treats the page as part of the font.
- **Small props had clipped outlines and one wrong frame size**: drawn with
  no margin, so the outline had nowhere to go. The manifest test found it.
- **Market rats vanished on the cobbles** (grey on grey) in the
  Kettlebridge mock screen; now violet-grey.
- **The egg stall's awning used danger red**, which is reserved for
  monsters; now amber, which also marks it as the stall that matters.
- **The greatsword read as a stick** and clipped its frame; broader, shorter.
- **The bow vanished** when aimed toward or away from the viewer.
- **Ambience beds were hiss**: their spectrograms were evenly bright to
  8 kHz. Filters steepened; the high layers pulled down.
- **The base theme was 13% near-silence**; the brief asks for 30%. Longer
  rests and shorter ringing bring it to 23% by a strict measure (blocks
  17 dB under the cue's loudness). Still short of the brief; on the
  listening checklist.

## Limits, stated plainly

- Scripted pixel art is consistent and exact; it is not hand-drawn. The
  characters are the weakest part, as Q2 recorded. The lead judges.
- Synthesised wind, birds and guitar are the weakest sounds (Q3 recorded
  this too). Whether any of it sounds right cannot be judged here.
- Weapon enhancement variants, insides of area buildings and the third
  area have no art: none of them is designed or built.
