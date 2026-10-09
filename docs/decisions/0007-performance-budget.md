# ADR-0007: Performance budget

- **Status:** Proposed (structure agreed by the brief; numbers pending the
  project lead, open question Q4)
- **Date:** 2026-10-09
- **Decided by:** Pending project lead

## Context

The brief refers to a performance budget held in an ADR, and requires the
lead's approval for anything that alters it. No numbers have been set. This ADR
reserves that place and states what the budget must cover; the values are not
decided and must not be treated as binding until the lead accepts them.

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

## Proposed values

The engineer's proposed values are in `docs/design/open-questions.md`, Q4. They
are copied here only once the lead accepts them.

## Consequences

- Until accepted, no code may be justified or rejected on budget grounds; the
  engineer flags apparent performance risks in progress notes instead.
- Once accepted, changing any value requires the lead's approval and a
  superseding ADR.
