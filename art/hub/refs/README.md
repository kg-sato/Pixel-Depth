# Hub v4 references, textures and grades (2026-11-08)

The user's brief: make the camp hub about 4x the area (more room per store, a bigger backdrop), research textures for each store, and follow the workflow **find image, AI-generate a reference, build, Gemini grades**.

## 1. Found images (viewed in the browser, not downloaded)
| Store | Reference | What we took from it |
|---|---|---|
| Sell stall | [Small Market Stall](https://sketchfab.com/3d-models/4eef05ec5aef4faa8d7dc29fbcc3fab9), [Minecraft Market Stall](https://sketchfab.com/3d-models/7eba0d8ca6184dfd852280b11fa495f0) | crates of colourful goods on a deck, striped awning on four posts |
| Forge | [Blacksmith house](https://sketchfab.com/3d-models/96a4d1415679461080fbd7cd02533c13), [Blacksmith and his home](https://sketchfab.com/3d-models/bc8d7688f3fa4441b8608bf3615a71fa), [Blacksmith forge furniture](https://sketchfab.com/3d-models/blacksmith-forge-furniture-320ed264a00c41c0bac53011ec99671f) | stone base, dark timber frame, teal shingles, glowing forge, anvil and tools |
| Trophy hall | [Voxel skull with horns](https://www.cgtrader.com/3d-print-models/miniatures/figurines/voxel-skull-with-horns) (no voxel trophy hall found) | horned skull silhouette |
| Guest cabins | [Cozy Isometric Cabin](https://sketchfab.com/3d-models/2ab1921edcd6492e89710d739b761349) | shingle roof, plank walls, warm lit interior |
| Incubator | [Greenhouse in the moonlight](https://sketchfab.com/3d-models/35e2be8686cb4fda93e85d47f805ae81) | glass house at night, framed panes |
| Notice board | [Quest Board](https://sketchfab.com/3d-models/0b230b01c4834bf0af0523182c96d9fb) | roofed board with pinned notes |
| Campfire | [Voxel Camp Site](https://sketchfab.com/3d-models/02ddf9f4341b4b9eb6f67dc6428e017d) | stone ring, logs, benches |
| Whole hub | [Hub - Large Medieval](https://sketchfab.com/3d-models/0f687bae9a6148809dff4e7b0a7c70df), [Countryside Lobby](https://sketchfab.com/3d-models/942422680d3d4e909247b5694b2c3025) | a big lobby with spread-out buildings and paths |

Texture research (style only, no third-party texture is used): [Pixel Block Tiles](https://dr-froth.itch.io/pixel-block-tiles), [Pixel Terrain Tiles](https://beefpuppy.itch.io/ptt), [CC0 seamless cobblestone](https://opengameart.org/content/seamless-pattern-pack-cobblestonepng), [16x16 block texture set](https://opengameart.org/content/16x16-block-texture-set). Takeaways: 16 to 32 px tiles, 4 to 6 tone ramps, a lit top-left edge and a shaded bottom-right edge per brick or board, grout lines a few tones darker (not black), sparse detail pixels (nails, knots, flowers).

## 2. AI references (local FLUX schnell, `tools/comfy_wide.py`, 1152 x 864)
`art/hub/pdv4_<store>_s61.jpg` and `_s62.jpg` for sell, forge, trophy, cabin, incubator, notice, campfire and the whole hub. Graded against: sell s61, forge s61, trophy s61, cabin s62, incubator s61, notice s61, campfire s62, hub s61. (Grade briefs name them `.png`; they were converted to JPG afterwards to keep the repo light.)

## 3. Textures (ours: `art/pd_hub_tex.py`, 32 px, upscaled 8x; ids in `art/roblox_tex/hub/asset_ids.json`)
One tile = 4 to 8 studs. Shared ramps with the mine textures (`pd_art.py`), grout in lavender-slate.
| Store | Textures |
|---|---|
| Sell stall | planks_light (deck, counter top), planks (counter, drawers), awning (rose and cream stripes), beam (posts), wood_frame (crates) |
| Forge | stonebrick (base, chimney, yard wall), plaster + beam (timber frame), shingle_teal (roof), flagstone (yard), logs (stump), iron (anvil) |
| Trophy hall | stonebrick (hall, arch, braziers), shingle_plum (roof and portico), cobble (forecourt), planks (doors) |
| Guest cabins | logs (walls and front gable), moss_roof or shingle_teal, planks_light (porch), stonebrick (chimney) |
| Incubator | stonebrick (base and plinth), wood_frame (frame), glass (clear panes, one shine streak), logs (twig nests) |
| Notice board | planks (board and wings), shingle_plum (gable), flagstone (forecourt), planks_light (relic chest) |
| Campfire | flagstone (patio), stonebrick (kerb, ring), logs (benches, split logs, kindling), iron (mug) |
| Ground and backdrop | cobble_soft (plaza), flagstone (paths), grass_top (meadow), bark (roots, trunk), rockface (Hollow Mountain wall, rear cliff) |

## 4. Gemini grades (Gemini 3.8 Flash, harsh: 5 = average, 7 = good, 8 = rare; logs in `art/hub/grades/`)
| Round | Sell | Forge | Trophy | Cabins | Incubator | Notice | Campfire | Whole hub | Average |
|---|---|---|---|---|---|---|---|---|---|
| R1 | 4.7 | 4.7 | 4.0 | 4.7 | 4.3 | 4.3 | 3.7 | 4.6 | 4.4 |
| R2 | 4.7 | 4.7 | 5.0 | 5.3 | 6.7 | 5.0 | 7.0 | 5.2 | 5.5 |
| R3 | 5.3 | 5.3 | 5.3 | 6.0 | 6.7 | 6.0 | 6.0 | 6.2 | 5.9 |
| R4 | 5.0 | 4.7 | 6.3 | 6.0 | 5.3 | 6.3 | 5.7 | 5.4 | 5.6 |
| R5 | 5.0 | 4.7 | 5.3 | 4.7 | 5.0 | 6.0 | 6.7 | 5.4 | 5.3 |
Plateau after R3 (the grader's fix lists started contradicting earlier rounds). A pairwise check (R3 vs R5, `pair_r3_r5.md`) picked R5 for the forge, incubator, notice board, campfire and backdrop, and R3 for the sell sign and the cabin layout; the final build merges those. Whole-hub space scored 6, 6, 8, 7, 7. Blocked below 8: next lever is modelled meshes (Claude Design 3D board, then Blender) for the skulls, chimneys and nests, which blocky parts cannot sculpt.
