# Open questions

Decisions waiting for the project lead. Each has options with pros and cons and
the engineer's recommendation. When the lead decides, record the answer here
(date and choice), move the substance into an ADR or design doc, and mark the
question **Resolved**.

Status at 2026-10-10: every question so far is resolved.

| # | Question | Blocks | Status |
|---|----------|--------|--------|
| Q1 | Base resolution, tile size, stretch and scale mode | M1, M2 | **Resolved** → ADR-0008 (amended: 21:9, 32:9) |
| Q2 | Where the art comes from | M2 | **Resolved**: placeholders now, art provisioned later |
| Q3 | Where the music and sound come from | M2 | **Resolved**: AI tools run by the lead; prompts in `audio-prompts.md` |
| Q4 | Performance budget values (ADR-0007) | First gameplay system | **Resolved** → ADR-0007 (test approach: Q16) |
| Q5 | Renderer | M1 | **Resolved**: Compatibility everywhere → ADR-0012 |
| Q6 | Input model | Player movement, first menu | **Resolved**: all recommendations → ADR-0013 |
| Q7 | Is the web build a shipping platform? | Nothing yet | **Resolved**: validation only, never shipped |
| Q8 | Approve ADR-0003 (typed GDScript) | M1 | **Resolved**: approved → ADR-0003 |
| Q9 | What was the calamity? | M2 art direction detail | **Resolved** → ADR-0010, `story.md` |
| Q10 | Merging docs-only PRs before CI exists | Docs PRs | **Resolved**: CI PR went first |
| Q11 | Plain git or Git LFS for binary assets | First large assets | **Resolved** → ADR-0011 |
| Q12 | Start fullscreen or windowed? | Release builds people judge | **Resolved**: fullscreen → ADR-0008 |
| Q13 | What the calamity looked like; where monsters come from | Art and audio of adventure areas | **Resolved**: B + C → `story.md` |
| Q14 | Does feeding the pet do anything in play? | Crafting/recipe design | **Resolved**: tutorial recipe; feeding = story moments → `story.md` |
| Q15 | How much world should 32:9 screens show? | First level layout | **Resolved**: show it all + UI width setting → ADR-0008 |
| Q16 | How to check the performance budget without a minimum-spec machine | First gameplay system | **Resolved**: 5800X + Steam Frame (B, C) |
| Q17 | Whole-number or fractional scaling, now that rendering is full resolution? | Nothing urgent | **Resolved**: keep whole-number |

---

## Q1. Base resolution, tile size, stretch and scale mode

**Resolved 2026-10-09:** the lead accepted the recommendation (C with the
stretch settings below). Recorded in ADR-0008, with what the first renders
showed. **Addition (lead, 2026-10-09):** 21:9 and 32:9 screens at 1080p and
1440p are supported targets; ADR-0008 amended with how they display. How much
world 32:9 should show is Q15.

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

**Resolved 2026-10-09:** option A. Placeholders made in code now; the final art
will be provisioned later by the lead.

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

**Resolved 2026-10-09:** none of the options below. Music and ambience will be
made with separate specialised AI tools, run by the lead. The engineer writes
and maintains the prompts for each designed area in
`docs/design/audio-prompts.md`. Sound effects (footsteps, tools, UI) are not
covered by that decision and remain open until sound work starts.

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

**Resolved 2026-10-09:** the lead accepted the CPU pairing (i5-7400 /
Ryzen 5 1600) with the GTX 1050 Ti and the 120 fps target; the table below
is now ADR-0007's values, except the macOS and Steam Deck rows, which the
lead dropped. How the budget is checked is Q16.

**Lead's direction (2026-10-09):** ideally 120 fps on a GeForce GTX 1050 Ti.
The lead asked for more guidance before deciding. This section explains what
that target means for this game, proposes a complete budget built around it,
and lists the few answers still needed.

### What "120 fps on a 1050 Ti" means here

- **8.3 ms per frame, everything included.** At 60 fps a frame may take
  16.7 ms; at 120 fps, half that. Game logic, physics, preparing the frame and
  the GPU all have to fit in 8.3 ms, every frame, or the game visibly stutters.
