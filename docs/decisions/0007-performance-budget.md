# ADR-0007: Performance budget

- **Status:** Accepted 2026-10-09. The proposed macOS and Steam Deck targets
  were dropped by the lead (Q16): no performance target is set for them.
- **Date:** 2026-10-09
- **Decided by:** Project lead (Q4: 120 fps on a GTX 1050 Ti; CPU pairing
  accepted); remaining values from the engineer's proposal

## Context

The brief refers to a performance budget held in an ADR, and requires the
lead's approval for anything that alters it. The lead set the target on
2026-10-09: ideally 120 fps on a GTX 1050 Ti, with the engineer's proposed CPU
pairing accepted. The values below are binding.

## Decision (structure)

The budget will define:

1. **Minimum-spec machine** for each desktop platform (CPU, GPU, RAM).
2. **Frame rate target** on minimum spec, and the frame-time split between
   gameplay logic, rendering and audio.
3. **Memory ceiling** (RAM in use during play).
4. **Load-time ceilings** (cold start, base ↔ adventure area transitions).
5. **Install size ceiling.**
6. **Which of these CI measures automatically** (headless measurements are
   possible for logic time and memory; rendering performance on real hardware
   is not and goes on a playtest checklist).

## Values

| Item | Value |
|---|---|
| **Minimum spec (Windows, Linux)** | GTX 1050 Ti 4 GB; Intel Core i5-7400 or AMD Ryzen 5 1600; 8 GB RAM; SSD |
| **Target on minimum spec** | 120 fps sustained at any supported screen size (ADR-0008), on a 120 Hz+ display |
| **Floor on minimum spec** | never below 60 fps, including the busiest scenes |
| **Frame time at 120 fps** | game logic ≤ 3 ms, rendering (CPU side) ≤ 3 ms, headroom ≥ 2.3 ms |
| **RAM** | ≤ 1.5 GB in play |
| **Video memory** | ≤ 1 GB |
| **Loads** | cold start ≤ 5 s; base ↔ area transition ≤ 1.5 s, on SSD |
| **Install size** | ≤ 1 GB |

The reasoning (why the CPU, not the GPU, is the risk at 640×360; 120 Hz
displays; physics interpolation) is in `docs/design/open-questions.md`, Q4.

**How it is checked** (Q16, decided 2026-10-09): no minimum-spec machine
exists, so the target cannot be verified on its own hardware. Day to day,
budgets are measured on the lead's Ryzen 7 5800X, which is about 1.84× faster
per core than the i5-7400 (Geekbench 5 and 6 single-core): game logic should
stay under about 1.6 ms there. CI tracks logic time and memory for
regressions once there is a simulation to measure. The lead also measures
on a Steam Frame (Snapdragon 8 Gen 3), with the x86 build through FEX and with
a native Linux ARM64 test build, as a weak-device stress test. The in-build
overlay (F3) shows the numbers; runs follow
`docs/playtests/2026-10-09-performance-devices.md`.

## Consequences

- Code is designed for the budget from the start: per-frame work kept small,
  crops and other slow processes updated on timers, off-screen objects asleep.
- An in-game frame-time display and a headless benchmark arrive with the first
  gameplay system.
- Moving objects at 120 fps need physics interpolation or 120 Hz physics; that
  affects how movement feels and comes to the lead with the first moving
  character.
- Since the scene renders at full screen resolution (ADR-0008 Amendment 3),
  lights, shadows and shaders cost GPU time per screen pixel: about 9× the
  work of 640×360 at 1080p and 32× at 5120×1440. The values are unchanged,
  but the GPU is no longer negligible; full-screen effects must be measured.
- Changing any value requires the lead's approval and a superseding ADR.
