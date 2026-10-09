# Playtest: foundation build on real machines

**For:** the project lead. **Why:** CI can only start the Linux build in a
virtual display with software rendering. It cannot open the Windows or macOS
builds at all, or show how the pixels look on a real monitor.

## 1. Build

Download from the latest release on the repository's Releases page (or from the
"Builds for this pull request" comment on the PR): the zip for your platform.

## 2. Setup

Note for each machine: OS and version, CPU/GPU, monitor resolution, and whether
it is a laptop screen or an external monitor.

## 3. Checks

1. **It opens.** Windows: unzip, run `Moelomol.exe` (SmartScreen: More info →
   Run anyway). macOS: unzip, right-click `Moelomol.app` → Open. Linux: unzip,
   `chmod +x Moelomol.x86_64`, run it. You should see the title over a
   checkerboard.
   Result:
2. **Build label.** Bottom right shows `v0.1.0 build N (abc1234)` matching the
   release. Result:
3. **Pixels are sharp.** The two stripe blocks under the palette should be
   perfectly even black-and-white lines, no grey, no shimmer; the checkerboard
   squares all the same size. Result:
4. **Edges.** A thin yellow line is visible along all four edges of the game
   area, and a red square sits in each corner. Result:
5. **Scale readout.** Bottom left says `scale Nx`. In the default window this
   should be `2x`. Result:
6. **Maximised.** The game has no fullscreen option yet. Maximise the window
   (macOS: the green button makes it fullscreen, which is fine). Note the
   readout and whether black bars appear. A maximised window is a bit smaller
   than the monitor because of the taskbar or title bar, so expect one step
   less than fullscreen (for example 2x with bars on a 1920×1080 monitor).
   Result:
7. **Resizing.** Drag the window smaller and larger. The picture should jump
   between whole sizes (never blurry in between), with black bars when the
   window is not an exact multiple. Note anything that looks wrong. Result:
8. **Palette.** Do the 27 colours look as intended on your screen? Any that
   look too similar, or too saturated for the lonely tone? Result:
9. **Text.** The text is readable but the letter spacing is uneven (placeholder
   font). Tell me if it is worse than that, e.g. unreadable. Result:
10. **macOS only:** does it run natively on Apple Silicon (Activity Monitor →
    "Kind" column says Apple)? Result:

## 4. Report back

Reply with the results per machine; failures become fixes or open questions.
