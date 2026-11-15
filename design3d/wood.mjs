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
  fur: "#8f8aa6", furDark: "#5b5272", furLight: "#b9b4cc", mask: "#33283f", cream: "#f6f0fa", pink: "#f4a9c2", nose: "#2a1f36", eye: "#1d1528", white: "#ffffff",
  red: "#e8525a", redDark: "#c23c4c", cloak: "#2f5d6b", cloakLight: "#4a8090", cloakDark: "#234854", brass: "#e2b65a",
  grassDark: "#4f7f58", grassDeep: "#3f6a4c", grass: "#6f9a5a", grassLight: "#8fb46a",
  birch: "#f3ede2", birchShade: "#d8cdc6", birchMark: "#3d3344", leaf: "#8fc878", leafLight: "#b7de8c", leafDark: "#5e9a5c", butter: "#f7e6a2",
  stone: "#8d8c92", stoneDark: "#66666e", stoneLight: "#a9a8ac", moss: "#5f8a4c", wood: "#c99a6b", woodDark: "#9a6d4d", woodEnd: "#f0d7a8",
  flame: "#ff7a1c", flameCore: "#ffc24a", ember: "#e8421c", bolt: "#fff7d0",
  steel: "#dfe3f5", acorn: "#c98f5a", acornCap: "#8a5d44",
  sp1: "#1c3733", sp2: "#234539", sp3: "#2c5442", spTip: "#3f6f52", bark: "#4a3a34", barkLight: "#63504a",
  log: "#5c4434", logLight: "#735640", logEnd: "#a07c58", roof: "#565a62", roofLight: "#6e737c", roofDark: "#3e4148", glow: "#ffb44a", glowHot: "#ffd98a",
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
    m.add("Body", at(ball(0.47, 0.52, 0.3), [0, 1.28, 0.43]), C.cream);
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
      for (const [y, l, dy, c] of [[2.74, 0.24, 0.02, C.fur], [2.46, 0.22, -0.1, C.furLight]]) m.add("Head", H(limb([0.7 * s, y, 0.12], [(0.84 + l) * s, y + dy, 0.08], 0.34, 0.17, 12)), c); // two soft lobes a side, not spikes
      m.add("Head", H(at(ball(0.44, 0.31, 0.2), [0.42 * s, 2.74, 0.76], [0, 18 * s, 10 * s])), C.mask); // the mask
      m.add("Head", H(at(ball(0.3, 0.1, 0.12), [0.4 * s, 3.08, 0.72], [0, 16 * s, 10 * s])), C.cream); // brow
      m.add("Head", H(at(ball(0.13, 0.1, 0.05), [0.7 * s, 2.46, 0.7], [0, 30 * s, 0])), C.pink); // blush
    }
    m.add("Head", H(at(ball(0.2, 0.14, 0.1), [0, 2.8, 0.9])), C.mask); // the mask joins over the nose
    for (const [x, a] of [[-0.22, 12], [0, 0], [0.22, -12]]) m.add("Head", H(at(ball(0.06, 0.2, 0.07, 8), [x, 3.36, 0.6], [-38, 0, a])), C.furDark); // forehead stripes
    m.add("Head", H(at(ball(0.36, 0.26, 0.28), [0, 2.44, 0.84])), C.cream); // muzzle
    m.add("Head", H(at(ball(0.11, 0.08, 0.08), [0, 2.54, 1.1])), C.nose);
    m.add("Head", H(tube([[-0.11, 2.4, 1.07], [-0.05, 2.36, 1.1], [0, 2.39, 1.11], [0.05, 2.36, 1.1], [0.11, 2.4, 1.07]], 0.022, 6, 12)), C.nose);
    m.add("Head", H(at(ball(0.3, 0.16, 0.2), [0.06, 3.6, 0.2], [0, 0, -12])), C.furLight); // one soft curl of fur on the crown
    m.bone("Eyes", "Head", hj([0, 2.8, 0.9]));
    for (const s of [-1, 1]) { // the reference's eyes: tall dark ovals, wide apart, one big light and one small
      m.add("Eyes", H(at(ball(0.125, 0.19, 0.07), [0.43 * s, 2.72, 0.93], [0, 16 * s, 0])), C.eye);
      m.add("Eyes", H(at(ball(0.05, 0.055, 0.03), [0.43 * s + 0.035, 2.8, 0.99])), C.white);
      m.add("Eyes", H(at(ball(0.022, 0.022, 0.02, 6), [0.43 * s - 0.04, 2.64, 0.985])), C.white);
    }
    m.bone("EyesShut", "Head", hj([0, 2.8, 0.95])); // happy closed arcs, hidden until used
    for (const s of [-1, 1]) m.add("EyesShut", H(tube([[0.28 * s, 2.68, 0.93], [0.43 * s, 2.79, 0.99], [0.58 * s, 2.68, 0.9]], 0.035, 6, 10)), C.cream);

    m.bone("EarL", "Head", hj([0.6, 3.36, 0]));
    m.add("EarL", H(at(ball(0.3, 0.36, 0.17), [0.66, 3.56, 0], [0, 0, -14])), C.furDark);
    m.add("EarL", H(at(ball(0.2, 0.25, 0.1), [0.66, 3.55, 0.1], [0, 0, -14])), C.pink);
    m.add("EarL", H(limb([0.56, 3.36, 0.14], [0.5, 3.62, 0.2], 0.09, 0.02, 6)), C.cream); // a wisp of pale fur inside
    m.add("EarL", H(limb([0.72, 3.78, 0.02], [0.78, 3.92, 0.04], 0.1, 0.05, 8)), C.furDark); // tufted tip
    m.mirror("EarL", "EarR");

    m.bone("ArmL", "Body", [0.58, 1.82, 0.05]);
    m.add("ArmL", limb([0.58, 1.82, 0.05], [0.92, 1.42, 0.12], 0.18, 0.155), C.fur);
    m.bone("ForeL", "ArmL", [0.92, 1.42, 0.12]);
    m.add("ForeL", limb([0.92, 1.42, 0.12], [1.02, 1.04, 0.28], 0.155, 0.17), C.fur);
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
    // birches, planned from the tree itself: a slim white trunk that leans and forks, dark eyes where old branches fell, thin
    // dark twigs, and the leaves as many small clusters hung on the twig ends (never one ball). They stand left of the camp,
    // so the lake and the cabin stay in view behind the maker. Canopies are their own bones: the storm shakes them.
    const trees = [[-6.4, -4.2, 11.5, 1.0, 0.5], [-11.2, -8.6, 14.5, 1.2, -0.7], [-13.4, -0.6, 12.5, 1.05, 0.9]];
    trees.forEach(([x, z, h, s, bendDir], ti) => {
      const tb = "Trunk" + (ti + 1), cb = "Canopy" + (ti + 1), R = (k) => rnd(ti * 97 + k);
      m.bone(tb, "Ground", [x, 0, z]);
      const sway = (u) => [x + Math.sin(u * 2.4) * 0.5 * bendDir * s, u * h, z + Math.sin(u * 1.7 + 1) * 0.3 * s];
      const trunkPts = []; for (let k = 0; k <= 8; k++) trunkPts.push(sway((k / 8) * 0.82));
      m.add(tb, tube(trunkPts, (u) => (0.44 - 0.26 * u) * s, 10, 24), C.birch);
      m.add(tb, at(lathe([[0.72 * s, 0], [0.56 * s, 0.2], [0.44 * s, 0.7], [0.4 * s, 1.1]], 10), [x, -0.05, z]), C.birchShade); // the dark foot
      for (let k = 0; k < 4; k++) { const a = (k / 4) * 6.283 + ti; m.add(tb, limb([x + Math.cos(a) * 0.3 * s, 0.25, z + Math.sin(a) * 0.3 * s], [x + Math.cos(a) * 1.0 * s, -0.1, z + Math.sin(a) * 1.0 * s], 0.2 * s, 0.06 * s, 6), C.birchShade); } // roots
      for (let k = 0; k < 16; k++) { // bark marks: short dark dashes that wrap the trunk, and three larger "eyes"
        const u = 0.06 + (k / 16) * 0.72, p = sway(u), a = R(k) * 6.283, rr = (0.44 - 0.26 * u) * s * 0.96, eye = k % 6 === 2;
        m.add(tb, at(lo(eye ? 0.2 * s : (0.12 + R(k + 40) * 0.14) * s, eye ? 0.13 * s : 0.035, 0.05), [p[0] + Math.sin(a) * rr, p[1], p[2] + Math.cos(a) * rr], [0, (a * 180) / Math.PI, 0]), C.birchMark);
      }
      // limbs: three forks off the upper trunk, each with two twigs; leaf clusters hang on every end
      const ends = [], top = sway(0.82);
      const forks = [[0.5, 0.0, 3.2, 0.5], [0.6, 2.2, 3.0, 0.55], [0.7, 4.3, 2.6, 0.6], [0.82, 1.1, 2.2, 0.9], [0.82, 3.6, 2.0, 0.95], [0.82, 5.4, 1.6, 1.0]];
      forks.forEach(([u, a0, len, rise], fi) => {
        const p = sway(u), a = a0 + ti * 1.3, e = [p[0] + Math.cos(a) * len * s, p[1] + len * rise * s, p[2] + Math.sin(a) * len * s * 0.8];
        const mid = [(p[0] + e[0]) / 2 + Math.cos(a + 1) * 0.3, (p[1] + e[1]) / 2 + 0.35 * s, (p[2] + e[2]) / 2];
        m.add(tb, tube([p, mid, e], (t) => (0.17 - 0.11 * t) * s * (1.2 - u * 0.5), 6, 8), fi < 3 ? C.birch : C.birchShade);
        ends.push(e, mid);
        for (const da of [-0.9, 0.8]) { // twigs
          const t2 = [e[0] + Math.cos(a + da) * 1.3 * s, e[1] + 0.5 * s, e[2] + Math.sin(a + da) * 1.3 * s * 0.8];
          m.add(tb, tube([mid, [(mid[0] + t2[0]) / 2, (mid[1] + t2[1]) / 2 + 0.2, (mid[2] + t2[2]) / 2], t2], 0.035 * s, 4, 4), C.birchMark);
          ends.push(t2);
        }
      });
      ends.push([top[0], top[1] + 1.0 * s, top[2]]);
      m.bone(cb, tb, [x, h * 0.62, z]);
      ends.forEach((e, ei) => {
        const cr = (0.95 + R(ei + 200) * 0.55) * s;
        m.add(cb, at(lo(cr * 0.98, cr * 0.74, cr * 0.92, 9, 7), e), C.leafDark); // the shaded heart of the cluster
        m.add(cb, at(lo(cr * 0.8, cr * 0.5, cr * 0.74, 8, 5), [e[0] - cr * 0.1, e[1] + cr * 0.34, e[2]]), C.leaf); // its lit top
        for (let k = 0; k < 16; k++) { // leaves on its shell: lit ones on top, dark below, a few butter ones
          const th = R(ei * 31 + k) * 6.283, ph = -0.7 + R(ei * 17 + k + 5) * 2.1, d = [Math.cos(th) * Math.cos(ph), Math.sin(ph), Math.sin(th) * Math.cos(ph)];
          const col = ph < -0.1 ? C.leafDark : k % 9 === 0 ? C.butter : ph > 0.6 ? C.leafLight : C.leaf;
          m.add(cb, at(lo(0.34 * s, 0.1 * s, 0.24 * s, 5, 3), [e[0] + d[0] * cr * 0.97, e[1] + d[1] * cr * 0.74, e[2] + d[2] * cr * 0.92], [(-ph * 180) / Math.PI * 0.6, (-th * 180) / Math.PI, 0]), col);
        }
        if (ei % 2 === 0) { // a hanging twig with small leaves: the weeping line of a birch
          const l = (1.4 + R(ei + 300) * 1.4) * s, bx = e[0] + (R(ei + 310) - 0.5) * cr, bz = e[2] + (R(ei + 320) - 0.5) * cr;
          m.add(cb, tube([[bx, e[1] - cr * 0.3, bz], [bx + 0.08, e[1] - cr * 0.3 - l * 0.5, bz], [bx + 0.16, e[1] - cr * 0.3 - l, bz + 0.05]], 0.02 * s, 3, 4), C.birchMark);
          for (let k = 1; k <= 5; k++) m.add(cb, at(lo(0.2 * s, 0.05 * s, 0.13 * s, 5, 3), [bx + 0.03 * k + (k % 2 ? 0.14 : -0.14) * s, e[1] - cr * 0.3 - (l * k) / 5, bz], [0, k * 70, k % 2 ? 50 : -50]), k % 2 ? C.leaf : C.leafLight);
        }
      });
    });

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

  // ---------- Cabin: the maker's home across the water (logs, a steep metal roof with a dormer, a stone chimney, a porch) ----------
  {
    const m = model("Cabin");
    m.bone("Walls", null, [0, 0, 0]);
    const X0 = -7, X1 = 5, Z0 = -4.5, Z1 = 4.5, WALL = 5.4, BASE = 0.7;
    const box = (w, h, d, p, r = [0, 0, 0], e = 0.16) => at(pillow(w, h, d, e, 4), p, r);
    // fieldstone footing
    for (let k = 0; k < 14; k++) { const u = k / 14, front = k % 2 === 0; m.add("Walls", box(1.9, 0.8, 1.0, [X0 + 0.8 + (k >> 1) * 1.72, 0.36, front ? Z1 - 0.1 : Z0 + 0.1], [0, 0, 0], 0.5), [C.stone, C.stoneDark, C.stoneLight][k % 3]); }
    for (let k = 0; k < 6; k++) for (const xs of [X0 + 0.1, X1 - 0.1]) m.add("Walls", box(1.0, 0.8, 1.7, [xs, 0.36, Z0 + 0.9 + k * 1.5], [0, 0, 0], 0.5), [C.stoneDark, C.stone, C.stoneLight][k % 3]);
    // log walls: round logs laid in courses, the side walls half a course higher so the ends cross at the corners
    const courses = Math.round((WALL - BASE) / 0.5);
    for (let k = 0; k < courses; k++) {
      const y = BASE + 0.25 + k * 0.5, c = k % 3 === 1 ? C.logLight : C.log;
      for (const z of [Z0, Z1]) m.add("Walls", limb([X0 - 0.5, y, z], [X1 + 0.5, y, z], 0.27, 0.27, 6), c);
      for (const x of [X0, X1]) m.add("Walls", limb([x, y + 0.25, Z0 - 0.5], [x, y + 0.25, Z1 + 0.5], 0.27, 0.27, 6), c);
      for (const z of [Z0, Z1]) for (const x of [X0 - 0.52, X1 + 0.52]) m.add("Walls", at(lo(0.05, 0.2, 0.2, 6, 4), [x, y, z]), C.logEnd); // pale cut ends
    }
    // gable ends: shorter logs up to the ridge
    const RIDGE = 10.4, EAVE = WALL + 0.2;
    for (let k = 0; k < 9; k++) { const y = WALL + 0.25 + k * 0.5, half = (Z1 - Z0) / 2 * (1 - (y - WALL) / (RIDGE - WALL)); if (half > 0.3) for (const x of [X0, X1]) m.add("Walls", limb([x, y, -half], [x, y, half], 0.27, 0.27, 6), k % 2 ? C.log : C.logLight); }
    // roof: two metal slopes with raised seams, a ridge cap, dark eaves
    const run = (Z1 - Z0) / 2 + 1.1, rise = RIDGE - EAVE + 0.9, slopeLen = Math.hypot(run, rise), pitch = (Math.atan2(rise, run) * 180) / Math.PI;
    for (const s of [-1, 1]) {
      const mid = [(X0 + X1) / 2, RIDGE - rise / 2 + 0.2, s * run / 2];
      m.add("Walls", box(X1 - X0 + 2.2, 0.22, slopeLen, mid, [s * pitch, 0, 0], 0.1), C.roof);
      for (let k = 0; k <= 9; k++) m.add("Walls", box(0.12, 0.34, slopeLen * 0.98, [X0 - 0.9 + k * ((X1 - X0 + 1.8) / 9), mid[1] + 0.06, mid[2]], [s * pitch, 0, 0], 0.3), k % 2 ? C.roofLight : C.roofDark);
    }
    m.add("Walls", limb([X0 - 1.15, RIDGE + 0.42, 0], [X1 + 1.15, RIDGE + 0.42, 0], 0.2, 0.2, 6), C.roofLight);
    // the dormer over the left windows: a small gable that faces the lake
    const DX = -3.2, DW = 2.3, DZ = 2.2, DR = 8.9;
    m.add("Walls", box(DW * 2, 2.4, 2.6, [DX, 6.9, DZ + 0.2], [0, 0, 0], 0.12), C.logLight);
    for (let k = 0; k < 4; k++) m.add("Walls", limb([DX - DW, 5.95 + k * 0.5, DZ + 1.5], [DX + DW, 5.95 + k * 0.5, DZ + 1.5], 0.22, 0.22, 6), k % 2 ? C.log : C.logLight);
    for (const s of [-1, 1]) m.add("Walls", box(3.2, 0.2, 3.6, [DX + s * 1.25, DR - 0.55, DZ - 0.1], [0, 0, -s * 38], 0.1), C.roof);
    m.add("Walls", limb([DX, DR + 0.42, DZ - 1.7], [DX, DR + 0.42, DZ + 1.8], 0.16, 0.16, 6), C.roofLight);
    // stone chimney, stepped, with a cap
    for (let k = 0; k < 11; k++) { const y = 0.6 + k * 1.05, w = k < 4 ? 2.2 : 1.6; m.add("Walls", box(w + rnd(k + 900) * 0.14, 1.0, w * 0.8, [2.2 + (rnd(k + 910) - 0.5) * 0.1, y, -1.2], [0, rnd(k + 920) * 6 - 3, 0], 0.4), [C.stone, C.stoneLight, C.stoneDark][k % 3]); }
    m.add("Walls", box(2.0, 0.3, 1.7, [2.2, 12.2, -1.2], [0, 0, 0], 0.3), C.stoneDark);
    // the porch on the right: a deck, four posts, a rail, a lean-to roof, two steps
    const PX0 = X1, PX1 = X1 + 6.2;
    m.add("Walls", box(PX1 - PX0 + 0.4, 0.3, 6.4, [(PX0 + PX1) / 2, 1.0, 1.6], [0, 0, 0], 0.1), C.logLight);
    for (let k = 0; k < 8; k++) m.add("Walls", box(0.06, 0.32, 6.3, [PX0 + 0.5 + k * 0.78, 1.01, 1.6], [0, 0, 0], 0.2), C.log); // deck boards
    for (const px of [PX0 + 0.4, PX0 + 2.3, PX0 + 4.2, PX1 - 0.2]) { m.add("Walls", limb([px, 1.1, 4.5], [px, 4.9, 4.5], 0.17, 0.17, 6), C.log); m.add("Walls", box(0.5, 0.2, 0.5, [px, 4.9, 4.5], [0, 0, 0], 0.3), C.logLight); }
    m.add("Walls", limb([PX1 - 0.2, 1.1, -1.4], [PX1 - 0.2, 4.9, -1.4], 0.17, 0.17, 6), C.log);
    m.add("Walls", limb([PX0 + 2.3, 2.3, 4.5], [PX1 - 0.2, 2.3, 4.5], 0.1, 0.1, 6), C.logLight);
    for (let k = 0; k < 8; k++) m.add("Walls", limb([PX0 + 2.5 + k * 0.48, 1.15, 4.5], [PX0 + 2.5 + k * 0.48, 2.3, 4.5], 0.05, 0.05, 4), C.log); // balusters
    m.add("Walls", limb([PX1 - 0.2, 2.3, 4.5], [PX1 - 0.2, 2.3, -1.4], 0.1, 0.1, 6), C.logLight);
    m.add("Walls", box(PX1 - PX0 + 1.2, 0.2, 7.6, [(PX0 + PX1) / 2 + 0.3, 5.5, 1.5], [0, 0, -9], 0.1), C.roof);
    for (let k = 0; k <= 5; k++) m.add("Walls", box(0.1, 0.3, 7.5, [PX0 + 0.1 + k * 1.3, 5.6 - k * 0.2, 1.5], [0, 0, -9], 0.3), k % 2 ? C.roofLight : C.roofDark);
    for (let k = 0; k < 2; k++) m.add("Walls", box(2.2, 0.32, 0.8, [PX0 + 1.35, 0.72 - k * 0.36, 5.0 + k * 0.7], [0, 0, 0], 0.2), C.logLight); // steps
    // window and door frames (the panes are the Glow bone)
    const wins = [[-5.3, 3.1, 1.5, 1.9], [-2.2, 3.1, 1.5, 1.9], [DX, 7.0, 1.3, 1.4], [3.2, 3.2, 1.1, 1.5]]; // x, y, half width, height
    for (const [x, y, hw, hh] of wins) {
      const zf = x === DX ? DZ + 1.78 : Z1 + 0.3;
      for (const s of [-1, 1]) m.add("Walls", box(0.2, hh + 0.3, 0.22, [x + s * hw, y, zf], [0, 0, 0], 0.3), C.logEnd);
      for (const s of [-1, 1]) m.add("Walls", box(hw * 2 + 0.3, 0.2, 0.26, [x, y + (s * hh) / 2, zf], [0, 0, 0], 0.3), C.logEnd);
      m.add("Walls", box(0.09, hh, 0.16, [x, y, zf + 0.02], [0, 0, 0], 0.3), C.log); m.add("Walls", box(hw * 2, 0.09, 0.16, [x, y, zf + 0.02], [0, 0, 0], 0.3), C.log); // mullions
    }
    m.add("Walls", box(1.9, 3.4, 0.24, [1.0, 2.6, Z1 + 0.3], [0, 0, 0], 0.12), C.logLight); // the door
    m.add("Walls", at(lo(0.09, 0.09, 0.09), [1.7, 2.5, Z1 + 0.5]), C.brass);
    m.add("Walls", limb([PX0 + 0.3, 4.4, 4.3], [PX0 + 0.3, 3.9, 4.3], 0.03, 0.03, 4), C.nose); // the porch lantern's hook
    m.bone("Glow", "Walls", [0, 3, Z1], "Neon");
    for (const [x, y, hw, hh] of wins) m.add("Glow", at(pillow(hw * 2, hh, 0.1, 0.15, 6), [x, y, x === DX ? DZ + 1.72 : Z1 + 0.24]), C.glow);
    m.add("Glow", at(pillow(1.1, 1.0, 0.1, 0.2, 6), [1.0, 3.5, Z1 + 0.42]), C.glow); // the door's glass
    m.add("Glow", at(lo(0.2, 0.26, 0.2, 8, 6), [PX0 + 0.3, 3.7, 4.3]), C.glow); // the porch lantern
    // the reflection: the house upside down from its own footing, and the lights drawn out long, as on still water
    m.bone("Mirror", null, [0, 0, 0]);
    m.add("Mirror", at(pillow(X1 - X0 + 1, WALL, Z1 - Z0 + 1, 0.12, 6), [(X0 + X1) / 2, -WALL / 2, 0]), C.log);
    for (const s of [-1, 1]) m.add("Mirror", at(pillow(X1 - X0 + 2.2, 0.3, slopeLen, 0.1, 6), [(X0 + X1) / 2, -(RIDGE - rise / 2 + 0.2), s * run / 2], [-s * pitch, 0, 0]), C.roofDark);
    m.add("Mirror", at(pillow(1.7, 12, 1.4, 0.3, 6), [2.2, -6.2, -1.2]), C.stoneDark);
    m.add("Mirror", at(pillow(PX1 - PX0 + 1.2, 0.3, 7.6, 0.1, 6), [(PX0 + PX1) / 2 + 0.3, -5.5, 1.5], [0, 0, 9]), C.roofDark);
    m.bone("MirrorGlow", "Mirror", [0, -3, Z1], "Neon");
    for (const [x, y, hw, hh] of wins) m.add("MirrorGlow", at(pillow(hw * 1.9, hh * 7.5, 0.1, 0.6, 6), [x, -y - hh * 3.4, x === DX ? DZ + 1.72 : Z1 + 0.24]), C.glow);
    m.add("MirrorGlow", at(pillow(0.5, 8, 0.1, 0.6, 6), [PX0 + 0.3, -8, 4.3]), C.glow);
    out.push(m);
  }

  // ---------- Spruce1-3: the forest's trees, planned from the reference: a tall narrow spire, boughs in whorls that droop and
  // lift at the tip, dark blue-green with paler new growth, a bare foot of trunk with dead stubs. Each carries its mirror image. ----------
  const spruce = (name, h, tiers, seed, lean) => {
    const m = model(name), R = (k) => rnd(seed * 131 + k), geos = [];
    const add = (bn, g, c) => { m.add(bn, g, c); geos.push([g, c]); };
    m.bone("Trunk", null, [0, 0, 0]);
    const k0 = h / 30, axis = (y) => [Math.sin((y / h) * 1.6) * lean, y, Math.cos((y / h) * 2.1) * lean * 0.4 - lean * 0.4];
    const tp = []; for (let k = 0; k <= 6; k++) tp.push(axis((k / 6) * h * 0.97));
    add("Trunk", tube(tp, (u) => (0.95 - 0.86 * u) * k0, 7, 12), C.bark);
    for (let k = 0; k < 5; k++) { const a = (k / 5) * 6.283 + seed; add("Trunk", limb([Math.cos(a) * 0.5 * k0, 0.5 * k0, Math.sin(a) * 0.5 * k0], [Math.cos(a) * 1.7 * k0, -0.2, Math.sin(a) * 1.7 * k0], 0.42 * k0, 0.1 * k0, 5), C.bark); } // root flares
    for (let k = 0; k < 5; k++) { const y = h * (0.05 + 0.02 * k), a = R(k + 50) * 6.283, p = axis(y); add("Trunk", limb(p, [p[0] + Math.cos(a) * 1.5 * k0, y - 0.3 * k0, p[2] + Math.sin(a) * 1.5 * k0], 0.1 * k0, 0.03, 4), C.barkLight); } // dead stubs
    m.bone("Boughs", "Trunk", [0, h * 0.5, 0]);
    for (let t = 0; t < tiers; t++) {
      const u = t / (tiers - 1), y = h * (0.13 + 0.83 * u), p = axis(y), reach = h * 0.2 * Math.pow(1 - u, 0.78) + 0.5 * k0, n = Math.max(4, Math.round(8 - 3.5 * u));
      for (let k = 0; k < n; k++) {
        const a = (k / n) * 6.283 + t * 0.9 + R(t * 13 + k) * 0.6, len = reach * (0.72 + 0.5 * R(t * 7 + k + 3)), droop = rad(30 + 16 * R(t * 5 + k) - 26 * u);
        const hx = Math.cos(droop) * len * 0.5, hy = -Math.sin(droop) * len * 0.5;
        const col = [C.sp1, C.sp2, C.sp1, C.sp3][Math.floor(R(t * 3 + k + 9) * 4)];
        add("Boughs", at(lo(len * 0.56, len * 0.1 + 0.16 * k0, len * 0.27 + 0.12 * k0), [p[0] + Math.cos(a) * hx, y + hy, p[2] - Math.sin(a) * hx], [0, (a * 180) / Math.PI, (-droop * 180) / Math.PI]), col);
        if ((t + k) % 2 === 0) { // the tip lifts and is paler: this year's growth
          const tx = Math.cos(droop) * len * 0.92, ty = -Math.sin(droop) * len * 0.92 + len * 0.06;
          add("Boughs", at(lo(len * 0.2, len * 0.06 + 0.1 * k0, len * 0.15 + 0.08 * k0, 5, 3), [p[0] + Math.cos(a) * tx, y + ty, p[2] - Math.sin(a) * tx], [0, (a * 180) / Math.PI, 8]), C.spTip);
        }
      }
    }
    const topP = axis(h * 0.95);
    add("Boughs", at(lathe([[0.5 * k0, 0], [0.34 * k0, h * 0.03], [0.05, h * 0.075]], 6), topP), C.sp2);
    m.bone("Mirror", null, [0, 0, 0]);
    for (const [g, c] of geos) m.add("Mirror", mirrorY(g, 0), c);
    out.push(m);
  };
  spruce("Spruce1", 40, 17, 1, 0.5);
  spruce("Spruce2", 32, 15, 2, -0.7);
  spruce("Spruce3", 25, 13, 3, 0.3);

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

  // ---------- small things of the meadow ----------
  {
    const m = model("FlowerPatch"); // arnica-like mountain flowers: a yellow disc of petals, an orange eye, a leaf or two
    m.bone("Patch", null, [0, 0, 0]);
    for (let i = 0; i < 13; i++) {
      const a = rnd(i + 1100) * 6.283, r = Math.sqrt(rnd(i + 1110)) * 1.7, x = Math.cos(a) * r, z = Math.sin(a) * r, h = 0.5 + rnd(i + 1120) * 0.55, lx = (rnd(i + 1130) - 0.5) * 0.3;
      m.add("Patch", tube([[x, 0, z], [x + lx * 0.6, h * 0.6, z], [x + lx, h, z]], 0.025, 3, 3), C.stem);
      m.add("Patch", at(lo(0.2, 0.045, 0.2, 7, 3), [x + lx, h, z], [rnd(i + 1140) * 40 - 20, 0, rnd(i + 1150) * 40 - 20]), [C.petal, C.petalDeep, C.petal, C.petalPale][i % 4]);
      m.add("Patch", at(lo(0.07, 0.06, 0.07, 5, 3), [x + lx, h + 0.04, z]), C.ember);
      m.add("Patch", at(lo(0.16, 0.02, 0.06, 5, 3), [x + 0.1, h * 0.35, z], [0, i * 50, 30]), C.grass);
    }
    for (let i = 0; i < 10; i++) { const a = rnd(i + 1160) * 6.283, r = rnd(i + 1170) * 1.8, x = Math.cos(a) * r, z = Math.sin(a) * r; m.add("Patch", limb([x, 0, z], [x + (rnd(i + 1180) - 0.5) * 0.5, 0.4 + rnd(i + 1190) * 0.4, z + 0.1], 0.05, 0.01, 4), i % 2 ? C.grass : C.grassDark); }
    out.push(m);
  }
  {
    const m = model("GrassTuft");
    m.bone("Tuft", null, [0, 0, 0]);
    for (let i = 0; i < 9; i++) { const a = (i / 9) * 6.283, l = 0.55 + rnd(i + 1200) * 0.6; m.add("Tuft", tube([[Math.cos(a) * 0.12, 0, Math.sin(a) * 0.12], [Math.cos(a) * 0.3, l * 0.6, Math.sin(a) * 0.3], [Math.cos(a) * 0.62, l, Math.sin(a) * 0.62]], (u) => 0.07 - 0.06 * u, 4, 4), [C.grass, C.grassDark, C.grassLight][i % 3]); }
    out.push(m);
  }
  const rock = (name, seed, w, hgt, d) => { // a boulder: a lump with flat, weathered faces, moss on its top
    const m = model(name);
    m.bone("Rock", null, [0, 0, 0]);
    const g = new THREE.SphereGeometry(1, 9, 6), p = g.getAttribute("position");
    for (let i = 0; i < p.count; i++) { const k = 0.78 + 0.4 * rnd(Math.round(p.getX(i) * 7) * 13 + Math.round(p.getY(i) * 7) * 57 + Math.round(p.getZ(i) * 7) * 91 + seed); p.setXYZ(i, p.getX(i) * w * k, Math.max(p.getY(i) * hgt * k, -hgt * 0.35), p.getZ(i) * d * k); }
    const flat = g.toNonIndexed(); flat.computeVertexNormals();
    m.add("Rock", at(flat, [0, hgt * 0.3, 0]), C.stone);
    const g2 = new THREE.SphereGeometry(1, 7, 5).toNonIndexed(); g2.scale(w * 0.62, hgt * 0.45, d * 0.6); g2.computeVertexNormals();
    m.add("Rock", at(g2, [w * 0.5, hgt * 0.12, d * 0.3], [0, seed * 40, 12]), C.stoneDark);
    m.add("Rock", at(lo(w * 0.5, hgt * 0.12, d * 0.45, 7, 4), [-w * 0.1, hgt * 1.02, 0]), C.moss);
    out.push(m);
  };
  rock("Rock1", 1, 1.5, 1.0, 1.1); rock("Rock2", 2, 2.1, 0.8, 1.5);
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
