# ADR-0002: Engine: Godot 4.7.2 stable, pinned

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (brief of 2026-10-09)

## Context

The brief specifies Godot 4.7.2. Godot changes APIs and project-setting names
between minor versions, and much published material targets Godot 3 or early
Godot 4.

## Decision

The project uses Godot **4.7.2-stable** (official build, commit `ed1daf0bf`,
verified with `--version` on 2026-10-09). The editor, CI and export templates
all use exactly this version. The standard (non-.NET) build is used, see
ADR-0003.

Upgrading the engine, including patch releases, is a separate PR with its own
progress note, a full test and showcase-render run, and a review of the
verified-API appendix in `docs/architecture.md`.

## Consequences

- CI must download the pinned engine and export templates, not "latest".
- `project.godot` will carry `config/features=PackedStringArray("4.7", ...)`;
  opening the project in another version shows a warning.
- Anything learned about engine behaviour is recorded against 4.7.2 and must be
  rechecked on upgrade.

## Verification

Milestone 1 CI prints the engine version and fails if it is not
`4.7.2.stable.official`.
