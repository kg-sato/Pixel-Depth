// Wood Pickaxe biography: "a birch branch dropped by a spring storm, whittled by a young raccoon in one long night".
// The setting (the owner, 2026-11-15: a whole place of its own, built to refs/forge/scene_cabin_lake.jpg): a mountain lake at the
// edge of a spruce forest, a log cabin with lit windows on the far bank, wildflower meadows, two forested slopes crossing
// behind. The maker follows refs/forge/model_chibi_animals.jpg: a big fluffy head, a tiny body, dot eyes, fur tufts, layered gear.
// Models: BoltKit (the maker), WoodSet (the camp: birches, log, fire), WoodWorld (painted terrain and its mirror for the lake),
// Cabin, Spruce1-3, PineClump, FlowerPatch, GrassTuft, Rock1-2, Lightning, BirchBranch, WoodBlank, Shaving, Acorn, Knife, Leaf.
// Front of every model is +Z, the camera stands at +Z. Units are studs. Heights and painted pictures come from wood_world.py.
import terrain from "./tex/wood_terrain.mjs";
export const name = "wood";

const C = {
  fur: "#4f4858", furDark: "#2c2832", furLight: "#6f6779", mask: "#211c27", cream: "#f3e6c8", tan: "#c8a67e", tanDark: "#a98862", pink: "#f4a9c2", nose: "#2a1f36", eye: "#1d1528", white: "#ffffff",
  red: "#e8525a", redDark: "#c23c4c", vest: "#8a5a3c", cloak: "#1f7f7c", cloakLight: "#3aa39c", cloakDark: "#176260", brass: "#e2b65a",
  grassDark: "#4f7f58", grassDeep: "#3f6a4c", grass: "#6f9a5a", grassLight: "#8fb46a",
  birch: "#f3ede2", birchShade: "#d8cdc6", birchMark: "#3d3344", leaf: "#8fc878", leafLight: "#b7de8c", leafDark: "#5e9a5c", butter: "#f7e6a2",
  stone: "#8d8c92", stoneDark: "#66666e", stoneLight: "#a9a8ac", moss: "#5f8a4c", wood: "#c99a6b", woodDark: "#9a6d4d", woodEnd: "#f0d7a8",
  flame: "#ff7a1c", flameCore: "#ffc24a", ember: "#e8421c", bolt: "#fff7d0",
  steel: "#dfe3f5", acorn: "#c98f5a", acornCap: "#8a5d44",
  sp1: "#1c3733", sp2: "#234539", sp3: "#2c5442", spTip: "#3f6f52", bark: "#4a3a34", barkLight: "#63504a",
  log: "#5c4434", logLight: "#735640", logEnd: "#a07c58", roof: "#565a62", roofLight: "#6e737c", roofDark: "#3e4148", glow: "#ffae2a", glowHot: "#ffd98a",
  petal: "#f2c230", petalDeep: "#e8a516", petalPale: "#f6e7a0", stem: "#4f7a45",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, field, mirrorY, rnd, model } = T;
  const out = [];
  // a cheap rounded lump (a pad of needles, a leaf, a petal disc): far fewer triangles than ball()
  const lo = (rx, ry, rz, ws = 6, hs = 4) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const rad = (d) => (d * Math.PI) / 180;

  // ---------- BoltKit: the young raccoon ----------
  {
    const m = model("BoltKit");
    m.bone("Hips", null, [0, 0.95, 0]);
    m.bone("Body", "Hips", [0, 0.95, 0]);
    m.add("Body", lathe([[0.02, 0.7], [0.46, 0.73], [0.67, 0.95], [0.7, 1.25], [0.58, 1.65], [0.42, 1.95], [0.02, 2.04]], 20), C.fur);
    m.add("Body", at(ball(0.47, 0.52, 0.3), [0, 1.28, 0.43]), C.cloak);
    const hem = []; for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2; hem.push([Math.sin(a) * 0.72, 0.9 + Math.sin(a * 5) * 0.03, Math.cos(a) * 0.6 - 0.1]); }
    m.add("Body", tube(hem, 0.1, 6, 32), C.cream); // the vest's fur hem
    // chest ruff: five soft points of pale fur under the chin
    for (const [x, l] of [[-0.3, 0.3], [-0.15, 0.4], [0, 0.46], [0.15, 0.4], [0.3, 0.3]]) m.add("Body", limb([x, 1.72, 0.5], [x * 1.25, 1.72 - l * 0.7, 0.6], 0.14, 0.07, 8), C.cream);
    // neckerchief: a soft ring, a knot and a bib point (the bow language of the pickaxes)
    const ring = []; for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2; ring.push([Math.sin(a) * 0.46, 1.93 + Math.cos(a) * 0.03, Math.cos(a) * 0.44]); }
    m.add("Body", tube(ring, 0.13, 8, 32), C.red);
    m.add("Body", at(puff([[-0.42, 0.05], [0.42, 0.05], [0.0, -0.62]], 0.16, 0.1), [0, 1.9, 0.52], [-18, 0, 0]), C.red);
    m.add("Body", at(ball(0.13, 0.11, 0.1), [0, 1.9, 0.6]), C.redDark);
    for (const s of [-1, 1]) m.add("Body", limb([0.07 * s, 1.84, 0.6], [0.2 * s, 1.5, 0.52], 0.045, 0.02, 6), C.redDark);
    // a traveller's cloak: a short cape down his back with a paler hem and a hood bunched behind the neck
    m.add("Body", at(puff([[-0.5, 0], [0.5, 0], [0.82, -1.0], [0.42, -1.16], [0, -1.06], [-0.42, -1.16], [-0.82, -1.0]], 0.1, 0.07), [0, 1.9, -0.56], [9, 0, 0]), C.cloak);
    m.add("Body", at(puff([[-0.82, -1.0], [-0.42, -1.16], [0, -1.06], [0.42, -1.16], [0.82, -1.0], [0.8, -0.86], [0.42, -1.0], [0, -0.9], [-0.42, -1.0], [-0.8, -0.86]], 0.12, 0.05, false), [0, 1.9, -0.585], [9, 0, 0]), C.cloakLight);
    m.add("Body", at(ball(0.78, 0.5, 0.5), [0, 2.16, -0.5]), C.cloak);
    for (const s of [-1, 1]) m.add("Body", at(puff([[-0.2, 0], [0.24, 0.04], [0.3, -0.5], [0.02, -0.66], [-0.24, -0.46]], 0.08, 0.06), [0.5 * s, 1.94, 0.36], [-14, 24 * s, 8 * s], [s, 1, 1]), C.cloak); // the cloak falls over each shoulder
    m.add("Body", at(ball(0.1, 0.1, 0.08, 8), [0, 1.74, 0.68]), C.brass); // its clasp
    m.add("Body", at(ball(0.44, 0.2, 0.26), [0, 2.1, -0.46]), C.cloakDark);
    for (const s of [-1, 1]) m.add("Body", limb([0.5 * s, 1.92, -0.1], [0.36 * s, 1.9, 0.34], 0.1, 0.07, 8), C.cloak); // it is tied over the shoulders
    // a fur-lined leather vest, open at the front, and a bedroll strapped across his back
    m.add("Body", at(ball(0.74, 0.6, 0.62, 18), [0, 1.4, -0.12]), C.vest);
    for (const s of [-1, 1]) m.add("Body", tube([[0.3 * s, 1.86, 0.34], [0.5 * s, 1.5, 0.5], [0.56 * s, 1.1, 0.46], [0.5 * s, 0.86, 0.34]], 0.075, 6, 10), C.cream);
    for (const [y, x] of [[1.5, 0.6], [1.3, 0.64], [1.1, 0.62]]) m.add("Body", at(ball(0.035, 0.035, 0.03, 6), [-x, y, 0.36]), C.brass);
    m.add("Body", at(lathe([[0.02, -0.56], [0.2, -0.56], [0.23, -0.44], [0.23, 0.44], [0.2, 0.56], [0.02, 0.56]], 12), [0, 1.62, -0.84], [0, 0, 90]), C.cloakLight);
    for (const x of [-0.3, 0.3]) m.add("Body", at(lathe([[0.245, -0.05], [0.245, 0.05]], 12), [x, 1.62, -0.84], [0, 0, 90]), C.woodDark);
    for (const s of [-1, 1]) m.add("Body", at(lathe([[0.02, -0.02], [0.17, -0.02], [0.17, 0.02], [0.02, 0.02]], 10), [0.57 * s, 1.62, -0.84], [0, 0, 90]), C.cloak);
    // belt with a brass buckle; satchel on his right hip with a butter button and a leaf tucked in
    const belt = []; for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2; belt.push([Math.sin(a) * 0.7, 1.16, Math.cos(a) * 0.68]); }
    m.add("Body", tube(belt, 0.07, 6, 32), C.woodDark);
    m.add("Body", at(pillow(0.26, 0.22, 0.1, 0.5), [0, 1.16, 0.7]), C.brass);
    m.add("Body", tube([[0.5, 1.86, 0.2], [0.2, 1.5, 0.6], [-0.3, 1.15, 0.62], [-0.66, 0.98, 0.3]], 0.055, 6, 14), C.wood);
    m.add("Body", at(pillow(0.46, 0.42, 0.3, 0.5), [-0.72, 0.98, 0.22], [0, -24, 8]), C.woodDark);
    m.add("Body", at(pillow(0.5, 0.2, 0.34, 0.5), [-0.73, 1.14, 0.23], [0, -24, 8]), C.wood);
    m.add("Body", at(ball(0.07, 0.07, 0.05, 8), [-0.8, 1.06, 0.4]), C.butter);
    m.add("Body", at(puff([[0, 0], [0.12, 0.1], [0.13, 0.26], [0, 0.42], [-0.13, 0.26], [-0.12, 0.1]], 0.03, 0.025), [-0.62, 1.2, 0.2], [0, -20, -18]), C.leaf);

    // the head: 16% larger than the first model (the reference: the head is over half the height), grown about the neck joint
    const HS = 1.16, J = [0, 2.02, 0];
    const H = (g) => at(g, [0, J[1] * (1 - HS), 0], [0, 0, 0], HS);
    const hj = (p) => [p[0] * HS, J[1] + (p[1] - J[1]) * HS, p[2] * HS];
    m.bone("Head", "Body", J);
    m.add("Head", H(at(ball(1.02, 0.88, 0.92, 24), [0, 2.74, 0.05])), C.fur);
    m.add("Head", H(at(ball(0.8, 0.5, 0.7, 18), [0, 3.12, -0.05])), C.furLight); // a paler crown
    for (const s of [-1, 1]) {
      // cheek ruffs: four ragged points a side, the lower ones pale (the reference's tufted outline)
      const tuft = (len, wid) => puff([[0, wid], [len * 0.5, wid * 0.7], [len * 0.85, wid * 0.2], [len, 0], [len * 0.7, -wid * 0.5], [len * 0.36, -wid * 0.86], [0, -wid]], 0.07, 0.045);
      for (const [y, a, len, wid, c, zf] of [[2.78, 8, 0.5, 0.2, C.furLight, 0.0], [2.58, -12, 0.62, 0.22, C.tan, 0.04], [2.4, -30, 0.56, 0.2, C.cream, 0.08], [2.26, -50, 0.4, 0.16, C.cream, 0.12]]) { // the cheek ruff: three flat pointed tufts a side, swept back, built on the right and mirrored
        const g = at(tuft(len, wid), [0.76, y, 0.18 + zf], [0, -22, a]);
        m.add("Head", H(s > 0 ? g : at(g, [0, 0, 0], [0, 0, 0], [-1, 1, 1])), c);
      }
      m.add("Head", H(at(ball(0.3, 0.23, 0.16), [0.4 * s, 2.73, 0.8], [0, 18 * s, 14 * s])), C.mask); // the mask: a patch round each eye
      m.add("Head", H(tube([[0.1 * s, 2.96, 0.93], [0.42 * s, 3.03, 0.84], [0.78 * s, 2.94, 0.6], [1.0 * s, 2.78, 0.3]], (u) => 0.06 - 0.03 * u, 8, 14)), C.cream); // the brow band
      m.add("Head", H(at(ball(0.13, 0.1, 0.05), [0.7 * s, 2.46, 0.7], [0, 30 * s, 0])), C.pink); // blush
    }
    m.add("Head", H(at(ball(0.9, 0.5, 0.52, 18), [0, 2.42, 0.44])), C.tan); // the tan lower face

    for (const [x, a] of [[-0.22, 12], [0, 0], [0.22, -12]]) m.add("Head", H(at(ball(0.06, 0.2, 0.07, 8), [x, 3.36, 0.6], [-38, 0, a])), C.furDark); // forehead stripes
    m.add("Head", H(at(ball(0.36, 0.26, 0.28), [0, 2.44, 0.84])), C.cream); // muzzle
    m.add("Head", H(at(ball(0.14, 0.1, 0.1), [0, 2.55, 1.1])), C.nose);
    m.add("Head", H(tube([[-0.11, 2.4, 1.07], [-0.05, 2.36, 1.1], [0, 2.39, 1.11], [0.05, 2.36, 1.1], [0.11, 2.4, 1.07]], 0.022, 6, 12)), C.nose);
    for (const [x, a, l] of [[-0.12, 20, 0.2], [0.04, -2, 0.26], [0.18, -22, 0.18]]) m.add("Head", H(at(puff([[-0.1, 0], [0.1, 0], [0.04, l * 0.7], [0, l], [-0.05, l * 0.6]], 0.12, 0.07), [x, 3.56, 0.12], [-14, 0, a])), C.fur); // a tuft of dark hair on the crown
    m.bone("Eyes", "Head", hj([0, 2.8, 0.9]));
    for (const s of [-1, 1]) { // the reference's eyes: tall dark ovals, wide apart, one big light and one small
      m.add("Eyes", H(at(ball(0.125, 0.19, 0.07), [0.43 * s, 2.72, 0.93], [0, 16 * s, 0])), C.eye);
      m.add("Eyes", H(at(ball(0.05, 0.055, 0.03), [0.43 * s + 0.035, 2.8, 0.99])), C.white);
      m.add("Eyes", H(at(ball(0.022, 0.022, 0.02, 6), [0.43 * s - 0.04, 2.64, 0.985])), C.white);
    }
    m.bone("EyesShut", "Head", hj([0, 2.8, 0.95])); // happy closed arcs, hidden until used
    for (const s of [-1, 1]) m.add("EyesShut", H(tube([[0.28 * s, 2.68, 0.93], [0.43 * s, 2.79, 0.99], [0.58 * s, 2.68, 0.9]], 0.035, 6, 10)), C.cream);

    m.bone("EarL", "Head", hj([0.6, 3.36, 0]));
    m.add("EarL", H(at(ball(0.29, 0.33, 0.15), [0.64, 3.5, 0.02], [0, 0, -14])), C.tan);
    m.add("EarL", H(at(ball(0.28, 0.32, 0.16), [0.64, 3.5, -0.05], [0, 0, -14])), C.furDark);
    m.add("EarL", H(at(ball(0.18, 0.21, 0.1), [0.64, 3.49, 0.09], [0, 0, -14])), C.pink);
    m.mirror("EarL", "EarR");

    m.bone("ArmL", "Body", [0.58, 1.82, 0.05]);
    m.add("ArmL", limb([0.58, 1.82, 0.05], [0.92, 1.42, 0.12], 0.2, 0.18), C.cloak); // the shirt sleeve
    m.add("ArmL", at(ball(0.2, 0.07, 0.2, 10), [0.9, 1.44, 0.12], [0, 0, 40]), C.cream); // its frayed edge
    m.bone("ForeL", "ArmL", [0.92, 1.42, 0.12]);
    m.add("ForeL", limb([0.92, 1.42, 0.12], [1.02, 1.04, 0.28], 0.155, 0.17), C.fur);
    m.add("ForeL", at(lathe([[0.19, -0.07], [0.2, 0], [0.19, 0.07]], 12), [1.0, 1.12, 0.25], [20, 0, -14]), C.vest); // a leather cuff
    m.add("ForeL", at(ball(0.21, 0.19, 0.22), [1.03, 0.97, 0.32]), C.furDark);
    for (const dx of [-0.12, 0, 0.12]) m.add("ForeL", at(ball(0.075, 0.09, 0.08, 8), [1.03 + dx, 0.86, 0.44 - Math.abs(dx) * 0.3]), C.furDark);
    m.add("ForeL", at(ball(0.09, 0.05, 0.09, 8), [1.03, 0.84, 0.3]), C.pink);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");

    m.bone("LegL", "Hips", [0.32, 0.95, 0]);
    m.add("LegL", limb([0.32, 0.95, 0], [0.36, 0.32, 0.04], 0.23, 0.2), C.fur);
    m.add("LegL", at(ball(0.26, 0.17, 0.37), [0.37, 0.17, 0.2]), C.furDark);
    for (const dx of [-0.13, 0, 0.13]) m.add("LegL", at(ball(0.065, 0.055, 0.06, 8), [0.37 + dx, 0.2, 0.53 - Math.abs(dx) * 0.35]), C.pink); // toe beans
    m.mirror("LegL", "LegR");

    // the tail: five rings, bushy, with ragged tufts where the rings meet
    m.bone("Tail1", "Hips", [0, 0.95, -0.5]);
    m.add("Tail1", at(ball(0.27, 0.27, 0.3), [0, 1.02, -0.62]), C.fur);
    m.add("Tail1", at(ball(0.36, 0.34, 0.34), [0, 1.24, -0.93]), C.mask);
    for (let k = 0; k < 6; k++) { const a = (k / 6) * 6.283; m.add("Tail1", limb([Math.cos(a) * 0.2, 1.3 + Math.sin(a) * 0.2, -1.0], [Math.cos(a) * 0.36, 1.4 + Math.sin(a) * 0.36, -1.08], 0.14, 0.07, 8), C.mask); }
    m.bone("Tail2", "Tail1", [0, 1.4, -1.12]);
    m.add("Tail2", at(ball(0.42, 0.38, 0.38), [0, 1.58, -1.22]), C.fur);
    m.add("Tail2", at(ball(0.38, 0.36, 0.35), [0, 1.95, -1.4]), C.mask);
    m.add("Tail2", at(ball(0.28, 0.3, 0.27), [0, 2.28, -1.46]), C.cream);
    for (let k = 0; k < 6; k++) { const a = (k / 6) * 6.283; m.add("Tail2", limb([Math.cos(a) * 0.24, 1.7 + Math.sin(a) * 0.1, -1.28 + Math.sin(a) * 0.2], [Math.cos(a) * 0.42, 1.82 + Math.sin(a) * 0.12, -1.34 + Math.sin(a) * 0.36], 0.15, 0.07, 8), C.fur); }
    for (const [x, z] of [[-0.12, 0], [0.12, 0.04], [0, -0.1]]) m.add("Tail2", limb([x, 2.4, -1.46 + z], [x * 1.6, 2.6, -1.5 + z * 2], 0.12, 0.06, 8), C.cream);
    out.push(m);
  }

  // ---------- WoodSet: the camp on the near bank (three birches, the log seat, the fire) ----------
  {
    const m = model("WoodSet");
    m.bone("Ground", null, [0, 0, 0]);
    // (the three birches are now models from the CC0 nature kit: design3d/kit_import.py, KitBirch1-3)
    // the log seat and the campfire
    m.bone("Log", "Ground", [2.6, 0.55, 2.2]);
    m.add("Log", at(lathe([[0.02, -1.7], [0.5, -1.7], [0.62, -1.55], [0.64, 1.55], [0.5, 1.7], [0.02, 1.7]], 16), [2.6, 0.6, 2.2], [0, 28, 90]), C.wood);
    for (const e of [-1, 1]) {
      const p = [2.6 + e * 1.52, 0.6, 2.2 - e * 0.81];
      m.add("Log", at(ball(0.5, 0.5, 0.06), p, [0, 28 + 90, 0]), C.woodEnd);
      m.add("Log", at(ball(0.3, 0.3, 0.07), p, [0, 28 + 90, 0]), C.wood);
      m.add("Log", at(ball(0.12, 0.12, 0.08), p, [0, 28 + 90, 0]), C.woodEnd);
    }
    m.add("Log", at(ball(0.5, 0.12, 0.3), [2.3, 1.2, 2.4], [0, 28, 0]), C.moss);
    const onLog = (g) => at(g, [2.6, 0.6, 2.2], [0, 28, 90]); // log space: the axis is Y, the bark is at radius 0.64
    for (let k = 0; k < 9; k++) { const a = (k / 9) * 6.283 + 0.3, len = 0.7 + rnd(k + 700) * 1.5, y = -1.2 + rnd(k + 720) * 2.4 - len / 2; m.add("Log", onLog(at(ball(0.06, len / 2, 0.035, 8), [Math.cos(a) * 0.645, y + len / 2, Math.sin(a) * 0.645], [0, (-a * 180) / Math.PI + 90, 0])), C.woodDark); }
    m.add("Log", onLog(limb([0.5, 0.7, 0.2], [1.05, 0.95, 0.35], 0.16, 0.13, 8)), C.wood);
    m.add("Log", onLog(at(ball(0.13, 0.13, 0.04, 10), [1.07, 0.96, 0.36], [0, 15, -60])), C.woodEnd);
    for (const [y, r] of [[-0.9, 0.2], [-0.62, 0.13]]) { // mushrooms on the bark, near the end
      m.add("Log", onLog(limb([0.62, y, -0.1], [0.9, y, -0.14], 0.05, 0.045, 6)), C.cream);
      m.add("Log", onLog(at(ball(r, r * 0.6, r, 10), [0.94, y, -0.15], [0, 0, 90])), C.red);
      for (const dd of [-0.5, 0.5]) m.add("Log", onLog(at(ball(r * 0.22, r * 0.2, r * 0.22, 6), [0.94 + r * 0.5, y + dd * r, -0.15 + dd * r * 0.5])), C.cream);
    }
    m.bone("Fire", "Ground", [-0.6, 0, 3.0]);
    for (let i = 0; i < 9; i++) { // a ring of river stones, each a different size and tilt, soot on the inner side
      const a = (i / 9) * 6.283, w = 0.5 + rnd(i + 800) * 0.3;
      m.add("Fire", at(pillow(w, 0.34 + rnd(i + 810) * 0.2, 0.46, 0.6), [-0.6 + Math.cos(a) * 1.08, 0.16, 3.0 + Math.sin(a) * 1.08], [rnd(i + 820) * 16 - 8, (-a * 180) / Math.PI + 90, rnd(i + 830) * 12 - 6]), [C.stone, C.stoneDark, C.stoneLight][i % 3]);
      m.add("Fire", at(lo(w * 0.3, 0.1, 0.1), [-0.6 + Math.cos(a) * 0.86, 0.2, 3.0 + Math.sin(a) * 0.86], [0, (-a * 180) / Math.PI + 90, 0]), C.nose);
    }
    for (let i = 0; i < 4; i++) { const a = (i / 4) * 3.14159 + 0.3; m.add("Fire", limb([-0.6 - Math.cos(a) * 0.72, 0.1, 3.0 - Math.sin(a) * 0.72], [-0.6 + Math.cos(a) * 0.6, 0.42, 3.0 + Math.sin(a) * 0.6], 0.14, 0.11, 8), i % 2 ? C.woodDark : C.bark); }
    m.add("Fire", at(lo(0.6, 0.08, 0.6, 8, 4), [-0.6, 0.06, 3.0]), C.nose); // ash bed
    for (const [dx, dz] of [[1.9, 0.4], [2.1, 0.75], [1.95, 0.05]]) m.add("Fire", at(lathe([[0.02, -0.6], [0.14, -0.6], [0.15, 0.6], [0.02, 0.6]], 8), [-0.6 + dx, 0.16, 3.0 + dz], [0, 20 + dz * 30, 90]), C.wood); // split firewood, stacked by the ring
    const flame = (r, h, lean0 = 0.25) => { const lean = lean0 * 0.6; // a lick of fire: a teardrop that bends as it rises
      const pts = []; for (let k = 0; k <= 8; k++) { const u = k / 8; pts.push([Math.sin(u * 3.4) * lean * h * 0.35, u * h, Math.sin(u * 2.2 + 1) * lean * h * 0.12]); }
      return tube(pts, (u) => r * 1.25 * Math.sin(Math.PI * Math.pow(Math.min(u + 0.04, 1), 0.42)) * (1 - 0.3 * u) + 0.01, 18, 30);
    };
    m.bone("Flame1", "Fire", [-0.6, 0.3, 3.0], "Neon"); m.add("Flame1", at(flame(0.5, 1.7), [-0.6, 0.3, 3.0]), C.flame);
    m.bone("Flame2", "Fire", [-0.86, 0.3, 3.12], "Neon"); m.add("Flame2", at(flame(0.3, 1.05, -0.35), [-0.9, 0.3, 3.12], [0, 0, 10]), C.ember);
    m.bone("Flame3", "Fire", [-0.36, 0.3, 2.86], "Neon"); m.add("Flame3", at(flame(0.28, 0.9, 0.4), [-0.3, 0.3, 3.16], [0, 0, -12]), C.flame);
    m.bone("FlameCore", "Fire", [-0.6, 0.32, 3.06], "Neon"); m.add("FlameCore", at(flame(0.26, 1.0, 0.2), [-0.6, 0.32, 3.2]), C.flameCore);
    m.add("FlameCore", at(flame(0.14, 0.55, -0.3), [-0.8, 0.32, 3.26]), C.flameCore);
    out.push(m);
  }

  // ---------- WoodWorld: the ground itself. Two painted height fields and their mirror images for the lake ----------
  {
    const m = model("WoodWorld");
    const L = terrain.lakeY, nr = terrain.near, fr = terrain.far, n = nr.h.length - 1;
    // the meadow: 2.3-stud cells; the middle of the lake is left open so the mirror world shows through the water
    const hole = (i, j) => nr.d[j][i] < -4 && nr.d[j][i + 1] < -4 && nr.d[j + 1][i] < -4 && nr.d[j + 1][i + 1] < -4;
    m.bone("Meadow", null, [0, 0, 0], "SmoothPlastic", "tex/wood_meadow.png");
    m.addTex("Meadow", field(nr.rect[0], nr.rect[1], nr.rect[2], nr.rect[3], nr.h, hole));
    // the valley and its mountains: 20-stud cells, open where the meadow lies over it
    const cw = (fr.rect[2] - fr.rect[0]) / n, cd = (fr.rect[3] - fr.rect[1]) / n;
    const under = (i, j) => { const x0 = fr.rect[0] + i * cw, z0 = fr.rect[1] + j * cd; return x0 > nr.rect[0] + 3 && x0 + cw < nr.rect[2] - 3 && z0 > nr.rect[1] + 3 && z0 + cd < nr.rect[3] - 3; };
    m.bone("Valley", null, [0, 0, 0], "SmoothPlastic", "tex/wood_valley.png");
    m.addTex("Valley", field(fr.rect[0], fr.rect[1], fr.rect[2], fr.rect[3], fr.h, under));
    // the same two, upside down below the water line: what the lake reflects
    m.bone("MeadowM", null, [0, 0, 0], "SmoothPlastic", "tex/wood_meadow.png");
    m.addTex("MeadowM", mirrorY(field(nr.rect[0], nr.rect[1], nr.rect[2], nr.rect[3], nr.h, (i, j) => hole(i, j) || nr.h[j][i] < L + 0.2), L));
    m.bone("ValleyM", null, [0, 0, 0], "SmoothPlastic", "tex/wood_valley.png");
    m.addTex("ValleyM", mirrorY(field(fr.rect[0], fr.rect[1], fr.rect[2], fr.rect[3], fr.h, (i, j) => under(i, j) || fr.rect[1] + j * cd > -100), L));
    out.push(m);
  }

  // ---------- Cabin: the maker's home across the water. Remade 2026-11-15 from its reference sheets (refs/forge/sheets/
  // cabin_views, cabin_materials): every material is its own bone with a tiling picture (design3d/cabin_tex.py): peeled round
  // logs with end grain, a standing-seam metal roof, fieldstone, deck planks; frames, flowers and brass stay in the palette. ----------
  {
    const m = model("Cabin");
    const TAU = Math.PI * 2;
    m.bone("Logs", null, [0, 0, 0], "SmoothPlastic", "tex/cabin_logs.png");
    m.bone("Ends", "Logs", [0, 0, 0], "SmoothPlastic", "tex/cabin_ends.png");
    m.bone("Roof", "Logs", [0, 8, 0], "SmoothPlastic", "tex/cabin_roof.png");
    m.bone("Stone", "Logs", [0, 0, 0], "SmoothPlastic", "tex/cabin_stone.png");
    m.bone("Planks", "Logs", [0, 0, 0], "SmoothPlastic", "tex/cabin_planks.png");
    m.bone("Trim", "Logs", [0, 0, 0]);
    const uvOf = (g, fn) => { const p = g.getAttribute("position"), n = g.getAttribute("normal"), uv = new Float32Array(p.count * 2); for (let i = 0; i < p.count; i++) { const [u, v] = fn(p.getX(i), p.getY(i), p.getZ(i), n.getX(i), n.getY(i), n.getZ(i)); uv[2 * i] = u; uv[2 * i + 1] = v; } g.setAttribute("uv", new THREE.BufferAttribute(uv, 2)); return g; };
    // box mapping in the piece's own space, before it is placed: one tile of the picture covers `tile` studs
    const boxUV = (g, tile) => uvOf(g, (x, y, z, nx, ny, nz) => { const ax = Math.abs(nx), ay = Math.abs(ny), az = Math.abs(nz); return ay >= ax && ay >= az ? [x / tile, z / tile] : ax >= az ? [z / tile, y / tile] : [x / tile, y / tile]; });
    const slab = (w, h, d, tile, p, r = [0, 0, 0]) => at(boxUV(new THREE.BoxGeometry(w, h, d), tile), p, r); // a flat-faced board or sheet
    const lump = (w, h, d, tile, p, r = [0, 0, 0], e = 0.45) => at(boxUV(pillow(w, h, d, e, 5), tile), p, r); // a rounded stone
    const box = (w, h, d, p, r = [0, 0, 0], e = 0.16) => at(pillow(w, h, d, e, 4), p, r); // palette trim
    // a peeled log from p0 to p1: the picture runs along it, twice round it (dark where it meets the logs above and below)
    let logN = 0;
    const log = (p0, p1, r, ends = true, seg = 12) => {
      const A = new THREE.Vector3(...p0), B = new THREE.Vector3(...p1), ax = B.clone().sub(A), len = ax.length(); ax.normalize();
      const ref = Math.abs(ax.y) > 0.9 ? new THREE.Vector3(0, 0, 1) : new THREE.Vector3(0, -1, 0);
      const side = new THREE.Vector3().crossVectors(ax, ref).normalize(), down = new THREE.Vector3().crossVectors(side, ax).normalize();
      const pos = [], nor = [], uv = [], idx = [], uoff = (logN++ * 0.37) % 1;
      for (let i = 0; i <= 1; i++) for (let k = 0; k <= seg; k++) {
        const a = (k / seg) * TAU, n = down.clone().multiplyScalar(Math.cos(a)).add(side.clone().multiplyScalar(Math.sin(a))), c = (i ? B : A).clone().add(n.clone().multiplyScalar(r));
        pos.push(c.x, c.y, c.z); nor.push(n.x, n.y, n.z); uv.push(uoff + (i * len) / 4, k / seg);
      }
      for (let k = 0; k < seg; k++) { const a = k, b = k + 1, c = seg + 1 + k, d = c + 1; idx.push(a, b, c, b, d, c); }
      const g = new THREE.BufferGeometry();
      g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3)); g.setAttribute("normal", new THREE.Float32BufferAttribute(nor, 3)); g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2)); g.setIndex(idx);
      // outward faces: turn the triangles if the first one looks inward
      const pa = new THREE.Vector3(pos[0], pos[1], pos[2]), pb = new THREE.Vector3(pos[3], pos[4], pos[5]), pc = new THREE.Vector3(pos[(seg + 1) * 3], pos[(seg + 1) * 3 + 1], pos[(seg + 1) * 3 + 2]);
      if (pb.clone().sub(pa).cross(pc.clone().sub(pa)).dot(new THREE.Vector3(nor[0], nor[1], nor[2])) < 0) for (let i = 0; i < idx.length; i += 3) { const t = idx[i]; idx[i] = idx[i + 1]; idx[i + 1] = t; }
      g.setIndex(idx);
      m.addTex("Logs", g);
      if (ends) for (const [P, s] of [[A, -1], [B, 1]]) { // end grain discs
        const ep = [], en = [], eu = [], ei = [];
        ep.push(P.x + ax.x * s * 0.01, P.y + ax.y * s * 0.01, P.z + ax.z * s * 0.01); en.push(ax.x * s, ax.y * s, ax.z * s); eu.push(0.5, 0.5);
        for (let k = 0; k <= seg; k++) { const a = (k / seg) * TAU, n = down.clone().multiplyScalar(Math.cos(a)).add(side.clone().multiplyScalar(Math.sin(a))), c = P.clone().add(n.multiplyScalar(r)).add(ax.clone().multiplyScalar(s * 0.01)); ep.push(c.x, c.y, c.z); en.push(ax.x * s, ax.y * s, ax.z * s); eu.push(0.5 + Math.cos(a) * 0.46, 0.5 + Math.sin(a) * 0.46); }
        for (let k = 1; k <= seg; k++) ei.push(0, k, k + 1);
        const p1v = new THREE.Vector3(ep[3], ep[4], ep[5]).sub(P), p2v = new THREE.Vector3(ep[6], ep[7], ep[8]).sub(P);
        if (p1v.cross(p2v).dot(ax) * s < 0) for (let i = 0; i < ei.length; i += 3) { const t = ei[i + 1]; ei[i + 1] = ei[i + 2]; ei[i + 2] = t; }
        const eg = new THREE.BufferGeometry();
        eg.setAttribute("position", new THREE.Float32BufferAttribute(ep, 3)); eg.setAttribute("normal", new THREE.Float32BufferAttribute(en, 3)); eg.setAttribute("uv", new THREE.Float32BufferAttribute(eu, 2)); eg.setIndex(ei);
        m.addTex("Ends", eg);
      }
    };
    const X0 = -4.2, X1 = 4.2, Z0 = -3.6, Z1 = 3.6, WALL = 7.4, BASE = 0.7, LR = 0.47, CS = 0.84; // compact and two storeys, thick logs, as on the reference sheet
    // fieldstone footing: large stones under every wall
    for (let k = 0; k < 10; k++) { const front = k % 2 === 0; m.addTex("Stone", lump(2.0, 0.9, 1.1, 4.5, [X0 + 0.8 + (k >> 1) * 1.7, 0.36, front ? Z1 - 0.1 : Z0 + 0.1], [0, rnd(k + 60) * 10 - 5, 0])); }
    for (let k = 0; k < 5; k++) for (const xs of [X0 + 0.1, X1 - 0.1]) m.addTex("Stone", lump(1.1, 0.9, 1.8, 4.5, [xs, 0.36, Z0 + 0.8 + k * 1.4], [0, rnd(k + 70) * 10 - 5, 0]));
    // log walls: courses of peeled logs, the side walls half a course higher so the ends cross at the corners
    const courses = Math.round((WALL - BASE) / CS);
    for (let k = 0; k < courses; k++) {
      const y = BASE + CS / 2 + k * CS, over = 0.7 + rnd(k + 80) * 0.3;
      for (const z of [Z0, Z1]) log([X0 - over, y, z], [X1 + over, y, z], LR);
      for (const x of [X0, X1]) log([x, y + CS / 2, Z0 - over], [x, y + CS / 2, Z1 + over], LR);
    }
    const RIDGE = 12.2, EAVE = WALL + 0.2;
    for (let k = 0; k < 6; k++) { const y = WALL + CS / 2 + k * CS, half = ((Z1 - Z0) / 2) * (1 - (y - WALL) / (RIDGE - WALL)); if (half > 0.3) for (const x of [X0, X1]) log([x, y, -half - 0.1], [x, y, half + 0.1], LR, false); }
    // purlins poke out under the eaves: three round beams along the ridge line
    for (const [y, z] of [[RIDGE - 0.15, 0], [9.9, -1.8], [9.9, 1.8]]) log([X0 - 1.0, y, z], [X1 + 1.0, y, z], 0.24);
    // roof: two metal slopes with deep eaves and a dark fascia board, a ridge cap
    const run = (Z1 - Z0) / 2 + 1.3, rise = RIDGE - EAVE + 1.0, slopeLen = Math.hypot(run, rise), pitch = (Math.atan2(rise, run) * 180) / Math.PI;
    for (const s of [-1, 1]) {
      const mid = [(X0 + X1) / 2, RIDGE - rise / 2 + 0.25, (s * run) / 2];
      m.addTex("Roof", slab(X1 - X0 + 2.6, 0.22, slopeLen, 7.5, mid, [s * pitch, 0, 0]));
      m.addTex("Planks", slab(X1 - X0 + 2.6, 0.3, 0.22, 3, [mid[0], EAVE - 0.72, s * (run - 0.02)], [s * pitch, 0, 0])); // fascia
    }
    m.addTex("Roof", at(boxUV(new THREE.CylinderGeometry(0.22, 0.22, X1 - X0 + 2.7, 8), 4), [(X0 + X1) / 2, RIDGE + 0.5, 0], [0, 0, 90]));
    // the dormer over the left windows
    const DX = 0, DW = 1.5, DZ = 1.9, DR = 11.1;
    for (let k = 0; k < 5; k++) { log([DX - DW, DR - 2.95 + k * 0.5, DZ + 1.5], [DX + DW, DR - 2.95 + k * 0.5, DZ + 1.5], 0.24); for (const s of [-1, 1]) log([DX + s * DW, DR - 2.7 + k * 0.5, DZ - 1.0], [DX + s * DW, DR - 2.7 + k * 0.5, DZ + 1.7], 0.24, k > 2); }
    for (const s of [-1, 1]) m.addTex("Roof", slab(2.4, 0.14, 3.9, 4, [DX + s * 0.92, DR - 0.42, DZ - 0.1], [0, 0, -s * 38]));
    m.addTex("Roof", at(boxUV(new THREE.CylinderGeometry(0.16, 0.16, 3.9, 8), 4), [DX, DR + 0.5, DZ - 0.1], [90, 0, 0]));
    // stone chimney: big stones below, smaller above, a cap, and a clay pot
    for (let k = 0; k < 14; k++) { const y = 0.6 + k * 1.02, w = k < 5 ? 2.3 : 1.7; for (const dx of [-0.42, 0.42]) m.addTex("Stone", lump(w * 0.56 + rnd(k + 900) * 0.14, 1.04, w * 0.84, 4.5, [2.0 + dx * (w / 1.9) + (k % 2) * 0.1, y, -1.4], [0, rnd(k * 2 + 920 + dx) * 8 - 4, 0])); }
    m.addTex("Stone", lump(2.2, 0.34, 1.9, 2.4, [2.0, 15.0, -1.4], [0, 0, 0], 0.3));
    // the porch on the right: deck, posts, rail, lean-to roof, steps
    const PX0 = X1, PX1 = X1 + 3.9;
    m.addTex("Planks", slab(PX1 - PX0 + 0.4, 0.22, 6.4, 3, [(PX0 + PX1) / 2, 1.0, 1.6]));
    for (const px of [PX0 + 0.4, PX0 + 2.0, PX1 - 0.2]) log([px, 0.2, 4.5], [px, 5.0, 4.5], 0.19, false);
    log([PX1 - 0.2, 0.2, -1.4], [PX1 - 0.2, 5.0, -1.4], 0.19, false);
    log([PX0 + 0.1, 5.0, 4.5], [PX1 + 0.1, 4.2, 4.5], 0.17); // the porch beam
    log([PX0 + 2.0, 2.3, 4.5], [PX1 - 0.2, 2.3, 4.5], 0.11, false);
    for (let k = 0; k < 3; k++) m.addTex("Planks", slab(0.1, 1.2, 0.1, 3, [PX0 + 2.3 + k * 0.48, 1.7, 4.5])); // balusters
    log([PX1 - 0.2, 2.3, 4.5], [PX1 - 0.2, 2.3, -1.4], 0.11, false);
    m.addTex("Roof", slab(PX1 - PX0 + 1.4, 0.14, 7.8, 4, [(PX0 + PX1) / 2 + 0.3, 5.5, 1.5], [0, 0, -9]));
    for (let k = 0; k < 2; k++) m.addTex("Planks", slab(2.2, 0.3, 0.8, 3, [PX0 + 1.35, 0.72 - k * 0.36, 5.0 + k * 0.7]));
    // a woodshed on the left end with split firewood (end grain out)
    m.addTex("Roof", slab(3.4, 0.14, 5.2, 4, [X0 - 2.0, 3.9, 0.6], [0, 0, 14]));
    for (const z of [-1.6, 2.8]) log([X0 - 3.4, 0.2, z], [X0 - 3.4, 3.5, z], 0.17, false);
    for (let r = 0; r < 4; r++) for (let k = 0; k < 6; k++) log([X0 - 2.6, 0.5 + r * 0.42, -1.2 + k * 0.72 + (r % 2) * 0.2], [X0 - 1.2, 0.5 + r * 0.42, -1.2 + k * 0.72 + (r % 2) * 0.2], 0.2, true, 7);
    // the door: planks with two iron straps and a brass latch
    m.addTex("Planks", slab(1.7, 3.3, 0.2, 3, [0, 2.55, Z1 + 0.52]));
    for (const y of [1.6, 3.4]) m.add("Trim", box(1.6, 0.14, 0.08, [0, y, Z1 + 0.64], [0, 0, 0], 0.3), C.roofDark);
    m.add("Trim", at(lo(0.1, 0.1, 0.1), [0.6, 2.5, Z1 + 0.68]), C.brass);
    // windows: frames, mullions, shutters and a flower box (the panes are the Glow bone)
    const wins = [[-2.75, 2.9, 0.85, 1.6], [2.75, 2.9, 0.85, 1.6], [-2.3, 5.9, 0.8, 1.3], [2.3, 5.9, 0.8, 1.3], [DX, DR - 1.75, 0.8, 1.1]]; // x, y, half width, height
    for (const [x, y, hw, hh] of wins) {
      const zf = x === DX ? DZ + 1.82 : Z1 + 0.6;
      for (const s of [-1, 1]) m.add("Trim", box(0.22, hh + 0.34, 0.24, [x + s * hw, y, zf], [0, 0, 0], 0.3), C.logEnd);
      for (const s of [-1, 1]) m.add("Trim", box(hw * 2 + 0.36, 0.22, 0.28, [x, y + (s * hh) / 2, zf], [0, 0, 0], 0.3), C.logEnd);
      m.add("Trim", box(0.17, hh, 0.2, [x, y, zf + 0.04], [0, 0, 0], 0.3), C.bark); m.add("Trim", box(hw * 2, 0.17, 0.2, [x, y, zf + 0.04], [0, 0, 0], 0.3), C.bark);
      if (x !== DX) for (const s of [-1, 1]) m.addTex("Planks", slab(0.7, hh + 0.2, 0.1, 3, [x + s * (hw + 0.5), y, zf - 0.04], [0, s * 14, 0])); // shutters, a little open
    }
    for (const x of [-2.75, 2.75]) { m.addTex("Planks", slab(2.3, 0.4, 0.5, 3, [x, 1.75, Z1 + 0.88])); for (let k = 0; k < 6; k++) { m.add("Trim", at(lo(0.2, 0.17, 0.2, 6, 4), [x - 0.9 + k * 0.36, 2.09 + (k % 2) * 0.08, Z1 + 0.9]), [C.petal, C.red, C.petalPale, C.petalDeep, C.red, C.cream][k]); m.add("Trim", at(lo(0.22, 0.1, 0.22, 6, 4), [x - 0.9 + k * 0.36, 1.95, Z1 + 0.9]), C.grassDark); } }
    m.add("Trim", limb([PX0 + 0.3, 4.4, 4.3], [PX0 + 0.3, 3.9, 4.3], 0.03, 0.03, 4), C.nose); // the porch lantern's hook
    m.add("Trim", at(lathe([[0.02, 0.26], [0.2, 0.2], [0.24, 0.3], [0.02, 0.5]], 8), [PX0 + 0.3, 3.74, 4.3]), C.roofDark); // and its cap
    m.bone("Glow", "Logs", [0, 3, Z1], "Neon");
    for (const [x, y, hw, hh] of wins) m.add("Glow", at(pillow(hw * 2, hh, 0.1, 0.15, 6), [x, y, x === DX ? DZ + 1.76 : Z1 + 0.54]), C.glow);
    m.add("Glow", at(pillow(0.8, 0.7, 0.1, 0.2, 6), [0, 3.5, Z1 + 0.64]), C.glow); // the door's glass
    m.add("Glow", at(lo(0.2, 0.26, 0.2, 8, 6), [PX0 + 0.3, 3.56, 4.3]), C.glow); // the porch lantern
    // the reflection: the house upside down from its own footing, and the lights drawn out long, as on still water
    m.bone("Mirror", null, [0, 0, 0]);
    m.add("Mirror", at(pillow(X1 - X0 + 1, WALL, Z1 - Z0 + 1, 0.12, 6), [(X0 + X1) / 2, -WALL / 2, 0]), C.log);
    for (const s of [-1, 1]) m.add("Mirror", at(pillow(X1 - X0 + 2.2, 0.3, slopeLen, 0.1, 6), [(X0 + X1) / 2, -(RIDGE - rise / 2 + 0.2), (s * run) / 2], [-s * pitch, 0, 0]), C.roofDark);
    m.add("Mirror", at(pillow(1.7, 15, 1.4, 0.3, 6), [2.0, -7.6, -1.4]), C.stoneDark);
    m.add("Mirror", at(pillow(PX1 - PX0 + 1.2, 0.3, 7.6, 0.1, 6), [(PX0 + PX1) / 2 + 0.3, -5.5, 1.5], [0, 0, 9]), C.roofDark);
    m.bone("MirrorGlow", "Mirror", [0, -3, Z1], "Neon");
    for (const [x, y, hw, hh] of wins) m.add("MirrorGlow", at(pillow(hw * 1.9, hh * 7.5, 0.1, 0.6, 6), [x, -y - hh * 3.4, x === DX ? DZ + 1.76 : Z1 + 0.54]), C.glow);
    m.add("MirrorGlow", at(pillow(0.5, 8, 0.1, 0.6, 6), [PX0 + 0.3, -8, 4.3]), C.glow);
    out.push(m);
  }

  // ---------- Dock: a small plank dock on posts with a lantern at its end and a rowboat tied beside it (root at the water line) ----------
  {
    const m = model("Dock"), geos = [];
    const add = (g, c) => { m.add("Dock", g, c); geos.push([g, c]); };
    m.bone("Dock", null, [0, 0, 0]);
    const bx = (w, h, d, p, r = [0, 0, 0]) => at(pillow(w, h, d, 0.2, 4), p, r);
    for (let k = 0; k < 12; k++) add(bx(3.0, 0.16, 0.86, [0, 0.9 + (k % 3) * 0.015, 0.5 + k * 0.92], [0, (k % 2) * 2 - 1, 0]), k % 3 === 1 ? C.logLight : C.log);
    for (const z of [0.6, 4.2, 7.8, 11.2]) for (const x of [-1.5, 1.5]) add(limb([x, -1.6, z], [x, 1.25, z], 0.17, 0.15, 6), C.bark);
    for (const x of [-1.5, 1.5]) add(limb([x, 0.72, 0.4], [x, 0.72, 11.4], 0.09, 0.09, 4), C.bark);
    add(limb([1.5, 1.2, 11.2], [1.5, 3.9, 11.2], 0.11, 0.09, 6), C.bark); // the lantern post and its arm
    add(limb([1.5, 3.8, 11.2], [0.7, 3.95, 11.2], 0.06, 0.05, 4), C.bark);
    add(at(lathe([[0.02, 0.26], [0.22, 0.2], [0.26, 0.3], [0.02, 0.5]], 8), [0.7, 3.3, 11.2]), C.roofDark);
    // the rowboat: a round hull, two thwarts, an oar laid across
    const hull = []; for (let k = 0; k <= 12; k++) { const u = k / 12, a = u * Math.PI; hull.push([Math.cos(a) * 2.6, -Math.sin(a) * 0.9]); }
    add(at(puff(hull.map(([x, y]) => [x, y]), 1.5, 0.3), [-3.3, 0.5, 6.4], [0, 90, 0]), C.logLight);
    add(at(puff(hull.map(([x, y]) => [x * 0.86, y * 0.72]), 1.1, 0.2), [-3.3, 0.62, 6.4], [0, 90, 0]), C.log);
    for (const z of [5.4, 7.4]) add(bx(1.7, 0.12, 0.4, [-3.3, 0.5, z]), C.logEnd);
    add(limb([-4.2, 0.62, 4.6], [-2.4, 0.66, 8.2], 0.05, 0.05, 4), C.logEnd);
    add(tube([[-2.4, 0.5, 5.0], [-1.9, 0.3, 4.9], [-1.5, 0.95, 4.3]], 0.03, 4, 6), C.cream); // its painter, tied to a post
    m.bone("Lamp", "Dock", [0.7, 3.3, 11.2], "Neon");
    m.add("Lamp", at(lo(0.2, 0.24, 0.2, 8, 6), [0.7, 3.14, 11.2]), C.glow);
    m.bone("Mirror", null, [0, 0, 0]);
    for (const [g, c] of geos) m.add("Mirror", mirrorY(g, 0), c);
    m.bone("MirrorGlow", "Mirror", [0.7, -3.3, 11.2], "Neon");
    m.add("MirrorGlow", at(pillow(0.46, 3.6, 0.3, 0.6, 6), [0.7, -4.6, 11.2]), C.glow);
    out.push(m);
  }

  // (the spruces, rocks, flowers, grass, fern and bush come from the CC0 nature kit: design3d/kit_import.py)
  // ---------- PineClump: a stand of small spruces for the far slopes (they stand on the painted forest and give it an edge) ----------
  {
    const m = model("PineClump");
    m.bone("Clump", null, [0, 0, 0]);
    for (let i = 0; i < 30; i++) {
      const x = (rnd(i + 1000) - 0.5) * 84, z = (rnd(i + 1010) - 0.5) * 60, h = 17 + rnd(i + 1020) * 15, w = h * 0.2;
      m.add("Clump", at(lathe([[0.5, 0], [0.3, h * 0.5]], 4), [x, 0, z]), C.bark);
      for (let t = 0; t < 5; t++) { const u = t / 5; m.add("Clump", at(lathe([[w * (1 - u * 0.78), 0], [w * (1 - u * 0.78) * 0.5, h * 0.12], [0.05, h * 0.3]], 6), [x, h * (0.12 + u * 0.66), z], [0, i * 40 + t * 30, 0]), [C.sp1, C.sp2, C.sp1, C.sp3, C.spTip][(i + t) % 5]); }
    }
    out.push(m);
  }

  {
    const m = model("Lightning");
    m.bone("Bolt", null, [0, 0, 0], "Neon");
    m.add("Bolt", puff([[0.6, 0], [1.5, 0], [0.5, -3.4], [1.3, -3.4], [0.2, -6.2], [0.9, -6.2], [-0.9, -10.6], [-0.2, -7.0], [-0.9, -7.0], [-0.1, -4.4], [-0.9, -4.4]], 0.08, 0.04, false), C.bolt);
    out.push(m);
  }

  // ---------- props ----------
  {
    const m = model("BirchBranch");
    m.bone("Branch", null, [0, 0, 0]);
    m.add("Branch", tube([[-1.9, 0.0, 0], [-0.9, 0.12, 0.04], [0.2, 0.05, -0.03], [1.2, 0.2, 0.02], [2.1, 0.12, 0]], (t) => 0.24 - 0.09 * t, 10, 24), C.birch);
    for (const [x, a] of [[-1.2, 20], [-0.2, 200], [0.7, 110], [1.5, 300]]) m.add("Branch", at(ball(0.16, 0.05, 0.07), [x, 0.06 + Math.cos((a * Math.PI) / 180) * 0.2, Math.sin((a * Math.PI) / 180) * 0.2], [a, 0, 0]), C.birchMark);
    m.add("Branch", limb([0.5, 0.1, 0], [1.0, 0.75, 0.25], 0.09, 0.05, 6), C.birch);
    m.add("Branch", limb([-0.6, 0.1, 0], [-0.95, 0.6, -0.3], 0.08, 0.045, 6), C.birch);
    m.add("Branch", at(ball(0.24, 0.24, 0.05), [-1.92, 0, 0], [0, 90, 0]), C.woodEnd); // the snapped end
    m.bone("Leaves", "Branch", [1.0, 0.75, 0.25]);
    const leaf = () => puff([[0, 0], [0.26, 0.2], [0.3, 0.52], [0, 0.9], [-0.3, 0.52], [-0.26, 0.2]], 0.05, 0.04);
    m.add("Leaves", at(leaf(), [1.0, 0.75, 0.25], [10, 20, -30]), C.leaf);
    m.add("Leaves", at(leaf(), [1.05, 0.7, 0.25], [-20, -10, -80], 0.85), C.leafLight);
    m.add("Leaves", at(leaf(), [-0.95, 0.6, -0.3], [0, 40, 40], 0.9), C.leaf);
    m.add("Leaves", at(leaf(), [2.1, 0.12, 0], [0, 0, -70], 0.8), C.butter);
    out.push(m);
  }
  {
    // WoodBlank: the half-carved pickaxe. Head up along +Y, crescent arms along X; bark still on the lower handle.
    const m = model("WoodBlank");
    m.bone("Blank", null, [0, 0, 0]);
    m.add("Blank", limb([0, -2.5, 0], [0, 1.3, 0], 0.17, 0.15, 10), C.birchShade);
    m.add("Blank", limb([0, -2.5, 0], [0, -0.9, 0], 0.22, 0.21, 10), C.birch);
    for (const [y, a] of [[-2.1, 30], [-1.5, 190], [-1.1, 100]]) m.add("Blank", at(ball(0.15, 0.05, 0.07), [Math.sin((a * Math.PI) / 180) * 0.21, y, Math.cos((a * Math.PI) / 180) * 0.21], [0, a, 0]), C.birchMark);
    const cres = [], N = 16; // a crescent that tapers to two points, thick in the middle like the finished head
    for (let k = 0; k <= N; k++) { const u = k / N, a = Math.PI * (0.04 + 0.92 * u); cres.push([Math.cos(a) * 2.15, Math.sin(a) * 1.0 - 0.35]); }
    for (let k = N - 1; k >= 1; k--) { const u = k / N, a = Math.PI * (0.04 + 0.92 * u); cres.push([Math.cos(a) * 2.15, Math.sin(a) * 1.0 - 0.35 - 0.62 * Math.pow(Math.sin(Math.PI * u), 0.7)]); }
    m.add("Blank", at(puff(cres, 0.36, 0.14, false), [0, 1.35, 0]), C.woodEnd);
    for (const s of [-1, 1]) m.add("Blank", at(pillow(0.34, 0.22, 0.4, 0.5), [0.9 * s, 1.72, 0.0], [0, 0, -24 * s]), C.birchShade); // uncut facets
    m.add("Blank", at(ball(0.3, 0.26, 0.3), [0, 1.42, 0]), C.birchShade);
    out.push(m);
  }
  {
    const m = model("Shaving");
    m.bone("Curl", null, [0, 0, 0]);
    const pts = []; for (let k = 0; k <= 18; k++) { const a = (k / 18) * Math.PI * 3.2, r = 0.2 - 0.006 * k; pts.push([Math.cos(a) * r, k * 0.028, Math.sin(a) * r]); }
    const curve = new THREE.CatmullRomCurve3(pts.map((p) => new THREE.Vector3(...p)));
    const g = new THREE.TubeGeometry(curve, 36, 0.075, 8, false); g.computeVertexNormals();
    m.add("Curl", at(g, [0, 0, 0], [0, 0, 0], [1, 1, 0.8]), C.woodEnd);
    out.push(m);
  }
  {
    const m = model("Acorn");
    m.bone("Acorn", null, [0, 0, 0]);
    m.add("Acorn", lathe([[0.02, -0.42], [0.16, -0.36], [0.28, -0.15], [0.3, 0.05], [0.26, 0.16], [0.02, 0.18]], 14), C.acorn);
    m.add("Acorn", lathe([[0.33, 0.04], [0.35, 0.14], [0.26, 0.3], [0.1, 0.37], [0.02, 0.38]], 14), C.acornCap);
    m.add("Acorn", limb([0, 0.36, 0], [0.05, 0.54, 0], 0.045, 0.035, 6), C.acornCap);
    m.add("Acorn", at(ball(0.06, 0.1, 0.03), [-0.13, -0.08, 0.26], [0, -25, 15]), C.woodEnd);
    out.push(m);
  }
  {
    const m = model("Knife");
    m.bone("Knife", null, [0, 0, 0]);
    m.add("Knife", limb([0, -0.42, 0], [0, 0.0, 0], 0.085, 0.08, 8), C.woodDark);
    m.add("Knife", at(ball(0.12, 0.05, 0.1), [0, 0.02, 0]), C.red);
    m.add("Knife", at(puff([[-0.08, 0], [0.09, 0], [0.11, 0.42], [0.02, 0.72], [-0.08, 0.5]], 0.03, 0.025), [0, 0.04, 0]), C.steel);
    out.push(m);
  }
  {
    const m = model("Leaf");
    m.bone("Leaf", null, [0, 0, 0]);
    m.add("Leaf", at(puff([[0, 0], [0.24, 0.18], [0.28, 0.48], [0, 0.84], [-0.28, 0.48], [-0.24, 0.18]], 0.05, 0.04), [0, -0.4, 0]), C.leaf);
    m.add("Leaf", limb([0, -0.62, 0], [0, 0.2, 0.03], 0.03, 0.02, 5), C.grassDark);
    out.push(m);
  }
  return out;
}
