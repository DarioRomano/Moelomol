# 2026-10-14: Web preview on GitHub Pages, and freeing Actions storage

The lead reported the GitHub Actions storage as full and asked (1) to delete
every release except the most recent, and (2) to put the web build on a GitHub
Pages site.

## Done

- **Storage.** Release downloads do not count toward the Actions storage
  quota; workflow artifacts do. The repository held 250 PR build artifacts
  (6.7 GB, every one from an already-merged PR) and 26 releases (3.7 GB, not
  counted). The engineer put this to the lead, who chose to delete the
  artifacts only. All 250 were deleted through the REST API
  (`DELETE repos/DarioRomano/Moelomol/actions/artifacts/<id>`); a recount
  showed 0 left. **No release was deleted.** GitHub recalculates the storage
  figure some hours later, not at once.
- **Web preview.** New workflow `.github/workflows/pages.yml` ("Web preview"):
  on every push to `main` and by hand, export the web build with
  `tools/export.sh web` and deploy `build/web` with
  `actions/upload-pages-artifact@v5` and `actions/deploy-pages@v5` (latest
  major tags, read from the actions' repositories; their inputs read from
  their `action.yml`). Kept apart from the release workflow so a failed
  deployment never blocks a release. The web preset has
  `variant/thread_support=false`, so the build needs no cross-origin
  isolation headers, which GitHub Pages cannot send.
- ADR-0004 and ADR-0009 additions; Q7 noted as revisited; README says where
  to play; Q40 asks how long to keep PR builds.

## Not done, and why

- **Enabling Pages.** The repository's Pages source must be set to "GitHub
  Actions" (Settings > Pages) by the owner. The Pages API is blocked from this
  environment, so the engineer could not do or check it. Until it is set, the
  Web preview workflow's deploy job fails; it can be re-run by hand after.
- **Web-specific work** (browser saves, audio unlock, load size): out of scope;
  the web build is a preview (ADR-0004).

## What broke, and how it was found

- Nothing broke. `actionlint` could not be installed here (the Go module
  proxy and `golang.org` are blocked), so the workflow was only parsed as
  YAML locally; its first real test is the first push to `main` after merge.
  The PR's own checks do not run it.

## Needs a human

`docs/playtests/2026-10-14-web-preview.md`.
