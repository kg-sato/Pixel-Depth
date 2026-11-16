// Forge-scene pickaxes for the pickaxes that have no model in ReplicatedStorage.PickaxeArt (2026-11-16 overnight choice):
// each is built from its own biography, so the reveal shows a real pickaxe instead of the plain part fallback.
// ForgeStory's ctx.pick() takes ForgeModels[<model>] when PickaxeArt has no such model.
// Every model stands upright like the real pickaxe models: the haft along +Y from y = 0, the head on top, the blades along X.
//   MossbackPickaxe: a boulder-stone head grown over with moss, a fern sprout and a little nest twig; a dark haft bound in rope.
//   KilnPickaxe: a glazed ceramic head, cream with blue-dipped points and a fine crackle, a terracotta collar; pale ash haft.
//   GeodePickaxe: two geode halves for blades, violet crystal showing (Neon), on her red toy hammer's head; ribbon-wrapped haft.
export const name = "picks";

const C = {
  haftDark: "#5a3a26", haftPale: "#d8b88a", haft: "#9a6a3e", rope: "#c9b384", ropeDark: "#a08a60",
  stone: "#8a8478", stoneDark: "#6a655c", stoneLight: "#a8a296", moss: "#5a8a3a", mossLight: "#7aae4a", mossDark: "#3e6a2a", fern: "#6aa84a",
  glaze: "#f0d9b5", glazeBlue: "#4a6fa5", glazeBlueDark: "#36557e", terracotta: "#c9683e", crackle: "#a8906a",
  rock: "#8a8478", rockDark: "#6a655c", cut: "#e9e3d6", crystal: "#9b6fd6", crystalLight: "#d6b8ff", red: "#d8402e", ribbon: "#f2a0b4",
};

