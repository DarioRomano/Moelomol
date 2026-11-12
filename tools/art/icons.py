"""Icons: 16 x 16 for things carried or cast, 8 x 8 for status effects
(combat-art-prompts.md A-01 to A-10). Each must read as a silhouette."""
from px import Canvas, from_art, strip
from lib import out

SHEET_SCALE = 4


def icon(rows=None, draw=None):
    c = Canvas(16, 16)
    if rows:
        c.art(8 - max(len(r) for r in rows) // 2, 8 - len(rows) // 2, rows)
    if draw:
        draw(c)
    return c.outline()


def greatsword(c):
    c.line(2, 13, 4, 11, "b", 2)
    c.line(3, 9, 7, 13, "s", 1)
    c.line(5, 10, 12, 3, "S", 3)
    c.line(5, 10, 13, 2, "T", 2)
    c.line(6, 9, 13, 2, "P")


def hammer(c):
    c.line(2, 13, 9, 6, "b", 2)
    c.line(2, 13, 8, 7, "o")
    c.rect(7, 2, 7, 6, "o"); c.rect(7, 2, 7, 1, "a"); c.rect(7, 7, 7, 1, "b")
    c.rect(8, 2, 1, 6, "s"); c.rect(12, 2, 1, 6, "s")


def bow(c):
    for k in range(-6, 7):
        t = k / 6.0
        x, y = 8 + k * 0.7 + (1 - t * t) * 3, 8 + k * 0.7 - (1 - t * t) * 3
        c.px(x, y, "o"); c.px(x - 1, y + 1, "b") if abs(k) < 5 else None
    c.line(4, 4, 12, 12, "p")


def lantern(c):
    c.ring(8, 3.5, 2.5, "S", 1.3)
    c.rect(4, 5, 8, 9, "s"); c.rect(5, 6, 6, 7, "V"); c.rect(7, 6, 2, 5, "P"); c.px(6, 11, "v"); c.px(9, 10, "y")
    c.rect(3, 5, 10, 1, "S"); c.rect(3, 13, 10, 1, "S"); c.rect(7, 6, 0, 0, "s")


def arrow(tip, bud=False):
    def draw(c):
        c.line(3, 12, 11, 4, "y")
        c.px(2, 12, "T"); c.px(3, 13, "T"); c.px(2, 13, "p")
        c.rect(11, 2, 3, 3, tip); c.px(13, 2, "P" if tip != "V" else "y")
        if bud:
            c.px(10, 2, "G"); c.px(14, 5, "G")
    return draw


def packet(mark):
    def draw(c):
        c.rect(3, 2, 10, 12, "p"); c.rect(3, 2, 10, 2, "P"); c.rect(3, 13, 10, 1, "y")
        c.art(5, 5, mark)
    return draw


ART = {
    "catmint": ["...V..V...", "..PV.VP...", "...V..V.V.", "..CcC.cCV.", "...c.Cc.c.", "..CcCc.Cc.", "...ccCcc..", "....ccc...", "....bbb..."],
    "radish": ["...C..C...", "..CcC.cC..", "...cCcc...", "...RRRR...", "..RRPRRR..", "..RRRRRR..", "...RRRR...", "....Rr....", ".....r...."],
    "cat_treat": ["..........", "..oo...o..", ".oaaoooao.", "oacaaaaaoo", ".oaaacaao.", "..oo...o..", ".........."],
    "grey_pelt": [".s.ssss.s.", "sSSSSSSSSs", ".STSSSSTS.", ".SSSTSSSS.", "sSSSSSSTSs", ".SSTSSSSS.", "sSSSSSSSSs", ".s.s..s.s."],
    "tusk": [".......PP.", ".....PPPp.", "....PPPp..", "...PPPp...", "..PPPp....", ".PPPp.....", ".PPp......", "ypp......."],
    "grist_heart": ["..VV..VV..", ".VyVVVVVV.", "VVVVVVVVVv", "VVVVVVVVVv", ".VVVVVVVv.", "..VVVVVv..", "...VVVv...", "....Vv...."],
    "quills": ["........P.", ".....P.T2.", "....T2T2..", ".P.T2T2...", ".T2T22....", "..T22.....", ".T22......", "s2........"],
    "rook_feather": ["......11..", ".....1121.", "....11211.", "...11211..", "..11211...", ".11211....", ".121......", "s1........"],
    "jackdaw_feather": ["......ss..", ".....sS1s.", "....sS11s.", "...1S11s..", "..1S11s...", ".1S11.....", ".1S1......", "T1........"],
    "toad_slime": ["....M.....", "...mMm....", "..mMmmG...", ".mMmmmmG..", ".mmmmmmG..", ".GmmmmGG..", "..GGGGG...", ".........."],
    "wing_dust": ["..........", "....P.....", "..P..V.P..", "...PpP....", "..pPPPp...", ".pPPVPPp..", ".ppPPPpp..", ".........."],
    "straw": ["p.y.p.y...", ".ypyypy...", ".yypyyy...", "..bbbb....", "..ypyy....", ".ypyypy...", ".yypyypy..", "y.p.y.p.y."],
    "wheat_seed": ["....y.....", "...ypy....", "..y.y.y...", "...ypy....", "..y.y.y...", "...ypy....", "....G.....", "....G....."],
    "pike_scale": ["...GGGG...", "..GmmmmG..", ".GmWmmmmG.", ".GmmmmmmG.", ".GmmmmmmG.", "..GmmmmG..", "...GmmG...", "....GG...."],
    "lichen": ["..M..y....", ".GMG.yG...", "GMMMGGMG..", ".GMGyMMMG.", "..GyyGMG..", ".GMGyG.G..", "..G..G....", ".........."],
    "sluice_crank": ["SS........", "sSSSSSSS..", ".......SS.", ".......SS.", ".......aa.", ".......ao.", ".......aa."],
    "winch_key": [".aaa......", "a...a.....", "a...aaaaaa", "a...a..a.a", ".aaa...a.a"],
    "note": ["PPPPPPPP..", "PssssssPp.", "PPPPPPPPp.", "PsssssPPp.", "PPPPPPPPp.", "PssssPPPp.", "PPPPPPPPp.", ".pppppppp."],
    "satchel": ["...bbbb...", "..b....b..", ".oooooooo.", "oaaaaaaaao", "oaaahhaaao", "oooobboooo", "oaaaaaaaao", ".oooooooo."],
    "mana": ["....W.....", "...WPW....", "..WPPWW...", ".WPWWWWw..", ".WWWWWWw..", "..WWWWw...", "...Www....", "....w....."],
    "sun": ["....h.....", ".h..h..h..", "..haaah...", "..ahhha...", "hhahhhahh.", "..ahhha...", "..haaah...", ".h..h..h..", "....h....."],
    "moon": ["...TTT....", "..TPP.....", ".TPP......", ".TPP......", ".TPP......", ".TPPP...T.", "..TPPPPT..", "...TTTT..."],
    "spell_till": ["..........", ".b.b.b.b..", "obobobobo.", "..........", ".b.b.b.b..", "obobobobo.", "..........", ".b.b.b.b..", "obobobobo."],
    "spell_water": ["....W.....", "....W.....", "...WPW....", "..WPWWW...", ".WPWWWWW..", ".WWWWWWw..", ".WWWWWww..", "..Wwwww..."],
    "spell_rain": ["..TTTT....", ".TPPPPTT..", "TPPPPPPPT.", "TTTTTTTTT.", "..........", ".W..W..W..", "W..W..W...", "..W..W..W."],
    "spell_plant": ["..........", "..CC..CC..", ".CccC.cC..", "..Cc.cC...", "...ccc....", "....c.....", "..bbcbb...", ".bbbbbbb.."],
    "spell_harvest": ["....hhh...", "..hha.....", ".hha......", ".ha.......", ".ha.......", ".hha...b..", "..hhaab...", "....hhb..."],
    "spell_clear": ["h...C...h.", ".h.CcC.h..", "...CcC....", ".CCcccCC..", "..CcccC...", "...CcC....", ".h..c..h..", "h...b...h."],
}

STATUS = {
    "smoulder": ["...a....", "..aha...", "..ahha..", ".ahhhao.", ".aohhao.", ".oaoao..", "..ooo..."],
    "chill": ["...P....", ".P.P.P..", "..PWP...", "PPWPWPP.", "..PWP...", ".P.P.P..", "...P...."],
    "rot": ["....G...", "...Gv...", "...v....", "..vVv...", ".vVVVv..", ".vVVVv..", "..vvv..."],
    "frozen": ["TTTTTTT.", "T..P..T.", "T.PWP.T.", "TPWPWPT.", "T.PWP.T.", "T..P..T.", "TTTTTTT."],
}


def build():
    made = []

    def keep(name, c):
        made.append((name, out("icons/" + name, c)))

    for name, fn in (("greatsword", greatsword), ("hammer", hammer), ("bow", bow), ("lantern", lantern),
                     ("arrow", arrow("T")), ("arrow_ember", arrow("a")), ("arrow_frost", arrow("W")), ("arrow_rot", arrow("V", bud=True))):
        keep(name, icon(draw=fn))
    keep("catmint_seeds", icon(draw=packet(["..V...", ".cVc..", "..c...", "..c..."])))
    keep("radish_seeds", icon(draw=packet([".c.c..", "..c...", ".RRR..", "..R..."])))
    for name, rows in ART.items():
        keep(name, icon(rows))
    for name, rows in STATUS.items():
        made.append(("status_" + name, out("icons/status_" + name, from_art(rows).crop(0, 0, 8, 8))))
    pips = Canvas(16, 3)  # five stack pips: lit, then dim
    for i in range(5):
        pips.rect(i * 3, 0, 2, 2, "h" if i == 0 else "2")
    made.append(("stack_pips", out("icons/stack_pips", pips)))
    return made
