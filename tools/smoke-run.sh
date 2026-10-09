#!/usr/bin/env bash
# Unpacks an exported Linux build zip, runs it for a few seconds in a virtual
# display and fails if it crashes or logs an error. This proves the export
# starts; it says nothing about how the game feels (see docs/playtests/).
#
#   tools/smoke-run.sh dist/Moelomol-<label>-linux.zip
set -euo pipefail

ZIP="$(realpath "$1")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

unzip -q "$ZIP" -d "$WORK"
chmod +x "$WORK/Moelomol.x86_64"

set +e
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
  "$WORK/Moelomol.x86_64" --audio-driver Dummy --quit-after 120 >"$WORK/run.log" 2>&1
CODE=$?
set -e

if [ "$CODE" -ne 0 ] || grep -qE "^(ERROR|SCRIPT ERROR)" "$WORK/run.log"; then
  cat "$WORK/run.log"
  echo "Smoke run failed (exit $CODE)." >&2
  [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Smoke run failed::exit $CODE; $(grep -m1 -E '^(ERROR|SCRIPT ERROR)' "$WORK/run.log" || true)"
  exit 1
fi
echo "Smoke run passed: started, ran 120 frames, quit cleanly, no errors logged."
