"""The art in assets/ obeys the art direction and can be rebuilt from source.

Standard library only (CI runs it with the other script tests).
"""
import filecmp
import json
import os
import struct
import sys
import tempfile
import unittest
import zlib

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.path.join(ROOT, "assets")
sys.path.insert(0, os.path.join(ROOT, "tools", "art"))


def read_png(path):
    """Width, height and RGBA rows of a PNG as tools/art/px.py writes them."""
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    at, idat, size = 8, b"", None
    while at < len(data):
        n, tag = struct.unpack(">I4s", data[at:at + 8])
        body = data[at + 8:at + 8 + n]
        if tag == b"IHDR":
            w, h, depth, colour = struct.unpack(">IIBB", body[:10])
            assert (depth, colour) == (8, 6), "%s is not 8-bit RGBA" % path
            size = (w, h)
        elif tag == b"IDAT":
            idat += body
        at += n + 12
    raw = zlib.decompress(idat)
    w, h = size
    rows = []
    for y in range(h):
        line = raw[y * (w * 4 + 1):(y + 1) * (w * 4 + 1)]
        assert line[0] == 0, "%s uses a PNG filter the reader does not handle" % path
        rows.append(line[1:])
    return w, h, rows


def all_pngs():
    found = []
    for folder, _dirs, files in os.walk(ASSETS):
        found += [os.path.join(folder, f) for f in files if f.endswith(".png")]
    return sorted(found)


class TestAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.load(open(os.path.join(ASSETS, "art_manifest.json")))
        import px
        cls.palette = {bytes(rgb) + b"\xff": key for key, rgb in px.RGB.items()}

    def test_every_pixel_is_a_palette_colour_or_fully_transparent(self):
        for path in all_pngs():
            _w, _h, rows = read_png(path)
            for row in rows:
                for i in range(0, len(row), 4):
                    pixel = row[i:i + 4]
                    if pixel[3] == 0:
                        continue
                    self.assertIn(pixel, self.palette, "%s has %s, which is not in the palette" % (os.path.relpath(path, ROOT), pixel.hex()))

    def test_pure_black_and_white_appear_only_in_the_interface(self):
        extremes = {k for k, v in self.palette.items() if v in ("K", "X")}
        for path in all_pngs():
            if os.sep + "ui" + os.sep in path:
                continue
            _w, _h, rows = read_png(path)
            for row in rows:
                for i in range(0, len(row), 4):
                    self.assertNotIn(row[i:i + 4], extremes, "%s uses a pure extreme (UI only)" % os.path.relpath(path, ROOT))

    def test_the_manifest_lists_exactly_the_images_on_disk(self):
        on_disk = {os.path.relpath(p, ROOT).replace(os.sep, "/") for p in all_pngs()}
        self.assertEqual(on_disk, set(self.manifest), "assets/art_manifest.json and assets/ disagree")

    def test_sizes_frames_and_animations_fit_their_images(self):
        for rel, info in self.manifest.items():
            w, h, _rows = read_png(os.path.join(ROOT, rel))
            self.assertEqual([w, h], info["size"], rel)
            if "frame" not in info:
                continue
            fw, fh = info["frame"]
            self.assertEqual((w % fw, h % fh), (0, 0), "%s: the frame does not divide the image" % rel)
            for name, anim in info.get("anims", {}).items():
                self.assertLess(anim["row"], h // fh, "%s %s: row" % (rel, name))
                self.assertLessEqual(anim.get("start", 0) + anim["frames"], w // fw, "%s %s: frames" % (rel, name))
                self.assertGreater(anim["fps"], 0, "%s %s" % (rel, name))

    def test_the_player_has_every_facing_of_every_animation(self):
        for weapon in ("base", "greatsword", "hammer", "bow", "lantern"):
            anims = self.manifest["assets/player/player_%s.png" % weapon]["anims"]
            names = {n.rsplit("_", 1)[0] for n in anims}
            for name in names:
                for facing in "sne":
                    self.assertIn("%s_%s" % (name, facing), anims, weapon)
            self.assertTrue({"idle", "walk"} <= names, weapon)

    def test_every_creature_kind_has_a_sprite(self):
        source = open(os.path.join(ROOT, "src", "combat", "creature_kind.gd")).read()
        import re
        for kind in re.findall(r'_make\(&"(\w+)"', source):
            if kind in ("training", "shelled", "runner", "caster"):  # the arena's test dummies keep their code drawing
                continue
            self.assertIn("assets/creatures/%s.png" % kind, self.manifest, "no sprite for the creature kind '%s'" % kind)

    def test_the_art_rebuilds_byte_for_byte_from_its_source(self):
        import importlib
        import lib
        import build
        keep = (lib.ASSETS, lib.SHEETS, dict(lib.MANIFEST))
        with tempfile.TemporaryDirectory() as tmp:
            lib.ASSETS, lib.SHEETS = os.path.join(tmp, "assets"), os.path.join(tmp, "sheets")
            lib.MANIFEST.clear()
            os.makedirs(lib.ASSETS)
            try:
                for name in build.MODULES:
                    importlib.import_module(name).build()
                lib.write_manifest("art_manifest.json")
                for rel in self.manifest:
                    fresh = os.path.join(tmp, rel)
                    self.assertTrue(os.path.exists(fresh), "the generators no longer make %s" % rel)
                    self.assertTrue(filecmp.cmp(fresh, os.path.join(ROOT, rel), shallow=False), "%s differs from what tools/art/build.py makes" % rel)
                self.assertTrue(filecmp.cmp(os.path.join(lib.ASSETS, "art_manifest.json"), os.path.join(ASSETS, "art_manifest.json"), shallow=False), "the manifest is stale")
            finally:
                lib.ASSETS, lib.SHEETS = keep[0], keep[1]
                lib.MANIFEST.clear()
                lib.MANIFEST.update(keep[2])

    def test_every_asset_folder_is_in_the_register(self):
        register = open(os.path.join(ROOT, "docs", "design", "asset-register.md")).read()
        for folder in sorted({rel.split("/")[1] for rel in self.manifest}):
            self.assertIn("`assets/%s/" % folder, register, "assets/%s/ is not in docs/design/asset-register.md" % folder)


if __name__ == "__main__":
    unittest.main()
