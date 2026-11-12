"""Props: the things people left (art-direction.md, "Traces, not bodies"),
the farm's furniture, crops, and what each area's objective turns on.

Outlined, anchored bottom centre. Warm tones only on the farm and on what the
player is meant to notice out in the world (notes, the key, lit windows).
"""
import math
from px import Canvas, from_art, rng, strip
from lib import out

T = 16
SHEET_SCALE = 3


def planks(c, x, y, w, h, tones=("b", "o", "a"), across=True, gap=4):
    d, m, l = tones
    c.rect(x, y, w, h, m)
    if across:
        for j in range(y + gap - 1, y + h, gap):
            c.rect(x, j, w, 1, d)
    else:
        for i in range(x + gap - 1, x + w, gap):
            c.rect(i, y, 1, h, d)
    c.rect(x, y, w, 1, l)


# --- the farm ---------------------------------------------------------------------

def chest(opened):
    c = Canvas(16, 15)
    planks(c, 1, 6, 14, 8, across=False)
    c.rect(1, 6, 14, 1, "b")
    if opened:
        planks(c, 1, 0, 14, 5)
        c.rect(2, 5, 12, 2, "0")
    else:
        c.rect(1, 2, 14, 4, "o")
        c.rect(1, 2, 14, 1, "a")
    c.rect(7, 5 if not opened else 7, 2, 3, "S")  # the hasp
    c.rect(0, 9, 16, 1, "s")
    return c.outline()


def mailbox():
    c = Canvas(12, 20)
    c.rect(5, 8, 2, 12, "b")
    c.rect(1, 2, 10, 6, "o")
    c.rect(1, 2, 10, 1, "a")
    c.rect(1, 7, 10, 1, "b")
    c.rect(3, 4, 5, 1, "0")  # the slot
    c.rect(10, 0, 1, 4, "R")  # the flag (never raised again)
    return c.outline()


def bench():
    c = Canvas(26, 13)
    planks(c, 1, 1, 24, 4, gap=2)
    planks(c, 1, 6, 24, 3, gap=5)
    for x in (2, 21):
        c.rect(x, 9, 3, 4, "b")
    return c.outline()


def lamp(lit, post="b", tall=22):
    c = Canvas(10, tall)
    c.rect(4, 8, 2, tall - 8, post)
    c.rect(3, tall - 2, 4, 2, post)
    c.rect(2, 1, 6, 7, "0")
    c.rect(3, 2, 4, 5, "h" if lit else "1")
    if lit:
        c.rect(4, 3, 2, 3, "P")
    c.rect(1, 0, 8, 1, post)
    return c.outline()


