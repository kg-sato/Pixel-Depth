// Fossil Pickaxe biography: "It swam once." A spiral shell sinks into sea mud long ago; a field mouse brushes it out of
// the clay of a dig trench grain by grain, and for one moment the trench is under the ancient sea and the shell creature
// swims round her head; then it settles back into stone in her paws. Scene bible: vault "Forge Biographies - Scene Bibles
// (2026-11-15)", Fossil. References: refs/forge/sheets/fossil_setting_s11.png (a grey clay trench running toward the
// setting sun under an orange canvas shade, string and pegs on the left lip, a table with a notebook and a cup on the
// right, hoodoos and mesas beyond, a purple sky) and mouse_views_s11.png (warm brown fur, cream muzzle and belly, big pink
// ears, round black glasses, khaki pith helmet, white shirt, olive waistcoat with pockets of brushes, pink tail).
// Models: MouseKit (the maker, BoltKit's bone names), FossilTrench (walls of banded seabed, floor, the ground above),
// DigCamp (shade, poles, string grid and pegs, bucket, sieve, table, notebook, magnifier, cup), Badlands (hoodoos and mesas),
// Ammonite (shell, Pearl glow bone, the living Body that shows in the vision), DigBrush, FieldBook, Fish, FossilPickaxe.
// Front of every model is +Z. Units are studs. The trench runs along -Z from z = +6 to z = -16, inside |x| < 1.6, floor y = 0,
// ground above at y = 2.6. Authoring +X is screen right once flipped (the table side).
export const name = "fossil";

