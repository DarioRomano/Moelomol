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
5. **Scale readout.** Bottom left says `scale Nx` and the view size; they
   should match the table in check 6 for your monitor. Result:
6. **Fullscreen.** The game starts fullscreen. Note the scale readout and
   whether black bars appear: 1920×1080 should show 3x, 2560×1440 4x, with no
   bars. On an ultrawide monitor, 2560×1080 should show 3x (view 853×360),
   3440×1440 4x (860×360); on a 32:9 monitor, 3840×1080 3x and 5120×1440 4x
   (both 1280×360). Result:
6b. **Leaving and re-entering fullscreen.** Windows and Linux: Alt+Enter
   switches to a window and back. macOS: Ctrl+Cmd+F does the same; also check
   the green window button still works, and that Ctrl+Cmd+F switches exactly
   once per press (if macOS also handles the shortcut itself, it could switch
   twice and appear to do nothing). Holding the keys down must not flicker.
   Result:
7. **Resizing** (skip unless you started it with `--windowed` from a
   terminal). Drag the window smaller and larger. The picture should jump
   between whole sizes (never blurry in between), with black bars when the
   window is not an exact multiple. Note anything that looks wrong. Result:
8. **Palette.** Do the 27 colours look as intended on your screen? Any that
   look too similar, or too saturated for the lonely tone? Result:
9. **Text.** Text is drawn at full screen resolution (since the
   full-resolution change). It should be sharp, smooth-edged and evenly spaced
   at every scale, including 1080p. The font itself is a placeholder. Result:
10. **macOS only:** does it run natively on Apple Silicon (Activity Monitor →
    "Kind" column says Apple)? Result:

## 4. Report back

Reply with the results per machine; failures become fixes or open questions.
