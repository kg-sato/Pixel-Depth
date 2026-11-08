# Egg references (for the 3D egg models)

The user's sources (2026-11-08, Pinterest): https://ca.pinterest.com/pin/928656385676970359/ , https://ca.pinterest.com/pin/758012181084266857/ , https://ca.pinterest.com/pin/497647827591945444/ , https://ca.pinterest.com/pin/777363585728687785/ , https://ca.pinterest.com/pin/492370171770117939/ . Saved as `refs/pin1-5.jpg` and `refs/pins_sheet.jpg` (pixel-art themed eggs: cosmic swirl with mist, lava cracks, vines, gem socket, crystal scales, obsidian, golden spiral, thorn nest, skull, pastel stripes).

Workflow: sources, then local FLUX (`tools/comfy_wide.py`, scripts `spike/gen_egg_refs*.sh`), then harsh Gemini grades (`grades/`), four rounds. Round 1 was too smooth (about 6.2); round 2 forced visible cubes; rounds 3 and 4 re-prompted only the eggs under 7, then under 8.

## Final picks (`final/egg_01..10.jpg`, sheet `final/eggs_final_sheet.jpg`)
| # | Egg | Pick | Gemini overall |
|---|---|---|---|
| 1 | Fossil (Common, the tutorial egg) | r2 s201 | 8.0 |
| 2 | Moss | r3 s312 | 7.6 |
| 3 | Ember | r4 s421 | 8.2 |
| 4 | Crystal | r2 s231 | 7.8 |
| 5 | Tide | r3 s341 | 8.4 |
| 6 | Gold | r2 s251 | 7.4 |
| 7 | Obsidian | r4 s461 | 8.0 |
| 8 | Cosmic | r2 s272 | 7.6 |
| 9 | Prism (Mythic) | r2 s281 | 8.4 |
| 10 | Bone (Secret) | r4 s492 | 7.9 |
Moss, crystal, gold and cosmic did not improve in round 4 (plateau); five eggs are 8 or more. Next step: the Claude Design 3D board, then Blender voxel models (under 20k triangles each); the egg-to-rarity mapping is a suggestion, not decided.
