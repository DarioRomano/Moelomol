"""The cat, and every creature (enemies.md, area-millbrook.md,
area-kettlebridge.md). All face east; the game mirrors them.

Creatures are wildlife changed by the god's presence: cool greys and greens,
more violet the further from the farm. Their eyes ('e' in the art) turn
danger red while they wind up and strike, so the telegraph is in the sprite.
The cat alone is drawn in the farm's warm tones.
"""
import math
from px import Canvas, from_art, strip
from lib import out
import props

SHEET_SCALE = 3
PAD = 3


def frames_from(base, eye, alt=None, extra=None, lunge=2):
    """idle (2), move (2), windup, attack, hurt from one or two drawings."""
    w = max(len(r) for r in base) + PAD * 2
    h = len(base) + PAD

    def draw(rows, dx=0, dy=0, e=eye, squash=False):
        c = Canvas(w, h)
        c.art(PAD + dx, PAD + dy - 1, rows, remap={"e": e})
        if squash:  # gather: everything above the feet sinks a pixel
            c.shift(0, 1, 0, 0, w, h - 3)
        return c.outline()

    alt = alt or base
    frames = [draw(base), draw(base, dy=1) if alt is base else draw(base, squash=True), draw(base), draw(alt, dy=0 if alt is not base else -1),
              draw(base, dx=-1, e="R", squash=True), draw(alt, dx=lunge, e="R"), draw(base, dx=-2, e="P")]
    names = ["idle_a", "idle_b", "move_a", "move_b", "windup", "attack", "hurt"]
    for name, rows in (extra or []):
        frames.append(draw(rows))
        names.append(name)
    anims = {"idle": {"row": 0, "start": 0, "frames": 2, "fps": 2, "loop": True},
             "move": {"row": 0, "start": 2, "frames": 2, "fps": 8, "loop": True},
             "windup": {"row": 0, "start": 4, "frames": 1, "fps": 1, "loop": False},
             "attack": {"row": 0, "start": 5, "frames": 1, "fps": 1, "loop": False},
             "hurt": {"row": 0, "start": 6, "frames": 1, "fps": 1, "loop": False}}
    for i, name in enumerate(names[7:]):
        anims[name] = {"row": 0, "start": 7 + i, "frames": 1, "fps": 1, "loop": False}
    return frames, anims, (w, h)


MOUSE = ["........VV..", ".......VyV..", "...yyyyyyyy.", "..yyyyyyyyey", ".yyyyyyyyyyP", "syyyppppyy..", "s.y..y.y.y.."]
MOUSE_B = MOUSE[:6] + ["s..yy...yy.."]

BIRD = ["......nnn.....", ".....n1e1ss...", "..1111111.....", ".111211111....", "01112111111...", ".0011111......", "...1..1.......", "...s..s......."]
BIRD_UP = ["..11....11....", "...11..11.....", "....1111nnn...", "...11111ne1ss.", "..1111111.....", ".0.1111.......", "..............", ".............."]
BIRD_DOWN = ["......nnn.....", "....111ne1ss..", "..1111111.....", ".1111111......", "11.1111.11....", "1...11...1....", "..............", ".............."]

HOG = ["....T.T.T.....", "..T2T2T2T2T...", ".s2222222222..", "s22s2s2s2s2yy.", "2222222222yyey", "s2s2s2s2s2yyyP", ".222222222yy..", "..y..y..y.y..."]
HOG_B = HOG[:7] + ["...y..y.y..y.."]
HOG_CURLED = ["...T.T.T.T....", ".T2s2s2s2s2T..", "s222222222222.", "2s2s2s2s2s2s2T", "2222222222222.", "s2s2s2s2s2s2s.", ".2222222222...", "..T.T.T.T....."]

TOAD = [".........ye...", "....mmmmmymm..", "..mmmGmmmmmmm.", ".mmGmmmmGmmmmm", "mmmmmmGmmmmMMM", "mGmmmmmmmMMMM.", "GGmmGGmmMMMM..", "GG.mGG...mm...", "G..GGG..mmm..."]
TOAD_HOP = [".........ye...", "....mmmmmymm..", "..mmmGmmmmmmm.", ".mmGmmmmGmmmmm", "mmmmmmGmmmmMMM", ".GmmmmmmmMMMM.", "..GmmGGmMMMM..", ".GG..GG..mm...", "GG....GGG.mm.."]
TOAD_LOB = [".........ye...", "....mmmmmymm..", "..mmmGmmmmmmpp", ".mmGmmmmGmmpPPp", "mmmmmmGmmmpPPPp", "mGmmmmmmmMMppp.", "GGmmGGmmMMMM..", "GG.mGG...mm...", "G..GGG..mmm..."]

