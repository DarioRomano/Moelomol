"""Layout sketches for the farm estate, its homestead and Millbrook
(docs/design/base.md, area-millbrook.md): ASCII maps and PNGs. The homestead
and Millbrook use one character per 2 x 2 tiles; the estate one per 4 x 4.

Run from this folder: python3 make_sketches.py && python3 make_screen_views.py
It writes base.png, millbrook.png (and base.txt, millbrook.txt, whose text is
pasted into the design docs). Needs Pillow. Documentation only: docs/ has a
.gdignore, so Godot never imports these images, and exports exclude docs/.
"""
from PIL import Image, ImageDraw, ImageFont
import random

BASE = """\
#######GG###############
#,,....=.HHHHH...~~~~.,#
#.BBB..=.HHHHHA.~~~~~,,#
#.BBB..=.HHDHH..~~~~~,,#
#.BbB..=...=L...~~~~.f,#
#.s============.n.ff.f,#
#,,,:::TTTT=::::.fffff,#
#C,,:::TTTT=::::.ffoff,#
#PPP:::TTTT=::::.fffff,#
#PPP:::::::=::::..fff,,#
#PPP:::::::=::::...ff,,#
#,,,:::::::============G
G===========.....,,,,,,#
#,,,,,,....=m....,,,,,,#
###########GG###########"""

W, H = 56, 32
g = [['.'] * W for _ in range(H)]

def put(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = c

def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, c)

def line(points, c, width=1):
    for (xa, ya), (xb, yb) in zip(points, points[1:]):
        n = max(abs(xb - xa), abs(yb - ya))
        for i in range(n + 1):
            x = round(xa + (xb - xa) * i / n)
            y = round(ya + (yb - ya) * i / n)
            for dx in range(width):
                put(x + dx, y, c)

random.seed(7)
# Woods round the edge, ragged.
for x in range(W):
    for y in range(H):
        edge = min(x, y, W - 1 - x, H - 1 - y)
        if edge == 0 or (edge == 1 and random.random() < 0.55):
            g[y][x] = 't'
# Orchard (west): apple trees in rows.
rect(2, 3, 11, 17, '.')
for y in range(4, 18, 2):
    for x in range(3, 11, 2):
        put(x, y, 'a')
rect(4, 11, 6, 12, 'P')            # cider press shed
# Wheat field, half harvested (south-west).
rect(2, 20, 11, 28, 'y')
rect(2, 20, 6, 28, 'u')
line([(2, 19), (12, 19), (12, 29)], 'h')
put(7, 19, '.')                    # a gap in the hedge: the way into the field (fix, 2026-10-11)
# The flooded lower meadow (south).
rect(13, 22, 42, 28, 'w')
for x in range(13, 43):
    if random.random() < 0.5: put(x, 21, 'w')
    if random.random() < 0.5: put(x, 29, 'w')
# Changed land beyond the ford (south edge).
rect(14, 30, 41, 30, 'v')
for x in range(16, 40):
    if random.random() < 0.4 and g[29][x] != 'w': put(x, 29, 'v')
# Brook, millpond, race.
line([(55, 7), (50, 8), (47, 9)], '~', 2)
rect(42, 9, 51, 16, '~')
put(48, 12, 'i'); put(49, 12, 'i')  # island
line([(42, 18), (42, 19), (41, 21), (40, 22)], '~', 2)
# The race runs on south as the brook, past the yard to the map's edge, so the
# flooded meadow is the only way to the ford (fix, 2026-10-11).
line([(42, 22), (42, 31)], '~', 2)
# Mill and sluice.
rect(38, 16, 41, 18, 'M')
put(42, 17, 'X')
# Miller's yard and cottage (east, across the race).
rect(45, 19, 53, 26, '.')
line([(45, 19), (53, 19), (53, 26), (45, 26), (45, 19)], '#')
put(45, 21, '.')                   # yard gate
rect(48, 20, 50, 21, 'H')
# Beekeeper's hives and hut (north-east).
rect(41, 3, 42, 4, 'H')
for (x, y) in [(45, 3), (47, 3), (49, 3), (46, 5), (48, 5), (50, 5)]:
    put(x, y, 'e')
# The lane from the farm (north) down to the green, between hedges.
lane = [(27, 0), (27, 2), (29, 4), (29, 6), (27, 8), (27, 10)]
line(lane, '=', 2)
for y in range(1, 9):
    xs = [x for x in range(W) if g[y][x] == '=']
    if xs:
        put(min(xs) - 1, y, 'h'); put(max(xs) + 1, y, 'h')
# Village green (lighter grass), well, cottages, gardens.
rect(20, 10, 35, 17, '.')
rect(21, 11, 33, 16, ',')
put(27, 13, 'W')
for (x0, y0) in [(17, 9), (32, 8), (36, 12), (17, 15), (23, 18)]:
    rect(x0, y0, x0 + 2, y0 + 1, 'H')
