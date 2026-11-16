// Titan Hammer Pickaxe biography: "On loan." A stone giant sleeps as the far wall of a canyon; his fingertip has cracked
// along an old line. Three marmot masons ask, he lifts one finger, they band the tip with glowing runes and it comes free;
// he turns over and sleeps on; it takes all three to carry it. Scene bible: vault "Forge Biographies - Scene Bibles
// (2026-11-15)", Titan Hammer. References: refs/forge/sheets/titan_setting_s11.png and marmot_views_s11.png.
// Models: MarmotKit (one mason; the scene makes three, the foreman with the Horn bone shown), StoneGiant (head with an
// Eyelid bone, shoulder, forearm, the open hand on the valley floor; the index finger is the Finger bone, its tip the Tip
// bone with Crack (Neon) and three Neon Band bones), GiantCanyon (floor, walls, boulders, pines), Scaffold (on the finger,
// Neon lanterns), TitanHammerPickaxe (the banded fingertip on a haft).
// Front of every model is +Z. Units are studs. The giant lies across the back of the valley, his hand reaching toward the
// cameras; the index fingertip rests at about (2, 0, -2), where the crew work.
export const name = "titan";

const C = {
  fur: "#b07a3e", furDark: "#7a5228", cream: "#f0dcb8", nose: "#2a1e1a", eye: "#1a1418", white: "#ffffff", tooth: "#fff4dc",
  hat: "#f0c030", hatDark: "#c89a18", scarf: "#d94f4f", apron: "#5f86a8", apronDark: "#45688a", belt: "#6a4628", brass: "#e0a03a", iron: "#5a5660", wood: "#9a6a3e",
  stone: "#8c8478", stoneDark: "#6a645a", stoneLight: "#aaa294", crack: "#3e3a36", moss: "#6a8a3e", mossLight: "#8aae4a",
  rune: "#ffa040", runeHot: "#ffd080", canyon: "#a8907a", canyonDark: "#8a7462", canyonLight: "#c4ac92", ground: "#9a8a6a", grass: "#7a9a4a",
  pine: "#3e6a4a", pineDark: "#2e5038", trunk: "#5a4030", rope: "#c9b384", plank: "#b88a56", lamp: "#ffd98a", haft: "#7a5236",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, model, rnd } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 7, hs = 5) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const box = (w, h, d) => new THREE.BoxGeometry(w, h, d);
  const cyl = (r0, r1, h, seg = 12) => new THREE.CylinderGeometry(r1, r0, h, seg);
  const cone = (r, h, seg = 7) => new THREE.ConeGeometry(r, h, seg);
  const ring = (cx, cy, cz, rx, rz, n = 16) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([cx + Math.sin(a) * rx, cy, cz + Math.cos(a) * rz]); } return p; };
  const bump = (g, amt, s) => { const p = g.attributes.position; for (let i = 0; i < p.count; i++) { const x = p.getX(i), y = p.getY(i), z = p.getZ(i), k = 1 + amt * Math.sin(x * 1.7 * s + 1) * Math.sin(y * 2.1 * s + 2) * Math.sin(z * 1.3 * s + 3); p.setXYZ(i, x * k, y * k, z * k); } g.computeVertexNormals(); return g; };
  const cracks = (m, bn, c, r, n, seed) => { for (let k = 0; k < n; k++) { const a = rnd(seed + k) * 6.28, b = rnd(seed + k * 3) * 3.14; const p0 = [c[0] + Math.sin(b) * Math.cos(a) * r[0], c[1] + Math.cos(b) * r[1], c[2] + Math.sin(b) * Math.sin(a) * r[2]]; const p1 = [p0[0] + (rnd(k * 7) - 0.5) * r[0] * 0.5, p0[1] + (rnd(k * 9) - 0.5) * r[1] * 0.5, p0[2] + (rnd(k * 11) - 0.5) * r[2] * 0.3]; m.add(bn, tube([p0, p1], 0.06 + rnd(k) * 0.06, 4, 3), C.crack); } };

  // ---------- MarmotKit ----------
  {
    const m = model("MarmotKit");
    m.bone("Hips", null, [0, 0.9, 0]);
    m.bone("Body", "Hips", [0, 0.9, 0]);
    m.add("Body", lathe([[0.02, 0.5], [0.62, 0.56], [0.76, 0.9], [0.72, 1.3], [0.54, 1.66], [0.3, 1.9], [0.02, 1.94]], 20), C.fur);
    m.add("Body", at(ball(0.46, 0.6, 0.3, 14), [0, 1.18, 0.46]), C.cream);
    m.add("Body", at(pillow(1.0, 1.0, 0.16, 0.3, 8), [0, 1.0, 0.6]), C.apron);
    m.add("Body", tube(ring(0, 0.92, 0.04, 0.76, 0.74, 20), 0.07, 5, 30), C.belt);
    m.add("Body", at(box(0.12, 0.4, 0.1), [0.5, 0.74, 0.6]), C.iron); // the hammer on his belt
    m.add("Body", at(box(0.3, 0.1, 0.12), [0.5, 0.96, 0.62]), C.iron);
    m.add("Body", tube(ring(0, 1.84, 0.06, 0.36, 0.34, 16), 0.08, 6, 24), C.scarf);
    m.add("Body", at(puff([[0, 0], [0.24, -0.1], [0, -0.3], [-0.24, -0.1]], 0.04, 0.02), [0, 1.78, 0.4]), C.scarf);
    m.bone("Horn", "Body", [0.6, 1.2, 0]); // the foreman's curled brass horn
    m.add("Horn", tube([[0.6, 1.5, -0.1], [0.82, 1.24, 0.1], [0.74, 0.96, 0.3], [0.86, 0.86, 0.5]], (u) => 0.04 + 0.1 * u * u, 8, 20), C.brass);
    m.add("Horn", tube([[0.3, 1.86, 0.1], [0.6, 1.5, -0.1]], 0.02, 4, 4), C.belt);
    m.bone("Head", "Body", [0, 1.94, 0]);
    m.add("Head", at(ball(0.94, 0.84, 0.86, 22), [0, 2.7, 0]), C.fur);
    m.add("Head", at(ball(0.56, 0.42, 0.42, 16), [0, 2.44, 0.52]), C.cream);
    m.add("Head", at(ball(0.13, 0.1, 0.1, 10), [0, 2.58, 0.94]), C.nose);
    for (const s of [-1, 1]) m.add("Head", at(box(0.09, 0.16, 0.05), [0.05 * s, 2.28, 0.9]), C.tooth);
    for (const s of [-1, 1]) m.add("Head", at(ball(0.18, 0.18, 0.1, 10), [0.66 * s, 3.2, -0.1]), C.furDark);
    m.bone("Eyes", "Head", [0, 2.82, 0.78]);
    for (const s of [-1, 1]) { m.add("Eyes", at(ball(0.13, 0.15, 0.06, 10), [0.3 * s, 2.82, 0.8], [0, 18 * s, 0]), C.eye); m.add("Eyes", at(ball(0.04, 0.05, 0.03, 6), [0.3 * s + 0.04, 2.88, 0.85]), C.white); }
    m.bone("EyesShut", "Head", [0, 2.82, 0.84]);
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.18 * s, 2.82, 0.82], [0.3 * s, 2.78, 0.86], [0.42 * s, 2.82, 0.8]], 0.03, 5, 8), C.furDark);
    m.bone("Hat", "Head", [0, 3.4, 0]);
    m.add("Hat", at(lathe([[0.02, 0], [0.74, 0], [0.72, 0.3], [0.56, 0.54], [0.24, 0.64], [0.02, 0.66]], 18), [0, 3.3, 0]), C.hat);
    m.add("Hat", at(cyl(0.9, 0.86, 0.06, 20), [0, 3.3, 0.08], [-6, 0, 0]), C.hat);
    m.add("Hat", tube([[0, 3.32, 0.76], [0, 3.9, 0.1], [0, 3.92, -0.3]], 0.06, 5, 10), C.hatDark);
    m.bone("ArmL", "Body", [0.58, 1.6, 0]);
    m.add("ArmL", limb([0.58, 1.6, 0], [0.84, 1.16, 0.1], 0.16, 0.14), C.fur);
    m.bone("ForeL", "ArmL", [0.84, 1.16, 0.1]);
    m.add("ForeL", limb([0.84, 1.16, 0.1], [0.9, 0.8, 0.26], 0.14, 0.12), C.fur);
    m.add("ForeL", at(ball(0.15, 0.13, 0.15, 10), [0.91, 0.74, 0.3]), C.furDark);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");
    m.bone("LegL", "Hips", [0.28, 0.66, 0]);
    m.add("LegL", limb([0.28, 0.66, 0], [0.3, 0.12, 0.04], 0.18, 0.15), C.fur);
    m.add("LegL", at(ball(0.2, 0.1, 0.3, 10), [0.3, 0.07, 0.16]), C.furDark);
    m.mirror("LegL", "LegR");
    m.bone("Tail1", "Hips", [0, 0.7, -0.6]);
    m.add("Tail1", at(ball(0.2, 0.3, 0.2, 10), [0, 0.6, -0.76], [-30, 0, 0]), C.furDark);
    out.push(m);
  }

  // ---------- StoneGiant: asleep on his side across the back of the valley ----------
  {
    const m = model("StoneGiant");
    m.bone("Body", null, [0, 0, -30]);
    m.add("Body", bump(at(lo(26, 16, 14, 18, 12), [-14, 6, -40]), 0.06, 0.15), C.stone); // shoulder and back: a cliff
    m.add("Body", bump(at(lo(18, 10, 10, 16, 10), [16, 2, -44]), 0.06, 0.2), C.stoneDark); // hip, far right
    cracks(m, "Body", [-14, 6, -40], [26, 16, 14], 26, 11);
    for (let k = 0; k < 18; k++) m.add("Body", at(lo(1.5 + rnd(k) * 1.5, 0.5, 1.4, 6, 4), [-30 + rnd(k * 3) * 36, 16 + rnd(k * 5) * 5, -34 + rnd(k * 7) * 6]), k % 2 ? C.moss : C.mossLight); // moss on the shoulder
    m.bone("Head", "Body", [-34, 12, -30]);
    m.add("Head", bump(at(lo(10, 9, 9, 18, 12), [-36, 14, -26], [0, 20, 70]), 0.05, 0.2), C.stoneLight);
    m.add("Head", at(lo(2.6, 1.8, 2.4, 10, 8), [-30.5, 15, -18.5]), C.stone); // the nose
    m.add("Head", at(lo(4.4, 0.9, 2.0, 10, 6), [-31, 9.6, -19.5], [0, 0, -16]), C.stoneDark); // the slack mouth
    m.add("Head", at(lo(3.4, 3.4, 1.6, 10, 8), [-44, 16, -24]), C.stone); // the ear (a nest in it)
    m.add("Head", at(lo(1.2, 0.6, 1.2, 8, 4), [-44, 18.4, -23.2]), C.wood);
    cracks(m, "Head", [-36, 14, -26], [9, 8, 8], 14, 44);
    m.bone("Eyelid", "Head", [-33, 18.5, -18.5]); // the closed eye: a stone lid; the scene lifts it to a slit
    m.add("Eyelid", at(lo(3.2, 1.1, 1.0, 12, 6), [-33, 18.5, -18.4], [0, 0, -10]), C.stoneLight);
    m.bone("EyeDark", "Head", [-33, 18.4, -18.9]);
    m.add("EyeDark", at(lo(2.6, 0.9, 0.4, 10, 6), [-33, 18.4, -18.9], [0, 0, -10]), "#1a1418");
    // the forearm comes forward along the valley floor and the open hand lies palm up
    m.bone("Arm", "Body", [-8, 3, -26]);
    m.add("Arm", bump(tube([[-8, 3, -26], [-4, 2.2, -16], [-1, 1.8, -8]], (u) => 5.4 - 1.4 * u, 14, 12), 0.04, 0.3), C.stone);
    cracks(m, "Arm", [-4, 2.5, -16], [4, 3, 8], 10, 70);
    m.bone("Hand", "Arm", [0, 1.4, -6]);
    m.add("Hand", bump(at(lo(6.2, 1.8, 5.0, 16, 10), [1, 1.4, -4.5]), 0.04, 0.4), C.stoneLight); // the palm
    for (let k = 0; k < 9; k++) m.add("Hand", at(lo(0.5, 0.2, 0.5, 6, 4), [-1.5 + rnd(k) * 5, 3.0, -6.5 + rnd(k * 3) * 4]), C.grass); // grass in the palm
    for (const [x, z, h] of [[-0.5, -5.5, 3.2], [1.6, -6.4, 2.6], [3.0, -4.8, 2.2]]) { m.add("Hand", at(cyl(0.18, 0.22, h * 0.4, 6), [x, 3.0 + h * 0.2, z]), C.trunk); for (let j = 0; j < 3; j++) m.add("Hand", at(cone(1.0 - j * 0.25, 1.2, 8), [x, 3.0 + h * 0.4 + j * 0.6, z]), j % 2 ? C.pineDark : C.pine); } // trees in his palm
    const finger = (bn, base, dir, len, r) => { const tip = [base[0] + dir[0] * len, base[1] + dir[1] * len, base[2] + dir[2] * len]; m.add(bn, bump(tube([base, [(base[0] + tip[0]) / 2, base[1] + 0.3, (base[2] + tip[2]) / 2], tip], (u) => r * (1 - 0.15 * u), 10, 8), 0.04, 0.6), C.stone); return tip; };
    m.bone("Thumb", "Hand", [-4, 1.6, -3]);
    finger("Thumb", [-4.5, 1.6, -2.5], [-0.6, 0.2, 0.8], 5, 1.6);
    for (const [i, x] of [[0, 3.4], [1, 1.0], [2, -1.4]]) { m.bone("F" + i, "Hand", [x, 1.4, -1]); finger("F" + i, [x + 0.6, 1.2, -1.2], [0.15, -0.08, 1], 5.5 - i * 0.6, 1.2); }
    // the index finger, nearest the cameras: it lifts; its tip is the part that comes away
    m.bone("Finger", "Hand", [4.6, 1.4, -1]);
    const ftip = finger("Finger", [5.0, 1.2, -1.2], [0.06, -0.12, 1], 4.8, 1.3);
    m.bone("Tip", "Finger", [ftip[0], ftip[1], ftip[2]]);
    m.add("Tip", bump(at(lo(1.15, 1.05, 1.5, 12, 10), [ftip[0], ftip[1], ftip[2] + 0.7]), 0.05, 0.8), C.stoneLight);
    m.bone("Crack", "Tip", [ftip[0], ftip[1], ftip[2]], "Neon");
    m.add("Crack", tube([[ftip[0] - 1.1, ftip[1] + 0.3, ftip[2] - 0.1], [ftip[0], ftip[1] + 1.05, ftip[2] + 0.05], [ftip[0] + 1.1, ftip[1] + 0.2, ftip[2] - 0.1]], 0.07, 4, 10), C.rune);
    for (let k = 0; k < 3; k++) { m.bone("Band" + (k + 1), "Tip", [ftip[0], ftip[1], ftip[2] + 0.2 + k * 0.5], "Neon"); m.add("Band" + (k + 1), at(tube(ring(0, 0, 0, 1.22, 1.12, 20), 0.09, 5, 30), [ftip[0], ftip[1], ftip[2] + 0.2 + k * 0.5], [90, 0, 0]), C.rune); }
    out.push(m);
  }

  // ---------- GiantCanyon: the valley floor, the side walls, boulders, pines ----------
  {
    const m = model("GiantCanyon");
    m.bone("Floor", null, [0, 0, 0]);
    m.add("Floor", at(box(160, 0.4, 160), [0, -0.2, -40]), C.ground);
    for (let k = 0; k < 80; k++) m.add("Floor", at(lo(0.2 + rnd(k) * 0.6, 0.12 + rnd(k * 2) * 0.2, 0.3 + rnd(k * 3) * 0.4, 6, 4), [(rnd(k * 5) - 0.5) * 40, 0.05, 10 - rnd(k * 7) * 40]), [C.stoneDark, C.canyonLight, C.grass][k % 3]);
    m.bone("Walls", null, [0, 0, 0]);
    for (const s of [-1, 1]) for (let k = 0; k < 6; k++) { const h = 12 + k * 5 + rnd(k + s) * 6; m.add("Walls", bump(at(lo(10, h, 14, 10, 8), [s * (26 + k * 9), h * 0.4, -10 - k * 14]), 0.08, 0.3), [C.canyon, C.canyonDark, C.canyonLight][(k + (s > 0 ? 1 : 0)) % 3]); }
    for (let k = 0; k < 16; k++) { const s = k % 2 ? 1 : -1, x = s * (9 + rnd(k * 3) * 10), z = 6 - rnd(k * 5) * 30; m.add("Walls", at(cyl(0.2, 0.26, 1.4, 6), [x, 0.7, z]), C.trunk); for (let j = 0; j < 3; j++) m.add("Walls", at(cone(1.4 - j * 0.35, 1.6, 8), [x, 1.6 + j * 0.8, z]), j % 2 ? C.pineDark : C.pine); }
    out.push(m);
  }

  // ---------- Scaffold: up the side of the index finger, lanterns to show the scale ----------
  {
    const m = model("Scaffold");
    m.bone("Frame", null, [0, 0, 0]);
    for (const [x, z] of [[0, 0], [1.6, 0], [0, 1.4], [1.6, 1.4]]) m.add("Frame", at(box(0.12, 4.0, 0.12), [x, 2.0, z]), C.wood);
    for (const y of [1.3, 2.6, 3.9]) { m.add("Frame", at(box(1.8, 0.08, 1.6), [0.8, y, 0.7]), C.plank); m.add("Frame", at(box(1.8, 0.06, 0.06), [0.8, y + 0.5, 0]), C.wood); }
    for (const d of [0, 1.4]) m.add("Frame", tube([[0, 0.2, d], [1.6, 1.3, d], [0, 2.6, d], [1.6, 3.9, d]], 0.035, 4, 12), C.rope);
    m.add("Frame", tube([[-0.3, 4.0, 0.3], [-0.4, 0, 0.3]], 0.03, 4, 2), C.rope); // a rope ladder
    m.add("Frame", tube([[-0.3, 4.0, 0.8], [-0.4, 0, 0.8]], 0.03, 4, 2), C.rope);
    for (let k = 1; k < 10; k++) m.add("Frame", at(box(0.06, 0.04, 0.5), [-0.35, k * 0.4, 0.55]), C.plank);
    m.bone("Lamps", "Frame", [0.8, 2.6, 0.7], "Neon");
    for (const [x, y, z] of [[0, 1.8, 0], [1.6, 3.1, 1.4], [0, 4.4, 1.4]]) m.add("Lamps", at(ball(0.12, 0.16, 0.12, 8), [x, y, z]), C.lamp);
    out.push(m);
  }

  // ---------- TitanHammerPickaxe: the banded fingertip on a haft ----------
  {
    const m = model("TitanHammerPickaxe");
    const HEAD = 3.2;
    m.bone("Haft", null, [0, 0, 0]);
    m.add("Haft", at(cyl(0.12, 0.1, 3.4, 10), [0, 1.7, 0]), C.haft);
    for (let k = 0; k < 4; k++) m.add("Haft", at(cyl(0.14, 0.14, 0.08, 12), [0, 0.4 + k * 0.12, 0]), k % 2 ? C.scarf : C.rope);
    m.bone("Head", "Haft", [0, HEAD, 0]);
    m.add("Head", bump(at(lo(1.25, 0.55, 0.55, 14, 10), [0, HEAD, 0]), 0.06, 1.2), C.stoneLight); // the fingertip, lying across: a hammer face and a blunt point
    m.add("Head", at(lo(0.4, 0.5, 0.5, 8, 6), [-1.2, HEAD, 0]), C.stone);
    m.bone("Bands", "Head", [0, HEAD, 0], "Neon");
    for (const x of [-0.6, 0, 0.6]) m.add("Bands", at(tube(ring(0, 0, 0, 0.58, 0.58, 18), 0.05, 5, 24), [x, HEAD, 0], [0, 0, 90]), C.rune);
    out.push(m);
  }
  return out;
}
