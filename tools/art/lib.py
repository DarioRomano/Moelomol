"""Shared by the art builders: where files go, the manifest, review sheets."""
import json
import os
from px import Canvas
from font import width as text_width

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.path.join(ROOT, "assets")
SHEETS = os.path.join(ROOT, "docs", "design", "images", "assets")
MANIFEST = {}


def out(rel, canvas, frame=None, anims=None, **meta):
    """Saves assets/<rel>.png and records it. `frame` is (w, h) for strips and
    sheets; `anims` maps a name to {row, frames, fps, loop}."""
    path = os.path.join(ASSETS, rel + ".png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    canvas.save(path)
    entry = {"size": [canvas.w, canvas.h]}
    if frame:
        entry["frame"] = list(frame)
    if anims:
        entry["anims"] = anims
    entry.update(meta)
    MANIFEST["assets/" + rel + ".png"] = entry
    return canvas


def write_manifest(name):
    path = os.path.join(ASSETS, name)
    with open(path, "w", newline="\n") as f:
        json.dump(MANIFEST, f, indent=1, sort_keys=True)
        f.write("\n")


def sheet(name, title, items, scale=3, bg="1", width=1200, pad=6):
    """A review sheet: every item drawn `scale` times larger with its name.
    Not a game asset (docs/ is not imported)."""
    placed, x, y, row_h = [], pad, 16, 0
    for label, c in items:
        w = max(c.w * scale, text_width(label)) + pad
        if x + w > width and x > pad:
            x, y, row_h = pad, y + row_h + 14, 0
        placed.append((label, c, x, y))
        x += w
        row_h = max(row_h, c.h * scale)
    total = Canvas(width + pad, y + row_h + 16, bg)
    total.text(pad, 4, title, "h")
    for label, c, x, y in placed:
        total.rect(x - 1, y - 1, c.w * scale + 2, c.h * scale + 2, "2")
        total.blit(c.scaled(scale), x, y)
        total.text(x, y + c.h * scale + 3, label, "T")
    os.makedirs(SHEETS, exist_ok=True)
    total.save(os.path.join(SHEETS, name + ".png"))
    return total
