// Kiln Pickaxe biography: "wet clay dug from the terrace, thrown on the wheel, glazed and fired once; she taps it and it rings".
// Setting from refs/forge/sheets/kiln_setting_s11.png (a potter's yard cut into a clay cliff, a brick bottle kiln, a kick wheel
// under a reed awning, shelves of drying pots, terraced clay pits and a red river below); the maker from
// refs/forge/sheets/molepotter_views_s11.png (a mole in a clay-smeared apron and a blue head scarf, paws grey with slip).
// Models: PotterKit (BoltKit's bone names, plus Scarf and Apron), KilnYard (everything that stands in the yard, in the
// authoring positions kiln_world.py keeps clear), KickWheel, ClayHead (the clay in its stages), Teapot, GlazeJug, TrimTool,
// ClayCurl, Swallow, KilnWorld (painted height fields from kiln_world.py). Front of every model is +Z. Units are studs.
import terrain from "./tex/kiln_terrain.mjs";
export const name = "kiln";

const C = {
  fur: "#7a6a62", furDark: "#5e5049", furLight: "#94847a", snout: "#f2b4b0", nose: "#e88f93", paw: "#f0b9ae", claw: "#f6ead8", slip: "#b9b3aa", eye: "#17121a", white: "#ffffff",
  apron: "#f0dc9a", apronShade: "#d9c07a", cuff: "#efe9dc", scarf: "#4580bd", scarfDark: "#346aa3",
  brick: "#b4502f", brickDark: "#93402a", brickLight: "#c9683e", mortar: "#caa58a", soot: "#3a2c2a", glow: "#ffc04a", red: "#e8502a", iron: "#5a5560",
  wood: "#9a7350", woodDark: "#74553a", woodLight: "#b98f66", reed: "#d9c27a", reedDark: "#b89e58", rope: "#b8a078",
  pot: "#f0d9b5", potShade: "#dcc09a", potWarm: "#e6c9a0", fired: "#c9683e", firedDark: "#b5532f",
  clayWet: "#b5694a", clayWetDark: "#96533a", clayMid: "#c27a56", head: "#d6cab8", stone: "#8a8c96", stoneDark: "#6a6c78",
  glaze: "#4a6fa5", glazeLight: "#7fa3d4", crackle: "#eef4fc", cloth: "#f4efe6", navy: "#27304a", rust: "#c9683e",
};