rect(14, 14, 16, 17, 'g')          # garden behind cottage 4
put(15, 18, 'c')                   # the hen coop
rect(37, 14, 39, 15, 'g')          # garden of cottage 3
rect(35, 2, 38, 5, 'K')            # chapel
rect(13, 3, 16, 5, 'S')            # school
# Roads and paths.
line([(27, 10), (27, 21)], '=', 2)            # old south road, into the flood
line([(27, 29), (27, 31)], '=', 2)            # ...and out to the ford
line([(20, 12), (14, 12), (14, 6)], '=')      # west to the orchard and up to the school
line([(12, 12), (13, 12)], '=')
line([(35, 16), (37, 17)], '=')               # east to the mill
line([(31, 10), (34, 7), (36, 6)], '=')       # up to the chapel
line([(37, 6), (40, 5), (42, 5)], '=')        # on to the hives
line([(38, 19), (40, 20)], '=')               # mill to the footbridge
put(41, 20, 'b'); put(42, 20, 'b'); put(43, 20, 'b')
line([(44, 20), (45, 21)], '=')               # footbridge to the yard gate
put(29, 19, 's')                              # signpost into the water
# Night lights: glowing fungus in the orchard.
for (x, y) in [(5, 6), (9, 14), (3, 16), (9, 4)]:
    put(x, y, '*')

MARKERS = {
    '1': (28, 1), '2': (31, 5), '3': (25, 13), '4': (17, 4), '5': (13, 15),
    '6': (14, 18), '7': (39, 3), '8': (30, 19), '9': (37, 18), 'A': (42, 21),
    'B': (51, 22), 'C': (7, 12), 'D': (8, 24), 'E': (47, 13), 'F': (29, 30),
    'G': (47, 7),
}
for k, (x, y) in MARKERS.items():
    put(x, y, k)

MILLBROOK = '\n'.join(''.join(r) for r in g)

COL = {
    't': '#2f3b2e', '#': '#7a4a2b', '.': '#6b7a57', ',': '#94a07a', '=': '#a9a07c', 'H': '#b8733a',
    'D': '#f3d58a', 'B': '#7a4a2b', 'b': '#a97a4f', 'T': '#5c3d22', ':': '#8a8a5c', '~': '#4f8296',
    'P': '#8f8a6a', 'C': '#8f8a6a', 'A': '#5f8f3e', 'n': '#e0a95b', 'm': '#e0a95b', 'G': '#f3d58a',
    'L': '#f3d58a', 's': '#e0a95b', 'f': '#a4ad7a', 'o': '#7d869a', 'a': '#47573f', 'y': '#c9b56a',
    'u': '#a59a6b', 'h': '#3f4f38', 'w': '#5f8a96', 'v': '#6e5b73', 'M': '#7d869a', 'X': '#d9d6cc',
    'i': '#47573f', 'W': '#a9b0bf', 'g': '#5f8f3e', 'c': '#b8733a', 'K': '#a9b0bf', 'S': '#7d869a',
    '*': '#c9a0dc', 'e': '#e0a95b',
}

EW, EH = 40, 24
e = [['x'] * EW for _ in range(EH)]

def erect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < EW and 0 <= y < EH:
                e[y][x] = c

# The estate's outer hedge and the woods beyond it.
erect(0, 0, 39, 0, 't'); erect(0, 0, 0, 23, 't'); erect(39, 0, 39, 23, 't')
# Parcels (all overgrown at the start); the digit is the order they open.
erect(1, 1, 9, 11, '5')     # north woods and the spring
erect(10, 1, 29, 4, '6')    # the hill and the old windmill
erect(10, 5, 29, 12, '1')   # the great fields
erect(30, 1, 38, 11, '4')   # walled garden and glasshouse
erect(1, 12, 13, 22, '3')   # the old orchard
erect(26, 12, 38, 22, '2')  # east pasture and the big barn
# The homestead (open from the start), bottom centre: 48 x 32 tiles.
erect(14, 15, 25, 22, 'h')
erect(14, 13, 25, 14, '1')
# Old track from the homestead's north gate up through the great fields.
for y in range(5, 15):
    e[y][17] = "-"
erect(0, 23, 39, 23, 't')
e[23][19] = 'G'; e[23][20] = 'G'
ESTATE = '\n'.join(''.join(r) for r in e)
ESTATE_COL = {'t': '#2f3b2e', 'x': '#2f3b2e', 'h': '#8cbf4a', '-': '#4a3f2e', 'G': '#f3d58a',
              '5': '#34452f', '6': '#5a5a40', '1': '#4c5536', '4': '#4a4f52', '3': '#3d4a30', '2': '#535a38'}
