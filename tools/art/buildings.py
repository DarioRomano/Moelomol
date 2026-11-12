"""Buildings: modular 16 px pieces per style, and composed landmarks.

A building seen in the 3/4 view (ADR-0014) is roof rows, an eave row, then a
front wall two tiles tall with windows and a door. Styles differ only in
their three roof tones, three wall tones and wall pattern, so every house in
the game is built the same way. Warm styles are the farm's (warmth means
life); the world's are cool stone and grey wood, their windows dark.
"""
from px import Canvas, rng, strip
from lib import out

T = 16
SHEET_SCALE = 2
STYLES = {
    # roof (dark, mid, light), wall (dark, mid, light), pattern, door (dark, mid)
    "farmhouse": (("b", "o", "a"), ("y", "p", "P"), "plaster", ("b", "o")),
    "workshop": (("1", "2", "s"), ("b", "o", "a"), "planks", ("b", "o")),
    "thatch": (("b", "a", "h"), ("b", "o", "a"), "planks", ("b", "o")),
    "cottage": (("0", "1", "2"), ("s", "S", "T"), "stone", ("1", "2")),
    "church": (("0", "1", "2"), ("S", "T", "p"), "stone", ("0", "1")),
    "timber": (("1", "2", "s"), ("1", "2", "s"), "planks", ("0", "1")),
    "brick": (("0", "1", "2"), ("v", "V", "y"), "stone", ("0", "1")),
}
PIECES = ["roof_ridge_l", "roof_ridge", "roof_ridge_r", "roof_l", "roof", "roof_r", "eave_l", "eave", "eave_r",
          "wall_l", "wall", "wall_r", "window", "window_lit", "base_l", "base", "base_r", "door_top", "door_bottom"]


def roof_tile(style, part, side):
    dark, mid, light = STYLES[style][0]
    c = Canvas(T, T, mid)
    r = rng("roof%s%s%s" % (style, part, side))
    for row in range(4):  # shingles: staggered, each with a shadow under it
        y = row * 4
        c.rect(0, y + 3, T, 1, dark)
        for col in range(-1, 5):
            x = col * 4 + (row % 2) * 2
            c.px(x, y + 1, dark)
            c.px(x, y + 2, dark)
            if r.random() < 0.3:
                c.rect(x + 1, y, 3, 1, light)  # a shingle catching the light
            elif r.random() < 0.05:
                c.px(x + 2, y, dark)  # a chipped corner
    if part == "ridge":
        c.rect(0, 0, T, 2, light)
        c.rect(0, 2, T, 1, dark)
    if part == "eave":
        c.rect(0, 11, T, 2, light)
        c.rect(0, 13, T, 3, "0")  # the eave's shadow on the wall
    if side == "l":
        c.rect(0, 0, 2, T, light)
        c.rect(2, 0, 1, T, dark)
    if side == "r":
        c.rect(T - 2, 0, 2, T, dark)
    return c


def wall_tile(style, part, side, feature=None):
    dark, mid, light = STYLES[style][1]
    pattern = STYLES[style][2]
    c = Canvas(T, T, mid)
    r = rng("wall%s%s%s" % (style, part, side))
    if pattern == "stone":
        for row in range(4):
            c.rect(0, row * 4 + 3, T, 1, dark)
            for col in range(-1, 3):
                x = col * 8 + (row % 2) * 4
                c.rect(x, row * 4, 1, 3, dark)
                if r.random() < 0.35:
                    c.rect(x + 1, row * 4, 7, 1, light)
    elif pattern == "planks":
        for x in range(3, T, 4):
            c.rect(x, 0, 1, T, dark)
        for _ in range(4):
            c.px(r.randrange(T), r.randrange(T), light)
    else:  # plaster: flat, flecked, held in a timber frame
        for _ in range(5):
            c.px(r.randrange(T), r.randrange(T), dark)
        for _ in range(3):
            c.px(r.randrange(T), r.randrange(T), light)
        if part == "wall":
            c.rect(0, 0, T, 2, "b")
    frame = "b" if pattern == "plaster" else dark
    if side == "l":
        c.rect(0, 0, 2, T, frame)
    if side == "r":
        c.rect(T - 2, 0, 2, T, frame)
    if part == "base":
        c.rect(0, 12, T, 3, dark)  # the footing
        c.rect(0, 15, T, 1, "0")
    if feature in ("window", "window_lit"):
        glass, glint = ("a", "h") if feature == "window_lit" else ("0", "1")
        c.rect(3, 4, 10, 10, frame if pattern == "plaster" else "0")
        c.rect(4, 5, 8, 8, glass)
        c.rect(7, 5, 2, 8, frame if pattern == "plaster" else "0")  # the glazing bars
        c.rect(4, 8, 8, 1, frame if pattern == "plaster" else "0")
        c.px(4, 5, glint)
        c.px(5, 5, glint)
        c.px(4, 6, glint)
        c.rect(2, 14, 12, 1, light)  # the sill
    return c


def door_tiles(style):
    dd, dm = STYLES[style][3]
    top = wall_tile(style, "wall", "m")
    bottom = wall_tile(style, "base", "m")
    for c, y0 in ((top, 6), (bottom, 0)):
        h = T - y0
        c.rect(1, y0, 14, h, "0")
        c.rect(2, y0 + (1 if c is top else 0), 12, h, dm)
        for x in (5, 9):
            c.rect(x, y0 + 1, 1, h, dd)
    top.rect(2, 7, 12, 1, dd)
    bottom.px(11, 4, "a" if STYLES[style][2] != "stone" else "T")  # the latch
    bottom.rect(1, 15, 14, 1, "0")
    return top, bottom


