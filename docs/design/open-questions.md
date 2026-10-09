# Open questions

Decisions waiting for the project lead. Each has options with pros and cons and
the engineer's recommendation. When the lead decides, record the answer here
(date and choice), move the substance into an ADR or design doc, and mark the
question **Resolved**.

Status at 2026-10-09 (after the CI pull request): Q1 and Q10 resolved; Q5 and
Q8 are applied as working assumptions in the Godot project until the lead
decides; Q12 is new.

| # | Question | Blocks | Status |
|---|----------|--------|--------|
| Q1 | Base resolution, tile size, stretch and scale mode | M1, M2 | **Resolved** → ADR-0008 |
| Q2 | Where the art comes from | M2 | Open |
| Q3 | Where the music and sound come from | M2 | Open |
| Q4 | Performance budget values (ADR-0007) | M1 CI budget checks | Open |
| Q5 | Renderer | M1 | Open (working assumption: A) |
| Q6 | Input model | Player movement (later) | Open |
| Q7 | Is the web build a shipping platform? | Nothing yet | Open |
| Q8 | Approve ADR-0003 (typed GDScript) | M1 | Open (working assumption: approve) |
| Q9 | What was the calamity? | M2 art direction detail | Open |
| Q10 | Merging docs-only PRs before CI exists | Docs PRs | **Resolved**: CI PR went first |
| Q11 | Plain git or Git LFS for binary assets | First large assets | Open |
| Q12 | Start fullscreen or windowed? | Release builds people judge | Open |

---

## Q1. Base resolution, tile size, stretch and scale mode

**Resolved 2026-10-09:** the lead accepted the recommendation (C with the
stretch settings below). Recorded in ADR-0008, with what the first renders
showed.

Pixel art needs one fixed internal resolution, scaled up by whole numbers so
every art pixel becomes the same number of screen pixels. Everything else
(tile size, character size, UI, how much of the world is visible) follows from
it. Expensive to change once art exists.

Setting names verified in 4.7.2 (see architecture appendix):
`display/window/size/viewport_width|height`, `display/window/stretch/mode`
(`disabled`, `canvas_items`, `viewport`), `display/window/stretch/aspect`
(`ignore`, `keep`, `keep_width`, `keep_height`, `expand`),
`display/window/stretch/scale_mode` (`fractional`, `integer`).

Integer scale factors at common screens (window size ÷ base, rounded down):

| Base | 1280×720 | 1920×1080 | 2560×1440 | 3840×2160 | 1280×800 (Steam Deck) | 2560×1600 (MacBook) | 16 px tiles visible |
|---|---|---|---|---|---|---|---|
| 320×180 | 4 | 6 | 8 | 12 | 4 | 8 | 20 × 11 |
| 480×270 | 2 (border) | 4 | 5 (border) | 8 | 2 (border) | 5 (border) | 30 × 17 |
| 640×360 | 2 | 3 | 4 | 6 | 2 | 4 | 40 × 22 |

**A. 320×180, 16 px tiles**
- Pro: very chunky, readable pixels; least art per screen; fills all common
  16:9 screens exactly.
- Con: only 20 × 11 tiles visible, which makes a farm feel cramped and works
  against wide, empty vistas; inventory, crafting and note-reading UI get very
  tight; pixel text at this size limits how much a note can show.

**B. 480×270, 16 px tiles**
- Pro: a middle ground in detail and view size.
- Con: does not scale to 1440p or 720p by a whole number, so common screens get
  borders or blur.

**C. 640×360, 16 px tiles** (recommended)
- Pro: whole-number scale on 720p, 1080p, 1440p and 4K; 40 × 22 tiles visible,
  which suits both a farm layout and wide lonely views where the character is
  small in an empty world; room for readable notes and crafting UI.
- Con: more art needed per screen; characters are small (about 16 × 24 px), so
  silhouettes must be designed carefully to read.

**Stretch settings that go with it (recommended):** `stretch/mode = viewport`
(the game renders at 640×360 and is scaled up, so nothing can sit between art
pixels), `scale_mode = integer` (no blurry fractional scaling), and
`aspect = expand` (16:10 screens such as MacBooks and the Steam Deck show a
little more world instead of black bars). Consequence: UI must anchor to screen
edges, and level framing must not depend on an exact view size. The exact
behaviour of `integer` + `expand` together must be confirmed with showcase
renders at several window sizes in Milestone 1; not yet verified.

**Recommendation:** C with the stretch settings above.

## Q2. Where the art comes from

Adding external art or commissioning art needs the lead's approval. The
engineer can draw pixel art only with code (scripts that write PNGs pixel by
pixel), which is fine for shapes, palettes, tiles and layout tests but will not
reach final quality, especially for characters and expressive scenes.

**A. Code-generated placeholder art** (Python standard library only, scripts
in `tools/art/`, every image regenerated from source)
- Pro: no dependency, no cost; starts now; the palette is enforced by the
  script, so placeholders already obey the art direction; shows scale,
  readability and layout on screen.
