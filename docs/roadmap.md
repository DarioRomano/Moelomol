# Roadmap

Updated whenever a milestone moves. Dates are when something actually happened,
not targets.

## Milestone 0: Foundation (done 2026-10-09)

- Repository created with `main`, `CLAUDE.md`, ADRs 0001–0007, art and audio
  direction drafts, open questions, this roadmap.
- No code, no Godot project, no CI.

## Milestone 1: Project skeleton and CI (done 2026-10-09, first pull request)

- `project.godot` with the ADR-0008 display settings, Compatibility renderer
  (Q5 working assumption) and typed GDScript (Q8 working assumption).
- Headless test runner, `tools/run-tests.sh`; showcase renders at six window
  sizes, `tools/render-showcase.sh`.
- Pull-request workflow: Change notes, Headless tests, Web build, Desktop
  export, Visual review renders, plus a build-links comment.
- Release workflow: every merge to `main` publishes Windows, macOS and Linux
  builds (ADR-0009).
- Playtest checklist for the lead: `docs/playtests/2026-10-09-foundation-build.md`.

Still open from this milestone: Q4 (performance budget, so no budget checks in
CI yet), Q5 and Q8 (working assumptions), Q12 (fullscreen).

## Milestone 2: Art and audio direction slice (not started)

Blocked on: nothing (Q2, Q3 and Q9 answered 2026-10-09; recorded in the
following pull request).

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
