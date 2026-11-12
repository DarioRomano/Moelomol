"""Ground tiles (16 x 16, no outline): the floor of every place.

Grounds stay low in contrast (art-direction.md, "Readability before detail"):
at most three neighbouring tones per tile, detail as sparse flecks and blades.
"""
from px import Canvas, rng, strip
from lib import out

T = 16

# base, light, dark, accent for each mood of grass (distance from the farm
# shows in the colour: healthy, overgrown, changed).
GRASS = {
    "farm": ("m", "M", "G", "C"),
    "wild": ("G", "m", "g", "M"),
    "changed": ("v", "V", "0", "y"),
    "yard": ("g", "G", "0", "m"),  # the churchyard: long and dark
}


def grass_tile(mood, seed, long=False, flowers=None):
    base, light, dark, accent = GRASS[mood]
    c = Canvas(T, T, base)
    r = rng("grass%s%s" % (mood, seed))
    for _ in range(2):  # a soft darker patch
        x, y = r.randrange(T - 2), r.randrange(T)
        c.rect(x, y, 2 + r.randrange(2), 1, dark)
    for _ in range(6 if long else 3):  # a tuft: two light tips over a dark root
        x, y = r.randrange(T - 2), r.randrange(1, T - 1)
        c.px(x, y, light)
        c.px(x + 2, y, light)
        c.px(x + 1, y + 1, dark)
        if long:
            c.px(x, y - 1, light)
            c.px(x + 1, y, light)
    if r.random() < 0.4:
        c.px(r.randrange(T), r.randrange(T), accent)
    if flowers:
        for _ in range(3):
            x, y = r.randrange(1, T - 1), r.randrange(1, T - 1)
            c.px(x, y, r.choice(flowers))
            c.px(x, y + 1, dark)
    return c


def dirt_tile(seed, base="y", light="M", dark="G", stones="s"):
    c = Canvas(T, T, base)
    r = rng("dirt%s" % seed)
    for _ in range(7):
        c.px(r.randrange(T), r.randrange(T), light)
    for _ in range(5):
        x, y = r.randrange(T), r.randrange(T)
        c.px(x, y, dark)
    for _ in range(1):  # a pebble with its shadow
        x, y = r.randrange(1, T - 1), r.randrange(1, T - 1)
        c.px(x, y, stones)
        c.px(x, y + 1, dark)
    return c


def soil_tile(seed, wet=False):
    """Tilled soil: furrows running across, a ridge every four pixels."""
    base, ridge, deep = ("2", "b", "1") if wet else ("b", "o", "2")
    c = Canvas(T, T, base)
    r = rng("soil%s%s" % (seed, wet))
    for y in range(T):
        if y % 4 == 3:  # the furrow's shadow
            for x in range(T):
                if r.random() < 0.75:
                    c.px(x, y, deep)
        if y % 4 == 1:  # crumbs of lit earth on the ridge
            for x in range(T):
                if r.random() < 0.22:
                    c.px(x, y, ridge)
    if wet:
        for _ in range(3):
            c.px(r.randrange(T), r.randrange(T), "W")  # a glint of water in the furrow
    return c


def furrow_tile(seed):
    """The old fields: grass grown over furrows that still show."""
    c = grass_tile("farm", "f%s" % seed)
    r = rng("furrow%s" % seed)
    for y in (3, 9, 14):
        for x in range(T):
            if r.random() < 0.7:
                c.px(x, y, "G")
    return c


def cobble_tile(seed):
    c = Canvas(T, T, "2")
    r = rng("cobble%s" % seed)
    for row in range(4):
        off = (row % 2) * 3 - 1 + r.randrange(2)
        for col in range(-1, 4):
            x, y = col * 5 + off, row * 4
            tone = r.choice("sssS")
            c.rect(x, y, 4, 3, tone)
            c.px(x, y, "S" if tone == "s" else "T")  # a worn top-left corner
            if r.random() < 0.15:
                c.px(x + 2, y + 1, "G")  # moss in the joints
    return c