- Con: will look like placeholder art; cannot prove the final mood; mostly
  thrown away later.

**B. Openly licensed (CC0 or similar) pixel art packs**
- Pro: better looking quickly; free or cheap.
- Con: external dependency requiring approval and a licence register; packs are
  generic and used by many games, which weakens identity; mixing packs breaks
  visual coherence; few packs fit a post-calamity farm.

**C. Commission a pixel artist**
- Pro: a coherent, distinctive look, which is the main carrier of mood
  alongside music.
- Con: cost and scheduling; needs Q1 and the art direction settled first so the
  brief is precise.

**D. The lead (or someone the lead chooses) draws the art**
- Pro: full creative control.
- Con: depends on that person's time; needs a tool choice (Aseprite is paid;
  Pixelorama and LibreSprite are free).

**Recommendation:** A now, so Milestone 2 can show the palette, scale and base
layout on screen and test the art direction; then C (or D) for final art, using
the Milestone 2 renders and `art-direction.md` as the brief. Avoid B except
perhaps for short-lived reference.

## Q3. Where the music and sound come from

**A. Code-synthesised placeholders** (Python standard library writing WAV
files, or Godot's `AudioStreamGenerator`, which exists in 4.7.2)
- Pro: no dependency; lets the bus layout and "silence first" mix structure be
  built now.
- Con: synthetic ambience (wind, birds, rain) sounds poor; synthetic music will
  not carry the mood.

**B. Openly licensed (CC0 or similar) sound libraries** for SFX and ambience
- Pro: real recorded wind, insects, rain, footsteps at high quality for free.
- Con: external dependency requiring approval and a licence register; library
  music is generic.

**C. Commission a composer (and possibly a sound designer)**
- Pro: music is the strongest single tool for loneliness; a unique score.
- Con: cost; works best once there is something to score against.

**Recommendation:** for SFX and ambience, B (CC0 only, every file listed in an
asset register with its source and licence), with A for UI clicks until
approved. For music, C, started once the art direction and a first scene exist.
Until then the game is deliberately quiet: ambience only, which fits the tone.
Whatever the source, music should be delivered as separate layers (stems), so it
can be thinned and thickened at runtime (`AudioStreamSynchronized` and
`AudioStreamInteractive` exist in 4.7.2; their behaviour is not yet verified).

## Q4. Performance budget values (ADR-0007)

Proposed values, for the lead to accept, change or reject:

| Item | Proposal |
|---|---|
| Minimum spec | 4-core CPU from about 2017; Intel UHD 620-class integrated GPU; 8 GB RAM; SSD |
| Frame rate | 60 fps sustained on minimum spec at 1080p |
| Frame time split | gameplay logic ≤ 4 ms, rendering ≤ 8 ms, headroom ≥ 4 ms |
| RAM | ≤ 1 GB in play |
| Loads | cold start ≤ 5 s; base ↔ area transition ≤ 2 s |
| Install size | ≤ 500 MB |
| Automatic in CI | logic time per simulated in-game day and peak memory, measured headless; rendering on real hardware via playtest checklist |

- Pro: modest numbers that suit a 2D pixel game and keep old laptops and the
  Steam Deck viable.
- Con: no real hardware has been measured; the numbers are educated guesses
  until a playtest on the lead's machines.

**Recommendation:** accept as a starting budget, to be revisited after the
first real-machine playtest.

## Q5. Renderer

**Working assumption since 2026-10-09:** the Godot project uses option A so it
could be created. Switching is one setting while there is no content. The
feature check is still to do.

Godot's web export always uses the Compatibility renderer
(`rendering/renderer/rendering_method.web` defaults to `gl_compatibility`); the
desktop default is Forward+ (`forward_plus`). Both verified in 4.7.2.

**A. Compatibility everywhere** (recommended)
- Pro: the Web build check and the desktop build render the same way, so visual
  review renders represent both; widest hardware support (older integrated
  GPUs); a 2D pixel game needs little that the other renderers add.
- Con: some rendering features differ between renderers. Which 2D features (if
  any) would be lost in 4.7.2 has **not been verified**; this must be checked
  before accepting.

**B. Forward+ on desktop, Compatibility on web**
- Pro: the full desktop feature set.
- Con: two rendering paths; the web check no longer proves the desktop look;
  higher minimum GPU.

**C. Mobile renderer on desktop**
- Pro: lighter than Forward+.
- Con: same split-path problem as B, with no clear benefit for this game.

**Recommendation:** A, subject to a feature check in Milestone 1 that confirms
no needed 2D feature is missing.

## Q6. Input model

**A. Keyboard and mouse only**
- Pro: simplest UI; least testing.
- Con: excludes the Steam Deck and players who prefer controllers; a relaxed
  farming game is commonly played on controllers.

**B. Keyboard and mouse plus full controller support** (recommended)
- Pro: covers every desktop setup including the Steam Deck (Linux).
- Con: every menu needs focus navigation; more playtesting; controller feel can
  only be checked by a human.

**C. Controller first**
- Pro: one well-tuned control scheme.
- Con: mouse users are second-class in inventory and crafting screens.

**Recommendation:** B. All input goes through named InputMap actions from day
one, never raw keys. Controller behaviour goes on playtest checklists.

## Q7. Is the web build a shipping platform?

**A. CI-only build check** (recommended)
- Pro: proves the export pipeline works without committing to web-specific
  support (browser saves, audio unlock on first click, download size).
- Con: if web shipping is wanted later, those issues arrive late.

**B. Ship a web version (for example a demo)**
- Pro: easy for people to try.
- Con: browser save storage, audio autoplay rules and load size become
  requirements now.

**Recommendation:** A for now.

## Q8. Approve ADR-0003 (statically typed GDScript)

**Working assumption since 2026-10-09:** the project is typed GDScript with
untyped declarations as errors. ADR-0003 stays Proposed until the lead answers.

The brief does not name a language. The engineer proposed GDScript with static
typing (see the ADR for the reasoning). The alternative, C#, needs the .NET
build of Godot and the .NET SDK in CI, and its web export support in 4.7.2 has
not been verified.

**Recommendation:** approve ADR-0003.

## Q9. What was the calamity?

Not stated in the brief. The answer decides the visual language of the world,
what the notes talk about, and why monsters exist. It is a creative decision for
the lead; options are offered only to make the choice concrete.

**A. The Vanishing:** people disappeared, the world is intact and overgrowing.
- Pro: half-finished lives (set tables, unpicked fields) are strong
  environmental storytelling; no gore; nature reclaiming the land suits a
  farming game.
- Con: does not by itself explain monsters.

**B. A spreading blight:** something poisoned the land and made the monsters.
- Pro: explains monsters and gives each area a visible "how far did it spread"
  gradient.
- Con: on its own, risks a generic "corruption" look.

**C. Physical cataclysm** (fire, earthquake, falling sky)
- Pro: dramatic ruins and strong landmarks.
- Con: ruins and ash are hard to make lonely rather than bleak; destroys the
  quiet, intact-but-empty feeling.

**Recommendation:** a combination of A and B: the people vanished and a blight
spread through the wild lands, but did not reach the base. This explains why
the base is peaceful and fighting happens elsewhere (ADR-0005 point 2), and it
gives a clear visual rule: the further from the base, the more the land has
changed.

## Q10. Merging docs-only PRs before CI exists

**Resolved 2026-10-09:** the lead asked for CI first, so the CI pull request was
the first one and every later PR gets the checks (option A in effect).

ADR-0006 requires four CI checks to pass before merging, and those checks do
not exist until Milestone 1.

**A. Make the CI pull request the next one, and hold other PRs until it has
merged** (recommended)
- Pro: the gate is never bent; the waiting window is short.
- Con: documentation PRs wait.

**B. Allow the lead to merge docs-only PRs by hand until CI exists**
- Pro: no waiting.
- Con: a second exception to the rule.

**Recommendation:** A.

## Q11. Plain git or Git LFS for binary assets

**A. Plain git** (recommended for now)
- Pro: no extra tooling for anyone cloning; CI is simpler.
- Con: the repository grows forever with each revision of large files.

**B. Git LFS**
- Pro: keeps the repository small as audio and art accumulate.
- Con: an external dependency; GitHub applies storage and bandwidth quotas to
  LFS that CI downloads use up; adding it later means rewriting history or
  starting LFS from that point onward.

**Recommendation:** A until the repository approaches about 500 MB, then
revisit. Pixel art PNGs are small; music is the main growth risk.

## Q12. Start fullscreen or windowed?

Found while writing the first playtest checklist. With whole-number scaling
(ADR-0008), a maximised window on a 1920×1080 monitor is a little shorter than
the screen (taskbar, title bar), so it drops from 3x to 2x and shows wide black
bars. The game currently starts in a 1280×720 window and has no fullscreen
option. The setting is `display/window/size/mode`; its values have not yet been
verified against the engine.

**A. Start in fullscreen** (recommended)
- Pro: every common monitor shows the game at full size with no bars (3x at
  1080p, 4x at 1440p, 6x at 4K).
- Con: needs a way out (an options menu or a key), which touches the input
  model and needs your approval.

**B. Start windowed at 1280×720** (current)
- Pro: friendly for development and for small laptop screens.
- Con: first impression is small, and maximising gives bars.

**C. Start windowed at the largest whole multiple that fits the screen**
- Pro: no bars, still a window.
- Con: more code, and window decorations differ per platform, so it needs
  testing on all three.

**Recommendation:** A, with fullscreen toggled by an options menu when the
first menu is built, plus the platform-standard shortcut (to be confirmed
under Q6).