// where things stand in the yard (authoring space; kiln_world.py keeps this ground level and clear, ForgeKiln.luau uses the same numbers with x and z flipped)
const K = [-9, 0, -7];       // the kiln's middle; its fire door faces +Z
const AW = [1.5, 0, -0.8];   // the awning's middle; the wheel stands at (1.5, 0, 0)
const SH = [11.5, 0, -9.5];  // the drying shelves
const FW = [-14.5, 0, -3];   // the firewood stack
const BLOCK = [-5.2, 0, 0.6]; // the chopping block she sits on while the kiln burns
const P1 = [10, 0, -3], P2 = [19, 0, -7]; // the washing line's poles

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, field, model } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 6, hs = 4) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const prof = (P) => (y) => { // radius of a lathe profile at height y
    for (let i = 1; i < P.length; i++) if (y <= P[i][1]) { const a = P[i - 1], b = P[i], u = (y - a[1]) / Math.max(b[1] - a[1], 1e-6); return a[0] + (b[0] - a[0]) * Math.min(Math.max(u, 0), 1); }
    return P[P.length - 1][0];
  };
  const ring = (cx, y, cz, r, n = 16) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([cx + Math.sin(a) * r, y, cz + Math.cos(a) * r]); } return p; };

  // ---------- PotterKit: the mole potter ----------
  {
    const m = model("PotterKit");
    m.bone("Hips", null, [0, 0.95, 0]);
    m.add("Hips", at(lo(0.08, 0.08, 0.08), [0, 0.95, 0]), C.fur); // a bead inside the body, so Hips is a real bone and comes first in the rig's order
    m.bone("Body", "Hips", [0, 0.95, 0]);
    m.add("Body", lathe([[0.02, 0.62], [0.56, 0.68], [0.84, 0.98], [0.86, 1.32], [0.7, 1.7], [0.52, 1.96], [0.02, 2.06]], 22), C.fur);
    m.add("Body", at(ball(0.5, 0.5, 0.3, 14), [0, 1.2, -0.6]), C.furDark); // a darker saddle down her back
    // the apron: bib, skirt, neck strap, waist tie with a bow behind, a pocket, and the clay she has wiped on it
    m.bone("Apron", "Body", [0, 1.95, 0.4]);
    m.add("Apron", at(ball(0.48, 0.34, 0.2, 14), [0, 1.72, 0.52]), C.apron);
    m.add("Apron", at(ball(0.8, 0.64, 0.38, 18), [0, 1.1, 0.58]), C.apron);
    for (const s of [-1, 1]) m.add("Apron", tube([[0.3 * s, 1.92, 0.46], [0.5 * s, 2.02, 0.05], [0.2 * s, 1.8, -0.63], [-0.45 * s, 1.4, -0.76]], 0.055, 6, 16), C.apron);
    m.add("Apron", at(ball(0.3, 0.1, 0.2, 10), [0, 2.0, 0.34]), C.cuff);
    m.add("Apron", tube(ring(0, 1.36, 0, 0.87, 18), 0.05, 6, 36), C.apronShade);
    for (const s of [-1, 1]) m.add("Apron", at(ball(0.2, 0.12, 0.06, 8), [0.2 * s, 1.38, -0.9], [0, 0, 24 * s]), C.apronShade);
    m.add("Apron", at(lo(0.07, 0.07, 0.06), [0, 1.36, -0.9]), C.apron);
    m.add("Apron", at(pillow(0.52, 0.3, 0.08, 0.4, 6), [-0.12, 0.92, 0.93], [8, 0, 0]), C.apronShade);
    for (const [x, y, z, rx, ry, c] of [[0.3, 1.24, 0.9, 0.17, 0.1, C.clayWet], [-0.36, 1.34, 0.86, 0.12, 0.16, C.clayMid], [0.12, 0.84, 0.93, 0.2, 0.08, C.clayWet], [0.42, 0.98, 0.84, 0.09, 0.12, C.slip], [-0.08, 1.7, 0.71, 0.13, 0.07, C.clayMid], [-0.3, 1.02, 0.9, 0.08, 0.08, C.slip]]) m.add("Apron", at(lo(rx, ry, 0.035, 8, 4), [x, y, z]), c);

    m.bone("Head", "Body", [0, 2.02, 0]);
    m.add("Head", at(ball(0.95, 0.82, 0.88, 24), [0, 2.72, 0.02]), C.fur);
    m.add("Head", at(ball(0.5, 0.4, 0.42, 16), [0, 2.5, 0.6]), C.furLight);
    m.add("Head", limb([0, 2.5, 0.8], [0, 2.47, 1.3], 0.28, 0.15, 12), C.snout); // the pink snout
    m.add("Head", at(ball(0.15, 0.13, 0.12, 10), [0, 2.48, 1.42]), C.nose);
    m.add("Head", at(lo(0.04, 0.025, 0.03), [-0.05, 2.55, 1.5]), C.white);
    m.add("Head", tube([[-0.2, 2.27, 0.86], [0, 2.2, 0.93], [0.2, 2.27, 0.86]], 0.022, 6, 8), C.furDark);
    for (const s of [-1, 1]) {
      for (const dy of [0.07, 0, -0.07]) m.add("Head", limb([0.22 * s, 2.46 + dy, 1.06], [0.8 * s, 2.46 + dy * 3.2, 0.96], 0.013, 0.004, 4), C.white);
      m.add("Head", at(ball(0.11, 0.08, 0.04, 8), [0.6 * s, 2.46, 0.68], [0, 30 * s, 0]), C.snout);
    }
    m.bone("Eyes", "Head", [0, 2.86, 0.82]);
    for (const s of [-1, 1]) {
      m.add("Eyes", at(ball(0.13, 0.15, 0.06), [0.4 * s, 2.84, 0.8], [0, 16 * s, 0]), C.eye);
      m.add("Eyes", at(lo(0.045, 0.05, 0.025), [0.4 * s + 0.035, 2.9, 0.855]), C.white);
    }
    m.bone("EyesShut", "Head", [0, 2.86, 0.84]);
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.26 * s, 2.8, 0.82], [0.4 * s, 2.9, 0.88], [0.54 * s, 2.8, 0.8]], 0.032, 6, 10), C.furDark);
    m.bone("EarL", "Head", [0.74, 3.12, 0]);
    m.add("EarL", at(ball(0.3, 0.32, 0.12), [0.86, 3.24, -0.02], [0, 14, -24]), C.fur);
    m.add("EarL", at(ball(0.22, 0.24, 0.08), [0.87, 3.24, 0.05], [0, 14, -24]), C.snout);
    m.mirror("EarL", "EarR");
    // the head scarf: a blue cap with cream dots, pushed back off her brow, knotted behind with two tails
    m.bone("Scarf", "Head", [0, 3.1, 0]);
    {
      const cap = new THREE.SphereGeometry(1, 22, 9, 0, Math.PI * 2, 0, Math.PI * 0.5); cap.scale(1.0, 0.76, 0.95); cap.computeVertexNormals();
      m.add("Scarf", at(cap, [0, 2.84, -0.06], [-34, 0, 0]), C.scarf);
      m.add("Scarf", at(tube(ring(0, 0, 0, 1.0, 20).map(([x, y, z]) => [x, y, z * 0.95]), 0.06, 6, 40), [0, 2.84, -0.06], [-34, 0, 0]), C.scarfDark);
      m.add("Scarf", at(ball(0.2, 0.16, 0.16, 10), [0.1, 2.5, -0.98]), C.scarfDark);
      for (const s of [-1, 1]) m.add("Scarf", at(puff([[-0.1, 0], [0.1, 0], [0.16, -0.5], [0, -0.42], [-0.16, -0.5]], 0.04, 0.03), [0.1 + 0.14 * s, 2.46, -1.04], [-24, 0, 20 * s], 1.5), C.scarf);
    }

    m.bone("ArmL", "Body", [0.62, 1.8, 0.05]);
    m.add("ArmL", limb([0.62, 1.8, 0.05], [0.96, 1.42, 0.14], 0.2, 0.17), C.fur);
    m.add("ArmL", limb([0.64, 1.78, 0.05], [0.84, 1.56, 0.1], 0.24, 0.23, 10), C.furDark); // the sleeve, rolled above the elbow
    m.add("ArmL", at(ball(0.27, 0.1, 0.27, 10), [0.87, 1.53, 0.11], [0, 0, 42]), C.cuff);
    m.bone("ForeL", "ArmL", [0.96, 1.42, 0.14]);
    m.add("ForeL", limb([0.96, 1.42, 0.14], [1.04, 1.06, 0.3], 0.17, 0.17), C.fur);
    m.add("ForeL", at(ball(0.25, 0.19, 0.28), [1.05, 0.97, 0.36]), C.paw); // big pink digging paws
    m.add("ForeL", at(ball(0.21, 0.1, 0.24, 10), [1.05, 0.89, 0.4]), C.slip); // grey with slip underneath
    for (const dx of [-0.15, -0.05, 0.05, 0.15]) m.add("ForeL", at(lo(0.045, 0.045, 0.12), [1.05 + dx, 0.92, 0.62 - Math.abs(dx) * 0.4]), C.claw);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");

    m.bone("LegL", "Hips", [0.34, 0.95, 0]);
    m.add("LegL", limb([0.34, 0.95, 0], [0.38, 0.34, 0.04], 0.26, 0.2), C.fur);
    m.add("LegL", at(ball(0.28, 0.12, 0.4), [0.4, 0.14, 0.24]), C.paw);
    for (const dx of [-0.14, 0, 0.14]) m.add("LegL", at(lo(0.04, 0.04, 0.09), [0.4 + dx, 0.14, 0.62 - Math.abs(dx) * 0.4]), C.claw);
    m.mirror("LegL", "LegR");

    m.bone("Tail1", "Hips", [0, 0.9, -0.6]);
    m.add("Tail1", limb([0, 0.9, -0.6], [0, 0.62, -1.4], 0.11, 0.08, 8), C.furDark);
    m.bone("Tail2", "Tail1", [0, 0.62, -1.4]);
    m.add("Tail2", tube([[0, 0.62, -1.4], [0.06, 0.6, -1.8], [0.02, 0.78, -2.15], [-0.06, 1.0, -2.3]], (u) => 0.08 - 0.05 * u, 6, 12), C.furDark);
    out.push(m);
  }

  // ---------- KilnYard: everything that stands in the yard ----------
  {
    const m = model("KilnYard");
    // the bottle kiln: brick courses in three tones over a mortar core, two iron bands, the arched fire door, a ledge for the teapot
    const KP = [[4.3, 0], [4.3, 0.5], [4.1, 0.62], [4.1, 4.2], [3.9, 5.4], [3.3, 6.8], [2.5, 8.0], [1.9, 8.9], [1.7, 9.4]], kr = prof(KP);
    const zf = K[2] + 4.1;
    m.bone("Kiln", null, [K[0], 0, K[2]]);
    m.add("Kiln", at(lathe(KP.map(([r, y]) => [r - 0.05, y]), 28), K), C.mortar);
    m.add("Kiln", at(lathe([[4.34, 0], [4.34, 0.5], [4.12, 0.62]], 28), K), C.brickDark);
    for (let i = 0, y = 0.64; y < 9.38; i++, y += 0.56) {
      const y1 = Math.min(y + 0.5, 9.4);
      m.add("Kiln", at(lathe([[kr(y), y], [kr((y + y1) / 2) + 0.03, (y + y1) / 2], [kr(y1), y1]], 28), K), [C.brick, C.brickLight, C.brick, C.brickDark][i % 4]);
    }
    for (const y of [3.0, 5.6]) m.add("Kiln", at(lathe([[kr(y) + 0.03, y - 0.12], [kr(y) + 0.1, y], [kr(y) + 0.03, y + 0.12]], 28), K), C.iron);
    m.add("Kiln", tube([[-1.38, 0.05], [-1.38, 1.7], [-1.02, 2.5], [0, 2.98], [1.02, 2.5], [1.38, 1.7], [1.38, 0.05]].map(([x, y]) => [K[0] + x, y, zf + 0.06]), 0.3, 8, 28), C.brickDark);
    const arch = [[-1.1, 0.05], [1.1, 0.05], [1.1, 1.7], [0.85, 2.35], [0, 2.72], [-0.85, 2.35], [-1.1, 1.7]];
    m.add("Kiln", at(puff(arch, 0.06, 0.02, false), [K[0], 0, zf + 0.03]), C.soot); // the dark mouth behind the glow
    m.add("Kiln", at(pillow(1.6, 0.3, 1.4, 0.3, 6), [K[0] + 3.3, 2.15, K[2] + 3.0]), C.brickDark); // the ledge the teapot stands on
    m.add("Kiln", at(lo(0.5, 0.5, 0.5), [K[0] + 3.1, 1.75, K[2] + 2.8]), C.brick);
    m.add("Kiln", tube(ring(0, 0, 0, 0.28, 12).map(([x, , z]) => [K[0] + x, 4.3 + z, K[2] + kr(4.3) + 0.03]), 0.06, 5, 24), C.iron); // the peephole's iron ring
    for (const [dx, dz, a] of [[-2.9, 5.0, 20], [-2.5, 5.3, -30], [-3.1, 5.5, 70]]) m.add("Kiln", limb([K[0] + dx - 0.5 * Math.cos(a), 0.1, K[2] + dz - 0.5 * Math.sin(a)], [K[0] + dx + 0.5 * Math.cos(a), 0.12, K[2] + dz + 0.5 * Math.sin(a)], 0.09, 0.08, 6), C.wood);
    m.bone("Door", "Kiln", [K[0], 1.4, zf], "Neon");
    m.add("Door", at(puff(arch.map(([x, y]) => [x * 0.93, 0.08 + y * 0.95]), 0.05, 0.02, false), [K[0], 0, zf + 0.11]), C.glow);
    m.bone("Peephole", "Kiln", [K[0], 4.3, K[2] + kr(4.3)], "Neon");
    m.add("Peephole", at(ball(0.2, 0.2, 0.07, 10), [K[0], 4.3, K[2] + kr(4.3) + 0.04]), C.red);
    m.bone("Chimney", "Kiln", [K[0], 9.4, K[2]]);
    const cr = (y) => 1.7 - ((y - 9.4) / 3.8) * 0.3;
    m.add("Chimney", at(lathe([[1.66, 9.4], [1.36, 13.2]], 20), K), C.mortar);
    for (let i = 0, y = 9.42; y < 13.18; i++, y += 0.56) {
      const y1 = Math.min(y + 0.5, 13.2);
      m.add("Chimney", at(lathe([[cr(y), y], [cr((y + y1) / 2) + 0.03, (y + y1) / 2], [cr(y1), y1]], 20), K), [C.brickLight, C.brick, C.brickDark, C.brick][i % 4]);
    }
    m.add("Chimney", at(lathe([[1.4, 13.2], [1.62, 13.3], [1.62, 13.8], [1.3, 13.9], [1.16, 13.86]], 20), K), C.brickDark);
    m.add("Chimney", at(ball(1.2, 0.1, 1.2, 12), [K[0], 13.72, K[2]]), C.soot);

    // the awning over the wheel: four posts, a sloping reed roof (higher toward the camera), a fringe, the slip bucket and a water jar
    m.bone("Awning", null, [AW[0], 0, AW[2]]);
    const roofY = (zl) => 6.1 + zl * 0.137; // top of the reed roof at local z
    for (const sx of [-3.9, 3.9]) for (const sz of [-3.1, 3.1]) m.add("Awning", limb([AW[0] + sx, 0, AW[2] + sz], [AW[0] + sx, roofY(sz) - 0.25, AW[2] + sz], 0.17, 0.15, 8), C.wood);
    for (const sz of [-3.1, 3.1]) m.add("Awning", limb([AW[0] - 4.2, roofY(sz) - 0.3, AW[2] + sz], [AW[0] + 4.2, roofY(sz) - 0.3, AW[2] + sz], 0.13, 0.13, 6), C.woodDark);
    for (const sx of [-3.9, 0, 3.9]) m.add("Awning", limb([AW[0] + sx, roofY(-3.5) - 0.28, AW[2] - 3.5], [AW[0] + sx, roofY(3.5) - 0.28, AW[2] + 3.5], 0.1, 0.1, 6), C.woodDark);
    m.add("Awning", at(pillow(8.8, 0.3, 7.4, 0.3, 10), [AW[0], 5.95, AW[2]], [-7.8, 0, 0]), C.reed);
    for (let i = 0; i < 16; i++) { const x = AW[0] - 4.2 + i * 0.56; m.add("Awning", limb([x, roofY(3.7) + 0.02, AW[2] + 3.7], [x, roofY(-3.7) + 0.02, AW[2] - 3.7], 0.1, 0.1, 6), i % 2 ? C.reedDark : C.reed); }
    for (let i = 0; i < 22; i++) { const x = AW[0] - 4.3 + i * 0.41; m.add("Awning", limb([x, roofY(3.7) - 0.05, AW[2] + 3.72], [x + 0.04 * Math.sin(i * 2.1), roofY(3.7) - 0.45 - 0.14 * Math.abs(Math.sin(i * 1.7)), AW[2] + 3.78], 0.05, 0.02, 4), C.reedDark); }
    m.add("Awning", at(lathe([[0.02, 0], [0.42, 0.02], [0.5, 0.8], [0.46, 0.82]], 14), [AW[0] + 2.5, 0, AW[2] - 1.2]), C.wood);
    for (const y of [0.2, 0.62]) m.add("Awning", at(lathe([[0.45 + y * 0.1, y - 0.04], [0.48 + y * 0.1, y], [0.45 + y * 0.1, y + 0.04]], 14), [AW[0] + 2.5, 0, AW[2] - 1.2]), C.iron);
    m.add("Awning", at(ball(0.45, 0.04, 0.45, 12), [AW[0] + 2.5, 0.74, AW[2] - 1.2]), C.slip);
    m.add("Awning", at(lathe([[0.02, 0], [0.34, 0.02], [0.56, 0.5], [0.5, 0.98], [0.3, 1.22], [0.34, 1.34]], 14), [AW[0] - 2.7, 0, AW[2] - 1.9]), C.fired);
    m.add("Awning", at(lathe([[0.555, 0.4], [0.575, 0.5], [0.545, 0.62]], 14), [AW[0] - 2.7, 0, AW[2] - 1.9]), C.glaze);

    // the drying shelves and their pots: pale unfired ware, a few fired ones
    m.bone("Shelves", null, [SH[0], 0, SH[2]]);
    for (const sx of [-4, 4]) for (const sz of [-0.6, 0.6]) m.add("Shelves", limb([SH[0] + sx, 0, SH[2] + sz], [SH[0] + sx, 4.5, SH[2] + sz], 0.12, 0.11, 6), C.wood);
    for (const y of [1.2, 2.5, 3.8]) m.add("Shelves", at(pillow(8.5, 0.16, 1.5, 0.3, 6), [SH[0], y, SH[2]]), C.woodLight);
    m.bone("Pots", "Shelves", [SH[0], 1.2, SH[2]]);
    const PP = [
      [[0.02, 0], [0.28, 0.02], [0.42, 0.3], [0.4, 0.55], [0.24, 0.8], [0.2, 0.95], [0.27, 1.02]],
      [[0.02, 0], [0.22, 0.02], [0.46, 0.3], [0.5, 0.42], [0.47, 0.44]],
      [[0.02, 0], [0.3, 0.02], [0.36, 0.4], [0.3, 0.7], [0.2, 0.85], [0.24, 0.95]],
      [[0.02, 0], [0.2, 0.02], [0.24, 0.36], [0.22, 0.38]],
    ];
    let pi = 0;
    for (const y of [1.2, 2.5, 3.8]) for (let i = 0; i < 6; i++, pi++) {
      const s = 0.78 + 0.26 * T.rnd(pi + 3), p = PP[(pi * 3 + i) % 4].map(([r, h]) => [r * s, h * s]);
      const col = pi % 7 === 3 ? C.fired : pi % 5 === 4 ? C.firedDark : [C.pot, C.potShade, C.potWarm][pi % 3];
      m.add("Pots", at(lathe(p, 12), [SH[0] - 3.4 + i * 1.36 + 0.2 * (T.rnd(pi) - 0.5), y + 0.08, SH[2] + 0.2 * (T.rnd(pi + 9) - 0.5)]), col);
    }

    // firewood for the long burn, and the chopping block she waits on
    m.bone("Firewood", null, [FW[0], 0, FW[2]]);
    for (let L = 0, k = 0; L < 3; L++) for (let j = 0; j < 4 - L; j++, k++) {
      const z = FW[2] + (j - (3 - L) / 2) * 0.66, y = 0.33 + L * 0.57;
      m.add("Firewood", limb([FW[0] - 1.4, y, z], [FW[0] + 1.4, y, z], 0.31, 0.3, 8), k % 2 ? C.wood : C.woodDark);
      m.add("Firewood", at(lo(0.04, 0.22, 0.22, 8, 4), [FW[0] + 1.7, y, z]), C.woodLight);
    }
    m.add("Firewood", at(lathe([[0.02, 0], [0.62, 0.02], [0.66, 0.12], [0.63, 0.62], [0.56, 0.69], [0.02, 0.7]], 14), BLOCK), C.wood);
    m.add("Firewood", at(ball(0.5, 0.02, 0.5, 12), [BLOCK[0], 0.7, BLOCK[2]]), C.woodLight);

    // the washing line: her spare apron, a scarf and a towel
    m.bone("Line", null, [14.5, 0, -5]);
    for (const P of [P1, P2]) m.add("Line", limb([P[0], 0, P[2]], [P[0], 5.3, P[2]], 0.13, 0.1, 8), C.wood);
    m.add("Line", tube([[P1[0], 5.2, P1[2]], [14.5, 4.75, -5], [P2[0], 5.2, P2[2]]], 0.04, 5, 14), C.rope);
    m.bone("Washing", "Line", [14.5, 4.8, -5]);
    for (const [f, w, hh, col] of [[0.24, 1.5, 1.9, C.apron], [0.5, 1.3, 1.3, C.scarf], [0.76, 1.2, 1.7, C.fired]]) {
      const px = P1[0] + f * (P2[0] - P1[0]), pz = P1[2] + f * (P2[2] - P1[2]), py = 5.2 - 0.45 * 4 * f * (1 - f);
      m.add("Washing", at(puff([[-w / 2, 0], [w / 2, 0], [w * 0.48, -hh], [0, -hh * 1.03], [-w * 0.48, -hh]], 0.03, 0.02, false), [px, py, pz], [0, 24, 0]), col);
      for (const s of [-1, 1]) m.add("Washing", at(lo(0.05, 0.09, 0.05), [px + s * w * 0.4 * 0.914, py + 0.02, pz - s * w * 0.4 * 0.406]), C.woodLight);
    }
    out.push(m);
  }

  // ---------- KickWheel: frame and bench stand still, the wheel head, shaft and stone flywheel turn ----------
  {
    const m = model("KickWheel");
    m.bone("Frame", null, [0, 0, 0]);
    for (const s of [-1, 1]) m.add("Frame", at(pillow(0.3, 0.25, 2.9, 0.3, 6), [0.98 * s, 0.13, -0.35]), C.wood);
    m.add("Frame", at(pillow(2.2, 0.2, 0.3, 0.3, 6), [0, 0.11, 0]), C.woodDark);
    m.add("Frame", at(pillow(1.5, 0.18, 0.75, 0.35, 8), [0, 0.7, -1.25]), C.woodLight);
    for (const sx of [-0.6, 0.6]) for (const sz of [-0.25, 0.25]) m.add("Frame", limb([sx, 0, -1.25 + sz], [sx, 0.62, -1.25 + sz], 0.09, 0.08, 6), C.wood);
    m.add("Frame", lathe([[0.95, 1.0], [1.2, 1.0], [1.26, 1.22], [1.19, 1.24], [1.14, 1.08], [0.95, 1.06]], 20), C.woodDark); // the splash tray round the head
    for (const a of [0.6, 2.6, 4.4]) m.add("Frame", limb([Math.sin(a) * 1.05, 0.2, Math.cos(a) * 1.05], [Math.sin(a) * 1.05, 1.02, Math.cos(a) * 1.05], 0.07, 0.07, 6), C.wood);
    m.bone("Wheel", null, [0, 0, 0]);
    m.add("Wheel", limb([0, 0.2, 0], [0, 1.22, 0], 0.09, 0.09, 8), C.iron);
    m.add("Wheel", lathe([[0.02, 1.2], [0.78, 1.2], [0.82, 1.27], [0.78, 1.34], [0.02, 1.35]], 24), C.head);
    m.add("Wheel", at(lo(0.09, 0.02, 0.09), [0.6, 1.352, 0]), C.clayWet); // off-centre marks, so the turning reads
    { const sp = []; for (let k = 0; k <= 14; k++) { const a = (k / 14) * Math.PI * 2.2; sp.push([Math.sin(a) * (0.2 + 0.035 * k), 1.352, Math.cos(a) * (0.2 + 0.035 * k)]); } m.add("Wheel", tube(sp, 0.028, 4, 28), C.clayWet); }
    m.add("Wheel", lathe([[0.02, 0.2], [1.02, 0.2], [1.1, 0.32], [1.02, 0.44], [0.02, 0.45]], 24), C.stone);
    for (let k = 0; k < 4; k++) { const a = (k / 4) * Math.PI * 2 + 0.3; m.add("Wheel", at(ball(0.34, 0.02, 0.1, 8), [Math.sin(a) * 0.6, 0.455, Math.cos(a) * 0.6], [0, (a * 180) / Math.PI + 90, 0]), C.stoneDark); }
    out.push(m);
  }

  // ---------- ClayHead: the clay in its stages (the scene shows one at a time; base at y = 0, on the wheel head) ----------
  {
    const m = model("ClayHead");
    m.bone("Lump", null, [0, 0, 0]);
    m.add("Lump", at(ball(0.5, 0.34, 0.48, 14), [0, 0.3, 0]), C.clayWet);
    for (const [x, y, z, r] of [[0.3, 0.42, 0.14, 0.2], [-0.26, 0.36, -0.2, 0.22], [0.02, 0.5, -0.1, 0.24], [-0.14, 0.2, 0.32, 0.18]]) m.add("Lump", at(lo(r, r * 0.8, r, 8, 5), [x, y, z]), C.clayWetDark);
    m.bone("Mid", null, [0, 0, 0]);
    const MP = [[0.5, 0], [0.56, 0.12], [0.5, 0.5], [0.42, 0.9], [0.4, 1.0], [0.3, 1.02], [0.02, 1.0]], mr = prof(MP);
    m.add("Mid", lathe(MP, 20), C.clayWet);
    { const sp = []; for (let k = 0; k <= 40; k++) { const y = 0.08 + (k / 40) * 0.86, a = (k / 40) * Math.PI * 2 * 4; sp.push([Math.sin(a) * (mr(y) + 0.005), y, Math.cos(a) * (mr(y) + 0.005)]); } m.add("Mid", tube(sp, 0.022, 4, 80), C.clayMid); } // her fingers' spiral
    m.bone("Shaped", null, [0, 0, 0]);
    // a pick head stood on end, as a wheel would make it: a foot, a waist, the eye's swelling, and a long taper to the point
    const SP = [[0.34, 0], [0.42, 0.06], [0.3, 0.2], [0.26, 0.42], [0.36, 0.56], [0.4, 0.66], [0.36, 0.76], [0.24, 0.92], [0.13, 1.12], [0.04, 1.28], [0.01, 1.34]], sr = prof(SP);
    m.add("Shaped", lathe(SP, 20), C.clayMid);
    m.add("Shaped", lathe([[0.405, 0.6], [0.42, 0.66], [0.405, 0.72]], 20), C.clayWetDark);
    m.bone("Glaze", null, [0, 0, 0]);
    m.add("Glaze", lathe(SP.filter(([, y]) => y >= 0.2).map(([r, y]) => [r * 1.035 + 0.008, y]), 20), C.glaze);
    m.add("Glaze", lathe(SP.filter(([, y]) => y >= 0.92).map(([r, y]) => [r * 1.06 + 0.014, y + 0.004]), 20), C.glazeLight);
    for (let k = 0; k < 8; k++) { const a = (k / 8) * Math.PI * 2 + 0.2, r = sr(0.2) * 1.04 + 0.01; m.add("Glaze", at(lo(0.05, 0.07 + 0.03 * (k % 3), 0.05), [Math.sin(a) * r, 0.19 - 0.03 * (k % 3), Math.cos(a) * r]), C.glaze); }
    m.bone("Crackle", null, [0, 0, 0]);
    for (let k = 0; k < 14; k++) { // the crackle: fine pale lines wandering over the glaze
      const pts = []; let a = T.rnd(k) * Math.PI * 2, y = 0.26 + T.rnd(k + 20) * 0.7;
      for (let i = 0; i < 5; i++) { const r = sr(y) * 1.05 + 0.014; pts.push([Math.sin(a) * r, y, Math.cos(a) * r]); a += (T.rnd(k * 7 + i) - 0.5) * 0.9; y = Math.min(1.2, Math.max(0.22, y + (T.rnd(k * 5 + i + 40) - 0.4) * 0.22)); }
      m.add("Crackle", tube(pts, 0.011, 4, 8), C.crackle);
    }
    out.push(m);
  }

  // ---------- small things ----------
  {
    const m = model("Teapot"); // blue enamel with a cream band; the spout points to +X; the lid rattles
    m.bone("Pot", null, [0, 0, 0]);
    m.add("Pot", lathe([[0.02, 0], [0.34, 0.02], [0.5, 0.22], [0.52, 0.4], [0.42, 0.6], [0.28, 0.68], [0.26, 0.7]], 18), C.glaze);
    m.add("Pot", lathe([[0.512, 0.3], [0.532, 0.37], [0.5, 0.45]], 18), C.pot);
    m.add("Pot", tube([[0.44, 0.3, 0], [0.66, 0.42, 0], [0.8, 0.62, 0], [0.86, 0.76, 0]], (u) => 0.085 - 0.04 * u, 8, 10), C.glaze);
    m.add("Pot", tube([[-0.44, 0.56, 0], [-0.74, 0.6, 0], [-0.82, 0.36, 0], [-0.5, 0.2, 0]], 0.05, 6, 12), C.iron);
    m.bone("Lid", "Pot", [0, 0.7, 0]);
    m.add("Lid", lathe([[0.27, 0.69], [0.22, 0.76], [0.08, 0.8], [0.09, 0.86], [0.02, 0.9]], 14), C.glazeLight);
    out.push(m);
  }
  {
    const m = model("GlazeJug"); // the jug of blue glaze: pours over +X
    m.bone("Jug", null, [0, 0, 0]);
    m.add("Jug", lathe([[0.02, 0], [0.3, 0.02], [0.42, 0.3], [0.38, 0.6], [0.24, 0.78], [0.3, 0.9]], 16), C.pot);
    m.add("Jug", at(ball(0.26, 0.03, 0.26, 10), [0, 0.86, 0]), C.glaze);
    m.add("Jug", at(ball(0.1, 0.05, 0.08, 8), [0.34, 0.88, 0]), C.pot);
    for (const [a, l] of [[0.2, 0.2], [1.5, 0.12], [-0.9, 0.16], [0.0, 0.3]]) m.add("Jug", at(lo(0.045, l, 0.03), [Math.cos(a) * 0.31, 0.86 - l * 0.6, Math.sin(a) * 0.31]), C.glaze);
    m.add("Jug", tube([[-0.3, 0.8, 0], [-0.6, 0.7, 0], [-0.6, 0.36, 0], [-0.4, 0.24, 0]], 0.05, 6, 12), C.potShade);
    out.push(m);
  }
  {
    const m = model("TrimTool"); // a loop tool: a wooden grip and a wire loop
    m.bone("Tool", null, [0, 0, 0]);
    m.add("Tool", limb([0, 0, 0], [0, 0.55, 0], 0.05, 0.04, 6), C.wood);
    m.add("Tool", tube([[0, 0.55, 0], [0.1, 0.66, 0], [0, 0.8, 0], [-0.1, 0.66, 0], [0, 0.57, 0]], 0.016, 4, 12), C.iron);
    out.push(m);
  }
  {
    const m = model("ClayCurl"); // a ribbon of clay the loop tool lifts off
    m.bone("Curl", null, [0, 0, 0]);
    const sp = []; for (let k = 0; k <= 12; k++) { const a = (k / 12) * Math.PI * 3.2; sp.push([Math.cos(a) * 0.11, k * 0.02, Math.sin(a) * 0.11]); }
    m.add("Curl", tube(sp, 0.03, 5, 14), C.clayMid);
    out.push(m);
  }
  {
    const m = model("Swallow"); // navy back, cream belly, rust throat, a forked tail; the wings are bones
    m.bone("Body", null, [0, 0, 0]);
    m.add("Body", ball(0.16, 0.14, 0.42, 10), C.navy);
    m.add("Body", at(ball(0.13, 0.1, 0.34, 8), [0, -0.05, 0.02]), C.cloth);
    m.add("Body", at(lo(0.09, 0.08, 0.1), [0, -0.03, 0.34]), C.rust);
    m.add("Body", limb([0, 0.0, 0.4], [0, -0.01, 0.52], 0.03, 0.008, 4), C.eye);
    for (const s of [-1, 1]) m.add("Body", limb([0.03 * s, 0, -0.36], [0.15 * s, 0, -0.88], 0.045, 0.01, 4), C.navy);
    m.bone("WingL", "Body", [0.12, 0.02, 0.05]);
    m.add("WingL", at(puff([[0, 0.16], [0.5, 0.2], [0.98, -0.12], [0.5, -0.02], [0, -0.14]], 0.02, 0.015), [0.12, 0.02, 0.05], [90, 0, 0]), C.navy);
    m.mirror("WingL", "WingR");
    out.push(m);
  }

  // ---------- KilnWorld: the yard and terraces, and the far valley, painted height fields ----------
  {
    const m = model("KilnWorld");
    const nr = terrain.near, fr = terrain.far, n = nr.h.length - 1;
    m.bone("Floor", null, [0, 0, 0], "SmoothPlastic", "tex/kiln_floor.png");
    m.addTex("Floor", field(nr.rect[0], nr.rect[1], nr.rect[2], nr.rect[3], nr.h));
    const cw = (fr.rect[2] - fr.rect[0]) / n, cd = (fr.rect[3] - fr.rect[1]) / n;
    const under = (i, j) => { const x0 = fr.rect[0] + i * cw, z0 = fr.rect[1] + j * cd; return x0 > nr.rect[0] + 3 && x0 + cw < nr.rect[2] - 3 && z0 > nr.rect[1] + 3 && z0 + cd < nr.rect[3] - 3; };
    m.bone("Far", null, [0, 0, 0], "SmoothPlastic", "tex/kiln_far.png");
    m.addTex("Far", field(fr.rect[0], fr.rect[1], fr.rect[2], fr.rect[3], fr.h, under));
    out.push(m);
  }
  return out;
}
