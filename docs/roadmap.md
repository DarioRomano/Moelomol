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
stamina, poise and stagger, lock-on), stacking effects and the Siphon. The lead
approved the design with Q18 (top-down ¾, ADR-0014) and Q19 (two weapons with
a swap) on 2026-10-10.

- **Done:** combat test arena with the shared foundation and the greatsword
  (2026-10-10); hammer, armour and the two-weapon swap (2026-10-10); bow
  (2026-10-10); magic and the status-effect system (2026-10-10). All four
  weapons exist. Combat feel changes from the lead's first play: stagger
  resets attacks, +40% melee reach, held charge rumble, three-level hammer
  charge with a cone shockwave, telegraphs that match the hit zone
  (2026-10-10). Second round: quick roll, guard and riposte (Q30), bow
  stages and one-press Volley, Siphon on magic's heavy hold (Q29)
  (2026-10-10). The Rot seed on magic's skill (Q31 A, 2026-10-11).
- **Next:** tuning from the lead's playtests; then the lead decides what
  follows (the combat prototype has no further planned step).
- **Waiting on the lead:** arena playtest
  (`docs/playtests/2026-10-10-combat-arena.md`), hammer, bow and magic
  playtests (`docs/playtests/2026-10-10-hammer.md`,
  `docs/playtests/2026-10-10-bow.md`, `docs/playtests/2026-10-10-magic.md`),
  combat feel changes (`docs/playtests/2026-10-10-combat-feel.md`), round
  two (`docs/playtests/2026-10-10-combat-feedback-round-two.md`).

## Farming and the day–night cycle (started 2026-10-10)

`docs/design/farming.md`: the clock and its phases, overnight crop growth,
farming by magic with Mana, seeds without shops, controls at the base. The
lead decided Q21–Q27 on 2026-10-10.

- **Done:**
  - Farm test scene with the clock, the day–night tint, sleeping, tilling,
    watering, planting, overnight growth, harvesting and seeds back
    (2026-10-10).
  - The lead's decisions built: a 20-minute day that cycles on its own;
    farming by spells paid in Mana; the watering spell's tiers up to rain
    (2026-10-10).
- **Waiting on the lead:** farming playtest
  (`docs/playtests/2026-10-10-farming.md`). Q28 decided 2026-10-11.
- **Next:** saving, cooking (food restores Mana and gives buffs; the cat
  treats are the first recipe), farming upgrades, the pet at the farm, Mana
  costs for enhanced weapon skills.

## World: the farm and the first area (design started 2026-10-11)

`docs/design/world.md` (how the base and the areas fit together),
`docs/design/base.md` (the farm) and `docs/design/area-millbrook.md`
(Millbrook, the hamlet below the farm, with its objective: open the ford).
Proposals with layout sketches; nothing built. The lead decided Q33
(2026-10-11): the farm is much bigger but overgrown, and each boss defeated
opens more of it; redrawn as a 160 × 96 farm with the homestead and six
parcels.

- **Decided (2026-10-11):** the lead accepted every recommendation: the
  camera (ADR-0015), separate scenes (ADR-0016), starting weapons, falling,
  objectives and the notes satchel, a boss's heart opening its parcel, and
  how farming magic looks (Q28).
- **Layouts accepted (2026-10-11):** the farm and Millbrook.
- **The lead's order (2026-10-11):** more varied enemies, Millbrook and its
  themed boss first; the farm after.

## Millbrook, the first area (started 2026-10-11)

`docs/design/enemies.md` (archetypes, Millbrook's six creatures, Grist the
miller's boar) and `docs/design/area-millbrook.md` (zone-by-zone
encounters). Built in stages, each its own pull request:

1. **Design:** enemies and the boss, the encounter plan (2026-10-11).
2. **Creatures:** creature kinds in the combat simulation, the six
   Millbrook creatures and Grist, with tests and review renders; playable
   in the arena with F11 and F12 (2026-10-11). Playtest:
   `docs/playtests/2026-10-11-creatures-and-grist.md`.
3. **The area:** Millbrook walkable from the accepted map; collision from
   the map; the camera (ADR-0015); the clock with day and night rosters;
   falling (2026-10-11). Two map corrections (wheat field gap, brook to
   the south edge). Playtest: `docs/playtests/2026-10-11-millbrook-walkable.md`.
4. **The objective:** notes and the satchel, the crank, the sluice, the
   flood draining, the ford, Grist's heart (2026-10-11; falling came with
   stage 3). Interact F / B and satchel I / View chosen by the lead.
   Playtest: `docs/playtests/2026-10-11-millbrook-objective.md`.

**Millbrook is complete as far as it can be without the farm.**

## The farm, the title screen and saving (started 2026-10-12)

The lead asked for a title screen that starts at the farm or the last save,
and for saving; and chose to build the real farm first, to save when
sleeping and at the gate, and to keep one save (2026-10-12).

1. **The farm** from the accepted layout, joined to Millbrook at the south
   gate (ADR-0016); one clock, bag and Mana for the game; each place
   remembers itself; falling wakes the player at the farm (2026-10-12).
   Playtest: `docs/playtests/2026-10-12-the-farm.md`.
2. **The title screen and saving.**

Then, from `base.md`'s order: the house inside with the bed, the Clear
spell, the cat, Grist's heart opening the great fields.

## Later (not planned)

Decided and ready for the first gameplay system: language (ADR-0003),
performance budget and how it is checked (ADR-0007, Q16), renderer
(ADR-0012), input model (ADR-0013), display with full-resolution rendering
and UI width (ADR-0008). Q17 decided: keep whole-number scaling. Waiting on the lead: the device performance runs
(`docs/playtests/2026-10-09-performance-devices.md`).

Exploration and foraging, crafting and enhancement, upgrade systems, skills,
trinkets and artefacts, notes and story, animals. These are named in
ADR-0005 but are not scheduled and are not to be built speculatively.
