#!/usr/bin/env python3
"""Regenerates every image in assets/ and the review sheets in
docs/design/images/assets/. Usage: tools/art/build.py [module ...]"""
import importlib
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402

MODULES = ["ground", "nature", "buildings", "props", "player", "creatures", "effects", "icons", "ui", "mock"]


def main(argv):
    wanted = argv or MODULES
    for name in MODULES:
        if not os.path.exists(os.path.join(os.path.dirname(__file__), name + ".py")):
            continue
        made = importlib.import_module(name).build()
        if name in wanted and made:
            lib.sheet(name, "Moelomol assets: " + name, made, scale=getattr(importlib.import_module(name), "SHEET_SCALE", 3))
        print("%-10s %d images" % (name, len(made or [])))
    lib.write_manifest("art_manifest.json")
    print("manifest: %d files" % len(lib.MANIFEST))


if __name__ == "__main__":
    main(sys.argv[1:])
