### Evidence Used & Verification Status
- **Files inspected**:
  - `Games/Pixel Depth/art/eggs/refs/pins_sheet.jpg` (Owner pixel-art references: 2D cosmic mist egg, shelf UI items, 9-egg themed grid, 50-egg sprite matrix, and pastel striped variants).
  - `Games/Pixel Depth/art/eggs/eggs_r1_sheet.jpg` (20 candidate tiles across 4 rows $\times$ 5 columns, labelled `01_fossil_s101` through `10_bone_s192`).
- **Unverified**:
  - In-engine triangle budgets and LOD behavior in Roblox Studio (estimated strictly against 3D voxelization feasibility of the 2D concept geometry).
  - Hatching rig/cutline constraints and crew pet scale matching (not present in reference art).

---

### Candidate Evaluation & Grading
*Grading scale: 5 = average, 7 = good, 8 = rare (harsh grading applied).*

| Egg | Chosen Variant | Theme Read (1-10) | Voxel Cohesion (1-10) | Silhouette (1-10) | Palette Fit (1-10) | Buildability <20k Tris (1-10) | Overall (1-10) | Rationale |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **01 Fossil** | `01_fossil_s102` | 7 | 5 | 4 | 7 | 8 | **6** | `s102` avoids the over-complex hollow teeth of `s101`; stone seams give blocky structure, but ammonite swirl is smooth bas-relief rather than stepped cubes. |
| **02 Moss** | `02_moss_s111` | 8 | 6 | 7 | 8 | 7 | **7** | `s111` has a clean grid shell with mint tendrils; far superior to the hyper-photoreal, messy photogrammetry-style brush clump of `s112`. |
| **03 Ember** | `03_ember_s122` | 7 | 4 | 4 | 4 | 7 | **5** | `s122` has better tectonic plates than `s121`'s generic hole, but both fail the ref's all-over lava cracks and use aggressive magma orange instead of cosy night tones. |
| **04 Crystal** | `04_crystal_s132` | 7 | 5 | 6 | 8 | 7 | **6** | `s132` features physical facet relief breaking the outline with plum/violet shadows; `s131` is just a flat smooth egg with glowing fish scales. |
| **05 Tide** | `05_tide_s141` | 8 | 7 | 5 | 7 | 9 | **7** | `s141` has authentic cubic tile construction across the shell; `s142` has a stronger wave profile but dissolves into smooth clay paste. |
| **06 Gold** | `06_gold_s151` | 7 | 4 | 4 | 7 | 8 | **6** | `s151` incorporates the rose gem vortex from the ref; however, both variants are smooth/triangulated metallic sculpts with zero cubic stepping. |
| **07 Obsidian** | `07_obsidian_s162` | 6 | 7 | 5 | 6 | 9 | **6** | `s162` exhibits clean block masonry and plum slate tones; `s161` has a sharp eye but is just a low-poly oval that completely ignores the obsidian ref. |
| **08 Cosmic** | `08_cosmic_s171` | 8 | 3 | 7 | 8 | 6 | **6** | `s171` nails the starry vortex and plum/lilac mist, but it is a pure photoreal VFX render with zero voxel cohesion; `s172` looks like a smoking coal chimney. |
| **09 Prism** | `09_prism_s181` | 8 | 6 | 5 | 9 | 9 | **7** | `s181` has chunkier low-poly facets and hits the exact rose, mint, and butter palette; `s182` has micro-scale noise that will sparkle horribly at distance. |
| **10 Bone** | `10_bone_s191` | 8 | 3 | 8 | 6 | 5 | **6** | `s191` has the most iconic silhouette (skull crest + nest), but the fine organic twigs and smooth anatomy require a total voxel overhaul. |

---

### Prompt Revision Directives (Which Need Re-prompting & What to Change)

- **01 Fossil**: Needs new prompt — prompt for *"isometric 3D voxel art, stepped cubic spiral ammonite carved into chunky cream sandstone blocks, MagicaVoxel style"*.
- **02 Moss**: Keep `s111` as 3D blockout reference — prompt tweak: *"replace smooth vine splines with orthogonal cubic foliage tendrils and blocky pixel leaves"*.
- **03 Ember**: **Needs new prompt** — prompt for *"chunky dark plum basalt voxel cube egg covered in fine glowing mint and rose magma fissures across all sides, no gaping single crater"*.
- **04 Crystal**: Keep `s132` as color guide — prompt tweak: *"stepped cubic amethyst crystal clusters protruding from egg surface, MagicaVoxel geometric clusters instead of rhomboid smooth facets"*.
- **05 Tide**: Keep `s141` as production baseline — prompt tweak: *"extend the blocky white seafoam crest outward past the silhouette by 2-3 voxel units for stronger profile read"*.
- **06 Gold**: **Needs new prompt** — prompt for *"warm butter-gold cubic voxel egg with an inset square-pixel gem socket holding a glowing rose/magenta crystal cube, isometric voxel render"*.
- **07 Obsidian**: **Needs new prompt** — prompt for *"glossy jet-black cubic obsidian egg with sharp reflective block facets, lilac ambient bounce lighting, and a single inset glowing eye aperture"*.
- **08 Cosmic**: **Needs new prompt** — prompt for *"deep plum-black voxel egg with pixelated galaxy spiral core and chunky stepped volumetric voxel smoke rings, no smooth alpha smoke"*.
- **09 Prism**: Keep `s181` as production baseline — prompt tweak: *"enforce orthogonal cubic stepping on facets rather than diamond triangulation while keeping the mint/rose/butter pastel gradient"*.
- **10 Bone**: **Needs new prompt** — prompt for *"chunky low-res voxel skull atop a cream block egg seated in a blocky briar nest, stylized chunky voxels under 500 cubes, cozy plum rim light"*.
[agy exit 0; log Overnight\agy\20261108_151551_eggs_r1.md]