STOOK = ["..p.y.p.y.p..", "..yypyypyyp..", "...yyyyyyy...", "...y00y00y...", "...y0ey0ey...", "..yyyyyyyyy..", ".y.bbbbbbb.y.", "y..yyyyyyy..y",
         "y..ypypypy..y", "...yyyyyyy...", "..yypyypyyy..", "..ypyypyypy..", ".yyyyyyyyyyy.", ".yp.yp.yp.yp."]
STOOK_B = STOOK[:6] + ["yy.bbbbbbb.yy", "...yyyyyyy...", "...ypypypy...", "...yyyyyyy...", "..yypyypyyy..", "..ypyypyypy..", ".yyyyyyyyyyy.", "yp.yp.yp.yp.."]

MOTH = ["PP....PP..", "PVP..PVP..", "PPPssPPP..", ".PPsePP...", ".pP.sPp...", "..p..p...."]
MOTH_B = ["...PP.....", "..PVPs....", "..PPPse...", "..pPPs....", "...p.s....", ".........."]

RAT = [".........ss...", "........sVs...", "...ssssssss...", "..sTssssssse..", ".ssssTssssssp.", "Vssssssssssss.", "V.sssvvvvss...", ".V.s..s.s..s.."]
RAT_B = RAT[:7] + [".V..ss...ss..."]
RUNT = ["......ss.", "..ssssse.", ".sssssssp", "Vssvvss..", "V.s.s.s.."]
RUNT_B = RUNT[:4] + ["V..ss.ss."]
# Market rats are more changed than Millbrook's mice: violet-grey, so they
# read against the square's grey cobbles; the bare tail is pale.
_RAT_TONES = str.maketrans({"s": "V", "V": "p", "T": "y"})
RAT, RAT_B, RUNT, RUNT_B = ([row.translate(_RAT_TONES) for row in rows] for rows in (RAT, RAT_B, RUNT, RUNT_B))

PIKE = ["..............GGG.....", ".....G..GGGGGGGGGGG...", "g..GGGmGGmGGmGGGGGeGG.", ".gGGGmGGmGGmGGGGGGGGpp", "g..GGGGGGGGGGGGGGppp..", ".....g....g..........."]
PIKE_SPIT = PIKE[:2] + ["g..GGGmGGmGGmGGGGGeGGp", ".gGGGmGGmGGmGGGGGGG.WW", "g..GGGGGGGGGGGGGGppp.W", ".....g....g..........."]
PIKE_UNDER = ["......................", ".......1111111111.....", "1..11111111111111111..", ".1111111111111111111..", "1..1111111111111111...", "......................"]

CAT = {
    "sit": [".......a.a", ".......aaa", "......aaea", "......aaah", "...aa.aaa.", "..aoaaaha.", ".aaoaahha.", ".aoaaahha.", "oaaoaahha.", "o.aaa.aa.."],
    "blink": [".......a.a", ".......aaa", "......aaoa", "......aaah", "...aa.aaa.", "..aoaaaha.", ".aaoaahha.", ".aoaaahha.", "oaaoaahha.", "o.aaa.aa.."],
    "look": ["......a..a", "......aaaa", "......eaea", "......ahha", "...aa.aaa.", "..aoaaaha.", ".aaoaahha.", ".aoaaahha.", "oaaoaahha.", "o.aaa.aa.."],
    "stroked": ["o......a.a", "o......aaa", ".o....aaoa", ".o....aaah", "..oaa.aaa.", "..aoaaaha.", ".aaoaahha.", ".aoaaahha.", ".aaoaahha.", "..aaa.aa.."],
    "walk_a": ["o.........a.a.", "o.........aaa.", ".o..aaaaaaaea.", ".oaaoaoaaaaah.", "..aaoaoaaahh..", "..aaaaaaaah...", "..a.a...a.a...", "..a.a...a.a..."],
    "walk_b": ["..........a.a.", "oo........aaa.", "..o.aaaaaaaea.", "..aaoaoaaaaah.", "..aaoaoaaahh..", "..aaaaaaaah...", "..a..a.a..a...", ".a...a.a...a.."],
    "eat": ["o.............", "o.............", ".o..aaaaaa.a.a", ".oaaoaoaaaaaaa", "..aaoaoaaaaaea", "..aaaaaaa.aah.", "..a.a...a.....", "..a.a...a..cc."],
    "curled": ["..............", "...aaaaaaa....", ".aaoaoaoaaaa..", "aaoaaaaaaoaaa.", "aoaaaaaahhaaa.", "aaaaaaaahaaoo.", ".aaaaaaaaooo..", ".............."],
}


def cat_frames(night):
    """At night the cat's eyes catch the changed land's violet: the one wrong
    detail, never explained (art-direction.md, "The pet")."""
    frames = []
    for name, rows in CAT.items():
        c = Canvas(16, 12)
        c.art(1, 12 - len(rows) - 1, rows, remap={"e": "V" if night else "C"})
        frames.append(c.outline())
    return frames


