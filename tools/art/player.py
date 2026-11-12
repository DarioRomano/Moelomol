"""The player: a farmer in a straw hat, 16 x 24 on a 48 x 48 frame (room for
the weapon's swing), feet at (24, 38).

Every pose is written once, in the character's own terms (forward, to their
right, up), and drawn facing south, north and east from that; west is east
mirrored by the game. That keeps the figure identical in every frame of every
weapon: the thing image generators cannot do (combat-art-prompts.md).
"""
import math
from px import Canvas, rng, strip
from lib import out

F = 48
SHEET_SCALE = 2
FACINGS = ("s", "n", "e")
CHEST = (24, 27)
REST_R, REST_L = (1, 5, -7), (1, -5, -7)


def project(facing, v):
    f, s, u = v
    if facing == "s":
        return (-s, f * 0.5 - u)
    if facing == "n":
        return (s, -f * 0.5 - u)
    return (f, s * 0.5 - u)


def depth(facing, v):
    f, s, _u = v
    return f if facing == "s" else (-f if facing == "n" else s)


def norm(v):
    n = math.sqrt(sum(x * x for x in v)) or 1.0
    return tuple(x / n for x in v)


def add(a, b, k=1.0):
    return tuple(x + y * k for x, y in zip(a, b))


class Pose:
    def __init__(self, r=REST_R, l=REST_L, legs="stand", bob=0, crouch=0, lean=0, weapon=None, grip=None, aim=None,
                 draw=0.0, arrow=True, both=False, special=None):
        self.r, self.l, self.legs, self.bob, self.crouch, self.lean = r, l, legs, bob, crouch, lean
        self.weapon, self.grip, self.aim, self.draw, self.arrow, self.both = weapon, grip, aim, draw, arrow, both
        self.special = special


def P(**kw):
    return Pose(**kw)


# --- the body ---------------------------------------------------------------------

def draw_legs(c, facing, pose, y0):
    top = 33 + pose.crouch + y0
    lift = {"stand": (0, 0), "step_l": (2, 0), "step_r": (0, 2), "pass": (0, 0), "wide": (0, 0), "stomp_up": (0, 4),
            "kneel": (0, 0)}[pose.legs]
    if facing in ("s", "n"):
        spread = 1 if pose.legs == "wide" else 0
        for x, up in ((20 - spread, lift[0]), (25 + spread, lift[1])):
            bottom = 38 - up
            c.rect(x, top, 3, max(0, bottom - top - 2), "2")
            c.rect(x + 2, top, 1, max(0, bottom - top - 2), "1")
            c.rect(x, bottom - 2, 3, 2, "b")
    else:
        fwd = {"step_l": 2, "step_r": -2, "wide": 2, "stomp_up": 0}.get(pose.legs, 0)
        for x, tone, up in ((23 - fwd, "1", lift[0]), (22 + fwd, "2", lift[1])):  # far leg, then near
            bottom = 38 - up
            c.rect(x, top, 4, max(0, bottom - top - 2), tone)
            c.rect(x, bottom - 2, 5, 2, "b")


def draw_torso(c, facing, dx, dy):
    if facing == "e":
        c.rect(21 + dx, 25 + dy, 6, 8, "o")
        c.rect(21 + dx, 25 + dy, 1, 8, "b")
        c.rect(19 + dx, 29 + dy, 3, 4, "y")  # the satchel, on the far hip
        c.line(22 + dx, 25 + dy, 25 + dx, 31 + dy, "b")
        c.rect(21 + dx, 32 + dy, 6, 1, "b")
        return
    c.rect(20 + dx, 25 + dy, 8, 8, "o")
    c.rect(27 + dx, 25 + dy, 1, 8, "b")
    c.rect(20 + dx, 32 + dy, 8, 1, "b")
    if facing == "s":
        c.rect(23 + dx, 25 + dy, 2, 1, "p")  # the collar
        c.line(26 + dx, 25 + dy, 21 + dx, 31 + dy, "b")  # the satchel's strap
        c.rect(18 + dx, 30 + dy, 3, 4, "y")
    else:
        c.line(21 + dx, 25 + dy, 26 + dx, 31 + dy, "b")
        c.rect(27 + dx, 30 + dy, 3, 4, "y")
        c.rect(27 + dx, 30 + dy, 3, 1, "p")


