#!/usr/bin/env bash
# Prints release notes for the commit being released: the Change notes of the
# pull request that was merged into it, plus how to run each download.
# Called by .github/workflows/release.yml.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?}"
SHA="${GITHUB_SHA:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PR_JSON="$(gh api "repos/$REPO/commits/$SHA/pulls" --jq '[.[] | select(.merged_at != null)][0] // empty')"

if [ -n "$PR_JSON" ]; then
  NUMBER="$(jq -r '.number' <<<"$PR_JSON")"
  TITLE="$(jq -r '.title' <<<"$PR_JSON")"
  NOTES="$(jq -r '.body // ""' <<<"$PR_JSON" | python3 "$HERE/change_notes.py" extract)"
  echo "## $TITLE (#$NUMBER)"
  echo
  if [ -n "$NOTES" ]; then echo "$NOTES"; else echo "_The pull request had no change notes._"; fi
else
  echo "## Commit ${SHA:0:7}"
  echo
  echo "_No merged pull request is associated with this commit; it was pushed to main directly._"
fi

cat <<'EOF'

## Downloads

- **Windows:** unzip and run `Moelomol.exe`. Windows may warn that the app is unrecognised (it is not signed); choose "More info", then "Run anyway".
- **macOS:** unzip and open `Moelomol.app`. The app is not notarised: the first time, right-click it and choose Open.
- **Linux:** unzip and run `./Moelomol.x86_64` (you may need `chmod +x Moelomol.x86_64` first).

These are development builds. There is no gameplay yet unless the notes above say otherwise.
EOF
