"""Palette-locked pixel drawing for Moelomol's art (docs/design/art-direction.md).

Standard library only. Every image is a grid of palette keys (one character
each) or None for transparent, so a sprite can never hold a colour outside
the project palette. All art is regenerated from source by tools/art/build.py.
"""
import random
import struct
import zlib

# One character per palette colour (art-direction.md, "Proposed palette").
PALETTE = {
    "0": "#1b1e2b", "1": "#2a2f40", "2": "#3d4459",  # shadow and night
    "s": "#5a6377", "S": "#7d869a", "T": "#a9b0bf",  # stone and ruins
    "p": "#d9d6cc", "P": "#f0ece1",  # paper and pale light
    "g": "#2f3b2e", "G": "#47573f", "m": "#6b7a57", "M": "#94a07a",  # wild growth
    "v": "#4a3f52", "V": "#6e5b73", "y": "#8f8a6a",  # changed land
    "w": "#2e5566", "W": "#4f8296",  # water
    "b": "#7a4a2b", "o": "#b8733a", "a": "#e0a95b", "h": "#f3d58a",  # base warmth
    "c": "#5f8f3e", "C": "#8cbf4a",  # living crops
    "r": "#8c3b3b", "R": "#c2584a",  # danger
    "K": "#0e0f16", "X": "#ffffff",  # extremes (UI only)
}
RGB = {k: tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) for k, v in PALETTE.items()}
OUTLINE = "0"


