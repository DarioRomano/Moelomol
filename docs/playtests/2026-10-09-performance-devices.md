# Playtest: performance on the 5800X and the Steam Frame (Q16)

**For:** the project lead. **Why:** the performance budget (ADR-0007) is
120 fps on a GTX 1050 Ti with an i5-7400. No such machine is available, so we
measure on what is (Q16, options A to C). There is no gameplay yet: these runs
prove the builds work on each device and give a baseline to compare later
builds against. They do not prove the budget.

## 1. Build

The latest release on the Releases page (or a PR's build comment). Note the
build label shown in the overlay's last line.

- **5800X (Windows or Linux):** the Windows or Linux zip.
- **Steam Frame, option B:** the normal **Linux** zip (x86-64), run through
  FEX.
- **Steam Frame, option C:** the **Linux ARM64** zip (test build), run
  natively.

## 2. How to use the overlay

- **F3** (or both stick buttons pressed together on a controller): show or
  hide the overlay.
- **F2:** next scene: title → test card → renderer features → title. Measure
  on **renderer features**: it has lights, shadows, particles and shaders.
- **F4:** V-Sync on/off. With V-Sync on, the frame rate stops at the screen's
  refresh rate; **off** shows how much headroom there is.
- Without a keyboard (e.g. Steam launch options), start the game with
  `-- --perf-overlay --start-scene renderer_features --no-vsync`
  (the `--` matters when launching from a terminal).
- Let each scene run for 10 seconds before reading the numbers.

## 3. Checks

For each device, note: device, OS, screen resolution and refresh rate.

1. **It starts.** The game opens fullscreen on the title. Result:
2. **Overlay line 5 identifies the device correctly** (OS, x86_64 or arm64,
   CPU, GPU, `gl_compatibility`). On the Steam Frame, x86_64 under FEX and
   arm64 natively. Result:
3. **Renderer features, V-Sync off:** write down line 1 (FPS, frame avg,
   max, frames over 8.33 ms) and line 2 (logic, render CPU, render GPU).
   Result:
4. **Same with V-Sync on:** does it hold the screen's refresh rate (e.g.
   120 Hz) without frames over budget? Result:
5. **Test card, V-Sync off:** line 1 and 2 again. Result:
6. **Steam Frame only, both builds:** compare the x86_64 (FEX) and arm64
   numbers from check 3. How much slower is the emulated build? Result:
7. **Anything visibly wrong** (missing lights or shadows, flicker, wrong
   colours) in the renderer features scene on each device, especially the
   Steam Frame's graphics driver. Result:
8. **5800X only:** for the logic number in check 3, the rough rule is that
   about 1.6 ms on the 5800X would use the whole 3 ms logic budget on the
   minimum spec. (Today it should be near zero.) Result:

## 4. Report back

Paste the numbers per device and build. They become the baseline in
`docs/progress/`, and any device problem becomes an issue or an open
question.
