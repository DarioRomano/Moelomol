# Combat art prompts for AI image generation

- **Status:** First set, for the lead to run (2026-10-10). Art is provisioned
  by the lead (Q2); these prompts are the brief.
- **Covers:** everything in `combat.md`: the four weapons, their attack
  poses and effects, the three status effects and Release, and the combat
  HUD. Not covered: creatures (designed with each area's roster) and the base.
- **Follows:** `art-direction.md` (palette, warmth means life, traces not
  bodies, one art-pixel grid), ADR-0008 (640×360 layout, 16 px tiles, the
  player 16 × 24 art pixels).
- **Assumes Q18 = top-down ¾ view.** If the lead chooses side view, every
  in-game sprite prompt here must be regenerated (the concept prompts still
  apply). Prompts marked *depends on Q18* say so.
- **Cannot be judged by the engineer:** whether a result looks right is the
  lead's call. Each prompt says what to check.

## How to use these prompts

AI image tools are good at concepts and single images, and unreliable at exact
pixel sizes, exact palettes and consistent animation frames. So the workflow
has three steps:

1. **Concept first (C prompts).** Generate concept sheets at normal
   resolution to settle each weapon's look. These are reference only; they
   never ship.
2. **Assets (A prompts).** Generate pixel-art assets, ideally at 8× the
   target size (for example a 16 × 16 icon as 128 × 128), then:
   - downscale to the target size with nearest-neighbour (no smoothing);
   - map every colour to the nearest colour of the project palette;
   - clean up stray pixels by hand.
   The engineer can build a small script for the first two steps if wanted.
3. **Animation (F prompts).** Generators rarely keep a character identical
   across frames. Use them for **key poses** (the start, impact and end of
   an attack), then finish the in-between frames by hand or with a
   sprite-animation tool. Each F prompt lists the key poses needed.

If the tool accepts a reference image, give it the approved concept sheet
and the player sprite for every later prompt; that keeps the style
consistent.

## Delivery spec

| Asset type | Size (art pixels) | Layout |
|---|---|---|
| Inventory / HUD weapon icon | 16 × 16 | single image |
| Status effect icon | 8 × 8 | single image |
| Player combat frames | 48 × 48 per frame (player 16 × 24 centred, room for the weapon swing) | horizontal strip, one row per facing direction |
| Effects (slashes, shockwaves, spells) | 32 × 32 or 64 × 64 per frame (stated per prompt) | horizontal strip |
| HUD elements | stated per prompt | single image |

- **Format:** PNG with transparency, no background, no anti-aliasing (hard
  pixel edges), colours only from the project palette.
- **File names:** `cmb_<weapon>_<asset>_<variant>.png`, for example
  `cmb_hammer_icon_a.png`, `cmb_bow_draw_s.png` (s = facing south).
- **Source files** (`.aseprite`, `.psd`, `.kra`) go through Git LFS
  (ADR-0011); final PNGs are small and stay in plain git.
- **Facing directions** (*depends on Q18*): four (south, north, east; west is
  east mirrored). Eight is possible later.

## Licence and register

As for audio: before the first generated image is committed, the lead
confirms the tool's terms allow use in a sold game. Each file gets a row in
`asset-register.md`: prompt ID, tool and model/version, date, exact prompt,
seed if shown, licence terms, and whether it was edited by hand.

## Shared style anchor

Append this to every **A** and **F** prompt:

> Pixel art for a quiet, lonely 2D farming and adventure game. Top-down
> three-quarter view. Hard-edged pixels, no anti-aliasing, no gradients, no
> dithering noise, transparent background. Limited muted palette: cool
> desaturated greys, blues and mossy greens for the world; warm amber, honey
> and soft gold reserved for things that are alive and loved; muted violet
> only for the strange. Clean readable silhouette at very small size. Simple,
> handmade, slightly worn: the tools of someone who farms alone.

**Palette** (paste where the tool accepts colours): `#1b1e2b #2a2f40 #3d4459
#5a6377 #7d869a #a9b0bf #d9d6cc #f0ece1 #2f3b2e #47573f #6b7a57 #94a07a
#4a3f52 #6e5b73 #8f8a6a #2e5566 #4f8296 #7a4a2b #b8733a #e0a95b #f3d58a
#5f8f3e #8cbf4a #8c3b3b #c2584a #0e0f16 #ffffff`

Shared **Avoid** list for every prompt:

> photorealism, 3D render, smooth shading, gradients, glow bloom, lens
> flare, anime, chibi, cartoon outlines thicker than one pixel, bright
> saturated neon colours, text, logos, watermark, signature, background
> scenery (unless asked), blood, gore, corpses, skulls, heroic fantasy armour,
> glowing runes everywhere, epic poses

## Design rules every weapon follows

- **Each weapon was made, not found:** built by a farmer from tools and
  materials: a plough share, a fence-post maul, orchard wood, a lantern.
  Monster materials added through enhancement look grown-in (bark, shell,
  violet veins), not ornamental.
- **Warm = alive.** The player's weapons use the warm wood and iron tones of
  the base. Only magic glows in the "changed" violet (it is the god's
  influence; `combat.md`).
- **Readable at 16 px.** Each weapon must be recognisable as a silhouette:
  long blade, heavy head, curve, lantern.

---

## Greatsword

### C-01 Greatsword concept sheet (reference only, never shipped)

- **Prompt:** Concept art sheet of a farmer's greatsword forged from an old
  plough share: a long, heavy, single-edged blade, slightly curved, dark
  hammered iron with a worn bright edge, a long wooden grip wrapped in
  leather strips and twine, no crossguard or a simple iron bar. Shown from the
  side, front and back, plus two variants: one enhanced with grey stone
  plates grown into the spine of the blade, one with dark bark creeping up
  the grip. Muted, earthy colours, soft painterly style, plain light
  background, design notes as small sketches.
- **Avoid:** shared list, plus ornate filigree, gems, glowing blades.
- **Check for:** reads as heavy and homemade; a plough origin is visible; no
  "hero sword" glamour.

### A-01 Greatsword icon

- **Prompt:** A single pixel art icon of a heavy single-edged greatsword made
  from a plough share, dark iron blade with a bright worn edge, long wooden
  grip wrapped in leather, drawn diagonally from lower left to upper right,
  filling a square canvas. + style anchor
- **Spec:** 16 × 16 (generate at 128 × 128).
- **Check for:** recognisable as a big blade at 16 px; edge highlight is one
  pixel; colours from the palette.

### F-01 Greatsword light chain (key poses) — *depends on Q18*

- **Prompt:** Pixel art sprite sheet of a small farmer character (simple
  clothes, warm brown and amber tones, no armour) swinging a huge
  single-edged greatsword in a wide horizontal sweep, three swings in a
  chain: wind-up with the blade held back, the sweep with a short motion
  arc, the follow-through. Top-down three-quarter view, character facing
  south (towards the viewer). Frames in one row, same character size in every
  frame. + style anchor
- **Spec:** 48 × 48 per frame; key poses needed: wind-up, impact, follow-through
  for each of 3 swings (9 poses), for south, north and east.
- **Check for:** the blade looks heavy (body leans into it); character stays
  the same size and colours in every frame.

### F-02 Greatsword finishers (key poses) — *depends on Q18*

- **Prompt:** Pixel art sprite sheet of the same small farmer character with
  a huge greatsword performing four finishing moves, one per row: an overhead
  cleave straight down into the ground; a forward shoulder shove with the
  blade held flat; a full spin sweep; a rising upward slash. Top-down
  three-quarter view facing south. + style anchor
- **Spec:** 48 × 48 per frame; per move: wind-up, impact, recovery (3 poses);
  south, north, east.
- **Check for:** each finisher has a distinct silhouette at impact (so the
  player can tell them apart mid-fight).

### A-02 Greatsword effects

- **Prompt:** Pixel art effect sprite sheet, transparent background: (row 1)
  a wide pale crescent slash arc in 4 frames, appearing and fading; (row 2) a
  dust and small debris burst when something is pushed into a wall, 4 frames;
  (row 3) a short ring of dust for the spin sweep, 4 frames. Colours: pale
  paper white `#f0ece1`, grey `#a9b0bf`, dust brown `#8f8a6a`. + style anchor
- **Spec:** 64 × 64 per frame.
- **Check for:** effects are brief and pale, never brighter than the
  character; no sparkles.

---

## Hammer

### C-02 Hammer concept sheet (reference only)

- **Prompt:** Concept art sheet of a farmer's war hammer made from a fence-post
  maul: a heavy squared wooden head banded with rough iron straps, a long
  ash-wood handle worn smooth where the hands go, a rope loop at the end.
  Side, front and top views, plus two variants: one with a cracked stone face
  grown onto the striking end, one with an iron band glowing faintly from
  inside its cracks. Earthy muted colours, painterly, plain light background.
- **Avoid:** shared list, plus thunder, lightning, Viking or Norse motifs.
- **Check for:** feels heavy and blunt; clearly a farm tool turned weapon.

### A-03 Hammer icon

- **Prompt:** A single pixel art icon of a heavy maul hammer, squared wooden
  head with iron bands, long wooden handle, drawn diagonally, head at upper
  right. + style anchor
- **Spec:** 16 × 16 (generate at 128 × 128).
- **Check for:** the head reads as heavy and square at 16 px.

### F-03 Hammer charge and strike (key poses) — *depends on Q18*

- **Prompt:** Pixel art sprite sheet of the same small farmer character with
  a heavy maul hammer: (row 1) charging: hammer lifted gradually higher behind
  the shoulder in 4 stages, body coiling, the last pose straining with the
  hammer at its highest; (row 2) the strike: the hammer slammed down into the
  ground in front, then recovery; (row 3) a quick short jab with the hammer
  head, 3 poses; (row 4) a stomp with one foot, 3 poses. Top-down
  three-quarter view facing south. + style anchor
- **Spec:** 48 × 48 per frame; south, north, east.
- **Check for:** the charge clearly builds over its 4 poses (so the sweet
  spot can be read from the pose too); the strike looks like it lands with
  all the body's weight.

### A-04 Hammer effects

- **Prompt:** Pixel art effect sprite sheet, transparent background: (row 1)
  a ground shockwave ring expanding outwards with cracks and flying pebbles,
  6 frames; (row 2) a small spark of light on the hammer head, 3 frames (the
  sweet-spot signal); (row 3) a stone shell shattering into a few chunks, 5
  frames (armour break); (row 4) a weak puff of dust for an early or late
  strike, 3 frames. Colours: greys `#7d869a #a9b0bf`, dust `#8f8a6a`, spark
  `#f3d58a`. + style anchor
- **Spec:** 64 × 64 per frame (row 2: 16 × 16).
- **Check for:** the perfect-strike shockwave is clearly bigger and more
  satisfying than the weak puff; the spark is tiny but unmistakable.

---

## Bow

### C-03 Bow concept sheet (reference only)

- **Prompt:** Concept art sheet of a farmer's recurve bow carved from orchard
  wood (apple or pear), the grain visible, a grip wrapped in cloth, string of
  twisted gut, a simple leather quiver of plain arrows with grey goose
  feathers. Plus variants of crafted arrowheads: one with an ember-orange
  tip, one frosted pale blue, one with a dark violet bud. Muted natural
  colours, painterly, plain light background.
- **Avoid:** shared list, plus elven, ornate, glowing bows.
- **Check for:** light and graceful next to the heavy weapons; arrowheads
  distinguishable by colour alone.

### A-05 Bow and arrowhead icons

- **Prompt:** Pixel art icon set: (1) a wooden recurve bow drawn diagonally;
  (2) a plain arrow; (3) an arrow with an ember-orange tip; (4) an arrow with
  a frosted pale-blue tip; (5) an arrow with a dark violet bud tip. Each on
  its own square tile, transparent background. + style anchor
- **Spec:** 16 × 16 each (generate at 128 × 128).
- **Check for:** the three crafted arrows differ by tip colour and shape at
  16 px.

### F-04 Bow draw, release and dodge shot (key poses) — *depends on Q18*

- **Prompt:** Pixel art sprite sheet of the same small farmer character with
  a wooden recurve bow: (row 1) a quick shot: raise, release, lower; (row 2) a
  slow three-stage draw: bow raised, half drawn, fully drawn with the body
  leaning back slightly, then release; (row 3) a dodge roll ending in a
  crouched shot; (row 4) walking slowly while holding a full draw. Top-down
  three-quarter view facing south. + style anchor
- **Spec:** 48 × 48 per frame; south, north, east.
- **Check for:** each draw stage is visibly different (the player reads the
  stage from the pose); the dodge shot flows from the roll.

### A-06 Bow effects

- **Prompt:** Pixel art effect sprite sheet, transparent background: (row 1)
  an arrow in flight with a short pale motion trail, 3 frames; (row 2) a
  longer, brighter trail for a piercing arrow, 3 frames; (row 3) a heavy
  arrow impact burst, 4 frames; (row 4) a marker arrow stuck in the ground
  with a faint pulsing ring, 4 frames; (row 5) a rain of falling arrows
  seen from above at an angle, 6 frames. Colours: pale `#d9d6cc #f0ece1`,
  greys. + style anchor
- **Spec:** 32 × 32 per frame (rows 4–5: 64 × 64).
- **Check for:** the three arrow strengths are told apart by trail length;
  the rain reads as many arrows without becoming noise.

---

## Magic

### C-04 Lantern and magic concept sheet (reference only)

- **Prompt:** Concept art sheet of a farmer's lantern used as a magic focus:
  an old iron storm lantern, slightly dented, the glass replaced with thin
  slices of a strange pale violet crystal, a muted violet light inside that
  moves like slow smoke. The handle wrapped in twine. Next to it, three
  effects shown as small studies: smouldering embers (amber and orange
  sparks), creeping frost (pale blue crystals), and rot (dark violet spots
  and soft moss). Painterly, muted, a little uncanny, plain dark background.
- **Avoid:** shared list, plus wizard staffs, wands, spellbooks, pentagrams,
  bright purple.
- **Check for:** homely object with something wrong inside it; the violet is
  muted, not neon.

### A-07 Lantern icon

- **Prompt:** A single pixel art icon of an old iron storm lantern with a
  muted violet light inside, held by its ring handle, slightly tilted.
  + style anchor
- **Spec:** 16 × 16 (generate at 128 × 128).
- **Check for:** reads as a lantern at 16 px; the violet light is the only
  saturated colour.

### F-05 Casting and Release (key poses) — *depends on Q18*

- **Prompt:** Pixel art sprite sheet of the same small farmer character
  holding an iron lantern: (row 1) a quick forward flick of the lantern
  throwing a bolt, 3 poses; (row 2) a heavier underarm throw, 3 poses; (row 3)
  swinging the lantern down to pour light onto the ground, 4 poses; (row 4)
  the Release: lantern thrust forward with both hands, light bursting
  outward, then recoil, 4 poses; (row 5) a short blink: the character
  dissolving into violet smoke and reappearing, 4 poses. Top-down
  three-quarter view facing south. + style anchor
- **Spec:** 48 × 48 per frame; south, north, east.
- **Check for:** casting poses are light and mobile (never rooted); the
  Release pose is the most dramatic thing magic does.

### A-08 Spell effects

- **Prompt:** Pixel art effect sprite sheet, transparent background: (row 1)
  a small ember bolt, a tumbling amber spark with a short trail, 4 frames;
  (row 2) a frost shard, a pale blue crystal spinning, 4 frames; (row 3) a rot
  pool on the ground, a spreading dark violet stain with small moss tufts, 6
  frames growing then looping; (row 4) a chill patch left behind by the blink,
  pale frost on the ground, 4 frames. Colours: embers `#e0a95b #b8733a`,
  frost `#4f8296 #a9b0bf`, rot `#4a3f52 #6e5b73 #47573f`. + style anchor
- **Spec:** 32 × 32 per frame (rows 3–4: 64 × 64).
- **Check for:** each effect is identifiable by colour and shape alone (and
  by shape alone, for colour-blind players).

### A-09 Release bursts

- **Prompt:** Pixel art effect sprite sheet, transparent background, each row
  a burst of light and particles, 6 frames: (row 1) a single-effect release,
  a modest violet burst; (row 2) Shatter: amber and pale blue fragments
  exploding outward; (row 3) Blight bloom: dark violet spores drifting out in
  a ring; (row 4) Brittle: a cracking pale shell breaking off a shape; (row 5)
  all three together: the largest burst, all colours, still restrained.
  + style anchor
- **Spec:** 64 × 64 per frame.
- **Check for:** a clear step up in size from one effect to three; even the
  largest stays within the muted palette.

---

## Status effects and HUD

### A-10 Status effect icons and stack marks

- **Prompt:** Pixel art icon set, tiny, transparent background, each on its
  own square: (1) Smoulder: a small ember flame, amber; (2) Chill: a
  six-pointed frost crystal, pale blue; (3) Rot: a dark violet drop with a
  small sprout; (4) Frozen: the frost crystal inside a square ice block; (5)
  five tiny pips in a row for counting stacks (one pip lit, the rest dim).
  + style anchor
- **Spec:** 8 × 8 each (generate at 64 × 64); pips row 8 × 3.
- **Check for:** each icon is distinct by **shape** as well as colour;
  readable at 8 px over both light and dark ground.

### A-11 Effects on a creature

- **Prompt:** Pixel art overlay effects, transparent background, looping, to
  place over a small creature: (row 1) small embers rising off it, 4 frames;
  (row 2) frost creeping at its feet and a few ice crystals, 4 frames; (row 3)
  dark violet spots and drifting spores, 4 frames; (row 4) a creature-shaped
  block of pale ice (frozen), 2 frames. + style anchor
- **Spec:** 32 × 32 per frame.
- **Check for:** effects stay readable when all three play on one creature
  at once.

### A-12 Combat HUD pieces

- **Prompt:** Pixel art UI elements, flat and minimal, like marks drawn on
  old paper, transparent background: (1) a thin horizontal health bar frame
  and fill in warm red `#c2584a`; (2) a thin stamina bar in pale gold
  `#f3d58a`; (3) a thin focus bar in muted violet `#6e5b73`; (4) a small arc
  charge meter with a highlighted notch near the top (the hammer's sweet
  spot); (5) three small pips for bow draw stages; (6) five small feather
  marks for Flow; (7) a lock-on marker: four tiny corner brackets.
  + style anchor
- **Spec:** bars 64 × 4; meter 16 × 16; pips and marks 4 × 4 each; brackets
  12 × 12.
- **Check for:** sits quietly at the screen edge (art direction: calm, sparse
  UI); fits the UI width frame (ADR-0008).
