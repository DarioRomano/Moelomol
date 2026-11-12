"""Mock game screens at the real 640 x 360: every kind of asset together, to
judge whether they read as one game. Review only (not game assets)."""
import os
import random
from px import Canvas
from lib import SHEETS
import ground as G, nature as N, buildings as B, props as P, player as PL, creatures as C, ui as U, icons as I

T = 16
W, H = 40, 23


def fill(c, tiles, x0=0, y0=0, w=W, h=H, seed=1):
    r = random.Random(seed)
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            c.blit(r.choice(tiles), x * T, y * T)


def region(c, x0, y0, w, h, tiles, fringe, seed=2):
    fill(c, tiles, x0, y0, w, h, seed)
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            n, s, wst, e = y == y0, y == y0 + h - 1, x == x0, x == x0 + w - 1
            idx = 8 if n and e else 9 if s and e else 10 if s and wst else 11 if n and wst else 0 if n else 1 if e else 2 if s else 3 if wst else None
            if idx is not None:
                c.blit(fringe[idx], x * T, y * T)


def stand(c, sprite, x, y, flip=False):
    """Draws a sprite with its bottom centre at (x, y)."""
    c.blit(sprite, int(x - sprite.w / 2), int(y - sprite.h), flip)


def hud(c, label):
    c.blit(U.bar_frame(), 8, 8); c.blit(U.bar_fill("R", "r").crop(0, 0, 50, 4), 9, 9)
    c.blit(U.bar_frame(), 8, 16); c.blit(U.bar_fill("h", "a").crop(0, 0, 64, 4), 9, 17)
    c.text(8, 26, label, "P")


def farm():
    c = Canvas(W * T, H * T)
    fill(c, [G.grass_tile("farm", i) for i in range(4)] + [G.grass_tile("farm", "w0", flowers="hPa")])
    fr, bank = G.fringe_set("farm"), G.fringe_set("farm", bank=True)
    region(c, 0, 14, 40, 2, [G.dirt_tile(i) for i in range(4)], fr)
    region(c, 17, 9, 2, 6, [G.dirt_tile(i) for i in range(4)], fr)
    region(c, 23, 16, 9, 5, [G.soil_tile(0), G.soil_tile(1)], fr)
    region(c, 23, 16, 4, 5, [G.soil_tile(0, True)], fr)
    region(c, 2, 16, 8, 5, G.water_frames()[:1], bank)
    for i in range(9):
        for j in range(4):
            kind = "catmint" if i < 5 else "radish"
            c.blit(P.crop(kind, (i + j) % 4), (23 + i) * T, (16 + j) * T + 2)
    for x in range(0, 40, 6):
        stand(c, N.tree("wild" if x % 12 else "farm", x, wood="grey"), x * T + 20, 46)
    f = N.fence_set("warm")
    for x in range(21, 34):
        c.blit(f[0], x * T, 15 * T - 8)
    stand(c, B.compose("farmhouse", 6, 2, door=2, windows=(1, 4), lit=True, chimney=True), 18 * T + 8, 9 * T + 6)
    stand(c, B.compose("workshop", 4, 1, door=1, windows=(3,)), 30 * T, 9 * T + 6)
    stand(c, B.compose("thatch", 3, 1, door=1), 8 * T, 10 * T)
    stand(c, N.tree("farm", "apple", wood="warm", fruit="a"), 36 * T, 13 * T)
    stand(c, P.mailbox(), 15 * T, 14 * T + 4); stand(c, P.bench(), 24 * T, 12 * T); stand(c, P.chest(False), 27 * T, 12 * T)
    stand(c, P.lamp(True), 21 * T + 8, 10 * T); stand(c, N.reeds(0), 3 * T, 17 * T); stand(c, N.rock(1, mossy=True), 11 * T, 19 * T)
    stand(c, C.cat_frames(False)[0], 20 * T, 12 * T)
    stand(c, PL.render("s", PL.P(r=(5, 1, 8), lean=-1), None), 22 * T, 16 * T + 8)
    stand(c, PL.render("e", PL.Pose(legs="step_l"), None), 12 * T, 15 * T + 6)
    hud(c, "The farm   day 3   07:40")
    c.blit(U.bar_frame(), 8, 38); c.blit(U.bar_fill("W", "w").crop(0, 0, 40, 4), 9, 39)
    return c


def kettlebridge():
    c = Canvas(W * T, H * T)
    fill(c, [G.grass_tile("changed", i) for i in range(4)] + [G.grass_tile("wild", 0)])
    fr, bank = G.fringe_set("changed"), G.fringe_set("changed", bank=True)
    region(c, 6, 3, 20, 11, [G.cobble_tile(i) for i in range(4)], fr)
    region(c, 0, 14, 40, 2, [G.dirt_tile(i) for i in range(4)], fr)
    region(c, 0, 17, 40, 6, G.water_frames()[:1], bank)
    fill(c, [G.grass_tile("yard", i) for i in range(4)], 28, 4, 11, 9)
    deck, rl, rr, raised = P.bridge_parts()
    for y in range(17, 23):
        c.blit(rl, 18 * T, y * T); c.blit(rr, 19 * T, y * T)
    stand(c, B.compose("church", 8, 3, door=1, windows=(3, 4, 5, 6), lit=True), 33 * T, 4 * T + 8)
    stand(c, B.tower("church"), 27 * T + 8, 4 * T + 8)
    stand(c, B.compose("brick", 7, 2, door=3, windows=(0, 1, 5, 6)), 4 * T, 5 * T)
    stand(c, B.compose("cottage", 2, 1, door=0), 22 * T, 14 * T)
    for i, (awn, goods) in enumerate((("pa", "eggs"), ("pG", "seeds"), ("pV", "cloth"), ("ps", None))):
        stand(c, P.stall(awn, goods), (9 + i * 4) * T, (8 if i % 2 else 11) * T)
    for i in range(10):
        stand(c, P.gravestone(i % 3, i % 2 == 0), (29 + (i % 5) * 2) * T + 8, (7 + (i // 5) * 3) * T)
    stand(c, C.lichen_back("windup"), 34 * T, 12 * T)
    stand(c, P.barge(), 30 * T, 21 * T)
    stand(c, P.lamp(False, "1", 30), 17 * T, 14 * T); stand(c, P.notice_board(), 7 * T, 14 * T)
    rat = C.frames_from(C.RAT, "y", C.RAT_B)[0]
    stand(c, rat[0], 13 * T, 13 * T); stand(c, rat[4], 15 * T, 12 * T, True); stand(c, rat[3], 11 * T, 12 * T)
    bird = C.frames_from([r.replace("n", "S") for r in C.BIRD], "p", None, [("u", [r.replace("n", "S") for r in C.BIRD_UP])])[0]
    stand(c, bird[7], 21 * T, 7 * T)
    stand(c, C.frames_from(C.PIKE, "y", C.PIKE, [("s", C.PIKE_SPIT)])[0][7], 12 * T, 19 * T)
    stand(c, PL.render("e", PL.P(grip=(5, 0, -2), aim=(1, 0.1, 0), lean=2, legs="wide"), "greatsword"), 9 * T, 13 * T + 8, True)
    hud(c, "Kettlebridge   day 5   16:10")
    c.blit(I.icon(draw=I.greatsword), 8, 38)
    return c


def build():
    os.makedirs(SHEETS, exist_ok=True)
    for name, fn in (("mock_farm", farm), ("mock_kettlebridge", kettlebridge)):
        fn().scaled(2).save(os.path.join(SHEETS, name + ".png"))
    return []
