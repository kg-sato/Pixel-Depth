// Geode Pickaxe biography: "Nobody wanted it." A plain grey rock is thrown in the reject barrel of a stone stall again and
// again; a hedgehog child takes it, sits in the dust and taps it with her toy hammer until it cracks open on a cave of
// violet crystal. Scene bible: vault "Forge Biographies - Scene Bibles (2026-11-15)", Geode.
// References: refs/forge/sheets/geode_setting_s11.png (a dusty roadside stall at a clay quarry: striped awning, bunting,
// stones on violet velvet trays, a barrel of grey rejects, a hand cart, stepped orange terraces, white windmills, pale sky)
// and hedgehog_views_s11.png (brown spines with pale tips, cream face, green eyes, rosy cheeks, straw hat with a pink
// ribbon, yellow smock with a patch pocket, red toy hammer).
// Models: HedgehogKit (the maker, BoltKit's bone names), Stallkeeper (a ferret who sorts the stones), GeodeStall, RejectBarrel,
// GeodeRock (two halves that open, with Neon crystal inside and a Neon crack), HandCart, GeodeLand (ground, road, terraces),
// Windmill (Sails bone), ToyHammer, Bunting.
// Front of every model is +Z. Units are studs. The stall stands at x = -4 (screen left once flipped), the road runs away
// along -Z, the cart is at x = +4, the terraces and windmills are far off on the +X side.
export const name = "geode";

