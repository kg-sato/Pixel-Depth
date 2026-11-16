// Mossback Pickaxe biography: "a boulder a snail carried for forty years, until the moss had taken it over".
// Setting from the scene bible "Mossback" and refs/forge/sheets/mossback_setting_s11.png (a terraced clay canyon, ochre and
// rust bands, a rope bridge, a mossy shelf by a waterfall); the maker from snail_views_s11.png (a giant garden snail: cream-tan
// body, honey spiral shell with caramel bands, sleepy eyes on her face, two ball-tipped feelers, a rope harness holding a mossy boulder).
// Models: SnailKit, MossBoulder (its moss, ferns, tree and nest are bones, so the scene grows them year by year),
// MossbackWorld (painted height fields from mossback_world.py), ClaySlabA/B/C, CaveMouth, Waterfall, RopeBridge, Bird,
// TrailBit, Rainbow. Stones and plants come from the CC0 kit (kit_import.py). Front of every model is +Z. Units are studs.
import terrain from "./tex/mossback_terrain.mjs";
export const name = "mossback";

const C = {
  skin: "#f5cc95", skinShade: "#c79a67", foot: "#fbe0b4", pink: "#e3805b", eye: "#17121a", white: "#ffffff", mouth: "#8a5a44",
  shell: "#e99f46", shellLight: "#f4bd6a", shellDark: "#a65f21", shellCore: "#944514",
  rope: "#96643c", ropeDark: "#74492a",
  rock: "#8e8e8a", rockLight: "#a8a8a4", rockDark: "#696a60",
  moss: "#7d9325", mossLight: "#a3b43c", mossDark: "#6b7f1e", fern: "#4f8a48", bark: "#6e5444", leaf: "#6aa85c", leafLight: "#9ccf74",
  twig: "#8a6a48", egg: "#cfe6e8",
  clay: "#b55a40", clayLight: "#cb8369", rust: "#8b3f2e", clayDark: "#6c2a1e", cave: "#2a1a16",
  water: "#bfe6ee", waterLight: "#eefaff", plank: "#9a7350", plankDark: "#7a5a3e",
  bird: "#4a6fa5", birdDark: "#35527e", beak: "#ffb347", silver: "#e6eef2",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, field, model, rnd } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 6, hs = 4) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const rad = (d) => (d * Math.PI) / 180;

  // ---------- SnailKit ----------
  {
    const m = model("SnailKit");
    m.bone("Body", null, [0, 0.35, 0]);
    m.add("Body", at(pillow(1.9, 0.95, 4.0, 0.62, 14), [0, 0.5, 0.2]), C.skin); // the foot: long, low and soft
    m.add("Body", at(pillow(2.35, 0.3, 4.5, 0.7, 12), [0, 0.16, 0.2]), C.foot); // its pale skirt on the ground
    for (let i = 0; i < 9; i++) for (const s of [-1, 1]) m.add("Body", at(lo(0.2, 0.13, 0.26), [1.12 * s, 0.14, -1.6 + i * 0.46]), C.foot); // the frilled edge
    for (let i = 0; i < 7; i++) m.add("Body", at(lo(0.07, 0.04, 0.07, 5, 3), [(rnd(i) - 0.5) * 1.2, 0.93 - Math.abs(rnd(i) - 0.5) * 0.3, 1.2 + rnd(i + 20) * 1.0]), C.skinShade); // speckles on her neck

    m.bone("Tail", "Body", [0, 0.3, -1.6]);
    m.add("Tail", at(limb([0, 0.5, -1.5], [0, 0.22, -5.0], 0.9, 0.16, 12), [0, 0, 0], [0, 0, 0], [1, 0.62, 0.66]), C.skin);
    m.add("Tail", at(pillow(1.7, 0.24, 2.2, 0.75, 10), [0, 0.13, -2.2]), C.foot);

    m.bone("Head", "Body", [0, 0.7, 1.7]);
    m.add("Head", limb([0, 0.62, 1.7], [0, 1.72, 2.5], 0.68, 0.54, 14), C.skin); // the neck rises
    m.add("Head", at(ball(0.66, 0.6, 0.64, 20), [0, 1.98, 2.62]), C.skin);
    m.add("Head", tube([[-0.26, 1.84, 3.16], [-0.12, 1.75, 3.24], [0, 1.73, 3.26], [0.12, 1.75, 3.24], [0.26, 1.84, 3.16]], 0.03, 6, 12), C.mouth); // a small smile
    for (const s of [-1, 1]) {
      m.add("Head", at(ball(0.13, 0.09, 0.05, 8), [0.4 * s, 1.86, 3.08], [0, 30 * s, 0]), C.pink);
      m.add("Head", limb([0.2 * s, 1.72, 3.1], [0.3 * s, 1.5, 3.42], 0.07, 0.06, 6), C.skinShade); // the short feelers
      m.add("Head", at(lo(0.085, 0.085, 0.085), [0.3 * s, 1.5, 3.44]), C.skin);
    }
    // as on snail_views_s11.png: her eyes are on her face (tall black ovals, one highlight, a heavy lid that makes her look
    // sleepy), and the two stalks are thin feelers with a ball at the tip. EyeL and ShutL are swapped for a blink or a smile.
    for (const s of [-1, 1]) m.add("Head", at(ball(0.17, 0.09, 0.09, 10), [0.3 * s, 2.24, 3.13], [-18, 0, -8 * s]), C.skinShade);
    m.bone("EyeL", "Head", [0.3, 2.08, 3.1]);
    m.add("EyeL", at(ball(0.13, 0.17, 0.07, 12), [0.3, 2.08, 3.16], [0, 12, 0]), C.eye);
    m.add("EyeL", at(lo(0.045, 0.05, 0.03), [0.34, 2.15, 3.22]), C.white);
    m.bone("ShutL", "Head", [0.3, 2.08, 3.1]);
    m.add("ShutL", tube([[0.16, 2.04, 3.17], [0.3, 2.15, 3.21], [0.44, 2.04, 3.15]], 0.035, 6, 10), C.mouth);
    m.bone("StalkL", "Head", [0.3, 2.42, 2.6]);
    m.add("StalkL", limb([0.3, 2.42, 2.6], [0.58, 3.5, 2.78], 0.09, 0.07, 8), C.skin);
    m.add("StalkL", at(ball(0.17, 0.17, 0.17, 12), [0.6, 3.62, 2.8]), C.foot);
    m.mirror("EyeL", "EyeR"); m.mirror("ShutL", "ShutR"); m.mirror("StalkL", "StalkR");

    // the shell: one tube wound as a growing spiral in the side plane, widened across; a dark seam between the turns
    m.bone("Shell", "Body", [0, 1.2, -0.4]);
    const c = [0, 2.0, -0.55], R1 = 1.13, GROW = 2.2, TURNS = 2.5, TH0 = rad(-50);
    const sp = (rr, phi) => [0, c[1] + Math.sin(TH0 + phi) * rr, c[2] + Math.cos(TH0 + phi) * rr];
    const pts = [], seam = [];
    for (let i = 0; i <= 90; i++) {
      const phi = (i / 90) * TURNS * Math.PI * 2, r = R1 * Math.pow(GROW, -phi / (Math.PI * 2));
      pts.push(sp(r, phi));
      if (i <= 60) { const q = sp(r * 0.5, phi); seam.push([0.43 * Math.pow(GROW, -phi / (Math.PI * 2)), q[1], q[2]]); }
    }
    const R0 = R1 * Math.pow(GROW, -TURNS);
    m.add("Shell", at(tube(pts, (u) => 0.56 * (R1 + (R0 - R1) * u), 14, 110), [0, 0, 0], [0, 0, 0], [1.4, 1, 1]), C.shell);
    for (const s of [-1, 1]) { // the seam and the coil's heart show on both cheeks of the shell
      m.add("Shell", tube(seam.map((p) => [p[0] * s, p[1], p[2]]), 0.05, 5, 70), C.shellDark);
      m.add("Shell", at(ball(0.2, 0.32, 0.32, 10), [0.5 * s, c[1], c[2]]), C.shellCore);
    }
    for (let k = 0; k < 9; k++) { // caramel growth bands across the big outer turn
      const phi = rad(18 + k * 30), r = R1 * Math.pow(GROW, -phi / (Math.PI * 2)), tr = 0.56 * r * 1.02;
      const ring = [];
      for (let i = 0; i <= 12; i++) { const a = rad(-100 + i * (200 / 12)); const mid = sp(r + Math.cos(a) * tr, phi); ring.push([Math.sin(a) * tr * 1.4, mid[1], mid[2]]); }
      m.add("Shell", tube(ring, 0.045, 5, 24), k % 2 ? C.shellDark : C.shellLight);
    }

    // the harness: two rope girths round the shell, a rope ring on top where the boulder rides, a knot
    m.bone("Harness", "Shell", [0, 3.7, -0.55]);
    for (const [dz, ry, rx] of [[0.5, 1.74, 0.95], [-0.55, 1.7, 0.93]]) {
      const loop = [];
      for (let i = 0; i <= 20; i++) { const a = (i / 20) * Math.PI * 2; loop.push([Math.sin(a) * rx, c[1] + Math.cos(a) * ry, c[2] + dz + Math.sin(a * 2) * 0.05]); }
      m.add("Harness", tube(loop, 0.07, 7, 40), dz > 0 ? C.rope : C.ropeDark);
    }
    const ring = [];
    for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2; ring.push([Math.sin(a) * 0.78, 3.72 + Math.cos(a * 2) * 0.03, c[2] + Math.cos(a) * 0.78]); }
    m.add("Harness", tube(ring, 0.1, 7, 32), C.rope);
    m.add("Harness", at(ball(0.16, 0.14, 0.14, 8), [0.95, 2.3, c[2] + 0.5]), C.ropeDark);
    for (const [l, a] of [[0.5, 10], [0.4, -16]]) m.add("Harness", limb([0.97, 2.25, c[2] + 0.5], [1.05 + a * 0.004, 2.25 - l, c[2] + 0.5 + a * 0.01], 0.05, 0.03, 5), C.rope);
    out.push(m);
  }

  // ---------- MossBoulder: the load, then the home, then the pickaxe head ----------
  {
    const m = model("MossBoulder");
    const R = 1.2;
    const bump = (x, y, z) => 1 + 0.1 * Math.sin(x * 3.1 + 1) * Math.sin(y * 2.7 + 2) + 0.07 * Math.sin(z * 4.3 + x * 2.1) + 0.05 * Math.sin(y * 6.1 + z * 3.3);
    const top = (ax, az) => { // a point on the boulder's upper surface: ax, az are angles from straight up, in degrees
      const d = new THREE.Vector3(Math.sin(rad(ax)), 1, Math.sin(rad(az))).normalize(); const k = R * bump(d.x, d.y, d.z);
      return [d.x * k, R * 0.92 + d.y * k * 0.92, d.z * k];
    };
    m.bone("Rock", null, [0, 0, 0]);
    const g = new THREE.SphereGeometry(1, 22, 14); const p = g.attributes.position;
    for (let i = 0; i < p.count; i++) { const x = p.getX(i), y = p.getY(i), z = p.getZ(i), k = R * bump(x, y, z); p.setXYZ(i, x * k, R * 0.92 + y * k * 0.92, z * k); }
    g.computeVertexNormals();
    m.add("Rock", g, C.rock);
    for (const [ax, az, s] of [[40, 30, 0.5], [-55, 10, 0.42], [20, -60, 0.46], [-30, -40, 0.36], [70, -20, 0.34]]) { const q = top(ax, az); m.add("Rock", at(lo(s, s * 0.35, s, 8, 4), [q[0] * 0.93, q[1] - (q[1] - R * 0.92) * 0.07, q[2] * 0.93]), ax > 0 ? C.rockLight : C.rockDark); }
    m.add("Rock", at(lo(R * 0.95, 0.2, R * 0.95, 10, 3), [0, 0.12, 0]), C.rockDark);
    // moss in three ages: first a few cushions, then more, then a cap over the whole top with a fringe hanging down
    const cushions = (bone, list, col) => { for (const [ax, az, s] of list) { const q = top(ax, az); m.add(bone, at(ball(s, s * 0.42, s, 10), q), col); } };
    m.bone("Moss1", "Rock", [0, R * 1.84, 0]);
    cushions("Moss1", [[0, 0, 0.5], [34, 18, 0.34], [-28, -22, 0.3]], C.moss);
    m.bone("Moss2", "Rock", [0, R * 1.84, 0]);
    cushions("Moss2", [[-44, 20, 0.42], [20, -46, 0.4], [52, -14, 0.34], [-12, 50, 0.36], [-58, -30, 0.3], [10, 30, 0.3]], C.mossLight);
    m.bone("Moss3", "Rock", [0, R * 1.84, 0]);
    cushions("Moss3", [[68, 30, 0.42], [-72, 0, 0.44], [0, 74, 0.42], [30, -76, 0.4], [-40, -64, 0.4], [-60, 54, 0.38], [76, -40, 0.36]], C.mossDark);
    cushions("Moss3", [[18, 6, 0.4], [-20, 14, 0.38], [0, -24, 0.4]], C.moss);
    for (let k = 0; k < 10; k++) { const a = k * 36 + 8, q = top(Math.cos(rad(a)) * 88, Math.sin(rad(a)) * 88); m.add("Moss3", limb(q, [q[0] * 1.04, q[1] - 0.3 - rnd(k) * 0.4, q[2] * 1.04], 0.09, 0.03, 5), k % 2 ? C.moss : C.mossLight); }
    // ferns: small fronds in two tufts
    m.bone("Ferns", "Rock", top(-34, 26));
    for (const [ax, az, n] of [[-34, 26, 5], [42, -30, 4]]) {
      const q = top(ax, az);
      for (let k = 0; k < n; k++) m.add("Ferns", at(puff([[0, 0], [0.09, 0.2], [0.07, 0.5], [0, 0.78], [-0.07, 0.5], [-0.09, 0.2]], 0.03, 0.015), q, [38 + rnd(k) * 16, k * (360 / n) + ax, 0]), k % 2 ? C.fern : C.leaf);
    }
    // the tiny tree that takes root on it
    const tb = top(8, -14);
    m.bone("Tree", "Rock", tb);
    m.add("Tree", tube([tb, [tb[0] + 0.06, tb[1] + 0.5, tb[2]], [tb[0] - 0.05, tb[1] + 0.95, tb[2] + 0.05], [tb[0] + 0.02, tb[1] + 1.3, tb[2]]], (u) => 0.1 - 0.05 * u, 7, 10), C.bark);
    m.add("Tree", limb([tb[0], tb[1] + 0.7, tb[2]], [tb[0] + 0.3, tb[1] + 1.0, tb[2] + 0.1], 0.04, 0.025, 5), C.bark);
    for (const [dx, dy, dz, s, col] of [[0, 1.5, 0, 0.42, C.leaf], [0.34, 1.2, 0.12, 0.3, C.leafLight], [-0.28, 1.28, -0.1, 0.3, C.leaf], [0.05, 1.82, 0.05, 0.26, C.leafLight]]) m.add("Tree", at(ball(s, s * 0.85, s, 10), [tb[0] + dx, tb[1] + dy, tb[2] + dz]), col);
    // the nest: a ring of twigs and two pale eggs
    const nb = top(-10, -44);
    m.bone("Nest", "Rock", nb);
    for (let k = 0; k < 3; k++) { const ring = []; for (let i = 0; i <= 12; i++) { const a = (i / 12) * Math.PI * 2 + k; ring.push([nb[0] + Math.sin(a) * (0.3 - k * 0.03), nb[1] + 0.08 + k * 0.07 + Math.sin(a * 3 + k) * 0.02, nb[2] + Math.cos(a) * (0.3 - k * 0.03)]); } m.add("Nest", tube(ring, 0.05, 5, 24), k % 2 ? C.twig : C.ropeDark); }
    for (const s of [-1, 1]) m.add("Nest", at(lo(0.085, 0.11, 0.085, 8, 5), [nb[0] + 0.08 * s, nb[1] + 0.14, nb[2]]), C.egg);
    out.push(m);
  }

  // ---------- MossbackWorld: the terraces and the far canyon, painted height fields ----------
  {
    const m = model("MossbackWorld");
    const nr = terrain.near, fr = terrain.far, n = nr.h.length - 1;
    m.bone("Floor", null, [0, 0, 0], "SmoothPlastic", "tex/mossback_floor.png");
    m.addTex("Floor", field(nr.rect[0], nr.rect[1], nr.rect[2], nr.rect[3], nr.h));
    const cw = (fr.rect[2] - fr.rect[0]) / n, cd = (fr.rect[3] - fr.rect[1]) / n;
    const under = (i, j) => { const x0 = fr.rect[0] + i * cw, z0 = fr.rect[1] + j * cd; return x0 > nr.rect[0] + 3 && x0 + cw < nr.rect[2] - 3 && z0 > nr.rect[1] + 3 && z0 + cd < nr.rect[3] - 3; };
    m.bone("Far", null, [0, 0, 0], "SmoothPlastic", "tex/mossback_far.png");
    m.addTex("Far", field(fr.rect[0], fr.rect[1], fr.rect[2], fr.rect[3], fr.h, under));
    out.push(m);
  }

  // ---------- ClaySlabA/B/C: rounded clay ledges for the bench edges (a height field cannot overhang). Long axis is X ----------
  for (const [nm, rx, ry, rz, topc, under] of [["ClaySlabA", 12, 1.5, 5.5, "#c2694c", "#7a3324"], ["ClaySlabB", 8.5, 1.25, 4.4, "#ad5139", "#6c2a1e"], ["ClaySlabC", 15, 1.8, 6.6, "#cb8369", "#8b3f2e"]]) {
    const m = model(nm);
    m.bone("Slab", null, [0, 0, 0]);
    const g = new THREE.SphereGeometry(1, 20, 10); const p = g.attributes.position;
    for (let i = 0; i < p.count; i++) {
      const x = p.getX(i), y = p.getY(i), z = p.getZ(i); const sq = (v) => Math.sign(v) * Math.pow(Math.abs(v), 0.62);
      p.setXYZ(i, sq(x) * rx, sq(y) * ry, sq(z) * rz * (1 + 0.1 * Math.sin(x * 4.1 + rx) + 0.06 * Math.sin(x * 9.3)));
    }
    g.computeVertexNormals();
    m.add("Slab", g, topc);
    m.add("Slab", at(ball(rx * 0.97, ry * 0.5, rz * 0.97, 16), [0, -ry * 0.72, 0]), under);
    out.push(m);
  }

  // ---------- CaveMouth: a dark opening in a bench face, with a worn clay lip. Faces +Z ----------
  {
    const m = model("CaveMouth");
    m.bone("Hole", null, [0, 0, 0]);
    m.add("Hole", at(ball(2.6, 3.4, 1.0, 16), [0, 2.6, -0.5]), C.cave);
    const arch = [];
    for (let i = 0; i <= 14; i++) { const a = rad(-100 + i * (200 / 14)); arch.push([Math.sin(a) * 2.9, 2.5 + Math.cos(a) * 3.6, 0.1]); }
    m.add("Hole", tube(arch, (u) => 0.55 + 0.2 * Math.sin(u * 9), 8, 28), C.clay);
    m.add("Hole", at(pillow(6.6, 0.7, 2.2, 0.6, 8), [0, 0.1, 0.5]), C.clayLight); // the sill
    out.push(m);
  }

  // ---------- Waterfall: built 9 studs tall (scaled to each terrace face); the foot is at the origin, the lip 3 studs behind ----------
  {
    const m = model("Waterfall");
    m.bone("Sheet", null, [0, 0, 0], "Neon");
    for (const [dx, w, lean] of [[0, 1.5, 0], [-0.7, 0.6, 0.25], [0.8, 0.5, 0.2]]) {
      const pts = [[dx, 9.75, -5.4], [dx, 9.6, -3.9], [dx * 1.05, 8.6, -2.6 + lean], [dx * 1.1, 4.5, -1.7 + lean], [dx * 1.15, 0.4, -1.2 + lean]];
      m.add("Sheet", at(tube(pts, (u) => 0.5 + 0.12 * u, 8, 20), [0, 0, 0], [0, 0, 0], [w, 1, 0.6]), dx === 0 ? C.water : C.waterLight);
    }
    m.bone("Foam", "Sheet", [0, 0.5, -0.8], "Neon");
    for (let k = 0; k < 7; k++) m.add("Foam", at(ball(0.5 + rnd(k) * 0.3, 0.3, 0.5 + rnd(k + 9) * 0.3, 8), [(rnd(k + 3) - 0.5) * 2.6, 0.55, -0.8 + (rnd(k + 5) - 0.3) * 1.2]), C.waterLight);
    out.push(m);
  }

  // ---------- RopeBridge: 110 studs from bench to bench, sagging in the middle. Runs along X ----------
  {
    const m = model("RopeBridge");
    const L = 55, sag = (x) => -7 * (1 - (x / L) * (x / L));
    m.bone("Deck", null, [0, 0, 0]);
    for (let i = 0; i < 64; i++) { const x = -L + 0.9 + i * ((2 * L - 1.8) / 63); m.add("Deck", at(pillow(1.3, 0.22, 3.0, 0.5, 4), [x, sag(x), 0], [0, (rnd(i) - 0.5) * 8, Math.atan(14 * x / (L * L)) * 57.3]), i % 3 ? C.plank : C.plankDark); }
    m.bone("Ropes", "Deck", [0, 0, 0]);
    for (const z of [-1.5, 1.5]) {
      const lowr = [], high = [];
      for (let i = 0; i <= 24; i++) { const x = -L + (i / 24) * 2 * L; lowr.push([x, sag(x) - 0.05, z]); high.push([x, sag(x) * 0.9 + 2.5, z * 1.1]); }
      m.add("Ropes", tube(lowr, 0.12, 6, 48), C.ropeDark);
      m.add("Ropes", tube(high, 0.11, 6, 48), C.rope);
      for (let i = 1; i < 24; i++) { const x = -L + (i / 24) * 2 * L; m.add("Ropes", limb([x, sag(x), z], [x, sag(x) * 0.9 + 2.5, z * 1.1], 0.05, 0.05, 5), C.rope); }
      for (const s of [-1, 1]) m.add("Ropes", limb([s * L, -2.5, z * 1.2], [s * L, 4.2, z * 1.2], 0.4, 0.3, 8), C.plankDark); // the end posts
    }
    out.push(m);
  }

  // ---------- Bird: the one that nests on the boulder for a few years, and leaves ----------
  {
    const m = model("Bird");
    m.bone("Body", null, [0, 0.2, 0]);
    m.add("Body", at(ball(0.2, 0.19, 0.25, 12), [0, 0.22, 0]), C.bird);
    m.add("Body", at(ball(0.16, 0.13, 0.19, 10), [0, 0.16, 0.06]), C.foot);
    m.add("Body", at(ball(0.15, 0.145, 0.15, 12), [0, 0.42, 0.14]), C.bird);
    m.add("Body", at(lo(0.05, 0.04, 0.09), [0, 0.4, 0.3]), C.beak);
    for (const s of [-1, 1]) m.add("Body", at(lo(0.03, 0.035, 0.02), [0.075 * s, 0.45, 0.26]), C.eye);
    m.add("Body", at(puff([[-0.07, 0], [0.07, 0], [0.1, -0.3], [0, -0.26], [-0.1, -0.3]], 0.03, 0.012), [0, 0.24, -0.2], [70, 0, 0]), C.birdDark);
    m.bone("WingL", "Body", [0.17, 0.3, 0.02]);
    m.add("WingL", at(puff([[0, 0.08], [0.34, 0.06], [0.42, -0.06], [0.2, -0.12], [0, -0.08]], 0.03, 0.012), [0.17, 0.3, 0.0], [90, 0, 0]), C.birdDark);
    m.mirror("WingL", "WingR");
    out.push(m);
  }

  // ---------- TrailBit: one stride of her silver trail. Long axis is Z ----------
  {
    const m = model("TrailBit");
    m.bone("Strip", null, [0, 0, 0]);
    m.add("Strip", pillow(1.25, 0.05, 2.1, 0.8, 5), C.silver);
    out.push(m);
  }

  // ---------- Rainbow: six bands, a half circle 150 studs across standing in the XY plane ----------
  {
    const m = model("Rainbow");
    m.bone("Arc", null, [0, 0, 0], "Neon");
    ["#ff7a6a", "#ffb35c", "#ffe27a", "#8fdc8a", "#7ab8f0", "#b79af0"].forEach((col, k) => {
      const pts = [], r = 75 - k * 2.0;
      for (let i = 0; i <= 32; i++) { const a = (i / 32) * Math.PI; pts.push([Math.cos(a) * r, Math.sin(a) * r, 0]); }
      m.add("Arc", at(tube(pts, 1.0, 4, 48), [0, 0, 0], [0, 0, 0], [1, 1, 0.15]), col);
    });
    out.push(m);
  }
  return out;
}
