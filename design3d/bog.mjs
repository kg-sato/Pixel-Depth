// The Bog-Iron Pickaxe biography (Pixel Depth, brief "Forge Biographies (2026-11-15)", scene bible entry "Bog-Iron").
// A frog smelts bog ore in a clay chimney furnace on a tiny island in a blackwater bog at dawn. "The bog wanted it back."
// Models: FrogKit (the maker), BogSet (furnace, bellows, ore, walkway, boat: everything on and about the island), BogNet (his net
// on a pole), BogWorld (the painted ground and its mirror), BogLily, CottonGrass, Pitcher (placed by src/ForgeBogMap.luau),
// OreNodule, MushroomCharm. The ground, its pictures and the map come from design3d/bog_world.py.
// Space: x to screen right, y up, z toward the camera; the island is at the origin, the water at terrain.waterY.
import terrain from "./tex/bog_terrain.mjs";
export const name = "bog";

const C = {
  frog: "#78893a", frogDark: "#56682c", frogLight: "#a6b565", belly: "#fbe3a9", eyeRing: "#dfe0a8", eye: "#1d1528", white: "#ffffff", pink: "#f4a9c2", mouth: "#2a4a2a",
  boot: "#6f3425", bootLight: "#8a4a34", bootDark: "#4e2016", reed: "#e7ba8c", reedDark: "#c4935f", rope: "#d9a066", netWood: "#a45d2e", netMesh: "#d8d8d4",
  clay: "#b8754e", clayDark: "#9a5d3c", clayLight: "#d09468", soot: "#3a2e2a", hollow: "#1c1210", fire: "#ff8a2a", fireHot: "#ffc24a", slag: "#ff6a1c",
  rust: "#b8552e", rustDark: "#8a3d22", rustLight: "#d47a44", iron: "#4a4a52",
  leather: "#7a5038", leatherLight: "#9a6a4a", patch: "#c9a070", plank: "#6c595c", plankLight: "#84706e", plankDark: "#4a3e44", post: "#3a3238",
  moss: "#6e7f58", mossLight: "#8fa468", mossDark: "#4f6044", pad: "#5f8a78", padLight: "#7fa890", padDark: "#4a6c66", petal: "#f6eef0", petalPink: "#f0c4d4", butter: "#f2c230",
  cotton: "#f4f2ea", stem: "#8a8a56", stemDark: "#6a7048", pitcher: "#8a3a3e", pitcherLight: "#b86a4a", pitcherGreen: "#7a9a4c",
  coal: "#2a2628", cap: "#c8402e", capDark: "#9a2c24",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, field, mirrorY, rnd, model } = T;
  const out = [];
  // a cheap rounded lump: far fewer triangles than ball()
  const lo = (rx, ry, rz, ws = 6, hs = 4) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  // a lily pad: a flat disc with a notch, lying on the water
  const pad = (r, p, yaw = 0) => { const g = new THREE.CircleGeometry(r, 12, 0.3, Math.PI * 2 - 0.6); g.rotateX(-Math.PI / 2); return at(g, p, [0, yaw, 0]); };
  const ring = (cx, y, cz, rx, rz, n = 16) => { const pts = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; pts.push([cx + Math.sin(a) * rx, y, cz + Math.cos(a) * rz]); } return pts; };
  const W = terrain.waterY;

  // ---------- FrogKit: the maker. A plump green frog, wide head with the eyes on top, reed hat, rope belt, boots. Colours measured on refs/forge/sheets/frog_views_s11.png ----------
  {
    const m = model("FrogKit");
    m.bone("Hips", null, [0, 0.8, 0]);
    m.bone("Body", "Hips", [0, 0.8, 0]);
    m.add("Body", lathe([[0.02, 0.52], [0.6, 0.56], [0.88, 0.92], [0.86, 1.34], [0.68, 1.7], [0.42, 1.92], [0.02, 1.98]], 20), C.frog);
    m.add("Body", at(ball(0.66, 0.62, 0.3, 16), [0, 1.16, 0.58]), C.belly); // the pale belly
    for (const [x, y, z, r] of [[-0.3, 1.5, -0.62, 0.13], [0.26, 1.3, -0.8, 0.16], [-0.1, 1.05, -0.86, 0.12], [0.44, 1.62, -0.5, 0.1], [-0.52, 1.2, -0.66, 0.11], [0.06, 1.7, -0.62, 0.09], [0.6, 1.1, -0.6, 0.1], [-0.66, 1.52, -0.3, 0.08]])
      m.add("Body", at(lo(r, r, 0.05, 8, 5), [x, y, z], [0, Math.atan2(x, z) * 57.3, 0]), C.frogDark); // the speckled back
    m.add("Body", tube(ring(0, 0.95, 0, 0.89, 0.89), 0.06, 6, 32), C.rope); // the rope belt and its knot
    m.add("Body", at(ball(0.11, 0.1, 0.09, 8), [0.2, 0.95, 0.86]), C.rope);
    for (const dx of [-0.06, 0.1]) m.add("Body", limb([0.2, 0.93, 0.88], [0.2 + dx, 0.62, 0.9], 0.04, 0.03, 6), C.rope);
    m.add("Body", at(pillow(0.3, 0.34, 0.2, 0.5, 6), [-0.62, 0.84, 0.62], [0, -40, 6]), C.reedDark); // a reed creel on his hip
    m.add("Body", at(pillow(0.34, 0.1, 0.24, 0.5, 6), [-0.62, 1.02, 0.62], [0, -40, 6]), C.reed);

    const J = [0, 1.9, 0];
    m.bone("Head", "Body", J);
    m.add("Head", at(ball(1.3, 0.84, 1.0, 24), [0, 2.62, 0.08]), C.frog);
    m.add("Head", at(ball(1.2, 0.5, 0.92, 20), [0, 2.36, 0.14]), C.belly); // the pale jaw
    m.add("Head", tube([[-1.02, 2.56, 0.6], [-0.6, 2.44, 0.92], [0, 2.4, 1.07], [0.6, 2.44, 0.92], [1.02, 2.56, 0.6]], 0.028, 6, 20), C.mouth); // the wide mouth
    for (const s of [-1, 1]) {
      m.add("Head", at(ball(0.44, 0.44, 0.44, 16), [0.62 * s, 3.26, 0.26]), C.frog); // the eye mounds on top of the head
      m.add("Head", at(ball(0.035, 0.03, 0.03, 6), [0.13 * s, 2.86, 1.03]), C.mouth); // nostrils
      m.add("Head", at(ball(0.16, 0.11, 0.05, 8), [0.96 * s, 2.52, 0.6], [0, 48 * s, 0]), C.pink); // blush
    }
    for (const [x, y, z, r] of [[-0.3, 3.3, -0.4, 0.14], [0.2, 3.36, -0.2, 0.1], [0.5, 3.1, -0.66, 0.13], [-0.7, 2.96, -0.62, 0.1], [0, 3.02, -0.84, 0.12]]) m.add("Head", at(lo(r, 0.05, r, 8, 5), [x, y, z], [-30, 0, 0]), C.frogDark);
    for (const s of [-1, 1]) m.add("Head", at(ball(0.29, 0.34, 0.07), [0.62 * s, 3.3, 0.61], [-8, 10 * s, 0]), C.eyeRing); // the pale ring round each eye (reference frog_views_s11)
    m.bone("Eyes", "Head", [0, 3.3, 0.6]);
    for (const s of [-1, 1]) { // tall dark ovals, one big light and one small
      m.add("Eyes", at(ball(0.22, 0.28, 0.1), [0.62 * s, 3.3, 0.63], [-8, 10 * s, 0]), C.eye);
      m.add("Eyes", at(ball(0.075, 0.08, 0.04), [0.62 * s + 0.06, 3.42, 0.72]), C.white);
      m.add("Eyes", at(ball(0.032, 0.032, 0.025, 6), [0.62 * s - 0.07, 3.19, 0.71]), C.white);
    }
    m.bone("EyesShut", "Head", [0, 3.3, 0.66]); // happy closed arcs, hidden until used
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.42 * s, 3.22, 0.62], [0.62 * s, 3.36, 0.71], [0.82 * s, 3.22, 0.6]], 0.04, 6, 10), C.mouth);
    m.bone("Cheeks", "Head", [0, 2.46, 0.45]); // puffed when he blows or strains: scale this bone (rest size is a small pouch)
    for (const s of [-1, 1]) m.add("Cheeks", at(ball(0.36, 0.32, 0.34, 14), [0.9 * s, 2.46, 0.45]), C.frogLight);
    m.bone("Hat", "Head", [0, 3.6, -0.05]); // a wide woven reed hat, tipped back so his eyes show under the brim
    m.add("Hat", at(lathe([[0.02, 0], [1.5, 0], [1.54, 0.05], [1.02, 0.3], [0.5, 0.58], [0.12, 0.74], [0.02, 0.76]], 22), [0, 3.6, -0.1], [-12, 0, 0]), C.reed);
    for (const [r, y] of [[1.3, 0.17], [0.78, 0.44], [0.3, 0.68]]) m.add("Hat", at(tube(ring(0, y, 0, r, r), 0.035, 5, 24), [0, 3.6, -0.1], [-12, 0, 0]), C.reedDark);
    m.add("Hat", at(lathe([[1.5, -0.02], [1.56, 0.02], [1.5, 0.07]], 22), [0, 3.6, -0.1], [-12, 0, 0]), C.reedDark);

    m.bone("ArmL", "Body", [0.8, 1.62, 0.05]);
    m.add("ArmL", limb([0.8, 1.62, 0.05], [1.12, 1.25, 0.15], 0.17, 0.15), C.frog);
    m.bone("ForeL", "ArmL", [1.12, 1.25, 0.15]);
    m.add("ForeL", limb([1.12, 1.25, 0.15], [1.2, 0.9, 0.32], 0.14, 0.15), C.frog);
    m.add("ForeL", at(ball(0.19, 0.17, 0.2), [1.21, 0.84, 0.36]), C.frog);
    for (const dx of [-0.14, 0, 0.14]) m.add("ForeL", at(ball(0.085, 0.085, 0.085, 8), [1.21 + dx, 0.72, 0.5 - Math.abs(dx) * 0.4]), C.frogLight); // round finger pads
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");

    m.bone("LegL", "Hips", [0.42, 0.8, 0]);
    m.add("LegL", limb([0.42, 0.8, 0], [0.5, 0.44, 0.05], 0.27, 0.22), C.frog);
    m.add("LegL", limb([0.5, 0.5, 0.05], [0.5, 0.2, 0.05], 0.26, 0.27), C.boot); // his boots
    m.add("LegL", at(lathe([[0.27, -0.05], [0.3, 0], [0.27, 0.05]], 12), [0.5, 0.54, 0.05]), C.bootLight);
    m.add("LegL", at(ball(0.33, 0.18, 0.52), [0.52, 0.18, 0.3]), C.boot);
    m.add("LegL", at(ball(0.3, 0.06, 0.48), [0.52, 0.05, 0.3]), C.bootDark);
    m.mirror("LegL", "LegR");
    out.push(m);
  }

  // ---------- BogSet: the island's things. Root at the island's ground (y = 0); the water is at W ----------
  {
    const m = model("BogSet"), geos = [], sgeos = [];
    const F = [1.6, 0, -0.8]; // the furnace stands here (bog_world.py paints the baked earth round it)
    const addM = (bone, g, c) => { m.add(bone, g, c); geos.push([g, c]); }; // things the water shows upside down
    const addS = (bone, g, c) => { m.add(bone, g, c); sgeos.push([g, c]); }; // the two upper rings: their reflection is its own bone
    m.bone("Ground", null, [0, 0, 0]);
    // the ore heap (bog_world.py paints rust under it), a pile of charcoal, a stump to sit on
    for (let i = 0; i < 16; i++) { const a = rnd(i + 40) * 6.283, r = Math.sqrt(rnd(i + 50)) * 1.1, s = 0.24 + rnd(i + 60) * 0.22; m.add("Ground", at(lo(s, s * 0.8, s * 0.9, 7, 5), [4.6 + Math.cos(a) * r, 0.12 + (1.1 - r) * 0.42, 0.8 + Math.sin(a) * r], [rnd(i) * 90, rnd(i + 1) * 90, 0]), [C.rust, C.rustDark, C.rustLight, C.rust][i % 4]); }
    for (let i = 0; i < 10; i++) m.add("Ground", at(limb([-0.4, 0, 0], [0.4, 0, 0], 0.09, 0.08, 5), [3.5 + (rnd(i + 70) - 0.5) * 1.2, 0.1 + (i % 3) * 0.14, -3.0 + (rnd(i + 80) - 0.5) * 0.9], [0, rnd(i + 90) * 180, 0]), C.coal);
    m.add("Ground", lathe([[0.02, 0], [0.46, 0], [0.42, 0.52], [0.02, 0.54]], 10).translate(-3.2, 0, -1.6), C.post);
    m.add("Ground", at(lathe([[0.02, 0.54], [0.4, 0.54], [0.02, 0.56]], 10), [-3.2, 0, -1.6]), C.plankLight);
    m.add("Ground", at(lathe([[0.02, 0], [1.75, 0], [1.6, 0.07], [0.02, 0.08]], 18), F), C.clayDark); // the clay pad the furnace is built on

    // the furnace: a base with the fire mouth, and two more rings of clay that are stacked on it in the scene
    m.bone("Furnace", "Ground", F);
    addM("Furnace", at(lathe([[0.02, 0.05], [1.3, 0.05], [1.36, 0.3], [1.26, 0.9], [1.12, 1.5], [1.02, 1.9], [0.72, 1.92], [0.7, 1.6], [0.02, 1.6]], 20), F), C.clay);
    for (const y of [0.34, 1.0, 1.55]) addM("Furnace", at(tube(ring(0, y, 0, 1.36 - y * 0.2, 1.36 - y * 0.2), 0.06, 5, 24), F), C.clayLight); // coils of clay, smoothed by hand
    for (let i = 0; i < 7; i++) { const a = 1.2 + i * 0.75, y = 0.5 + rnd(i + 20) * 1.1, r = 1.3 - y * 0.16; m.add("Furnace", at(lo(0.2, 0.16, 0.05, 6, 4), [F[0] + Math.sin(a) * r, y, F[2] + Math.cos(a) * r], [0, a * 57.3, 0]), i % 2 ? C.clayLight : C.clayDark); } // patches
    const arch = (w, h) => { const p = [[-w, 0], [-w, h * 0.55]]; for (let k = 0; k <= 8; k++) { const a = Math.PI * (1 - k / 8); p.push([Math.cos(a) * w, h * 0.55 + Math.sin(a) * h * 0.45]); } p.push([w, 0]); return p; };
    m.add("Furnace", at(puff(arch(0.5, 1.0), 0.3, 0.05, false), [F[0], 0.14, F[2] + 1.2]), C.hollow); // the mouth's dark recess
    m.add("Furnace", at(tube([[-0.56, 0.14, 0], [-0.58, 0.72, 0], [-0.4, 1.06, 0], [0, 1.24, 0], [0.4, 1.06, 0], [0.58, 0.72, 0], [0.56, 0.14, 0]], 0.1, 6, 18), [F[0], 0, F[2] + 1.3]), C.clayLight); // its rolled rim
    m.add("Furnace", at(lo(0.14, 0.12, 0.1, 6, 4), [F[0] - 0.94, 0.3, F[2] + 0.94]), C.hollow); // the tap hole
    m.bone("Mouth", "Furnace", [F[0], 0.6, F[2] + 1.3], "Neon"); // the fire seen in the mouth
    m.add("Mouth", at(puff(arch(0.42, 0.86), 0.06, 0.03, false), [F[0], 0.17, F[2] + 1.37]), C.fire);
    m.bone("Stack1", "Furnace", [F[0], 1.9, F[2]]);
    addS("Stack1", at(lathe([[0.72, 1.9], [1.04, 1.9], [0.96, 2.5], [0.9, 3.0], [0.66, 3.0], [0.68, 1.9]], 18), F), C.clay);
    addS("Stack1", at(tube(ring(0, 2.46, 0, 0.99, 0.99), 0.055, 5, 22), F), C.clayLight);
    m.bone("Stack2", "Stack1", [F[0], 3.0, F[2]]);
    addS("Stack2", at(lathe([[0.66, 3.0], [0.92, 3.0], [0.84, 3.6], [0.78, 4.05], [0.88, 4.18], [0.8, 4.26], [0.62, 4.2], [0.6, 3.0]], 18), F), C.clay);
    m.add("Stack2", at(lathe([[0.79, 3.8], [0.9, 4.2], [0.8, 4.28], [0.63, 4.22]], 18), F), C.soot); // a sooty lip
    m.bone("Throat", "Stack2", [F[0], 4.0, F[2]], "Neon"); // the glow in the top of the stack
    m.add("Throat", at(lathe([[0.02, 4.0], [0.6, 4.0], [0.02, 4.02]], 14), F), C.fireHot);
    m.bone("Slag", "Furnace", [F[0] - 0.94, 0.3, F[2] + 0.94], "Neon"); // slag dribbling from the tap hole: scale it from nothing
    m.add("Slag", tube([[F[0] - 0.94, 0.3, F[2] + 0.94], [F[0] - 1.2, 0.12, F[2] + 1.3], [F[0] - 1.5, 0.1, F[2] + 1.8], [F[0] - 1.7, 0.1, F[2] + 2.4]], (u) => 0.08 - 0.03 * u, 6, 12), C.slag);
    m.add("Slag", at(lo(0.34, 0.05, 0.24, 8, 4), [F[0] - 1.76, 0.1, F[2] + 2.5]), C.slag);
    m.bone("Bloom", "Ground", [F[0], 0.55, F[2] + 1.1], "Neon"); // the glowing lump of iron; the scene carries it out and cools it
    for (const [x, y, z, r] of [[0, 0, 0, 0.36], [0.22, 0.1, 0.05, 0.22], [-0.2, -0.04, 0.12, 0.24], [0.04, 0.2, -0.14, 0.2], [-0.06, -0.16, -0.1, 0.22]]) m.add("Bloom", at(lo(r, r * 0.86, r, 7, 5), [F[0] + x, 0.55 + y, F[2] + 1.1 + z]), C.fireHot);

    // the bellows: screen left of the furnace, its nozzle in the furnace wall. The top board is hinged at the nozzle end and
    // rests open; the bag between the boards is its own bone, squashed in y as the top comes down
    const B = [-0.9, 0, -0.5];
    const board = () => puff([[0.1, 0.16], [-0.5, 0.42], [-1.5, 0.66], [-2.3, 0.6], [-2.62, 0.3], [-2.62, -0.3], [-2.3, -0.6], [-1.5, -0.66], [-0.5, -0.42], [0.1, -0.16]], 0.09, 0.04);
    m.bone("BellowsBase", "Ground", [0.3, 0.2, B[2]]);
    m.add("BellowsBase", at(board(), [0.3, 0.2, B[2]], [-90, 0, 0]), C.plank);
    for (const x of [-0.2, -1.9]) m.add("BellowsBase", at(pillow(0.2, 0.2, 1.0, 0.4, 4), [x, 0.08, B[2]]), C.post);
    m.add("BellowsBase", limb([0.3, 0.3, B[2]], [0.62, 0.42, B[2] - 0.12], 0.15, 0.09, 8), C.iron); // the nozzle
    m.bone("BellowsBag", "BellowsBase", [B[0], 0.26, B[2]]);
    m.add("BellowsBag", at(pillow(2.3, 0.66, 1.1, 0.55, 8), [B[0] - 0.1, 0.59, B[2]]), C.leather);
    for (const y of [0.42, 0.6, 0.78]) m.add("BellowsBag", at(tube(ring(0, 0, 0, 1.17, 0.57, 14), 0.035, 4, 20), [B[0] - 0.1, y, B[2]]), C.leatherLight); // the folds
    m.add("BellowsBag", at(pillow(0.5, 0.36, 0.06, 0.4, 4), [B[0] - 0.3, 0.6, B[2] + 0.56]), C.patch); // a patch, stitched on
    m.bone("BellowsTop", "BellowsBase", [0.3, 0.5, B[2]]);
    const top = at(board(), [0, 0, 0], [-90, 0, 0]);
    m.add("BellowsTop", at(top, [0.3, 0.5, B[2]], [0, 0, -17]), C.plankLight);
    m.add("BellowsTop", at(at(limb([-2.5, 0.06, 0], [-3.2, 0.1, 0], 0.09, 0.08, 6), [0, 0, 0], [0, 0, -17]), [0.3, 0.5, B[2]]), C.post); // the handle
    m.add("BellowsTop", at(at(pillow(0.5, 0.05, 0.4, 0.4, 4), [-1.5, 0.08, 0.1], [0, 20, -17]), [0.3, 0.5, B[2]]), C.patch);

    // moss and small mushrooms that move in while the iron cools: scale this bone from nothing
    m.bone("Moss", "Ground", [F[0], 0.02, F[2]]);
    for (let i = 0; i < 14; i++) { const a = -1.4 + i * 0.33 + rnd(i + 5) * 0.2, y = 0.1 + rnd(i + 30) * 1.3, r = 1.36 - y * 0.2; m.add("Moss", at(lo(0.3 + rnd(i) * 0.16, 0.2, 0.1, 6, 4), [F[0] + Math.sin(a) * r, y, F[2] + Math.cos(a) * r], [0, a * 57.3, 0]), [C.moss, C.mossLight, C.mossDark][i % 3]); }
    for (let i = 0; i < 9; i++) { const a = i * 0.7, r = 1.5 + rnd(i + 11) * 0.7; m.add("Moss", at(lo(0.34, 0.1, 0.28, 6, 4), [F[0] + Math.sin(a) * r, 0.1, F[2] + Math.cos(a) * r]), [C.mossLight, C.moss][i % 2]); }
    for (const [x, z, s] of [[-1.3, 1.3, 1], [-1.0, 1.62, 0.7], [1.5, 1.2, 0.8]]) {
      m.add("Moss", limb([F[0] + x, 0.06, F[2] + z], [F[0] + x, 0.06 + 0.3 * s, F[2] + z], 0.06 * s, 0.05 * s, 6), C.belly);
      m.add("Moss", at(lathe([[0.02, 0], [0.22, 0], [0.18, 0.1], [0.02, 0.17]], 8), [F[0] + x, 0.32 * s, F[2] + z], [0, 0, 0], s), C.cap);
    }

    // the plank walkway: from the island's edge to the spit at screen left, on posts in the water
    m.bone("Walk", "Ground", [0, 0, 0]);
    const wy = (x) => 0.02 - 0.2 * Math.min(1, Math.max(0, (-x - 10) / 21));
    for (let k = 0; k < 23; k++) { const x = -9.6 - k * 1.0; addM("Walk", at(pillow(0.9, 0.14, 2.3 + (k % 3) * 0.12, 0.2, 4), [x, wy(x) + (k % 2) * 0.02, 1.5 + ((k * 7) % 5 - 2) * 0.04], [0, ((k * 5) % 7) - 3, ((k * 3) % 5 - 2) * 0.6]), [C.plank, C.plankLight, C.plankDark, C.plank][k % 4]); }
    for (const z of [0.55, 2.45]) addM("Walk", limb([-9.4, -0.12, z], [-32, -0.3, z], 0.09, 0.09, 4), C.post);
    for (let k = 0; k < 6; k++) for (const z of [0.4, 2.6]) { const x = -11 - k * 4; addM("Walk", limb([x, W - 2.4, z], [x, wy(x) + 0.5 + rnd(k + z) * 0.3, z], 0.15, 0.12, 6), C.post); }
    addM("Walk", tube([[-15, 0.52, 2.6], [-17, 0.2, 2.66], [-19, 0.5, 2.6]], 0.03, 4, 8), C.rope); // a sagging hand rope
    // lily pads by the walkway (the ore lies under them)
    m.bone("Pads", "Ground", [-16, W, 4.6]);
    for (const [x, z, r, c] of [[-14.6, 4.2, 0.8, C.pad], [-16.1, 4.9, 1.0, C.padLight], [-17.4, 4.0, 0.7, C.padDark], [-15.4, 5.9, 0.6, C.pad], [-18.3, 5.4, 0.85, C.padLight], [-13.3, 5.2, 0.55, C.padDark]]) m.add("Pads", pad(r, [x, W + 0.04, z], x * 60), c);
    // the half-sunk rowing boat off the island's right shore: bow up, stern under
    m.bone("Boat", "Ground", [10.5, W, 9.2]);
    const hull = []; for (let k = 0; k <= 12; k++) { const a = (k / 12) * Math.PI; hull.push([Math.cos(a) * 2.6, -Math.sin(a) * 0.9]); }
    const boat = (g) => at(at(g, [0, 0, 0], [0, 90, 0]), [10.5, W - 0.15, 9.2], [-17, 38, 14]);
    addM("Boat", boat(puff(hull.map(([x, y]) => [x, y]), 1.5, 0.3)), C.plankDark);
    m.add("Boat", boat(at(puff(hull.map(([x, y]) => [x * 0.86, y * 0.72]), 1.1, 0.2), [0, 0.12, 0])), C.post);
    m.add("Boat", boat(at(pillow(0.4, 0.12, 1.7, 0.2, 4), [0, 0.02, 0])), C.plank);
    m.add("Boat", boat(at(lo(0.5, 0.14, 0.36, 6, 4), [1.4, 0.3, 0.6])), C.moss);

    m.bone("Mirror", null, [0, 0, 0]); // the scene sets this bone to y = 2 * water level
    for (const [g, c] of geos) m.add("Mirror", mirrorY(g, 0), c);
    m.bone("MirrorStack", "Mirror", [0, 0, 0]); // shown once the rings are stacked
    for (const [g, c] of sgeos) m.add("MirrorStack", mirrorY(g, 0), c);
    out.push(m);
  }

  // ---------- BogNet: a round landing net on a long pole. Grip at the origin, the pole along +Y, the hoop at the top ----------
  {
    const m = model("BogNet");
    m.bone("Net", null, [0, 0, 0]);
    m.add("Net", limb([0, -1.0, 0], [0, 2.9, 0], 0.07, 0.06, 6), C.netWood);
    for (const y of [-0.2, 0.3]) m.add("Net", at(lathe([[0.08, -0.05], [0.09, 0], [0.08, 0.05]], 6), [0, y, 0]), C.rope);
    const hoop = []; for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2; hoop.push([Math.sin(a) * 0.72, 3.62 + Math.cos(a) * 0.72, 0]); }
    m.add("Net", tube(hoop, 0.05, 5, 24), C.netWood);
    for (let k = -2; k <= 2; k++) { const x = k * 0.28, h = Math.sqrt(Math.max(0.02, 0.5 - x * x)); m.add("Net", tube([[x, 3.62 + h, 0], [x, 3.62 + h * 0.4, -0.5], [x, 3.62 - h * 0.4, -0.5], [x, 3.62 - h, 0]], 0.022, 4, 8), C.netMesh); }
    for (let k = -1; k <= 1; k++) { const y = 3.62 + k * 0.36, w = Math.sqrt(Math.max(0.02, 0.5 - k * k * 0.13)); m.add("Net", tube([[-w, y, 0], [-w * 0.4, y, -0.5], [w * 0.4, y, -0.5], [w, y, 0]], 0.022, 4, 8), C.netMesh); }
    out.push(m);
  }

  // ---------- BogWorld: the ground itself. Two painted height fields and their mirror images for the black water ----------
  {
    const m = model("BogWorld");
    const nr = terrain.near, fr = terrain.far, n = nr.h.length - 1;
    const hole = (i, j) => nr.d[j][i] < -4 && nr.d[j][i + 1] < -4 && nr.d[j + 1][i] < -4 && nr.d[j + 1][i + 1] < -4; // open water: the mirror world shows through
    m.bone("Bog", null, [0, 0, 0], "SmoothPlastic", "tex/bog_ground.png");
    m.addTex("Bog", field(nr.rect[0], nr.rect[1], nr.rect[2], nr.rect[3], nr.h, hole));
    const cw = (fr.rect[2] - fr.rect[0]) / n, cd = (fr.rect[3] - fr.rect[1]) / n;
    const under = (i, j) => { const x0 = fr.rect[0] + i * cw, z0 = fr.rect[1] + j * cd; return x0 > nr.rect[0] + 3 && x0 + cw < nr.rect[2] - 3 && z0 > nr.rect[1] + 3 && z0 + cd < nr.rect[3] - 3; };
    m.bone("Far", null, [0, 0, 0], "SmoothPlastic", "tex/bog_far.png");
    m.addTex("Far", field(fr.rect[0], fr.rect[1], fr.rect[2], fr.rect[3], fr.h, under));
    m.bone("BogM", null, [0, 0, 0], "SmoothPlastic", "tex/bog_ground.png");
    m.addTex("BogM", mirrorY(field(nr.rect[0], nr.rect[1], nr.rect[2], nr.rect[3], nr.h, (i, j) => hole(i, j) || nr.h[j][i] < W + 0.2), W));
    m.bone("FarM", null, [0, 0, 0], "SmoothPlastic", "tex/bog_far.png");
    m.addTex("FarM", mirrorY(field(fr.rect[0], fr.rect[1], fr.rect[2], fr.rect[3], fr.h, (i, j) => under(i, j) || fr.rect[1] + j * cd > -100), W));
    out.push(m);
  }

  // ---------- things the map scatters ----------
  {
    const m = model("BogLily"); // a raft of lily pads with one flower (root on the water)
    m.bone("Pads", null, [0, 0, 0]);
    for (const [x, z, r, c] of [[0, 0, 0.9, C.pad], [1.3, 0.5, 0.62, C.padLight], [-0.7, 1.2, 0.5, C.padDark], [0.5, -1.2, 0.56, C.padLight], [-1.4, -0.3, 0.42, C.pad]]) m.add("Pads", pad(r, [x, 0, z], x * 80 + z * 50), c);
    for (let k = 0; k < 6; k++) m.add("Pads", at(lo(0.08, 0.05, 0.2, 5, 3), [1.3 + Math.sin(k * 1.047) * 0.14, 0.09, 0.5 + Math.cos(k * 1.047) * 0.14], [-30, k * 60, 0]), k % 2 ? C.petal : C.petalPink);
    m.add("Pads", at(lo(0.07, 0.06, 0.07, 5, 3), [1.3, 0.1, 0.5]), C.butter);
    out.push(m);
  }
  {
    const m = model("CottonGrass"); // a tussock of sedge with white cotton heads
    m.bone("Tuft", null, [0, 0, 0]);
    for (let i = 0; i < 7; i++) { const a = rnd(i + 3) * 6.283, r = rnd(i + 9) * 0.34, h = 0.9 + rnd(i + 15) * 0.7, lx = Math.cos(a) * (r + 0.24), lz = Math.sin(a) * (r + 0.24);
      m.add("Tuft", limb([Math.cos(a) * r, 0, Math.sin(a) * r], [lx, h, lz], 0.022, 0.014, 4), i % 2 ? C.stem : C.stemDark);
      m.add("Tuft", at(lo(0.1, 0.13, 0.1, 6, 4), [lx + 0.03, h + 0.07, lz], [0, 0, -20]), C.cotton); }
    for (let i = 0; i < 8; i++) { const a = i * 0.785 + 0.3, h = 0.4 + rnd(i + 21) * 0.4; m.add("Tuft", limb([Math.cos(a) * 0.12, 0, Math.sin(a) * 0.12], [Math.cos(a) * 0.42, h, Math.sin(a) * 0.42], 0.03, 0.008, 4), i % 2 ? C.mossLight : C.stemDark); }
    m.add("Tuft", at(lo(0.4, 0.16, 0.4, 7, 4), [0, 0.02, 0]), C.moss);
    out.push(m);
  }
  {
    const m = model("Pitcher"); // pitcher plants: red-veined trumpets with a hood
    m.bone("Pitcher", null, [0, 0, 0]);
    for (const [x, z, h, t] of [[0, 0, 1.0, 6], [0.22, 0.1, 0.74, -12], [-0.2, 0.14, 0.82, 14], [0.04, -0.22, 0.6, -8]]) {
      m.add("Pitcher", at(lathe([[0.02, 0], [0.04, 0.1], [0.08, 0.6], [0.13, 0.92], [0.17, 1.0], [0.1, 0.98], [0.02, 0.6]], 7), [x, 0, z], [t, 0, t], h), h > 0.8 ? C.pitcher : C.pitcherLight);
      m.add("Pitcher", at(lo(0.15, 0.04, 0.17, 6, 3), [x + t * 0.012, h * 1.06, z - 0.08], [-35, 0, 0], h), C.pitcherGreen);
    }
    m.add("Pitcher", at(lo(0.34, 0.1, 0.34, 7, 4), [0, 0.02, 0]), C.mossDark);
    out.push(m);
  }

  // ---------- props ----------
  {
    const m = model("OreNodule"); // a rusty lump of bog ore, wet from the water
    m.bone("Ore", null, [0, 0, 0]);
    for (const [x, y, z, r, c] of [[0, 0, 0, 0.3, C.rust], [0.2, 0.08, 0.06, 0.2, C.rustLight], [-0.18, -0.05, 0.1, 0.21, C.rustDark], [0.02, 0.16, -0.14, 0.18, C.rust], [-0.06, -0.14, -0.12, 0.2, C.rustDark], [0.1, -0.1, 0.18, 0.15, C.rustLight]]) m.add("Ore", at(lo(r, r * 0.82, r, 7, 5), [x, y, z]), c);
    out.push(m);
  }
  {
    const m = model("MushroomCharm"); // the small red mushroom that grew on the cooling iron: the pickaxe's charm
    m.bone("Charm", null, [0, 0, 0]);
    m.add("Charm", limb([0, -0.2, 0], [0, 0.08, 0], 0.07, 0.06, 8), C.belly);
    m.add("Charm", lathe([[0.02, 0.04], [0.26, 0.04], [0.24, 0.16], [0.14, 0.27], [0.02, 0.31]], 12), C.cap);
    m.add("Charm", at(lathe([[0.02, 0.03], [0.24, 0.04], [0.02, 0.05]], 12), [0, 0, 0]), C.belly);
    for (const [a, y, r] of [[0.4, 0.2, 0.2], [2.2, 0.16, 0.23], [4.1, 0.22, 0.17], [5.3, 0.14, 0.24]]) m.add("Charm", at(lo(0.04, 0.025, 0.04, 5, 3), [Math.sin(a) * r, y, Math.cos(a) * r]), C.white);
    m.add("Charm", tube([[0, 0.3, 0], [0.05, 0.44, 0], [0, 0.56, 0], [-0.05, 0.44, 0], [0, 0.3, 0]], 0.015, 4, 12), C.rope);
    out.push(m);
  }
  return out;
}
