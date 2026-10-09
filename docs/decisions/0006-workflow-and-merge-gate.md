# ADR-0006: Development workflow and merge gate

- **Status:** Accepted. Merge gate extended by ADR-0009 (adds the Change notes
  check), on the lead's instruction of 2026-10-09.
- **Date:** 2026-10-09
- **Decided by:** Project lead (brief of 2026-10-09)

## Context

The project lead directs the work; an engineer (often a fresh thread with no
memory) implements it. Branch protection is not configured on GitHub, so the
merge gate has to be honoured by hand.

## Decision

**Branches and pull requests**
- The default branch is `main`. Never commit to it directly. The initial commit
  of 2026-10-09 was made directly to `main` on the lead's explicit instruction,
  because an empty repository has no branch for a PR to target. It is the only
  exception.
- One feature branch per change, named for the change. One coherent change per
  PR.
- Never force-push, rewrite history, or rename the default branch.

**Merge gate.** A PR is merged only when all four CI checks pass:
1. Headless tests
2. Web build
3. Desktop export
4. Visual review renders

Never merge a red PR. Never skip, disable or quarantine a test to get green.
Until Milestone 1 creates these checks, no PR can satisfy this gate. The PR that
adds CI is itself checked by the CI it adds. How documentation-only PRs opened
before then are handled is open question Q10; until the lead answers, they stay
open and unmerged.

**Verification before claiming something works**
- Run the headless suite. For visual changes, run the showcase renders and look
  at the images at more than one window size and aspect ratio.
- New tests are checked by breaking the code they cover and confirming they
  fail.
- Godot APIs are verified against the running 4.7.2 engine and recorded in the
  appendix of `docs/architecture.md`.
- Anything needing a human (feel, input, controller, audio mix, real-machine
  performance) goes on a checklist in `docs/playtests/` and is not claimed.

**Documentation**
- Every thread that changes something adds a note to `docs/progress/`.
- ADR for anything expensive to reverse; design doc for consequences; roadmap
  updated when a milestone moves.
- Genuine forks go to `docs/design/open-questions.md` with pros, cons and a
  recommendation, and are brought to the lead.

## Consequences

- Slower than committing straight to `main`, but every change is reviewable and
  CI-gated.
- Because the gate is advisory, a mistake is possible; the engineer must check
  CI status explicitly before every merge.
- Turning on branch protection would make the gate enforced. That is a
  repository setting for the lead; recommended once Milestone 1's CI exists.