def well():
    c = Canvas(24, 26)
    c.rect(3, 12, 18, 12, "S")
    for j in range(12, 24, 4):
        c.rect(3, j + 3, 18, 1, "s")
        for i in range(3 + (j // 4 % 2) * 3, 21, 6):
            c.rect(i, j, 1, 3, "s")
    c.ellipse(11.5, 12, 9, 3, "s")
    c.ellipse(11.5, 12, 7, 2, "0")
    for x in (3, 19):
        c.rect(x, 2, 2, 11, "2")
    c.rect(1, 0, 22, 3, "1")  # the little roof
    c.rect(1, 0, 22, 1, "2")
    c.rect(6, 6, 12, 1, "s")  # the windlass, its rope still wound
    c.rect(11, 6, 2, 6, "y")
    return c.outline()


def signpost():
    c = Canvas(18, 22)
    c.rect(8, 4, 2, 18, "2")
    c.poly([(1, 3), (14, 3), (17, 6), (14, 9), (1, 9)], "s")
    c.rect(1, 3, 14, 1, "S")
    c.rect(3, 6, 8, 1, "0")
    return c.outline()


def hive():
    c = Canvas(14, 16)
    for j, w in enumerate((6, 8, 10, 12, 12, 12)):
        c.rect(7 - w // 2, 1 + j * 2, w, 2, "y" if j % 2 else "M")
    c.rect(1, 13, 12, 3, "2")
    c.rect(6, 10, 2, 2, "0")
    return c.outline()


def shelter():
    """The great fields' ruined shelter: three posts and what is left of a roof."""
    c = Canvas(48, 34)
    for x in (4, 22, 41):
        c.rect(x, 10, 3, 24, "s")
        c.rect(x + 2, 10, 1, 24, "2")
    c.poly([(0, 12), (30, 2), (47, 6), (47, 10), (30, 8), (0, 16)], "2")
    c.line(0, 12, 30, 2, "s")
    c.line(31, 14, 44, 30, "2", 2)  # a fallen rafter
    for x in range(2, 28, 5):
        c.line(x, 15 - x // 4, x + 2, 13 - x // 4, "1")
    return c.outline()


def crop(kind, stage, withered=False):
    """Four growth stages on a transparent tile, to stand on tilled soil.
    Living crops are the only saturated green in the game."""
    c = Canvas(T, T)
    dark, light = ("y", "p") if withered else ("c", "C")
    if stage == 0:  # sown: two seed leaves
        c.px(7, 11, dark); c.px(9, 11, dark); c.px(8, 12, dark)
        return c.outline()
    if kind == "catmint":
        h = (0, 5, 8, 11)[stage]
        for x, lean in ((5, -1), (8, 0), (11, 1)):
            c.line(x, 14, x + lean, 14 - h, dark)
            for y in range(14 - h + 1, 14, 2):
                c.px(x + lean - 1, y, light)
                c.px(x + lean + 1, y + 1, light)
            if stage == 3:  # flower spikes: the one violet that is loved
                c.rect(x + lean, 14 - h - 2, 1, 3, "p" if withered else "V")
                c.px(x + lean, 14 - h - 3, "P" if not withered else "y")
    else:  # radish: a rosette of leaves, the root showing when ready
        r = (0, 3, 5, 6)[stage]
        for a in range(0, 360, 60 if stage > 1 else 120):
            x, y = 8 + math.cos(math.radians(a)) * r, 11 - abs(math.sin(math.radians(a))) * r
            c.line(8, 12, x, y, dark)
            c.px(x, y, light)
        if stage == 3:
            c.rect(6, 12, 4, 3, "y" if withered else "R")
            c.px(6, 12, "p")
    return c.outline()


# --- inside the farmhouse ---------------------------------------------------------

def bed():
    c = Canvas(22, 34)
    c.rect(1, 1, 20, 32, "b")
    c.rect(2, 2, 18, 5, "o")  # the headboard
    c.rect(2, 8, 18, 24, "p")
    c.rect(4, 9, 14, 6, "P")  # the pillow
    c.rect(2, 16, 18, 16, "a")  # the quilt, patched
    for x, y in ((3, 18), (11, 18), (7, 24), (15, 24)):
        c.rect(x, y, 4, 4, "o")
    c.rect(2, 16, 18, 1, "h")
    return c.outline()


def stove(frame):
    c = Canvas(18, 26)
    c.rect(7, 0, 4, 8, "2")  # the flue
    c.rect(1, 8, 16, 16, "1")
    c.rect(1, 8, 16, 2, "2")
    c.rect(0, 23, 18, 2, "0")
    c.rect(4, 13, 10, 7, "0")
    if frame is not None:  # the fire behind the door, two frames
        c.rect(5, 14, 8, 5, "o")
        for x in range(5, 13):
            if (x + frame) % 2:
                c.rect(x, 15, 1, 3, "a")
            if (x + frame) % 3 == 0:
                c.px(x, 14, "h")
    for x in (4, 13):
        c.px(x, 21, "s")
    return c.outline()


def table():
    c = Canvas(34, 22)
    planks(c, 1, 2, 32, 12, across=False, gap=6)
    c.rect(1, 13, 32, 2, "b")
    for x in (2, 29):
        c.rect(x, 15, 3, 6, "b")
    return c.outline()


def chair():
    c = Canvas(12, 16)
    c.rect(2, 1, 8, 6, "o"); c.rect(2, 1, 8, 1, "a"); c.rect(3, 3, 6, 2, "b")
    c.rect(1, 7, 10, 4, "a"); c.rect(1, 10, 10, 1, "b")
    for x in (1, 9):
        c.rect(x, 11, 2, 5, "b")
    return c.outline()


def cupboard():
    c = Canvas(18, 30)
    planks(c, 1, 1, 16, 28, across=False, gap=8)
    c.rect(1, 1, 16, 2, "a")
    c.rect(1, 14, 16, 1, "b")
    for x in (7, 10):
        c.px(x, 9, "h"); c.px(x, 21, "h")
    return c.outline()


def rug():
    c = Canvas(48, 28)
    c.rect(1, 1, 46, 26, "o")
    c.box(3, 3, 42, 22, "a")
    c.box(6, 6, 36, 16, "b")
    for x in range(10, 40, 6):
        c.rect(x, 12, 3, 4, "h")
    for x in range(1, 47, 2):
        c.px(x, 0, "a"); c.px(x, 27, "a")
    return c


def candle(frame):
    c = Canvas(6, 11)
    c.rect(2, 5, 2, 5, "P")
    c.rect(1, 10, 4, 1, "s")
    c.px(2 + frame % 2, 2, "h"); c.rect(2, 3, 2, 2, "a"); c.px(2, 4, "h")
    return c.outline()


def small(rows):
    return from_art(rows).outline()


# --- Millbrook --------------------------------------------------------------------

def sluice(frame):
    c = Canvas(18, 22)
    c.rect(1, 12, 16, 9, "s")
    c.rect(1, 12, 16, 1, "T")
    c.rect(7, 16, 4, 5, "0")  # the gate
    a = frame * math.pi / 8
    c.ring(8.5, 6.5, 6, "2", 4.5)
    for k in range(4):
        c.line(8.5, 6.5, 8.5 + math.cos(a + k * math.pi / 2) * 6, 6.5 + math.sin(a + k * math.pi / 2) * 6, "2")
    c.rect(8, 6, 2, 2, "S")
    return c.outline()


def millstone(leaning):
    c = Canvas(22, 16)
    if leaning:
        c.ellipse(10.5, 7.5, 9, 7, "s"); c.ellipse(9.5, 7, 8, 6, "S"); c.ellipse(9.5, 7, 2, 1.5, "0")
        for k in range(6):
            c.line(9.5, 7, 9.5 + math.cos(k) * 7, 7 + math.sin(k) * 5, "s")
    else:
        c.rect(2, 7, 18, 6, "s"); c.ellipse(10.5, 7, 9, 3.5, "S"); c.ellipse(10.5, 7, 2, 1, "0")
    return c.outline()


def sacks():
    c = Canvas(18, 14)
    for x, y in ((1, 5), (9, 5), (5, 0)):
        c.blob(x + 4, y + 4.5, 4, 4, "y", "p", "P")
        c.rect(x + 3, y, 2, 1, "y")
    return c.outline()


def trough():
    c = Canvas(42, 14)
    planks(c, 1, 3, 40, 9, tones=("1", "2", "s"), gap=3)
    c.rect(3, 4, 36, 3, "w")
    c.rect(5, 5, 6, 1, "W")
    for x in (2, 37):
        c.rect(x, 12, 3, 2, "1")
    return c.outline()


def wallow():
    c = Canvas(56, 40)
    c.ellipse(27.5, 20, 27, 18, "1")
    c.ellipse(27.5, 20, 24, 15, "2")
    c.ellipse(24, 17, 12, 6, "v")
    r = rng("wallow")
    for _ in range(18):
        c.px(r.randrange(8, 48), r.randrange(8, 32), r.choice("1s"))
    return c


def sheaf():
    c = Canvas(12, 16)
    for x in range(2, 10):
        c.line(x, 15, 5.5 + (x - 5.5) * 0.3, 7, "y")
        c.line(5.5 + (x - 5.5) * 0.3, 7, x - 1 + (x % 2) * 2, 1, "p" if x % 2 else "y")
    c.rect(4, 7, 4, 2, "b")  # the binding
    return c.outline()


def fungus(frame):
    c = Canvas(10, 9)
    for x, y, w in ((1, 4, 4), (5, 2, 4), (4, 6, 3)):
        c.rect(x, y, w, 2, "V" if frame == 0 else "y")
        c.rect(x + 1, y - 1, w - 2, 1, "y" if frame == 0 else "P")
        c.px(x + w // 2, y + 2, "v")
    return c.outline()


# --- Kettlebridge -----------------------------------------------------------------

def stall(awning, goods):
    """A market stall left set out: trestle, awning on poles, the day's goods."""
    c = Canvas(34, 30)
    for x in (2, 30):
        c.rect(x, 4, 2, 24, "2")
    for i in range(1, 33):  # the striped awning, sagging
        sag = 1 if 8 < i < 26 else 0
        c.rect(i, 1 + sag, 1, 7, awning[(i // 4) % 2])
    c.rect(1, 8, 32, 1, "0")
    for i in range(1, 33, 4):
        c.rect(i, 9, 2, 1, awning[0])  # the scalloped edge
    planks(c, 3, 16, 28, 5, tones=("1", "2", "s"), gap=6, across=False)
    c.rect(3, 21, 28, 5, "1")
    if goods == "eggs":  # Arthur's: a crate of eggs and the cash tin
        c.rect(6, 12, 10, 4, "y"); c.rect(6, 12, 10, 1, "p")
        for x in (7, 10, 13):
            c.px(x, 13, "P")
        c.rect(20, 13, 6, 3, "s"); c.rect(20, 13, 6, 1, "T")
    elif goods == "seeds":  # the seed merchant's: packets in rows
        for x in range(5, 28, 4):
            c.rect(x, 12, 3, 4, "p"); c.px(x + 1, 13, "c")
    elif goods == "cloth":
        for x, tone in ((5, "V"), (12, "s"), (19, "y")):
            c.rect(x, 12, 6, 4, tone); c.rect(x, 12, 6, 1, "p")
    else:  # empty crates
        for x in (6, 18):
            c.rect(x, 12, 8, 4, "2"); c.rect(x, 12, 8, 1, "s")
    return c.outline()


def rostrum():
    c = Canvas(34, 28)
    planks(c, 3, 2, 28, 16, tones=("1", "2", "s"), across=False, gap=5)
    c.rect(3, 2, 28, 2, "S")
    c.rect(10, 6, 14, 6, "1")  # the desk's front panel
    c.rect(15, 0, 4, 3, "y")  # the gavel block
    for j in range(3):
        c.rect(1 + j * 2, 18 + j * 3, 32 - j * 4, 3, "s" if j % 2 else "2")
    return c.outline()


def gravestone(kind, mossed):
    c = Canvas(14, 20)
    if kind == 0:  # round-headed
        c.rect(2, 6, 10, 12, "T"); c.ellipse(6.5, 6, 5, 5, "T"); c.rect(10, 6, 2, 12, "S")
    elif kind == 1:  # square, leaning
        c.poly([(3, 2), (12, 3), (11, 18), (2, 18)], "T"); c.line(12, 3, 11, 18, "S")
    else:  # a low slab
        c.rect(1, 10, 12, 8, "T"); c.rect(1, 10, 12, 2, "p"); c.rect(11, 12, 2, 6, "S")
    c.rect(4, 8 if kind < 2 else 13, 6, 1, "s")  # worn lines where a name was
    c.rect(5, 11 if kind < 2 else 15, 4, 1, "s")
    c.rect(1, 17, 12, 2, "S")
    if mossed:
        for x, y in ((2, 4), (3, 3), (3, 5), (2, 9), (9, 15), (4, 2)):
            if c.get(x, y):
                c.px(x, y, "G"); c.px(x + 1, y, "m")
    return c.outline()


def barge():
    """The Marigold: tied up below the bridge, her hold open, her cabin locked."""
    c = Canvas(192, 52)
    c.poly([(8, 14), (176, 14), (190, 26), (176, 44), (8, 44), (1, 30)], "1")
    c.poly([(10, 12), (175, 12), (187, 24), (175, 40), (10, 40), (4, 28)], "2")
    c.poly([(14, 15), (172, 15), (181, 24), (172, 36), (14, 36), (9, 27)], "s")  # the deck
    for x in range(20, 170, 9):
        c.line(x, 16, x, 35, "2")
    c.rect(52, 18, 84, 16, "0")  # the open hold
    c.rect(54, 20, 80, 12, "1")
    for x in range(58, 130, 14):
        c.rect(x, 22, 10, 7, "y"); c.rect(x, 22, 10, 1, "p")  # sacks never unloaded
    planks(c, 18, 14, 26, 20, tones=("1", "2", "S"), gap=5)  # the cabin
    c.rect(18, 12, 26, 3, "S")
    c.rect(28, 22, 6, 10, "0"); c.px(32, 27, "a")  # its door, and the one warm thing: a brass padlock
    c.rect(22, 18, 4, 4, "0"); c.rect(36, 18, 4, 4, "0")
    c.rect(150, 20, 3, 12, "y")  # the tiller
    c.rect(100, 40, 34, 2, "V")  # her name board, the paint gone violet-grey
    c.line(170, 14, 180, 2, "y"); c.line(24, 14, 14, 2, "y")  # mooring ropes
    return c.outline()


def bridge_parts():
    deck = Canvas(T, T, "s")
    for y in range(3, T, 4):
        deck.rect(0, y, T, 1, "2")
    for x, y in ((3, 1), (11, 5), (6, 9), (13, 13)):
        deck.px(x, y, "S")
    rail_l, rail_r = deck.crop(0, 0, T, T), deck.crop(0, 0, T, T)
    rail_l.rect(0, 0, 3, T, "1"); rail_l.rect(1, 0, 1, T, "S")
    rail_r.rect(T - 3, 0, 3, T, "1"); rail_r.rect(T - 2, 0, 1, T, "S")
    raised = Canvas(64, 44)  # one leaf standing on end: its underside
    raised.rect(1, 1, 62, 42, "1")
    for x in range(8, 60, 12):
        raised.rect(x, 1, 3, 42, "2")
    for y in (8, 24, 38):
        raised.rect(1, y, 62, 2, "0")
    raised.rect(1, 1, 62, 2, "s")
    return deck, rail_l, rail_r, raised.outline()


def notice_board():
    c = Canvas(24, 24)
    for x in (3, 19):
        c.rect(x, 4, 2, 20, "2")
    c.rect(1, 2, 22, 14, "s"); c.rect(1, 1, 22, 2, "1")
    c.rect(3, 4, 7, 9, "P"); c.rect(12, 5, 8, 6, "p")  # notices, one newer than the other
    c.rect(4, 6, 5, 1, "s"); c.rect(4, 8, 4, 1, "s"); c.rect(13, 7, 5, 1, "s")
    return c.outline()


def build():
    made = []

    def keep(rel, c, **meta):
        made.append((rel.split("/")[-1], out("props/" + rel, c, **meta)))

    keep("farm/chest", strip([chest(False), chest(True)]), frame=(16, 15), layout="closed open")
    keep("farm/mailbox", mailbox())
    keep("farm/bench", bench())
    keep("farm/porch_lamp", strip([lamp(False), lamp(True)]), frame=(10, 22), layout="unlit lit")
    keep("farm/shelter_ruined", shelter())
    for kind in ("catmint", "radish"):
        keep("farm/crop_" + kind, strip([crop(kind, s) for s in range(4)] + [crop(kind, 3, True)]), frame=(T, T),
             layout="sown sprout growing ready withered")
    keep("farm/cat_blanket", small(["..aaaaaaaaaaaa..", ".aohaohaohaohao.", ".ahoahoahoahoah.", ".aohaohaohaohao.", "..aaaaaaaaaaaa.."]))
    keep("house/bed", bed())
    keep("house/stove", strip([stove(None), stove(0), stove(1)]), frame=(18, 26), layout="cold lit_a lit_b",
         anims={"burn": {"row": 0, "start": 1, "frames": 2, "fps": 4, "loop": True}})
    keep("house/table", table())
    keep("house/chair", chair())
    keep("house/cupboard", cupboard())
    keep("house/rug", rug())
    keep("house/candle", strip([candle(0), candle(1)]), frame=(6, 11), anims={"burn": {"row": 0, "frames": 2, "fps": 4, "loop": True}})
    keep("house/seed_tin", small(["SSSSSSSS", "TcTTTTTS", "TCcTTTTs", "TTTTTTTs", "TTTTTTTs", "ssssssss"]))
    keep("house/basket", small(["..bbbbbb..", ".b......b.", "oaoaoaoaoa", "aoaoaoaoao", ".oaoaoaoa.", "..bbbbbb.."]))
    keep("house/cup", small([".PPP.", "PwwPP", "PPPP.", ".PP.."]))
    keep("house/window_seat", small(["oooooooooooooooooooooooooooooooo", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "ahhhhhhhaahhhhhhhhaahhhhhhhhhhha",
                                     "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", "boobboobboobboobboobboobboobboob",
                                     "boobboobboobboobboobboobboobboob", "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"]))
    keep("world/well", well())
    keep("world/signpost", signpost())
    keep("world/hive", hive())
    keep("world/lamp_post", strip([lamp(False, "1", 30), lamp(True, "1", 30)]), frame=(10, 30), layout="unlit lit")
    keep("world/notice_board", notice_board())
    keep("world/note", strip([small(["PPPPPP.", "PssssP.", "PPPPPPp", "PsssPPp", "PPPPPPp", ".pppppp"]),
                              small(["PPPPPPh", "PssssPh", "PPPPPPp", "PsssPPp", "PPPPPPp", "hpppppp"])]), frame=(9, 8),
         anims={"glint": {"row": 0, "frames": 2, "fps": 2, "loop": True}})
    keep("millbrook/sluice", strip([sluice(f) for f in range(4)]), frame=(18, 22),
         anims={"turn": {"row": 0, "frames": 4, "fps": 8, "loop": True}})
    keep("millbrook/crank", small(["SS......", "sSSSSSS.", "......SS", "......aS", "......aa"]))
    keep("millbrook/millstone", strip([millstone(True), millstone(False)]), frame=(22, 16), layout="leaning flat")
    keep("millbrook/sacks", sacks())
    keep("millbrook/trough", trough())
    keep("millbrook/wallow", wallow())
    keep("millbrook/sheaf", sheaf())
    keep("millbrook/fungus", strip([fungus(0), fungus(1)]), frame=(10, 9), anims={"glow": {"row": 0, "frames": 2, "fps": 1, "loop": True}})
    keep("millbrook/grist_heart", small([".VV.VV.", "VyVVVVV", "VVVVVVv", ".VVVVv.", "..VVv..", "...v..."]))
    keep("millbrook/footbridge", strip(bridge_parts()[:3]), frame=(T, T), layout="deck rail_left rail_right")
    for name, awning, goods in (("eggs", "pa", "eggs"), ("seeds", "pG", "seeds"), ("cloth", "pV", "cloth"), ("empty", "ps", None)):
        keep("kettlebridge/stall_" + name, stall(awning, goods))
    keep("kettlebridge/rostrum", rostrum())
    keep("kettlebridge/gravestones", strip([gravestone(k, m) for k in range(3) for m in (False, True)]), frame=(14, 20),
         layout="round round_mossed square square_mossed slab slab_mossed")
    keep("kettlebridge/barge", barge())
    parts = bridge_parts()
    keep("kettlebridge/bridge_deck", strip(parts[:3]), frame=(T, T), layout="deck rail_left rail_right")
    keep("kettlebridge/bridge_leaf_raised", parts[3])
    keep("kettlebridge/winch_key", small(["aa....", "a.aaaa", "aa..a."]))
    keep("kettlebridge/padlock", small([".SS.", "S..S", "aaaa", "a0aa", "aaaa"]))
    keep("kettlebridge/vase_dead", small(["y.y.y", ".yyy.", "..y..", ".SSS.", ".STS.", ".SSS."]))
    return made