- **The GPU is unlikely to be the problem.** The game draws at 640×360
  (about 0.23 million pixels; ADR-0008) and then scales the finished picture
  up, which is a single cheap copy even at 5120×1440. A 1050 Ti (2016,
  4 GB) runs the Compatibility renderer (OpenGL 3.3, Q5) comfortably. The GPU
  risks are effects added later: many lights, full-screen shaders, large
  particle counts.
- **The CPU is the real risk.** Godot runs game scripts, physics and the scene
  tree on one main thread. Farming games tend to have many objects that each
  "think" every frame (crops, animals, the pet, enemies), and GDScript is
  interpreted (typed GDScript, ADR-0003, is faster but still not C++). The
  budget below keeps game logic to about 3 ms per frame, which shapes code
  from the start: crops update on a timer rather than every frame,
  off-screen things sleep, and so on.
- **The monitor decides what the player sees.** 120 fps is only visible on a
  120 Hz (or faster) screen. With V-Sync on (the engine default, verified),
  a 60 Hz monitor shows 60 fps. The budget is about having the headroom; an
  options menu can offer 60 / 120 / uncapped later
  (`application/run/max_fps`, verified).
- **Movement must be interpolated.** Godot's physics runs 60 times a second
  by default. Drawing 120 frames a second from 60 physics updates makes
  moving things judder unless physics interpolation is on
  (`physics/common/physics_interpolation`, verified to exist, off by default)
  or physics runs at 120. That touches camera behaviour and how movement
  feels, so it comes back to you with the first moving character.
- **What 120 fps buys in pixel art.** Positions are drawn on a 640×360 grid,
  so slow movement still steps one art pixel at a time at any frame rate. The
  gains are lower input latency and smoother fast camera pans. Worth having,
  but this is why the budget below also defines a 60 fps floor.

### Proposed budget

| Item | Proposal |
|---|---|
| **Minimum spec (Windows, Linux)** | GTX 1050 Ti 4 GB; Intel Core i5-7400 or AMD Ryzen 5 1600 (2017, 4–6 cores); 8 GB RAM; SSD |
| **Target on minimum spec** | 120 fps sustained at any supported screen size (ADR-0008), on a 120 Hz+ display |
| **Floor on minimum spec** | never below 60 fps, including the busiest scenes |
| **Frame time split at 120 fps** | game logic ≤ 3 ms, rendering (CPU side) ≤ 3 ms, headroom ≥ 2.3 ms |
| **macOS** | Apple M1, 8 GB: 120 fps on 120 Hz (ProMotion) displays, 60 fps on others. Intel Macs: best effort, not a target |
| **Steam Deck** (if Linux handhelds matter) | 60 fps (LCD model) / 90 fps (OLED model) |
| **RAM** | ≤ 1.5 GB in play |
| **Video memory** | ≤ 1 GB (pixel art needs far less) |
| **Loads** | cold start ≤ 5 s; base ↔ area transition ≤ 1.5 s, on SSD |
| **Install size** | ≤ 1 GB (music is the largest part) |

### What can be checked, and how

- **Automatically in CI:** game-logic time per simulated tick and peak memory,
  measured headless once there is a simulation to measure. CI machines are not
  a 1050 Ti, so CI can only catch regressions (something got 30% slower), not
  prove the target.
- **Only on real hardware:** actual frame rate and smoothness. This needs a
  machine at or near the minimum spec, run against a playtest checklist with
  an in-game frame-time display (to be built with the first gameplay).

### What I need from you

1. **The CPU.** A 1050 Ti says nothing about the processor, and the CPU is the
   real constraint. Accept the i5-7400 / Ryzen 5 1600 pairing, or name one.
2. **Mac and Steam Deck:** accept the targets above, or drop either.
3. **A test machine.** Do you have (or can you get) a machine near the
   minimum spec to run performance checklists on? Without one, the 120 fps
   target cannot be confirmed by anyone.

**Recommendation:** accept the table above (with your CPU answer) as
ADR-0007's values. I then mark ADR-0007 accepted and add the frame-time
display and benchmark harness when the first gameplay system lands.

## Q5. Renderer

**Resolved 2026-10-09:** option A, Compatibility everywhere (ADR-0012). The
feature check was done: six 2D features work (`renderer_features` showcase).

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

**Resolved 2026-10-09:** the lead accepted every recommendation: Q6a B (mouse
in menus and inventories), Q6b keyboard / Xbox / PlayStation / Nintendo
prompts, Q6c D (rumble and light bar now, DualSense prototype later), Q6d
menu setting plus Alt+Enter and Ctrl+Cmd+F. Recorded in ADR-0013; the
shortcuts are implemented.