def sawdust_tile(seed):
    c = Canvas(T, T, "y")
    r = rng("sawdust%s" % seed)
    for y in (2, 7, 12):  # rake lines
        for x in range(T):
            if r.random() < 0.6:
                c.px(x, y + r.randrange(2), "p")
    for _ in range(6):
        c.px(r.randrange(T), r.randrange(T), "b" if r.random() < 0.3 else "M")
    return c


def wheat_tile(seed, cut=False):
    if cut:  # stubble on bare ground
        c = dirt_tile("st%s" % seed, base="y", light="M", dark="G", stones="G")
        r = rng("stubble%s" % seed)
        for row in range(4):
            for col in range(4):
                x, y = col * 4 + (row % 2) * 2, row * 4 + 1 + r.randrange(2)
                c.px(x, y, "p")
                c.px(x, y + 1, "G")
        return c
    c = Canvas(T, T, "y")
    r = rng("wheat%s" % seed)
    for x in range(T):  # stalks: short upright strokes, staggered
        for y in range(T):
            if x % 2 == 0 and (y + x * 5) % 6 < 3:
                c.px(x, y, "M")
            if x % 4 == 1 and (y + x * 3) % 8 == 0:
                c.px(x, y, "G")
    for _ in range(7):  # pale ears, left standing since the harvest stopped
        x, y = r.randrange(T), r.randrange(T - 1)
        c.px(x, y, "p")
        c.px(x, y + 1, "M")
    return c


def mud_tile(seed):
    c = Canvas(T, T, "2")
    r = rng("mud%s" % seed)
    for _ in range(10):
        c.px(r.randrange(T), r.randrange(T), r.choice("1v"))
    x, y = r.randrange(2, 10), r.randrange(2, 12)
    c.rect(x, y, 4, 2, "w")  # a puddle left behind
    c.px(x + 1, y, "W")
    for _ in range(2):
        c.px(r.randrange(T), r.randrange(T), "G")
    return c


def water_frames(flood=False):
    """Four frames: short pale ripples drifting; the water itself is flat."""
    frames = []
    r = rng("waterflood" if flood else "water")
    ripples = [(r.randrange(T), r.randrange(T), r.randrange(2, 5)) for _ in range(5)]
    for f in range(4):
        c = Canvas(T, T, "w")
        for i, (x, y, n) in enumerate(ripples):
            shift = (f + i) % 4
            if shift == 3:
                continue  # each ripple rests one frame in four
            for k in range(n - (1 if shift == 2 else 0)):
                c.px((x + k + shift) % T, y, "W")
        if flood:  # murkier: drowned grass shows through
            for i in range(6):
                x, y = (i * 7 + 3) % T, (i * 5 + 2) % T
                c.px(x, y, "G")
                c.px(x, (y + 1) % T, "g")
        frames.append(c)
    return frames


def floor_tile(seed):
    """The farmhouse's floorboards: warm, the one indoor floor."""
    c = Canvas(T, T, "o")
    r = rng("floor%s" % seed)
    for y in (0, 5, 10, 15):
        c.rect(0, y, T, 1, "b")
    for band, y in enumerate((1, 6, 11)):
        x = r.randrange(T)
        c.rect(x, y, 1, 4, "b")  # where two boards meet
        for _ in range(3):
            c.px(r.randrange(T), y + r.randrange(4), "a")  # grain
    return c


