# 2026-10-09: Initial commit and foundation docs

## What was done

- Created `main` with the initial commit, directly, on the lead's explicit
  instruction (the repository was empty, so there was no branch for a PR to
  target). Recorded as the single exception in ADR-0006.
- Added `README.md`, `CLAUDE.md`, `.gitignore`, `.gitattributes`.
- ADRs from the brief's current requirements: 0001 (record decisions), 0002
  (Godot 4.7.2 pinned), 0004 (platforms), 0005 (core design constraints), 0006
  (workflow and merge gate), all Accepted. 0003 (typed GDScript) is Proposed,
  because the language was the engineer's call. 0007 (performance budget) is
  Proposed with the structure only; the brief's "[ADR number]" placeholder for
  the performance budget now refers to ADR-0007.
- Design drafts: `docs/design/art-direction.md`, `docs/design/audio-direction.md`.
- `docs/design/open-questions.md`: 11 questions with options, pros, cons and
  recommendations.
- `docs/roadmap.md`, `docs/architecture.md` (verified-API appendix),
  `docs/playtests/README.md`.

No Godot project, code, tests, CI or assets were created. Milestone 1 is blocked
on Q1, Q5 and Q8.

## What broke, and how it was found

- **No dry-run push on an empty repository.** `git push --dry-run` fails with
  "src refspec HEAD does not match any" before the first commit, so push access
  could only be confirmed by the real push.
- **GitHub release page returns 403 through the session proxy**, while the
  release asset download works. Found when checking that 4.7.2 exists; worked
  around by listing tags with `git ls-remote` and downloading the asset
  directly. The command is in `CLAUDE.md`.
- **Release-binary `--doctool` has no descriptions or deprecation flags.** Found
  while trying to confirm that `TileMap` is deprecated. Recorded in the
  architecture appendix so no one draws conclusions from it.
- **Engine default texture filter is Linear**, which blurs pixel art. Not a bug
  yet (no project exists); recorded so Milestone 1 sets Nearest explicitly.

## Not verified

Everything about look, sound and feel. The palette and art and audio rules are
drafts until shown on screen and through speakers.