**Lead's direction (2026-10-09):** support a standard keyboard and controller
input. Controllers get haptic feedback. DualSense players get DualSense
features: adaptive triggers and its haptic feedback. The lead asked for more
guidance. This section explains how input is built, what Godot 4.7.2 can and
cannot do (checked against the engine), and the four decisions left.

### How input will be built (engineering, no decision needed)

- **Actions, never keys.** Every input goes through named actions (`move_up`,
  `interact`, `use_tool`, `attack`, `open_inventory`, …) in Godot's InputMap.
  Keyboard keys and controller buttons are both bound to the same actions, so
  game code never knows which device is used.
- **Rebinding** of every action in the options menu, for keyboard and
  controller separately, saved per player.
- **The last device used wins.** Button prompts on screen switch instantly to
  whatever the player last touched.
- **Accessibility basics:** hold-or-toggle for held actions, adjustable stick
  dead zones, vibration intensity slider including off.
- **One haptics service.** Gameplay asks for named effects ("hoe hits soil",
  "harvest", "hit taken", "pet purrs nearby"). The service decides what each
  controller can do with them, so DualSense effects can be added later
  without touching gameplay code.

### What Godot 4.7.2 provides (verified against the engine, 2026-10-09)

| Feature | Built in? | Notes |
|---|---|---|
| Rumble (two motors, strength, duration) | **Yes** | `Input.start_joy_vibration(device, weak, strong, duration)`, for any controller with motors; how each controller model feels needs a playtest |
| Light bar colour | **Yes** | `Input.set_joy_light`, `has_joy_light` (DualShock 4, DualSense) |
| Gyro and accelerometer | **Yes** | `get_joy_gyroscope`, `get_joy_accelerometer`, calibration functions |
| Controller name and type | **Yes** | `get_joy_name`, `get_joy_info`, for picking button prompts |
| **DualSense adaptive triggers** | **No** | No method in any engine class (searched every class) |
| **DualSense HD haptics** (voice-coil, finer than rumble) | **No** | Same search |

Outside the engine (from the Godot community, not verified by me): adaptive
triggers need operating-system-specific native code that scripts cannot do;
on PC they work only over a USB cable, not Bluetooth; an engine change for
them covered only macOS and iOS. DualSense HD haptics on PC are driven as an
audio signal over USB. One open-source Godot extension, "Audio Haptics" (MIT),
does this; it was built for Godot 4.2, is tested on Linux and untested on
Windows, with no macOS support. No Godot extension for adaptive triggers was
found.

**Plainly: rumble on every controller is easy. DualSense adaptive triggers and
HD haptics are not available in Godot and would need native (C++) code we
write or adopt, and on PC they would only work with the controller plugged in
by cable.**

### Decision Q6a: the mouse

"Standard keyboard" leaves open whether the mouse is used.

**A. Keyboard only; the mouse is never used.**
- Pro: one keyboard layout to design for; matches controller play exactly.
- Con: players instinctively click in inventories and menus.

**B. Keyboard for play; the mouse also works in menus and inventories**
(recommended)
- Pro: natural for PC players; costs little because menus need pointer
  support anyway.
- Con: every menu must work with mouse, keyboard and controller.

**C. Keyboard and mouse for play** (mouse aims tools and attacks)
- Pro: precise aiming on PC.
- Con: combat and farming must then be designed around aiming, and play
  differently on controller.

**Recommendation:** B.

### Decision Q6b: which controller families get their own button prompts

Each family needs its own set of button icons (art; placeholder until art is
provisioned).

**Recommendation:** keyboard, Xbox, PlayStation (one set covering DualShock 4
and DualSense) and Nintendo. Steam Deck shows Xbox-style prompts, as it does
in most games. Other controllers fall back to Xbox prompts.

### Decision Q6c: how to get DualSense adaptive triggers and HD haptics

**A. Standard rumble and light bar only.**
- Pro: no dependencies, no native code; works wired and wireless on every
  platform.
- Con: does not meet your DualSense requirement.

