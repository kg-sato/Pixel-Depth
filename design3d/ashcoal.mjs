// Ashcoal Pickaxe biography: "oak logs stacked in a ring and buried under turf; a badger charcoal burner watched the mound
// for three nights". The setting (scene bible entry "Ashcoal", refs/forge/sheets/ashcoal_setting_s11.png): a clearing in an old
// oak wood on a hillside at night, a turf-covered charcoal mound as tall as the maker, a split-log windbreak, a stack of oak
// cordwood, a three-legged stool, a kettle and one lantern; between the trunks a valley filling with mist.
// Models: BadgerKit (the maker, the same bone names as BoltKit), AshcoalSet (the clearing's things), AshcoalWorld (painted
// terrain), SootPuff (a soot sprite with ember eyes), AshKettle, AshCup, AshPoker, AshLog (what he holds).
// Front of every model is +Z, the camera stands at +Z. Units are studs. Heights and painted pictures come from ashcoal_world.py.
import terrain from "./tex/ashcoal_terrain.mjs";
export const name = "ashcoal";

const C = {
  fur: "#5f5b66", furDark: "#221e27", furLight: "#8d8994", white: "#f4f0e6", cream: "#e6dcc8", nose: "#17131c", soot: "#3a3540", eye: "#0e0a14", eyeRing: "#4a4552", pink: "#e9a3b4",
  coat: "#4f5737", coatDark: "#3a4128", coatLight: "#677048", patch1: "#8a5a3c", patch2: "#5d6f8c", patch3: "#b08a3e", brass: "#d9a94e", boot: "#4a382c", bootLight: "#6a5240",
  mitt: "#b4553a", mittDark: "#8c3f2c", cap: "#7d6b55", capDark: "#5c4d3e", capLight: "#96846a",
  turf: "#3f4530", turfDark: "#2c3122", turfLight: "#56603a", earth: "#4b3c31", earthDark: "#30261f",
  oak: "#6e5440", oakDark: "#4d3a2d", oakEnd: "#d2b282", oakEndDark: "#b08e62",
  coal: "#1d1a1f", coalLight: "#3a363d", ash: "#8d8a88", ember: "#ff7a2a", emberHot: "#ffc45a",
  iron: "#3b3d45", ironLight: "#5a5d68", tin: "#9aa0aa", tinDark: "#737984", stone: "#7d7c82", stoneDark: "#5c5b62", sack: "#a08c66", sackDark: "#7d6c4e", rope: "#c8b48a", tea: "#a8642c",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, field, rnd, model } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 6, hs = 4) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const deg = (r) => (r * 180) / Math.PI;
  const ring = (rx, rz, y, zc = 0, n = 16) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([Math.sin(a) * rx, y, Math.cos(a) * rz + zc]); } return p; };

  // ---------- BadgerKit: the charcoal burner ----------
  {
    const m = model("BadgerKit");
    m.bone("Hips", null, [0, 0.95, 0]);
    m.bone("Body", "Hips", [0, 0.95, 0]);
    // a stout body in a waxed coat, open down the front
    m.add("Body", lathe([[0.02, 0.66], [0.56, 0.7], [0.82, 0.95], [0.86, 1.25], [0.72, 1.65], [0.5, 1.95], [0.02, 2.04]], 20), C.coat);
    m.add("Body", tube(ring(0.84, 0.8, 0.86), 0.09, 6, 32), C.coatDark); // the hem
    m.add("Body", tube(ring(0.52, 0.5, 1.96), 0.14, 8, 32), C.coatLight); // the collar, turned up
    // the hood, down: a soft bag of cloth lying on his back below the collar, its rim folded over (the turnaround's back view)
    m.add("Body", at(ball(0.62, 0.5, 0.34, 16), [0, 1.78, -0.56], [-18, 0, 0]), C.coat);
    m.add("Body", at(ball(0.46, 0.36, 0.2, 12), [0, 1.86, -0.74], [-18, 0, 0]), C.coatDark);
    m.add("Body", tube([[-0.5, 1.98, -0.28], [-0.6, 1.9, -0.62], [-0.32, 2.06, -0.86], [0, 2.1, -0.9], [0.32, 2.06, -0.86], [0.6, 1.9, -0.62], [0.5, 1.98, -0.28]], 0.09, 7, 24), C.coatLight);
    m.add("Body", at(ball(0.3, 0.6, 0.2), [0, 1.34, 0.68]), C.cream); // his shirt, where the coat stands open
    for (const s of [-1, 1]) m.add("Body", tube([[0.22 * s, 1.9, 0.46], [0.32 * s, 1.5, 0.74], [0.34 * s, 1.1, 0.8], [0.3 * s, 0.82, 0.74]], 0.07, 6, 12), C.coatDark); // the two edges of the coat
    for (const y of [1.56, 1.32, 1.08]) m.add("Body", at(ball(0.05, 0.05, 0.035, 6), [0.42, y, 0.76]), C.brass);
    m.add("Body", tube(ring(0.88, 0.86, 1.12), 0.05, 6, 32), C.rope); // a rope for a belt
    m.add("Body", at(ball(0.1, 0.09, 0.08, 8), [0.1, 1.12, 0.88]), C.rope);
    for (const dx of [-0.04, 0.1]) m.add("Body", limb([0.1, 1.1, 0.9], [0.1 + dx, 0.84, 0.92], 0.035, 0.03, 6), C.rope);
    // the patches: one on the front, one on the back, one over the pocket
    m.add("Body", at(pillow(0.34, 0.32, 0.08, 0.5), [-0.52, 1.5, 0.52], [-8, -40, 6]), C.patch1);
    m.add("Body", at(pillow(0.4, 0.36, 0.08, 0.5), [0.3, 1.36, -0.8], [6, 160, -8]), C.patch2);
    m.add("Body", at(pillow(0.42, 0.34, 0.12, 0.5), [-0.58, 0.98, 0.6], [0, -40, 0]), C.coatDark); // the pocket
    m.add("Body", at(pillow(0.2, 0.18, 0.06, 0.5), [-0.62, 0.92, 0.68], [0, -40, 10]), C.patch3);
    m.add("Body", at(pillow(0.36, 0.3, 0.08, 0.5), [0.66, 1.06, -0.5], [0, 128, 12]), C.patch3);

    const HS = 1.16, J = [0, 2.02, 0];
    const H = (g) => at(g, [0, J[1] * (1 - HS), 0], [0, 0, 0], HS);
    const hj = (p) => [p[0] * HS, J[1] + (p[1] - J[1]) * HS, p[2] * HS];
    m.bone("Head", "Body", J);
    m.add("Head", H(at(ball(1.02, 0.88, 0.92, 24), [0, 2.74, 0.05])), C.fur);
    m.add("Head", H(at(ball(0.4, 1.0, 1.02, 18), [0, 2.76, 0.1])), C.white); // the white stripe, nose to crown
    for (const s of [-1, 1]) {
      m.add("Head", H(at(ball(0.3, 0.42, 0.2), [0.43 * s, 2.78, 0.78], [-10, 18 * s, 10 * s])), C.furDark); // the black band through each eye
      m.add("Head", H(at(ball(0.3, 0.4, 0.34), [0.5 * s, 3.12, 0.42], [-40, 10 * s, 8 * s])), C.furDark);
      m.add("Head", H(at(ball(0.16, 0.23, 0.06), [0.43 * s, 2.74, 0.905], [0, 16 * s, 0])), C.eyeRing); // a paler rim so the eye reads on the black
      m.add("Head", H(at(ball(0.44, 0.36, 0.38), [0.58 * s, 2.36, 0.42])), C.white); // the white cheek
      m.add("Head", H(at(ball(0.13, 0.1, 0.05), [0.72 * s, 2.44, 0.7], [0, 30 * s, 0])), C.pink);
      const tuft = (len, wid) => puff([[0, wid], [len * 0.5, wid * 0.7], [len * 0.85, wid * 0.2], [len, 0], [len * 0.7, -wid * 0.5], [len * 0.36, -wid * 0.86], [0, -wid]], 0.07, 0.045);
      for (const [y, a, len, wid, c, zf] of [[2.62, -8, 0.5, 0.2, C.furLight, 0.02], [2.42, -28, 0.56, 0.2, C.white, 0.08], [2.26, -48, 0.4, 0.16, C.white, 0.12]]) { // cheek ruff, swept back
        const g = at(tuft(len, wid), [0.78, y, 0.18 + zf], [0, -22, a]);
        m.add("Head", H(s > 0 ? g : at(g, [0, 0, 0], [0, 0, 0], [-1, 1, 1])), c);
      }
    }
    m.add("Head", H(at(ball(0.42, 0.3, 0.36), [0, 2.42, 0.84])), C.white); // the muzzle
    m.add("Head", H(at(ball(0.17, 0.13, 0.12), [0, 2.54, 1.15])), C.nose);
    m.add("Head", H(at(ball(0.15, 0.1, 0.05), [0.2, 2.5, 1.08], [0, 24, 0])), C.soot); // soot smudges on his nose and chin
    m.add("Head", H(at(ball(0.1, 0.08, 0.05), [-0.14, 2.3, 1.1], [20, -14, 0])), C.soot);
    m.add("Head", H(tube([[-0.11, 2.38, 1.11], [-0.05, 2.34, 1.15], [0, 2.37, 1.16], [0.05, 2.34, 1.15], [0.11, 2.38, 1.11]], 0.022, 6, 12)), C.nose);
    // the flat tweed cap
    m.add("Head", H(at(ball(0.94, 0.3, 0.97, 18), [0, 3.5, 0.06], [8, 0, 0])), C.cap);
    m.add("Head", H(at(ball(0.58, 0.07, 0.42, 12), [0, 3.36, 0.92], [14, 0, 0])), C.capDark); // its peak
    m.add("Head", H(tube(ring(0.93, 0.95, 3.42, 0.05), 0.055, 6, 32)), C.capDark);
    m.add("Head", H(at(ball(0.1, 0.06, 0.1, 8), [0, 3.8, 0.02])), C.capDark);
    for (let k = 0; k < 9; k++) { const a = rnd(k + 300) * 6.283, r = 0.25 + rnd(k + 310) * 0.5; m.add("Head", H(at(lo(0.09, 0.03, 0.06), [Math.sin(a) * r, 3.5 + 0.28 * Math.sqrt(Math.max(0, 1 - (r * r) / 0.86)), 0.06 + Math.cos(a) * r], [0, deg(a), 0])), k % 2 ? C.capLight : C.capDark); } // tweed flecks

    m.bone("Eyes", "Head", hj([0, 2.8, 0.9]));
    for (const s of [-1, 1]) {
      m.add("Eyes", H(at(ball(0.125, 0.19, 0.07), [0.43 * s, 2.74, 0.94], [0, 16 * s, 0])), C.eye);
      m.add("Eyes", H(at(ball(0.055, 0.06, 0.03), [0.43 * s + 0.035, 2.82, 1.0])), C.white);
      m.add("Eyes", H(at(ball(0.024, 0.024, 0.02, 6), [0.43 * s - 0.04, 2.66, 0.995])), C.white);
    }
    m.bone("EyesShut", "Head", hj([0, 2.8, 0.95])); // sleepy closed lids: arcs that hang down
    for (const s of [-1, 1]) m.add("EyesShut", H(tube([[0.28 * s, 2.78, 0.94], [0.43 * s, 2.68, 1.0], [0.58 * s, 2.78, 0.91]], 0.035, 6, 10)), C.cream);

    m.bone("EarL", "Head", hj([0.86, 3.1, 0]));
    m.add("EarL", H(at(ball(0.24, 0.26, 0.1), [0.92, 3.16, -0.02], [0, 0, -40])), C.white);
    m.add("EarL", H(at(ball(0.19, 0.21, 0.1), [0.92, 3.16, 0.05], [0, 0, -40])), C.furDark);
    m.mirror("EarL", "EarR");

    m.bone("ArmL", "Body", [0.66, 1.8, 0.05]);
    m.add("ArmL", limb([0.66, 1.8, 0.05], [1.02, 1.4, 0.12], 0.23, 0.2), C.coat);
    m.add("ArmL", at(pillow(0.26, 0.24, 0.08, 0.5), [0.98, 1.52, -0.06], [10, 150, 40]), C.patch1); // elbow patch
    m.bone("ForeL", "ArmL", [1.02, 1.4, 0.12]);
    m.add("ForeL", limb([1.02, 1.4, 0.12], [1.12, 1.06, 0.26], 0.19, 0.19), C.coat);
    m.add("ForeL", at(lathe([[0.21, -0.08], [0.225, 0], [0.21, 0.08]], 12), [1.11, 1.1, 0.25], [20, 0, -14]), C.mittDark); // the mitt's ribbed cuff
    m.add("ForeL", at(ball(0.23, 0.2, 0.24), [1.13, 0.96, 0.32]), C.mitt); // a fingerless knitted mitt
    for (const dx of [-0.12, 0, 0.12]) m.add("ForeL", at(ball(0.075, 0.09, 0.08, 8), [1.13 + dx, 0.84, 0.44 - Math.abs(dx) * 0.3]), C.furDark);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");

    m.bone("LegL", "Hips", [0.36, 0.95, 0]);
    m.add("LegL", limb([0.36, 0.95, 0], [0.4, 0.36, 0.04], 0.25, 0.22), C.furDark);
    m.add("LegL", at(ball(0.29, 0.19, 0.4), [0.41, 0.18, 0.2]), C.boot); // a worn boot
    m.add("LegL", at(lathe([[0.25, -0.06], [0.27, 0], [0.25, 0.06]], 12), [0.4, 0.38, 0.05]), C.bootLight);
    m.add("LegL", at(ball(0.3, 0.05, 0.41, 10), [0.41, 0.05, 0.2]), C.earthDark);
    m.mirror("LegL", "LegR");

    m.bone("Tail1", "Hips", [0, 0.95, -0.6]);
    m.add("Tail1", at(ball(0.26, 0.24, 0.3), [0, 0.98, -0.82]), C.fur);
    m.bone("Tail2", "Tail1", [0, 1.0, -1.0]);
    m.add("Tail2", at(ball(0.22, 0.2, 0.26), [0, 1.02, -1.12]), C.furLight);
    m.add("Tail2", at(ball(0.14, 0.13, 0.16), [0, 1.05, -1.32]), C.white);
    out.push(m);
  }

  // ---------- AshcoalSet: the clearing's things. The mound stands at (MX, MZ); ashcoal_world.py paints its ash ring there ----------
  const MX = -2.6, MZ = -1.5;
  {
    const m = model("AshcoalSet");
    const prof = [[3.3, 0], [3.24, 0.5], [3.0, 1.3], [2.5, 2.2], [1.8, 3.0], [1.0, 3.6], [0.34, 3.9], [0.02, 3.96]];
    const domeR = (y) => { for (let i = 0; i < prof.length - 1; i++) { const [r0, y0] = prof[i], [r1, y1] = prof[i + 1]; if (y <= y1) return r0 + ((r1 - r0) * (y - y0)) / (y1 - y0); } return 0.02; };
    const onDome = (a, y, o = 0) => { const r = domeR(y) + o; return [MX + Math.cos(a) * r, y, MZ + Math.sin(a) * r]; };
    const face = (a) => 90 - deg(a); // the yaw that turns a thing's +Z to point out of the mound at angle a
    m.bone("Ground", null, [0, 0, 0]);

    // the stack: oak logs stood on end in three rings round a centre pole (BORN shows them one ring at a time)
    const logs = (bone, n, r0, r1, h, rad, seed) => {
      for (let k = 0; k < n; k++) {
        const a = (k / n) * 6.283 + seed, j = (rnd(k + seed * 31) - 0.5) * 0.16;
        const top = [MX + Math.cos(a) * (r1 + j), h + j, MZ + Math.sin(a) * (r1 + j)];
        m.add(bone, limb([MX + Math.cos(a) * r0, 0.05, MZ + Math.sin(a) * r0], top, rad, rad * 0.92, 8), k % 3 ? C.oak : C.oakDark);
        m.add(bone, at(lo(rad * 0.8, 0.05, rad * 0.8, 8, 3), [top[0], top[1] + rad * 0.72, top[2]]), C.oakEnd);
      }
    };
    m.bone("Ring1", "Ground", [MX, 0, MZ]); logs("Ring1", 8, 0.55, 0.3, 3.3, 0.24, 0.2);
    m.add("Ring1", limb([MX, 0, MZ], [MX, 3.7, MZ], 0.13, 0.11, 8), C.oakDark); // the centre pole: pulled out to leave the flue
    m.bone("Ring2", "Ground", [MX, 0, MZ]); logs("Ring2", 13, 1.35, 0.85, 2.8, 0.25, 0.5);
    m.bone("Ring3", "Ground", [MX, 0, MZ]); logs("Ring3", 18, 2.25, 1.6, 2.15, 0.26, 0.9);

    // the turf: sods laid over the stack like scales, a rim of beaten earth at its foot
    m.bone("Turf", "Ground", [MX, 0, MZ]);
    m.add("Turf", at(lathe(prof, 28), [MX, 0, MZ]), C.turf);
    m.add("Turf", at(lathe([[3.55, 0], [3.5, 0.22], [3.28, 0.34]], 28), [MX, 0, MZ]), C.earth);
    for (const y of [0.95, 1.85, 2.7, 3.35]) { const p = []; for (let i = 0; i <= 28; i++) p.push(onDome((i / 28) * 6.283, y + Math.sin(i * 2.1) * 0.05, 0.015)); m.add("Turf", tube(p, 0.045, 5, 56), C.turfDark); } // the seams between the courses of sods
    for (let k = 0; k < 40; k++) { // seams down the courses, tufts of grass still growing on the sods
      const a = rnd(k + 400) * 6.283, y = 0.2 + rnd(k + 410) * 3.3, p = onDome(a, y, 0.02);
      m.add("Turf", at(lo(0.22 + rnd(k + 420) * 0.2, 0.12, 0.1), p, [-(20 + y * 14), face(a), 0]), k % 3 ? C.turfLight : C.turfDark);
    }
    const VENTS = [[0.55, 0.75], [1.3, 0.8], [2.1, 0.75], [2.85, 0.8], [0.9, 2.3], [1.75, 2.4], [2.6, 2.3], [-0.5, 0.8], [3.7, 0.8]]; // angle, height: most face the camera
    for (const [a, y] of VENTS) m.add("Turf", at(lo(0.27, 0.27, 0.08, 8, 4), onDome(a, y, 0.0), [-(20 + y * 12), face(a), 0]), C.earthDark); // each vent hole's scorched rim
    m.add("Turf", at(lo(0.4, 0.1, 0.4, 8, 4), [MX, 3.94, MZ]), C.earthDark);
    m.bone("Vents", "Ground", [MX, 1.5, MZ], "Neon"); // the glow inside every vent hole
    for (const [a, y] of VENTS) m.add("Vents", at(lo(0.16, 0.16, 0.07, 8, 4), onDome(a, y, 0.045), [-(20 + y * 12), face(a), 0]), C.ember);
    m.add("Vents", at(lo(0.22, 0.07, 0.22, 8, 4), [MX, 4.0, MZ]), C.ember);

    // what is under the turf on the third dawn: a heap of charcoal on a bed of ash, embers between the lumps
    m.bone("Coal", "Ground", [MX, 0, MZ]);
    m.add("Coal", at(lo(3.1, 0.1, 3.1, 14, 4), [MX, 0.03, MZ]), C.ash);
    for (let k = 0; k < 64; k++) {
      const a = rnd(k + 500) * 6.283, r = Math.sqrt(rnd(k + 510)) * 2.5, y = 0.2 + (1 - r / 2.6) * 1.5 * (0.6 + 0.4 * rnd(k + 520));
      m.add("Coal", at(lo(0.3 + rnd(k + 530) * 0.3, 0.2 + rnd(k + 540) * 0.16, 0.26 + rnd(k + 550) * 0.2, 5, 3), [MX + Math.cos(a) * r, y, MZ + Math.sin(a) * r], [rnd(k + 560) * 60 - 30, rnd(k + 570) * 360, rnd(k + 580) * 60 - 30]), k % 4 ? C.coal : C.coalLight);
    }
    for (let k = 0; k < 9; k++) { const a = rnd(k + 600) * 6.283, r = 1.2 + rnd(k + 610) * 1.5; m.add("Coal", limb([MX + Math.cos(a) * r, 0.2, MZ + Math.sin(a) * r], [MX + Math.cos(a + 0.5) * (r - 0.9), 0.5 + rnd(k + 620) * 0.6, MZ + Math.sin(a + 0.5) * (r - 0.9)], 0.17, 0.14, 6), C.coal); } // whole charred logs
    m.bone("Embers", "Ground", [MX, 0.6, MZ], "Neon");
    for (let k = 0; k < 20; k++) { const a = rnd(k + 700) * 6.283, r = Math.sqrt(rnd(k + 710)) * 2.2; m.add("Embers", at(lo(0.14, 0.09, 0.12, 5, 3), [MX + Math.cos(a) * r, 0.34 + (1 - r / 2.6) * 1.3, MZ + Math.sin(a) * r]), C.ember); }
    m.bone("Sods", "Ground", [MX, 0, MZ]); // the sods raked off and thrown back in a ring
    for (let k = 0; k < 12; k++) {
      const a = -0.5 + (k / 11) * 4.2 + (rnd(k + 800) - 0.5) * 0.2, r = 3.6 + rnd(k + 810) * 0.8, p = [MX + Math.cos(a) * r, 0.16, MZ + Math.sin(a) * r], rot = [rnd(k + 820) * 30 - 15, rnd(k + 830) * 360, rnd(k + 840) * 30 - 15];
      m.add("Sods", at(pillow(0.9, 0.2, 0.7, 0.5), p, rot), C.earth);
      m.add("Sods", at(pillow(0.86, 0.14, 0.66, 0.5), [p[0], p[1] + 0.12, p[2]], rot), k % 2 ? C.turf : C.turfDark);
    }

    // the windbreak: split oak logs stood in an arc on the windward side, tied to two rails, propped from behind
    m.bone("Windbreak", "Ground", [MX, 0, MZ]);
    const rails = [[], []];
    for (let k = 0; k < 14; k++) {
      const a = 2.55 + (k / 13) * 2.0, r = 4.75 + (rnd(k + 900) - 0.5) * 0.12, h = 2.7 + rnd(k + 910) * 0.7, x = MX + Math.cos(a) * r, z = MZ + Math.sin(a) * r;
      m.add("Windbreak", at(lathe([[0.02, 0], [0.3, 0], [0.33, 0.2], [0.31, h - 0.12], [0.02, h]], 8), [x, 0, z], [rnd(k + 920) * 6 - 3, face(a), rnd(k + 930) * 6 - 3], [1, 1, 0.5]), k % 3 ? C.oak : C.oakDark);
      m.add("Windbreak", at(lo(0.27, 0.04, 0.14, 8, 3), [x, h - 0.02, z], [0, face(a), 0]), C.oakEnd);
      rails[0].push([MX + Math.cos(a) * (r + 0.24), 0.9, MZ + Math.sin(a) * (r + 0.24)]); rails[1].push([MX + Math.cos(a) * (r + 0.24), 2.1, MZ + Math.sin(a) * (r + 0.24)]);
    }
    for (const p of rails) m.add("Windbreak", tube(p, 0.08, 6, 28), C.oakDark);
    for (const a of [2.8, 3.55, 4.3]) m.add("Windbreak", limb([MX + Math.cos(a) * 6.3, 0, MZ + Math.sin(a) * 6.3], [MX + Math.cos(a) * 5.0, 2.2, MZ + Math.sin(a) * 5.0], 0.1, 0.09, 6), C.oakDark);

    // the cordwood: four rows of oak logs between two stakes
    const SX = 7.2, SZ = -1.4, YAW = 24, cy = Math.cos((YAW * Math.PI) / 180), sy = Math.sin((YAW * Math.PI) / 180);
    m.bone("Cordwood", "Ground", [SX, 0, SZ]);
    for (let row = 0; row < 4; row++) for (let k = 0; k < 6 - (row % 2); k++) {
      const acr = (k - 2.5 + (row % 2) * 0.5) * 0.58 + (rnd(row * 9 + k + 1000) - 0.5) * 0.05, y = 0.3 + row * 0.5, sl = (rnd(row * 9 + k + 1010) - 0.5) * 0.3, rr = 0.27 + rnd(row * 9 + k + 1020) * 0.05;
      const c = [SX + sy * acr + cy * sl, y, SZ + cy * acr - sy * sl];
      m.add("Cordwood", at(lathe([[0.02, -1.7], [rr - 0.02, -1.7], [rr, -1.6], [rr, 1.6], [rr - 0.02, 1.7], [0.02, 1.7]], 8), c, [0, YAW, 90]), (row + k) % 3 ? C.oak : C.oakDark);
      for (const e of [-1, 1]) {
        const p = [c[0] + e * cy * 1.71, y, c[2] - e * sy * 1.71];
        m.add("Cordwood", at(lo(rr * 0.9, rr * 0.9, 0.04, 8, 3), p, [0, YAW + 90, 0]), C.oakEnd);
        m.add("Cordwood", at(lo(rr * 0.45, rr * 0.45, 0.05, 6, 3), p, [0, YAW + 90, 0]), C.oakEndDark);
      }
    }
    for (const e of [-1, 1]) for (const f of [-1, 1]) m.add("Cordwood", limb([SX + sy * e * 1.85 + cy * f * 1.1, 0, SZ + cy * e * 1.85 - sy * f * 1.1], [SX + sy * e * 1.9 + cy * f * 1.1, 2.5, SZ + cy * e * 1.9 - sy * f * 1.1], 0.1, 0.08, 6), C.oakDark);
    // two sacks of last week's charcoal by the stack, a few lumps spilled
    m.add("Cordwood", at(pillow(1.0, 1.3, 0.8, 0.6), [5.3, 0.62, 0.3], [0, 30, 6]), C.sack);
    m.add("Cordwood", at(ball(0.2, 0.16, 0.2, 8), [5.36, 1.34, 0.3]), C.sackDark);
    m.add("Cordwood", at(pillow(1.2, 0.7, 0.8, 0.6), [6.3, 0.34, 1.1], [0, -20, 0]), C.sackDark);
    for (let k = 0; k < 7; k++) m.add("Cordwood", at(lo(0.14, 0.1, 0.12, 5, 3), [6.9 + rnd(k + 1100) * 0.8, 0.1, 1.4 + rnd(k + 1110) * 0.7], [0, rnd(k + 1120) * 360, 0]), C.coal);

    // the three-legged stool
    const TX = 2.4, TZ = 1.2;
    m.bone("Stool", "Ground", [TX, 0, TZ]);
    m.add("Stool", at(lathe([[0.02, 0.94], [0.6, 0.94], [0.66, 1.02], [0.6, 1.1], [0.02, 1.1]], 14), [TX, 0, TZ]), C.oak);
    m.add("Stool", at(lo(0.5, 0.02, 0.5, 10, 3), [TX, 1.1, TZ]), C.oakEnd);
    for (let k = 0; k < 3; k++) { const a = (k / 3) * 6.283 + 0.5; m.add("Stool", limb([TX + Math.cos(a) * 0.34, 0.96, TZ + Math.sin(a) * 0.34], [TX + Math.cos(a) * 0.62, 0, TZ + Math.sin(a) * 0.62], 0.09, 0.07, 6), C.oakDark); }

    // the flat stone the kettle stands on, a few hot coals under it
    m.bone("Hearth", "Ground", [4.0, 0, 2.3]);
    for (let k = 0; k < 6; k++) { const a = (k / 6) * 6.283; m.add("Hearth", at(pillow(0.42, 0.26, 0.34, 0.6), [4.0 + Math.cos(a) * 0.62, 0.12, 2.3 + Math.sin(a) * 0.62], [0, face(a) + 90, rnd(k + 1200) * 10 - 5]), k % 2 ? C.stone : C.stoneDark); }
    m.add("Hearth", at(lo(0.5, 0.06, 0.5, 8, 3), [4.0, 0.05, 2.3]), C.coal);
    m.add("Hearth", at(pillow(0.9, 0.12, 0.8, 0.5), [4.0, 0.3, 2.3], [0, 12, 0]), C.stoneDark);
    m.bone("HearthGlow", "Hearth", [4.0, 0.14, 2.3], "Neon");
    for (let k = 0; k < 6; k++) { const a = (k / 6) * 6.283 + 0.4; m.add("HearthGlow", at(lo(0.1, 0.07, 0.1, 5, 3), [4.0 + Math.cos(a) * 0.28, 0.13, 2.3 + Math.sin(a) * 0.28]), C.ember); }

    // the lantern at his feet: an iron cage, a candle flame inside
    const LX = 1.3, LZ = 2.7;
    m.bone("Lantern", "Ground", [LX, 0, LZ]);
    m.add("Lantern", at(lathe([[0.02, 0], [0.3, 0], [0.32, 0.08], [0.26, 0.14], [0.02, 0.16]], 12), [LX, 0, LZ]), C.iron);
    m.add("Lantern", at(lathe([[0.02, 0.9], [0.3, 0.9], [0.32, 0.96], [0.14, 1.12], [0.08, 1.2], [0.02, 1.22]], 12), [LX, 0, LZ]), C.iron);
    for (let k = 0; k < 4; k++) { const a = (k / 4) * 6.283 + 0.785; m.add("Lantern", limb([LX + Math.cos(a) * 0.26, 0.12, LZ + Math.sin(a) * 0.26], [LX + Math.cos(a) * 0.26, 0.92, LZ + Math.sin(a) * 0.26], 0.03, 0.03, 5), C.ironLight); }
    m.add("Lantern", tube([[LX - 0.22, 1.1, LZ], [LX - 0.2, 1.42, LZ], [LX, 1.54, LZ], [LX + 0.2, 1.42, LZ], [LX + 0.22, 1.1, LZ]], 0.025, 5, 14), C.ironLight);
    m.add("Lantern", at(lathe([[0.02, 0.14], [0.1, 0.14], [0.1, 0.34], [0.02, 0.36]], 8), [LX, 0, LZ]), C.cream); // the candle
    m.bone("Flame", "Lantern", [LX, 0.36, LZ], "Neon");
    { const pts = []; for (let k = 0; k <= 6; k++) { const u = k / 6; pts.push([Math.sin(u * 3) * 0.02, u * 0.42, 0]); } m.add("Flame", at(tube(pts, (u) => 0.13 * Math.sin(Math.PI * Math.pow(Math.min(u + 0.04, 1), 0.42)) * (1 - 0.3 * u) + 0.008, 10, 14), [LX, 0.36, LZ]), C.emberHot); }
    out.push(m);
  }

  // ---------- AshcoalWorld: the ground itself, two painted height fields ----------
  {
    const m = model("AshcoalWorld");
    const nr = terrain.near, fr = terrain.far, n = nr.h.length - 1;
    m.bone("Floor", null, [0, 0, 0], "SmoothPlastic", "tex/ashcoal_floor.png");
    m.addTex("Floor", field(nr.rect[0], nr.rect[1], nr.rect[2], nr.rect[3], nr.h));
    const cw = (fr.rect[2] - fr.rect[0]) / n, cd = (fr.rect[3] - fr.rect[1]) / n;
    const under = (i, j) => { const x0 = fr.rect[0] + i * cw, z0 = fr.rect[1] + j * cd; return x0 > nr.rect[0] + 3 && x0 + cw < nr.rect[2] - 3 && z0 > nr.rect[1] + 3 && z0 + cd < nr.rect[3] - 3; };
    m.bone("Valley", null, [0, 0, 0], "SmoothPlastic", "tex/ashcoal_valley.png");
    m.addTex("Valley", field(fr.rect[0], fr.rect[1], fr.rect[2], fr.rect[3], fr.h, under));
    out.push(m);
  }

  // ---------- SootPuff: a soot sprite, round and fuzzy, with ember eyes ----------
  {
    const m = model("SootPuff");
    m.bone("Body", null, [0, 0.4, 0]);
    m.add("Body", at(ball(0.4, 0.38, 0.4, 12), [0, 0.42, 0]), C.coal);
    for (let k = 0; k < 16; k++) { const a = rnd(k + 1300) * 6.283, e = (rnd(k + 1310) - 0.3) * 1.4, r = Math.cos(e) * 0.36; m.add("Body", limb([Math.cos(a) * r, 0.42 + Math.sin(e) * 0.34, Math.sin(a) * r], [Math.cos(a) * r * 1.5, 0.42 + Math.sin(e) * 0.52, Math.sin(a) * r * 1.5], 0.09, 0.03, 5), k % 3 ? C.coal : C.coalLight); } // fuzz
    for (const s of [-1, 1]) m.add("Body", at(ball(0.11, 0.06, 0.14, 6), [0.16 * s, 0.05, 0.08]), C.coal); // two tiny feet
    m.bone("Eyes", "Body", [0, 0.48, 0.36], "Neon");
    for (const s of [-1, 1]) m.add("Eyes", at(ball(0.075, 0.095, 0.05, 8), [0.15 * s, 0.48, 0.36], [0, 14 * s, 0]), C.ember);
    out.push(m);
  }

  // ---------- what he holds ----------
  {
    const m = model("AshKettle"); // stands on its base at the origin; the handle's top is at y 1.26, the spout points to +X
    m.bone("Kettle", null, [0, 0, 0]);
    m.add("Kettle", lathe([[0.02, 0.02], [0.42, 0.03], [0.54, 0.26], [0.52, 0.56], [0.36, 0.8], [0.02, 0.84]], 14), C.iron);
    m.add("Kettle", lathe([[0.02, 0.82], [0.24, 0.82], [0.2, 0.9], [0.02, 0.92]], 12), C.ironLight);
    m.add("Kettle", at(ball(0.07, 0.07, 0.07, 8), [0, 0.97, 0]), C.brass);
    m.add("Kettle", tube([[0.44, 0.4, 0], [0.7, 0.52, 0], [0.82, 0.8, 0], [0.9, 0.86, 0]], (u) => 0.1 - 0.045 * u, 8, 10), C.iron);
    m.add("Kettle", tube([[-0.34, 0.78, 0], [-0.4, 1.1, 0], [0, 1.26, 0], [0.4, 1.1, 0], [0.34, 0.78, 0]], 0.035, 6, 16), C.ironLight);
    m.add("Kettle", at(lo(0.3, 0.2, 0.06, 6, 3), [0, 0.3, 0.5]), C.soot);
    out.push(m);
  }
  {
    const m = model("AshCup"); // a dented tin mug, base at the origin, the handle to -X
    m.bone("Cup", null, [0, 0, 0]);
    m.add("Cup", lathe([[0.02, 0], [0.17, 0], [0.19, 0.04], [0.2, 0.36], [0.17, 0.36], [0.16, 0.08], [0.02, 0.07]], 12), C.tin);
    m.add("Cup", at(lo(0.165, 0.02, 0.165, 10, 3), [0, 0.3, 0]), C.tea);
    m.add("Cup", tube([[-0.19, 0.3, 0], [-0.32, 0.28, 0], [-0.33, 0.12, 0], [-0.19, 0.08, 0]], 0.028, 5, 10), C.tinDark);
    out.push(m);
  }
  {
    const m = model("AshPoker"); // a long iron poker with a hooked end: held at the origin, the hook 3.3 studs up the +Y axis
    m.bone("Poker", null, [0, 0, 0]);
    m.add("Poker", limb([0, -0.5, 0], [0, 3.2, 0], 0.045, 0.04, 6), C.iron);
    m.add("Poker", tube([[0, 3.15, 0], [0, 3.4, 0.02], [0.02, 3.5, 0.2], [0, 3.36, 0.34]], 0.04, 6, 10), C.iron);
    m.add("Poker", tube(ring(0.1, 0.1, 0, 0, 10).map((p) => [p[0], -0.62 + p[2], 0]), 0.03, 5, 20), C.ironLight); // the ring of its handle
    m.add("Poker", limb([0, -0.3, 0], [0, 0.3, 0], 0.06, 0.06, 6), C.patch1); // a leather grip
    out.push(m);
  }
  {
    const m = model("AshLog"); // one length of oak cordwood, lying along X, its middle at the origin
    m.bone("Log", null, [0, 0, 0]);
    m.add("Log", at(lathe([[0.02, -1.2], [0.24, -1.2], [0.26, -1.1], [0.26, 1.1], [0.24, 1.2], [0.02, 1.2]], 8), [0, 0, 0], [0, 0, 90]), C.oak);
    for (const e of [-1, 1]) { m.add("Log", at(lo(0.23, 0.23, 0.04, 8, 3), [e * 1.2, 0, 0], [0, 90, 0]), C.oakEnd); m.add("Log", at(lo(0.11, 0.11, 0.05, 6, 3), [e * 1.2, 0, 0], [0, 90, 0]), C.oakEndDark); }
    out.push(m);
  }
  return out;
}
