// Stone Pickaxe biography: "a lilac pebble that a river rolled for a hundred years; an otter cracks it on her belly stone".
// Setting from refs/forge/sheets/stone_setting_s11.png (a shallow river in a canyon of pale layered limestone); the maker from
// refs/forge/sheets/otter_views_s11.png (chocolate fur, cream chest and muzzle, a crossed sash of green reeds, a long thick tail).
// Models: OtterKit (same bone names as BoltKit, so poses carry over), StoneWorld (painted height fields from stone_world.py),
// StonePebble, BellyStone, StoneShard, StoneHandle. Trees, boulders, pebbles and plants come from the CC0 kit (kit_import.py).
// Front of every model is +Z. Units are studs.
import terrain from "./tex/stone_terrain.mjs";
export const name = "stone";

const C = {
  fur: "#8a4b35", furDark: "#5f3123", furLight: "#a4604a", cream: "#f2d9a8", creamShade: "#dcbd88", nose: "#1f1a22", eye: "#17121a", white: "#ffffff", pink: "#e8a79a",
  reed: "#5f9a48", reedDark: "#467a38", reedLight: "#86bb62",
  lilac: "#b9a7d6", lilacLight: "#d8cdea", lilacDark: "#8f7fb4", stone: "#8a8c96", stoneDark: "#6a6c78", stoneLight: "#aeb0b8",
  drift: "#b7a58f", driftDark: "#927f6a", driftLight: "#d6c8b4",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, field, model } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 6, hs = 4) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };

  // ---------- OtterKit: the river otter ----------
  {
    const m = model("OtterKit");
    m.bone("Hips", null, [0, 0.95, 0]);
    m.bone("Body", "Hips", [0, 0.95, 0]);
    m.add("Body", lathe([[0.02, 0.66], [0.5, 0.7], [0.74, 0.96], [0.77, 1.3], [0.64, 1.68], [0.48, 1.96], [0.02, 2.06]], 22), C.fur);
    m.add("Body", at(ball(0.55, 0.66, 0.34, 18), [0, 1.3, 0.42]), C.cream); // the pale chest and belly
    m.add("Body", at(ball(0.36, 0.3, 0.2, 14), [0, 1.86, 0.34]), C.cream);
    // the reed sash: two bands crossed on the chest, a wrap at the waist, a knot and two loose ends on her left hip
    m.add("Body", tube([[0.5, 1.94, 0.1], [0.3, 1.62, 0.6], [-0.2, 1.3, 0.76], [-0.62, 1.04, 0.44]], 0.075, 8, 16), C.reed);
    m.add("Body", tube([[-0.5, 1.94, 0.1], [-0.3, 1.62, 0.6], [0.2, 1.3, 0.76], [0.62, 1.04, 0.44]], 0.075, 8, 16), C.reedDark);
    m.add("Body", tube([[0.5, 1.94, 0.1], [0.34, 2.0, -0.4], [-0.34, 2.0, -0.4], [-0.5, 1.94, 0.1]], 0.075, 8, 14), C.reed);
    const waist = []; for (let i = 0; i <= 16; i++) { const a = (i / 16) * Math.PI * 2; waist.push([Math.sin(a) * 0.76, 1.02 + Math.sin(a * 2) * 0.03, Math.cos(a) * 0.66]); }
    m.add("Body", tube(waist, 0.08, 8, 32), C.reed);
    m.add("Body", at(ball(0.15, 0.13, 0.12, 10), [0.66, 1.03, 0.42]), C.reedDark);
    for (const [dx, l, a] of [[0.06, 0.5, 8], [-0.08, 0.42, -14]]) m.add("Body", at(puff([[-0.07, 0], [0.07, 0], [0.1, -l], [0, -l * 0.86], [-0.1, -l]], 0.04, 0.03), [0.68 + dx, 1.0, 0.46], [10, 20, a]), dx > 0 ? C.reedLight : C.reed);
    for (const [x, y] of [[0.16, 1.5], [-0.14, 1.44], [0.02, 1.16]]) m.add("Body", at(lo(0.05, 0.05, 0.04), [x, y, 0.8]), C.reedLight); // woven knots where the bands cross

    m.bone("Head", "Body", [0, 2.02, 0]);
    m.add("Head", at(ball(0.98, 0.84, 0.9, 24), [0, 2.74, 0.04]), C.fur);
    m.add("Head", at(ball(0.7, 0.44, 0.5, 20), [0, 2.44, 0.5]), C.cream); // cream cheeks and muzzle, wide
    m.add("Head", at(ball(0.42, 0.3, 0.3, 16), [0, 2.5, 0.84]), C.cream);
    m.add("Head", at(ball(0.2, 0.14, 0.14, 12), [0, 2.66, 1.06]), C.nose); // a broad dark nose
    m.add("Head", at(lo(0.06, 0.03, 0.03), [-0.05, 2.72, 1.16]), C.white);
    m.add("Head", tube([[-0.14, 2.44, 1.06], [-0.06, 2.38, 1.1], [0, 2.42, 1.11], [0.06, 2.38, 1.1], [0.14, 2.44, 1.06]], 0.022, 6, 12), C.nose);
    for (const s of [-1, 1]) {
      for (const [dy, a] of [[0.06, 10], [0, 0], [-0.07, -12]]) m.add("Head", limb([0.34 * s, 2.5 + dy, 0.9], [0.98 * s, 2.5 + dy + a * 0.012, 0.74], 0.014, 0.005, 4), C.white); // whiskers
      m.add("Head", at(ball(0.1, 0.035, 0.05, 8), [0.42 * s, 3.08, 0.74], [0, 16 * s, 12 * s]), C.furDark); // a short brow
      m.add("Head", at(ball(0.11, 0.08, 0.04, 8), [0.66 * s, 2.5, 0.68], [0, 30 * s, 0]), C.pink);
    }
    m.bone("Eyes", "Head", [0, 2.84, 0.86]);
    for (const s of [-1, 1]) {
      m.add("Eyes", at(ball(0.13, 0.17, 0.07), [0.42 * s, 2.84, 0.84], [0, 16 * s, 0]), C.eye);
      m.add("Eyes", at(ball(0.05, 0.055, 0.03), [0.42 * s + 0.035, 2.91, 0.9]), C.white);
      m.add("Eyes", at(ball(0.022, 0.022, 0.02, 6), [0.42 * s - 0.04, 2.77, 0.895]), C.white);
    }
    m.bone("EyesShut", "Head", [0, 2.84, 0.9]);
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.28 * s, 2.8, 0.84], [0.42 * s, 2.9, 0.9], [0.56 * s, 2.8, 0.82]], 0.035, 6, 10), C.furDark);
    m.bone("EarL", "Head", [0.78, 3.14, 0]);
    m.add("EarL", at(ball(0.2, 0.2, 0.12), [0.82, 3.2, 0.0], [0, 0, -30]), C.fur);
    m.add("EarL", at(ball(0.12, 0.12, 0.07), [0.83, 3.2, 0.07], [0, 0, -30]), C.furDark);
    m.mirror("EarL", "EarR");

    m.bone("ArmL", "Body", [0.6, 1.8, 0.05]);
    m.add("ArmL", limb([0.6, 1.8, 0.05], [0.94, 1.42, 0.14], 0.19, 0.165), C.fur);
    m.bone("ForeL", "ArmL", [0.94, 1.42, 0.14]);
    m.add("ForeL", limb([0.94, 1.42, 0.14], [1.02, 1.06, 0.3], 0.165, 0.17), C.fur);
    m.add("ForeL", at(ball(0.2, 0.17, 0.22), [1.03, 0.98, 0.34]), C.furDark);
    for (const dx of [-0.12, 0, 0.12]) m.add("ForeL", at(ball(0.07, 0.08, 0.09, 8), [1.03 + dx, 0.88, 0.47 - Math.abs(dx) * 0.3]), C.furDark);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");

    m.bone("LegL", "Hips", [0.34, 0.95, 0]);
    m.add("LegL", limb([0.34, 0.95, 0], [0.38, 0.34, 0.04], 0.25, 0.2), C.fur);
    m.add("LegL", at(ball(0.3, 0.12, 0.42), [0.4, 0.14, 0.24]), C.furDark); // a broad webbed foot
    for (const dx of [-0.16, 0, 0.16]) m.add("LegL", at(ball(0.08, 0.07, 0.1, 8), [0.4 + dx, 0.14, 0.62 - Math.abs(dx) * 0.4]), C.furDark);
    m.mirror("LegL", "LegR");

    // the tail: long and thick, the otter's rudder
    m.bone("Tail1", "Hips", [0, 0.9, -0.5]);
    m.add("Tail1", limb([0, 0.9, -0.45], [0, 0.56, -1.5], 0.36, 0.27, 14), C.fur);
    m.bone("Tail2", "Tail1", [0, 0.56, -1.5]);
    m.add("Tail2", limb([0, 0.56, -1.5], [0, 0.36, -2.7], 0.27, 0.08, 14), C.fur);
    m.add("Tail2", at(ball(0.1, 0.09, 0.14, 8), [0, 0.35, -2.76]), C.furDark);
    out.push(m);
  }

  // ---------- StoneWorld: the canyon floor and the far canyon, painted height fields ----------
  {
    const m = model("StoneWorld");
    const nr = terrain.near, fr = terrain.far, n = nr.h.length - 1;
    m.bone("Floor", null, [0, 0, 0], "SmoothPlastic", "tex/stone_floor.png");
    m.addTex("Floor", field(nr.rect[0], nr.rect[1], nr.rect[2], nr.rect[3], nr.h));
    const cw = (fr.rect[2] - fr.rect[0]) / n, cd = (fr.rect[3] - fr.rect[1]) / n;
    const under = (i, j) => { const x0 = fr.rect[0] + i * cw, z0 = fr.rect[1] + j * cd; return x0 > nr.rect[0] + 3 && x0 + cw < nr.rect[2] - 3 && z0 > nr.rect[1] + 3 && z0 + cd < nr.rect[3] - 3; };
    m.bone("Far", null, [0, 0, 0], "SmoothPlastic", "tex/stone_far.png");
    m.addTex("Far", field(fr.rect[0], fr.rect[1], fr.rect[2], fr.rect[3], fr.h, under));
    out.push(m);
  }

  // ---------- LimeSlabA/B/C: the canyon's sculpted layers ----------
  // The reference walls are stacks of rounded limestone ledges that swell in and out. A height field cannot overhang, so the
  // ledges are these slabs, set into the painted walls by stone_world.py: a cream top that catches the sun, a darker underside
  // that draws the shadow line between one layer and the next. Long axis is X.
  for (const [nm, rx, ry, rz, top, under] of [["LimeSlabA", 13, 1.5, 6, "#f1e8d8", "#b9a892"], ["LimeSlabB", 9, 1.25, 4.6, "#e6dac6", "#ad9c88"], ["LimeSlabC", 17, 1.8, 7.5, "#f6eee0", "#c0af98"]]) {
    const m = model(nm);
    m.bone("Slab", null, [0, 0, 0]);
    const g = new THREE.SphereGeometry(1, 20, 10);
    const p = g.attributes.position;
    for (let i = 0; i < p.count; i++) { // a pillow, not an egg: the sides stand nearly straight and the top is flat-ish, with a slow wobble along its length
      const x = p.getX(i), y = p.getY(i), z = p.getZ(i);
      const sq = (v) => Math.sign(v) * Math.pow(Math.abs(v), 0.62);
      const wob = 1 + 0.1 * Math.sin(x * 4.1 + rx) + 0.06 * Math.sin(x * 9.3);
      p.setXYZ(i, sq(x) * rx, sq(y) * ry, sq(z) * rz * wob);
    }
    g.computeVertexNormals();
    m.add("Slab", g, top);
    m.add("Slab", at(ball(rx * 0.97, ry * 0.5, rz * 0.97, 16), [0, -ry * 0.72, 0]), under);
    out.push(m);
  }

  // ---------- props ----------
  {
    const m = model("StonePebble"); // the lilac pebble the river rounded: smooth, with a pale band and a few specks
    m.bone("Pebble", null, [0, 0, 0]);
    m.add("Pebble", ball(0.44, 0.31, 0.37, 20), C.lilac);
    m.add("Pebble", at(ball(0.445, 0.05, 0.375, 20), [0, 0.06, 0], [0, 0, 8]), C.lilacLight);
    for (let k = 0; k < 7; k++) { const a = k * 2.4, b = (k % 3) * 0.5 - 0.4; m.add("Pebble", at(lo(0.04, 0.03, 0.04), [Math.cos(a) * 0.4 * Math.cos(b), Math.sin(b) * 0.29, Math.sin(a) * 0.34 * Math.cos(b)]), k % 2 ? C.lilacDark : C.lilacLight); }
    out.push(m);
  }
  {
    const m = model("BellyStone"); // her favourite flat stone, worn smooth, with a shallow dimple where she always strikes
    m.bone("Stone", null, [0, 0, 0]);
    m.add("Stone", ball(0.5, 0.13, 0.42, 20), C.stone);
    m.add("Stone", at(ball(0.2, 0.03, 0.17, 12), [0, 0.11, 0]), C.stoneDark);
    m.add("Stone", at(ball(0.46, 0.04, 0.38, 16), [0.03, 0.05, 0.02]), C.stoneLight);
    out.push(m);
  }
  {
    const m = model("StoneShard"); // half the pebble after the crack: the round back, and a fresh pale face with flake scars
    m.bone("Shard", null, [0, 0, 0]);
    const g = new THREE.SphereGeometry(1, 18, 12, 0, Math.PI * 2, 0, Math.PI / 2); g.scale(0.44, 0.3, 0.37); g.computeVertexNormals();
    m.add("Shard", g, C.lilac);
    m.add("Shard", at(ball(0.43, 0.03, 0.36, 18), [0, 0.0, 0]), C.lilacLight);
    for (const [x, z, r] of [[0.12, 0.06, 0.16], [-0.16, -0.08, 0.13], [0.02, -0.18, 0.1]]) m.add("Shard", at(lo(r, 0.02, r * 0.8, 8, 3), [x, -0.02, z]), C.white);
    m.add("Shard", at(puff([[-0.4, 0], [0.4, 0], [0.34, -0.1], [0.1, -0.16], [-0.2, -0.12]], 0.5, 0.03, false), [0, -0.01, 0], [90, 0, 0]), C.lilacDark);
    out.push(m);
  }
  {
    const m = model("StoneHandle"); // a driftwood stick the river left, and the reed binding she ties round it
    m.bone("Stick", null, [0, 0, 0]);
    m.add("Stick", tube([[0, -1.3, 0], [0.04, -0.6, 0.02], [-0.03, 0.1, 0], [0.02, 0.8, -0.02], [0, 1.25, 0]], (u) => 0.11 - 0.03 * u, 9, 16), C.drift);
    for (const [y, a] of [[-0.8, 30], [-0.1, 200], [0.5, 110]]) m.add("Stick", at(lo(0.07, 0.05, 0.05), [Math.sin((a * Math.PI) / 180) * 0.1, y, Math.cos((a * Math.PI) / 180) * 0.1]), C.driftDark);
    m.add("Stick", limb([0.02, 0.3, 0], [0.26, 0.56, 0.08], 0.05, 0.02, 6), C.driftLight);
    m.bone("Reeds", "Stick", [0, 1.0, 0]);
    for (let k = 0; k < 5; k++) { const ring = []; for (let i = 0; i <= 10; i++) { const a = (i / 10) * Math.PI * 2; ring.push([Math.sin(a) * 0.13, 0.82 + k * 0.09 + Math.sin(a) * 0.03, Math.cos(a) * 0.13]); } m.add("Reeds", tube(ring, 0.035, 6, 20), k % 2 ? C.reed : C.reedDark); }
    m.add("Reeds", at(puff([[-0.05, 0], [0.05, 0], [0.08, -0.4], [0, -0.34], [-0.08, -0.4]], 0.03, 0.02), [0.12, 0.84, 0.1], [0, 30, -20]), C.reedLight);
    out.push(m);
  }
  return out;
}