**B. Adopt third-party extensions.**
- Pro: least work, if one fits.
- Con: an external dependency each (needs your approval); the only one found
  covers HD haptics only, targets Godot 4.2, is untested on Windows and
  missing on macOS; nothing covers adaptive triggers; we would depend on
  others to keep them working with future Godot versions.

**C. Write our own native extension for DualSense.**
- Pro: full control over both features, shaped to our effects.
- Con: C++ native code, which ADR-0003 rules out (it would need superseding);
  separate builds for Windows, macOS and Linux in CI; it has to talk to the
  controller alongside Godot's own controller handling, which needs a
  prototype to prove the two do not interfere; on PC it works only over USB
  cable; it can only be tested by someone holding a DualSense.

**D. Start with A, design for C, prototype C when there is something to feel**
(recommended)
- Ship rumble and light bar for every controller now, through the haptics
  service. Treat adaptive triggers and HD haptics as a later, timeboxed
  prototype on Windows over USB, once tools and combat exist (that is where
  triggers mean something: resistance on a hoe swing, a bow draw). The
  prototype decides between B and C with facts, and C would come to you as
  an ADR superseding ADR-0003.
- Pro: no cost before the effects can be judged; no gameplay code changes
  later.
- Con: DualSense owners get only rumble until then; Bluetooth players get
  only rumble even after.

**Recommendation:** D. It needs a DualSense (and you to test it) when the
prototype comes.

### Decision Q6d: leaving fullscreen

The game starts fullscreen (Q12) and has no way out yet.

**Recommendation:** an options-menu setting (fullscreen / windowed) when the
first menu is built, plus the platform shortcuts players expect: Alt+Enter on
Windows and Linux, Ctrl+Cmd+F on macOS.

## Q7. Is the web build a shipping platform?

**Resolved 2026-10-09:** the web build is never shipped; it is only built to
validate the export pipeline (option A). ADR-0004 updated.

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

**Resolved 2026-10-09:** approved. ADR-0003 is Accepted.

**Working assumption since 2026-10-09:** the project is typed GDScript with
untyped declarations as errors. ADR-0003 stays Proposed until the lead answers.

The brief does not name a language. The engineer proposed GDScript with static
typing (see the ADR for the reasoning). The alternative, C#, needs the .NET
build of Godot and the .NET SDK in CI, and its web export support in 4.7.2 has
not been verified.

**Recommendation:** approve ADR-0003.

## Q9. What was the calamity?

