# ADR-0009: CI, pull-request builds and releases

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (instruction of 2026-10-09); engineering details by
  the engineer

## Context

The lead asked for: CI that builds every pull request; pull requests that carry
change notes and runnable builds; a release with runnable builds for all
platforms on every merge to `main`; tests for each new feature in each pull
request. ADR-0006 already names four required checks.

## Decision

**Pull requests** (`.github/workflows/pull-request.yml`) run five checks:

| Check (job name) | What it does |
|---|---|
| Change notes | Fails unless the PR description has a filled-in `## Change notes` section |
| Headless tests | `tools/run-tests.sh` |
| Web build | Exports the web build and uploads it |
| Desktop export | Exports Windows, macOS and Linux, smoke-runs the Linux build, uploads all three |
| Visual review renders | `tools/render-showcase.sh` under a virtual display; uploads the PNGs |

A sixth job, "Post build links", keeps one comment on the PR updated with the
check results and download links. It is informational, not part of the gate.

**The merge gate** of ADR-0006 is the four checks named there **plus Change
notes**, which enforces the lead's instruction that PRs carry change notes.

**Every new feature comes with tests in the same PR**, and each test is seen to
fail when the code it covers is broken (ADR-0006). The PR template asks for
both.

**Releases** (`.github/workflows/release.yml`): every push to `main` (in
practice, every merged PR) runs the tests, exports Windows, macOS and Linux,
smoke-runs the Linux build, and publishes a GitHub release:
- tag `v<application/config/version>-build.<run number>`, for example
  `v0.1.0-build.3`;
- marked as a pre-release while the version is below 1.0;
- notes are the title and Change notes of every PR merged since the previous
  release, oldest first, plus how to run each download (corrected
  2026-10-09: the first version took only one PR per release, see the
  progress note of that date on release notes);
- assets are one zip per desktop platform. The web build is not released
  (open question Q7).

**Tooling choices**
- Only GitHub's own actions (`actions/checkout@v7`, `actions/cache@v6`,
  `actions/upload-artifact@v7`) and the `gh` CLI preinstalled on runners. No
  third-party actions, which would be external dependencies.
- Godot is downloaded from the official GitHub release by
  `tools/install-godot.sh` and cached; only the export templates the presets
  use are kept.
- Tests use a small in-house runner (`tests/runner/`), not GUT or gdUnit4,
  which would be addons needing approval. Any error logged while a test runs
  fails that test, using the engine's `Logger` class.
- Renders use Xvfb and Mesa's software OpenGL (llvmpipe) with the
  Compatibility renderer.
- Builds are not code-signed or notarised: no signing certificates exist.

## Consequences

- Each PR produces downloadable builds for all three desktop platforms and the
  web, kept 14 days; downloads need a GitHub login.
- Each merge produces a permanent public release. The repository's releases
  page is the changelog; there is no separate CHANGELOG file, because CI
  committing to `main` would break ADR-0006.
- Windows SmartScreen and macOS Gatekeeper warn about unsigned builds; the
  release notes explain how to open them. Signing needs certificates (secrets
  the engineer does not have) and will be raised when builds go to players.
- The export templates download is about 1.3 GB on a cache miss.
- Build numbers can skip: GitHub keeps at most one waiting run per
  concurrency group, so when PRs are merged seconds apart a waiting release
  run is replaced by the newer one (seen 2026-10-09: no `build.4`). Nothing is
  lost: the next release lists every PR merged since the previous one.
- The engineer cannot read Actions job logs from this environment (only check
  results and annotations), so every tool prints its failures as `::error`
  annotations.
- Branch protection is still not configured, so the gate remains advisory.

## Verification

The workflows run on their own introducing pull request. Tests for the change
notes parser live in `tools/ci/test_change_notes.py` and run as part of
`tools/run-tests.sh`.
