"""Layout sketch for the second area, Kettlebridge, the market town on the
river (docs/design/area-kettlebridge.md; Q43 A): ASCII map and PNG, one
character per 2 x 2 tiles, like Millbrook's.

Run from this folder: python3 make_kettlebridge.py
It writes kettlebridge.png and kettlebridge.txt (whose text is pasted into
the design doc), and walks the map breadth-first (CLAUDE.md: walk the map):
every place can be reached from the road in, the bridge is the only way
south, and the island cannot be reached. Documentation only (docs/ has a
.gdignore). Needs Pillow.
"""
import random
from collections import deque

from make_sketches import COL, render

W, H = 64, 36
g = [['.'] * W for _ in range(H)]


def put(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = c


def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, c)


random.seed(11)
# Woods round the edge, ragged; the river runs out of both sides.
for x in range(W):
    for y in range(H):
        edge = min(x, y, W - 1 - x, H - 1 - y)
        if edge == 0 or (edge == 1 and random.random() < 0.5):
            g[y][x] = 't'
# The road in from Millbrook's ford (north), through fields going violet.
rect(1, 1, 62, 6, ',')
for x in range(1, 63):
    for y in range(1, 7):
        if random.random() < 0.35:
            put(x, y, 'v')
for x in [14, 15, 48, 49]:
    rect(x, 1, x, 6, 'h')
put(14, 4, ','); put(15, 4, ','); put(48, 3, ','); put(49, 3, ',')  # gaps in the field hedges
rect(31, 0, 32, 8, '=')
# The town: streets.
rect(2, 8, 61, 8, '=')                      # the back lane along the town's top
rect(31, 8, 32, 22, '=')                    # the high street down to the bridge
rect(2, 22, 61, 22, '=')                    # the towpath along the river
rect(42, 8, 43, 22, '=')                    # Church Lane
rect(19, 8, 20, 22, '=')                    # Drovers' Lane
# The market square, cobbled, with its stalls.
rect(23, 11, 40, 18, '_')
for x in range(25, 39, 3):
    put(x, 13, 'k'); put(x, 16, 'k')        # empty market stalls
rect(23, 11, 30, 11, '_')
# Buildings round the square.
rect(23, 9, 29, 10, 'H'); rect(34, 9, 40, 10, 'H')     # north side
rect(21, 11, 22, 13, 'H')                               # the chandler's (west side)
rect(21, 15, 22, 21, 'H')                               # the coaching inn (west side)
rect(34, 19, 40, 20, 'H')                               # the corn exchange (south side)
rect(23, 19, 29, 21, 'H')                               # the bridge-keeper's and the toll house
# The drovers' pens and the auction ring (west).
rect(2, 9, 17, 21, ',')
rect(3, 10, 17, 21, '#')
rect(4, 11, 16, 20, 'O')                                # the ring's sawdust
put(10, 15, 'R'); put(11, 15, 'R')                      # the auctioneer's rostrum
put(17, 15, '.'); put(17, 16, '.')                      # the ring's gate, to the inn yard
rect(18, 15, 18, 18, ',')                               # the inn yard
# The church and its churchyard (east).
rect(45, 9, 50, 13, 'K')
rect(44, 14, 55, 20, 'q')
for x in range(45, 55, 2):
    for y in range(15, 20, 2):
        put(x, y, '+')                                  # gravestones
rect(44, 21, 55, 21, '#'); put(49, 21, '.')             # the churchyard wall, its gate
rect(56, 14, 56, 21, '#')
# Almshouses and cottages (east).
rect(52, 9, 60, 11, 'H')
rect(57, 15, 60, 20, 'H')
# The river, the raised bridge, the winch house, the wharf and the barge.
rect(0, 23, 63, 28, '~')
rect(31, 23, 32, 28, 'Y')                               # the bridge, drawn up
rect(34, 21, 35, 21, 'Z')                               # the winch house
rect(44, 24, 49, 25, 'n')                               # the moored barge
rect(10, 25, 13, 26, 'i')                               # the island
# Beyond the river: the changed land, and the road on south.
rect(1, 29, 62, 34, 'v')
for x in range(1, 63):
    for y in range(29, 35):
        if random.random() < 0.25:
            put(x, y, ',')
rect(31, 29, 32, 35, '=')
# Places, numbered as in the design doc.
MARKERS = {
    '1': (33, 3),   # the milestone: "Kettlebridge 1 mile"
    '2': (30, 9),   # the top of the high street, the notice board
    '3': (28, 14),  # Arthur's egg stall: the key in the cash tin
    '4': (23, 12),  # the chandler's: the lantern
    '5': (23, 17),  # the coaching inn: the traveller's diary
    '6': (18, 16),  # the inn yard and the ring's gate
    '7': (10, 12),  # the auction ring: Duke
    '8': (30, 22),  # the bridge-keeper's door, by the toll house
    '9': (36, 22),  # the winch house's door
    'A': (33, 22),  # the foot of the raised bridge
    'B': (46, 22),  # the wharf and the barge
    'C': (44, 12),  # the church door; the carving
    'D': (50, 18),  # the churchyard
    'E': (55, 12),  # the almshouses
    'F': (12, 22),  # the towpath where the island is seen
    'G': (34, 18),  # the seed merchant's stall
}
for c, (x, y) in MARKERS.items():
    put(x, y, c)
KETTLEBRIDGE = '\n'.join(''.join(r) for r in g)

# Walkable: everything but woods, buildings, walls, water and the raised
# bridge; the stalls and gravestones are things to walk round.
SOLID = set('tHK#~YZnihk+R')


def walk(start, solid):
    seen = {start}
    queue = deque([start])
    while queue:
        x, y = queue.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in seen and g[ny][nx] not in solid:
                seen.add((nx, ny))
                queue.append((nx, ny))
    return seen


def check():
    entrance = (31, 0)
    seen = walk(entrance, SOLID)
    for c, (x, y) in MARKERS.items():
        if c == 'F':
            assert (11, 25) not in seen, 'the island cannot be reached'
        assert (x, y) in seen, f'place {c} cannot be reached'
    assert not any(y >= 29 for (x, y) in seen), 'south of the river, before the bridge is down'
    lowered = walk(entrance, SOLID - {'Y'})
    assert (31, 35) in lowered, 'the bridge down: the road south'
    assert {(17, 15), (17, 16)} <= seen, 'the ring has a gate'
    fields = [(x, y) for y in range(1, 7) for x in range(1, 63) if g[y][x] in ',v']
    assert all(f in seen for f in fields), 'every field beside the road can be reached'
    print('walk: every place reached; the river crossed only by the bridge; the island out of reach')


if __name__ == '__main__':
    check()
    col = dict(COL)
    col.update({'_': '#b9ad8c', 'k': '#8a6a4a', 'O': '#c9a26a', 'R': '#5c3d22', 'q': '#55704a', '+': '#a9b0bf',
                'Y': '#7a4a2b', 'Z': '#a9b0bf', 'n': '#5c3d22', 'K': '#a9b0bf'})
    import make_sketches
    make_sketches.COL.update(col)
    render(KETTLEBRIDGE, 20, 'kettlebridge.png', 'Kettlebridge (proposal): 128 x 72 tiles; one square = 2 x 2 tiles', set(MARKERS))
    open('kettlebridge.txt', 'w').write(KETTLEBRIDGE + '\n')
    print(KETTLEBRIDGE)
