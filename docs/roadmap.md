# Roadmap

Updated whenever a milestone moves. Dates are when something actually happened,
not targets.

## Milestone 0: Foundation (done 2026-10-09)

- Repository created with `main`, `CLAUDE.md`, ADRs 0001–0007, art and audio
  direction drafts, open questions, this roadmap.
- No code, no Godot project, no CI.

## Milestone 1: Project skeleton and CI (not started)

Blocked on: Q1 (resolution and stretch), Q5 (renderer), Q8 (language).
Benefits from: Q4 (performance budget), Q10 (docs PR handling).

- `project.godot` with the decided display, rendering and input settings.
- A headless test runner and `tools/run-tests.sh`.
- `tools/render-showcase.sh` rendering showcase scenes at several window sizes
  and aspect ratios.
- GitHub Actions workflow with the four checks: Headless tests, Web build,
  Desktop export (Windows, macOS, Linux), Visual review renders.
- Engine version pin check (ADR-0002); untyped-code check (ADR-0003).
- First playtest checklist: open the desktop build on each of the lead's
  machines.

No gameplay in this milestone.

## Milestone 2: Art and audio direction slice (not started)

Blocked on: Milestone 1, Q2 (art source), Q3 (audio source). Benefits from Q9.

- Palette and placeholder (or real) art for the base area as listed in
  `docs/design/art-direction.md`, with an asset register.
- A showcase scene of the base, rendered for review; no gameplay.
- Audio bus layout and base ambience, if Q3 allows.
- A playtest checklist for the lead to judge the mood on real screens and
  speakers.

## Later (not planned)

Farming, exploration and foraging, combat, crafting and enhancement, upgrade
systems, skills, trinkets and artefacts, notes and story. These are named in
ADR-0005 but are not scheduled and are not to be built speculatively.