class Canvas:
    def __init__(self, w, h, fill=None):
        self.w, self.h = w, h
        self.g = [[fill] * w for _ in range(h)]

    # --- pixels -------------------------------------------------------------
    def px(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h and c != ".":
            self.g[y][x] = c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.g[y][x]
        return None

    def rect(self, x, y, w, h, c):
        for j in range(int(y), int(y + h)):
            for i in range(int(x), int(x + w)):
                self.px(i, j, c)

    def box(self, x, y, w, h, c):
        self.rect(x, y, w, 1, c)
        self.rect(x, y + h - 1, w, 1, c)
        self.rect(x, y, 1, h, c)
        self.rect(x + w - 1, y, 1, h, c)

    def line(self, x0, y0, x1, y1, c, width=1):
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            if width == 1:
                self.px(x0, y0, c)
            else:
                self.rect(x0 - (width - 1) // 2, y0 - (width - 1) // 2, width, width, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx, cy, rx, ry, c):
        """Filled ellipse about a centre given in pixel-centre coordinates."""
        for j in range(int(cy - ry - 1), int(cy + ry + 2)):
            for i in range(int(cx - rx - 1), int(cx + rx + 2)):
                if ((i - cx) / max(rx, 0.01)) ** 2 + ((j - cy) / max(ry, 0.01)) ** 2 <= 1.0:
                    self.px(i, j, c)

    def ring(self, cx, cy, r, c, r_inner=None, squash=1.0):
        r_inner = r - 1.2 if r_inner is None else r_inner
        for j in range(int(cy - r - 1), int(cy + r + 2)):
            for i in range(int(cx - r - 1), int(cx + r + 2)):
                d = ((i - cx) ** 2 + ((j - cy) / squash) ** 2) ** 0.5
                if r_inner < d <= r:
                    self.px(i, j, c)

    def blob(self, cx, cy, rx, ry, dark, mid, light=None):
        """A shaded rounded mass: lit from the upper left, shadowed below."""
        self.ellipse(cx, cy, rx, ry, dark)
        self.ellipse(cx - rx * 0.08, cy - ry * 0.22, rx * 0.9, ry * 0.78, mid)
        if light:
            self.ellipse(cx - rx * 0.3, cy - ry * 0.45, rx * 0.45, ry * 0.3, light)

    def poly(self, pts, c):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            for i in range(len(pts)):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % len(pts)]
                if y0 == y1:
                    continue
                if min(y0, y1) <= y < max(y0, y1):
                    xs.append(x0 + (y - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for a, b in zip(xs[0::2], xs[1::2]):
                self.rect(round(a), y, max(1, round(b) - round(a) + 1), 1, c)

    # --- sprites ------------------------------------------------------------
    def art(self, x, y, rows, flip=False, remap=None):
        """Stamp ASCII art: one palette key per character, '.' transparent."""
        for j, row in enumerate(rows):
            row = row[::-1] if flip else row
            for i, ch in enumerate(row):
                if ch not in ". ":
                    self.px(x + i, y + j, (remap or {}).get(ch, ch))

    def blit(self, other, x, y, flip=False):
        for j in range(other.h):
            for i in range(other.w):
                c = other.g[j][other.w - 1 - i if flip else i]
                if c is not None:
                    self.px(x + i, y + j, c)

    def crop(self, x, y, w, h):
        out = Canvas(w, h)
        for j in range(h):
            for i in range(w):
                out.g[j][i] = self.get(x + i, y + j)
        return out

    def flipped(self):
        out = Canvas(self.w, self.h)
        out.g = [row[::-1] for row in self.g]
        return out

    def outline(self, c=OUTLINE, corners=False):
        """One dark pixel round everything opaque: the house style for anything
        that stands on the ground (characters, creatures, props)."""
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] is None:
                    near = [(1, 0), (-1, 0), (0, 1), (0, -1)]
                    if corners:
                        near += [(1, 1), (-1, 1), (1, -1), (-1, -1)]
                    if any(self.get(x + i, y + j) is not None for i, j in near):
                        add.append((x, y))
        for x, y in add:
            self.g[y][x] = c
        return self

    def swap(self, mapping):
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] in mapping:
                    self.g[y][x] = mapping[self.g[y][x]]
        return self

    def shift(self, dx, dy, x0=0, y0=0, w=None, h=None):
        """Moves a region by whole pixels (bobbing heads, lunges)."""
        w, h = w or self.w, h or self.h
        part = self.crop(x0, y0, w, h)
        self.rect_clear(x0, y0, w, h)
        self.blit(part, x0 + dx, y0 + dy)
        return self

    def rect_clear(self, x, y, w, h):
        for j in range(y, y + h):
            for i in range(x, x + w):
                if 0 <= i < self.w and 0 <= j < self.h:
                    self.g[j][i] = None

    def bounds(self):
        xs = [x for y in range(self.h) for x in range(self.w) if self.g[y][x] is not None]
        ys = [y for y in range(self.h) for x in range(self.w) if self.g[y][x] is not None]
        return (min(xs), min(ys), max(xs), max(ys)) if xs else None

    def scaled(self, n):
        out = Canvas(self.w * n, self.h * n)
        for y in range(out.h):
            src = self.g[y // n]
            out.g[y] = [src[x // n] for x in range(out.w)]
        return out

    # --- text ---------------------------------------------------------------
    def text(self, x, y, s, c="P", font=None):
        from font import GLYPHS, advance
        font = font or GLYPHS
        for ch in s:
            rows = font.get(ch, font["?"])
            for j, row in enumerate(rows):
                for i, bit in enumerate(row):
                    if bit == "#":
                        self.px(x + i, y + j, c)
            x += advance(ch, font)
        return x

    # --- output -------------------------------------------------------------
    def save(self, path):
        raw = bytearray()
        for row in self.g:
            raw.append(0)
            for c in row:
                raw += bytes(RGB[c]) + b"\xff" if c is not None else b"\x00\x00\x00\x00"

        def chunk(tag, data):
            body = tag + data
            return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

        png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
        with open(path, "wb") as f:
            f.write(png)


def from_art(rows, remap=None):
    c = Canvas(max(len(r) for r in rows), len(rows))
    c.art(0, 0, rows, remap=remap)
    return c


def strip(frames):
    """Frames side by side, all the same size."""
    w, h = frames[0].w, frames[0].h
    out = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        out.blit(f, i * w, 0)
    return out


def rng(name):
    """A generator seeded by a name: textures are the same on every build."""
    return random.Random(zlib.crc32(name.encode()))


def speckle(c, x, y, w, h, colours, density, seed):
    r = rng(seed)
    for _ in range(int(w * h * density)):
        c.px(x + r.randrange(w), y + r.randrange(h), r.choice(colours))
