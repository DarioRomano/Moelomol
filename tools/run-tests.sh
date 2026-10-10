#!/usr/bin/env bash
# Runs the full headless test suite. Needs no display.
#
#   tools/run-tests.sh                  # all tests
#   tools/run-tests.sh --filter palette # only tests whose "path::name" contains "palette"
#
# Uses $GODOT if set, otherwise `godot` on PATH. Must be Godot 4.7.2 (ADR-0002);
# tools/install-godot.sh installs it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"

"$ROOT/tools/check-godot-version.sh"

# Repository check: large files must go through Git LFS (ADR-0011). Skipped
# outside a git checkout (for example an unpacked source archive).
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  python3 "$ROOT/tools/ci/check_large_files.py" "$ROOT"
fi

# Tests for the CI helper scripts (Python standard library only).
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -q -s "$ROOT/tools/ci" -p "test_*.py"

# A fresh checkout has no .godot/ cache, so class_name scripts are not yet
# registered. Importing builds the cache. --import exits non-zero on failure.
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || {
  echo "Import failed; rerunning with output:" >&2
  "$GODOT" --headless --path "$ROOT" --import
  exit 1
}

# Run the suite, then also fail on objects the engine reports as leaked at
# exit. Those messages come after the runner has finished, so its logged-error
# hook cannot see them (a reference cycle between two fighters was found this
# way, 2026-10-10).
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
set +e
"$GODOT" --headless --path "$ROOT" -s res://tests/runner/run_tests.gd -- "$@" 2>&1 | tee "$LOG"
STATUS="${PIPESTATUS[0]}"
set -e
if grep -Eq "instances were leaked at exit|resources still in use at exit" "$LOG"; then
  echo "Leak at exit: objects outlived the tests (see the engine's message above)." >&2
  [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Leak at exit::objects outlived the tests; look for a reference cycle"
  [ "$STATUS" -eq 0 ] && STATUS=1
fi
exit "$STATUS"
