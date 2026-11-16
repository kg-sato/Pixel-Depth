// Kobold-Copper Pickaxe biography: "Made by committee." Three kobolds open a green copper vein in a cramped tunnel under the
// roots and hammer the cold copper in turn. Scene bible: vault "Forge Biographies - Scene Bibles (2026-11-15)", Kobold-Copper.
// References (when generated): refs/forge/sheets/copper_setting_s11.png and kobold_views_s11.png.
// Models: KoboldKit (same bone names as BoltKit and OtterKit, so poses carry over; Helmet, Flame, Flowers and Whistle are
// shown or hidden per kobold, so one kit serves all three at different scales), CopperMine (the tunnel: it is seen from
// INSIDE, so its shell faces inward), Lantern, StumpAnvil, CopperLump, Hammer, MinePick, CratesTable, BucketLift.
// Front of every model is +Z. Units are studs. The tunnel runs along Z: the back wall with the vein is at z = -8, the cameras
// stand toward +Z. Palette: copper #c8743a, verdigris #3fa58c, tunnel dark #4a3550, lantern #ffd98a.
export const name = "copper";

const C = {
  skin: "#7fa69c", skinDark: "#5c8279", skinLight: "#a9c4b6", earIn: "#d9a09a", nose: "#2a2030", snout: "#d9a09a", shorts: "#3a3440", eye: "#ffd98a", pupil: "#2a1c14", white: "#ffffff", fang: "#f6f0dc",
  leather: "#8a5a36", leatherDark: "#6a4226", leatherLight: "#a8744a", stitch: "#e2c79a",
  copper: "#c8743a", copperDark: "#9a5428", copperLight: "#e8a064", copperDull: "#7c5a4c", copperDullDark: "#5e463e", verdigris: "#3fa58c", verdDark: "#2b7f6c", verdLight: "#7fd8bd", glint: "#9ff0d6",
  rock: "#4a3550", rockDark: "#372640", rockLight: "#62496a", rockWarm: "#6a4c5a", floor: "#7a5240", floorLight: "#96684c",
  wood: "#8a5a36", woodDark: "#6e4428", woodLight: "#a87a4c", root: "#7a4a2c", rootLight: "#a8683a",
  iron: "#4a4652", ironLight: "#7a7684", rope: "#c9b384", ropeDark: "#a08a60", lamp: "#ffd98a", wax: "#f2ead2",
  petal: "#fff4f0", petalPink: "#f4a6c0", pollen: "#ffcf4a", tin: "#b8bcc6", tea: "#d9c9a4", teaMark: "#b0503a", enamel: "#4a8f9a",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, field, model, rnd } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 7, hs = 5) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const half = (rx, ry, rz, seg = 18) => { const g = new THREE.SphereGeometry(1, seg, 10, 0, Math.PI * 2, 0, Math.PI / 2); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const ring = (cx, cy, cz, rx, rz, r, wob = 0, n = 16) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([cx + Math.sin(a) * rx, cy + Math.sin(a * 2) * wob, cz + Math.cos(a) * rz]); } return tube(p, r, 7, n * 2); };
  // a standing ring: in the XY plane (axis "z") or the YZ plane (axis "x")
  const vring = (cx, cy, cz, rad, r, axis = "z", n = 14) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push(axis === "z" ? [cx + Math.sin(a) * rad, cy + Math.cos(a) * rad, cz] : [cx, cy + Math.cos(a) * rad, cz + Math.sin(a) * rad]); } return tube(p, r, 6, n * 2); };
  // smooth value noise on a grid, 0..1
  const vn = (x, y, s = 0) => {
    const xi = Math.floor(x), yi = Math.floor(y), xf = x - xi, yf = y - yi, h = (a, b) => rnd(a * 157.3 + b * 311.7 + s * 71.1);
    const u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
    return (h(xi, yi) * (1 - u) + h(xi + 1, yi) * u) * (1 - v) + (h(xi, yi + 1) * (1 - u) + h(xi + 1, yi + 1) * u) * v;
  };
  // turn every triangle so it faces the point target(centroid): the tunnel is looked at from inside
  const facing = (g, target) => {
    if (!g.index) { const idx = []; for (let k = 0; k < g.getAttribute("position").count; k++) idx.push(k); g.setIndex(idx); }
    const p = g.getAttribute("position"), ix = g.index.array, a = new THREE.Vector3(), b = new THREE.Vector3(), c = new THREE.Vector3();
    for (let i = 0; i < ix.length; i += 3) {
      a.fromBufferAttribute(p, ix[i]); b.fromBufferAttribute(p, ix[i + 1]); c.fromBufferAttribute(p, ix[i + 2]);
      const n = b.clone().sub(a).cross(c.clone().sub(a)), cen = a.clone().add(b).add(c).multiplyScalar(1 / 3), t = target(cen);
      if (n.dot(new THREE.Vector3(t[0], t[1], t[2]).sub(cen)) < 0) { const s = ix[i + 1]; ix[i + 1] = ix[i + 2]; ix[i + 2] = s; }
    }
    g.computeVertexNormals();
    return g;
  };
  const grid = (nu, nv, pos, skip) => { // a sheet of (nu + 1) x (nv + 1) points from pos(i, j)
    const P = [], idx = [];
    for (let j = 0; j <= nv; j++) for (let i = 0; i <= nu; i++) P.push(...pos(i, j));
    const row = nu + 1;
    for (let j = 0; j < nv; j++) for (let i = 0; i < nu; i++) {
      if (skip && skip(i, j)) continue;
      const a = j * row + i, b = a + 1, c = a + row, d = c + 1;
      idx.push(a, c, b, b, c, d);
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(P, 3));
    g.setIndex(idx); g.computeVertexNormals();
    return g;
  };

  // ---------- KoboldKit: one kobold; the scene makes three of it ----------
  {
    const m = model("KoboldKit");
    m.bone("Hips", null, [0, 0.95, 0]);
    m.bone("Body", "Hips", [0, 0.95, 0]);
    m.add("Body", lathe([[0.02, 0.66], [0.5, 0.7], [0.72, 0.96], [0.74, 1.3], [0.6, 1.68], [0.44, 1.96], [0.02, 2.06]], 22), C.skin);
    m.add("Body", at(ball(0.4, 0.3, 0.2, 14), [0, 1.9, 0.3]), C.skinLight);
    // the leather apron: a bib, a skirt, a belt, a pocket with a stitched patch, two straps over the shoulders
    m.add("Body", at(ball(0.62, 0.5, 0.36, 18), [0, 1.14, 0.44]), C.leather);
    m.add("Body", at(ball(0.4, 0.34, 0.24, 14), [0, 1.62, 0.4]), C.leather);
    m.add("Body", ring(0, 1.32, 0, 0.76, 0.72, 0.07, 0.02), C.leatherDark);
    m.add("Body", at(pillow(0.4, 0.3, 0.12, 0.4, 8), [0.2, 1.02, 0.78], [-12, 12, 0]), C.leatherLight);
    m.add("Body", at(pillow(0.2, 0.18, 0.06, 0.4, 6), [-0.3, 1.18, 0.76], [-10, -18, 12]), C.leatherDark);
    for (const [x, y] of [[-0.38, 1.26], [-0.22, 1.26], [-0.38, 1.1], [-0.22, 1.1]]) m.add("Body", at(lo(0.025, 0.025, 0.02), [x, y, 0.8 - Math.abs(x + 0.3) * 0.2]), C.stitch);
    m.add("Body", tube([[0.3, 1.84, 0.5], [0.42, 2.0, 0.1], [0.36, 1.94, -0.36], [0.24, 1.4, -0.66]], 0.06, 7, 14), C.leatherDark);
    m.add("Body", tube([[-0.3, 1.84, 0.5], [-0.42, 2.0, 0.1], [-0.36, 1.94, -0.36], [-0.24, 1.4, -0.66]], 0.06, 7, 14), C.leatherDark);
    m.add("Body", at(lo(0.07, 0.07, 0.05), [0.3, 1.82, 0.56]), C.copper);
    m.add("Body", at(lo(0.07, 0.07, 0.05), [-0.3, 1.82, 0.56]), C.copper);

    m.bone("Head", "Body", [0, 2.02, 0]);
    m.add("Head", at(ball(0.98, 0.84, 0.9, 24), [0, 2.74, 0.04]), C.skin);
    m.add("Head", at(ball(0.5, 0.34, 0.4, 18), [0, 2.46, 0.66]), C.skinLight); // a short blunt muzzle
    m.add("Head", at(ball(0.21, 0.18, 0.17, 12), [0, 2.6, 1.0]), C.snout);
    m.add("Head", at(lo(0.06, 0.035, 0.03), [-0.06, 2.69, 1.14]), C.white);
    for (const s of [-1, 1]) m.add("Head", at(lo(0.035, 0.03, 0.03), [0.08 * s, 2.52, 1.13]), C.nose);
    m.add("Head", tube([[-0.3, 2.4, 0.9], [-0.12, 2.33, 1.0], [0, 2.36, 1.02], [0.12, 2.33, 1.0], [0.3, 2.4, 0.9]], 0.024, 6, 12), C.nose);
    m.add("Head", limb([0.2, 2.36, 0.94], [0.21, 2.2, 0.97], 0.05, 0.012, 6), C.fang); // one snaggle tooth
    for (const s of [-1, 1]) {
      m.add("Head", at(ball(0.16, 0.04, 0.06, 8), [0.44 * s, 3.2, 0.72], [0, 16 * s, 14 * s]), C.skinDark);
      for (const [dx, dy] of [[0.0, 0], [0.1, 0.07], [0.12, -0.06]]) m.add("Head", at(lo(0.03, 0.03, 0.02), [(0.66 + dx) * s, 2.52 + dy, 0.66 - dx * 0.5]), C.skinDark); // freckles
    }
    // lamp eyes: the round amber lens glows (a Neon bone), the slit pupil and the highlight sit on it
    m.bone("Eyes", "Head", [0, 2.86, 0.82], "Neon");
    for (const s of [-1, 1]) m.add("Eyes", at(ball(0.25, 0.28, 0.1, 14), [0.44 * s, 2.86, 0.78], [0, 14 * s, 0]), C.eye);
    m.bone("Pupils", "Head", [0, 2.86, 0.9]);
    for (const s of [-1, 1]) {
      m.add("Pupils", at(ball(0.13, 0.15, 0.04, 10), [0.45 * s, 2.85, 0.875], [0, 14 * s, 0]), C.pupil);
      m.add("Pupils", at(ball(0.045, 0.05, 0.03, 6), [0.45 * s + 0.07, 2.95, 0.885]), C.white);
      m.add("Pupils", vring(0.44 * s, 2.86, 0.8, 0.27, 0.04), C.nose);
    }
    m.bone("EyesShut", "Head", [0, 2.86, 0.9]);
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.24 * s, 2.82, 0.84], [0.44 * s, 2.93, 0.9], [0.64 * s, 2.82, 0.8]], 0.04, 6, 10), C.skinDark);
    // the ears: very large and pointed, each on its own bone so they can flap in an argument
    m.bone("EarL", "Head", [0.8, 2.8, 0]);
    m.add("EarL", at(puff([[0, -0.34], [0.6, -0.4], [1.25, 0.3], [0.62, 0.52], [0.06, 0.4]], 0.1, 0.06), [0.76, 2.78, 0], [0, -18, 0]), C.skin);
    m.add("EarL", at(puff([[0.16, -0.2], [0.56, -0.24], [0.98, 0.22], [0.56, 0.36], [0.2, 0.26]], 0.04, 0.03), [0.78, 2.78, 0.09], [0, -18, 0]), C.earIn);
    m.mirror("EarL", "EarR");

    m.bone("ArmL", "Body", [0.6, 1.8, 0.05]);
    m.add("ArmL", limb([0.6, 1.8, 0.05], [0.94, 1.42, 0.14], 0.18, 0.155), C.skin);
    m.bone("ForeL", "ArmL", [0.94, 1.42, 0.14]);
    m.add("ForeL", limb([0.94, 1.42, 0.14], [1.02, 1.06, 0.3], 0.155, 0.17), C.skin);
    m.add("ForeL", ring(0.99, 1.2, 0.24, 0.19, 0.19, 0.045), C.leatherDark); // a wrist wrap
    m.add("ForeL", at(ball(0.21, 0.18, 0.23), [1.03, 0.98, 0.34]), C.skinDark);
    for (const dx of [-0.13, 0, 0.13]) m.add("ForeL", at(ball(0.075, 0.085, 0.1, 8), [1.03 + dx, 0.88, 0.48 - Math.abs(dx) * 0.3]), C.skinDark);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");

    m.bone("LegL", "Hips", [0.34, 0.95, 0]);
    m.add("LegL", limb([0.34, 0.95, 0], [0.38, 0.34, 0.04], 0.24, 0.2), C.skin);
    m.add("LegL", at(ball(0.29, 0.2, 0.28, 12), [0.35, 0.8, 0.01]), C.shorts);
    m.add("LegL", at(ball(0.3, 0.13, 0.44), [0.4, 0.14, 0.26]), C.skinDark); // big flat feet
    for (const dx of [-0.16, 0, 0.16]) m.add("LegL", at(ball(0.085, 0.075, 0.1, 8), [0.4 + dx, 0.14, 0.66 - Math.abs(dx) * 0.4]), C.snout);
    m.mirror("LegL", "LegR");

    m.bone("Tail1", "Hips", [0, 0.9, -0.5]);
    m.add("Tail1", limb([0, 0.9, -0.45], [0, 0.7, -1.2], 0.15, 0.1, 10), C.skin);
    m.bone("Tail2", "Tail1", [0, 0.7, -1.2]);
    m.add("Tail2", limb([0, 0.7, -1.2], [0, 0.94, -1.86], 0.1, 0.05, 10), C.skin);
    m.add("Tail2", at(ball(0.13, 0.11, 0.17, 8), [0, 0.98, -1.96], [-20, 0, 0]), C.skinDark);

    // what tells the three apart
    m.bone("Helmet", "Head", [0, 3.28, 0]);
    m.add("Helmet", at(half(0.88, 0.64, 0.86, 20), [0, 3.24, 0.02]), C.copper);
    m.add("Helmet", ring(0, 3.25, 0.02, 0.92, 0.9, 0.075, 0.015, 20), C.copperDark);
    m.add("Helmet", at(ball(0.2, 0.12, 0.05, 8), [0.36, 3.56, 0.62], [-30, 28, 0]), C.copperDark); // a dent
    m.add("Helmet", at(ball(0.14, 0.2, 0.05, 8), [-0.5, 3.5, 0.5], [-26, -40, 0]), C.copperLight);
    for (let k = 0; k < 8; k++) { const a = (k / 8) * Math.PI * 2; m.add("Helmet", at(lo(0.04, 0.04, 0.04), [Math.sin(a) * 0.84, 3.34, 0.02 + Math.cos(a) * 0.82]), C.copperLight); }
    m.add("Helmet", ring(0, 3.42, 0.02, 0.84, 0.82, 0.05, 0.01, 20), C.copperDark); // the cap's second band
    m.add("Helmet", at(lathe([[0.16, 0], [0.16, 0.06], [0.1, 0.08], [0.1, 0.12]], 10), [0, 3.84, 0.3]), C.copperDark); // the candle cup on the front
    m.add("Helmet", at(lathe([[0.075, 0], [0.075, 0.26], [0.03, 0.29]], 10), [0, 3.94, 0.3]), C.wax);
    m.bone("Flame", "Helmet", [0, 4.26, 0.3], "Neon");
    m.add("Flame", at(ball(0.065, 0.14, 0.065, 8), [0, 4.34, 0.3]), C.lamp);
    m.bone("Flowers", "Helmet", [0.5, 3.4, 0.5]);
    for (const [x, y, z, s, col] of [[0.62, 3.42, 0.56, 1, C.petal], [0.36, 3.52, 0.74, 0.8, C.petalPink], [0.8, 3.4, 0.24, 0.85, C.petalPink], [-0.2, 3.72, 0.62, 0.7, C.petal]]) {
      m.add("Flowers", at(lo(0.07 * s, 0.07 * s, 0.07 * s), [x, y, z]), C.pollen);
      for (let k = 0; k < 6; k++) { const a = (k / 6) * Math.PI * 2; m.add("Flowers", at(lo(0.085 * s, 0.03 * s, 0.085 * s), [x + Math.sin(a) * 0.13 * s, y - 0.02, z + Math.cos(a) * 0.13 * s]), col); }
      m.add("Flowers", limb([x, y - 0.03, z], [x * 0.9, y - 0.2, z * 0.86], 0.02, 0.02, 5), C.verdDark);
    }
    m.bone("Whistle", "Body", [0, 1.9, 0.5]);
    m.add("Whistle", tube([[0.36, 2.0, 0.2], [0.24, 1.84, 0.58], [0.04, 1.6, 0.74], [-0.2, 1.82, 0.6], [-0.36, 2.0, 0.2]], 0.025, 6, 16), C.teaMark);
    m.add("Whistle", at(lathe([[0.06, 0], [0.085, 0.05], [0.085, 0.2], [0.05, 0.26], [0.035, 0.34]], 10), [0.04, 1.5, 0.78], [0, 0, 100]), C.tin);
    m.add("Whistle", at(lo(0.04, 0.02, 0.03), [0.1, 1.56, 0.86]), C.nose);
    out.push(m);
  }

  // ---------- CopperMine: the tunnel, seen from inside ----------
  {
    const m = model("CopperMine");
    const W = 8, H = 8.5, Z0 = -8.7, Z1 = 18, NA = 26, NJ = 34;
    const HOLES = [{ side: 1, z: -2, yaw: -1 }, { side: -1, z: 5, yaw: -1 }]; // side tunnels: +X wall near the back, -X wall nearer the cameras
    const wallAt = (i, j) => { // one point of the arch: a boxy vault, rough with rock
      const th = (i / NA) * Math.PI, z = Z0 + ((Z1 - Z0) * j) / NJ, c = Math.cos(th), s = Math.sin(th);
      const n = (vn(i * 0.55, j * 0.5, 3) - 0.5) * 1.3 + (vn(i * 1.7, j * 1.6, 4) - 0.5) * 0.45;
      const x = (W + n) * Math.sign(c) * Math.pow(Math.abs(c), 0.5), y = (H + n * 0.8) * Math.pow(s, 0.7) - 0.3;
      return [x, y, z + (vn(i * 0.9, j * 0.9, 5) - 0.5) * 0.3];
    };
    const inHole = (i, j) => {
      const a = wallAt(i, j), b = wallAt(i + 1, j + 1), x = (a[0] + b[0]) / 2, y = (a[1] + b[1]) / 2, z = (a[2] + b[2]) / 2;
      return HOLES.some((h) => Math.sign(x) === h.side && Math.abs(z - h.z) < 2.1 && y < 4.2 && Math.abs(x) > 5);
    };
    m.bone("Rock", null, [0, 0, 0]);
    m.add("Rock", facing(grid(NA, NJ, wallAt, inHole), (c) => [0, 3.2, c.z]), C.rock);
    m.add("Rock", field(-24, Z0 - 6, 24, Z1, Array.from({ length: 29 }, (_, j) => Array.from({ length: 41 }, (_, i) => (vn(i * 0.6, j * 0.6, 9) - 0.5) * 0.22 + (vn(i * 2.1, j * 2.1, 10) - 0.5) * 0.08))), C.floor);
    m.add("Rock", facing(grid(22, 14, (i, j) => { const x = -9.5 + (19 * i) / 22, y = -0.5 + (10 * j) / 14; return [x, y, -8 + (vn(i * 0.7, j * 0.7, 6) - 0.5) * 0.5]; }), () => [0, 3, 6]), C.rockDark); // the back wall
    m.add("Rock", facing(grid(8, 8, (i, j) => [-9 + (18 * i) / 8, -0.5 + (10 * j) / 8, Z1]), () => [0, 3, 0]), C.rockDark); // the dark behind the cameras
    for (const h of HOLES) { // each side tunnel curves away into the dark
      const x0 = h.side * 6.4, pts = [[x0, 2.1, h.z], [h.side * 11, 2.2, h.z - 1.2], [h.side * 15.5, 2.5, h.z - 4.5], [h.side * 18.5, 2.8, h.z - 10]];
      const g = tube(pts, 4.0, 14, 12);
      g.setIndex(Array.from(g.index.array).slice(0, -14 * 6)); // without the two end fans: the mouth stays open
      m.add("Rock", at(lo(4.4, 4.4, 1.2, 10, 6), [h.side * 19, 2.8, h.z - 11], [0, h.side * 25, 0]), C.rockDark); // the far end closes in dark rock
      const curve = new THREE.CatmullRomCurve3(pts.map((p) => new THREE.Vector3(...p)));
      m.add("Rock", facing(g, (c) => { let best = null, bd = 1e9; for (let k = 0; k <= 20; k++) { const p = curve.getPointAt(k / 20), d = p.distanceTo(c); if (d < bd) { bd = d; best = p; } } return [best.x, best.y, best.z]; }), C.rockDark);
    }
    for (let k = 0; k < 70; k++) { // lumps and ledges that catch the lantern
      const i = 1 + Math.floor(rnd(k * 3.1) * (NA - 2)), j = 1 + Math.floor(rnd(k * 5.3 + 1) * (NJ - 3)), p = wallAt(i, j);
      if (inHole(i, j) || inHole(i - 1, j - 1)) continue;
      const s = 0.5 + rnd(k * 7.7) * 0.9;
      m.add("Rock", at(lo(s, s * (0.5 + rnd(k) * 0.4), s * 0.9, 7, 5), [p[0] * 0.985, p[1] * 0.985, p[2]], [rnd(k * 2) * 40, rnd(k * 4) * 360, rnd(k * 6) * 40]), [C.rockLight, C.rockWarm, C.rock, C.rockDark][k % 4]);
    }
    for (let k = 0; k < 16; k++) { // big rounded slabs set in the walls and the back
      const back = k < 6, i = 2 + Math.floor(rnd(k * 2.9 + 3) * (NA - 4)), j = 3 + Math.floor(rnd(k * 6.7 + 2) * (NJ - 8)), p = back ? [-7.5 + k * 3 + rnd(k) * 1.2, 0.8 + rnd(k * 3) * 1.2, -8.1] : wallAt(i, j);
      if (!back && (inHole(i, j) || inHole(i - 1, j - 1) || inHole(i, j - 1) || inHole(i - 1, j))) continue;
      const sz = 1.5 + rnd(k * 5.1) * 1.1;
      m.add("Rock", at(lo(sz, sz * (0.75 + rnd(k * 2) * 0.4), sz * 0.7, 10, 7), [p[0] * (back ? 1 : 1.02), p[1] * (back ? 1 : 1.02), p[2]], [rnd(k * 2) * 30, rnd(k * 4) * 360, rnd(k * 6) * 30]), [C.rockLight, C.rock, C.rockWarm][k % 3]);
    }
    for (let k = 0; k < 26; k++) { // rubble on the floor, kept clear of the middle where they work
      const side = k % 2 ? 1 : -1, x = side * (3.6 + rnd(k * 1.9) * 3.4), z = Z0 + 1.5 + rnd(k * 4.3) * (Z1 - Z0 - 4), s = 0.2 + rnd(k * 8.1) * 0.45;
      m.add("Rock", at(lo(s, s * 0.6, s * 0.85, 6, 4), [x, s * 0.3, z], [0, rnd(k) * 360, 0]), [C.floorLight, C.rockLight, C.rockWarm][k % 3]);
    }

    // the vein across the back wall, the rock that hides it until the pick opens the wall, and its glints
    const VEIN = [[-7, 1.5], [-4.6, 2.5], [-2.1, 2.3], [0.4, 3.7], [3, 4.1], [5.2, 5.5], [7.2, 6.1]];
    const veinCurve = new THREE.CatmullRomCurve3(VEIN.map(([x, y]) => new THREE.Vector3(x, y, 0)));
    const flatTube = (pts, r, zs = 0.45) => at(at(tube(pts.map(([x, y]) => [x, y, 0]), r, 9, 30), [0, 0, 0], [0, 0, 0], [1, 1, zs]), [0, 0, -7.72]);
    m.bone("Vein", null, [0, 3.6, -7.7]);
    m.add("Vein", flatTube(VEIN, (u) => 0.5 - 0.22 * Math.abs(u - 0.5)), C.verdigris);
    m.add("Vein", flatTube([[-2.1, 2.3], [-1.2, 1.2], [-0.2, 0.5]], (u) => 0.28 - 0.16 * u), C.verdDark);
    m.add("Vein", flatTube([[0.4, 3.7], [-0.6, 5], [-0.9, 6.4]], (u) => 0.3 - 0.18 * u), C.verdigris);
    m.add("Vein", flatTube([[3, 4.1], [4.2, 3.0], [5.8, 2.6]], (u) => 0.26 - 0.15 * u), C.verdDark);
    for (let k = 0; k < 16; k++) { // green stain bleeding into the rock round it
      const p = veinCurve.getPointAt((k + 0.5) / 16);
      m.add("Vein", at(lo(0.8 + rnd(k) * 0.5, 0.5 + rnd(k * 2) * 0.4, 0.07, 8, 4), [p.x + (rnd(k * 3) - 0.5) * 0.8, p.y + (rnd(k * 5) - 0.5) * 0.9, -7.9], [0, 0, rnd(k * 7) * 180]), k % 2 ? C.verdDark : C.verdLight);
    }
    for (let k = 0; k < 14; k++) { // native copper showing in the green
      const p = veinCurve.getPointAt((k + 0.3) / 14), s = 0.12 + rnd(k * 9) * 0.14;
      m.add("Vein", at(lo(s, s * 0.8, s * 0.6, 6, 4), [p.x + (rnd(k * 11) - 0.5) * 0.4, p.y + (rnd(k * 13) - 0.5) * 0.3, -7.5], [rnd(k) * 60, rnd(k * 2) * 60, 0]), k % 3 ? C.copper : C.copperLight);
    }
    m.bone("VeinGlow", "Vein", [0, 3.6, -7.5], "Neon");
    for (let k = 0; k < 12; k++) { const p = veinCurve.getPointAt((k + 0.6) / 12); m.add("VeinGlow", at(lo(0.07 + rnd(k * 4) * 0.06, 0.07, 0.04, 6, 4), [p.x + (rnd(k * 6) - 0.5) * 0.5, p.y + (rnd(k * 8) - 0.5) * 0.4, -7.44]), C.glint); }
    m.bone("Cover", null, [0, 3.6, -7.5]);
    for (let k = 0; k < 20; k++) {
      const p = veinCurve.getPointAt(k / 19);
      m.add("Cover", at(lo(1.25 + rnd(k) * 0.4, 1.15 + rnd(k * 3) * 0.3, 0.55, 8, 6), [p.x, p.y + (rnd(k * 5) - 0.5) * 0.3, -7.62], [0, 0, rnd(k * 7) * 90]), [C.rock, C.rockDark, C.rockLight][k % 3]);
    }
    for (const [x, y] of [[-0.9, 0.9], [-0.8, 5.9], [5.2, 2.8], [-0.2, 0.3], [-0.9, 6.6]]) m.add("Cover", at(lo(1.1, 1.0, 0.5, 8, 6), [x, y, -7.62]), C.rock);

    // timber: three crooked frames, the frames of the side tunnels, the pole the lantern hangs from
    m.bone("Timber", null, [0, 0, 0]);
    const frame = (z, tilt, wide = 6.2, top = 6.7) => {
      m.add("Timber", at(pillow(0.72, top + 0.4, 0.72, 0.3, 8), [-wide, top / 2 - 0.1, z], [tilt * 0.4, 0, -4 - tilt]), C.wood);
      m.add("Timber", at(pillow(0.7, top + 0.4, 0.7, 0.3, 8), [wide, top / 2 - 0.1, z], [-tilt * 0.3, 0, 5 + tilt * 0.6]), C.woodDark);
      m.add("Timber", at(pillow(wide * 2 + 0.7, 0.78, 0.82, 0.3, 8), [0, top + 0.1, z], [0, tilt * 0.6, 2 + tilt * 0.5]), C.wood);
      m.add("Timber", limb([-wide + 0.2, top - 1.7, z], [-wide + 1.9, top - 0.1, z], 0.2, 0.2, 7), C.woodLight);
      m.add("Timber", limb([wide - 0.2, top - 1.9, z], [wide - 2.1, top - 0.15, z], 0.2, 0.2, 7), C.woodLight);
      for (const s of [-1, 1]) m.add("Timber", at(pillow(0.5, 0.26, 0.9, 0.4, 6), [s * wide, top - 0.24, z], [0, 0, s * 4]), C.woodDark); // wedges under the lintel
    };
    frame(-5.2, 2); frame(3.4, -3); frame(11.5, 1.5);
    m.add("Timber", tube([[-5.9, 7.0, -1.6], [-2, 7.28, -1.5], [2.2, 7.16, -1.7], [5.9, 7.05, -1.6]], 0.16, 8, 14), C.woodLight); // the lantern pole
    m.add("Timber", vring(-0.4, 7.02, -1.6, 0.12, 0.035), C.iron); // its hook: the Lantern hangs at (-0.4, 6.95, -1.6)
    for (const h of HOLES) {
      const x = h.side * 7.0;
      m.add("Timber", at(pillow(0.6, 5.2, 0.6, 0.3, 8), [x, 2.4, h.z - 2.35], [0, 0, h.side * 3]), C.woodDark);
      m.add("Timber", at(pillow(0.6, 5.2, 0.6, 0.3, 8), [x, 2.4, h.z + 2.35], [0, 0, h.side * -2]), C.wood);
      m.add("Timber", at(pillow(0.66, 0.66, 5.6, 0.3, 8), [x, 4.95, h.z], [3, 0, 0]), C.wood);
    }
    for (let k = 0; k < 7; k++) m.add("Timber", at(pillow(0.9, 0.12, 2.6, 0.3, 6), [-1.2 + (k % 2) * 0.5, 0.06, 6 + k * 1.7], [0, 80 + rnd(k) * 20, 0]), k % 2 ? C.woodDark : C.wood); // duckboards toward the cameras

    // roots through the roof, and one great root along it
    m.bone("Roots", null, [0, 7, 0]);
    for (let k = 0; k < 18; k++) {
      const x = (rnd(k * 2.3) - 0.5) * 11, z = Z0 + 2 + rnd(k * 6.1) * (Z1 - Z0 - 6), len = 1.2 + rnd(k * 9.7) * 2.6;
      const top = 8.4 - Math.abs(x) * 0.14, w = rnd(k * 4.4) - 0.5;
      m.add("Roots", tube([[x, top, z], [x + w * 0.5, top - len * 0.4, z + w * 0.3], [x - w * 0.3, top - len * 0.75, z - w * 0.4], [x + w * 0.2, top - len, z]], (u) => 0.13 - 0.1 * u, 6, 10), k % 3 ? C.root : C.rootLight);
    }
    m.add("Roots", tube([[-6, 6.6, -7], [-3.5, 7.9, -3], [-1, 8.1, 3], [2.5, 7.9, 9], [5.5, 6.9, 15]], (u) => 0.42 - 0.12 * u, 9, 22), C.root);
    m.add("Roots", tube([[6.2, 6.3, -6], [4, 7.7, -1], [3, 8.0, 5], [0, 8.1, 12]], (u) => 0.3 - 0.1 * u, 8, 18), C.rootLight);
    for (const [x, z, d, col] of [[-6.6, -7.2, 1, C.root], [6.4, -7.4, -1, C.rootLight], [-7.1, 0.5, 1, C.rootLight], [7.0, 2.6, -1, C.root], [-3.2, -7.7, 1, C.rootLight], [3.6, -7.7, -1, C.root], [-7.0, 8.5, 1, C.root], [6.9, 9.5, -1, C.rootLight]]) { // thick roots that come down the walls and grip the floor
      const back = Math.abs(z) > 7 && Math.abs(x) < 6;
      m.add("Roots", tube([[x * 0.5, 8.2, z + (back ? 2.5 : d)], [x * 0.82, 7.2, z + (back ? 0.8 : d * 0.4)], [x * (back ? 1 : 0.95), 4.6, z], [x * (back ? 1.05 : 0.9) + d * 0.3, 2.0, z + (back ? 0.3 : -d * 0.5)], [x * (back ? 1.1 : 0.84) + d * 0.6, 0.1, z + (back ? 0.9 : -d)]], (u) => 0.34 - 0.2 * u + 0.12 * Math.max(0, u - 0.85) * 6, 8, 20), col);
    }

    // the far lanterns in the side tunnels (the scene puts a dim light on each: authoring (14.5, 3.4, -5.4) and (-14.5, 3.4, 1.6))
    m.bone("FarLights", null, [0, 3.4, 0], "Neon");
    for (const h of HOLES) for (const [dx, dz, s] of [[14.5, -3.4, 0.22], [17.6, -8.6, 0.14]]) m.add("FarLights", at(lo(s, s * 1.2, s), [h.side * dx, 3.4, h.z + dz]), C.lamp);

    // clutter: the tool rack on the -X wall, the shrine of bent nails in the back corner, a coil of rope
    m.bone("Clutter", null, [0, 0, 0]);
    m.add("Clutter", at(pillow(0.22, 0.5, 3.6, 0.3, 8), [-6.9, 3.5, -3.6], [0, 0, 6]), C.woodLight);
    for (let k = 0; k < 4; k++) {
      const z = -4.9 + k * 0.9;
      m.add("Clutter", limb([-6.9, 3.6, z], [-6.5, 3.7, z], 0.05, 0.05, 6), C.iron);
      m.add("Clutter", limb([-6.6, 3.6, z], [-6.5, 2.2 - (k % 2) * 0.3, z + 0.05], 0.055, 0.055, 6), C.wood);
      m.add("Clutter", at(pillow(0.2, 0.26, k % 2 ? 0.7 : 0.4, 0.4, 6), [-6.5, 2.1 - (k % 2) * 0.3, z + 0.05]), k % 2 ? C.ironLight : C.iron);
    }
    for (const [y, w] of [[1.5, 2.6], [2.6, 2.2]]) { // shelves of jars by the rack
      m.add("Clutter", at(pillow(0.7, 0.12, w, 0.3, 6), [-6.5, y, 0.6], [0, 0, 4]), C.wood);
      for (let k = 0; k < 4; k++) m.add("Clutter", at(lathe([[0.02, 0], [0.13, 0], [0.15, 0.24], [0.09, 0.3], [0.02, 0.3]], 8), [-6.5, y + 0.06, 0.6 - w / 2 + 0.3 + k * (w - 0.6) / 3]), [C.enamel, C.tea, C.teaMark, C.tin][(k + (y > 2 ? 1 : 0)) % 4]);
    }
    for (const z of [-0.6, 1.8]) m.add("Clutter", at(pillow(0.16, 3.2, 0.16, 0.3, 6), [-6.3, 1.6, z]), C.woodDark);
    m.add("Clutter", at(lo(0.9, 0.5, 0.7, 9, 6), [-5.4, 0.45, -6.7]), C.rockLight); // the shrine's rock
    m.add("Clutter", at(lathe([[0.1, 0], [0.1, 0.3], [0.04, 0.34]], 8), [-5.4, 0.92, -6.7]), C.wax);
    for (let k = 0; k < 9; k++) { // bent nails stuck in it, every one at its own angle
      const a = (k / 9) * Math.PI * 2, x = -5.4 + Math.sin(a) * 0.55, z = -6.7 + Math.cos(a) * 0.42;
      m.add("Clutter", tube([[x, 0.8, z], [x + Math.sin(a) * 0.05, 1.05, z], [x + Math.sin(a + 1) * 0.16, 1.2 + rnd(k) * 0.1, z + Math.cos(a + 1) * 0.12]], 0.022, 5, 6), k % 3 ? C.ironLight : C.copper);
    }
    m.add("Clutter", ring(5.6, 0.14, -6.4, 0.5, 0.5, 0.1, 0.03, 14), C.rope);
    m.add("Clutter", ring(5.6, 0.3, -6.4, 0.42, 0.42, 0.1, 0.03, 14), C.ropeDark);
    out.push(m);
  }

  // ---------- props ----------
  {
    const m = model("Lantern"); // hangs from its top (the origin): a chain, a cap, the glass, a base
    m.bone("Frame", null, [0, 0, 0]);
    m.add("Frame", limb([0, 0, 0], [0, -1.2, 0], 0.035, 0.035, 6), C.iron);
    m.add("Frame", vring(0, -1.28, 0, 0.1, 0.03), C.iron);
    m.add("Frame", at(lathe([[0.02, 0], [0.36, 0], [0.3, 0.06], [0.12, 0.22], [0.06, 0.3], [0.02, 0.3]], 12), [0, -1.66, 0]), C.copperDark);
    m.add("Frame", at(lathe([[0.02, 0], [0.2, 0], [0.34, 0.05], [0.34, 0.12], [0.26, 0.16], [0.02, 0.16]], 12), [0, -2.52, 0]), C.copperDark);
    for (let k = 0; k < 4; k++) { const a = (k / 4) * Math.PI * 2 + 0.78; m.add("Frame", limb([Math.sin(a) * 0.31, -2.38, Math.cos(a) * 0.31], [Math.sin(a) * 0.31, -1.66, Math.cos(a) * 0.31], 0.03, 0.03, 5), C.copper); }
    m.add("Frame", ring(0, -2.02, 0, 0.32, 0.32, 0.025, 0, 12), C.copper);
    m.bone("Glass", "Frame", [0, -2.0, 0], "Neon");
    m.add("Glass", at(lathe([[0.2, 0], [0.27, 0.12], [0.28, 0.5], [0.22, 0.7]], 12), [0, -2.38, 0]), C.lamp);
    out.push(m);
  }
  {
    const m = model("StumpAnvil"); // a root stump with an iron plate let into its top; a box behind it for the smallest one
    m.bone("Stump", null, [0, 0, 0]);
    m.add("Stump", lathe([[1.5, 0], [1.2, 0.3], [1.05, 0.9], [1.08, 1.5], [1.12, 1.68], [0.02, 1.7]], 16), C.wood);
    for (let k = 0; k < 6; k++) { const a = (k / 6) * Math.PI * 2 + 0.3; m.add("Stump", limb([Math.sin(a) * 0.9, 0.5, Math.cos(a) * 0.9], [Math.sin(a) * 2.0, 0.04, Math.cos(a) * 2.0], 0.3, 0.1, 8), k % 2 ? C.woodDark : C.wood); }
    for (const r of [0.86, 0.62, 0.38, 0.16]) m.add("Stump", ring(0, 1.71, 0, r, r, 0.022, 0, 16), C.woodDark); // growth rings
    m.add("Stump", at(lo(1.06, 0.03, 1.06, 14, 4), [0, 1.7, 0]), C.woodLight);
    m.add("Stump", at(pillow(1.3, 0.2, 1.0, 0.3, 8), [0, 1.8, 0]), C.iron);
    m.add("Stump", at(pillow(1.16, 0.05, 0.86, 0.3, 8), [0, 1.9, 0]), C.ironLight);
    for (const [x, z] of [[-0.56, -0.4], [0.56, -0.4], [-0.56, 0.4], [0.56, 0.4]]) m.add("Stump", at(lo(0.05, 0.04, 0.05), [x, 1.92, z]), C.copper);
    m.bone("Step", null, [0, 0, -1.8]);
    m.add("Step", at(pillow(1.3, 0.9, 1.0, 0.25, 8), [0, 0.45, -1.8], [0, 8, 0]), C.woodLight);
    for (const y of [0.22, 0.66]) m.add("Step", at(pillow(1.36, 0.08, 1.06, 0.25, 6), [0, y, -1.8], [0, 8, 0]), C.woodDark);
    out.push(m);
  }
  {
    const m = model("CopperLump"); // the cold copper: Dull as it came from the wall, Bright under it as the hammers clean it
    m.bone("Bright", null, [0, 0, 0]);
    m.add("Bright", at(ball(0.5, 0.33, 0.42, 14), [0, 0.3, 0]), C.copper);
    m.add("Bright", at(ball(0.3, 0.2, 0.26, 10), [0.26, 0.38, 0.12]), C.copperLight);
    m.add("Bright", at(ball(0.26, 0.2, 0.24, 10), [-0.28, 0.32, -0.1]), C.copperDark);
    m.bone("Dull", null, [0, 0, 0]);
    m.add("Dull", at(ball(0.53, 0.36, 0.45, 14), [0, 0.3, 0]), C.copperDull);
    m.add("Dull", at(ball(0.33, 0.23, 0.29, 10), [0.26, 0.38, 0.12]), C.copperDullDark);
    m.add("Dull", at(ball(0.29, 0.23, 0.27, 10), [-0.28, 0.32, -0.1]), C.copperDull);
    for (let k = 0; k < 6; k++) { const a = k * 1.9; m.add("Dull", at(lo(0.12, 0.06, 0.1), [Math.cos(a) * 0.4, 0.34 + Math.sin(k) * 0.14, Math.sin(a) * 0.32]), C.verdDark); } // verdigris crust
    out.push(m);
  }
  {
    const m = model("Hammer"); // held at the origin (the grip); the head is up the handle at +Y, its face toward +Z
    m.bone("Hammer", null, [0, 0, 0]);
    m.add("Hammer", tube([[0, -0.2, 0], [0.015, 0.4, 0], [0, 1.25, 0]], (u) => 0.07 - 0.015 * u, 8, 10), C.wood);
    m.add("Hammer", ring(0, 0.0, 0, 0.075, 0.075, 0.02, 0, 10), C.leatherDark);
    m.add("Hammer", at(pillow(0.36, 0.34, 0.74, 0.3, 8), [0, 1.3, 0]), C.iron);
    m.add("Hammer", at(pillow(0.4, 0.38, 0.12, 0.3, 8), [0, 1.3, 0.36]), C.ironLight);
    m.add("Hammer", at(pillow(0.4, 0.38, 0.12, 0.3, 8), [0, 1.3, -0.36]), C.ironLight);
    out.push(m);
  }
  {
    const m = model("MinePick"); // the old iron pick that opens the wall: held at the origin, the head across the top
    m.bone("Pick", null, [0, 0, 0]);
    m.add("Pick", tube([[0, -0.3, 0], [0.02, 0.6, 0], [0, 1.7, 0]], (u) => 0.075 - 0.015 * u, 8, 10), C.woodDark);
    m.add("Pick", tube([[0, 1.5, -0.95], [0, 1.74, -0.45], [0, 1.8, 0], [0, 1.74, 0.45], [0, 1.5, 0.95]], (u) => 0.03 + 0.11 * Math.sin(u * Math.PI), 8, 16), C.iron);
    m.add("Pick", at(pillow(0.3, 0.3, 0.34, 0.35, 8), [0, 1.76, 0]), C.ironLight);
    out.push(m);
  }
  {
    const m = model("CratesTable"); // two tea crates and a plank: the committee's table, with its teapot and three cups
    m.bone("Table", null, [0, 0, 0]);
    for (const [x, r] of [[-0.9, 6], [0.95, -9]]) {
      m.add("Table", at(pillow(1.3, 1.3, 1.2, 0.2, 8), [x, 0.65, 0], [0, r, 0]), C.tea);
      for (const y of [0.2, 1.1]) m.add("Table", at(pillow(1.36, 0.12, 1.26, 0.2, 6), [x, y, 0], [0, r, 0]), C.woodLight);
      m.add("Table", at(lo(0.3, 0.3, 0.03, 10, 5), [x, 0.66, 0.6], [0, r, 0]), C.teaMark); // the stencil mark
    }
    m.add("Table", at(pillow(3.6, 0.14, 1.3, 0.25, 8), [0, 1.4, 0], [0, 2, 1.5]), C.wood);
    m.add("Table", at(lathe([[0.02, 0], [0.2, 0], [0.34, 0.1], [0.36, 0.3], [0.24, 0.48], [0.1, 0.5], [0.02, 0.5]], 12), [-0.6, 1.48, 0.1]), C.enamel);
    m.add("Table", tube([[-0.28, 1.74, 0.1], [0.0, 1.86, 0.1], [0.06, 1.98, 0.1]], 0.05, 6, 6), C.enamel);
    m.add("Table", vring(-0.98, 1.74, 0.1, 0.14, 0.035), C.enamel);
    m.add("Table", at(lo(0.07, 0.06, 0.07), [-0.6, 2.02, 0.1]), C.copper);
    for (const [x, z] of [[0.3, 0.3], [0.8, -0.2], [1.3, 0.25]]) m.add("Table", at(lathe([[0.01, 0], [0.09, 0], [0.13, 0.16], [0.11, 0.16], [0.07, 0.02], [0.01, 0.02]], 10), [x, 1.48, z]), C.tin);
    out.push(m);
  }
  {
    const m = model("BucketLift"); // a windlass frame against the wall, a rope up into the dark, and the ore bucket on it
    m.bone("Lift", null, [0, 0, 0]);
    for (const s of [-1, 1]) {
      m.add("Lift", at(pillow(0.4, 5.2, 0.4, 0.3, 8), [s * 1.1, 2.6, 0], [0, 0, s * -3]), C.wood);
      m.add("Lift", limb([s * 1.15, 0.2, 0], [s * 1.1, 1.6, -1.2], 0.14, 0.14, 7), C.woodDark);
    }
    m.add("Lift", at(pillow(2.9, 0.4, 0.42, 0.3, 8), [0, 5.2, 0], [0, 0, 2]), C.woodDark);
    m.add("Lift", at(lathe([[0.02, 0], [0.3, 0], [0.3, 1.5], [0.02, 1.5]], 12), [-0.75, 3.6, 0], [0, 0, -90]), C.woodLight); // the drum
    m.add("Lift", tube([[0.75, 3.6, 0], [1.4, 3.6, 0], [1.4, 3.2, 0.3], [1.75, 3.2, 0.3]], 0.05, 6, 8), C.iron); // the crank
    for (let k = 0; k < 5; k++) m.add("Lift", vring(-0.5 + k * 0.24, 3.6, 0, 0.33, 0.045, "x"), C.rope);
    m.add("Lift", limb([0.1, 3.9, 0.2], [0.1, 8.6, 0.6], 0.04, 0.04, 6), C.rope);
    m.bone("Bucket", "Lift", [0, 3.3, 0.5]);
    m.add("Bucket", limb([0, 3.3, 0.5], [0, 2.3, 0.5], 0.04, 0.04, 6), C.rope);
    m.add("Bucket", at(lathe([[0.02, 0], [0.36, 0], [0.48, 0.7], [0.44, 0.7], [0.33, 0.05], [0.02, 0.05]], 14), [0, 1.3, 0.5]), C.wood);
    for (const y of [1.42, 1.86]) m.add("Bucket", ring(0, y, 0.5, 0.4 + (y - 1.3) * 0.16, 0.4 + (y - 1.3) * 0.16, 0.03, 0, 14), C.iron);
    m.add("Bucket", tube([[-0.44, 1.98, 0.5], [-0.26, 2.26, 0.5], [0, 2.34, 0.5], [0.26, 2.26, 0.5], [0.44, 1.98, 0.5]], 0.03, 6, 12), C.iron);
    for (let k = 0; k < 5; k++) { const a = k * 1.3; m.add("Bucket", at(lo(0.16, 0.13, 0.15), [Math.cos(a) * 0.2, 1.98 + (k % 2) * 0.06, 0.5 + Math.sin(a) * 0.2]), k % 2 ? C.verdigris : C.rockLight); }
    out.push(m);
  }
  return out;
}
