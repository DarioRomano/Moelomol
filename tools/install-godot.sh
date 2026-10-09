#!/usr/bin/env bash
# Installs the pinned Godot editor (Linux x86_64) and, with --templates, the
# export templates needed by CI. Prints the editor path on the last line.
#
#   tools/install-godot.sh [--templates] [install_dir]
#
# install_dir defaults to $HOME/.cache/moelomol-godot. Downloads are skipped
# when the files are already there (CI caches that directory).
set -euo pipefail

VERSION="4.7.2"
TAG="${VERSION}-stable"
BASE="https://github.com/godotengine/godot/releases/download/${TAG}"
# Only the templates the presets in export_presets.cfg use are kept.
TEMPLATES_NEEDED=(
  version.txt
  linux_release.x86_64 linux_debug.x86_64
  linux_release.arm64 linux_debug.arm64
  windows_release_x86_64.exe windows_debug_x86_64.exe
  windows_release_x86_64_console.exe windows_debug_x86_64_console.exe
  macos.zip
  web_nothreads_release.zip web_nothreads_debug.zip
)

WITH_TEMPLATES=0
if [ "${1:-}" = "--templates" ]; then WITH_TEMPLATES=1; shift; fi
DIR="${1:-$HOME/.cache/moelomol-godot}"
mkdir -p "$DIR"

EDITOR="$DIR/Godot_v${TAG}_linux.x86_64"
if [ ! -x "$EDITOR" ]; then
  curl -fsSL -o "$DIR/editor.zip" "$BASE/Godot_v${TAG}_linux.x86_64.zip"
  unzip -oq "$DIR/editor.zip" -d "$DIR"
  rm "$DIR/editor.zip"
  chmod +x "$EDITOR"
fi

if [ "$WITH_TEMPLATES" = 1 ]; then
  CACHED="$DIR/templates"
  if [ ! -f "$CACHED/version.txt" ]; then
    curl -fsSL -o "$DIR/templates.tpz" "$BASE/Godot_v${TAG}_export_templates.tpz"
    mkdir -p "$CACHED"
    unzip -oq "$DIR/templates.tpz" "${TEMPLATES_NEEDED[@]/#/templates/}" -d "$DIR/unpack"
    mv "$DIR/unpack/templates/"* "$CACHED/"
    rm -rf "$DIR/unpack" "$DIR/templates.tpz"
  fi
  TARGET="$HOME/.local/share/godot/export_templates/${VERSION}.stable"
  mkdir -p "$TARGET"
  cp -n "$CACHED/"* "$TARGET/"
fi

echo "$EDITOR"