export function build(THREE, T) {
  const { ball, limb, lathe, tube, at, model, rnd } = T;
  const out = [];
  const cyl = (r0, r1, h, seg = 12) => new THREE.CylinderGeometry(r1, r0, h, seg);
  const cone = (r, h, seg = 6) => new THREE.ConeGeometry(r, h, seg);
  const lo = (rx, ry, rz, ws = 7, hs = 5) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const HEAD = 3.3;
  const blade = (s, r0, curve = 0.25, len = 1.35) => [[0, HEAD, 0], [s * len * 0.5, HEAD + 0.02, 0], [s * len, HEAD - curve, 0]]; // a pick point, drooping a little
  const wraps = (m, bn, y0, n, col, r = 0.13) => { for (let k = 0; k < n; k++) m.add(bn, at(cyl(r, r, 0.07, 12), [0, y0 + k * 0.11, 0]), k % 2 ? col : C.ropeDark); };

  // ---------- MossbackPickaxe ----------
  {
    const m = model("MossbackPickaxe");
    m.bone("Haft", null, [0, 0, 0]);
    m.add("Haft", at(cyl(0.11, 0.09, 3.4, 10), [0, 1.7, 0]), C.haftDark);
    wraps(m, "Haft", 0.4, 5, C.rope);
    wraps(m, "Haft", HEAD - 0.6, 3, C.rope);
    m.bone("Head", "Haft", [0, HEAD, 0]);
    for (const s of [-1, 1]) {
      m.add("Head", tube(blade(s, 0.3, 0.32), (u) => 0.3 - 0.26 * u, 9, 16), C.stone);
      m.add("Head", at(lo(0.14, 0.08, 0.16, 6, 4), [s * 0.6, HEAD + 0.12, 0.12]), C.stoneDark);
      m.add("Head", at(lo(0.1, 0.06, 0.1, 6, 4), [s * 0.95, HEAD - 0.02, -0.12]), C.stoneLight);
    }
    m.add("Head", at(lo(0.4, 0.38, 0.36, 12, 9), [0, HEAD, 0]), C.stoneDark); // the eye: a rounded boulder knot
    m.bone("Moss", "Head", [0, HEAD + 0.3, 0]);
    for (let k = 0; k < 14; k++) { const x = (rnd(k * 3) - 0.5) * 1.8, d = Math.abs(x); m.add("Moss", at(lo(0.16 + rnd(k) * 0.1, 0.08, 0.16, 7, 4), [x, HEAD + 0.24 - d * d * 0.12, (rnd(k * 5) - 0.5) * 0.2]), [C.moss, C.mossLight, C.mossDark][k % 3]); }
    for (let k = 0; k < 5; k++) { const a = -0.6 + k * 0.3; m.add("Moss", tube([[0.1, HEAD + 0.36, 0], [0.1 + Math.sin(a) * 0.2, HEAD + 0.62, Math.cos(a) * 0.05], [0.1 + Math.sin(a) * 0.38, HEAD + 0.78, 0.04]], (u) => 0.03 - 0.02 * u, 5, 8), C.fern); } // a fern sprout
    m.add("Moss", tube([[-0.5, HEAD + 0.3, 0.1], [-0.3, HEAD + 0.42, -0.05], [-0.1, HEAD + 0.36, 0.08]], 0.025, 4, 8), C.haft); // a nest twig
    out.push(m);
  }

  // ---------- KilnPickaxe ----------
  {
    const m = model("KilnPickaxe");
    m.bone("Haft", null, [0, 0, 0]);
    m.add("Haft", at(cyl(0.1, 0.09, 3.4, 10), [0, 1.7, 0]), C.haftPale);
    wraps(m, "Haft", 0.35, 6, C.terracotta, 0.12);
    m.bone("Head", "Haft", [0, HEAD, 0]);
    for (const s of [-1, 1]) {
      m.add("Head", tube(blade(s, 0.26, 0.2, 1.4), (u) => 0.26 - 0.23 * u, 10, 18), C.glaze);
      m.add("Head", tube([[s * 1.0, HEAD - 0.06, 0], [s * 1.2, HEAD - 0.12, 0], [s * 1.42, HEAD - 0.21, 0]], (u) => 0.13 - 0.1 * u, 10, 8), C.glazeBlue); // the dipped point
      m.add("Head", tube(blade(s, 0.1, 0.2, 1.0).map(([x, y, z]) => [x, y + 0.19 - Math.abs(x) * 0.08, z + 0.05]), 0.012, 4, 10), C.crackle); // crackle lines
      m.add("Head", tube([[s * 0.3, HEAD - 0.12, 0.2], [s * 0.6, HEAD + 0.05, 0.18], [s * 0.8, HEAD - 0.02, 0.16]], 0.01, 4, 8), C.crackle);
    }
    m.add("Head", at(cyl(0.3, 0.3, 0.5, 14), [0, HEAD, 0], [90, 0, 0]), C.terracotta); // the collar round the eye
    m.add("Head", tube([[-0.3, HEAD + 0.3, 0], [0, HEAD + 0.32, 0], [0.3, HEAD + 0.3, 0]], 0.05, 6, 8), C.glazeBlueDark);
    out.push(m);
  }

  // ---------- GeodePickaxe ----------
  {
    const m = model("GeodePickaxe");
    m.bone("Haft", null, [0, 0, 0]);
    m.add("Haft", at(cyl(0.1, 0.09, 3.4, 10), [0, 1.7, 0]), C.haft);
    for (let k = 0; k < 8; k++) m.add("Haft", at(cyl(0.12, 0.12, 0.08, 12), [0, 0.4 + k * 0.12, 0], [0, 0, (k % 2 ? 1 : -1) * 8]), C.ribbon); // her hat ribbon, wound round
    m.bone("Head", "Haft", [0, HEAD, 0]);
    m.add("Head", at(cyl(0.24, 0.24, 0.6, 14), [0, HEAD, 0], [0, 0, 90]), C.red); // the toy hammer's head is the eye
    for (const s of [-1, 1]) { // a half geode on each side, stretched to a point, its cut face to the front
      const g = new THREE.SphereGeometry(1, 16, 10, Math.PI / 2, Math.PI); const p = g.attributes.position; // the back half (z <= 0)
      for (let i = 0; i < p.count; i++) { const x = p.getX(i), y = p.getY(i), z = p.getZ(i); const k = 1 + 0.12 * Math.sin(x * 5 + y * 3) * Math.sin(z * 4 + 1); p.setXYZ(i, x * k, y * k, z * k); }
      g.computeVertexNormals();
      m.add("Head", at(g, [s * 0.95, HEAD - 0.08, 0.02], [0, 0, s * -12], [0.72, 0.36, 0.3]), C.rock);
      m.add("Head", at(cyl(0.36, 0.36, 0.02, 20), [s * 0.95, HEAD - 0.08, 0.03], [90, 0, s * -12], [2.0, 1, 1]), C.cut); // the pale rind
    }
    m.bone("Crystal", "Head", [0, HEAD, 0.05], "Neon");
    for (const s of [-1, 1]) for (let k = 0; k < 12; k++) {
      const a = (k / 12) * Math.PI * 2, r = 0.08 + rnd(k * 7 + s) * 0.18;
      m.add("Crystal", at(cone(0.04 + rnd(k) * 0.02, 0.12 + rnd(k * 2) * 0.06, 5), [s * 0.95 + Math.cos(a) * r * 1.9, HEAD - 0.08 + Math.sin(a) * r * 0.9, 0.08], [90, 0, 0]), k % 3 ? C.crystal : C.crystalLight);
    }
    out.push(m);
  }
  return out;
}
