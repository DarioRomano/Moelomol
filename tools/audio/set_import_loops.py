#!/usr/bin/env python3
"""After Godot has imported assets/audio/, marks the looping files as loops
in their .import sidecars (from assets/audio_manifest.json). Run, then let
the editor (or `godot --headless --import`) re-import."""
import json
import os
import re

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))


def main():
    manifest = json.load(open(os.path.join(ROOT, "assets", "audio_manifest.json")))
    changed = 0
    for rel, info in manifest.items():
        path = os.path.join(ROOT, rel + ".import")
        if not os.path.exists(path) or not info.get("loop"):
            continue
        text = open(path).read()
        new = re.sub(r"^loop=false$", "loop=true", text, flags=re.M)
        new = re.sub(r"^edit/loop_mode=\d+$", "edit/loop_mode=2", new, flags=re.M)  # 2 = Forward (verified in 4.7.2)
        if new != text:
            open(path, "w", newline="\n").write(new)
            changed += 1
    print("marked %d files as loops" % changed)


if __name__ == "__main__":
    main()
