## Summary
<!-- One or two sentences: what this pull request does and why. -->

## Change notes
<!-- Required (CI checks it). What changed, written for the project lead and
     future players, one bullet per change. This becomes the release notes when
     the PR is merged. Say plainly what was left out and anything placeholder. -->

## How it was checked
<!-- Tests added for the new behaviour, and the deliberate break that proved
     each one fails. Renders looked at (which sizes). Godot APIs verified
     against the engine (recorded in docs/architecture.md). -->

## Needs a human
<!-- Anything that cannot be verified headlessly, with a link to the
     checklist in docs/playtests/. Write "Nothing" if so. -->

## Checklist
- [ ] Each new feature has tests, and each test was seen to fail when its code was broken
- [ ] `tools/run-tests.sh` passes
- [ ] Visual change: `tools/render-showcase.sh` run and the images looked at
- [ ] Progress note added in `docs/progress/`
- [ ] ADR / design doc / roadmap / open questions updated if affected
- [ ] All CI checks green before merging
