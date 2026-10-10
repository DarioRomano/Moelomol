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

After this milestone: Q4, Q5, Q12 and Q15 decided and implemented
(fullscreen with shortcuts, ultrawide, UI width setting, renderer feature
check). Q8 and Q16 decided; full-resolution rendering, ARM64 test build and
frame-time overlay added.

## Milestone 2: Art and audio direction slice (not started)

Blocked on: nothing. Q2 (placeholders now), Q3 (AI audio from the prompts in
`docs/design/audio-prompts.md`, run by the lead) and Q9 (the pet, ADR-0010)
were answered 2026-10-09. Audio files depend on the lead generating them and
confirming the tools' licence terms.

- Placeholder art for the base area as listed in
  `docs/design/art-direction.md`, including the pet, recorded in the asset register.
- A showcase scene of the base, rendered for review; no gameplay.
- Audio bus layout; base music and ambience once the lead has generated them.
- A playtest checklist for the lead to judge the mood on real screens and
  speakers.

## Combat prototype (started 2026-10-10)

`docs/design/combat.md` and `docs/design/combat-art-prompts.md`: four
weapons (greatsword, hammer, bow, magic), the shared foundation (dodge,
stamina, poise and stagger, lock-on), stacking effects and Release. The lead
approved the design with Q18 (top-down ¾, ADR-0014) and Q19 (two weapons with
a swap) on 2026-10-10.

- **Done:** combat test arena with the shared foundation and the greatsword
  (2026-10-10); hammer, armour and the two-weapon swap (2026-10-10); bow
  (2026-10-10); magic and the status-effect system (2026-10-10). All four
  weapons exist.
- **Next:** tuning from the lead's playtests; then the lead decides what
  follows (the combat prototype has no further planned step).
- **Waiting on the lead:** arena playtest
  (`docs/playtests/2026-10-10-combat-arena.md`), hammer, bow and magic
  playtests (`docs/playtests/2026-10-10-hammer.md`,
  `docs/playtests/2026-10-10-bow.md`, `docs/playtests/2026-10-10-magic.md`).

## Later (not planned)

Decided and ready for the first gameplay system: language (ADR-0003),
performance budget and how it is checked (ADR-0007, Q16), renderer
(ADR-0012), input model (ADR-0013), display with full-resolution rendering
and UI width (ADR-0008). Q17 decided: keep whole-number scaling. Waiting on the lead: the device performance runs
(`docs/playtests/2026-10-09-performance-devices.md`).

Farming, exploration and foraging, combat, crafting and enhancement, upgrade
systems, skills, trinkets and artefacts, notes and story. These are named in
ADR-0005 but are not scheduled and are not to be built speculatively.
