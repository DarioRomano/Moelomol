#!/usr/bin/env bash
# Exports runnable builds and packages each as a zip in dist/.
#
#   tools/export.sh <platform...>     platforms: windows macos linux web
#
# Environment:
#   GODOT          Godot 4.7.2 editor binary (default: godot)
#   BUILD_NUMBER   written into the build stamp (default: dev)
#   BUILD_COMMIT   written into the build stamp (default: current git commit)
#   BUILD_LABEL    used in zip names (default: dev)
#
# Export templates must be installed (tools/install-godot.sh --templates).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"
BUILD_NUMBER="${BUILD_NUMBER:-dev}"
BUILD_COMMIT="${BUILD_COMMIT:-$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo dev)}"
BUILD_LABEL="${BUILD_LABEL:-dev}"
DIST="$ROOT/dist"

if [ "$#" -eq 0 ]; then
  echo "usage: tools/export.sh windows|macos|linux|web ..." >&2
  exit 2
fi

"$ROOT/tools/check-godot-version.sh"

# The stamp is read at runtime by src/core/build_info.gd. It is git-ignored.
printf '{"build": "%s", "commit": "%s"}\n' "$BUILD_NUMBER" "$BUILD_COMMIT" > "$ROOT/build_stamp.json"
trap 'rm -f "$ROOT/build_stamp.json"' EXIT

"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1
mkdir -p "$DIST"

export_one() {
  local preset="$1" out="$2"
  mkdir -p "$(dirname "$out")"
  local log
  log="$(mktemp)"
  # Godot can print export errors yet exit 0, so the output file is checked too.
  if ! "$GODOT" --headless --path "$ROOT" --export-release "$preset" "$out" >"$log" 2>&1 || [ ! -s "$out" ]; then
    cat "$log" >&2
    echo "Export failed: $preset" >&2
    [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Export failed::$preset (see job log)"
    rm -f "$log"
    return 1
  fi
  if grep -E "^(ERROR|SCRIPT ERROR)" "$log" >&2; then
    echo "Export of $preset logged errors" >&2
    [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Export logged errors::$preset: $(grep -m1 -E '^(ERROR|SCRIPT ERROR)' "$log")"
    rm -f "$log"
    return 1
  fi
  rm -f "$log"
}

for platform in "$@"; do
  name="Moelomol-${BUILD_LABEL}-${platform}"
  stage="$ROOT/build/$platform"
  rm -rf "$stage"
  case "$platform" in
    windows)
      export_one "Windows Desktop" "$stage/Moelomol.exe"
      (cd "$stage" && zip -qr "$DIST/$name.zip" .)
      ;;
    linux)
      export_one "Linux" "$stage/Moelomol.x86_64"
      chmod +x "$stage/Moelomol.x86_64"
      (cd "$stage" && zip -qr "$DIST/$name.zip" .)
      ;;
    macos)
      # Godot's macOS export is already a zip containing Moelomol.app.
      export_one "macOS" "$stage/Moelomol.zip"
      cp "$stage/Moelomol.zip" "$DIST/$name.zip"
      ;;
    web)
      export_one "Web" "$stage/index.html"
      (cd "$stage" && zip -qr "$DIST/$name.zip" .)
      ;;
    *)
      echo "Unknown platform: $platform" >&2
      exit 2
      ;;
  esac
  echo "Packaged $DIST/$name.zip"
done
