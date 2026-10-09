#!/usr/bin/env bash
# Creates or updates one comment on the pull request listing the runnable
# builds and renders from this CI run. Called by .github/workflows/pull-request.yml.
# All inputs arrive as environment variables (never interpolated into code).
set -euo pipefail

MARKER="<!-- moelomol-build-links -->"
REPO="${GITHUB_REPOSITORY:?}"

icon() { [ "$1" = "success" ] && echo "✅" || echo "❌ ($1)"; }
link() { [ -n "$2" ] && echo "[$1]($2)" || echo "$1 (not built)"; }

BODY="$(cat <<EOF
$MARKER
### Builds for this pull request

Commit \`${BUILD_COMMIT:0:7}\` · [CI run]($RUN_URL)

| Check | Result |
|---|---|
| Headless tests | $(icon "$RESULT_TESTS") |
| Web build | $(icon "$RESULT_WEB") |
| Desktop export | $(icon "$RESULT_DESKTOP") |
| Visual review renders | $(icon "$RESULT_RENDERS") |

**Runnable builds:** $(link Windows "$URL_WINDOWS") · $(link macOS "$URL_MACOS") · $(link Linux "$URL_LINUX") · $(link Web "$URL_WEB")
**Test build (not a supported platform):** $(link "Linux ARM64, e.g. Steam Frame" "${URL_LINUX_ARM64:-}")
**Renders to review:** $(link "Showcase images" "$URL_RENDERS")

Downloads need a GitHub login and expire after 14 days. The macOS build is
not notarised: right-click the app and choose Open the first time. The Linux
binary may need \`chmod +x\`. The web build must be served over HTTP, for
example \`python3 -m http.server\` in the unzipped folder.
EOF
)"

EXISTING="$(gh api "repos/$REPO/issues/$PR_NUMBER/comments" --paginate \
  --jq ".[] | select(.body | startswith(\"$MARKER\")) | .id" | head -n 1)"

if [ -n "$EXISTING" ]; then
  gh api -X PATCH "repos/$REPO/issues/comments/$EXISTING" -f body="$BODY" >/dev/null
  echo "Updated comment $EXISTING"
else
  gh api -X POST "repos/$REPO/issues/$PR_NUMBER/comments" -f body="$BODY" >/dev/null
  echo "Created comment"
fi
