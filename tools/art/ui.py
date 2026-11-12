"""Interface pieces: calm and sparse, like marks on old paper
(art-direction.md, "User interface"; combat-art-prompts.md A-12).
The only place the palette's pure black and white are allowed."""
import math
from px import Canvas, strip
from lib import out
import lib
import font
import creatures

SHEET_SCALE = 3


def bar_frame():
    c = Canvas(66, 6, "0")
    c.rect(1, 1, 64, 4, "1")
    return c


def bar_fill(light, dark):
    c = Canvas(64, 4, light)
    c.rect(0, 3, 64, 1, dark)
    c.rect(0, 0, 64, 1, "P" if light != "h" else "P")
    c.rect(0, 0, 64, 1, light)
    c.px(0, 0, dark); c.px(63, 0, dark)
    return c


def charge_meter(level):
    """The hammer's charge: an arc that fills, with the sweet spot's notch."""
    c = Canvas(16, 16)
    for k in range(40):
        a = math.pi * 0.75 + k / 39.0 * math.pi * 1.5
        x, y = 7.5 + math.cos(a) * 6.5, 7.5 + math.sin(a) * 6.5
        sweet = 30 <= k <= 34
        c.px(x, y, "h" if sweet else ("T" if k / 39.0 <= level / 4.0 and level else "2"))
        if sweet:
            c.px(7.5 + math.cos(a) * 5.5, 7.5 + math.sin(a) * 5.5, "a")
    return c


