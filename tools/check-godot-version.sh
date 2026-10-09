#!/usr/bin/env bash
# Fails unless $GODOT (or `godot`) is exactly the pinned engine (ADR-0002).
set -euo pipefail

GODOT="${GODOT:-godot}"
EXPECTED="4.7.2.stable.official"

if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
  echo "Godot not found (GODOT=$GODOT). Run tools/install-godot.sh." >&2
  exit 1
fi

ACTUAL="$("$GODOT" --version 2>/dev/null | tail -n 1)"
case "$ACTUAL" in
  "$EXPECTED".*) ;;
  *)
    echo "Wrong Godot version: got '$ACTUAL', need '$EXPECTED' (ADR-0002)." >&2
    [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Godot version::got '$ACTUAL', need '$EXPECTED'"
    exit 1
    ;;
esac
