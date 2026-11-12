"""Effects: brief and pale, never brighter than the character
(combat-art-prompts.md A-02 to A-11), plus the farm's spells and the
creatures' own marks. Horizontal strips, one effect per file.
"""
import math
from px import Canvas, rng, strip
from lib import out

SHEET_SCALE = 2


def burst(name, n, size, colours, count, speed=1.0, gravity=0.0, chunk=1, ring=None, fade=True):
    """Particles thrown out from the centre; optional expanding ring."""
    r = rng(name)
    parts = [(r.uniform(0, math.tau), r.uniform(0.45, 1.0), r.choice(colours), r.randrange(chunk) + 1) for _ in range(count)]
    frames = []
    for f in range(n):
        t = (f + 1) / n
        c = Canvas(size, size)
        if ring:
            c.ring(size / 2, size / 2, t * size * 0.46, ring[min(len(ring) - 1, f * len(ring) // n)], t * size * 0.46 - (2.2 if f < n - 1 else 1.2), squash=0.6)
        for a, k, col, big in parts:
            if fade and t > k + 0.25:
                continue
            d = t * k * size * 0.45 * speed
            x, y = size / 2 + math.cos(a) * d, size / 2 + math.sin(a) * d * 0.7 + gravity * t * t * size * 0.3
            s = max(big, 2 if size >= 64 else 1) if t < 0.7 else 1
            c.rect(x, y, s, s, col)
        frames.append(c)
    return frames


def slash(n, size, colours, sweep=2.6, start=-2.2, width=3):
    """A crescent arc that appears and thins out."""
    frames = []
    for f in range(n):
        c = Canvas(size, size)
        t = f / (n - 1)
        a0 = start + sweep * 0.35 * t
        a1 = start + sweep * min(1.0, 0.45 + t)
        steps = 60
        for i in range(steps):
            a = a0 + (a1 - a0) * i / steps
            thick = width * math.sin(math.pi * i / steps) * (1.0 - t * 0.6)
            for k in range(int(round(thick)) + 1):
                rad = size * 0.42 - k
                c.px(size / 2 + math.cos(a) * rad, size / 2 + math.sin(a) * rad * 0.75, colours[0] if k == 0 else colours[-1])
        frames.append(c)
    return frames


def ring_frames(n, size, colours, squash=0.6, cracks=False, seed="ring"):
    frames = []
    r = rng(seed)
    crack = [r.uniform(0, math.tau) for _ in range(7)]
    for f in range(n):
        c = Canvas(size, size)
        rad = (f + 1) / n * size * 0.47
        c.ring(size / 2, size / 2, rad, colours[min(f * len(colours) // n, len(colours) - 1)], rad - max(1.2, 3.2 - f * 0.5), squash=squash)
        if cracks:
            for a in crack:
                for k in range(int(rad * 0.5), int(rad), 2):
                    c.px(size / 2 + math.cos(a) * k, size / 2 + math.sin(a) * k * squash, "s" if f < n - 2 else "2")
        frames.append(c)
    return frames


def arrow_frames(tip, trail, red=False, n=3):
    frames = []
    for f in range(n):
        c = Canvas(32, 32)
        for k in range(trail):
            if (k + f) % 3 != 2:
                c.px(13 - k, 16, "p" if k < trail // 2 else "T")
        c.rect(14, 16, 9, 1, "y")
        c.rect(14, 15, 2, 1, "R" if red else "T")
        c.rect(14, 17, 2, 1, "R" if red else "T")
        c.px(23, 16, tip)
        c.px(24, 16, tip if tip != "T" else "P")
        frames.append(c.outline() if f == 0 else c.outline())
    return frames


def rain_of_arrows(n=6):
    frames = []
    r = rng("volley")
    arrows = [(r.randrange(6, 58), r.randrange(-30, 10), r.randrange(4)) for _ in range(14)]
    for f in range(n):
        c = Canvas(64, 64)
        for x, y0, _k in arrows:
            y = y0 + f * 11
            if y > 56:
                c.rect(x, 54 + (x % 5), 1, 4, "y")  # stuck in the ground
                c.px(x, 53 + (x % 5), "R")
                continue
            c.line(x, y, x - 2, y - 7, "p")
            c.px(x, y + 1, "T")
        frames.append(c)
    return frames


def projectile(kind, n=4):
    frames = []
    for f in range(n):
        c = Canvas(32, 32)
        if kind == "ember":
            c.ellipse(17, 16, 2.5, 2.5, "o"); c.ellipse(17, 16, 1.5, 1.5, "a"); c.px(17 + (f % 2), 15, "h")
            for k in range(4):
                c.px(13 - k * 2, 16 + ((k + f) % 3) - 1, "o" if k < 2 else "b")
        elif kind == "frost":
            a = f * math.pi / 4
            for k in range(4):
                c.line(16, 16, 16 + math.cos(a + k * math.pi / 2) * 5, 16 + math.sin(a + k * math.pi / 2) * 5, "W")
            c.rect(15, 15, 3, 3, "T"); c.px(16, 16, "P")
        else:  # the rot seed: a dark husk with a faint glow
            c.ellipse(16, 16, 3.5, 2.5, "v"); c.ellipse(16 - f % 2, 16, 2, 1.5, "V"); c.px(15, 15, "y")
            c.px(16 + (f % 2), 12, "G"); c.px(16, 13, "G")
        frames.append(c.outline())
    return frames


def seed_growth():
    frames = []
    for f in range(9):
        c = Canvas(32, 32)
        grow = min(f, 5) / 5.0 if f < 6 else 1.0
        wither = f >= 6
        stem, bud = ("G", "V") if not wither else ("y", "v")
        for k in range(int(3 + grow * 4)):  # tendrils
            a = k * 1.1 + 0.4
            c.line(16, 20, 16 + math.cos(a) * grow * (9 - (f - 5) * 2 if wither else 9), 20 - abs(math.sin(a)) * grow * 8, stem)
        c.ellipse(16, 19 - grow * 3, 1.5 + grow * 2.5 - (f - 5 if wither else 0) * 0.7, 1.5 + grow * 2, bud)
        c.px(15, 18 - grow * 3, "y")
        frames.append(c.outline() if not wither else c)
    return frames


def tether(n=4):
    frames = []
    for f in range(n):
        c = Canvas(32, 16)
        for x in range(32):
            y = 8 + round(math.sin((x + f * 4) * 0.4) * 1.5)
            c.px(x, y, "V")
            if (x + f * 4) % 11 == 0:
                c.rect(x - 1, y - 1, 2, 2, "P")  # a mote travelling home
        frames.append(c)
    return frames


def beam(n=4):
    frames = []
    for f in range(n):
        c = Canvas(32, 16)
        half = (1, 3, 2, 1)[f]
        c.rect(0, 8 - half, 32, half * 2, "V")
        if f < 3:
            c.rect(0, 8 - max(1, half - 1), 32, max(1, half * 2 - 2), "P" if f == 1 else "p")
        frames.append(c)
    return frames


def overlay(kind, n=4):
    """Looping marks to draw over a creature, each a different shape as well
    as a different colour (readable without colour)."""
    frames = []
    r = rng("overlay" + kind)
    pts = [(r.randrange(6, 26), r.randrange(8, 28)) for _ in range(6)]
    for f in range(n):
        c = Canvas(32, 32)
        if kind == "smoulder":  # sparks rising
            for i, (x, y) in enumerate(pts):
                yy = y - ((f * 3 + i * 5) % 14)
                c.px(x, yy, "a" if (f + i) % 2 else "h"); c.px(x, yy + 1, "o")
        elif kind == "chill":  # crystals at the feet
            for i, (x, _y) in enumerate(pts[:4]):
                h = 2 + (i + f) % 3
                c.line(x, 28, x + (i % 2) * 2 - 1, 28 - h, "T"); c.px(x, 28 - h, "P")
            c.rect(6, 29, 20, 1, "W")
        elif kind == "rot":  # spots and drifting spores
            for i, (x, y) in enumerate(pts):
                c.rect(x, y, 2, 2, "v")
                c.px(x + ((f + i) % 4) - 1, y - 2 - ((f + i) % 3), "V")
        else:  # frozen: a block of pale ice
            c.rect(6, 6, 20, 23, "T"); c.box(6, 6, 20, 23, "P")
            c.line(9, 9, 13 + f % 2, 15, "P"); c.line(20, 12, 23, 20, "W"); c.rect(7, 27, 18, 1, "W")
        frames.append(c)
    return frames


def glow(n, size, colours, marks):
    """A farm spell landing on a tile: a soft square of light closing in."""
    frames = []
    for f in range(n):
        c = Canvas(size, size)
        inset = (0, 1, 2, 3, 4, 5)[min(f, 5)] if marks != "rise" else 0
        c.box(inset, inset, size - inset * 2, size - inset * 2, colours[min(f, len(colours) - 1)])
        for k in range(4):
            x = 2 + k * 4 + (f % 2)
            y = size - 3 - f * 2 if marks == "rise" else 2 + ((k * 5 + f * 3) % (size - 4))
            if 0 <= y < size:
                c.px(x, y, colours[0])
        frames.append(c)
    return frames


def rain(n=4):
    frames = []
    r = rng("rain")
    drops = [(r.randrange(64), r.randrange(64)) for _ in range(26)]
    for f in range(n):
        c = Canvas(64, 64)
        for x, y in drops:
            yy = (y + f * 16) % 64
            c.line(x, yy, x - 1, yy + 3, "W")
            if yy > 56:
                c.rect(x - 2, 63, 4, 1, "T")  # a splash where it lands
        frames.append(c)
    return frames


def smoke(n=6):
    frames = []
    for f in range(n):
        c = Canvas(16, 32)
        for k in range(4):
            y = 28 - ((f * 3 + k * 7) % 28)
            x = 8 + round(math.sin((y + k * 3) * 0.3) * 2)
            rad = 1 + (28 - y) / 12.0
            c.ellipse(x, y, rad, rad, "T" if y > 14 else "S")
        frames.append(c)
    return frames


def glob(n=4, slick=False):
    frames = []
    for f in range(n):
        c = Canvas(32, 32)
        if slick:
            c.ellipse(16, 18, 11 - f, 6 - f * 0.5, "G"); c.ellipse(15, 17, 7 - f, 3, "m"); c.px(12, 16, "M")
        else:
            c.ellipse(16, 16, 3, 3 + (f % 2), "G"); c.ellipse(15, 15, 1.5, 1.5, "m"); c.px(15, 14, "M")
        frames.append(c.outline() if not slick else c)
    return frames


def fireflies(n=4):
    frames = []
    r = rng("fireflies")
    flies = [(r.randrange(4, 28), r.randrange(4, 28), r.randrange(4)) for _ in range(5)]
    for f in range(n):
        c = Canvas(32, 32)
        for x, y, k in flies:
            if (f + k) % 4 != 3:
                c.px(x + ((f + k) % 3) - 1, y + ((f * 2 + k) % 3) - 1, "h" if (f + k) % 2 else "C")
        frames.append(c)
    return frames


def dizzy(n=4):
    frames = []
    for f in range(n):
        c = Canvas(16, 8)
        for k in range(3):
            a = f * math.pi / 2 + k * math.tau / 3
            c.px(8 + math.cos(a) * 6, 4 + math.sin(a) * 2.5, "h" if math.sin(a) > -0.2 else "a")
        frames.append(c)
    return frames


def build():
    made = []

    def keep(name, frames, fps=12, loop=False):
        frame = (frames[0].w, frames[0].h)
        made.append((name, out("effects/" + name, strip(frames), frame=frame,
                               anims={"play": {"row": 0, "frames": len(frames), "fps": fps, "loop": loop}})))

    # greatsword (A-02)
    keep("slash", slash(4, 64, "PT"))
    keep("slash_heavy", slash(5, 64, "Pp", sweep=3.6, width=5))
    keep("wall_dust", burst("walldust", 4, 64, "yyTs", 16, gravity=0.3, chunk=2))
    keep("spin_dust", ring_frames(4, 64, "yT"))
    keep("guard_sparks", burst("guard", 3, 64, "TTS", 8, speed=0.5))
    keep("perfect_guard", burst("perfect", 4, 64, "PPah", 14, speed=0.9, ring="PpT"))
    # hammer (A-04)
    keep("shockwave", ring_frames(6, 64, "PTSs", cracks=True, seed="shock"))
    keep("shockwave_weak", burst("weak", 3, 64, "yT", 8, speed=0.4))
    keep("sweet_spot", burst("sweet", 3, 16, "hP", 5, speed=0.8, fade=False))
    keep("shell_break", burst("shell", 5, 64, "sSTT", 12, gravity=0.6, chunk=3))
    # bow (A-06)
    keep("arrow", arrow_frames("T", 4), loop=True)
    keep("arrow_pierce", arrow_frames("P", 10), loop=True)
    keep("arrow_ember", arrow_frames("a", 6), loop=True)
    keep("arrow_frost", arrow_frames("W", 6), loop=True)
    keep("arrow_rot", arrow_frames("V", 6), loop=True)
    keep("arrow_volley", arrow_frames("T", 5, red=True), loop=True)
    keep("pierce_burst", burst("pierce", 4, 32, "PT", 8, speed=0.8))
    keep("volley_rain", rain_of_arrows(), fps=14)
    # magic (A-08, A-09)
    keep("ember_bolt", projectile("ember"), loop=True)
    keep("frost_shard", projectile("frost"), loop=True)
    keep("rot_seed", projectile("rot"), loop=True)
    keep("seed_growth", seed_growth(), fps=6)
    keep("seed_leap", slash(4, 64, "Vv", sweep=2.2, start=-2.6, width=2))
    keep("chill_patch", [ring_frames(4, 64, "TW", squash=0.5)[i] for i in (0, 1, 2, 3)], fps=6)
    keep("siphon_tether", tether(), fps=10, loop=True)
    keep("siphon_beam", beam(), fps=16)
    keep("burst_single", burst("b1", 6, 64, "VVp", 12, speed=0.6))
    keep("burst_shatter", burst("b2", 6, 64, "aaWWT", 18, speed=0.9, chunk=2))
    keep("burst_blight", burst("b3", 6, 64, "vVVy", 16, speed=0.7, ring="Vv"))
    keep("burst_brittle", burst("b4", 6, 64, "TTPW", 14, speed=0.8, gravity=0.4, chunk=3))
    keep("burst_all", burst("b5", 6, 64, "aWVPTv", 28, speed=1.0, chunk=2, ring="PVv"))
    keep("blink_smoke", burst("blink", 4, 32, "Vvv", 12, speed=0.6, gravity=-0.3))
    # status effects on a creature (A-11)
    for kind in ("smoulder", "chill", "rot"):
        keep("status_" + kind, overlay(kind), fps=8, loop=True)
    keep("status_frozen", overlay("frozen", 2), fps=2, loop=True)
    # the farm's spells
    keep("spell_till", glow(5, 16, "hao", "fall"))
    keep("spell_water", glow(5, 16, "PWw", "fall"))
    keep("spell_plant", glow(5, 16, "Cc", "rise"))
    keep("spell_harvest", glow(5, 16, "hC", "rise"))
    keep("spell_clear", burst("clear", 6, 32, "hCMG", 14, speed=0.8, gravity=-0.2, ring="hC"))
    keep("rain", rain(), fps=12, loop=True)
    keep("chimney_smoke", smoke(), fps=5, loop=True)
    # creatures and the world
    keep("toad_glob", glob(), fps=8, loop=True)
    keep("toad_slick", glob(slick=True), fps=1)
    keep("pike_jet", burst("jet", 4, 32, "WWP", 10, speed=0.7, ring="PW"))
    keep("water_rings", ring_frames(5, 32, "PW", squash=0.5), fps=8)
    keep("fur_tufts", burst("fur", 4, 32, "sST", 8, gravity=0.3, chunk=2))
    keep("moth_dust", burst("mothdust", 4, 32, "Pp", 8, speed=0.5, gravity=0.3))
    keep("hit", burst("hit", 3, 32, "PT", 6, speed=0.7))
    keep("defeat", burst("defeat", 6, 32, "GmMy", 14, speed=0.6, gravity=-0.4))
    keep("dizzy", dizzy(), fps=8, loop=True)
    keep("fireflies", fireflies(), fps=3, loop=True)
    keep("step_dust", burst("step", 3, 16, "yT", 4, speed=0.5, gravity=-0.2))
    keep("splash", burst("splash", 4, 32, "WWP", 9, speed=0.6, gravity=0.5, ring="W"))
    return made
