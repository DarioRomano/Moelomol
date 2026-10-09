# ADR-0001: Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (brief of 2026-10-09)

## Context

Work on Moelomol is done across many separate threads by an engineer who starts
each thread with no memory of the previous one. Decisions that are not written
down get rediscovered, re-argued or silently contradicted.

## Decision

Decisions that are expensive to reverse are recorded as ADRs in
`docs/decisions/`, using `template.md`. ADRs are written from the project's
current requirements and added to as the project goes on. Changing or
superseding an ADR requires the project lead's approval and is done by writing a
new ADR, not by rewriting the old one.

Undecided forks do not become ADRs. They go in `docs/design/open-questions.md`
with options, pros and cons, and a recommendation, until the lead decides; the
decision then becomes an ADR (or a design-doc entry if it is cheap to reverse).

## Consequences

- A new thread can find out why things are the way they are.
- Some overhead per decision. Kept small by reserving ADRs for expensive
  decisions only.
