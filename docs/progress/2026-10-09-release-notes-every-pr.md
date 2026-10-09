# 2026-10-09: Release notes list every PR in the release

## What was done

`tools/ci/release-notes.sh` now lists every pull request merged since the
previous release, oldest first, each with its Change notes. Rendering moved
to `tools/ci/release_notes.py` with 8 tests.

## What broke, and how it was found

- **Release v0.1.0-build.1 lacked PR #1's notes.** Found by reading the first
  real release after the lead merged #1 and #3. #3 was stacked on #1 and was
  merged first, so one push brought both to `main`, and the script only asked
  which PR the released commit belonged to.
- **First fix attempt also missed #1.** Asking GitHub which PRs contain each
  commit in the release returns only the *first* PR that brought the commit to
  `main` (#3 for all of #1's commits). Found by testing the script against the
  real repository. The working fix matches each merged PR's
  `merge_commit_sha` against the commits in the release range (GitHub
  recorded #1's merge commit as 6b914ec, which is in that range).
- **API failures produced garbage notes instead of failing.** A failing
  `gh api` call inside `<( … )` escapes `set -e`; a test run against a branch
  name printed "## Commit origin/". Every API call is now captured with
  `$( … ) || fail …`, which stops the script with an `::error` annotation.
- **One of my own tests could not detect a wrong sort order.** In the only
  ordering test, the first-merged PR also had the higher number, so sorting by
  PR number (descending) passed. Found by the deliberate-break run; a second
  ordering test now covers the other direction.

## Lesson

Avoid stacked PRs: merging the top of a stack first carries the lower PRs
into `main` in one push. Prefer independent branches from `main`.

## Verified against the real repository

- First-release case for `0c10df6` (as `v0.1.0-build.1` should have been):
  lists #3 then #1.
- A commit that does not exist: exit 1, "could not compare …", no notes.

## Test mutations (each confirmed to fail, then reverted)

No release-range filter; unmerged PRs kept; sort by PR number ascending; sort
by PR number descending; whole PR body instead of the Change notes section.

## Not done

`v0.1.0-build.1`'s published notes were left as they are; releases are not
edited by hand (CLAUDE.md). The next release covers only PRs merged after it.