def draw_head(c, facing, dx, dy):
    if facing == "s":
        c.rect(20 + dx, 18 + dy, 8, 6, "a")
        c.rect(21 + dx, 24 + dy, 6, 1, "a")
        c.rect(20 + dx, 18 + dy, 8, 1, "b")
        c.rect(20 + dx, 19 + dy, 1, 2, "b")
        c.rect(27 + dx, 19 + dy, 1, 2, "b")
        c.px(21 + dx, 20 + dy, "h")
        c.px(22 + dx, 21 + dy, "0")
        c.px(25 + dx, 21 + dy, "0")
        c.rect(23 + dx, 23 + dy, 2, 1, "o")  # the mouth, set
    elif facing == "n":
        c.rect(20 + dx, 18 + dy, 8, 5, "b")
        c.rect(21 + dx, 19 + dy, 2, 1, "o")
        c.rect(22 + dx, 23 + dy, 4, 2, "a")
    else:
        c.rect(21 + dx, 18 + dy, 7, 6, "a")
        c.rect(22 + dx, 24 + dy, 5, 1, "a")
        c.rect(21 + dx, 18 + dy, 3, 5, "b")
        c.rect(24 + dx, 18 + dy, 4, 1, "b")
        c.px(26 + dx, 21 + dy, "0")
        c.px(28 + dx, 22 + dy, "a")
        c.px(25 + dx, 20 + dy, "h")
    ex = 1 if facing == "e" else 0  # the straw hat: brim, crown, band
    c.rect(18 + dx + ex, 17 + dy, 12, 1, "h")
    c.rect(19 + dx + ex, 18 + dy, 10, 1, "a")
    c.rect(21 + dx + ex, 13 + dy, 6, 4, "h")
    c.rect(21 + dx + ex, 16 + dy, 6, 1, "o")
    c.px(21 + dx + ex, 13 + dy, "P")
    c.px(26 + dx + ex, 14 + dy, "a")
    c.px(26 + dx + ex, 15 + dy, "a")


# --- what the hands hold ----------------------------------------------------------

def draw_greatsword(c, grip, d):
    """A plough share on a long grip: dark iron, one worn bright edge."""
    gx, gy = grip
    c.line(gx - d[0] * 4, gy - d[1] * 4, gx + d[0] * 2, gy + d[1] * 2, "b", 2)
    px, py = -d[1], d[0]
    c.line(gx + d[0] * 2 - px * 2, gy + d[1] * 2 - py * 2, gx + d[0] * 2 + px * 2, gy + d[1] * 2 + py * 2, "s", 2)
    c.line(gx + d[0] * 3, gy + d[1] * 3, gx + d[0] * 15, gy + d[1] * 15, "s", 4)  # the broad share
    c.line(gx + d[0] * 3, gy + d[1] * 3, gx + d[0] * 17, gy + d[1] * 17, "S", 3)
    c.line(gx + d[0] * 3, gy + d[1] * 3, gx + d[0] * 18, gy + d[1] * 18, "T", 2)
    c.line(gx + d[0] * 4, gy + d[1] * 4, gx + d[0] * 18, gy + d[1] * 18, "P", 1)  # the worn bright edge


def draw_hammer(c, grip, d):
    """A fence-post maul: ash handle, a squared head banded with iron."""
    gx, gy = grip
    c.line(gx - d[0] * 3, gy - d[1] * 3, gx + d[0] * 14, gy + d[1] * 14, "b", 2)
    c.line(gx - d[0] * 3, gy - d[1] * 3, gx + d[0] * 12, gy + d[1] * 12, "o", 1)
    hx, hy = round(gx + d[0] * 15), round(gy + d[1] * 15)
    c.rect(hx - 4, hy - 3, 8, 7, "o")
    c.rect(hx - 4, hy - 3, 8, 1, "a")
    c.rect(hx - 4, hy + 3, 8, 1, "b")
    c.rect(hx - 3, hy - 3, 1, 7, "s")
    c.rect(hx + 2, hy - 3, 1, 7, "s")