def pieces(style):
    tiles = [roof_tile(style, part, side) for part in ("ridge", "body", "eave") for side in ("l", "m", "r")]
    tiles += [wall_tile(style, "wall", side) for side in ("l", "m", "r")]
    tiles += [wall_tile(style, "wall", "m", "window"), wall_tile(style, "wall", "m", "window_lit")]
    tiles += [wall_tile(style, "base", side) for side in ("l", "m", "r")]
    tiles += list(door_tiles(style))
    return dict(zip(PIECES, tiles))


def compose(style, w, roof_rows=2, door=None, windows=(), lit=False, chimney=False):
    """A whole building `w` tiles wide: roof_rows of roof, the eave, the wall."""
    p = pieces(style)
    c = Canvas(w * T, (roof_rows + 3) * T + (8 if chimney else 0))
    oy = 8 if chimney else 0

    def side(i):
        return "_l" if i == 0 else ("_r" if i == w - 1 else "")

    for i in range(w):
        for j in range(roof_rows):
            c.blit(p[("roof_ridge" if j == 0 else "roof") + side(i)], i * T, oy + j * T)
        c.blit(p["eave" + side(i)], i * T, oy + roof_rows * T)
        upper = "window_lit" if (i in windows and lit) else ("window" if i in windows else "wall" + side(i))
        c.blit(p[upper], i * T, oy + (roof_rows + 1) * T)
        c.blit(p["base" + side(i)], i * T, oy + (roof_rows + 2) * T)
        if i == door:
            c.blit(p["door_top"], i * T, oy + (roof_rows + 1) * T)
            c.blit(p["door_bottom"], i * T, oy + (roof_rows + 2) * T)
    if chimney:
        x = (w - 2) * T + 2
        c.rect(x, 0, 8, 16, "s")
        c.rect(x + 6, 0, 2, 16, "2")
        c.rect(x - 1, 0, 10, 2, "T")
    return c.outline()


def tower(style, lit=False):
    """A bell tower, two tiles wide: the chapel's and the church's."""
    dark, mid, light = STYLES[style][1]
    c = Canvas(32, 64)
    c.poly([(16, 0), (30, 20), (1, 20)], STYLES[style][0][1])
    c.poly([(16, 0), (30, 20), (16, 20)], STYLES[style][0][0])
    c.rect(15, 0, 2, 3, "T")  # the finial
    for j in range(3):
        for i in range(2):
            t = wall_tile(style, "base" if j == 2 else "wall", "l" if i == 0 else "r")
            c.blit(t, i * T, 20 + j * T - (4 if j == 2 else 0))
    c.rect(11, 26, 10, 14, "0")  # the belfry opening
    c.rect(12, 27, 8, 13, "a" if lit else "1")
    c.ellipse(15.5, 33, 3, 3, "h" if lit else "s")  # the bell
    c.rect(15, 36, 2, 2, "0")
    return c.outline()


def mill_wheel():
    """Four frames of the mill's wheel turning (it turns again once the
    sluice is opened)."""
    frames = []
    for f in range(4):
        c = Canvas(34, 34)
        c.ring(16.5, 16.5, 15, "2", 12.5)
        c.ring(16.5, 16.5, 14, "s", 13)
        for k in range(8):
            import math
            a = (k + f * 0.25) * math.pi / 4
            x, y = 16.5 + math.cos(a) * 14, 16.5 + math.sin(a) * 14
            c.line(16.5, 16.5, x, y, "2")
            c.rect(x - 1, y - 1, 3, 3, "s")  # a paddle
        c.ellipse(16.5, 16.5, 2.5, 2.5, "S")
        frames.append(c.outline())
    return frames


def build():
    made = []

    def keep(rel, c, **meta):
        made.append((rel.split("/")[-1], out(rel, c, **meta)))

    for style in STYLES:
        p = pieces(style)
        keep("buildings/pieces_" + style, strip([p[n] for n in PIECES]), frame=(T, T), layout=" ".join(PIECES))
    keep("buildings/farmhouse", compose("farmhouse", 6, 2, door=2, windows=(1, 4), chimney=True))
    keep("buildings/farmhouse_lit", compose("farmhouse", 6, 2, door=2, windows=(1, 4), lit=True, chimney=True))
    keep("buildings/workshop", compose("workshop", 4, 1, door=1, windows=(3,)))
    keep("buildings/coop", compose("thatch", 3, 1, door=1))
    keep("buildings/cottage", compose("cottage", 4, 2, door=1, windows=(2,)))
    keep("buildings/cottage_small", compose("cottage", 3, 1, door=1, windows=(2,)))
    keep("buildings/shed", compose("timber", 3, 1, door=1))
    keep("buildings/mill", compose("timber", 6, 3, door=4, windows=(1, 2)))
    keep("buildings/chapel", compose("church", 4, 2, door=2, windows=(0, 3)))
    keep("buildings/church", compose("church", 8, 3, door=1, windows=(3, 4, 5, 6)))
    keep("buildings/church_lit", compose("church", 8, 3, door=1, windows=(3, 4, 5, 6), lit=True))
    keep("buildings/inn", compose("brick", 7, 2, door=3, windows=(0, 1, 5, 6)))
    keep("buildings/winch_house", compose("cottage", 2, 1, door=0))
    keep("buildings/tower", tower("church"))
    keep("buildings/tower_lit", tower("church", lit=True))
    keep("buildings/mill_wheel", strip(mill_wheel()), frame=(34, 34),
         anims={"turn": {"row": 0, "frames": 4, "fps": 6, "loop": True}})
    return made