def boar(state):
    """Grist: the miller's boar, huge, mud to the shoulder, tusks grown long."""
    c = Canvas(52, 36)
    low = 3 if state in ("charge", "windup") else 0
    stretch = 3 if state == "charge" else 0
    for x, up in ((10 - stretch, 0), (16, 1 if state == "move" else 0), (30, 0), (36 + stretch, 1 if state == "windup" else 0)):
        c.rect(x, 25, 4, 9 - up, "1")
        c.rect(x, 32 - up, 4, 2, "0")
    c.blob(22, 18, 17, 10, "1", "2", "s")
    c.ellipse(15, 22, 9, 5, "b")  # mud drying on the flank
    c.ellipse(14, 21, 7, 3, "y")
    for x in range(8, 36, 3):  # the bristle ridge, tipped violet
        c.line(x, 9 + abs(x - 22) // 6, x + 1, 6 + abs(x - 22) // 6, "v")
        c.px(x + 1, 5 + abs(x - 22) // 6, "V")
    c.blob(39, 17 + low, 8, 7, "1", "2", "s")  # the head
    c.rect(44, 18 + low, 6, 5, "s")  # the snout
    c.rect(49, 19 + low, 1, 3, "V")
    c.poly([(34, 9 + low), (37, 5 + low), (39, 10 + low)], "1")  # an ear
    eye = {"windup": "R", "charge": "R", "stunned": "P"}.get(state, "y")
    c.px(41, 15 + low, eye)
    c.px(42, 15 + low, eye)
    c.line(44, 23 + low, 47, 19 + low, "P")  # tusks
    c.line(46, 24 + low, 50, 21 + low, "P")
    c.px(47, 18 + low, "p")
    c.line(5, 14, 2, 11, "1")  # the tail
    if state == "stunned":
        for k in range(3):
            c.px(36 + k * 4, 3 + (k % 2) * 2, "h")
    c = c.outline()
    if state == "wallow":  # sunk in the wallow to the belly
        c.rect_clear(0, 26, 52, 10)
        c.rect(4, 25, 44, 1, "2")
        c.rect(8, 26, 36, 1, "1")
    return c


def cattle(kind, state):
    """Duke, the fair's champion bull, and the cattle of his herd."""
    big = kind == "duke"
    w, h = (56, 40) if big else (36, 26)
    c = Canvas(w, h)
    dark, mid, light = ("0", "1", "2") if big else ("2", "s", "S")
    bx, by, rx, ry = (25, 19, 18, 11) if big else (16, 13, 12, 7)
    low = (4 if big else 2) if state in ("charge", "windup") else 0
    leg_h = 11 if big else 8
    for i, x in enumerate((bx - rx + 5, bx - rx + 11, bx + rx - 12, bx + rx - 6)):
        up = 2 if (state == "move" and i % 2) or (state == "windup" and i == 3) else 0
        c.rect(x, by + ry - 3, 4 if big else 3, leg_h - up, dark)
        c.rect(x, by + ry - 3 + leg_h - up - 2, 4 if big else 3, 2, "0" if not big else "s")
    c.blob(bx, by, rx, ry, dark, mid, light)
    if big:
        c.ellipse(bx + 9, by - 6, 8, 6, mid)  # the hump of the shoulder
        c.ellipse(bx + 8, by - 8, 5, 3, light)
        for x, y in ((bx - 8, by - 2), (bx - 2, by + 3), (bx - 12, by + 4)):  # the change showing through the hide
            c.ellipse(x, y, 3, 2, "v")
            c.px(x, y, "V")
    else:
        c.ellipse(bx - 4, by - 1, 5, 3, "p")  # pied patches
        c.ellipse(bx + 5, by + 2, 3, 2, "p")
    hx, hy = bx + rx + (2 if big else 1), by - (2 if big else 1) + low
    c.blob(hx, hy, 7 if big else 5, 6 if big else 4, dark, mid, light)
    c.rect(hx + (3 if big else 2), hy + 1, 5 if big else 3, 4 if big else 3, "p" if big else "T")  # the muzzle
    eye = {"windup": "R", "charge": "R", "stunned": "P"}.get(state, "y")
    c.px(hx + 1, hy - 2, eye)
    if big:
        c.px(hx + 2, hy - 2, eye)
        c.line(hx - 3, hy - 5, hx - 6, hy - 10, "P", 2)  # horns
        c.line(hx + 2, hy - 5, hx + 6, hy - 10, "P", 2)
        c.px(hx + 6, hy - 11, "p")
        c.rect(hx + 5, hy + 4, 2, 2, "S")  # the ring in his nose
        c.rect(hx - 6, hy + 2, 3, 3, "a")  # the champion's rosette, still pinned to his halter
        c.px(hx - 5, hy + 3, "h")
        c.rect(hx - 5, hy + 5, 1, 3, "o")
    else:
        c.line(hx - 1, hy - 3, hx - 3, hy - 6, "p")
        c.line(hx + 2, hy - 3, hx + 4, hy - 6, "p")
    c.line(bx - rx, by - 3, bx - rx - 3, by + 6, dark)
    c.rect(bx - rx - 4, by + 6, 2, 3, "0" if not big else "v")
    if state == "stunned":
        for k in range(3):
            c.px(hx - 4 + k * 4, hy - 14 + (k % 2) * 2, "h")
    return c.outline()


def lichen_back(state):
    """A gravestone with something under it. Hidden, it is exactly the
    churchyard's mossed round stone (props.gravestone)."""
    c = Canvas(22, 28)
    stone = props.gravestone(0, True)
    if state == "hidden":
        c.blit(stone, 4, 8)
        return c
    rise = {"rising": 3, "risen": 7, "move": 7, "windup": 8, "attack": 5, "hurt": 6}[state]
    reach = {"rising": 2, "windup": 1, "attack": 8}.get(state, 4)
    c.rect(6, 27 - rise - 2, 10, rise + 2, "v")  # the hunched body
    c.rect(6, 27 - rise - 2, 10, 1, "V")
    c.rect(13, 27 - rise, 3, rise, "0")
    eye = "R" if state in ("windup", "attack") else "y"
    c.px(12, 27 - rise + 1, eye)
    c.px(15, 27 - rise + 1, eye)
    for side, sx in ((-1, 6), (1, 16)):  # arms of root
        c.line(sx, 27 - rise, sx + side * reach, 27 - rise + (3 if state != "attack" else 0), "b" if False else "V", 2)
        c.px(sx + side * reach, 27 - rise + 4, "y")
    for x in (7, 13):
        c.rect(x + (1 if state == "move" else 0), 25, 3, 2, "v")
    c = c.outline()
    c.blit(stone, 4 + (2 if state == "attack" else 0), 8 - rise + (1 if state == "hurt" else 0))
    return c


def build():
    made = []

    def keep(name, frames, frame, anims=None, **meta):
        frame = (frames[0].w, frames[0].h)
        made.append((name, out("creatures/" + name, strip(frames), frame=frame, anims=anims, **meta)))

    for name, base, alt, eye, extra in (
            ("field_mouse", MOUSE, MOUSE_B, "0", None),
            ("hedgehog", HOG, HOG_B, "0", [("curled", HOG_CURLED)]),
            ("flood_toad", TOAD, TOAD_HOP, "0", [("lob", TOAD_LOB)]),
            ("stook", STOOK, STOOK_B, "y", None),
            ("moth", MOTH, MOTH_B, "0", None),
            ("market_rat", RAT, RAT_B, "y", None),
            ("rat_runt", RUNT, RUNT_B, "y", None),
            ("river_pike", PIKE, PIKE, "y", [("spit", PIKE_SPIT), ("under", PIKE_UNDER)])):
        frames, anims, size = frames_from(base, eye, alt, extra)
        keep(name, frames, size, anims)
    for name, nape, eye in (("rook", "1", "P"), ("jackdaw", "S", "p")):
        def nap(rows):
            return [r.replace("n", nape) for r in rows]
        frames, anims, size = frames_from(nap(BIRD), eye, nap(BIRD), [("fly_up", nap(BIRD_UP)), ("fly_down", nap(BIRD_DOWN))])
        anims["fly"] = {"row": 0, "start": 7, "frames": 2, "fps": 8, "loop": True}
        keep(name, frames, size, anims)
    carried = Canvas(20, 16)  # a jackdaw with the runt it carries
    carried.art(3, 2, [r.replace("n", "S") for r in BIRD_UP], remap={"e": "p"})
    carried.art(6, 9, RUNT, remap={"e": "y"})
    keep("jackdaw_carrying", [carried.outline()], (20, 16))
    states = ["idle", "move", "windup", "charge", "stunned"]
    keep("grist", [boar(s) for s in states + ["wallow"]], (54, 38), layout=" ".join(states + ["wallow"]))
    keep("duke", [cattle("duke", s) for s in states], (58, 42), layout=" ".join(states))
    keep("herd_cattle", [cattle("herd", s) for s in ("idle", "move", "charge")], (38, 28), layout="idle move charge")
    lstates = ["hidden", "rising", "risen", "move", "windup", "attack", "hurt"]
    keep("lichen_back", [lichen_back(s) for s in lstates], (22, 28), layout=" ".join(lstates))
    for night in (False, True):
        keep("cat_night" if night else "cat", cat_frames(night), (18, 14), layout=" ".join(CAT))
    return made
