# ADR-0007: Performance budget

- **Status:** Accepted 2026-10-09 (Windows/Linux values). macOS and Steam Deck
  rows are proposed until the lead confirms them (Q16).
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
| macOS (proposed, Q16) | Apple M1, 8 GB: 120 fps on 120 Hz displays, 60 fps otherwise |
| Steam Deck (proposed, Q16) | 60 fps (LCD model) / 90 fps (OLED model) |

The reasoning (why the CPU, not the GPU, is the risk at 640×360; 120 Hz
displays; physics interpolation) is in `docs/design/open-questions.md`, Q4.

**How it is checked:** no minimum-spec machine exists; the approach is open
question Q16. Until it is answered, the working method is: day to day,
budgets are measured on the lead's Ryzen 7 5800X, which is about 1.84× faster
per core than the i5-7400 (Geekbench 5 and 6 single-core): game logic should
stay under about 1.6 ms there. CI tracks logic time and memory for
regressions once there is a simulation to measure. Real-hardware results go on
playtest checklists.

## Consequences

- Code is designed for the budget from the start: per-frame work kept small,
  crops and other slow processes updated on timers, off-screen objects asleep.
- An in-game frame-time display and a headless benchmark arrive with the first
  gameplay system.
- Moving objects at 120 fps need physics interpolation or 120 Hz physics; that
  affects how movement feels and comes to the lead with the first moving
  character.
- Changing any value requires the lead's approval and a superseding ADR.
