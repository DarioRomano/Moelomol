#!/usr/bin/env bash
# Prints release notes for the commit being released: the Change notes of
# every pull request merged since the previous release (oldest first), plus
# how to run each download. Called by .github/workflows/release.yml, before
# the new release exists. Any GitHub API failure stops the script (no
# half-made notes); every call's output is captured with $( ) so `set -e`
# sees failures.
#
# PREVIOUS_TAG overrides the previous-release lookup ("" = treat as the first
# release); used to test the script against the real repository.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?}"
SHA="${GITHUB_SHA:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  echo "release-notes: $1" >&2
  [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Release notes::$1"
  exit 1
}

if [ "${PREVIOUS_TAG+set}" = set ]; then
  PREV_TAG="$PREVIOUS_TAG"
else
  PREV_TAG="$(gh api "repos/$REPO/releases?per_page=1" --jq '.[0].tag_name // empty')" \
    || fail "could not list releases"
fi

# Commits in this release. The compare API lists up to 250 commits; a first
# release takes the first 100 commits of history. Both are far more than one
# release holds.
if [ -n "$PREV_TAG" ]; then
  COMMIT_LIST="$(gh api "repos/$REPO/compare/$PREV_TAG...$SHA" --jq '.commits[].sha')" \
    || fail "could not compare $PREV_TAG...$SHA"
else
  COMMIT_LIST="$(gh api "repos/$REPO/commits?sha=$SHA&per_page=100" --jq '.[].sha')" \
    || fail "could not list commits up to $SHA"
fi
[ -n "$COMMIT_LIST" ] || COMMIT_LIST="$SHA"

# The 100 most recently updated merged PRs into main; release_notes.py keeps
# those whose merge commit is in this release. (Asking which PR contains each
# commit misses PRs that reached main inside another PR: GitHub links a commit
# only to the first PR that merged it.)
PRS="$(gh api "repos/$REPO/pulls?state=closed&base=main&sort=updated&direction=desc&per_page=100" \
  --jq '[.[] | select(.merged_at != null) | {number, title, body, merged_at, merge_commit_sha}]')" \
  || fail "could not list merged pull requests"

NOTES="$(COMMITS="$COMMIT_LIST" PRS="$PRS" python3 -c '
import json, os
print(json.dumps({"commits": os.environ["COMMITS"].split(), "prs": json.loads(os.environ["PRS"])}))
' | python3 "$HERE/release_notes.py" "$SHA")" || fail "could not render notes"

printf '%s\n' "$NOTES"
cat <<'EOF'

## Downloads

- **Windows:** unzip and run `Moelomol.exe`. Windows may warn that the app is unrecognised (it is not signed); choose "More info", then "Run anyway".
- **macOS:** unzip and open `Moelomol.app`. The app is not notarised: the first time, right-click it and choose Open.
- **Linux:** unzip and run `./Moelomol.x86_64` (you may need `chmod +x Moelomol.x86_64` first).

These are development builds. There is no gameplay yet unless the notes above say otherwise.
EOF
