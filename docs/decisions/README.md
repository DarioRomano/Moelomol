# Architecture decision records

Each file records one decision that is expensive to reverse: what was decided,
why, and what it costs. Format: `NNNN-short-title.md`, numbered in order, never
renumbered. Use `template.md`.

Statuses: **Proposed** (written, waiting for the project lead), **Accepted**,
**Superseded by ADR-NNNN**, **Rejected**.

Changing or superseding an ADR needs the project lead's approval. To change a
decision, write a new ADR that supersedes the old one and update the old one's
status line; do not edit the substance of an accepted ADR in place.
Clarifications that do not change the decision (typos, links) are fine.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-engine-godot-4-7-2.md) | Engine: Godot 4.7.2 stable, pinned | Accepted |
| [0003](0003-language-typed-gdscript.md) | Language: statically typed GDScript | Proposed |
| [0004](0004-target-platforms.md) | Target platforms | Accepted |
| [0005](0005-core-design-constraints.md) | Core design constraints | Accepted |
| [0006](0006-workflow-and-merge-gate.md) | Development workflow and merge gate | Accepted |
| [0007](0007-performance-budget.md) | Performance budget | Proposed (values pending Q4) |
