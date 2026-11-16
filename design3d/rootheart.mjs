// Rootheart Pickaxe biography: "Grown, not made." A bead of amber sap in the root hall of the oldest tree; the roots wind
// round it for years while a mole waters them; at the end the tree hands it down.
// Setting from the scene bible (vault "Forge Biographies - Scene Bibles", Rootheart) and, when rendered, the sheets
// refs/forge/sheets/rootheart_setting_s11.png and mole_views_s11.png.
// Models: MoleKit (same bone names as BoltKit and OtterKit, plus Glasses, Lens, Whiskers and Grey: the grey that comes with
// the years, faded in by the scene), RootHall (floor, shell, arching roots, the knot hole), RootCradle (seven finger roots,
// three bones each, that close over the sap), SapBead, GlowShroom, WateringCan, LightShaft.
// Ferns, clover and stones come from the CC0 kit (kit_import.py). Front of every model is +Z. Units are studs.
// The floor's height function H is repeated in src/ForgeRootheart.luau (floorY): change both together.
export const name = "rootheart";

const C = {
  fur: "#3a3a44", furDark: "#2a2a32", furLight: "#4c4c58", grey: "#b9b9c4", pink: "#e8a79a", pinkDark: "#c9807a", claw: "#f4e6d8", eye: "#121016", white: "#ffffff",
  vest: "#4f7a4a", vestDark: "#3f6b4a", patchA: "#c98b5e", patchB: "#7ad1b0", brass: "#d9a441", lens: "#cfe8f0",
  moss: "#3f6b4a", mossLight: "#5a8a52", mossDark: "#2c4a36", bark: "#5b5a48", barkDark: "#3c3f34", barkLight: "#74705a", shell: "#1e211c", earth: "#4a4334", mossBright: "#6aa23e", warm: "#6b4a30", warmDark: "#4a3222", warmLight: "#8a6240", stone: "#6b6f7a",
  amber: "#f2a23a", amberLight: "#fff0c8", teal: "#7ad1b0", stem: "#e8dcc0", stemDark: "#c9bb98", tin: "#8fa39a", tinDark: "#6d8078", ray: "#fff1c4", rayCore: "#fff8e0", sky: "#fff6dc",
};
const sm = (a, b, t) => { const x = Math.min(1, Math.max(0, (t - a) / (b - a))); return x * x * (3 - 2 * x); };
// the floor (authoring space): it rises to the walls, dips for the pool, humps for the cradle's mound and rolls a little
export const H = (x, z) => 7 * sm(26, 46, Math.hypot(x, (z + 8) * 0.92)) - 1.7 * (1 - sm(2.5, 6, Math.hypot(x + 10, z + 9))) + 0.9 * (1 - sm(1.2, 4.2, Math.hypot(x, z + 3.5))) + 0.35 * Math.sin(x * 0.21) * Math.cos(z * 0.17) * sm(9, 16, Math.hypot(x, z));
const KNOT = [-10.7, 42.7, -12.75]; // the knot hole on the shell; the ray falls from it onto the cradle
const CRADLE = [0, 0.9, -3.5];

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, field, rnd, model } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 6, hs = 4) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const ring = (cx, cy, cz, r, th, n = 14) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r, cz]); } return tube(p, th, 6, n * 2); };
  // turn a closed shape inside out: seen from within (the hall's shell)
  const inside = (g) => {
    const idx = g.index.array; for (let i = 0; i < idx.length; i += 3) { const t = idx[i]; idx[i] = idx[i + 1]; idx[i + 1] = t; }
    const n = g.getAttribute("normal"); for (let i = 0; i < n.count; i++) n.setXYZ(i, -n.getX(i), -n.getY(i), -n.getZ(i));
    return g;
  };

  // ---------- MoleKit: the gardener ----------
  {
    const m = model("MoleKit");
    m.bone("Hips", null, [0, 0.95, 0]);
    m.bone("Body", "Hips", [0, 0.95, 0]);
    m.add("Body", lathe([[0.02, 0.6], [0.56, 0.66], [0.84, 0.96], [0.88, 1.3], [0.72, 1.68], [0.5, 1.96], [0.02, 2.06]], 22), C.fur);
    // the patched waistcoat: a shell over the trunk, open in a V at the chest, brass buttons, two patches of other cloth
    m.add("Body", lathe([[0.87, 0.88], [0.93, 1.3], [0.77, 1.68], [0.56, 1.95]], 24), C.vest);
    const hem = []; for (let i = 0; i <= 18; i++) { const a = (i / 18) * Math.PI * 2; hem.push([Math.sin(a) * 0.88, 0.89, Math.cos(a) * 0.88]); }
    m.add("Body", tube(hem, 0.035, 6, 36), C.vestDark);
    m.add("Body", at(puff([[-0.2, 0.4], [0.2, 0.4], [0, -0.42]], 0.04, 0.03, false), [0, 1.57, 0.78], [-26, 0, 0]), C.furLight);
    for (const [y, z] of [[1.12, 0.93], [0.99, 0.91]]) m.add("Body", at(ball(0.055, 0.055, 0.035, 8), [0, y, z]), C.brass);
    m.add("Body", at(pillow(0.3, 0.26, 0.06, 0.4, 6), [0.52, 1.22, 0.76], [0, 34, 6]), C.patchA);
    m.add("Body", at(pillow(0.24, 0.22, 0.06, 0.4, 6), [-0.6, 1.5, 0.46], [0, -52, -8]), C.patchB);
    m.add("Body", at(pillow(0.28, 0.24, 0.06, 0.4, 6), [0.3, 1.36, -0.82], [0, 160, 4]), C.patchA);
    for (const s of [-1, 1]) m.add("Body", tube([[0.12 * s, 1.92, 0.6], [0.2 * s, 1.6, 0.8], [0.06 * s, 1.24, 0.94]], 0.03, 6, 10), C.vestDark);

    m.bone("Head", "Body", [0, 2.02, 0]);
    m.add("Head", at(ball(0.98, 0.84, 0.9, 24), [0, 2.74, 0.04]), C.fur);
    m.add("Head", at(ball(0.44, 0.34, 0.36, 16), [0, 2.5, 0.7]), C.furLight);
    m.add("Head", limb([0, 2.52, 0.86], [0, 2.44, 1.5], 0.25, 0.11, 12), C.pink);
    m.add("Head", at(ball(0.12, 0.1, 0.1, 10), [0, 2.44, 1.6]), C.pinkDark);
    m.add("Head", tube([[-0.12, 2.32, 0.98], [0, 2.28, 1.04], [0.12, 2.32, 0.98]], 0.02, 6, 8), C.furDark);
    m.bone("Eyes", "Head", [0, 2.9, 0.86]);
    for (const s of [-1, 1]) {
      m.add("Eyes", at(ball(0.075, 0.09, 0.05, 10), [0.34 * s, 2.9, 0.85], [0, 16 * s, 0]), C.eye);
      m.add("Eyes", at(ball(0.026, 0.028, 0.02, 6), [0.34 * s + 0.02, 2.94, 0.89]), C.white);
    }
    m.bone("EyesShut", "Head", [0, 2.9, 0.88]);
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.25 * s, 2.87, 0.84], [0.34 * s, 2.93, 0.89], [0.43 * s, 2.87, 0.83]], 0.028, 6, 10), C.furDark);
    // round wire glasses, a little big for him
    m.bone("Glasses", "Head", [0, 2.9, 0.95]);
    for (const s of [-1, 1]) {
      m.add("Glasses", ring(0.34 * s, 2.9, 0.95, 0.21, 0.026), C.brass);
      m.add("Glasses", tube([[0.55 * s, 2.92, 0.93], [0.8 * s, 2.98, 0.55], [0.9 * s, 3.02, 0.1]], 0.02, 5, 8), C.brass);
    }
    m.add("Glasses", tube([[-0.13, 2.92, 0.96], [0, 2.97, 1.0], [0.13, 2.92, 0.96]], 0.022, 5, 8), C.brass);
    m.bone("Lens", "Glasses", [0, 2.9, 0.95]);
    for (const s of [-1, 1]) m.add("Lens", at(ball(0.2, 0.2, 0.012, 12), [0.34 * s, 2.9, 0.95]), C.lens);
    m.bone("Whiskers", "Head", [0, 2.46, 1.1]);
    for (const s of [-1, 1]) for (const [dy, a] of [[0.05, 0.1], [0, 0], [-0.06, -0.12]]) m.add("Whiskers", limb([0.16 * s, 2.46 + dy, 1.12], [0.72 * s, 2.46 + dy + a, 0.98], 0.012, 0.004, 4), C.white);
    // the grey of old age: brows, temples, muzzle and a streak on the crown. The scene fades this bone in over his three visits.
    m.bone("Grey", "Head", [0, 2.74, 0.04]);
    for (const s of [-1, 1]) {
      m.add("Grey", at(ball(0.15, 0.05, 0.05, 8), [0.36 * s, 3.16, 0.74], [0, 16 * s, 10 * s]), C.grey);
      m.add("Grey", at(ball(0.18, 0.26, 0.22, 10), [0.84 * s, 2.76, 0.3]), C.grey);
      m.add("Grey", at(ball(0.2, 0.15, 0.1, 10), [0.29 * s, 2.42, 0.93]), C.grey);
    }
    m.add("Grey", at(ball(0.3, 0.07, 0.36, 12), [0, 3.55, 0.02]), C.grey);
    m.bone("EarL", "Head", [0.8, 3.18, 0]);
    m.add("EarL", at(ball(0.12, 0.12, 0.08, 8), [0.82, 3.2, 0.0], [0, 0, -30]), C.furDark);
    m.mirror("EarL", "EarR");

    m.bone("ArmL", "Body", [0.6, 1.8, 0.05]);
    m.add("ArmL", limb([0.6, 1.8, 0.05], [0.94, 1.42, 0.14], 0.2, 0.18), C.fur);
    m.bone("ForeL", "ArmL", [0.94, 1.42, 0.14]);
    m.add("ForeL", limb([0.94, 1.42, 0.14], [1.02, 1.06, 0.3], 0.18, 0.18), C.fur);
    // the digging paw: broad, pink, with four pale claws
    m.add("ForeL", at(ball(0.3, 0.14, 0.34, 12), [1.04, 0.96, 0.4]), C.pink);
    for (const dx of [-0.2, -0.07, 0.07, 0.2]) m.add("ForeL", limb([1.04 + dx, 0.94, 0.66 - Math.abs(dx) * 0.3], [1.04 + dx * 1.25, 0.9, 0.94 - Math.abs(dx) * 0.4], 0.05, 0.015, 6), C.claw);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");

    m.bone("LegL", "Hips", [0.34, 0.95, 0]);
    m.add("LegL", limb([0.34, 0.95, 0], [0.38, 0.34, 0.04], 0.27, 0.2), C.fur);
    m.add("LegL", at(ball(0.26, 0.11, 0.36, 10), [0.4, 0.13, 0.2]), C.pink);
    for (const dx of [-0.14, 0, 0.14]) m.add("LegL", at(ball(0.07, 0.06, 0.09, 6), [0.4 + dx, 0.12, 0.54 - Math.abs(dx) * 0.4]), C.pinkDark);
    m.mirror("LegL", "LegR");

    m.bone("Tail1", "Hips", [0, 0.9, -0.6]);
    m.add("Tail1", limb([0, 0.9, -0.66], [0, 0.8, -1.1], 0.09, 0.07, 8), C.pink);
    m.bone("Tail2", "Tail1", [0, 0.8, -1.1]);
    m.add("Tail2", limb([0, 0.8, -1.1], [0, 0.88, -1.42], 0.07, 0.03, 8), C.pink);
    out.push(m);
  }

  // ---------- RootHall: the hall under the oldest tree ----------
  {
    const m = model("RootHall");
    const N = 56, X0 = -52, X1 = 52, Z0 = -62, Z1 = 46;
    const rows = []; for (let j = 0; j <= N; j++) { const r = []; for (let i = 0; i <= N; i++) r.push(H(X0 + ((X1 - X0) * i) / N, Z0 + ((Z1 - Z0) * j) / N)); rows.push(r); }
    m.bone("Floor", null, [0, 0, 0]);
    m.add("Floor", field(X0, Z0, X1, Z1, rows), C.moss);
    // stones round the pool
    for (let k = 0; k < 11; k++) { const a = k * 0.571 + 0.2, r = 5.6 + rnd(k) * 0.9, x = -10 + Math.sin(a) * r, z = -9 + Math.cos(a) * r; m.add("Floor", at(lo(0.7 + rnd(k + 9) * 0.6, 0.4, 0.6 + rnd(k + 5) * 0.5), [x, H(x, z) + 0.05, z], [0, rnd(k + 3) * 360, 0]), C.stone); }
    // moss in three greens, and bare earth, laid over the floor in soft pads
    m.bone("Moss", null, [0, 0, 0]);
    for (let k = 0; k < 150; k++) {
      const x = (rnd(k * 3 + 1) - 0.5) * 84, z = rnd(k * 3 + 2) * 90 - 54;
      if (Math.hypot(x + 10, z + 9) < 6.5 || Math.hypot(x, (z + 8) * 0.92) > 40) continue;
      const s = 0.9 + rnd(k * 3 + 3) * 2.2;
      m.add("Moss", at(lo(s, 0.16 + rnd(k) * 0.14, s * (0.6 + rnd(k + 7) * 0.5)), [x, H(x, z) + 0.03, z], [0, rnd(k + 11) * 360, 0]), [C.mossLight, C.mossDark, C.mossLight, C.earth, C.mossDark][k % 5]);
    }
    // moss mounds: round bright cushions, the reference's strongest shapes on the floor
    for (const [x, z, r, h] of [[8.5, 8, 2.6, 1.1], [-6.5, 5.5, 2.2, 0.9], [9, -14, 3.4, 1.5], [-16, -2, 3.0, 1.3], [-3.5, -11, 2.4, 1.0], [15, 9, 2.8, 1.2], [-13, 11, 2.2, 0.9], [20, -8, 3.6, 1.6], [3, -22, 4.0, 1.8], [-20, -20, 3.8, 1.7], [0.5, 12, 1.8, 0.7]]) m.add("Moss", at(ball(r, h, r * 0.86, 12), [x, H(x, z) - h * 0.25, z], [0, x * 20, 0]), C.mossBright);
    // the shell: the hollow of the tree seen from inside, dark, with root ribs running up it
    m.bone("Shell", null, [0, 0, 0]);
    m.add("Shell", inside(at(ball(46, 48, 50, 28), [0, -4, -8])), C.shell);
    m.bone("RootsW", null, [0, 0, 0]);
    for (let i = 0; i < 14; i++) {
      const phi = (i / 14) * Math.PI * 2 + 0.2, w = 0.5 * Math.sin(i * 2.3), pts = [];
      for (const [e, k] of [[-0.08, 0.955], [0.22, 0.95], [0.52, 0.955], [0.82, 0.96], [1.08, 0.965]]) pts.push([46 * k * Math.cos(e) * Math.sin(phi + w * e), -4 + 48 * k * Math.sin(e), -8 + 50 * k * Math.cos(e) * Math.cos(phi + w * e)]);
      m.add("RootsW", tube(pts, (u) => 2.6 - 1.3 * u, 8, 18), i % 3 ? C.barkDark : C.bark);
      // and each rib flows out over the floor as a root (the reference's fluted walls that pour into the moss)
      const fx = (k) => 46 * k * Math.sin(phi + 0.12 * Math.sin(i * 1.9 + k * 9)), fz = (k) => -8 + 50 * k * Math.cos(phi + 0.12 * Math.sin(i * 1.9 + k * 9));
      m.add("RootsW", tube([[fx(0.93), 6, fz(0.93)], [fx(0.8), H(fx(0.8), fz(0.8)) + 1.2, fz(0.8)], [fx(0.66), H(fx(0.66), fz(0.66)) + 0.3, fz(0.66)], [fx(0.54), H(fx(0.54), fz(0.54)) - 0.3, fz(0.54)]], (u) => 2.4 - 2.0 * u, 8, 14), i % 2 ? C.bark : C.barkLight);
    }
    // the great roots: arches across the hall, each as thick as a house. None crosses the ray's path (z -13 to -3).
    const ARCH = [{ z: 14, peak: 30, w: 30, r: 3.4, skew: 2 }, { z: 3, peak: 33, w: 33, r: 3.0, skew: -3 }, { z: -22, peak: 34, w: 34, r: 3.6, skew: 4 }, { z: -34, peak: 30, w: 30, r: 3.2, skew: -2 }, { z: -46, peak: 25, w: 24, r: 3.0, skew: 1 }];
    m.bone("RootsA", null, [0, 0, 0]);
    ARCH.forEach((a, k) => {
      const pts = [[-a.w, -3, a.z + a.skew], [-a.w * 0.86, 9, a.z], [-a.w * 0.5, a.peak * 0.8, a.z - a.skew * 0.5], [a.skew, a.peak, a.z], [a.w * 0.5, a.peak * 0.8, a.z + a.skew * 0.5], [a.w * 0.86, 9, a.z], [a.w, -3, a.z - a.skew]];
      m.add("RootsA", tube(pts, (u) => a.r * (1 - 0.3 * Math.sin(u * Math.PI)), 12, 36), k % 2 ? C.bark : C.barkLight);
      // a second, thinner root twisting along each arch
      m.add("RootsA", tube(pts.map(([x, y, z], i) => [x * 0.93, y - 1.5 + Math.sin(i * 1.7) * 1.2, z + 2.6 * Math.cos(i * 1.3)]), a.r * 0.4, 8, 30), C.barkDark);
      // buttress feet where it enters the floor
      for (const s of [-1, 1]) m.add("RootsA", at(lo(a.r * 1.7, 2.6, a.r * 1.5, 8, 5), [a.w * 0.97 * s, H(a.w * 0.97 * s, a.z) - 0.6, a.z - a.skew * s], [0, k * 40, 0]), C.bark);
    });
    // roots across the floor, running from the walls to the mound and the pool
    m.bone("RootsF", null, [0, 0, 0]);
    const FLOOR = [
      [[[-30, -1, 6], [-20, 0.3, 2], [-13, 0.2, -1], [-7, 0.1, -3]], 1.1, 0.3],
      [[[28, -1, -14], [18, 0.5, -10], [9, 0.3, -7.5], [3.5, 0.5, -5]], 1.0, 0.3],
      [[[-8, -1, -40], [-5, 0.6, -26], [-2, 0.4, -14], [-0.5, 0.7, -7]], 1.3, 0.35],
      [[[14, -1, -38], [10, 0.5, -26], [7, 0.3, -17], [2, 0.6, -8]], 1.0, 0.3],
      [[[-28, -1, -24], [-20, 0.6, -17], [-15.5, 0.2, -13]], 1.2, 0.5],
      [[[24, -1, 10], [17, 0.4, 7], [12, 0.2, 2]], 0.9, 0.3],
      [[[-22, -1, 20], [-14, 0.4, 14], [-9, 0.15, 9]], 0.9, 0.25],
    ];
    FLOOR.forEach(([pts, r0, r1], k) => {
      m.add("RootsF", tube(pts, (u) => r0 + (r1 - r0) * u, 8, 22), k % 2 ? C.bark : C.barkLight);
      for (let j = 1; j < 6; j++) { const u = j / 6, a = Math.floor(u * (pts.length - 1)), f = u * (pts.length - 1) - a, p = pts[a], q = pts[Math.min(a + 1, pts.length - 1)]; m.add("Moss", at(lo(0.9, 0.22, 0.7), [p[0] + (q[0] - p[0]) * f, p[1] + (q[1] - p[1]) * f + (r0 + (r1 - r0) * u) * 0.8, p[2] + (q[2] - p[2]) * f], [0, j * 50, 0]), j % 2 ? C.mossLight : C.moss); }
    });
    // rootlets hanging from the roof, kept clear of the ray
    const A = new THREE.Vector3(...KNOT), B = new THREE.Vector3(...CRADLE), AB = B.clone().sub(A);
    for (let k = 0; k < 44; k++) {
      const x = (rnd(k * 5 + 2) - 0.5) * 60, z = rnd(k * 5 + 3) * 70 - 46, q = 1 - (x / 46) ** 2 - ((z + 8) / 50) ** 2;
      if (q < 0.25) continue;
      const top = -4 + 48 * Math.sqrt(q) - 0.5, len = 5 + rnd(k * 5 + 4) * 12, P = new THREE.Vector3(x, top - len / 2, z);
      const tt = Math.min(1, Math.max(0, P.clone().sub(A).dot(AB) / AB.lengthSq()));
      if (P.distanceTo(A.clone().add(AB.clone().multiplyScalar(tt))) < 7) continue;
      m.add("RootsF", tube([[x, top, z], [x + (rnd(k) - 0.5) * 1.6, top - len * 0.5, z + (rnd(k + 2) - 0.5) * 1.6], [x + (rnd(k + 4) - 0.5) * 2.4, top - len, z + (rnd(k + 6) - 0.5) * 2.4]], (u) => 0.36 - 0.3 * u, 5, 8), k % 2 ? C.barkDark : C.bark);
    }
    // the knot hole: a ring of old bark on the shell, and the day behind it
    const n = AB.clone().normalize(), uu = new THREE.Vector3().crossVectors(n, new THREE.Vector3(0, 0, 1)).normalize(), vv = new THREE.Vector3().crossVectors(n, uu);
    m.bone("Knot", null, [0, 0, 0]);
    const kr = []; for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2, r = 3.3 + 0.3 * Math.sin(a * 3); kr.push([A.x + (uu.x * Math.cos(a) + vv.x * Math.sin(a)) * r, A.y + (uu.y * Math.cos(a) + vv.y * Math.sin(a)) * r, A.z + (uu.z * Math.cos(a) + vv.z * Math.sin(a)) * r]); }
    m.add("Knot", tube(kr, 1.1, 8, 32), C.bark);
    m.bone("KnotGlow", null, [0, 0, 0], "Neon");
    const disc = new THREE.CircleGeometry(3.2, 24);
    disc.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 0, 1), n));
    disc.translate(A.x + n.x * 0.4, A.y + n.y * 0.4, A.z + n.z * 0.4);
    m.add("KnotGlow", disc, C.sky);
    out.push(m);
  }

  // ---------- RootCradle: the small roots that close over the sap ----------
  {
    const m = model("RootCradle");
    m.bone("Base", null, [0, 0, 0]);
    m.add("Base", lathe([[1.55, -0.2], [1.3, 0.3], [0.9, 0.6], [0.5, 0.72], [0.02, 0.76]], 18), C.warm);
    for (let k = 0; k < 6; k++) { const a = k * 1.05 + 0.4; m.add("Base", tube([[Math.sin(a) * 0.9, 0.5, Math.cos(a) * 0.9], [Math.sin(a + 0.2) * 1.7, 0.2, Math.cos(a + 0.2) * 1.7], [Math.sin(a + 0.5) * 2.6, -0.3, Math.cos(a + 0.5) * 2.6]], (u) => 0.2 - 0.12 * u, 6, 10), k % 2 ? C.warmDark : C.warmLight); }
    for (let k = 0; k < 5; k++) { const a = k * 1.26; m.add("Base", at(lo(0.4, 0.12, 0.34), [Math.sin(a) * 1.05, 0.5, Math.cos(a) * 1.05], [0, k * 70, 0]), k % 2 ? C.moss : C.mossLight); }
    // seven fingers, open like a hand at rest: (radius from the axis, height) along each, in three bones
    const SEG = [[[0.75, 0.45], [1.25, 1.15], [1.45, 1.8]], [[1.45, 1.8], [1.5, 2.4], [1.35, 2.95]], [[1.35, 2.95], [1.15, 3.35], [0.85, 3.6]]];
    const RAD = [[0.2, 0.16], [0.16, 0.12], [0.12, 0.04]];
    for (let i = 1; i <= 7; i++) {
      const a = ((i - 1) / 7) * Math.PI * 2, sx = Math.sin(a), cz = Math.cos(a), P = ([r, y], tw = 0) => [sx * r + cz * tw, y, cz * r - sx * tw];
      ["a", "b", "c"].forEach((suf, s) => {
        m.bone("F" + i + suf, s ? "F" + i + "abc"[s - 1] : "Base", P(SEG[s][0]));
        m.add("F" + i + suf, tube([P(SEG[s][0]), P(SEG[s][1], 0.06 * (s - 1)), P(SEG[s][2])], (u) => RAD[s][0] + (RAD[s][1] - RAD[s][0]) * u, 7, 8), (i + s) % 3 ? C.warm : C.warmLight);
        if (s < 2) m.add("F" + i + suf, at(lo(RAD[s][0] * 1.25, RAD[s][0] * 1.25, RAD[s][0] * 1.25), P(SEG[s][0])), C.warmDark);
      });
      m.add("F" + i + "b", at(lo(0.16, 0.07, 0.12), P([SEG[1][1][0] + 0.1, SEG[1][1][1]])), i % 2 ? C.mossLight : C.moss);
    }
    out.push(m);
  }

  // ---------- props ----------
  {
    const m = model("SapBead"); // the drop of amber: lit from inside
    m.bone("Bead", null, [0, 0, 0], "Neon");
    m.add("Bead", ball(0.34, 0.36, 0.34, 18), C.amber);
    m.add("Bead", limb([0, 0.2, 0], [0, 0.62, 0], 0.2, 0.03, 10), C.amber);
    m.bone("Shine", "Bead", [0, 0, 0], "Neon");
    m.add("Shine", at(ball(0.09, 0.12, 0.05, 8), [-0.14, 0.12, 0.27], [0, -24, 20]), C.amberLight);
    out.push(m);
  }
  {
    const m = model("GlowShroom"); // three mushrooms; the caps are their own bone, so the scene can make them glow in a wave
    m.bone("Stem", null, [0, 0, 0]);
    m.bone("Cap", "Stem", [0, 0, 0], "Neon");
    for (const [x, z, h, r, lean] of [[0, 0, 1.5, 0.5, 4], [0.7, 0.2, 0.95, 0.34, -10], [-0.55, 0.4, 0.6, 0.26, 12]]) {
      const tx = x + Math.sin((lean * Math.PI) / 180) * h;
      m.add("Stem", limb([x, -0.1, z], [tx, h, z], r * 0.2, r * 0.13, 8), C.stem);
      m.add("Stem", at(ball(r * 1.2, 0.04, r * 1.2, 12), [tx, h, z]), C.stemDark);
      const cap = new THREE.SphereGeometry(1, 14, 7, 0, Math.PI * 2, 0, Math.PI / 2); cap.scale(r * 1.3, r * 0.6, r * 1.3); cap.computeVertexNormals();
      m.add("Cap", at(cap, [tx, h, z], [0, 0, -lean * 0.6]), C.teal);
    }
    out.push(m);
  }
  {
    const m = model("WateringCan"); // tin, with a long spout and a rose; the spout points to +Z
    m.bone("Can", null, [0, 0, 0]);
    m.add("Can", lathe([[0.02, 0], [0.42, 0.02], [0.45, 0.7], [0.4, 0.72]], 18), C.tin);
    m.add("Can", at(ball(0.4, 0.03, 0.4, 14), [0, 0.6, 0]), C.tinDark);
    for (const y of [0.16, 0.7]) { const p = []; for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2; p.push([Math.sin(a) * 0.45, y, Math.cos(a) * 0.45]); } m.add("Can", tube(p, 0.03, 6, 32), C.tinDark); }
    m.add("Can", limb([0, 0.25, 0.4], [0, 0.62, 1.0], 0.1, 0.06, 10), C.tin);
    m.add("Can", at(ball(0.15, 0.15, 0.05, 12), [0, 0.66, 1.06], [-32, 0, 0]), C.tinDark);
    m.add("Can", tube([[0, 0.66, -0.4], [0, 0.8, -0.75], [0, 0.4, -0.85], [0, 0.12, -0.42]], 0.04, 6, 14), C.tinDark);
    m.add("Can", tube([[-0.4, 0.7, 0], [0, 1.05, 0], [0.4, 0.7, 0]], 0.035, 6, 12), C.tinDark);
    out.push(m);
  }
  {
    const m = model("LightShaft"); // the ray: two soft cones from the knot hole (the origin) down the -Y axis; the scene aims and fades them
    m.bone("Shaft", null, [0, 0, 0], "Neon");
    m.add("Shaft", lathe([[5.0, -44], [1.3, 0]], 24), C.ray);
    m.bone("Core", null, [0, 0, 0], "Neon");
    m.add("Core", lathe([[2.6, -44], [0.7, 0]], 18), C.rayCore);
    out.push(m);
  }
  return out;
}
