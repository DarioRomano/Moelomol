# Asset register

Every art, audio and font asset in the game, where it came from, its licence,
and whether it is placeholder. Add a row in the same PR that adds the asset.
Rows marked **Placeholder** are the code drawings the game still uses until the files in `assets/` are wired in (Q2, amended 2026-11-12). Audio, art
source files and video are stored through Git LFS (ADR-0011).

| Asset | Path | Source | Licence | Status |
|---|---|---|---|---|
| App icon (sprout in soil) | `icon.svg` | Hand-written SVG by the engineer, draft palette | Project-owned | **Placeholder** |
| Test card drawing and 16×24 figure | `scenes/showcase/test_card.gd` (drawn in code) | Engineer | Project-owned | Debug only, not game content |
| Combat placeholders (player, greatsword, hammer, bow, arrows, lantern, spell bolts, Rot and Chill pools, effect pips, charge meter, draw pips, Volley mark and rain, creatures and stone shell, arena, effects incl. shockwave and shell shards, HUD) | `src/combat/combat_drawer.gd`, `scenes/combat/combat_hud.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until the AI art from `combat-art-prompts.md` |
| Millbrook creature placeholders (field mice, rooks, hedgehogs, flood toads, stooks and sheaves, moths, Grist with mud and tusks; lane telegraphs, glob and slick, the yard's millstones, sacks, wallow and trough, lights) | `src/combat/combat_drawer.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until the creature art |
| Millbrook map placeholders (ground, path, green, gardens, wheat and stubble, changed land, woods, hedgerows, apple trees, island, water, floodwater and drained mud, fences, footbridge, well, hives, sluice, signpost, buildings with roofs and dark windows, the chapel's tower, the mill wheel; night sight ring) | `src/world/area_drawer.gd`, `scenes/world/area_scene.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until Millbrook's art |
| Kettlebridge creature placeholders (market rats and runts, jackdaws carrying runts, river pike under and at the surface, the pike's jet, Lichen-backs and the gravestones they hide as; fur and water-ring effects) | `src/combat/combat_drawer.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until the creature art |
| Kettlebridge map placeholders (cobbles, market stalls, the auction ring's sawdust and rostrum, the churchyard and gravestones, the winch house, the barge, the lifting bridge in its two leaves; the key and the winch-house door) | `src/world/area_drawer.gd`, `scenes/world/area_scene.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until Kettlebridge's art |
| Millbrook notes and satchel placeholders (note paper with the loose thread, the satchel panel, notes on the ground with their warm glint, the crank, the sluice wheel, Grist's heart, the F/B prompt) | `scenes/world/note_view.gd`, `scenes/world/satchel_view.gd`, `scenes/world/area_scene.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until the UI and area art |
| Note texts (ten drafts) | `src/world/millbrook_notes.gd` | Engineer | Project-owned | **Draft** for the lead's taste |
| Farm placeholders (grass, path, fence, tilled and watered soil, catmint and radish in four stages, farmhouse with lit windows, farmer casting, spell glows and marks, rain, target and watering-area highlight, Mana bar, HUD) | `src/farm/farm_drawer.gd`, `scenes/farm/farm_hud.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until the provisioned base art |
| The farm's placeholders (grass, long grass, the first field's edge, old furrows, paths and gates, hedge, thicket, woods, pond, broken pen fence, wildflowers; farmhouse, workshop, coop, chest, porch lamp, apple tree, bench, rock, mailbox; cleared ground and the Clear cast; the great fields' hedgerows, ruined shelter and withering) | `src/farm/farm_ground.gd`, `src/farm/farm_drawer.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until the provisioned base art |
| The farmhouse inside's placeholders (floorboards, back wall, windows, cup, bed, window seat, stove, basket, table and chairs, cupboard and seed tin, rug, candle and stove glow) | `src/farm/house_drawer.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until the provisioned base art |
| The cat's placeholder (sitting, curled on the blanket, eyes closed when stroked) | `src/farm/cat_drawer.gd` (drawn in code) | Engineer, draft palette | Project-owned | **Placeholder** until the provisioned cat art |
| Ground tiles (grass in four moods with long and flowered variants, fringes and banks, path, soils, old furrows, cobbles, sawdust, wheat, stubble, mud, water and floodwater, floorboards; hedge, thicket, woods and wall blocks) | `assets/tiles/` (63 files), made by `tools/art/ground.py`, `nature.py` | Engineer, scripted, project palette | Project-owned | **Game art** (not yet wired in), replaceable |
| Trees, bushes, rocks, reeds, fences and gates | `assets/nature/` | `tools/art/nature.py` | Project-owned | **Game art** (not yet wired in), replaceable |
| Building pieces in seven styles and composed landmarks (farmhouse lit and unlit, workshop, coop, cottages, shed, mill and wheel, chapel, church lit and unlit, tower, inn, winch house) | `assets/buildings/` | `tools/art/buildings.py` | Project-owned | **Game art** (not yet wired in), replaceable |
| Props: the farm (chest, mailbox, bench, lamp, shelter, crops in four stages and withered, the cat's blanket), the farmhouse inside, the world (well, signpost, hive, lamp post, notice board, notes), Millbrook (sluice, crank, millstones, sacks, trough, wallow, sheaf, fungus, heart, footbridge), Kettlebridge (stalls, rostrum, gravestones, the barge, bridge deck and raised leaf, key, padlock) | `assets/props/` | `tools/art/props.py` | Project-owned | **Game art** (not yet wired in), replaceable |
| The player: five sheets (unarmed, greatsword, hammer, bow, lantern), every animation facing south, north and east | `assets/player/` | `tools/art/player.py` (a posed rig) | Project-owned | **Game art** (not yet wired in), replaceable |
| The cat (day and night eyes), every creature of Millbrook and Kettlebridge, Grist, Duke and his herd | `assets/creatures/` | `tools/art/creatures.py` | Project-owned | **Game art** (not yet wired in), replaceable. Duke is drawn ahead of being built |
| Effects (weapons, spells, status marks, farm spells, rain, smoke, creature marks) | `assets/effects/` | `tools/art/effects.py` | Project-owned | **Game art** (not yet wired in), replaceable |
| Icons (weapons, arrows, seeds, crops, drops, key items, spells, sun and moon, status effects) | `assets/icons/` | `tools/art/icons.py` | Project-owned | **Game art** (not yet wired in), replaceable |
| Interface (bars, charge meter, pips, lock-on, paper, panel, buttons, key and controller prompts, title, app icon) | `assets/ui/` | `tools/art/ui.py` | Project-owned | **Game art** (not yet wired in), replaceable |
| Pixel font "Moelomol" (ASCII 32 to 126, 10 px line, drawn for this project) | `assets/ui/moelomol_font.png`, `.fnt` | `tools/art/font.py` | Project-owned | **Game font** (not yet wired in) |
| Review sheets and mock screens | `docs/design/images/assets/*.png` | `tools/art/build.py` | Project-owned | Documentation only, not game content |
| Sound effects (134), ambience loops (9), music (MUS-01, 02, 10, 11 ×6, 12, 13, with stems) | `assets/audio/` (**not in the repository yet**: Q44), made by `tools/audio/build.py` | Engineer, synthesised (numpy, scipy, ffmpeg at build time only) | Project-owned | **Game audio**, replaceable; handed to the lead as a zip 2026-11-12 |
| Design sketches (farm and Millbrook layouts, screen shapes) | `docs/design/images/*.png`, drawn by `make_sketches.py` | Engineer | Project-owned | Documentation only, not game content (`docs/` is ignored by the importer and excluded from exports) |
| UI font in use | none (engine built-in default font, antialiasing off) | Godot engine | Ships with the engine | **Placeholder** until the Moelomol font above is wired in |

## AI-generated audio

(Superseded for now by Q3's amendment of 2026-11-12: the sound is synthesised by the engineer. This section applies again to any generated take that replaces a cue.)

Music and ambience will be generated by the lead with AI tools from
`audio-prompts.md` (Q3). Before the first file is committed, the lead confirms
the tool's terms allow use in a sold game. Each file then gets a row in the
table above with: cue ID, tool and model/version, generation date, the exact
prompt, seed (if shown), licence terms, and take number. None exist yet.

## AI-generated art

(Superseded for now by Q2's amendment of 2026-11-12: the art is scripted by the engineer. This section applies again to any generated image that replaces one.)

Combat art will be generated by the lead with AI image tools from
`combat-art-prompts.md` (Q2: art is provisioned by the lead). The same rules
as for audio apply: the lead confirms the tool's terms allow use in a sold
game before the first file is committed; each file gets a row with prompt ID,
tool and model/version, date, exact prompt, seed (if shown), licence terms,
and whether it was edited by hand. Concept sheets (C prompts) are reference
only and are not committed as game assets. None exist yet.

