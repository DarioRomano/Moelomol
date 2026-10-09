# Asset register

Every art, audio and font asset in the game, where it came from, its licence,
and whether it is placeholder. Add a row in the same PR that adds the asset.
Placeholders are replaced when the provisioned art arrives (Q2).

| Asset | Path | Source | Licence | Status |
|---|---|---|---|---|
| App icon (sprout in soil) | `icon.svg` | Hand-written SVG by the engineer, draft palette | Project-owned | **Placeholder** |
| Test card drawing and 16×24 figure | `scenes/showcase/test_card.gd` (drawn in code) | Engineer | Project-owned | Debug only, not game content |
| UI font | none (engine built-in default font, antialiasing off) | Godot engine | Ships with the engine | **Placeholder**: uneven letter spacing at 8 px; a pixel font is needed |
