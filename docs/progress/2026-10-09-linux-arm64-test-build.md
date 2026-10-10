# 2026-10-09: Linux ARM64 test build (Q16 option C)

## What was done

The lead will check performance on the Ryzen 7 5800X and on the Steam Frame
(Snapdragon 8 Gen 3), both through FEX with the x86 build (option B) and with
a native ARM64 build (option C). This PR adds the ARM64 build:

- Export preset `Linux ARM64` (Godot's official `linux_*.arm64` templates).
- `tools/export.sh linux-arm64`; every Linux export now checks the binary's
  CPU architecture with `file` (x86-64 / ARM aarch64).
- Built on every PR (linked in the build comment as a test build) and
  attached to every release, labelled "test build, not a supported platform".
- CI's template cache key bumped (v2) so the ARM64 templates are fetched.

## What broke, and how it was found

Nothing broke.

## Verified

- Exported locally: an `ELF 64-bit LSB executable, ARM aarch64` for GNU/Linux,
  27.6 MB zipped.
- The architecture check fails (exit 1, naming the real architecture) when
  the ARM64 preset is set to build x86_64.

## Not verified

- That the ARM64 build runs at all on the Steam Frame: it cannot run on CI's
  x86 machines. First real run is the lead's playtest
  (`docs/playtests/2026-10-09-performance-devices.md`, added with the
  frame-time overlay).
- Graphics drivers on the Steam Frame for OpenGL 3.3 (the Compatibility
  renderer).