const C = {
  fur: "#b0683a", furDark: "#8a4e2a", cream: "#f2e2c8", ear: "#f0a8a8", earOut: "#b0683a", nose: "#e88a96", eye: "#1a1420", white: "#ffffff",
  glasses: "#1e1e24", helmet: "#d8c290", helmetDark: "#b8a070", shirt: "#f2eee4", vest: "#6a7a3e", vestDark: "#525e2e", button: "#3a3a40",
  tail: "#e8a0a8", brushWood: "#c08a4e", bristle: "#e8d8b0", pencil: "#e8a030",
  clay: "#9a9088", clayDark: "#7a7068", clayLight: "#b9ad98", band1: "#a8a8b0", band2: "#c8bca4", band3: "#8a8e9a", band4: "#6a6470",
  ground: "#a89a8c", groundDark: "#8a7e74", canvas: "#d8843e", canvasDark: "#b0682e", pole: "#5a3e2a", string: "#e8dcc0", peg: "#c8a070",
  bucket: "#c8b878", bucketDark: "#9a8a50", table: "#7a5236", tableDark: "#5a3a26", page: "#efe2c4", ink: "#3a3448", cup: "#e8e0d0", tea: "#a8642c", brass: "#c9a24a",
  hoodoo: "#c87a5a", hoodooDark: "#8a4e4e", hoodooFar: "#7a5a78", mesa: "#a85e5a",
  shell: "#efe4c4", shellDark: "#c8b48a", shellRib: "#d8c8a0", pearl: "#bfe8ee", body: "#3f8f9c", bodyLight: "#7fd0d8",
  fish: "#3f8f9c", fishLight: "#8fd8e0", stone: "#b9ad98", stoneDark: "#8a8070", haft: "#7a5236",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, model, rnd } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 7, hs = 5) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const box = (w, h, d) => new THREE.BoxGeometry(w, h, d);
  const cyl = (r0, r1, h, seg = 12) => new THREE.CylinderGeometry(r1, r0, h, seg);
  const ring = (cx, cy, cz, rx, rz, n = 16) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([cx + Math.sin(a) * rx, cy, cz + Math.cos(a) * rz]); } return p; };
  const vring = (cx, cy, cz, rad, n = 18) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([cx + Math.sin(a) * rad, cy + Math.cos(a) * rad, cz]); } return p; };
  const spiral = (m, bn, c, r0, turns, col, ribCol, axis = "x") => { // an ammonite: a coiled tube that grows outward, ribs across it
    const pts = [], N = 80;
    for (let i = 0; i <= N; i++) { const a = (i / N) * turns * Math.PI * 2, r = r0 * Math.pow(0.42, (turns * Math.PI * 2 - a) / (Math.PI * 2)); pts.push(axis === "x" ? [c[0], c[1] + Math.cos(a) * r, c[2] + Math.sin(a) * r] : [c[0] + Math.cos(a) * r, c[1] + Math.sin(a) * r, c[2]]); }
    m.add(bn, tube(pts, (u) => 0.02 + r0 * 0.34 * Math.pow(u, 1.4), 10, 120), col);
    for (let k = 4; k < N; k += 4) { const u = k / N, p = pts[k], q = pts[k + 1] || pts[k], d = [q[0] - p[0], q[1] - p[1], q[2] - p[2]], tr = 0.02 + r0 * 0.35 * Math.pow(u, 1.4);
      const n = Math.hypot(...d) || 1, rg = [];
      for (let j = 0; j <= 10; j++) { const a = (j / 10) * Math.PI * 2; if (axis === "x") { const e1 = [1, 0, 0], e2 = [0, -d[2] / n, d[1] / n]; rg.push([p[0] + (Math.cos(a) * e1[0] + Math.sin(a) * e2[0]) * tr * 1.05, p[1] + (Math.cos(a) * e1[1] + Math.sin(a) * e2[1]) * tr * 1.05, p[2] + (Math.cos(a) * e1[2] + Math.sin(a) * e2[2]) * tr * 1.05]); } else { const e1 = [0, 0, 1], e2 = [-d[1] / n, d[0] / n, 0]; rg.push([p[0] + (Math.cos(a) * e1[0] + Math.sin(a) * e2[0]) * tr * 1.05, p[1] + (Math.cos(a) * e1[1] + Math.sin(a) * e2[1]) * tr * 1.05, p[2] + (Math.cos(a) * e1[2] + Math.sin(a) * e2[2]) * tr * 1.05]); } }
      m.add(bn, tube(rg, 0.012 + tr * 0.06, 4, 14), ribCol);
    }
  };

  // ---------- MouseKit: the field mouse scientist ----------
  {
    const m = model("MouseKit");
    m.bone("Hips", null, [0, 0.9, 0]);
    m.bone("Body", "Hips", [0, 0.9, 0]);
    m.add("Body", lathe([[0.02, 0.5], [0.52, 0.56], [0.66, 0.86], [0.64, 1.24], [0.5, 1.6], [0.32, 1.88], [0.02, 1.94]], 20), C.fur);
    m.add("Body", at(ball(0.42, 0.56, 0.3, 16), [0, 1.16, 0.38]), C.cream);
    m.add("Body", at(ball(0.3, 0.16, 0.26, 12), [0, 1.84, 0.24]), C.shirt); // the shirt collar
    // the waistcoat: open in front, pockets with brushes and pencils at the back
    for (const s of [-1, 1]) m.add("Body", at(pillow(0.4, 0.9, 0.5, 0.35, 8), [0.36 * s, 1.24, 0.12], [0, 28 * s, 0]), C.vest);
    m.add("Body", at(pillow(1.0, 0.94, 0.4, 0.35, 8), [0, 1.22, -0.36]), C.vest);
    for (const [x, y, z, r] of [[-0.4, 1.0, 0.48, -28], [0.4, 1.0, 0.48, 28], [-0.3, 0.96, -0.6, 180], [0.3, 0.96, -0.6, 180]]) { m.add("Body", at(pillow(0.26, 0.2, 0.06, 0.4, 6), [x, y, z], [0, r, 0]), C.vestDark); m.add("Body", at(ball(0.03, 0.03, 0.02, 6), [x, y + 0.08, z + (z > 0 ? 0.04 : -0.04)]), C.button); }
    for (const s of [-1, 1]) for (let k = 0; k < 3; k++) m.add("Body", at(cyl(0.022, 0.022, 0.32, 6), [0.3 * s + (k - 1) * 0.06, 1.16, -0.64], [6 * (k - 1), 0, 0]), [C.brushWood, C.pencil, C.bristle][k]); // brushes at the back
    for (const y of [1.44, 1.24]) m.add("Body", at(ball(0.035, 0.035, 0.02, 6), [0.16, y, 0.52]), C.button);
    m.bone("Head", "Body", [0, 1.94, 0]);
    m.add("Head", at(ball(0.92, 0.84, 0.86, 24), [0, 2.72, 0]), C.fur);
    m.add("Head", at(ball(0.62, 0.5, 0.42, 18), [0, 2.5, 0.5]), C.cream); // muzzle and cheeks
    m.add("Head", at(ball(0.12, 0.09, 0.09, 10), [0, 2.56, 0.98]), C.nose);
    for (const s of [-1, 1]) for (const dy of [-0.04, 0.04]) m.add("Head", tube([[0.16 * s, 2.52 + dy, 0.88], [0.5 * s, 2.54 + dy * 2, 0.86], [0.8 * s, 2.58 + dy * 3, 0.76]], 0.008, 3, 6), C.furDark); // whiskers
    m.bone("Eyes", "Head", [0, 2.84, 0.8]);
    for (const s of [-1, 1]) { m.add("Eyes", at(ball(0.16, 0.18, 0.07, 12), [0.3 * s, 2.84, 0.8], [0, 18 * s, 0]), C.eye); m.add("Eyes", at(ball(0.05, 0.06, 0.03, 8), [0.3 * s + 0.05, 2.9, 0.86]), C.white); }
    m.bone("EyesShut", "Head", [0, 2.84, 0.86]);
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.16 * s, 2.84, 0.84], [0.3 * s, 2.8, 0.88], [0.44 * s, 2.84, 0.8]], 0.03, 5, 8), C.furDark);
    m.bone("Glasses", "Head", [0, 2.84, 0.9]);
    for (const s of [-1, 1]) { m.add("Glasses", tube(vring(0.3 * s, 2.84, 0.92, 0.25), 0.03, 6, 24), C.glasses); m.add("Glasses", tube([[0.55 * s, 2.86, 0.88], [0.86 * s, 2.9, 0.3]], 0.02, 4, 4), C.glasses); }
    m.add("Glasses", tube([[-0.05, 2.86, 0.94], [0, 2.9, 0.96], [0.05, 2.86, 0.94]], 0.02, 4, 6), C.glasses);
    m.bone("EarL", "Head", [0.6, 3.2, -0.1]);
    m.add("EarL", at(cyl(0.52, 0.5, 0.1, 20), [0.86, 3.42, -0.12], [90, 0, -18]), C.earOut);
    m.add("EarL", at(cyl(0.4, 0.38, 0.06, 20), [0.86, 3.42, -0.06], [90, 0, -18]), C.ear);
    m.mirror("EarL", "EarR");
    m.bone("Helmet", "Head", [0, 3.4, 0]); // the pith helmet
    m.add("Helmet", at(lathe([[0.02, 0], [0.82, 0], [0.8, 0.3], [0.62, 0.58], [0.3, 0.72], [0.02, 0.74]], 20), [0, 3.24, -0.04]), C.helmet);
    m.add("Helmet", at(cyl(1.06, 1.0, 0.06, 24), [0, 3.24, 0.02], [-8, 0, 0]), C.helmet);
    m.add("Helmet", tube(ring(0, 3.34, -0.04, 0.82, 0.82, 22), 0.05, 5, 30), C.helmetDark);
    m.add("Helmet", at(ball(0.08, 0.05, 0.08, 8), [0, 3.98, -0.04]), C.helmetDark);
    m.bone("ArmL", "Body", [0.5, 1.62, 0]);
    m.add("ArmL", limb([0.5, 1.62, 0], [0.74, 1.2, 0.1], 0.14, 0.13), C.shirt);
    m.bone("ForeL", "ArmL", [0.74, 1.2, 0.1]);
    m.add("ForeL", limb([0.74, 1.2, 0.1], [0.8, 0.86, 0.24], 0.12, 0.1), C.fur);
    m.add("ForeL", tube(ring(0.75, 1.16, 0.12, 0.14, 0.14, 12), 0.05, 5, 16), C.shirt); // the rolled cuff
    m.add("ForeL", at(ball(0.12, 0.11, 0.13, 10), [0.81, 0.8, 0.28]), C.tail);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");
    m.bone("LegL", "Hips", [0.26, 0.7, 0]);
    m.add("LegL", limb([0.26, 0.7, 0], [0.28, 0.14, 0.04], 0.17, 0.13), C.fur);
    m.add("LegL", at(ball(0.16, 0.08, 0.34, 10), [0.28, 0.07, 0.2]), C.tail);
    m.mirror("LegL", "LegR");
    m.bone("Tail1", "Hips", [0, 0.7, -0.5]);
    m.add("Tail1", tube([[0, 0.7, -0.5], [0.3, 0.4, -1.2], [0.9, 0.5, -1.7], [1.3, 1.0, -1.8]], (u) => 0.07 - 0.05 * u, 6, 20), C.tail);
    out.push(m);
  }

  // ---------- FossilTrench: walls of banded seabed, the floor, the ground above ----------
  {
    const m = model("FossilTrench");
    const Z0 = 6, Z1 = -16, D = 2.6, HW = 1.6;
    m.bone("Walls", null, [0, 0, 0]);
    const bands = [C.band4, C.band1, C.band2, C.band3, C.band2, C.band1, C.clayLight];
    for (const s of [-1, 1]) {
      for (let k = 0; k < bands.length; k++) {
        const y0 = (k * D) / bands.length, h = D / bands.length, inset = (k % 2) * 0.08 + rnd(k + s) * 0.05;
        m.add("Walls", at(box(1.2, h, Z0 - Z1), [s * (HW + 0.6 + inset), y0 + h / 2, (Z0 + Z1) / 2]), bands[k]);
      }
      for (let k = 0; k < 26; k++) { const z = Z0 - 1 - rnd(k * 3 + s) * (Z0 - Z1 - 2), y = 0.3 + rnd(k * 5 + s) * 2.0; m.add("Walls", at(lo(0.2 + rnd(k) * 0.3, 0.12 + rnd(k * 2) * 0.12, 0.25, 6, 4), [s * (HW + 0.02), y, z]), [C.clay, C.clayDark, C.band2][k % 3]); } // pebbles and shells in the wall
      for (let k = 0; k < 8; k++) { const z = Z0 - 2 - k * 2.6; m.add("Walls", at(pillow(0.4, 0.5 + rnd(k) * 0.3, 1.6 + rnd(k * 3), 0.5, 6), [s * (HW + 0.1), D - 0.05, z], [0, 0, s * 20]), C.clayLight); } // the rounded crumbling lip
    }
    m.add("Walls", at(box(2 * HW + 2.4, D * 0.8, 1.0), [0, D * 0.4, Z1 - 0.4]), C.band2); // the far end: a low step toward the sun
    m.bone("Floor", null, [0, 0, 0]);
    m.add("Floor", at(box(2 * HW, 0.2, Z0 - Z1), [0, -0.1, (Z0 + Z1) / 2]), C.clay);
    for (let k = 0; k < 50; k++) m.add("Floor", at(lo(0.04 + rnd(k) * 0.08, 0.03, 0.05, 5, 3), [(rnd(k * 3) - 0.5) * 3, 0.02, Z0 - rnd(k * 5) * (Z0 - Z1)]), [C.clayLight, C.clayDark][k % 2]);
    for (let k = 0; k < 6; k++) m.add("Floor", at(box(2 * HW - 0.2, 0.06, 0.4), [0, 0.03, Z0 - 2 - k * 3.2]), C.clayDark); // dug steps
    m.bone("Ground", null, [0, 0, 0]);
    for (const s of [-1, 1]) m.add("Ground", at(box(80, 0.4, 140), [s * (HW + 1.2 + 40), D - 0.2, -40]), C.ground);
    m.add("Ground", at(box(2 * HW + 2.4, 0.4, 120), [0, D - 0.2, Z1 - 60.9]), C.ground);
    m.add("Ground", at(box(2 * HW + 2.4, 0.4, 20), [0, D - 0.2, Z0 + 10]), C.ground);
    for (let k = 0; k < 60; k++) { const s = k % 2 ? 1 : -1; m.add("Ground", at(lo(0.2 + rnd(k) * 0.4, 0.1, 0.3, 6, 4), [s * (3 + rnd(k * 3) * 14), D, 4 - rnd(k * 7) * 50]), [C.groundDark, C.clayLight][k % 2]); }
    for (let k = 0; k < 30; k++) { const s = k % 2 ? 1 : -1, x = s * (3.5 + rnd(k * 9) * 16), z = 2 - rnd(k * 4) * 60; for (let b = 0; b < 5; b++) m.add("Ground", limb([x, D, z], [x + (rnd(k * 9 + b) - 0.5) * 0.6, D + 0.3 + rnd(k + b) * 0.4, z + (rnd(k * 7 + b) - 0.5) * 0.6], 0.03, 0.01, 4), b % 2 ? "#7a8a4a" : "#5a6a3a"); } // dry tufts
    out.push(m);
  }

  // ---------- DigCamp: shade, string grid, bucket, sieve, table, notebook, magnifier, cup ----------
  {
    const m = model("DigCamp");
    const D = 2.6;
    m.bone("Camp", null, [0, 0, 0]);
    for (const [x, z, h] of [[-2.6, 2.4, 2.6], [2.6, 2.4, 2.4], [-2.6, -5.0, 2.2], [2.6, -5.0, 2.8]]) m.add("Camp", at(cyl(0.08, 0.07, h, 8), [x, D + h / 2, z]), C.pole);
    m.bone("Canvas", "Camp", [0, D + 2.4, -1.3]);
    { // the shade: a sagging sheet between the four poles
      const P = [], idx = [], NU = 12, NV = 10;
      for (let j = 0; j <= NV; j++) for (let i = 0; i <= NU; i++) { const u = i / NU, v = j / NV, x = -2.7 + 5.4 * u, z = 2.5 - 7.6 * v, sag = 0.5 * Math.sin(u * Math.PI) * Math.sin(v * Math.PI); P.push(x, D + 2.5 - sag + 0.2 * (u - 0.5) - 0.1 * v, z); }
      for (let j = 0; j < NV; j++) for (let i = 0; i < NU; i++) { const a = j * (NU + 1) + i, b = a + 1, c = a + NU + 1, d = c + 1; idx.push(a, c, b, b, c, d, a, b, c, b, d, c); }
      const g = new THREE.BufferGeometry(); g.setAttribute("position", new THREE.Float32BufferAttribute(P, 3)); g.setIndex(idx); g.computeVertexNormals();
      m.add("Canvas", g, C.canvas);
      m.add("Canvas", tube([[-2.7, D + 2.6, 2.5], [0, D + 2.2, 2.6], [2.7, D + 2.4, 2.5]], 0.04, 5, 12), C.canvasDark);
    }
    for (const [a, b] of [[[-2.6, D + 2.4, 2.4], [-3.6, D, 4.0]], [[2.6, D + 2.2, 2.4], [3.6, D, 4.2]]]) m.add("Camp", tube([a, b], 0.015, 3, 2), C.string); // guy ropes
    // the string grid on the left lip (authoring -X), numbered pegs
    for (let k = 0; k < 7; k++) { const z = 3 - k * 1.2; m.add("Camp", at(box(0.08, 0.5, 0.08), [-1.9, D + 0.25, z]), C.peg); m.add("Camp", at(box(0.14, 0.12, 0.02), [-1.9, D + 0.38, z + 0.05]), C.page); }
    m.add("Camp", tube([[-1.9, D + 0.42, 3], [-1.9, D + 0.42, 3 - 7.2]], 0.012, 3, 2), C.string);
    for (let k = 0; k < 7; k++) m.add("Camp", tube([[-1.9, D + 0.42, 3 - k * 1.2], [1.9, D + 0.42, 3 - k * 1.2]], 0.008, 3, 2), C.string);
    m.add("Camp", at(lathe([[0.02, 0], [0.3, 0], [0.38, 0.6], [0.36, 0.62], [0.02, 0.62]], 14), [-2.4, D, 0.8]), C.bucket); // bucket
    m.add("Camp", tube(ring(-2.4, D + 0.6, 0.8, 0.37, 0.37, 14), 0.03, 4, 20), C.bucketDark);
    m.add("Camp", at(cyl(0.5, 0.5, 0.14, 16), [-2.6, D + 0.07, -1.0], [0, 0, 8]), C.table); // a sieve
    m.add("Camp", at(cyl(0.44, 0.44, 0.02, 16), [-2.6, D + 0.1, -1.0], [0, 0, 8]), C.groundDark);
    // the camp table on the right lip
    m.bone("Table", "Camp", [2.7, D, -0.6]);
    m.add("Table", at(box(1.6, 0.08, 1.0), [2.7, D + 0.8, -0.6]), C.table);
    for (const [dx, dz] of [[-0.7, -0.4], [0.7, -0.4], [-0.7, 0.4], [0.7, 0.4]]) m.add("Table", at(box(0.08, 0.8, 0.08), [2.7 + dx, D + 0.4, -0.6 + dz]), C.tableDark);
    m.add("Table", at(box(0.6, 0.04, 0.44), [2.5, D + 0.86, -0.5], [0, 12, 0]), C.page);
    for (let k = 0; k < 4; k++) m.add("Table", at(box(0.42, 0.012, 0.02), [2.5, D + 0.885, -0.62 + k * 0.08], [0, 12, 0]), C.ink);
    m.add("Table", at(lathe([[0.02, 0], [0.1, 0], [0.13, 0.18], [0.02, 0.18]], 10), [3.2, D + 0.84, -0.8]), C.cup);
    m.add("Table", at(cyl(0.11, 0.11, 0.01, 10), [3.2, D + 1.0, -0.8]), C.tea);
    m.add("Table", tube(ring(3.0, D + 0.86, -0.3, 0.14, 0.14, 14), 0.025, 4, 18), C.brass); // the magnifier
    m.add("Table", at(cyl(0.12, 0.12, 0.01, 14), [3.0, D + 0.86, -0.3]), "#cfe6f0");
    m.add("Table", limb([3.1, D + 0.86, -0.18], [3.3, D + 0.86, 0.06], 0.025, 0.025, 5), C.tableDark);
    out.push(m);
  }

  // ---------- Badlands: hoodoos and mesas toward the sun ----------
  {
    const m = model("Badlands");
    m.bone("Land", null, [0, 0, 0]);
    for (let k = 0; k < 26; k++) {
      const x = (rnd(k * 2.3) - 0.5) * 140, z = -50 - rnd(k * 4.7) * 110, h = 6 + rnd(k * 6.1) * 16, r = 1.2 + rnd(k * 8.3) * 2.4;
      if (Math.abs(x) < 6 && z > -80) continue;
      const col = z < -120 ? C.hoodooFar : (k % 2 ? C.hoodoo : C.hoodooDark);
      m.add("Land", at(lathe([[r * 1.4, 0], [r, h * 0.3], [r * 0.7, h * 0.55], [r * 0.9, h * 0.7], [r * 0.5, h * 0.88], [r * 0.8, h * 0.94], [r * 0.6, h], [0.02, h * 1.01]], 9), [x, 0, z]), col);
    }
    for (const [x, z, w, h, d] of [[-50, -140, 40, 16, 20], [40, -150, 50, 20, 24], [-10, -190, 70, 12, 20], [70, -100, 30, 12, 18]]) {
      m.add("Land", at(pillow(w, h, d, 0.12, 8), [x, h / 2, z]), C.mesa);
      m.add("Land", at(pillow(w * 0.9, 1.2, d * 0.9, 0.3, 8), [x, h + 0.2, z]), C.hoodooFar);
    }
    out.push(m);
  }

  // ---------- Ammonite: the shell, its pearl glow, the living body in the vision ----------
  {
    const m = model("Ammonite");
    m.bone("Shell", null, [0, 0, 0]);
    spiral(m, "Shell", [0, 0, 0], 0.55, 2.4, C.shell, C.shellRib);
    m.bone("Pearl", "Shell", [0, 0, 0], "Neon");
    m.add("Pearl", at(ball(0.16, 0.16, 0.06, 10), [0.04, 0, 0], [0, 90, 0]), C.pearl);
    m.bone("Body", "Shell", [0, 0, 0.55]);
    for (let k = 0; k < 7; k++) { const a = -0.9 + k * 0.3; m.add("Body", tube([[0, -0.05, 0.6], [Math.sin(a) * 0.15, -0.1 + Math.cos(a) * 0.1, 0.9], [Math.sin(a) * 0.3, -0.2 + Math.cos(a) * 0.12, 1.2]], (u) => 0.05 - 0.035 * u, 5, 10), k % 2 ? C.body : C.bodyLight); }
    m.add("Body", at(ball(0.2, 0.18, 0.16, 10), [0, -0.02, 0.62]), C.body);
    for (const s of [-1, 1]) m.add("Body", at(ball(0.05, 0.05, 0.04, 8), [s * 0.14, 0.06, 0.7]), C.eye);
    out.push(m);
    const f = model("Fish");
    f.bone("Body", null, [0, 0, 0]);
    f.add("Body", at(ball(0.07, 0.1, 0.24, 8), [0, 0, 0]), C.fish);
    f.add("Body", at(ball(0.05, 0.03, 0.14, 6), [0, 0.04, 0.02]), C.fishLight);
    f.add("Body", puff([[0, 0], [0.1, 0.12], [0.1, -0.12]], 0.01, 0.005).rotateY(Math.PI / 2).translate(0, 0, -0.22), C.fish);
    out.push(f);
  }

  // ---------- DigBrush, FieldBook ----------
  {
    const b = model("DigBrush");
    b.bone("Body", null, [0, 0, 0]);
    b.add("Body", at(cyl(0.035, 0.04, 0.6, 8), [0, 0.3, 0]), C.brushWood);
    b.add("Body", at(cyl(0.06, 0.045, 0.06, 8), [0, 0.62, 0]), C.brass);
    b.add("Body", at(cyl(0.07, 0.06, 0.18, 8), [0, 0.74, 0]), C.bristle);
    out.push(b);
    const n = model("FieldBook");
    n.bone("Body", null, [0, 0, 0]);
    n.add("Body", at(box(0.5, 0.06, 0.66), [0, 0, 0]), C.vestDark);
    n.add("Body", at(box(0.46, 0.07, 0.62), [0, 0.01, 0]), C.page);
    out.push(n);
  }

  // ---------- FossilPickaxe: the ammonite set in a stone head on an old haft ----------
  {
    const m = model("FossilPickaxe");
    const HEAD = 3.3;
    m.bone("Haft", null, [0, 0, 0]);
    m.add("Haft", at(cyl(0.11, 0.09, 3.4, 10), [0, 1.7, 0]), C.haft);
    for (let k = 0; k < 5; k++) m.add("Haft", at(cyl(0.13, 0.13, 0.07, 12), [0, 0.4 + k * 0.11, 0]), k % 2 ? C.vest : C.helmet);
    m.bone("Head", "Haft", [0, HEAD, 0]);
    for (const s of [-1, 1]) {
      m.add("Head", tube([[0, HEAD, 0], [s * 0.7, HEAD + 0.02, 0], [s * 1.35, HEAD - 0.28, 0]], (u) => 0.28 - 0.25 * u, 9, 16), C.stone);
      for (let k = 0; k < 3; k++) m.add("Head", tube([[s * (0.3 + k * 0.3), HEAD + 0.24 - k * 0.04, -0.2], [s * (0.3 + k * 0.3), HEAD + 0.26 - k * 0.04, 0.2]], 0.02, 4, 4), C.stoneDark); // seabed bands
    }
    m.add("Head", at(cyl(0.42, 0.42, 0.34, 18), [0, HEAD, 0], [90, 0, 0]), C.stoneDark);
    spiral(m, "Head", [0, HEAD, 0.18], 0.36, 2.4, C.shell, C.shellRib, "z");
    m.bone("Pearl", "Head", [0, HEAD, 0.3], "Neon");
    m.add("Pearl", at(ball(0.09, 0.09, 0.04, 8), [0, HEAD, 0.26]), C.pearl);
    out.push(m);
  }
  return out;
}