const C = {
  spine: "#5a3a26", spineDark: "#3e2618", spineTip: "#efdcb4", skin: "#f6dcc0", skinDark: "#e6c2a0", cheek: "#f2a0a0", nose: "#1a1418",
  eye: "#1e3a24", eyeIris: "#3e7a3e", white: "#ffffff", mouth: "#7a2a2a", tooth: "#fffaf0",
  smock: "#f2c230", smockDark: "#d9a418", straw: "#e0b46a", strawDark: "#b88a44", ribbon: "#f2a0b4", hammerRed: "#d8402e", hammerWood: "#c89a5c",
  ferret: "#c8a27a", ferretDark: "#8a6444", ferretMask: "#5a4030", apron: "#4a6a8a", apronDark: "#36506a",
  wood: "#9a6a3e", woodDark: "#6e4626", woodLight: "#b88a56", stripeA: "#8a2a3a", stripeB: "#efe2c4", velvet: "#4a2a5e", brass: "#d0a040",
  rock: "#8a8478", rockDark: "#6a655c", rockLight: "#a8a296", crystal: "#9b6fd6", crystalLight: "#d6b8ff", cut: "#e9e3d6",
  gem1: "#4ab0d8", gem2: "#e8664a", gem3: "#f4d06f", gem4: "#6ad08a",
  sand: "#e0a874", sandLight: "#ecc090", sandDark: "#c48858", road: "#d8b48a", clay: "#d88a52", clayLight: "#eaa86a", clayDark: "#b0683a",
  mill: "#f0ebe0", millDark: "#c8c0b0", sail: "#6e4626", sailCloth: "#efe2c4", iron: "#4a4652",
  flagA: "#8a2a6a", flagB: "#e8b830", flagC: "#3a9a5a", flagD: "#d84a3a",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, model, rnd } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 7, hs = 5) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const box = (w, h, d) => new THREE.BoxGeometry(w, h, d);
  const cyl = (r0, r1, h, seg = 12) => new THREE.CylinderGeometry(r1, r0, h, seg);
  const cone = (r, h, seg = 6) => new THREE.ConeGeometry(r, h, seg);
  const ring = (cx, cy, cz, rx, rz, n = 16) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([cx + Math.sin(a) * rx, cy, cz + Math.cos(a) * rz]); } return p; };
  const tri = (a, b, c) => { const g = new THREE.BufferGeometry(); g.setAttribute("position", new THREE.Float32BufferAttribute([...a, ...b, ...c, ...a, ...c, ...b], 3)); g.computeVertexNormals(); return g; }; // two-sided

  // ---------- HedgehogKit: the child ----------
  {
    const m = model("HedgehogKit");
    m.bone("Hips", null, [0, 0.8, 0]);
    m.bone("Body", "Hips", [0, 0.8, 0]);
    m.add("Body", lathe([[0.02, 0.5], [0.62, 0.52], [0.7, 0.62], [0.62, 0.9], [0.5, 1.3], [0.4, 1.66], [0.02, 1.72]], 22), C.smock); // the smock, flared
    m.add("Body", tube(ring(0, 0.56, 0, 0.68, 0.68, 24), 0.05, 6, 40), C.smockDark);
    m.add("Body", at(pillow(0.34, 0.3, 0.06, 0.4, 6), [0.18, 0.86, 0.58], [-8, 10, 0]), C.smockDark); // the patch pocket
    m.add("Body", tube(ring(0, 1.22, 0.02, 0.46, 0.44, 20), 0.035, 5, 30), C.smockDark); // the yoke seam
    for (let k = 0; k < 14; k++) { const a = Math.PI * 0.55 + (k / 13) * Math.PI * 0.9; m.add("Body", at(cone(0.13, 0.5, 6), [Math.sin(a) * 0.46, 1.2 + (k % 3) * 0.16, Math.cos(a) * 0.46], [Math.cos(a) * -60 - 20, 0, Math.sin(a) * 60]), k % 2 ? C.spine : C.spineDark); } // spines down her back
    m.bone("Head", "Body", [0, 1.72, 0]);
    m.add("Head", at(ball(0.98, 0.88, 0.9, 24), [0, 2.55, 0]), C.spine);
    m.add("Head", at(ball(0.8, 0.72, 0.5, 22), [0, 2.48, 0.46]), C.skin); // the face
    m.add("Head", at(ball(0.34, 0.24, 0.26, 14), [0, 2.24, 0.82]), C.skin); // the snout
    m.add("Head", at(ball(0.13, 0.1, 0.1, 10), [0, 2.32, 1.06]), C.nose);
    for (const s of [-1, 1]) {
      m.add("Head", at(ball(0.16, 0.08, 0.04, 10), [0.5 * s, 2.24, 0.82], [0, 30 * s, 0]), C.cheek);
    }
    m.bone("Mouth", "Head", [0, 2.08, 0.9]);
    m.add("Mouth", at(ball(0.16, 0.08, 0.05, 10), [0, 2.08, 0.92]), C.mouth);
    m.add("Mouth", at(box(0.07, 0.06, 0.03), [-0.06, 2.13, 0.95]), C.tooth); // one tooth; the gap beside it is the missing one
    m.bone("Eyes", "Head", [0, 2.56, 0.82]);
    for (const s of [-1, 1]) {
      m.add("Eyes", at(ball(0.18, 0.22, 0.07, 14), [0.32 * s, 2.56, 0.84], [0, 16 * s, 0]), C.eye);
      m.add("Eyes", at(ball(0.11, 0.13, 0.04, 10), [0.32 * s, 2.52, 0.9], [0, 16 * s, 0]), C.eyeIris);
      m.add("Eyes", at(ball(0.05, 0.06, 0.03, 8), [0.32 * s + 0.06, 2.64, 0.93]), C.white);
      m.add("Eyes", tube([[0.18 * s, 2.82, 0.8], [0.32 * s, 2.86, 0.84], [0.48 * s, 2.8, 0.76]], 0.02, 5, 8), C.spineDark); // brows
    }
    m.bone("EyesShut", "Head", [0, 2.56, 0.88]);
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.2 * s, 2.54, 0.86], [0.32 * s, 2.6, 0.9], [0.46 * s, 2.54, 0.82]], 0.03, 6, 10), C.spineDark);
    // the spines of her head: cones with pale tips, round the back and the crown
    m.bone("Spines", "Head", [0, 2.6, -0.2]);
    for (let k = 0; k < 34; k++) {
      const a = rnd(k * 3.7) * Math.PI * 1.5 + Math.PI * 0.25, b = 0.25 + rnd(k * 5.3) * 1.15, d = [Math.sin(a) * Math.sin(b), Math.cos(b), Math.cos(a) * Math.sin(b)];
      if (d[2] > 0.35 && d[1] < 0.6) continue;
      const p = [d[0] * 0.9, 2.55 + d[1] * 0.82, d[2] * 0.84], len = 0.5 + rnd(k) * 0.25, tip = [p[0] + d[0] * len, p[1] + d[1] * len, p[2] + d[2] * len];
      m.add("Spines", limb(p, tip, 0.12, 0.02, 6), C.spine);
      m.add("Spines", limb([p[0] + d[0] * len * 0.7, p[1] + d[1] * len * 0.7, p[2] + d[2] * len * 0.7], tip, 0.045, 0.01, 6), C.spineTip);
    }
    m.bone("Hat", "Head", [0, 3.2, 0]); // a straw hat far too big, a pink ribbon
    m.add("Hat", at(cyl(1.62, 1.5, 0.08, 28), [0, 3.12, 0.05], [-10, 0, 0]), C.straw);
    m.add("Hat", at(lathe([[0.86, 0], [0.8, 0.3], [0.64, 0.6], [0.3, 0.74], [0.02, 0.76]], 22), [0, 3.12, -0.02], [-10, 0, 0]), C.straw);
    m.add("Hat", tube(ring(0, 3.28, -0.02, 0.84, 0.84, 24).map(([x, y, z]) => [x, y + z * 0.17, z]), 0.09, 6, 40), C.ribbon);
    m.add("Hat", at(pillow(0.3, 0.16, 0.08, 0.4, 6), [0.5, 3.26, -0.78], [0, 30, 20]), C.ribbon);
    m.add("Hat", tube(ring(0, 3.14, 0.05, 1.56, 1.56, 32).map(([x, y, z]) => [x, y + z * 0.17, z]), 0.04, 5, 48), C.strawDark);
    m.bone("ArmL", "Body", [0.5, 1.5, 0]);
    m.add("ArmL", limb([0.5, 1.5, 0], [0.78, 1.0, 0.08], 0.13, 0.12), C.skin);
    m.bone("ForeL", "ArmL", [0.78, 1.0, 0.08]);
    m.add("ForeL", limb([0.78, 1.0, 0.08], [0.84, 0.66, 0.2], 0.12, 0.11), C.skin);
    m.add("ForeL", at(ball(0.15, 0.13, 0.15, 10), [0.85, 0.6, 0.24]), C.skinDark);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");
    m.bone("LegL", "Hips", [0.26, 0.6, 0]);
    m.add("LegL", limb([0.26, 0.6, 0], [0.28, 0.12, 0.04], 0.16, 0.14), C.skin);
    m.add("LegL", at(ball(0.2, 0.1, 0.3, 10), [0.28, 0.08, 0.16]), C.skinDark);
    m.mirror("LegL", "LegR");
    out.push(m);
  }

  // ---------- Stallkeeper: a ferret in an apron, who sorts the stones ----------
  {
    const m = model("Stallkeeper");
    m.bone("Hips", null, [0, 1.0, 0]);
    m.bone("Body", "Hips", [0, 1.0, 0]);
    m.add("Body", lathe([[0.02, 0.6], [0.46, 0.66], [0.56, 1.0], [0.5, 1.6], [0.36, 2.1], [0.02, 2.2]], 18), C.ferret);
    m.add("Body", at(pillow(0.82, 1.2, 0.16, 0.3, 8), [0, 1.2, 0.46]), C.apron);
    m.add("Body", tube([[-0.36, 1.8, 0.44], [0, 2.1, 0.36], [0.36, 1.8, 0.44]], 0.04, 5, 10), C.apronDark);
    m.bone("Head", "Body", [0, 2.15, 0]);
    m.add("Head", at(ball(0.62, 0.56, 0.7, 20), [0, 2.65, 0.1]), C.ferret);
    m.add("Head", at(ball(0.3, 0.24, 0.36, 14), [0, 2.52, 0.68]), C.white);
    m.add("Head", at(ball(0.09, 0.07, 0.07, 8), [0, 2.58, 1.02]), C.nose);
    for (const s of [-1, 1]) {
      m.add("Head", at(ball(0.24, 0.12, 0.1, 10), [0.26 * s, 2.74, 0.6], [0, 20 * s, 0]), C.ferretMask);
      m.add("Head", at(ball(0.08, 0.07, 0.04, 8), [0.26 * s, 2.75, 0.68]), C.nose); // half-shut, bored eyes
      m.add("Head", at(ball(0.16, 0.18, 0.06, 10), [0.48 * s, 3.08, -0.05]), C.ferretDark);
    }
    m.bone("ArmL", "Body", [0.44, 1.9, 0]);
    m.add("ArmL", limb([0.44, 1.9, 0], [0.64, 1.4, 0.1], 0.13, 0.11), C.ferret);
    m.bone("ForeL", "ArmL", [0.64, 1.4, 0.1]);
    m.add("ForeL", limb([0.64, 1.4, 0.1], [0.68, 1.0, 0.24], 0.11, 0.1), C.ferret);
    m.add("ForeL", at(ball(0.12, 0.1, 0.12, 8), [0.68, 0.94, 0.28]), C.ferretDark);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");
    m.bone("LegL", "Hips", [0.22, 0.8, 0]);
    m.add("LegL", limb([0.22, 0.8, 0], [0.24, 0.1, 0.06], 0.14, 0.12), C.ferretDark);
    m.mirror("LegL", "LegR");
    m.bone("Tail1", "Hips", [0, 0.8, -0.4]);
    m.add("Tail1", tube([[0, 0.8, -0.4], [0.2, 0.5, -1.0], [0.5, 0.3, -1.4]], (u) => 0.14 - 0.06 * u, 7, 10), C.ferretDark);
    out.push(m);
  }

  // ---------- GeodeStall: the stall, its trays, its scales, its bunting ----------
  {
    const m = model("GeodeStall");
    m.bone("Frame", null, [0, 0, 0]);
    for (const [x, z] of [[-1.8, -0.9], [1.8, -0.9], [-1.8, 0.9], [1.8, 0.9]]) m.add("Frame", at(box(0.22, 4.4, 0.22), [x, 2.2, z]), C.woodDark);
    m.add("Frame", at(box(4.0, 0.16, 1.9), [0, 1.3, 0.2]), C.wood); // the counter
    m.add("Frame", at(box(4.0, 1.1, 0.08), [0, 0.75, 1.12]), C.woodLight); // its front board
    for (let k = 0; k < 3; k++) m.add("Frame", at(box(0.06, 1.0, 0.04), [-1.2 + k * 1.2, 0.75, 1.17]), C.woodDark);
    m.add("Frame", at(box(4.0, 0.12, 0.7), [0, 2.3, -0.7]), C.wood); // a shelf behind
    // the awning: striped strips, sloping toward the road, with a scalloped edge
    m.bone("Awning", "Frame", [0, 4.3, 0]);
    for (let k = 0; k < 10; k++) m.add("Awning", at(box(0.45, 0.06, 3.0), [-2.0 + 0.225 + k * 0.45, 4.3, 0.6], [-14, 0, 0]), k % 2 ? C.stripeB : C.stripeA);
    for (let k = 0; k < 10; k++) m.add("Awning", tri([-2.0 + k * 0.45, 3.93, 2.06], [-2.0 + (k + 1) * 0.45, 3.93, 2.06], [-2.0 + (k + 0.5) * 0.45, 3.65, 2.1]), k % 2 ? C.stripeB : C.stripeA);
    // trays of sorted stones on violet velvet: the pretty ones
    m.bone("Trays", "Frame", [0, 1.4, 0]);
    for (let i = 0; i < 4; i++) {
      const x = -1.4 + i * 0.95, z = 0.5;
      m.add("Trays", at(box(0.86, 0.12, 0.7), [x, 1.44, z], [-12, 0, 0]), C.woodLight);
      m.add("Trays", at(box(0.74, 0.03, 0.58), [x, 1.51, z], [-12, 0, 0]), C.velvet);
      for (let k = 0; k < 6; k++) { const g = [C.gem1, C.gem2, C.gem3, C.gem4][(i + k) % 4]; m.add("Trays", at(lo(0.09, 0.07, 0.08, 6, 4), [x - 0.24 + (k % 3) * 0.24, 1.58 + (k > 2 ? -0.04 : 0.02), z - 0.12 + (k > 2 ? 0.24 : 0)]), g); }
    }
    for (let k = 0; k < 9; k++) m.add("Trays", at(lo(0.14, 0.11, 0.12, 6, 4), [-1.6 + k * 0.4, 2.44, -0.7]), [C.rockLight, C.gem1, C.rock, C.gem3][k % 4]); // the shelf of better ones
    // the hanging brass scales
    m.bone("Scales", "Frame", [1.4, 3.7, 0.5]);
    m.add("Scales", limb([1.4, 3.7, 0.5], [1.4, 3.1, 0.5], 0.03, 0.03, 5), C.brass);
    m.add("Scales", at(box(0.9, 0.05, 0.05), [1.4, 3.1, 0.5]), C.brass);
    for (const s of [-1, 1]) { m.add("Scales", limb([1.4 + 0.42 * s, 3.1, 0.5], [1.4 + 0.42 * s, 2.7, 0.5], 0.012, 0.012, 4), C.brass); m.add("Scales", at(cyl(0.18, 0.12, 0.06, 12), [1.4 + 0.42 * s, 2.66, 0.5]), C.brass); }
    // bunting along the front of the awning and off to the far post
    m.bone("Flags", "Frame", [0, 3.6, 2.0]);
    const line = [[-2.0, 3.65, 2.05], [-0.6, 3.35, 2.15], [0.8, 3.4, 2.15], [2.0, 3.65, 2.05]];
    m.add("Flags", tube(line, 0.015, 4, 30), C.woodDark);
    for (let k = 0; k < 9; k++) { const u = (k + 0.5) / 9, x = -2.0 + 4.0 * u, y = 3.65 - 0.3 * Math.sin(u * Math.PI); m.add("Flags", tri([x - 0.17, y, 2.12], [x + 0.17, y, 2.12], [x, y - 0.42, 2.16]), [C.flagA, C.flagB, C.flagC, C.flagD][k % 4]); }
    out.push(m);
  }

  // ---------- RejectBarrel: the barrel of grey rejects ----------
  {
    const m = model("RejectBarrel");
    m.bone("Barrel", null, [0, 0, 0]);
    m.add("Barrel", lathe([[0.02, 0], [0.5, 0], [0.6, 0.5], [0.62, 0.7], [0.58, 1.2], [0.52, 1.34], [0.46, 1.34], [0.46, 1.2], [0.02, 1.2]], 18), C.wood);
    for (const y of [0.18, 0.66, 1.16]) m.add("Barrel", tube(ring(0, y, 0, 0.6 - Math.abs(y - 0.66) * 0.12, 0.6 - Math.abs(y - 0.66) * 0.12, 20), 0.035, 5, 30), C.iron);
    for (let k = 0; k < 12; k++) m.add("Barrel", at(lo(0.16 + rnd(k) * 0.08, 0.12, 0.15, 6, 4), [(rnd(k * 3) - 0.5) * 0.7, 1.22 + rnd(k * 5) * 0.14, (rnd(k * 7) - 0.5) * 0.7], [rnd(k) * 60, rnd(k * 2) * 180, 0]), [C.rock, C.rockDark, C.rockLight][k % 3]);
    out.push(m);
  }

  // ---------- GeodeRock: dull grey outside; two halves; a cave of violet crystal inside ----------
  {
    const m = model("GeodeRock");
    const R = 0.42;
    const half = (s) => { // one half of a lumpy ball, cut on x = 0, s = +1 or -1
      const g = new THREE.SphereGeometry(1, 16, 12, s > 0 ? 0 : Math.PI, Math.PI); const p = g.attributes.position;
      for (let i = 0; i < p.count; i++) { const x = p.getX(i), y = p.getY(i), z = p.getZ(i), k = R * (1 + 0.12 * Math.sin(x * 5 + y * 3) * Math.sin(z * 4 + 1)); p.setXYZ(i, x * k, y * k * 0.9, z * k); }
      g.computeVertexNormals(); return g;
    };
    for (const [bn, s] of [["HalfA", 1], ["HalfB", -1]]) {
      m.bone(bn, null, [0, 0, 0]);
      m.add(bn, half(s), C.rock);
      for (let k = 0; k < 5; k++) m.add(bn, at(lo(0.08, 0.05, 0.08, 6, 4), [s * (0.2 + rnd(k) * 0.15), (rnd(k * 3) - 0.5) * 0.5, (rnd(k * 5) - 0.5) * 0.5]), C.rockDark);
      m.add(bn, at(cyl(R * 0.98, R * 0.98, 0.02, 20), [s * 0.005, 0, 0], [0, 0, 90]), C.cut); // the pale cut rind
      m.bone("Crystal" + bn.slice(-1), bn, [0, 0, 0], "Neon");
      for (let k = 0; k < 16; k++) { // crystal points standing inward from the rind, toward the cut face
        const a = (k / 16) * Math.PI * 2, r = 0.12 + rnd(k * 7) * 0.2, y = Math.sin(a) * r, z = Math.cos(a) * r;
        m.add("Crystal" + bn.slice(-1), at(cone(0.05 + rnd(k) * 0.03, 0.16 + rnd(k * 2) * 0.1, 5), [s * 0.04, y, z], [0, 0, s * -90]), k % 3 ? C.crystal : C.crystalLight);
      }
    }
    m.bone("Crack", null, [0, 0, 0], "Neon");
    m.add("Crack", tube([[0.01, R * 0.95, 0.05], [0.03, R * 0.5, R * 0.8], [-0.02, 0, R * 0.98], [0.02, -R * 0.5, R * 0.82], [0, -R * 0.9, 0.1]], 0.014, 4, 20), C.crystalLight);
    out.push(m);
  }

  // ---------- ToyHammer ----------
  {
    const m = model("ToyHammer");
    m.bone("Body", null, [0, 0, 0]);
    m.add("Body", at(cyl(0.045, 0.05, 0.7, 8), [0, 0.35, 0]), C.hammerWood);
    m.add("Body", at(cyl(0.11, 0.11, 0.36, 12), [0, 0.74, 0], [0, 0, 90]), C.hammerRed);
    out.push(m);
  }

  // ---------- HandCart: a wooden cart with a load of rough stone ----------
  {
    const m = model("HandCart");
    m.bone("Bed", null, [0, 0, 0]);
    m.add("Bed", at(box(2.0, 0.12, 3.2), [0, 1.1, 0]), C.wood);
    for (const s of [-1, 1]) { m.add("Bed", at(box(0.1, 0.5, 3.2), [s * 0.96, 1.4, 0]), C.woodLight); m.add("Bed", at(box(2.0, 0.5, 0.1), [0, 1.4, s * 1.56]), C.woodLight); }
    m.add("Bed", limb([0.6, 1.2, 1.6], [0.6, 0.9, 3.2], 0.05, 0.05, 6), C.woodDark);
    m.add("Bed", limb([-0.6, 1.2, 1.6], [-0.6, 0.9, 3.2], 0.05, 0.05, 6), C.woodDark);
    for (let k = 0; k < 14; k++) m.add("Bed", at(lo(0.22 + rnd(k) * 0.1, 0.18, 0.2, 6, 4), [(rnd(k * 3) - 0.5) * 1.5, 1.42 + rnd(k * 5) * 0.2, (rnd(k * 7) - 0.5) * 2.6], [rnd(k) * 40, rnd(k * 2) * 180, 0]), [C.rock, C.rockDark][k % 2]);
    for (const [bn, s] of [["WheelL", 1], ["WheelR", -1]]) {
      m.bone(bn, "Bed", [s * 1.12, 0.62, 0]);
      m.add(bn, at(tube(ring(0, 0, 0, 0.6, 0.6, 20), 0.07, 6, 30), [s * 1.12, 0.62, 0], [0, 0, 90]), C.woodDark);
      for (let k = 0; k < 6; k++) { const a = (k / 6) * Math.PI * 2; m.add(bn, limb([s * 1.12, 0.62, 0], [s * 1.12, 0.62 + Math.cos(a) * 0.58, Math.sin(a) * 0.58], 0.03, 0.03, 4), C.wood); }
    }
    out.push(m);
  }

  // ---------- GeodeLand: dusty ground, the road, the stepped quarry terraces ----------
  {
    const m = model("GeodeLand");
    m.bone("Ground", null, [0, 0, 0]);
    m.add("Ground", at(cyl(140, 140, 0.4, 40), [0, -0.2, -40]), C.sand);
    m.add("Ground", at(box(4.4, 0.02, 120), [0.6, 0.012, -50]), C.road);
    for (const x of [-0.4, 1.6]) m.add("Ground", at(box(0.22, 0.02, 120), [x, 0.025, -50]), C.sandDark); // cart ruts
    for (let k = 0; k < 120; k++) m.add("Ground", at(lo(0.06 + rnd(k) * 0.1, 0.04, 0.07, 5, 3), [(rnd(k * 3) - 0.5) * 22, 0.02, 6 - rnd(k * 5) * 30]), [C.sandLight, C.sandDark, C.rockLight][k % 3]);
    m.bone("Terraces", null, [0, 0, 0]);
    const mound = (cx, cz, rx, rz, steps, h) => { // a stepped hill: rings that shrink as they rise, a pale lip on each step
      for (let k = 0; k < steps; k++) {
        const f = 1 - k / steps, y = (k + 0.5) * h;
        m.add("Terraces", at(cyl(rx * f, rx * f * 0.97, h, 28), [cx, y, cz], [0, 0, 0], [1, 1, rz / rx]), k % 2 ? C.clay : C.clayDark);
        m.add("Terraces", at(cyl(rx * f * 0.99, rx * f * 0.99, 0.12, 28), [cx, (k + 1) * h - 0.04, cz], [0, 0, 0], [1, 1, rz / rx]), C.clayLight);
      }
    };
    mound(36, -60, 34, 22, 9, 2.6);
    mound(-30, -82, 30, 18, 6, 2.2);
    mound(8, -110, 40, 16, 5, 2.0);
    // a long terraced quarry face on the +X side, stepping back from the road (the setting sheet's right half)
    for (let k = 0; k < 8; k++) {
      const x = 14 + k * 3.2, h = 1.6 + k * 1.7;
      m.add("Terraces", at(pillow(3.6, h, 70, 0.25, 8), [x, h / 2, -40], [0, -6, 0]), k % 2 ? C.clay : C.clayDark);
      m.add("Terraces", at(box(0.5, 0.14, 70), [x - 1.6, h + 0.02, -40], [0, -6, 0]), C.clayLight);
    }
    out.push(m);
  }

  // ---------- MarketBits: crates, sacks, posts, bunting over the road, a second stall farther up, dry grass ----------
  {
    const m = model("MarketBits");
    m.bone("Bits", null, [0, 0, 0]);
    const crate = (x, z, s, r) => { m.add("Bits", at(box(0.9 * s, 0.7 * s, 0.9 * s), [x, 0.35 * s, z], [0, r, 0]), C.woodLight); for (const dy of [0.1, 0.6]) m.add("Bits", at(box(0.94 * s, 0.08 * s, 0.94 * s), [x, dy * s, z], [0, r, 0]), C.woodDark); };
    crate(-6.3, 1.0, 1, 10); crate(-6.1, 1.0, 0.8, 30); crate(-6.4, 0.2, 1.1, -8); crate(-2.0, -14, 1, 20); crate(-2.6, -14.6, 0.8, 0);
    for (const [x, z, r] of [[-5.6, 2.2, 10], [-5.0, 2.4, -20], [3.0, -6, 30], [3.6, -6.4, 0]]) { m.add("Bits", at(lathe([[0.02, 0], [0.4, 0], [0.46, 0.4], [0.36, 0.8], [0.12, 0.9], [0.02, 0.92]], 12), [x, 0, z], [0, r, 0]), C.stripeB); m.add("Bits", tube(ring(x, 0.82, z, 0.16, 0.16, 10), 0.04, 4, 14), C.woodDark); } // sacks
    for (const [x, z] of [[-3.0, -4], [3.4, -4], [-3.0, -16], [3.4, -16]]) m.add("Bits", at(box(0.18, 5.2, 0.18), [x, 2.6, z]), C.woodDark); // poles that carry bunting over the road
    for (const z of [-4, -16]) {
      const line = [[-3.0, 5.0, z], [-1.4, 4.4, z], [0.2, 4.3, z], [1.8, 4.4, z], [3.4, 5.0, z]];
      m.add("Bits", tube(line, 0.015, 4, 30), C.woodDark);
      for (let k = 0; k < 12; k++) { const u = (k + 0.5) / 12, x = -3.0 + 6.4 * u, y = 5.0 - 0.7 * Math.sin(u * Math.PI); m.add("Bits", tri([x - 0.2, y, z], [x + 0.2, y, z], [x, y - 0.5, z + 0.02]), [C.flagA, C.flagB, C.flagC, C.flagD][(k + (z < -10 ? 1 : 0)) % 4]); }
    }
    // a second, smaller stall farther up the road on the same side
    for (const [x, z] of [[-4.0, -11], [-6.6, -11], [-4.0, -12.8], [-6.6, -12.8]]) m.add("Bits", at(box(0.16, 3.2, 0.16), [x, 1.6, z]), C.woodDark);
    m.add("Bits", at(box(3.0, 0.14, 2.0), [-5.3, 1.1, -11.9]), C.wood);
    for (let k = 0; k < 6; k++) m.add("Bits", at(box(0.5, 0.05, 2.4), [-6.55 + k * 0.5, 3.25, -11.9], [-10, 0, 0]), k % 2 ? C.stripeB : C.flagC);
    for (let k = 0; k < 40; k++) { const x = (rnd(k * 2.1) - 0.5) * 30, z = 4 - rnd(k * 3.9) * 40; if (Math.abs(x - 0.6) < 3) continue; for (let b = 0; b < 4; b++) m.add("Bits", limb([x, 0, z], [x + (rnd(k * 9 + b) - 0.5) * 0.5, 0.35 + rnd(k + b) * 0.3, z + (rnd(k * 7 + b) - 0.5) * 0.5], 0.03, 0.01, 4), b % 2 ? C.straw : C.strawDark); } // dry grass
    for (let k = 0; k < 30; k++) { const x = (rnd(k * 5.3) - 0.5) * 26, z = 3 - rnd(k * 1.7) * 36; if (Math.abs(x - 0.6) < 2.6) continue; m.add("Bits", at(lo(0.2 + rnd(k) * 0.3, 0.15 + rnd(k * 2) * 0.15, 0.25, 6, 4), [x, 0.08, z], [0, rnd(k) * 180, 0]), [C.clayDark, C.rockLight, C.sandDark][k % 3]); } // stones
    out.push(m);
  }

  // ---------- Windmill: a white tower, a cap, four lattice sails ----------
  {
    const m = model("Windmill");
    m.bone("Tower", null, [0, 0, 0]);
    m.add("Tower", lathe([[0.02, 0], [2.2, 0], [2.0, 4], [1.7, 7.6], [0.02, 7.6]], 18), C.mill);
    m.add("Tower", at(lathe([[1.9, 0], [1.6, 1.1], [0.5, 1.9], [0.02, 2.0]], 18), [0, 7.5, 0]), C.millDark);
    m.add("Tower", at(box(0.8, 1.4, 0.2), [0, 0.7, 2.1]), C.woodDark);
    m.bone("Sails", "Tower", [0, 8.2, 2.0]);
    for (let k = 0; k < 4; k++) {
      const a = (k / 4) * Math.PI * 2, dx = Math.sin(a), dy = Math.cos(a);
      m.add("Sails", limb([0, 8.2, 2.0], [dx * 6, 8.2 + dy * 6, 2.0], 0.1, 0.07, 5), C.sail);
      const nx = dy * 0.9, ny = -dx * 0.9;
      m.add("Sails", tri([dx * 1.2, 8.2 + dy * 1.2, 2.05], [dx * 5.8, 8.2 + dy * 5.8, 2.05], [dx * 5.8 + nx, 8.2 + dy * 5.8 + ny, 2.05]), C.sailCloth);
      m.add("Sails", tri([dx * 1.2, 8.2 + dy * 1.2, 2.05], [dx * 5.8 + nx, 8.2 + dy * 5.8 + ny, 2.05], [dx * 1.2 + nx, 8.2 + dy * 1.2 + ny, 2.05]), C.sailCloth);
    }
    m.add("Sails", at(ball(0.3, 0.3, 0.3, 8), [0, 8.2, 2.1]), C.sail);
    out.push(m);
  }
  return out;
}
