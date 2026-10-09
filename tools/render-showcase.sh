#!/usr/bin/env bash
# Renders every showcase scene at several window sizes and aspect ratios into
# renders/ (or $1). LOOK AT THE IMAGES: blur, seams, wrong draw order and
# misplaced UI are only visible there.
#
# Needs Xvfb (xvfb-run) and an OpenGL 3.3 driver; on machines without a GPU,
# Mesa's software renderer (llvmpipe) is used. Uses $GODOT or `godot`.
# If `openbox` is installed it runs as the window manager, which lets X11
# report fullscreen, and every render then also checks the window mode. CI
# installs it; without it the mode is not checked (a warning says so).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/renders}"
GODOT="${GODOT:-godot}"

# Scenes to review. Add new showcase scenes here.
SCENES=(
  "res://scenes/showcase/test_card.tscn"
  "res://scenes/boot/boot.tscn"
  "res://scenes/showcase/renderer_features.tscn"
)
# Window (= screen, the game starts fullscreen) sizes:
#   16:9 at 2x, 3x and 4x; a non-integer 16:9 laptop; 16:10 (Steam Deck,
#   MacBook-like); 21:9 at 1080p and 1440p; 32:9 at 1080p and 1440p; 4:3.
SIZES=(1280x720 1920x1080 2560x1440 1366x768 1280x800 2560x1080 3440x1440 3840x1080 5120x1440 1024x768)

"$ROOT/tools/check-godot-version.sh"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1
mkdir -p "$OUT"

# The outcome is also left as a CI annotation, because job logs cannot be read
# from the engineer's environment but annotations can.
if command -v openbox >/dev/null 2>&1; then
  WM_CHECK=(--check-window-mode)
  [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::notice title=Window mode::checked on every render (openbox running)"
else
  WM_CHECK=()
  echo "WARNING: openbox not installed; window mode (fullscreen) is NOT checked." >&2
  [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::warning title=Window mode::NOT checked: openbox not installed"
fi

# Runs one render inside its own virtual display, with the window manager
# first when there is one.
render_one() {
  local size="$1"; shift
  if [ "${#WM_CHECK[@]}" -gt 0 ]; then
    xvfb-run -a -s "-screen 0 ${size}x24" sh -c '
      openbox >/dev/null 2>&1 & sleep 1
      "$@"; status=$?; kill %1 2>/dev/null; exit $status' sh "$@"
  else
    xvfb-run -a -s "-screen 0 ${size}x24" "$@"
  fi
}

FAILED=0
for scene in "${SCENES[@]}"; do
  name="$(basename "$scene" .tscn)"
  for size in "${SIZES[@]}"; do
    file="$OUT/${name}_${size}.png"
    log="$(mktemp)"
    if LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}" render_one "$size" \
        "$GODOT" --path "$ROOT" --display-driver x11 --rendering-driver opengl3 \
        --audio-driver Dummy --resolution "$size" --position 0,0 \
        -s res://tools/render_showcase.gd -- --scene "$scene" --out "$file" "${WM_CHECK[@]}" \
        >"$log" 2>&1; then
      grep "^render_showcase:" "$log" || true
    else
      cat "$log" >&2
      reason="$(grep -m1 "^render_showcase ERROR:" "$log" || echo "no error line from render_showcase (crash?)")"
      echo "Render failed: $scene at $size: $reason" >&2
      [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Render failed::$scene at $size: $reason"
      FAILED=1
    fi
    rm -f "$log"
  done
done

# UI width setting (Q15): HUD frame at each width on 32:9 and 21:9 screens.
# Format: scene size ui-width
VARIANTS=(
  "res://scenes/showcase/test_card.tscn 5120x1440 21:9"
  "res://scenes/showcase/test_card.tscn 5120x1440 16:9"
  "res://scenes/showcase/test_card.tscn 3440x1440 21:9"
  "res://scenes/showcase/test_card.tscn 3440x1440 16:9"
)
for variant in "${VARIANTS[@]}"; do
  read -r scene size ui <<<"$variant"
  name="$(basename "$scene" .tscn)"
  file="$OUT/${name}_${size}_ui-${ui/:/-}.png"
  log="$(mktemp)"
  if LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}" render_one "$size" \
      "$GODOT" --path "$ROOT" --display-driver x11 --rendering-driver opengl3 \
      --audio-driver Dummy --resolution "$size" --position 0,0 \
      -s res://tools/render_showcase.gd -- --scene "$scene" --out "$file" --ui-width "$ui" "${WM_CHECK[@]}" \
      >"$log" 2>&1; then
    grep "^render_showcase:" "$log" || true
  else
    cat "$log" >&2
    reason="$(grep -m1 "^render_showcase ERROR:" "$log" || echo "no error line from render_showcase (crash?)")"
    echo "Render failed: $scene at $size, UI $ui: $reason" >&2
    [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Render failed::$scene at $size, UI $ui: $reason"
    FAILED=1
  fi
  rm -f "$log"
done

exit "$FAILED"