def draw_bow(c, hand, d, pull, string_hand, arrow):
    """Orchard wood, drawn as an arc across the aim; the string runs through
    the drawing hand."""
    hx, hy = hand
    n = math.hypot(d[0], d[1])
    d = (d[0] / n, d[1] / n) if n > 0.25 else (0.0, 1.0)
    px, py = -d[1], d[0]
    tips = []
    for k in range(-8, 9):
        t = k / 8.0
        bulge = (1 - t * t) * 3 - 3
        x, y = hx + px * k + d[0] * bulge, hy + py * k + d[1] * bulge
        c.px(round(x), round(y), "o" if abs(k) < 7 else "a")
        c.px(round(x - d[0]), round(y - d[1]), "b")  # the belly of the limb
        if abs(k) == 8:
            tips.append((x, y))
    c.px(round(hx), round(hy), "p")  # the cloth grip
    sx, sy = string_hand if pull > 0.05 else (hx - d[0] * 3, hy - d[1] * 3)
    for tx, ty in tips:
        c.line(tx, ty, sx, sy, "p")
    if arrow:
        c.line(sx, sy, sx + d[0] * 11, sy + d[1] * 11, "p")
        c.px(round(sx + d[0] * 12), round(sy + d[1] * 12), "T")
        c.px(round(sx), round(sy), "S")


def draw_lantern(c, hand):
    """An old storm lantern; the one violet thing the player owns."""
    x, y = round(hand[0]) - 2, round(hand[1]) + 1
    c.rect(x + 1, y, 3, 1, "S")
    c.rect(x, y + 1, 5, 6, "s")
    c.rect(x + 1, y + 2, 3, 4, "V")
    c.rect(x + 2, y + 2, 1, 3, "P")
    c.px(x + 1, y + 5, "v")
    c.rect(x, y + 7, 5, 1, "S")


def draw_ball(c, facing, phase):
    """The roll: tucked into a ball, hat leading."""
    cx, cy = 24, 32
    c.ellipse(cx, cy, 6, 5.5, "o")
    c.ellipse(cx + 1, cy + 1.5, 4.5, 3.5, "b")
    a = phase * math.pi / 2 + (0 if facing != "n" else math.pi)
    hx, hy = cx + math.cos(a) * 4, cy - abs(math.sin(a)) * 4 + 1
    c.ellipse(hx, hy, 3.4, 2.4, "h")
    c.rect(round(hx) - 1, round(hy), 3, 1, "a")
    bx, by = cx - math.cos(a) * 4, cy + abs(math.sin(a)) * 3
    c.rect(round(bx) - 1, round(by), 3, 2, "2")


def draw_fallen(c, facing):
    """Down: on the ground, hat rolled away. The game fades to the farm bed."""
    c.rect(14, 33, 14, 5, "o")
    c.rect(14, 37, 14, 1, "b")
    c.rect(28, 34, 6, 4, "2")
    c.rect(33, 35, 3, 3, "b")
    c.rect(9, 32, 6, 6, "a" if facing != "n" else "b")
    c.rect(9, 32, 6, 2, "b")
    c.ellipse(8, 27, 4.5, 2.2, "h")
    c.rect(6, 25, 4, 2, "h")