ESTATE_LABELS = {
    'Homestead (open)': (19.5, 18.5), '5 North woods\nand the spring': (5, 6), '6 The hill and\nthe windmill': (19.5, 2.4),
    '1 The great fields': (24, 8.5), '4 Walled garden\nand glasshouse': (34, 6), '3 The old orchard': (7, 17),
    '2 East pasture\nand the big barn': (32, 17), 'to Millbrook': (19.5, 24.6),
}


def render_estate(path):
    cell = 24
    pad = 28
    img = Image.new('RGB', (EW * cell, EH * cell + pad + 26), '#1b1e2b')
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 15)
    tf = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 16)
    rnd = random.Random(3)
    for y, r in enumerate(e):
        for x, c in enumerate(r):
            colour = ESTATE_COL[c]
            d.rectangle([x * cell, y * cell + pad, (x + 1) * cell - 1, (y + 1) * cell - 1 + pad], fill=colour)
            if c in '123456':
                # Thicket texture: darker tufts.
                for i in range(3):
                    tx, ty = x * cell + rnd.randrange(cell - 6), y * cell + pad + rnd.randrange(cell - 6)
                    d.rectangle([tx, ty, tx + 5, ty + 5], fill='#26301f')
    # Borders wherever two neighbouring squares belong to different parcels.
    for y in range(EH):
        for x in range(EW):
            c = e[y][x]
            if x + 1 < EW and e[y][x + 1] != c:
                xx = (x + 1) * cell
                d.line([xx, y * cell + pad, xx, (y + 1) * cell + pad], fill='#f3d58a' if 'h' in (c, e[y][x + 1]) else '#94a07a', width=2)
            if y + 1 < EH and e[y + 1][x] != c:
                yy = (y + 1) * cell + pad
                d.line([x * cell, yy, (x + 1) * cell, yy], fill='#f3d58a' if 'h' in (c, e[y + 1][x]) else '#94a07a', width=2)
    for text, (x, y) in ESTATE_LABELS.items():
        d.multiline_text((x * cell, y * cell + pad), text, fill='#f0ece1' if 'Homestead' not in text else '#1b1e2b',
                         font=f, anchor='mm', align='center')
    d.text((6, 5), 'The farm (proposal): 160 x 96 tiles; one square = 4 x 4 tiles; dark = overgrown; numbers = order they open',
           fill='#f0ece1', font=tf)
    img.save(path)


BASE_MARKERS = {
    '1': (10, 2), '2': (3, 2), '3': (8, 7), '4': (5, 10), '5': (2, 9), '6': (18, 3),
    '7': (14, 1), '8': (19, 9), '9': (13, 13), 'A': (11, 13), 'B': (13, 4), 'C': (1, 5),
    'N': (7, 1), 'W': (1, 12), 'E': (22, 11),
}


def render(text, cell, path, title, labels, overlay=None):
    rows = text.split('\n')
    w, h = len(rows[0]), len(rows)
    pad = 28
    img = Image.new('RGB', (w * cell, h * cell + pad), '#1b1e2b')
    d = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', min(16, max(10, cell - 4)))
        tfont = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 16)
    except OSError:
        font = tfont = ImageFont.load_default()
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            colour = COL.get(c, '#1b1e2b' if c not in labels else '#6b7a57')
            d.rectangle([x * cell, y * cell + pad, (x + 1) * cell - 1, (y + 1) * cell - 1 + pad], fill=colour)
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c in labels:
                cx, cy = x * cell + cell // 2, y * cell + cell // 2 + pad
                d.ellipse([cx - cell * 0.6, cy - cell * 0.6, cx + cell * 0.6, cy + cell * 0.6], fill='#f0ece1', outline='#1b1e2b')
                d.text((cx, cy), c, fill='#1b1e2b', font=font, anchor='mm')
    for c, (x, y) in (overlay or {}).items():
        cx, cy = x * cell + cell // 2, y * cell + cell // 2 + pad
        d.ellipse([cx - cell * 0.38, cy - cell * 0.38, cx + cell * 0.38, cy + cell * 0.38], fill='#f0ece1', outline='#1b1e2b')
        d.text((cx, cy), c, fill='#1b1e2b', font=font, anchor='mm')
    d.text((6, 5), title, fill='#f0ece1', font=tfont)
    img.save(path)

if __name__ == '__main__':
    render(BASE, 32, 'base.png', 'The homestead (proposal): 48 x 30 tiles; one square = 2 x 2 tiles', set(), BASE_MARKERS)
    render_estate('estate.png')
    render(MILLBROOK, 20, 'millbrook.png', 'Millbrook (proposal): 112 x 64 tiles; one square = 2 x 2 tiles', set(MARKERS))
    open('base.txt', 'w').write(BASE + '\n')
    open('estate.txt', 'w').write(ESTATE + '\n')
    open('millbrook.txt', 'w').write(MILLBROOK + '\n')
    for r in BASE.split('\n'): assert len(r) == 24, r
    print(MILLBROOK)