def nine(size, fill, edge, outer=None, torn=False):
    c = Canvas(size, size, fill)
    c.box(0, 0, size, size, outer or edge)
    if outer:
        c.box(1, 1, size - 2, size - 2, edge)
    for x, y in ((0, 0), (size - 1, 0), (0, size - 1), (size - 1, size - 1)):
        c.g[y][x] = None  # a nicked corner
    if torn:  # a note: the lower edge torn, a fold line, a shadow under it
        for x in range(2, size - 2, 5):
            c.g[size - 1][x] = None
            c.px(x + 1, size - 2, edge)
        c.rect(3, size // 3, size - 6, 1, edge)
    return c


def keycap(text, pad=False):
    """A key (square) or a controller button (round) with its letter."""
    w = max(11, font.width(text) + 6)
    c = Canvas(w, 12)
    if pad:
        c.ellipse((w - 1) / 2, 5.5, w / 2, 5.5, "2")
        c.ellipse((w - 1) / 2, 5, w / 2 - 1, 4.5, "s")
    else:
        c.rect(0, 0, w, 12, "0"); c.rect(1, 1, w - 2, 9, "T"); c.rect(1, 10, w - 2, 1, "s"); c.rect(1, 1, w - 2, 1, "P")
    c.text((w - font.width(text) + 1) // 2, 2, text, "P" if pad else "0")
    return c


def big_text(text, scale, top, bottom, shadow):
    w = font.width(text) * scale + scale
    c = Canvas(w, 10 * scale + scale)
    plain = Canvas(font.width(text) + 1, 10)
    plain.text(0, 0, text, "X")
    for y in range(plain.h):
        for x in range(plain.w):
            if plain.g[y][x]:
                c.rect(x * scale + scale // 2, y * scale + scale // 2, scale, scale, shadow)
    for y in range(plain.h):
        for x in range(plain.w):
            if plain.g[y][x]:
                c.rect(x * scale, y * scale, scale, scale, top if y < 4 else bottom)
                if y == 0 or not plain.g[y - 1][x]:
                    c.rect(x * scale, y * scale, scale, 1, "P")  # light along each top edge
    return c


def title():
    """The title: the name in the farm's warm tones, the cat sitting on it."""
    word = big_text("Moelomol", 3, "h", "a", "b")
    c = Canvas(word.w + 4, word.h + 14)
    c.blit(word, 2, 14)
    cat = creatures.cat_frames(False)[0]
    c.blit(cat, 1, 3)  # on the M's shoulder
    return c


def app_icon():
    c = Canvas(64, 64, "1")
    c.rect(0, 46, 64, 18, "b")
    for y in (49, 55, 61):
        c.rect(0, y, 64, 1, "2")
    for x in (8, 50):  # two sprouts in the furrow
        c.rect(x, 40, 2, 7, "c"); c.rect(x - 3, 38, 3, 3, "C"); c.rect(x + 2, 37, 3, 3, "C")
    c.blit(creatures.cat_frames(False)[0].scaled(3), 10, 10)
    for x, y in ((0, 0), (63, 0), (0, 63), (63, 63)):
        c.g[y][x] = None
    return c


def build():
    made = []

    def keep(name, c, **meta):
        made.append((name, out("ui/" + name, c, **meta)))

    keep("bar_frame", bar_frame())
    for name, light, dark in (("health", "R", "r"), ("stamina", "h", "a"), ("focus", "V", "v"), ("mana", "W", "w")):
        keep("bar_" + name, bar_fill(light, dark))
    keep("charge_meter", strip([charge_meter(i) for i in range(5)]), frame=(16, 16), layout="empty quarter half three_quarter full")
    pips = Canvas(8, 4); pips.rect(0, 0, 3, 3, "2"); pips.rect(4, 0, 3, 3, "h"); pips.px(4, 0, "P")
    keep("draw_pips", pips, frame=(4, 4), layout="empty lit")
    feathers = Canvas(10, 7)
    for i, (tone, rib) in enumerate((("2", "1"), ("P", "T"))):
        feathers.line(i * 5 + 3, 0, i * 5 + 1, 6, tone, 2); feathers.line(i * 5 + 3, 1, i * 5 + 1, 6, rib)
    keep("flow_feathers", feathers, frame=(5, 7), layout="dim lit")
    lock = Canvas(12, 12)
    for x, y, dx, dy in ((0, 0, 1, 1), (11, 0, -1, 1), (0, 11, 1, -1), (11, 11, -1, -1)):
        lock.line(x, y, x + dx * 3, y, "P"); lock.line(x, y, x, y + dy * 3, "P")
    keep("lock_on", lock)
    keep("paper", nine(48, "P", "p", torn=True), nine_slice=16)
    keep("panel", nine(48, "1", "2", outer="0"), nine_slice=16)
    keep("button", strip([nine(24, "1", "2", outer="0"), nine(24, "2", "h", outer="0")]), frame=(24, 24), nine_slice=8, layout="normal focused")
    thread = Canvas(8, 8); thread.line(1, 1, 6, 6, "o"); thread.line(6, 1, 3, 4, "o"); thread.rect(3, 3, 2, 2, "a")
    keep("loose_thread", thread)
    sel = Canvas(6, 8)
    for i in range(4):
        sel.rect(i, i, 1, 8 - i * 2, "h")
    keep("selector", sel)
    for text in ("F", "I", "J", "K", "L", "Q", "E", "Esc", "Tab", "Shift", "Space"):
        keep("key_" + text.lower(), keycap(text))
    for text in ("A", "B", "X", "Y", "LT", "RT", "RB", "View", "Start"):
        keep("pad_" + text.lower(), keycap(text, pad=True))
    keep("title", title())
    keep("app_icon", app_icon())
    n = font.build(lib.ASSETS + "/ui")
    lib.MANIFEST["assets/ui/moelomol_font.png"] = {"size": [128, 60], "glyphs": n, "line_height": font.LINE_HEIGHT, "format": "BMFont text (moelomol_font.fnt)"}
    sample = Canvas(250, 44, "1")
    sample.text(3, 3, "The quick brown fox jumps over the lazy dog.", "P")
    sample.text(3, 14, "ARTHUR'S KEY, 0123456789 - Kettlebridge?", "h")
    sample.text(3, 25, "\"Gone up to the market; back by four.\" (A.)", "p")
    made.append(("font sample", sample))
    return made