def render(facing, pose, weapon):
    c = Canvas(F, F)
    if pose.special == "ball":
        draw_ball(c, facing, pose.bob)
        return c.outline()
    if pose.special == "fallen":
        draw_fallen(c, facing)
        return c.outline()
    dy = pose.bob + pose.crouch
    lean = pose.lean
    hdx = lean if facing == "e" else 0
    tdx = (lean // 2 if lean > 0 else -((-lean) // 2)) if facing == "e" else 0
    hdy = dy + ((1 if lean > 1 else (-1 if lean < -1 else 0)) * (1 if facing == "s" else -1) if facing != "e" else 0)
    origin = (CHEST[0] + tdx, CHEST[1] + dy)

    def screen(v):
        x, y = project(facing, v)
        return (origin[0] + x, origin[1] + y)

    items = []  # (depth, draw function)
    r, l = pose.r, pose.l
    d3 = norm(pose.aim) if pose.aim else None
    if weapon in ("greatsword", "hammer") and pose.grip is not None:
        r = pose.grip
        l = add(pose.grip, d3, -3)
    if weapon == "bow" and pose.aim is not None:
        r = add(l, d3, -(2 + pose.draw * 7))

    def arm(hand, shoulder, near):
        def go():
            sx, sy = screen(shoulder)
            hx, hy = screen(hand)
            c.line(sx, sy, hx, hy, "o" if near else "b", 2)
            c.rect(round(hx), round(hy), 2, 2, "a")
        return go

    near_r = depth(facing, (0, 4, 0)) >= 0
    items.append((depth(facing, r) - 0.1, arm(r, (0, 4, 1), near_r or facing != "e")))
    items.append((depth(facing, l) - 0.1, arm(l, (0, -4, 1), (not near_r) or facing != "e")))

    if weapon in ("greatsword", "hammer") and d3 is not None:
        gx, gy = screen(r)
        ex, ey = project(facing, d3)
        wfn = draw_greatsword if weapon == "greatsword" else draw_hammer
        items.append((depth(facing, add(r, d3, 8)), lambda: wfn(c, (gx, gy), (ex, ey))))
    elif weapon == "bow":
        aim = d3 or (0.2, -0.2, -0.95)
        ex, ey = project(facing, aim)
        hand = screen(l)
        items.append((depth(facing, l) + 0.2, lambda: draw_bow(c, hand, (ex, ey), pose.draw, screen(r), pose.arrow and pose.aim is not None)))
    elif weapon == "lantern":
        hand = screen(r)
        items.append((depth(facing, r) + 0.2, lambda: draw_lantern(c, hand)))

    for _d, fn in sorted((i for i in items if i[0] < 0), key=lambda i: i[0]):
        fn()
    draw_legs(c, facing, pose, 0)
    draw_torso(c, facing, tdx, dy)
    draw_head(c, facing, hdx, hdy)
    for _d, fn in sorted((i for i in items if i[0] >= 0), key=lambda i: i[0]):
        fn()
    return c.outline()


def dissolve(frame, amount, seed):
    """The blink: the figure breaking into violet motes."""
    r = rng("blink%s" % seed)
    out_c = Canvas(F, F)
    for y in range(F):
        for x in range(F):
            p = frame.g[y][x]
            if p is None:
                continue
            roll = r.random()
            if roll > amount:
                out_c.g[y][x] = p
            elif roll > amount * 0.55:
                out_c.px(x + r.randrange(-2, 3), y - r.randrange(0, 4), "V" if roll > amount * 0.8 else "v")
    return out_c


# --- the animations ---------------------------------------------------------------

WALK = [("step_l", 0, 2), ("pass", 1, 0), ("step_r", 0, -2), ("pass", 1, 0)]


def walk(**hold):
    frames = []
    for legs, bob, swing in WALK:
        kw = dict(legs=legs, bob=bob)
        if "grip" not in hold and "aim" not in hold and "r" not in hold:
            kw.update(r=add(REST_R, (swing, 0, 0)), l=add(REST_L, (-swing, 0, 0)))
        kw.update(hold)
        frames.append(P(**kw))
    return frames


GS_CARRY = dict(grip=(2, 3, -2), aim=(-0.5, 0.25, 0.85))
HM_CARRY = dict(grip=(2, 4, -3), aim=(0.45, 0.2, -0.85))
BOW_CARRY = dict(l=(2, -4, -5))
LAN_CARRY = dict(r=(2, 4, -5))

SETS = {
    "base": [
        ("idle", 3, True, [P(), P(bob=1)]),
        ("walk", 8, True, walk()),
        ("roll", 12, False, [P(crouch=4, r=(3, 3, -6), l=(3, -3, -6)), P(special="ball", bob=0), P(special="ball", bob=1), P(crouch=2)]),
        ("hurt", 6, False, [P(lean=-2, r=(-2, 7, 2), l=(-2, -7, 2), legs="wide")]),
        ("down", 3, False, [P(crouch=5, legs="kneel", r=(3, 4, -9), l=(3, -4, -9), lean=2), P(special="fallen")]),
        ("cast", 8, False, [P(r=(4, 3, -1)), P(r=(5, 2, 5)), P(r=(5, 1, 8), lean=-1)]),
        ("interact", 6, False, [P(crouch=2, r=(5, 2, -5)), P(crouch=3, r=(6, 1, -7))]),
        ("stroke", 4, True, [P(crouch=4, r=(6, 1, -8)), P(crouch=4, r=(7, 2, -8))]),
    ],
    "greatsword": [
        ("idle", 3, True, [P(**GS_CARRY), P(bob=1, **GS_CARRY)]),
        ("walk", 8, True, walk(**GS_CARRY)),
        ("light_1", 12, False, [P(grip=(-1, 6, -1), aim=(-0.6, 0.8, 0.15), lean=-1, legs="wide"),
                                P(grip=(5, 0, -2), aim=(1, 0.1, 0), lean=2, legs="wide"), P(grip=(3, -5, -2), aim=(0.2, -1, 0.1), lean=1)]),
        ("light_2", 12, False, [P(grip=(-1, -6, -1), aim=(-0.6, -0.8, 0.15), lean=-1, legs="wide"),
                                P(grip=(5, 0, -2), aim=(1, -0.1, 0), lean=2, legs="wide"), P(grip=(3, 5, -2), aim=(0.2, 1, 0.1), lean=1)]),
        ("light_3", 12, False, [P(grip=(0, 2, 5), aim=(-0.5, 0.2, 0.9), lean=-2, legs="wide"),
                                P(grip=(5, 0, -3), aim=(1, 0, -0.3), lean=2, crouch=1, legs="wide"), P(grip=(4, -2, -6), aim=(0.8, -0.3, -0.5), crouch=1)]),
        ("cleave", 10, False, [P(grip=(-1, 0, 7), aim=(-0.3, 0, 1), lean=-2), P(grip=(5, 0, -6), aim=(1, 0, -0.2), lean=2, crouch=2, legs="wide"),
                               P(grip=(4, 0, -5), aim=(0.9, 0, 0.2), crouch=1)]),
        ("shove", 10, False, [P(grip=(0, -4, -1), aim=(0, 1, 0.05)), P(grip=(6, -4, 0), aim=(0, 1, 0.05), lean=3, legs="step_l"),
                              P(grip=(3, -4, -1), aim=(0, 1, 0.05), lean=1)]),
        ("spin", 14, False, [P(grip=(0, 3, -2), aim=(0, 1, 0), legs="wide"), P(grip=(-3, 0, -2), aim=(-1, 0, 0), legs="wide"),
                             P(grip=(0, -3, -2), aim=(0, -1, 0), legs="wide"), P(grip=(3, 0, -2), aim=(1, 0, 0), legs="wide")]),
        ("rise", 10, False, [P(grip=(2, 3, -8), aim=(0.6, 0.4, -0.7), crouch=2), P(grip=(4, 0, 4), aim=(0.4, 0, 0.9), lean=-1),
                             P(grip=(1, -2, 6), aim=(-0.3, -0.3, 0.9))]),
        ("guard", 4, False, [P(grip=(4, 4, 0), aim=(0, -1, 0.1), legs="wide"), P(grip=(2, 4, 0), aim=(0, -1, 0.2), legs="wide", lean=-2, bob=1)]),
    ],
    "hammer": [
        ("idle", 3, True, [P(**HM_CARRY), P(bob=1, **HM_CARRY)]),
        ("walk", 8, True, walk(**HM_CARRY)),
        ("charge", 4, False, [P(grip=(1, 3, -1), aim=(-0.5, 0.5, 0.4)), P(grip=(0, 3, 2), aim=(-0.6, 0.4, 0.7), legs="wide"),
                              P(grip=(-1, 3, 4), aim=(-0.5, 0.3, 0.9), legs="wide", lean=-1), P(grip=(-1, 2, 6), aim=(-0.3, 0.1, 1), legs="wide", lean=-2, crouch=1)]),
        ("strike", 10, False, [P(grip=(5, 0, -5), aim=(1, 0, -0.3), lean=3, crouch=2, legs="wide"), P(grip=(4, 0, -4), aim=(0.9, 0, 0), crouch=1)]),
        ("jab", 12, False, [P(grip=(0, 3, -2), aim=(1, 0, 0)), P(grip=(6, 2, -2), aim=(1, 0, 0), lean=2, legs="step_l"), P(grip=(3, 3, -2), aim=(1, 0, 0))]),
        ("stomp", 10, False, [P(legs="stomp_up", lean=-1, **HM_CARRY), P(crouch=1, legs="wide", lean=1, **HM_CARRY), P(**HM_CARRY)]),
    ],
    "bow": [
        ("idle", 3, True, [P(**BOW_CARRY), P(bob=1, **BOW_CARRY)]),
        ("walk", 8, True, walk(**BOW_CARRY)),
        ("quick", 12, False, [P(l=(6, -1, 0), aim=(1, 0, 0), draw=0.35), P(l=(6, -1, 0), aim=(1, 0, 0), draw=0, arrow=False), P(l=(3, -3, -4))]),
        ("draw", 6, False, [P(l=(6, -1, 0), aim=(1, 0, 0), draw=0.3), P(l=(7, -1, 0), aim=(1, 0, 0), draw=0.65, legs="wide"),
                            P(l=(7, -1, 0), aim=(1, 0, 0), draw=1.0, legs="wide", lean=-1), P(l=(7, -1, 0), aim=(1, 0, 0), draw=0, arrow=False, legs="wide")]),
        ("hold_walk", 5, True, walk(l=(7, -1, 0), aim=(1, 0, 0), draw=1.0)),
        ("roll_shot", 10, False, [P(crouch=3, l=(6, -1, 0), aim=(1, 0, 0), draw=0.8, legs="wide"), P(crouch=3, l=(6, -1, 0), aim=(1, 0, 0), draw=0, arrow=False, legs="wide")]),
        ("volley", 8, False, [P(l=(4, -1, 5), aim=(0.6, 0, 0.8), draw=1.0, lean=-2, legs="wide"), P(l=(4, -1, 5), aim=(0.6, 0, 0.8), draw=0, arrow=False, lean=-1)]),
    ],
    "lantern": [
        ("idle", 3, True, [P(**LAN_CARRY), P(bob=1, **LAN_CARRY)]),
        ("walk", 8, True, walk(**LAN_CARRY)),
        ("flick", 14, False, [P(r=(-1, 5, -2)), P(r=(7, 2, 1), lean=1), P(r=(4, 3, -3))]),
        ("throw", 10, False, [P(r=(-4, 4, -6), lean=-1, legs="wide"), P(r=(6, 2, 0), lean=2, legs="step_l"), P(r=(5, 2, 3), lean=1)]),
        ("lob", 10, False, [P(r=(-2, 4, -6)), P(r=(5, 3, -2)), P(r=(4, 3, 2))]),
        ("siphon_hold", 5, True, [P(r=(6, 1, 3), l=(5, -1, 2), lean=-2, legs="wide"), P(r=(6, 1, 3), l=(5, -1, 2), lean=-3, legs="wide", bob=1)]),
        ("siphon_release", 10, False, [P(r=(8, 0, 2), l=(6, -2, 1), lean=3, legs="step_l"), P(r=(3, 1, 4), lean=-3, legs="wide"), P(r=(3, 3, -2))]),
        ("blink", 14, False, "blink"),
    ],
}


def frames_for(weapon, anim_frames, facing):
    if anim_frames == "blink":
        idle = render(facing, P(**LAN_CARRY), weapon)
        return [dissolve(idle, 0.25, facing), dissolve(idle, 0.7, facing + "b"), dissolve(idle, 0.96, facing + "c"), dissolve(idle, 0.6, facing + "d")]
    return [render(facing, p, None if weapon == "base" else weapon) for p in anim_frames]


def build():
    made = []
    for weapon, anims in SETS.items():
        cols = max(4, max(len(a[3]) if a[3] != "blink" else 4 for a in anims))
        sheet = Canvas(cols * F, len(anims) * len(FACINGS) * F)
        info = {}
        review = Canvas(cols * F * 3 + 8, len(anims) * F)
        for i, (name, fps, loop, poses) in enumerate(anims):
            for j, facing in enumerate(FACINGS):
                row = i * len(FACINGS) + j
                frames = frames_for(weapon, poses, facing)
                for k, frame in enumerate(frames):
                    sheet.blit(frame, k * F, row * F)
                    review.blit(frame, j * (cols * F + 4) + k * F, i * F)
                info["%s_%s" % (name, facing)] = {"row": row, "frames": len(frames), "fps": fps, "loop": loop}
        out("player/player_" + weapon, sheet, frame=(F, F), anims=info, feet=[24, 38], west="mirror of east")
        made.append(("player_%s: rows %s | columns south, north, east" % (weapon, " ".join(a[0] for a in anims)), review))
    return made
