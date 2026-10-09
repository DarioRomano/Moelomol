#!/usr/bin/env bash
# Renders every showcase scene at several window sizes and aspect ratios into
# renders/ (or $1). LOOK AT THE IMAGES: blur, seams, wrong draw order and
# misplaced UI are only visible there.
#
# Needs Xvfb (xvfb-run) and an OpenGL 3.3 driver; on machines without a GPU,
# Mesa's software renderer (llvmpipe) is used. Uses $GODOT or `godot`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/renders}"
GODOT="${GODOT:-godot}"

# Scenes to review. Add new showcase scenes here.
SCENES=(
  "res://scenes/showcase/test_card.tscn"
  "res://scenes/boot/boot.tscn"
)
# Window sizes: 16:9 at 2x/3x, a non-integer 16:9 laptop, 16:10 (Steam Deck,
# MacBook-like), ultrawide, and 4:3.
SIZES=(1280x720 1920x1080 1366x768 1280x800 2560x1080 1024x768)

"$ROOT/tools/check-godot-version.sh"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1
mkdir -p "$OUT"

FAILED=0
for scene in "${SCENES[@]}"; do
  name="$(basename "$scene" .tscn)"
  for size in "${SIZES[@]}"; do
    file="$OUT/${name}_${size}.png"
    if ! LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}" \
        xvfb-run -a -s "-screen 0 ${size}x24" \
        "$GODOT" --path "$ROOT" --display-driver x11 --rendering-driver opengl3 \
        --audio-driver Dummy --resolution "$size" --position 0,0 \
        -s res://tools/render_showcase.gd -- --scene "$scene" --out "$file"; then
      echo "Render failed: $scene at $size" >&2
      [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::error title=Render failed::$scene at $size"
      FAILED=1
    fi
  done
done

exit "$FAILED"