def fringe_set(mood, bank=False):
    """Twelve overlay tiles that carry one ground over the edge of its
    neighbour: N E S W sides, the four outer corners, the four inner corners.
    Drawn over the other ground's tile, so any two grounds can meet. `bank`
    adds an earth lip with a dark waterline (for water and floodwater)."""
    base, light, dark, _accent = GRASS[mood]
    tiles = []

    def depth(r, i):
        return (3, 3, 4, 4, 3, 2, 2, 3, 4, 3, 3, 2, 3, 4, 4, 3)[(i + r * 5) % 16]

    def side(c, edge, seed):
        for i in range(T):
            d = depth(seed, i)
            for k in range(d + (2 if bank else 0)):
                x, y = {"N": (i, k), "S": (i, T - 1 - k), "W": (k, i), "E": (T - 1 - k, i)}[edge]
                if k < d:
                    c.px(x, y, light if (k == d - 1 and i % 3 == 0) else base)
                elif k == d:
                    c.px(x, y, "y")  # the earth lip
                else:
                    c.px(x, y, "0")  # the waterline's shadow

    def corner(c, where, inner):
        for y in range(T):
            for x in range(T):
                dx = x if "W" in where else T - 1 - x
                dy = y if "N" in where else T - 1 - y
                if inner:
                    continue
                d = (dx * dx + dy * dy) ** 0.5
                if d < 3.6:
                    c.px(x, y, base)
                elif bank and d < 4.8:
                    c.px(x, y, "y")
                elif bank and d < 5.8:
                    c.px(x, y, "0")

    for n, edge in enumerate("NESW"):
        c = Canvas(T, T)
        side(c, edge, n)
        tiles.append(c)
    for where in ("NE", "SE", "SW", "NW"):
        c = Canvas(T, T)
        corner(c, where, False)
        tiles.append(c)
    for n, where in enumerate(("NE", "SE", "SW", "NW")):
        c = Canvas(T, T)
        side(c, where[0], n)
        side(c, where[1], n + 2)
        tiles.append(c)
    return tiles


def build():
    made = []

    def keep(name, frames, **meta):
        made.append((name, out("tiles/" + name, strip(frames), frame=(T, T), **meta)))

    for mood in GRASS:
        keep("grass_" + mood, [grass_tile(mood, i) for i in range(4)], variants=4)
        keep("grass_" + mood + "_long", [grass_tile(mood, "l%d" % i, long=True) for i in range(4)], variants=4)
        keep("fringe_" + mood, fringe_set(mood), layout="N E S W NE SE SW NW inner-NE inner-SE inner-SW inner-NW")
        keep("bank_" + mood, fringe_set(mood, bank=True), layout="N E S W NE SE SW NW inner-NE inner-SE inner-SW inner-NW")
    keep("grass_farm_flowers", [grass_tile("farm", "w%d" % i, flowers="hPa") for i in range(4)], variants=4)
    keep("grass_changed_flowers", [grass_tile("changed", "w%d" % i, flowers="yV") for i in range(2)], variants=2)
    keep("path", [dirt_tile(i) for i in range(4)], variants=4)
    keep("cleared", [dirt_tile("c%d" % i, base="y", light="M", dark="b", stones="b") for i in range(2)], variants=2)
    keep("soil_dry", [soil_tile(i) for i in range(2)], variants=2)
    keep("soil_wet", [soil_tile(i, wet=True) for i in range(2)], variants=2)
    keep("old_furrows", [furrow_tile(i) for i in range(2)], variants=2)
    keep("cobbles", [cobble_tile(i) for i in range(4)], variants=4)
    keep("sawdust", [sawdust_tile(i) for i in range(2)], variants=2)
    keep("wheat", [wheat_tile(i) for i in range(2)], variants=2)
    keep("stubble", [wheat_tile(i, cut=True) for i in range(2)], variants=2)
    keep("mud", [mud_tile(i) for i in range(2)], variants=2)
    keep("water", water_frames(), anims={"flow": {"row": 0, "frames": 4, "fps": 3, "loop": True}})
    keep("floodwater", water_frames(flood=True), anims={"flow": {"row": 0, "frames": 4, "fps": 2, "loop": True}})
    keep("floorboards", [floor_tile(i) for i in range(2)], variants=2)
    return made
