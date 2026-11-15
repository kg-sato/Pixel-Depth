// Wood Pickaxe biography: "a birch branch dropped by a spring storm, whittled by a young raccoon in one long night".
// Models: WoodSet (diorama, birches, campfire, paper-theatre backdrop), BoltKit (the maker), BirchBranch, WoodBlank,
// Shaving, Acorn, Knife. Front of every model is +Z. Units are studs.
export const name = "wood";

const C = {
  fur: "#9c97b6", furDark: "#5b5272", mask: "#3b2d4d", cream: "#f6f0fa", pink: "#f4a9c2", nose: "#2a1f36", eye: "#1d1528", white: "#ffffff",
  red: "#e8525a", redDark: "#c23c4c",
  grass: "#9edcae", grassLight: "#c4f0c0", grassDark: "#6fbf8e", grassDeep: "#58a67e", soil: "#7a566c", soilDark: "#4d3554", soilDeep: "#33223d",
  birch: "#f7f1e8", birchShade: "#e4d8d2", birchMark: "#4f3f58", leaf: "#a9e3c3", leafLight: "#d5f5cf", butter: "#f7e6a2",
  stone: "#b7aed0", stoneDark: "#8f86ad", wood: "#c99a6b", woodDark: "#9a6d4d", woodEnd: "#f0d7a8",
  flame: "#ff9a3c", flameCore: "#ffd060", ember: "#f2603a",
  sky1: "#170a22", sky2: "#26123b", sky3: "#3a1d55", sky4: "#5a2f73", sky5: "#8a4a8c", sky6: "#c9739a",
  hill1: "#2a1740", hill2: "#3c2156", hill3: "#55306e", star: "#fff3c4", sun: "#ffd98a", cloud: "#4a3a66", cloudLight: "#6a5a8c", bolt: "#fff7d0",
  steel: "#dfe3f5", acorn: "#c98f5a", acornCap: "#8a5d44",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, strip, bend, model } = T;
  const out = [];

  // ---------- BoltKit: the young raccoon ----------
  {
    const m = model("BoltKit");
    m.bone("Hips", null, [0, 0.95, 0]);
    m.bone("Body", "Hips", [0, 0.95, 0]);
    m.add("Body", lathe([[0.02, 0.7], [0.46, 0.73], [0.67, 0.95], [0.7, 1.25], [0.58, 1.65], [0.42, 1.95], [0.02, 2.04]], 20), C.fur);
    m.add("Body", at(ball(0.47, 0.52, 0.3), [0, 1.28, 0.43]), C.cream);
    // neckerchief: a soft ring, a knot and a bib point (the bow language of the pickaxes)
    const ring = []; for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2; ring.push([Math.sin(a) * 0.46, 1.93 + Math.cos(a) * 0.03, Math.cos(a) * 0.44]); }
    m.add("Body", tube(ring, 0.13, 8, 32), C.red);
    m.add("Body", at(puff([[-0.42, 0.05], [0.42, 0.05], [0.0, -0.62]], 0.16, 0.1), [0, 1.9, 0.52], [-18, 0, 0]), C.red);
    m.add("Body", at(ball(0.13, 0.11, 0.1), [0, 1.9, 0.6]), C.redDark);
    for (const s of [-1, 1]) m.add("Body", limb([0.07 * s, 1.84, 0.6], [0.2 * s, 1.5, 0.52], 0.045, 0.02, 6), C.redDark); // folds from the knot

    // satchel: a strap across the chest, a pouch on his right hip with a butter button and a mint leaf tucked in
    m.add("Body", tube([[0.5, 1.86, 0.2], [0.2, 1.5, 0.6], [-0.3, 1.15, 0.62], [-0.66, 0.98, 0.3]], 0.055, 6, 14), C.wood);
    m.add("Body", tube([[0.5, 1.86, -0.2], [0.2, 1.5, -0.56], [-0.3, 1.15, -0.6], [-0.66, 0.98, -0.3]], 0.055, 6, 14), C.wood);
    m.add("Body", at(pillow(0.46, 0.42, 0.3, 0.5), [-0.72, 0.98, 0.22], [0, -24, 8]), C.woodDark);
    m.add("Body", at(pillow(0.5, 0.2, 0.34, 0.5), [-0.73, 1.14, 0.23], [0, -24, 8]), C.wood);
    m.add("Body", at(ball(0.07, 0.07, 0.05, 8), [-0.8, 1.06, 0.4]), C.butter);
    m.add("Body", at(puff([[0, 0], [0.12, 0.1], [0.13, 0.26], [0, 0.42], [-0.13, 0.26], [-0.12, 0.1]], 0.03, 0.025), [-0.62, 1.2, 0.2], [0, -20, -18]), C.leaf);
    // the neckerchief knot and its two tails at the back
    m.add("Body", at(ball(0.14, 0.12, 0.12, 10), [0, 1.93, -0.52]), C.redDark);
    m.add("Body", at(puff([[-0.1, 0], [0.1, 0], [0.16, -0.5], [0, -0.42], [-0.12, -0.52]], 0.05, 0.04), [0.14, 1.9, -0.56], [20, 0, 18]), C.red);
    m.add("Body", at(puff([[-0.1, 0], [0.1, 0], [0.12, -0.44], [0, -0.36], [-0.16, -0.46]], 0.05, 0.04), [-0.14, 1.9, -0.56], [20, 0, -18]), C.red);
    m.bone("Head", "Body", [0, 2.02, 0]);
    m.add("Head", at(ball(1.02, 0.88, 0.92, 24), [0, 2.74, 0.05]), C.fur);
    for (const s of [-1, 1]) {
      m.add("Head", limb([0.66 * s, 2.5, 0.2], [1.08 * s, 2.38, 0.14], 0.3, 0.13, 10), C.fur); // cheek tufts: two soft lobes
      m.add("Head", limb([0.7 * s, 2.62, 0.12], [1.04 * s, 2.66, 0.06], 0.26, 0.12, 10), C.fur);
      m.add("Head", at(ball(0.37, 0.27, 0.18), [0.4 * s, 2.79, 0.78], [0, 18 * s, 12 * s]), C.mask); // mask patch
      m.add("Head", at(ball(0.3, 0.1, 0.12), [0.4 * s, 3.08, 0.72], [0, 16 * s, 10 * s]), C.cream); // brow
      m.add("Head", at(ball(0.12, 0.1, 0.05), [0.66 * s, 2.5, 0.72], [0, 30 * s, 0]), C.pink); // blush
    }
    m.add("Head", at(ball(0.4, 0.29, 0.3), [0, 2.47, 0.82]), C.cream); // muzzle
    m.add("Head", at(ball(0.12, 0.09, 0.09), [0, 2.57, 1.1]), C.nose);
    m.add("Head", tube([[-0.13, 2.43, 1.07], [-0.06, 2.38, 1.1], [0, 2.41, 1.11], [0.06, 2.38, 1.1], [0.13, 2.43, 1.07]], 0.024, 6, 12), C.nose);

    for (const [x, a, l] of [[-0.16, 14, 0.34], [0.02, -4, 0.44], [0.2, -22, 0.32]]) m.add("Head", limb([x, 3.5, 0.12], [x - Math.sin((a * Math.PI) / 180) * l * 0.7, 3.5 + l * 0.7, 0.3], 0.14, 0.08, 8), C.fur); // head tuft
    for (const s of []) for (const dy of [0.05, -0.07]) m.add("Head", limb([0.3 * s, 2.47 + dy, 0.98], [0.78 * s, 2.5 + dy * 3.2, 0.92], 0.018, 0.008, 5), C.cream); // whiskers
    m.bone("Eyes", "Head", [0, 2.8, 0.9]);
    for (const s of [-1, 1]) {
      m.add("Eyes", at(ball(0.17, 0.2, 0.09), [0.4 * s, 2.8, 0.9], [0, 16 * s, 0]), C.cream);
      m.add("Eyes", at(ball(0.115, 0.145, 0.07), [0.395 * s, 2.79, 0.955], [0, 16 * s, 0]), C.eye);
      m.add("Eyes", at(ball(0.045, 0.045, 0.03), [0.36 * s + 0.03, 2.855, 1.01]), C.white);
    }
    m.bone("EyesShut", "Head", [0, 2.8, 0.95]); // happy closed arcs, hidden until used
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.26 * s, 2.76, 0.93], [0.4 * s, 2.86, 0.99], [0.54 * s, 2.76, 0.9]], 0.035, 6, 10), C.cream);

    m.bone("EarL", "Head", [0.6, 3.36, 0]);
    m.add("EarL", at(ball(0.3, 0.36, 0.17), [0.66, 3.56, 0], [0, 0, -14]), C.fur);
    m.add("EarL", at(ball(0.18, 0.23, 0.1), [0.66, 3.55, 0.1], [0, 0, -14]), C.pink);
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

    m.bone("Tail1", "Hips", [0, 0.95, -0.5]);
    m.add("Tail1", at(ball(0.27, 0.27, 0.3), [0, 1.02, -0.62]), C.fur);
    m.add("Tail1", at(ball(0.35, 0.33, 0.33), [0, 1.24, -0.93]), C.mask);
    m.bone("Tail2", "Tail1", [0, 1.4, -1.12]);
    m.add("Tail2", at(ball(0.39, 0.36, 0.36), [0, 1.58, -1.22]), C.fur);
    m.add("Tail2", at(ball(0.35, 0.34, 0.33), [0, 1.95, -1.4]), C.mask);
    m.add("Tail2", at(ball(0.25, 0.27, 0.24), [0, 2.28, -1.46]), C.cream);
    out.push(m);
  }

  // ---------- WoodSet: the birch grove diorama ----------
  {
    const m = model("WoodSet");
    m.bone("Ground", null, [0, 0, 0]);
    // island: grass cap with a round lip, soil body in two chunky terraces
    m.add("Ground", lathe([[0.02, -0.02], [12.4, -0.02], [13.0, -0.2], [13.1, -0.55], [12.7, -0.85], [0.02, -0.9]], 56), C.grass);
    m.add("Ground", lathe([[0.02, -0.85], [12.5, -0.85], [12.3, -1.6], [11.4, -2.4], [10.8, -2.6], [0.02, -2.65]], 56), C.soil);
    m.add("Ground", lathe([[0.02, -2.6], [9.6, -2.6], [9.2, -3.6], [7.6, -4.6], [4.5, -5.3], [0.02, -5.5]], 56), C.soilDark);
    // soft lighter patches, tufts and small flowers
    const rnd = (i) => { const x = Math.sin(i * 127.1) * 43758.5453; return x - Math.floor(x); };
    m.bone("Deco", "Ground", [0, 0, 0]);
    for (let i = 0; i < 9; i++) { const a = rnd(i) * 6.283, r = 2.5 + rnd(i + 20) * 8.5; m.add("Deco", at(ball(1.2 + rnd(i + 40) * 1.4, 0.05, 0.9 + rnd(i + 60)), [Math.cos(a) * r, 0, Math.sin(a) * r], [0, rnd(i) * 180, 0]), C.grassLight); }
    for (let i = 0; i < 22; i++) {
      const a = rnd(i + 100) * 6.283, r = 3.2 + rnd(i + 120) * 8.6, x = Math.cos(a) * r, z = Math.sin(a) * r;
      for (let k = -1; k <= 1; k++) m.add("Deco", limb([x + k * 0.13, 0, z], [x + k * 0.3, 0.36 + rnd(i + k) * 0.18, z + 0.05], 0.13, 0.07, 8), k ? C.grassDark : C.grassDeep);
    }
    for (let i = 0; i < 7; i++) {
      const a = rnd(i + 200) * 6.283, r = 4 + rnd(i + 220) * 7.5, x = Math.cos(a) * r, z = Math.sin(a) * r;
      m.add("Deco", limb([x, 0, z], [x, 0.34, z], 0.035, 0.03, 5), C.grassDark);
      for (let k = 0; k < 5; k++) { const b = (k / 5) * 6.283; m.add("Deco", at(ball(0.1, 0.05, 0.1, 8), [x + Math.cos(b) * 0.12, 0.36, z + Math.sin(b) * 0.12]), i % 2 ? C.butter : C.cream); }
      m.add("Deco", at(ball(0.07, 0.06, 0.07, 8), [x, 0.39, z]), C.flame);
    }

    // birches: three trunks; canopies are separate bones so the storm wind can shake them
    const trees = [[-6.2, -4.6, 7.2, 1.0], [5.6, -6.2, 8.4, 1.15], [-1.2, -8.6, 9.4, 1.25]];
    trees.forEach(([x, z, h, s], ti) => {
      const tb = "Trunk" + (ti + 1);
      m.bone(tb, "Ground", [x, 0, z]);
      m.add(tb, at(lathe([[0.62 * s, 0], [0.5 * s, 0.25], [0.42 * s, 1.2], [0.36 * s, h * 0.6], [0.26 * s, h], [0.02, h + 0.1]], 14), [x, 0, z]), C.birch);
      for (let k = 0; k < 7; k++) {
        const y = 0.8 + (k / 7) * (h - 1.6), a = rnd(ti * 31 + k) * 6.283, rr = (0.42 - 0.16 * (y / h)) * s;
        m.add(tb, at(ball(0.24 * s, 0.07, 0.08), [x + Math.sin(a) * rr, y, z + Math.cos(a) * rr], [0, (a * 180) / Math.PI, 0]), C.birchMark);
      }
      m.add(tb, limb([x, h * 0.62, z], [x + 1.5 * s, h * 0.8, z + 0.4], 0.16 * s, 0.09 * s, 8), C.birch);
      m.add(tb, limb([x, h * 0.7, z], [x - 1.3 * s, h * 0.92, z - 0.2], 0.15 * s, 0.08 * s, 8), C.birch);
      const cb = "Canopy" + (ti + 1);
      m.bone(cb, tb, [x, h * 0.78, z]);
      const blobs = [[0, h + 0.5, 0, 2.5], [1.9, h - 0.3, 0.5, 1.9], [-1.8, h + 0.1, -0.2, 1.8], [0.5, h + 1.9, 0.2, 1.7], [-0.6, h - 0.9, 1.1, 1.5]];
      blobs.forEach(([bx, by, bz, br], bi) => {
        m.add(cb, at(ball(br * s, br * 0.82 * s, br * 0.9 * s, 22), [x + bx * s, by, z + bz * s]), C.leaf);
        m.add(cb, at(ball(br * 0.74 * s, br * 0.5 * s, br * 0.68 * s, 18), [x + (bx - 0.25) * s, by + br * 0.42 * s, z + (bz + 0.3) * s]), C.leafLight); // soft top light
        m.add(cb, at(ball(br * 0.8 * s, br * 0.4 * s, br * 0.74 * s, 18), [x + bx * s, by - br * 0.5 * s, z + bz * s]), C.grassDark); // shaded underside
      });
      m.add(cb, at(ball(0.9 * s, 0.5 * s, 0.7 * s, 14), [x + 0.4 * s, h + 2.75, z + 0.5 * s]), C.butter); // one butter cap, like the bow on the pickaxe
      for (let k = 0; k < 0; k++) { // leaf dabs on the blobs (off: they read as bumps): light on top, dark underneath, a few butter ones
        const [bx, by, bz, br] = blobs[k % blobs.length], th = rnd(ti * 53 + k * 7 + 1) * 6.283, ph = -0.5 + rnd(ti * 29 + k * 3 + 2) * 1.9;
        const d = [Math.cos(th) * Math.cos(ph), Math.sin(ph) * 0.82, Math.sin(th) * Math.cos(ph) * 0.9];
        const col = ph < 0.1 ? C.grassDark : k % 7 === 0 ? C.butter : k % 2 ? C.leafLight : C.grass;
        m.add(cb, at(ball(0.44 * s, 0.2 * s, 0.34 * s, 8), [x + (bx + d[0] * br * 0.93) * s, by + d[1] * br * 0.93 * s, z + (bz + d[2] * br * 0.93) * s], [(-ph * 180) / Math.PI * 0.6, (-th * 180) / Math.PI, 0]), col);
      }
      for (let k = 0; k < 0; k++) { const a = rnd(ti * 17 + k + 300) * 6.283; m.add(cb, at(ball(0.8 * s, 0.6 * s, 0.5 * s), [x + Math.cos(a) * 1.7 * s, h + 0.5 + Math.sin(a * 1.7) * 1.3, z + 1.5 * s * Math.abs(Math.sin(a)) + 0.5]), k % 3 ? C.leafLight : C.butter); }
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
    m.add("Log", at(ball(0.5, 0.12, 0.3), [2.3, 1.2, 2.4], [0, 28, 0]), C.grassDark); // moss pad
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
    for (let i = 0; i < 8; i++) { const a = (i / 8) * 6.283; m.add("Fire", at(pillow(0.62, 0.42, 0.5, 0.55), [-0.6 + Math.cos(a) * 1.05, 0.18, 3.0 + Math.sin(a) * 1.05], [0, (-a * 180) / Math.PI + 90, 0]), i % 2 ? C.stone : C.stoneDark); }
    for (let i = 0; i < 3; i++) { const a = (i / 3) * 3.14159; m.add("Fire", limb([-0.6 - Math.cos(a) * 0.7, 0.12, 3.0 - Math.sin(a) * 0.7], [-0.6 + Math.cos(a) * 0.7, 0.3, 3.0 + Math.sin(a) * 0.7], 0.14, 0.12, 8), C.woodDark); }
    const flame = (r, h, lean0 = 0.25) => { const lean = lean0 * 0.6; // a lick of fire: a teardrop that bends as it rises
      const pts = []; for (let k = 0; k <= 8; k++) { const u = k / 8; pts.push([Math.sin(u * 3.4) * lean * h * 0.35, u * h, Math.sin(u * 2.2 + 1) * lean * h * 0.12]); }
      return tube(pts, (u) => r * 1.25 * Math.sin(Math.PI * Math.pow(Math.min(u + 0.04, 1), 0.42)) * (1 - 0.3 * u) + 0.01, 18, 30);
    };
    m.bone("Flame1", "Fire", [-0.6, 0.3, 3.0]); m.add("Flame1", at(flame(0.5, 1.7), [-0.6, 0.3, 3.0]), C.flame);
    m.add("Flame1", at(flame(0.3, 1.15, -0.3), [-0.42, 0.3, 2.9], [0, 60, 0]), C.ember);
    m.bone("Flame2", "Fire", [-0.86, 0.3, 3.12]); m.add("Flame2", at(flame(0.3, 1.05, -0.35), [-0.9, 0.3, 3.12], [0, 0, 10]), C.ember);
    m.bone("Flame3", "Fire", [-0.36, 0.3, 2.86]); m.add("Flame3", at(flame(0.28, 0.9, 0.4), [-0.3, 0.3, 3.16], [0, 0, -12]), C.flame);
    m.bone("FlameCore", "Fire", [-0.6, 0.32, 3.06], "Neon"); m.add("FlameCore", at(flame(0.26, 1.0, 0.2), [-0.6, 0.32, 3.2]), C.flameCore);
    m.add("FlameCore", at(flame(0.14, 0.55, -0.3), [-0.8, 0.32, 3.26]), C.flameCore);

    // paper-theatre backdrop: banded sky wall, three hill cut-outs, stars, sun, storm clouds, lightning
    m.bone("Sky", null, [0, 0, -30]);
    // sky: six paper bands, the palest at the horizon, each with a lighter cut edge
    const bands = [C.sky6, C.sky5, C.sky4, C.sky3, C.sky2, C.sky1], bh = [3.4, 3.6, 4.2, 5.2, 7, 26], HALF = 86;
    let y0 = -3;
    bands.forEach((c, i) => {
      const top = (u) => y0 + bh[i] + (i === bands.length - 1 ? 0 : Math.sin(u * 23 + i * 1.7) * 0.5 + Math.sin(u * 61 + i) * 0.18);
      m.add("Sky", strip(top, y0 - 1.2, HALF, 30 - i * 0.14, 96), c); y0 += bh[i];
    });
    m.bone("Dawn", "Sky", [0, 0, -29.3]);
    const dawnBands = ["#ffd9a0", "#ffc08f", "#f7a08c", "#d98aa0", "#a878b0", "#7a62a8"], dh = [3.4, 3.6, 4.2, 5.2, 7, 26];
    let d0 = -3;
    dawnBands.forEach((c, i) => {
      const top = (u) => d0 + dh[i] + (i === dawnBands.length - 1 ? 0 : Math.sin(u * 23 + i * 1.7) * 0.5 + Math.sin(u * 61 + i) * 0.18);
      m.add("Dawn", strip(top, d0 - 1.2, HALF, 29.3 - i * 0.1, 96), c); d0 += dh[i];
    });
    const hill = (r, base, amp, seed, c, cEdge) => {
      const top = (u) => base + Math.sin(u * 19 + seed) * amp + Math.sin(u * 47 + seed * 2.3) * amp * 0.35;
      m.add("Sky", strip(top, -9, HALF, r, 120), c);
      m.add("Sky", strip(top, 0, HALF, r - 0.05, 120, 0.16), cEdge);
    };
    hill(28.4, 5.4, 1.9, 0.4, C.hill3, C.sky4); hill(26.4, 3.1, 1.6, 2.1, C.hill2, C.hill3); hill(24.2, 0.9, 1.2, 4.4, C.hill1, C.hill2);
    // paper pines on the middle hill
    m.bone("Pines", "Sky", [0, 3, -26.2]);
    for (let i = 0; i < 14; i++) { const x = -76 + i * 11.4 + rnd(i + 500) * 4, h = 2.4 + rnd(i + 520) * 2.2; m.add("Pines", bend(at(puff([[-0.9, 0], [0.9, 0], [0.5, h * 0.4], [0.7, h * 0.4], [0.3, h * 0.72], [0.45, h * 0.72], [0, h], [-0.45, h * 0.72], [-0.3, h * 0.72], [-0.7, h * 0.4], [-0.5, h * 0.4]], 0.2, 0.06, true), [x, 2.6 + Math.sin(x * 0.4) * 0.7, -26.2]), 26.2), C.hill2); }
    m.bone("Stars", "Sky", [0, 16, -29.2], "Neon");
    const star4 = (r) => { const p = []; for (let k = 0; k < 8; k++) { const a = (k / 8) * 6.283, rr = k % 2 ? r * 0.32 : r; p.push([Math.sin(a) * rr, Math.cos(a) * rr]); } return puff(p, 0.06, 0.03, false); };
    for (let i = 0; i < 56; i++) m.add("Stars", bend(at(star4(0.28 + rnd(i + 600) * 0.5), [-80 + rnd(i + 620) * 160, 10 + rnd(i + 640) * 20, -29.2], [0, 0, rnd(i) * 40]), 29.2), C.star);
    m.bone("Sun", "Sky", [9, -3, -29.0], "Neon");
    m.add("Sun", at(ball(5.2, 5.2, 0.16, 32), [9, -3, -29.0]), C.sun);
    m.bone("SunRays", "Sun", [9, -3, -29.2], "Neon");
    for (let i = 0; i < 12; i++) { const a = (i / 12) * 6.283; m.add("SunRays", at(puff([[-0.5, 6.4], [0.5, 6.4], [0, 10.2]], 0.06, 0.03, false), [9, -3, -29.2], [0, 0, (a * 180) / Math.PI]), C.butter); }
    const cloud = (bn, x, y, z, s) => {
      m.bone(bn, "Sky", [x, y, z]);
      [[0, 0, 2.6, 1.3], [2.4, -0.2, 2.0, 1.0], [-2.5, -0.25, 2.1, 1.05], [1.0, 0.8, 1.8, 1.0], [-1.1, 0.7, 1.6, 0.9]].forEach(([dx, dy, w, h], i) => m.add(bn, at(ball(w * s, h * s, 0.35), [x + dx * s, y + dy * s, z + i * 0.04]), i > 2 ? C.cloudLight : C.cloud));
    };
    cloud("Cloud1", -10, 18, -21, 2.4); cloud("Cloud2", 11, 20, -20, 2.9);
    m.bone("Lightning", "Sky", [-3, 15, -19.5], "Neon");
    m.add("Lightning", at(puff([[0.6, 0], [1.5, 0], [0.5, -3.4], [1.3, -3.4], [-0.9, -8.6], [-0.1, -4.6], [-0.9, -4.6]], 0.08, 0.04, false), [-5.2, 15.5, -19.5]), C.bolt);
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
    const m = model("Drop");
    m.bone("Drop", null, [0, 0, 0]);
    m.add("Drop", lathe([[0.02, -0.16], [0.1, -0.12], [0.13, -0.02], [0.09, 0.14], [0.03, 0.34], [0.01, 0.42]], 10), "#cfe4ff");
    m.add("Drop", at(ball(0.03, 0.05, 0.02, 6), [-0.05, -0.02, 0.1]), C.white);
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