**Resolved 2026-10-09** (the lead's own answer, not one of the options below):
the player's pet, a cat that lives on the farm, is secretly an eldritch god. The
farm is unharmed because it enjoys the place; the player is the only one left
because they alone know how to make the most delicious cat treats, the first
recipe, unlocked from the start. Recorded in ADR-0010 and `story.md`. What the
calamity looked like and where monsters come from are still open (Q13).

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

**Resolved 2026-10-09:** Git LFS for larger assets (option B). Recorded in
ADR-0011: which file types, the 1 MiB guard, and cached LFS downloads in CI.

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

**Resolved 2026-10-09:** start fullscreen (option A). Recorded in the ADR-0008
amendment. How to leave fullscreen is Q6d.

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

## Q13. What did the calamity look like, and where do monsters come from?

**Resolved 2026-10-09:** B with C, as recommended. People were taken over
time, town by town; monsters are wildlife and land changed by the god's
presence, more so further from the base. Recorded in `story.md`.

Q9 settled who and why (the pet; see ADR-0010). Still open is what happened to
everyone and what the player fights. This decides how adventure areas look and
sound, what the notes describe, and what monsters drop. The no-gore rule from
the art direction applies to every option.

**What happened to the people**

**A. They vanished.** Overnight, everywhere, nothing left but their things.
- Pro: strongest for environmental storytelling (set tables, half-written
  letters); consistent with "traces, not bodies"; quietly cosmic.
- Con: notes must be written before the moment, so nobody can describe it
  directly.

**B. They were taken over time.** Town by town, following the cat's wandering.
- Pro: notes can witness it happening elsewhere ("the next valley went quiet
  last week"), which carries the reveal (`story.md`).
- Con: more writing to keep the timeline consistent.

**Where monsters come from**

**C. Wildlife and land changed by the god's presence.** Stronger change further
from the base.
- Pro: matches the art and audio rule "further from the base, more changed";
  monster drops can be natural materials, which fits farming and crafting.
- Con: needs care so animals do not read as cruelty.

**D. The god's dreams given shape.** Strange creatures that are not of this
world.
- Pro: free creature design; strongly eldritch.
- Con: harder to justify farmed and dropped materials; risks a generic
  "corruption" look.

**Recommendation:** B with C. People were taken town by town, so notes can
witness the spread and point at the cat. Monsters are wildlife and land changed
by the god's presence, more so further from the base, which is also why the
base (where it is content) stays peaceful.

## Q14. Does feeding the pet do anything in play?

**Resolved 2026-10-09:** the cat treats recipe is the tutorial for the skill
and crafting systems. Beyond that, feeding the pet triggers story moments
(option C), with no stat effects. Recorded in `story.md`.

Cat treats are the first recipe (ADR-0010). Whether giving them to the pet has
an effect is not decided, and it shapes the recipe and upgrade systems.

**A. Affection only.** The pet reacts happily; nothing else.
- Pro: simple; keeps the pet a companion rather than a power-up.
- Con: the first recipe has no gameplay purpose.

**B. Small blessings.** Treats give temporary bonuses (luck, foraging, combat).
- Pro: gives the first recipe a reason; uncanny if the blessings are slightly
  too strong.
- Con: overlaps with trinkets, artefacts and upgrades; risks making the god a
  vending machine.

**C. Story moments.** Feeding triggers rare small uncanny events at the base
that carry the reveal (`story.md`), with no stat effect.
- Pro: makes the core recipe the core story device; no balance impact.
- Con: content to author; easy to miss.

**Recommendation:** decide when recipes and crafting are designed. Leaning
towards A plus C: no stat bonuses, but feeding sometimes shows the player
something impossible.

## Q15. How much world should 32:9 screens show?

**Resolved 2026-10-09:** option A, show it all, and UI elements can be set to
21:9 or 16:9 widths in the settings (lead's addition). Recorded in the
ADR-0008 amendment; implemented as the UI width setting.

Found while adding super-ultrawide support (ADR-0008 amendment). With the
display settings unchanged, 32:9 screens see 1280×360 base pixels: twice the
width of 16:9 (80 tiles across instead of 40). 21:9 sees about 860 (54 tiles).

**A. Show it all** (current behaviour)
- Pro: wide, empty vistas suit the lonely tone; no black bars for
  super-ultrawide owners, who dislike them; no extra code.
- Con: every area must make sense at 80 tiles wide: areas narrower than that
  need a camera rule (stop at the area edge and fill the rest with darkness,
  or centre the area); more on screen means more to draw and simulate; the
  character is very small on a 32:9 screen.

**B. Cap at 21:9; wider screens get bars at the sides**
- Pro: level design only has to handle up to about 54 tiles wide; framing
  stays close to what was designed.
- Con: 32:9 owners see black bars on both sides; Godot has no built-in "maximum
  aspect" setting, so the cap is custom code that changes the visible area
  (camera behaviour, needs testing at every screen size).

**C. Cap at 16:9 everywhere**
- Pro: one framing to design for.
- Con: contradicts the decision to support ultrawide properly; large bars on
  21:9 and 32:9.

**Recommendation:** A for now. Nothing is designed yet that a wide view could
break. Revisit at the first level-layout work, where the camera rule for
narrow areas is needed anyway, and both are camera behaviour for you to
approve.

## Q16. How to check the performance budget without a minimum-spec machine

**Resolved 2026-10-09:** the lead measures on the Ryzen 7 5800X (option A's
scaled budget) and on the Steam Frame both through FEX with the x86 build
(B) and natively with a Linux ARM64 test build (C). Option D (a real
minimum-spec PC) was not chosen, so the budget stays unverified on its target
hardware. The macOS and Steam Deck performance targets were dropped.
Implemented: the ARM64 test build and the frame-time overlay, with the
checklist `docs/playtests/2026-10-09-performance-devices.md`.

Found from the lead's Q4 answer (2026-10-09): there is no machine near the
minimum spec (GTX 1050 Ti, i5-7400). The lead has a Ryzen 7 5800X with an
RTX 4080 Super, and two lower-powered devices with the same chip (Snapdragon
8 Gen 3): a OnePlus 12 phone and a Steam Frame, both able to run x86 builds
through the FEX emulator. Also open from Q4: confirming the macOS (Apple M1)
and Steam Deck targets, which the lead's answer did not mention.

**What each device can tell us**
- **The 5800X is about 1.84× faster per core than the i5-7400** (Geekbench 5
  and 6 single-core scores, hardwaredb.net). Godot's game logic runs on one
  main thread, so per-core speed is what matters. Rough rule: logic that takes
  1.6 ms on the 5800X takes about 3 ms (the whole logic budget) on the
  minimum spec. The 4080 Super says nothing useful about a 1050 Ti, but the
  GPU is not the risk (Q4).
- **The Snapdragon devices are a different machine, not a slower copy of the
  target.** They are ARM chips running our x86 build through FEX, which
  translates every instruction and costs an amount that varies by workload.
  The GPU is a phone GPU with different drivers. A result there is "how the
  game does on a weak, emulated device", which is useful as a stress test but
  cannot be converted into a 1050 Ti number. The Steam Frame is also the more
  practical of the two: it runs SteamOS (Linux) with FEX built in, while the
  phone needs an extra compatibility layer.

**A. Scaled budget on the 5800X, plus regression tracking in CI**
- Pro: no new hardware; an in-game frame-time display and a headless
  benchmark give numbers on every build; CI catches anything that gets slower.
- Con: the 1.84× conversion is approximate (cache sizes, memory speed and the
  GPU driver differ); it can say "probably fine", never "verified".

**B. A plus periodic runs on the Steam Frame (x86 build through FEX)**
- Pro: a real weak device, run at milestones; exactly what a Steam Frame
  player would run if we only ship x86; free, you already have it.
- Con: emulation noise makes it a stress test rather than a proxy.

**C. B plus a native Linux ARM64 test build for the Steam Frame**
- Pro: removes emulation, so the device's own speed shows; the export
  template for Linux ARM64 is already in the official template set.
- Con: an extra build to maintain; it measures a build no player would get
  unless ARM64 becomes a platform (ADR-0004, your call).

**D. Get a real minimum-spec PC** (a used i5-7400 / GTX 1050 Ti machine)
- Pro: the only way to actually verify the target.
- Con: cost and space; your decision.

**Recommendation:** B now, and D before any public release. A is the
day-to-day check (I build the frame-time display and benchmark with the first
gameplay system); the Steam Frame run goes on milestone playtest checklists.
Skip C unless you want ARM64 as a shipping platform.

**Also needed (from Q4):** confirm or drop the macOS target (Apple M1: 120 fps
on 120 Hz displays, 60 otherwise) and the Steam Deck target (60 / 90 fps).

## Q17. Whole-number or fractional scaling, now that rendering is full resolution?

**Resolved 2026-10-10:** option A, keep whole-number scaling (the lead).
ADR-0008 is unchanged.

Found while implementing the full-resolution change (ADR-0008 Amendment 3).
`scale_mode = integer` was chosen when the game was drawn at 640×360 and
scaled up, where fractional scaling would blur or distort everything. Drawing
at full resolution removes that for text, lights and shapes, but not for
pixel-art sprites: their art pixels must still map to whole screen pixels to
look even.

**A. Keep whole-number scaling** (current, recommended)
- Pro: every art pixel is the same size on screen; no shimmer when sprites
  or the camera move; every common fullscreen monitor (1080p, 1440p, 4K, the
  ultrawide sizes) is an exact multiple, and the game starts fullscreen.
- Con: windows or screens that are not an exact multiple get black borders
  (1366×768 laptops: thin bars; windowed mode: bars until the window size is a
  multiple; below 1280×720 the game drops to 1x).

**B. Fractional scaling**
- Pro: the game fills every window and screen exactly; no bars ever.
- Con: on non-multiple sizes, art pixels come out uneven (at 2.13x some are
  2 screen pixels wide, some 3), which shows as wobbling edges and shimmer when
  anything moves; level art would look slightly different on every screen.

**C. Whole-number scaling for the world, fractional for the UI only**
- Pro: no bars for menus and text, even art pixels in the world.
- Con: needs custom code (Godot's setting applies to everything); the world
  still has bars; UI and world scale would no longer match.

**Recommendation:** A. The bars only appear on unusual sizes and in windowed
mode, while B's shimmer would affect every player on those sizes all the time.
Revisit if playtests on real laptops show the bars bother people.
