"""Growing and standing things outdoors: trees, hedges, thickets, fences,
rocks, reeds. Everything that stands on the ground has the one-pixel dark
outline; sprites are anchored at the bottom centre.
"""
from px import Canvas, rng, strip
from lib import out

T = 16
# dark, mid, light leaves per mood (the same moods as the grass).
LEAVES = {"farm": ("G", "c", "C"), "wild": ("g", "G", "m"), "changed": ("0", "v", "V"), "willow": ("G", "m", "M")}
WOOD = {"warm": ("b", "o", "a"), "grey": ("2", "s", "S")}


def canopy(c, cx, cy, rx, ry, cols, seed, lumps=7):
    dark, mid, light = cols
    r = rng(seed)
    spots = [(cx + r.uniform(-rx, rx) * 0.6, cy + r.uniform(-ry, ry) * 0.5, r.uniform(0.35, 0.55)) for _ in range(lumps)]
    spots.append((cx, cy, 0.7))
    for x, y, k in spots:
        c.ellipse(x, y, rx * k, ry * k, dark)
    for x, y, k in spots:
        c.ellipse(x - 1, y - ry * k * 0.35, rx * k * 0.75, ry * k * 0.6, mid)
    for x, y, k in spots[: lumps // 2 + 1]:
        c.ellipse(x - rx * k * 0.3, y - ry * k * 0.55, rx * k * 0.35, ry * k * 0.22, light)
    for _ in range(int(rx * ry * 0.12)):  # leaf breaks: dark notches in the lit side
        x, y = cx + r.uniform(-rx, rx), cy + r.uniform(-ry, ry)
        if c.get(int(x), int(y)) == mid:
            c.px(x, y, dark)


def tree(mood, seed, w=32, h=44, wood="grey", fruit=None, bare=False):
    c = Canvas(w, h)
    wd, wm, wl = WOOD[wood]
    cx = w // 2
    c.rect(cx - 2, h - 14, 5, 13, wm)  # the trunk, lit from the left
    c.rect(cx + 1, h - 14, 2, 13, wd)
    c.px(cx - 2, h - 9, wl)
    c.px(cx - 2, h - 5, wl)
    c.rect(cx - 4, h - 2, 9, 1, wd)  # roots spreading
    if bare:
        c.rect(cx - 1, h - 24, 3, 10, wm)
        for dx, dy in ((-10, -9), (9, -11), (-6, -16), (5, -17)):
            y0 = h - 16 if abs(dx) > 7 else h - 23
            c.line(cx, y0, cx + dx, y0 + dy, wm, 2)
            c.line(cx + dx, y0 + dy, cx + dx + (3 if dx > 0 else -3), y0 + dy - 5, wd)
            c.line(cx + dx // 2, y0 + dy // 2, cx + dx // 2 + (-4 if dx > 0 else 4), y0 + dy // 2 - 6, wd)
    else:
        canopy(c, cx, h * 0.38, w * 0.46, h * 0.36, LEAVES[mood], "tree%s%s" % (mood, seed))
        if fruit:
            r = rng("fruit%s" % seed)
            for _ in range(6):
                x, y = cx + r.randrange(-11, 11), int(h * 0.38) + r.randrange(-9, 10)
                if c.get(x, y):
                    c.px(x, y, fruit)
                    c.px(x, y - 1, "h" if fruit == "a" else fruit)
    return c.outline()


def willow(seed):
    c = Canvas(48, 44)
    c.rect(22, 26, 5, 16, "s")
    c.rect(25, 26, 2, 16, "2")
    canopy(c, 24, 14, 22, 12, LEAVES["willow"], "willow%s" % seed, lumps=9)
    r = rng("willowfall%s" % seed)
    for x in range(3, 46, 2):  # trailing withies
        n = r.randrange(8, 18)
        for y in range(18, 18 + n):
            if c.get(x, y) is None or y > 22:
                c.px(x, y, "m" if (y + x) % 3 else "G")
        c.px(x, 18 + n, "M")
    return c.outline()


def block_set(kind):
    """Three tiles for anything grown or built in runs: the lit top edge, the
    fill, and the front face. The renderer picks by what is above and below."""
    cols = {"hedge": ("g", "G", "m"), "thicket": ("0", "g", "G"), "woods": ("g", "G", "m"),
            "woods_changed": ("0", "v", "V"), "wall": ("2", "s", "S")}[kind]
    dark, mid, light = cols
    tiles = []
    for part in ("top", "fill", "front"):
        c = Canvas(T, T, mid)
        r = rng(kind + part)
        if kind == "wall":
            for row in range(4):
                for col in range(-1, 3):
                    x = col * 7 + (row % 2) * 3
                    c.rect(x, row * 4, 6, 3, mid if r.random() < 0.7 else light)
                    c.rect(x, row * 4 + 3, 7, 1, dark)
                    c.rect(x + 6, row * 4, 1, 3, dark)
            if part == "top":
                c.rect(0, 0, T, 2, light)
                c.rect(0, 2, T, 1, dark)
            if part == "front":
                c.rect(0, 13, T, 3, dark)
        else:
            for _ in range(10):  # leaf clumps
                x, y = r.randrange(T), r.randrange(T)
                c.px(x, y, dark)
                c.px((x + 1) % T, y, dark)
                c.px(x, (y + 1) % T, dark)
            for _ in range(7 if part != "front" else 2):
                x, y = r.randrange(T), r.randrange(T)
                c.px(x, y, light)
                c.px((x + 1) % T, y, light)
            if part == "top":
                for x in range(T):
                    c.px(x, 0, "0")
                    c.px(x, 1, light if x % 4 != 3 else mid)
            if part == "front":
                c.rect(0, 9, T, 5, dark)
                for x in range(0, T, 3):
                    c.px(x, 8, dark)
                c.rect(0, 14, T, 2, "0")
            if kind == "thicket":
                for _ in range(4):  # thorns catch the light
                    c.px(r.randrange(T), r.randrange(T), "s")
        tiles.append(c)
    return tiles


def fence_set(wood):
    wd, wm, wl = WOOD[wood]

    def post(c, x, y=3, h=12):
        c.rect(x, y, 3, h, wm)
        c.rect(x + 2, y, 1, h, wd)
        c.px(x, y, wl)
        c.px(x + 1, y, wl)

    def rails(c, x0, x1, ys=(6, 10)):
        for y in ys:
            c.rect(x0, y, x1 - x0, 2, wm)
            c.rect(x0, y + 1, x1 - x0, 1, wd)

    tiles = []
    c = Canvas(T, T)  # across: rails with a post, tiles left to right
    rails(c, 0, T)
    post(c, 6)
    tiles.append(c.outline())
    c = Canvas(T, T)  # down: a post with the rail running away below it
    c.rect(7, 0, 2, T, wm)
    c.rect(8, 0, 1, T, wd)
    post(c, 6, 4, 9)
    tiles.append(c.outline())
    c = Canvas(T, T)  # a post alone (corners, ends)
    post(c, 6)
    tiles.append(c.outline())
    c = Canvas(T, T)  # broken: one rail down, the post leaning
    c.line(1, 11, 9, 14, wm)
    c.line(1, 12, 9, 15, wd)
    c.line(11, 14, 13, 4, wm, 2)
    c.rect(0, 6, 4, 2, wm)
    tiles.append(c.outline())
    c = Canvas(32, T)  # the gate, closed
    post(c, 1)
    post(c, 28)
    rails(c, 4, 28, (5, 8, 11))
    c.line(5, 12, 26, 5, wd)
    tiles.append(c.outline())
    c = Canvas(32, T)  # the gate, open: swung back along the fence
    post(c, 1)
    post(c, 28)
    c.rect(4, 4, 2, 10, wm)
    c.rect(5, 4, 1, 10, wd)
    tiles.append(c.outline())
    return tiles


def rock(seed, w=14, h=10, mossy=False):
    c = Canvas(w + 2, h + 2)
    c.blob(w / 2 + 0.5, h / 2 + 1.5, w / 2, h / 2, "s", "S", "T")
    r = rng("rock%s" % seed)
    c.line(r.randrange(4, w - 4), 3, r.randrange(4, w - 4), h - 2, "s")
    if mossy:
        for _ in range(10):
            x, y = r.randrange(2, w), r.randrange(1, 6)
            if c.get(x, y) in ("S", "T"):
                c.px(x, y, "G")
    return c.outline()


def reeds(seed):
    c = Canvas(T, T)
    r = rng("reeds%s" % seed)
    for x in range(1, T - 1, 2):
        top = r.randrange(2, 9)
        c.line(x, 15, x + r.choice((-1, 0, 0, 1)), top, "m" if x % 4 else "G")
        if r.random() < 0.4:
            c.rect(x, top, 1, 3, "b")  # a seed head
    return c.outline()


def bush(mood, seed, berries=None):
    c = Canvas(T, 14)
    canopy(c, 8, 8, 7, 5.5, LEAVES[mood], "bush%s%s" % (mood, seed), lumps=4)
    if berries:
        r = rng("berry%s" % seed)
        for _ in range(4):
            x, y = r.randrange(3, 13), r.randrange(4, 11)
            c.px(x, y, berries)
    return c.outline()


def stump():
    c = Canvas(12, 10)
    c.rect(1, 3, 10, 6, "s")
    c.rect(8, 3, 3, 6, "2")
    c.ellipse(5.5, 3, 5, 2, "T")
    c.ellipse(5.5, 3, 2.5, 1, "S")
    return c.outline()


def build():
    made = []

    def keep(rel, c, **meta):
        made.append((rel.split("/")[-1], out(rel, c, **meta)))

    for mood in ("farm", "wild", "changed"):
        for i in range(3 if mood != "farm" else 2):
            keep("nature/tree_%s_%d" % (mood, i), tree(mood, i, wood="warm" if mood == "farm" else "grey"))
    keep("nature/apple_tree", tree("farm", "apple", wood="warm", fruit="a"))
    keep("nature/apple_tree_picked", tree("farm", "apple", wood="warm"))
    keep("nature/apple_tree_wild", tree("wild", "orchard", fruit="y"))
    keep("nature/tree_bare", tree("wild", "bare", bare=True))
    keep("nature/willow", willow(0))
    for kind in ("hedge", "thicket", "woods", "woods_changed", "wall"):
        keep("tiles/block_" + kind, strip(block_set(kind)), frame=(T, T), layout="top fill front")
    for wood in WOOD:
        f = fence_set(wood)
        keep("nature/fence_%s" % wood, strip(f[:4]), frame=(T, T), layout="across down post broken")
        keep("nature/gate_%s" % wood, strip(f[4:]), frame=(32, T), layout="closed open")
    keep("nature/rocks", strip([rock(0), rock(1, mossy=True), rock(2, 14, 10, True)]), frame=(16, 12), variants=3)
    keep("nature/boulder", rock("big", 26, 18, mossy=True))
    keep("nature/reeds", strip([reeds(0), reeds(1)]), frame=(T, T), variants=2)
    keep("nature/bush_farm", bush("farm", 0))
    keep("nature/bush_wild", bush("wild", 0))
    keep("nature/bush_berries", bush("wild", 1, berries="V"))
    keep("nature/bush_changed", bush("changed", 0, berries="y"))
    keep("nature/stump", stump())
    return made
