from PIL import Image, ImageDraw, ImageFont
from make_sketches import BASE, COL
T = 10  # px per tile
SW, SH = 84, 36  # scenery canvas in tiles
ox, oy = (SW - 48) // 2, 3  # where the 48 x 30 base sits
img = Image.new('RGB', (SW * T, SH * T + 60), '#1b1e2b')
d = ImageDraw.Draw(img)
f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
# Scenery beyond the fence: wild fields and woods (not walkable).
for y in range(SH):
    for x in range(SW):
        c = '#47573f' if (x * 7 + y * 3) % 11 < 6 else '#3f4f38'
        if y < 3: c = '#2f3b2e'
        d.rectangle([x * T, y * T + 30, x * T + T - 1, y * T + T - 1 + 30], fill=c)
rows = BASE.split('\n')
for cy, r in enumerate(rows):
    for cx, ch in enumerate(r):
        for dy in range(2):
            for dx in range(2):
                x, y = ox + cx * 2 + dx, oy + cy * 2 + dy
                d.rectangle([x * T, y * T + 30, x * T + T - 1, y * T + T - 1 + 30], fill=COL[ch])
# The lane continues south out of the gate.
for y in range(oy + 30, SH):
    for x in (ox + 22, ox + 23, ox + 24, ox + 25):
        d.rectangle([x * T, y * T + 30, x * T + T - 1, y * T + T - 1 + 30], fill='#a9a07c')
# Views centred on the house door (base tile 22, 7).
cx, cy = ox + 23, oy + 12
views = [(80, 22.5, '#c2584a', '32:9: 80 x 22.5 tiles'), (53.3, 22.5, '#e0a95b', '21:9: 53 x 22.5'),
         (40, 30, '#4f8296', '4:3 (1024x768): 40 x 30'), (40, 22.5, '#f0ece1', '16:9: 40 x 22.5')]
for i, (w, h, colour, name) in enumerate(views):
    x0, y0 = (cx - w / 2) * T, (cy - h / 2) * T + 30
    if w == 40 and h == 30:
        x0, y0 = (cx - w / 2) * T - 3, oy * T + 30 - 3
        w += 0.6; h += 0.6
    d.rectangle([x0, y0, x0 + w * T, y0 + h * T], outline=colour, width=3 if h < 30 and w == 40 else 2)
    lx = 6 + i * 205
    d.rectangle([lx, SH * T + 40, lx + 14, SH * T + 52], outline=colour, width=3)
    d.text((lx + 20, SH * T + 38), name, fill=colour, font=f)
d.text((6, 6), 'The homestead on each screen shape, camera on the house (tiles); beyond its hedges, the overgrown farm', fill='#f0ece1', font=f)
img.save('base_views.png')
