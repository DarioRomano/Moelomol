# ADR-0011: Git LFS for large assets

- **Status:** Accepted
- **Date:** 2026-10-09
- **Decided by:** Project lead (open question Q11, 2026-10-09: "use Git LFS for
  larger assets"); patterns, limit and CI details by the engineer

## Context

Music and ambience (AI-generated, Q3), art source files and any video would
bloat plain git history forever. Git LFS stores them outside the history.
GitHub's free LFS allowance for personal accounts is 10 GiB of storage and
10 GiB of download bandwidth per month, and **downloads by GitHub Actions count
against the bandwidth** (GitHub billing docs, checked 2026-10-09). Over the
allowance with no payment method, LFS is disabled until the next month.

## Decision

**What goes through LFS** (patterns in `.gitattributes`):
- audio: `*.wav *.ogg *.mp3 *.flac`
- art source files: `*.aseprite *.ase *.psd *.kra *.xcf`
- video: `*.mp4 *.webm *.ogv`

**What stays in plain git:** everything else, including pixel-art PNGs (small),
fonts, Godot scenes and resources, and the `*.import` / `*.uid` sidecars.

**Guard:** `tools/ci/check_large_files.py` (run by `tools/run-tests.sh`, so in
the Headless tests check) fails if any tracked file over **1 MiB** is not in
LFS, or if a file matching an LFS pattern was committed as raw content (a
machine without `git lfs install`). It reads the index, so it needs neither
git-lfs nor the downloaded files.

**CI:** every job that needs the project's files runs
`.github/actions/lfs-pull`, which caches `.git/lfs` keyed on the exact set of
LFS objects in the commit, so a given set of files is downloaded from LFS once
and then served from the Actions cache.

## Consequences

- Everyone committing assets must run `git lfs install` once per machine.
  Cloning without git-lfs gives pointer files instead of audio.
- The bandwidth allowance is the real limit: each cache miss downloads every
  LFS file once. With, say, 300 MB of audio, about 30 cache misses a month
  would use the free 10 GiB. Changing any LFS file changes the cache key.
  Worth watching once audio arrives; the lead can see usage in GitHub's
  billing settings.
- Changing the patterns later only affects new commits; moving existing files
  into LFS would need `git lfs migrate`, which rewrites history and needs the
  lead's approval.
- Uploading LFS files from the engineer's environment has not been tried yet
  (the LFS API answered a read request on 2026-10-09).

## Verification

`tools/ci/test_check_large_files.py` (7 tests, each break seen to fail). A real
3 MB `.wav` committed through git-lfs became a 132-byte pointer and passed the
check.
