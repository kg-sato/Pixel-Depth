# Path & Surface Review: Roblox Voxel Camp Town (Round 2)

**Evaluator Role:** Delegated Read-Only Reviewer  
**Evidence Examined:**
- `Games/Pixel Depth/art/hub/pdv5_paths_s91.jpg` (Reference diorama: irregular flagstone arc, cream stepping stones, dirt/pebble clearing, block stone stairs)
- `Games/Pixel Depth/art/hub/pdv5_paths_s92.jpg` (Reference sheet: dirt bed with chunky stepping stones, wide ashlar steps with crevice moss)
- `Games/Pixel Depth/captures/v4/pa2_sheet.jpg` (Build quadrants: top-left stall lane & rail; top-right stream lane & stepping stones; bottom-left kiosk stairs; bottom-right east rise lane)
- `Games/Pixel Depth/captures/v4/t2r1_spawn.png` (Build overview: camera elevation, mine square, macro route readability)
- **Unverified:** In-engine material properties (Roughness/Reflectance), dynamic lighting transitions, collision bounds (`CanCollide`), and exact part counts.

---

### Rubric & Grading (Harsh Benchmark: 5 = Average, 7 = Good, 8 = Rare)

| Metric | Score (1–10) | Detailed Critique & Evidence |
| :--- | :---: | :--- |
| **Stone shape & irregularity** | **4.5** | **Decal flatness masquerading as masonry.** The reference (`pdv5_paths_s91.jpg`) displays distinct polygonal flagstones (trapezoids, pentagons) with individual bevels and recessed joints. In the build (`pa2_sheet.jpg`, `t2r1_spawn.png`), stones are purely a 2D cracked-line texture tiled across flat rectangular Parts. Where parts meet at angles (e.g., east rise lane), the texture seams mismatch and stretch. The mine plaza is an expanse of flat geometric slabs with zero surface relief. |
| **Edges (ragged, tufts, moss)** | **4.0** | **Confetti debris rather than natural overgrowth.** Adding green voxels along borders helped break razor-straight edges, but in `pa2_sheet.jpg` and `t2r1_spawn.png` they read as isolated 1x1 green cubes dropped along the border rather than creeping moss beds. The underlying path parts remain rigid prisms, and the "dark mossy bed" lacks depth beneath the high-contrast texture. |
| **Width variation & curves** | **4.0** | **Segmented ribbons with elbow kinks.** In `pdv5_paths_s91.jpg`, paths organically pinch, swell, and fan out around focal points. The build lanes (`pa2_sheet.jpg` bottom-right, `t2r1_spawn.png`) maintain a uniform width (~6 studs) and turn via abrupt 30°–45° polygonal miters rather than natural sweeping curves or tapering junctions. |
| **Material contrast with grass** | **5.0** | **Asphalt scars cutting pastel turf.** The cooler slate tint helps the night aesthetic, but the pitch-black grout lines produce excessive high-frequency noise against the mint-green lawn (`t2r1_spawn.png`). Instead of the warm, cohesive harmony in `pdv5_paths_s91.jpg`, the paths visually pierce the landscape with harsh contrast. |
| **Stairs** | **4.5** | **Cobblestone ramps with cosmetic nosing.** The nosing added to the kiosk stairs (`pa2_sheet.jpg` bottom-left) provides edge definition, but applying the cracked-cobblestone texture to treads and risers looks structurally absurd—it reads like a pile of loose river rocks glued onto a staircase. The references (`pdv5_paths_s91.jpg`, `s92.jpg`) clearly show flat, cut ashlar/slab steps. |
| **Readability as routes** | **5.5** | **Functional macro paths, confusing secondary features.** From bird's-eye (`t2r1_spawn.png`), primary destinations (mine, stall, kiosk) are legible. However, the stream edging uses the exact same width and cobble texture as the walkable paths, creating route confusion. Meanwhile, the stepping stones across the stream (`pa2_sheet.jpg` top-right) are muddy, submerged, and nearly invisible. |
| **Cohesion with references** | **4.0** | **Missing the tactile diorama warmth.** The references showcase chunky, soft-beveled volumes with warm cream stepping stones, dirt underlays, and soft lighting pools. The current build remains trapped in harsh, flat retro pixel-texturing with sharp CSG borders. |
| **Appeal** | **4.5** | **Visually fatiguing from distance.** While props and lanterns carry charm, looking at the paths from the camera perspective (`t2r1_spawn.png`) causes eye strain due to repetitive black linework and scattered single-block edge tufts. |

