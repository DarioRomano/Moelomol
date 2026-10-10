# Open questions

Decisions waiting for the project lead. Each has options with pros and cons and
the engineer's recommendation. When the lead decides, record the answer here
(date and choice), move the substance into an ADR or design doc, and mark the
question **Resolved**.

Status at 2026-10-10: Q28 (where farming magic comes from) and Q31 (a new mechanic for magic's Rot spell) are open; everything else is resolved.

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
| Q18 | Camera perspective: top-down or side view? | All sprites, combat, level layout | **Resolved**: top-down ¾ → ADR-0014 |
| Q19 | One weapon at a time, or two equipped with a swap? | Combat implementation | **Resolved**: two with a swap → `combat.md` |
| Q20 | Smoothing movement at 120 fps with 60 Hz combat logic | Feel of all movement | **Resolved**: A, fixed 60 Hz + render interpolation |
| Q21 | How the game clock runs (pace, during adventures, seasons) | Farming, adventuring, story pacing | **Resolved**: 20-minute day that fully cycles; night changes sight and monsters → `farming.md` |
| Q22 | How a day ends (sleep, staying up, falling asleep) | Farming slice | **Resolved** with Q21: sleep is optional, no forced end |
| Q23 | How crops grow with the day–night cycle | Farming slice | **Resolved**: A, plus watering by spell (4 crops, upgrades up to rain) |
| Q24 | What neglect costs (dry soil, unharvested crops) | Farming slice, tone | **Resolved**: A |
| Q25 | Where seeds come from without shops | Farming, exploration rewards | **Resolved**: A |
| Q26 | Controls and targeting at the base | Input model (ADR-0013) | **Resolved**: A |
| Q27 | Does farming use an energy bar? | Farming slice, upgrades | **Resolved**: farming is magic and costs Mana (sleep, food); enhanced weapon skills cost Mana too |
| Q28 | Where does farming magic come from, and how does it look? | Farming spell art, story notes | Open (working assumption: C) |
| Q29 | A more satisfying weapon skill for magic | Magic feel (lead's playtest) | **Resolved**: B, the Siphon, on heavy hold instead of the skill; the Rot pool it replaces goes to Q31 |
| Q30 | A clearer weapon skill for the greatsword | Greatsword feel (lead's playtest) | **Resolved**: A, guard and riposte |
| Q31 | A new mechanic for magic's Rot spell | Magic feel; the skill button | Open (interim: the old Rot pool on the skill button) |

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

## Q18. Camera perspective: top-down or side view?

**Resolved 2026-10-10:** option A, top-down ¾ view (ADR-0014).

Found while designing combat (2026-10-10): the perspective was never decided,
and it changes how every weapon plays and how every sprite is drawn. The art
plan's placeholder ("a player character standing in four directions")
already implies top-down, but no decision records it. `combat.md` and
`combat-art-prompts.md` assume A.

**A. Top-down ¾ view** (like most farming games: the ground seen from above at
an angle, characters drawn slightly from the front) (recommended)
- Pro: farming on a grid of fields, wandering a base and exploring open areas
  all work naturally; enemies can come from any side, so dodging, pushing into
  walls, kiting and area effects (shockwaves, pools, Volley) have room; fits
  the 640×360 view with 40 × 22 tiles and the ultrawide decisions.
- Con: each character and attack needs several facing directions (more art);
  aiming without a mouse needs soft aim and lock-on (designed).

**B. Side view** (a 2D action game seen from the side, with jumping)
- Pro: one facing direction to draw (mirrored); combat readability is
  excellent; jumping and verticality add options.
- Con: farming fields from the side is awkward; the base becomes a strip;
  open exploration becomes platforming; pushing and area effects mostly work
  along one line; most of the art direction and the "wide empty views" idea
  would need rethinking.

**Recommendation:** A. Once decided it becomes an ADR: expensive to reverse,
because every sprite depends on it.

## Q19. One weapon at a time, or two equipped with a swap?

**Resolved 2026-10-10:** option B, two weapons equipped with a 1.5 s swap
cooldown (`combat.md`). Built when the second weapon exists.

Found while designing combat. The brief wants weapons that fit different
playstyles and magic built on stacking; whether those can be combined in one
fight decides how deep builds go and how much needs balancing.

**A. One weapon equipped; change it outside combat**
- Pro: each weapon is balanced on its own; simplest controls; strongest
  identity per playstyle.
- Con: no combinations (magic stacks cashed in by a hammer strike, a bow
  pinning creatures for a greatsword); a wrong pick for a fight cannot be
  fixed mid-fight.

**B. Two equipped, swap any time with a short cooldown** (recommended)
- Pro: hybrid builds (the combinations in `combat.md`); each weapon covers the
  other's weakness (bow for flyers, hammer for shells); more depth for skills
  and trinkets.
- Con: more balancing; every pair must feel good; one more button.

**C. Any weapon, any time (a wheel)**
- Pro: maximum freedom.
- Con: playstyles blur into "use the right tool for each enemy"; weapon
  identity and mastery suffer; menus in the middle of fights.

**Recommendation:** B, with a 1.5 s swap cooldown to keep swaps deliberate.

## Q20. Smoothing movement at 120 fps with 60 Hz combat logic

**Resolved 2026-10-10:** option A (the lead): fixed 60 Hz logic with render
interpolation, the current default. F5 stays as a developer toggle; if the
playtest shows the delay can be felt, B is the fallback.

Found while building the combat arena (2026-10-10). The lead asked
(2026-10-10): *can the logic not be time based instead of frame based?*

### First, what "time based" means here

The combat logic **is already time based**, not frame based. Every timing is
defined in milliseconds (a 700 ms telegraph, a 150 ms sweet spot), and the game
cuts real time into fixed 16.7 ms slices ("ticks", 60 per second), however
fast or slow the screen draws. At 30, 60, 120 or 240 fps a dodge lasts
400 ms. This is called a **fixed timestep**.

The other kind of time-based logic is a **variable timestep**: every drawn
frame, advance the logic by exactly the time that passed since the last frame
(8.3 ms at 120 fps, 16.7 ms at 60, 25 ms at 40). Both are time based; they
differ in whether the slices are equal.

The question exists because, with fixed 16.7 ms slices, a 120 Hz screen draws
two frames per slice. Drawn as-is, moving things hold still every second frame
(judder). Godot's built-in physics interpolation does not apply, because the
combat simulation does not use Godot physics. In the arena, **F5** toggles
option A so it can be compared.

### Options

**A. Fixed 60 Hz logic, with render interpolation** (draw each character
between its last two positions) (current default)
- Pro: smooth on 120 Hz and faster screens; logic and timing exactly the same
  on every machine; tests reproduce every situation tick for tick; cheap (a
  blend per character per frame).
- Con: what is drawn is up to one tick (16.7 ms, on average about 8 ms)
  behind the simulation: a small extra delay between pressing a button and
  seeing the result.

**B. Fixed 120 Hz logic** (slices of 8.3 ms)
- Pro: smooth at 120 Hz with no added delay; timing windows twice as fine
  (a 150 ms window becomes 18 slices instead of 9); still exactly
  reproducible.
- Con: double the logic CPU time (measured 2026-10-10 on the cloud test
  machine: 0.02 ms per tick with the arena's 2 creatures, 0.5 ms with 30, so
  about 1 ms per frame with 30 creatures at 120 Hz, within the 3 ms budget of
  ADR-0007 but no longer negligible); above 120 Hz (144, 240 Hz screens) it
  judders again unless combined with A.

**C. Fixed 60 Hz logic, no smoothing**
- Pro: simplest; no added delay.
- Con: visible judder on 120 Hz screens, which are the target (ADR-0007).

**D. Variable timestep** (logic advances by each frame's real duration)
- Pro: smooth at every refresh rate with no interpolation and no added delay;
  the most common approach in simple Godot projects (`_process(delta)`).
- Con:
  - **Timing becomes machine dependent.** Windows are checked only when a
    frame happens, so a 150 ms hammer sweet spot is judged in 8 ms steps at
    120 fps but 25 ms steps at 40 fps. Precise timing (the hammer, the bow's
    clean release, dodge invulnerability) is fairer on fast machines.
  - **Results are not reproducible.** The same inputs give slightly different
    distances and outcomes at different frame rates (rounding builds up), so
    the 54 combat tests could only check "roughly", and the scripted review
    poses would differ between runs.
  - **Fast moves can skip through things at low frame rates.** A 24 px shove
    dash in one 50 ms frame can pass through a creature or a thin wall; every
    movement would need sweep tests.
  - **Hitches cause jumps.** A 100 ms stall becomes one 100 ms step; it must be
    clamped, which then breaks the timing it was meant to keep.
  - A rewrite of the simulation and its tests.

**E. Mixed:** fixed ticks for combat rules, variable timestep for the player's
own movement and the camera
- Pro: the player's own movement feels immediate; combat stays exact.
- Con: two clocks to keep in step; hits are judged against positions that move
  between ticks, which causes "I was out of range" disagreements; complex.

### Recommendation

**A now; B if the delay can be felt.** Fixed slices keep combat timing equal
on every machine and fully testable, which matters most for the
timing-precise weapons still to come (hammer, bow). D trades that away for
smoothness that A already provides. In the arena playtest on your 120 Hz
screen, compare F5 on (A) and off (C): if A feels smooth and you cannot feel
its delay, keep it; if you can, switch to B (a one-line change to the tick
rate plus re-checking the tick counts in the tests).

## Q21. How the game clock runs

**Resolved 2026-10-10 (the lead):** a day lasts **20 minutes** and **fully
cycles**: there is no requirement to go to sleep. There is no hunger. Grown
crops can be cooked for buffs, but eating is never required. **At night,
sight is impaired and different monsters spawn**; environmental effects can
light up spaces at night. This replaces options A–C below. Q22 is answered
by it.

Found while drafting `farming.md` (2026-10-10). The day–night cycle drives
crop growth, so its pace sets how often the player farms and how much an
adventure costs at home.

**A. One clock, running everywhere: 15-minute days (6:00–2:00), no seasons
yet** (recommended)
- Pro: the day has a shape everywhere (dusk is the cue to come home); an
  expedition has a real cost in farm days, which makes planning part of
  the play; one simple rule; 15 minutes leaves room for both farming and
  a trip out.
- Con: some pressure on adventuring (crops wait unwatered while the player
  is away; Q24 keeps that cost small); the pace needs tuning by playing.

**B. Time passes only at the base; adventures cost a fixed slice of time**
(for example, every trip out ends at dusk)
- Pro: no pressure while exploring; farming and adventuring stay neatly
  separate.
- Con: adventures lose the day–night cycle (no "come home at dusk"); the
  world outside feels timeless; trips are forced into a fixed shape.

**C. No running clock: a day lasts until the player sleeps**
- Pro: no pressure at all; simplest; fits "unhurried".
- Con: dusk and night become a choice rather than an event, so the art
  direction's emotional peak may never happen; no rhythm to the day.

On seasons: none in the first version under any option. They multiply crop
content and art (every crop per season, every area per season) and are
better decided once crops and areas exist. A broken or stuck season could
also be a story element.

**Recommendation:** A, with the pace (0.75 s per game minute) tuned in
playtests.

## Q22. How a day ends

**Resolved 2026-10-10 (the lead), with Q21:** the day cycles on its own and
sleep is never required, so nothing forces the day to end. Sleeping skips
to the next morning (and refills Mana, Q27). The cat-on-the-bed wake-up
proposed under A is dropped with option A.

**A. Sleep in the bed at any time; at 2:00 the player falls asleep wherever
they are and wakes at home at 6:00, with no penalty** (recommended)
- Pro: never punishing (fits the tone); always a clear end to the day; the
  wake-up is a natural story beat: the cat curled on the bed, as if it
  brought the player home (Q14's story moments, never explained).
- Con: no reason to fear staying out late, so night has no tension of its
  own (adventuring may add some later).

**B. As A, but falling asleep outside costs something** (dropped
materials, a slow start the next day)
- Pro: night outside has stakes.
- Con: punishment where the tone asks for gentleness; losing materials
  feels arbitrary in a world with no one to take them.

**C. No forced end: stay up as long as wanted**
- Pro: total freedom.
- Con: long nights become a way to cheat time; the day loses its shape;
  harder to balance growth (Q23).

**Recommendation:** A, and the lead's call on the cat-on-the-bed touch.

## Q23. How crops grow with the day–night cycle

**Resolved 2026-10-10 (the lead):** A, overnight growth. **Watering is
magic:** a watering spell waters up to 4 crops at first; upgrades widen it,
and its final form turns the weather rainy, which waters the entire farm.

**A. Overnight: each crop watered that day grows one day when the next day
starts; ripe after a set number of grown days** (recommended)
- Pro: dawn is when the farm changes, which is the lead's "day / night
  mechanic that progresses crop growth"; simple to read (one step a day);
  simple to test; adventures and sleep never break growth.
- Con: nothing visibly grows while the player watches.

**B. Continuously, through the game hours of watered soil**
- Pro: the farm changes during the day.
- Con: growth depends on when in the day the player watered, which is hard
  to read; small stage changes are easy to miss; more balancing.

**C. Overnight, without watering**
- Pro: the simplest possible farming.
- Con: removes the daily care that makes the farm feel tended, and the main
  hook for farming upgrades (bigger cans, sprinklers).

**Recommendation:** A.

## Q24. What neglect costs

**Resolved 2026-10-10 (the lead):** A.

**A. Nothing but time: an unwatered crop simply does not grow that day; a
ripe crop waits** (recommended)
- Pro: the tone asks for unhurried; a long expedition never wipes out the
  farm; still a clear incentive to water (faster harvests).
- Con: less tension; nothing makes the player come home except wanting to.

**B. Crops wither after several dry days** (for example 3)
- Pro: the farm needs the player; coming home matters.
- Con: punishes exploring, which drives the story; a lonely player losing
  their crops reads as cruel rather than meaningful.

**C. Ripe crops rot if left too long**
- Pro: rewards timely harvesting.
- Con: the same punishment problem as B, for less gain.

**Recommendation:** A.

## Q25. Where seeds come from without shops

**Resolved 2026-10-10 (the lead):** A.

ADR-0005 rules out merchants and any character to trade with.

**A. A starting seed tin, seeds back from every harvest, new kinds found on
adventures** (recommended)
- Pro: no characters needed; the farm is self-sustaining; new crops become
  exploration rewards (abandoned gardens, seed packets beside notes), which
  ties farming to the story; the tin is a quiet environmental hint (someone
  left it).
- Con: harvest yields must be balanced so the farm grows, but not
  explosively.

**B. Seeds only found, never returned by harvests**
- Pro: every seed is precious; strong pull to explore.
- Con: one bad run starves the farm; replanting the treats' catmint
  depends on luck; frustrating.

**C. An impersonal machine or shrine that trades produce for seeds**
- Pro: a steady supply and a use for surplus.
- Con: a shop in disguise; bends ADR-0005's "no trading" and would need the
  lead's design change; it also needs a story reason to exist.

**Recommendation:** A, with harvests returning 2 seeds for now (placeholder
balance).

## Q26. Controls and targeting at the base

**Resolved 2026-10-10 (the lead):** A.

The base has no combat (ADR-0005), so it can reuse the combat buttons with
farming meanings. ADR-0013 requires actions, rebindable, and no mouse aiming.

**A. Act on the tile in front of the player (highlighted); Use tool on the
light-attack button (J / X), Interact on the dodge button (Space / A),
switch tools with E / Q and RB / LB** (recommended)
- Pro: no new buttons to learn; A is the usual "interact" button on
  controllers; the target is always visible; works with eight keyboard
  directions.
- Con: sometimes the player must step to aim at a diagonal tile; one button
  meaning two things in two places must be clear in the controls screen.

**B. A free cursor moved with the right stick or arrow keys**
- Pro: precise; act without walking.
- Con: two things to steer at once on a controller; slower on keyboard;
  close to mouse-style aiming, which ADR-0013 avoids.

**C. Separate dedicated farming buttons**
- Pro: no double meanings.
- Con: more buttons than a controller comfortably has; nothing gained,
  since combat and farming never happen together.

**Recommendation:** A (the bindings are built that way as a working
assumption; they are separate InputMap actions, so changing them later costs
nothing).

## Q27. Does farming use an energy bar?

**Resolved 2026-10-10 (the lead):** neither option. **All farming is done
with magic, and therefore costs Mana.** Mana is replenished by sleep and by
food. So that Mana does not unbalance magic as a fighting style,
**enhanced weapon skills consume Mana; basic magic attacks do not.**

**A. No: time is the only budget at home** (recommended)
- Pro: unhurried; one less bar; farming upgrades (bigger cans, multi-tile
  hoe) save time rather than energy, which is easy to understand.
- Con: an all-day farming session has no limit except the clock.

**B. An energy bar spent by tool use, refilled by sleep and food**
- Pro: gives food from the farm a use; a familiar genre rule.
- Con: a second budget alongside time; adds a chore; food and healing are
  not designed yet (`combat.md` leaves healing open).

**Recommendation:** A. If food later needs a use, healing on adventures is a
better home for it than farming energy.

## Q28. Where does farming magic come from, and how does it look?

Found while building farming by magic (Q27, 2026-10-10). The combat design
says magic is the god's own influence: the lantern is drawn in the "changed
land" violets, the only player-side thing that is (`combat.md`,
`art-direction.md`). If all farming is magic too, the source of that magic
is a story question, and the colour is an art question.

**A. The player's own craft:** an old farmer's magic, nothing to do with the
god; drawn in the warm base and crop colours.
- Pro: the farm stays purely the player's; warm colours keep "warmth means
  life"; no new story weight.
- Con: two kinds of magic in one game need an explanation somewhere; misses
  a strong hint.

**B. The god's influence, like the lantern:** farming spells in the violets.
- Pro: one magic, one rule; the most farming-touched part of the game is
  quietly the god's doing, which fits the reveal (`story.md`).
- Con: violet at the base breaks the art rule that the base is the one warm
  place, and gives the secret away early.

**C. The same source, but the player cannot tell yet** (recommended):
farming spells glow in warm living green and gold; at night, or as the story
advances, a thread of violet shows in them.
- Pro: keeps the base warm; the hint grows with the story, which is how
  `story.md` wants the truth to come out; costs only a colour shift.
- Con: the writers and artists must keep the progression consistent; one
  more thing tied to story progress.

**Recommendation:** C. The farm test scene draws farming spells in warm
green and gold as a working assumption; nothing violet yet.

## Q29. A more satisfying weapon skill for magic

**Resolved 2026-10-10 (the lead):** B, the Siphon, but **on the heavy
button's hold** instead of the skill. The Rot pool that was there "needs to
be reworked to a different mechanic. It is rather boring" (Q31). As built:
`combat.md`, "Siphon: cashing in". Release is gone; the skill button holds
the old Rot pool until Q31 is answered.

Raised by the lead after playing (2026-10-10): the skill "is not quite
satisfying… too similar to the ice AoE left by blinking".

**What it is now:** Release, a 90° cone reaching 28 px. It consumes every
stack on the creatures it hits and turns them into one burst, plus Shatter,
Blight bloom or Brittle for mixed effects.

**Why it falls flat** (checked in the simulation, 2026-10-10):
- **On a creature without stacks it does nothing.** 0 damage, just a violet
  cone, so pressing it early feels broken.
- **Its payoff is drawn as a ring.** Magic already draws two circles, the
  Rot pool and Wardstep's Chill pool, so a successful Release looks like
  another pool.
- **The burst lands all at once.** Five stacks of three effects hit as one
  number and one flash; the build-up is not paid off visibly.

**A. Unravel: a chained, per-creature detonation** (recommended)
- **How it works:** hold the lantern up for 0.2 s; then every stacked
  creature within about 64 px (not a cone) is detonated in turn, nearest
  first, 0.1 s apart, each with its own hit-stop and rumble.
  - Each effect bursts in its own shape: Smoulder as an ember flare upward,
    Chill as ice shards outward, Rot as a sinking violet bloom.
  - Mixed effects play their combination on that creature (Shatter, Blight
    bloom, Brittle), so the order is readable.
  - With no stacks anywhere, it fizzles with a clear "nothing to release"
    puff and costs no Focus.
- Pro: a big stack count becomes a long, visible chain, which is the
  payoff the stacking builds towards; nothing is round and on the floor,
  so it can't be confused with a pool; keeps the design's core (stack,
  then cash in) and the step-in risk (64 px is close).
- Con: one more piece of sequencing in the simulation; a long chain needs
  a cap so it doesn't freeze the fight with hit-stop.

**B. Siphon: drain one target, then fire**
- **How it works:** hold the skill on the locked or nearest creature in
  front to pull its stacks into the lantern over up to 1 s; the lantern
  fills with their colours.
  - Release the button to fire a beam whose strength and kind come from
    what was drained (Smoulder burns along the line, Chill pierces and
    freezes, Rot spreads to anything the beam crosses).
  - A hit while draining interrupts it, like a cast.
- Pro: active and skilful; distinctive (a line, not a circle); the
  drain-then-fire rhythm matches the hammer and bow's hold-and-release
  identity.
- Con: one target at a time, which weakens magic against groups; the
  channel adds a third hold to the heavy button's tap/hold.

**C. Ignite the mark: a thrown orb**
- **How it works:** throw the lantern's flame as a slow orb (about 120 px/s
  for 1 s). It collects stacks from every creature it passes through and
  detonates where it stops, all collected stacks at once, in a radius.
- Pro: lets magic stay at range; aiming the orb through a line of
  creatures is a skill.
- Con: removes the "step in close" risk the design gave magic; a round
  detonation is the same shape problem again.

**Also possible with any option:** make Wardstep's leftover distinct, for
example a frost afterimage that creatures attack and that shatters into
Chill, instead of a pool. Then magic has one pool (Rot) and nothing else on
the floor.

**Recommendation:** A, with the chain capped at 6 creatures and hit-stop
shortened after the third.

## Q30. A clearer weapon skill for the greatsword

**Resolved 2026-10-10 (the lead):** A, guard and riposte, as recommended.
As built: `combat.md`, "Greatsword".

Raised by the lead after playing (2026-10-10): the skill "is hard to
understand: does it even work?"

**What it is now:** one button with two meanings.
- **Follow-through:** a big hit if a staggered creature is within 34 px.
- **Brace:** otherwise, a 0.5 s stance. A hit taken during it arms an
  instant heavy (Brace counter).

**What a probe showed** (simulation, 2026-10-10: a creature lunging, the
player bracing at different moments):
- **Brace does work.** Bracing at ticks 20–40 of the creature's 42-tick
  telegraph catches the lunge and arms the counter.
- **But the player takes the full 15 damage either way.**
- **A single lunge never staggers the player anyway** (30 poise damage
  against 50 poise), so the stagger protection is invisible.
- **The only payoff** is that the next heavy is instant, and the only sign
  of it is the text "BRACE READY" in the debug HUD.
- **The hidden switch:** whether the button means Follow-through or Brace
  depends on a hidden condition (a staggered creature within 34 px), so the
  same press does two unrelated things.

**A. Guard and riposte: one meaning, with clear feedback** (recommended)
- **Brace becomes a real guard.**
  - Hits during its 0.5 s deal 30% damage and cannot stagger.
  - A hit in its first 0.15 s is a **perfect brace**: no damage, the
    attacker is **repelled and staggered**, and the counter-cleave comes
    out **at once**, without a second button.
  - A visible guard pose, a bright flash and a heavy rumble mark the
    perfect brace.
- **Follow-through moves to the heavy button:** heavy on a staggered
  creature in reach is always Follow-through, the finisher for a stagger
  (the chain finishers otherwise).
- Pro: each button has one meaning; the skill is a learnable parry with an
  obvious reward; it uses the greatsword's stagger identity; Follow-through
  is easier to find.
- Con: the parry window is a new timing to tune (needs playtesting);
  heavy's meaning now depends on whether the target is staggered, which is
  visible (grey, stars) but still a context switch.

**B. Bull rush: a shoulder charge**
- **How it works:** dash 48 px with the shoulder, carrying every creature
  in front along and slamming them into walls, pillars and each other (the
  existing impact rules); creatures that hit something are staggered.
  - Follow-through moves to heavy on a staggered creature, as in A.
- Pro: the clearest possible skill; it leans fully into "lots of pushing";
  impacts are already the greatsword's most satisfying moment.
- Con: close to the shoulder-shove finisher (a heavy after one light); the
  greatsword loses its only defensive tool.

**C. Keep both meanings, but show them**
- **How it works:** keep the current rules and add feedback.
  - A "Follow-through" prompt and highlight on a staggered creature in
    reach.
  - A visible guard pose.
  - Damage reduction while braced.
  - A flash and rumble when Brace catches a hit.
  - The armed counter glowing on the blade.
- Pro: least change; the current design becomes readable.
- Con: still two unrelated moves on one button; the payoff still needs a
  second press.

**Recommendation:** A. It answers "does it work?" with a hit that visibly
does nothing to you and staggers the attacker, and it gives each button one
job.

## Q31. A new mechanic for magic's Rot spell

Raised by the lead with the Q29 answer (2026-10-10): the Siphon takes the
heavy hold, and the Rot pool that was there "needs to be reworked to a
different mechanic. It is rather boring." It lands on the **skill button**,
which Release used to hold.

**What the Rot spell has to do:**
- **Rot is the only effect without its own spell.** Ember bolt gives
  Smoulder, Frost shard gives Chill; without a Rot spell, Rot only comes
  from Blight bloom, so two of the three combinations become hard to reach.
- **It should not be a circle on the floor.** Wardstep already leaves one
  (the Chill pool), and the Q29 feedback was that two circles read alike.
- **It should feed the Siphon.** Magic's loop is now "stack, then drain and
  fire"; the best Rot spell gives the player a reason to Siphon at a
  particular moment.

**What it is now (interim):** the old Rot pool on the skill button: a 22 px
patch for 4 s, 1 Rot every 0.5 s to whatever stands in it, 20 Focus.

**A. Rot seed: a parasite that grows and jumps** (recommended)
- **How it works:** a slow seed (about 160 px/s) that latches onto the
  first creature it hits.
  - The seed grows on its host: 1 Rot at once, then 1 more every 0.6 s, for
    4 s. A small violet growth on the creature shows it.
  - **When the host dies, or the Siphon drains it, the seed jumps** to the
    nearest creature within 48 px with whatever time it has left.
  - One seed at a time; casting another moves it. About 15 Focus.
- Pro: one target, so it is about choosing a host; the jump turns killing
  or draining into spreading, which ties Rot to the Siphon; nothing on the
  floor; the "parasite" reading fits the changed land.
- Con: a new kind of thing to build (an effect attached to a creature that
  moves between creatures); against a single creature it is just Rot over
  time.

**B. Withering grasp: a pull**
- **How it works:** a violet hand reaches 48 px in front, grabs the first
  creature, gives it 3 Rot and pulls it 24 px towards the player. Heavy
  creatures (more poise) are not pulled, only slowed for a moment.
- Pro: physical and immediate; pulling a creature into Siphon reach is a
  clear setup; the most different from the other spells.
- Con: pulls danger towards a fragile caster; close to the greatsword's and
  hammer's push identity, in reverse.

**C. Blight link: tie two creatures together**
- **How it works:** press once on one creature, again on a second (within
  a few seconds) to link them with a violet thread for 5 s. Rot on either is
  copied to the other, and damage dealt to one deals 25% to the other.
- Pro: rewards fighting groups; every Ember bolt and Frost shard does more
  on a linked pair; visually distinct (a thread, not a circle).
- Con: two presses again (the lead just asked for one-press Volley);
  harder to read in a busy fight; strongest only with exactly two creatures.

**D. Spore cloak: an aura that follows the player**
- **How it works:** for 4 s, creatures within 24 px of the player gain 1 Rot
  every 0.5 s; the player's dodge leaves a spore puff (1 Rot) where it
  started.
- Pro: simplest to build (the pool, following the player); rewards the
  Siphon's close range.
- Con: still a circle; asks a fragile caster to stand close; the least
  change from what was called boring.

**Recommendation:** A. It is the only option that makes Rot interact with
the Siphon (drain the host and the seed jumps), it keeps one press, and
nothing about it is round or on the floor.