**Overall Score:** **4.5 / 10** *(Up from Round 1's 3.6; a noticeable step forward in structure and edge mitigation, but still below the "good" standard of 7.0).*

---

### Top 5 Concrete Fixes (Buildable with Roblox Parts & 32 px Textures)

1. **Replace Cobblestone on Stairs with Smooth Cut-Stone Slabs**
   - *Problem:* Kiosk steps (`pa2_sheet.jpg` bottom-left) use cobble texture across treads and risers, making steps look like unstable rubble.
   - *Fix:* Create treads from solid Parts (0.3 studs thick, overhanging 0.3 studs forward). Apply a dedicated 32×32 px smooth stone/ashlar texture (soft grey, horizontal hairline cleft, light top-lip highlight). Keep risers recessed by 0.2 studs and tint them 20% darker to cast a natural shadow under the nosing, exactly matching `pdv5_paths_s92.jpg`.

2. **Rebuild Stepping Stones as Elevated Cream Slabs with Dirt Underlays**
   - *Problem:* Stepping stones (`pa2_sheet.jpg` top-right, `t2r1_spawn.png`) are dingy, greenish-grey flat blocks submerged flush with the water/grass.
   - *Fix:* Use 2×2 stud Parts, 0.5 studs tall, tinted warm cream/bone (`RGB 220, 212, 192` to match `pdv5_paths_s91.jpg`), with alternating rotations (±7°). For stones placed in lawn, place a thin (0.05 stud) warm brown Part beneath them (32×32 px dirt texture) extending 0.4 studs outward to create a worn earthen bed before transitioning to grass.

3. **Soft Grout Color & Reduced Contrast on the 32 px Cobble Texture**
   - *Problem:* Pure black grout lines on the lane texture produce severe visual noise and look like asphalt tracks from the bird's-eye camera (`t2r1_spawn.png`).
   - *Fix:* Edit the 32×32 px cobble texture: replace pure black (`#000000`) grout with a dark, desaturated mossy slate (`#2A322C`). Shift the stone midtones toward soft lavender-slate (`#7E7E91`). Reducing the luminance delta between stone and grout by 35% preserves readability while stopping the visual vibration against the mint grass.

4. **Cluster Edge Tufts & Vary Lane Widths (Eliminate Single-Voxel Confetti)**
   - *Problem:* Scattered 1×1 single-block voxels along borders (`pa2_sheet.jpg`) look like disconnected litter rather than organic lawn overgrowth.
   - *Fix:* Construct lanes using alternating Part widths (segmenting lengths into 5-stud, 7-stud, and 5.5-stud chunks) to create natural silhouette variation. Replace single loose cubes with clustered L-shaped or 2×2 flat green wedge/slab "moss mats" (0.1 studs thick) that straddle the seam between grass and cobble, hugging inner corner notches.

5. **Differentiate Stream Embankments from Walkable Lanes & Feather the Mine Plaza**
   - *Problem:* The stone lining the stream (`t2r1_spawn.png` southwest) duplicates the primary lane texture, and the mine square terminates in a rigid geometric staircase silhouette.
   - *Fix:* Retexture stream embankment Parts with a distinct, darker river-boulder texture (no grid lines) raised 1.2 studs above water level. On the mine plaza apron, replace the hard 90° stepped polygon edges with tapered 32 px dirt/gravel transition wedges where lanes connect.
[agy exit 0; log Overnight\agy\20261108_143228_paths_r2.md]
