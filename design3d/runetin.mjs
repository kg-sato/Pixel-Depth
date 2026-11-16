// Rune-Tin Pickaxe biography: "Read aloud, it answers." A barn owl scribe engraves one rune a night into a plain tin blank
// and reads it aloud; each rune lights cyan as she speaks it. Scene bible: vault "Forge Biographies - Scene Bibles
// (2026-11-15)", Rune-Tin. References: refs/forge/sheets/runetin_setting_s11.png and owl_views_s11.png.
// Models: OwlKit (the maker, BoltKit's bone names), RuneRoom (the round tower room, seen from INSIDE, with the domed window),
// RuneDesk (desk, scrolls, ink, the lamp, seven candles that count the nights), SpireSea (the clay spires outside under the
// moon), RunePick (the tin head with seven rune bones and the haft), EngraveTool, TinCurl, Page.
// Front of every model is +Z. Units are studs. The window is in the back wall at z = -7.6; the owl stands between the desk
// and the window, facing +Z, where the cameras stand. Palette: tin #9fb4c8, night #2c2f4a, lamp #ffd166, rune #7fe9f5.
export const name = "runetin";

const C = {
  buff: "#cf9f6e", buffDark: "#a8784a", buffLight: "#e2bc8e", grey: "#8a5a32", greyDark: "#6a4224", face: "#f4ece0", faceRim: "#6e4226", heart: "#e3a03e",
  chest: "#f4ece0", speck: "#5e4a3a", eye: "#1a1420", white: "#ffffff", beak: "#2a2a34", beakDark: "#1a1a22", talon: "#2a2a30", legs: "#9a948c",
  shawl: "#2e4470", shawlDark: "#22345a", shawlLight: "#3e5688", ink: "#151628", brass: "#d9a82e", brassDark: "#9a7a32",
  plaster: "#7a5236", plasterDark: "#5e3c26", clay: "#a8735a", clayDark: "#7d5444", clayLight: "#c48c6c",
  wood: "#7a5236", woodDark: "#5a3a26", woodLight: "#9a6c48", floor: "#6e4a32", floorLight: "#8a6040",
  tin: "#9fb4c8", tinDark: "#6e8296", tinLight: "#c9d6e2", cut: "#3a4252", rune: "#7fe9f5",
  paper: "#efe2c4", paperDark: "#d4c29c", wax: "#f2ead2", flame: "#ffd166", leather: "#7a3e2e", book2: "#2e5a5a", book3: "#6a5a2e",
  night: "#2c2f4a", spire: "#5a4a5e", spireDark: "#3a3048", spireLight: "#7a6474", window: "#ffc070",
};

export function build(THREE, T) {
  const { ball, pillow, limb, lathe, tube, puff, at, model, rnd } = T;
  const out = [];
  const lo = (rx, ry, rz, ws = 7, hs = 5) => { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const half = (rx, ry, rz, seg = 18) => { const g = new THREE.SphereGeometry(1, seg, 10, 0, Math.PI * 2, 0, Math.PI / 2); g.scale(rx, ry, rz); g.computeVertexNormals(); return g; };
  const box = (w, h, d) => new THREE.BoxGeometry(w, h, d);
  const cyl = (r0, r1, h, seg = 12) => new THREE.CylinderGeometry(r1, r0, h, seg);
  const ring = (cx, cy, cz, rx, rz, n = 16) => { const p = []; for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2; p.push([cx + Math.sin(a) * rx, cy, cz + Math.cos(a) * rz]); } return p; };
  const vring = (cx, cy, cz, rad, n = 14, a0 = 0, a1 = Math.PI * 2) => { const p = []; for (let i = 0; i <= n; i++) { const a = a0 + ((a1 - a0) * i) / n; p.push([cx + Math.sin(a) * rad, cy + Math.cos(a) * rad, cz]); } return p; };
  const flip = (g) => { // turn a closed mesh inside out: a dome seen from inside
    if (!g.index) { const idx = []; for (let k = 0; k < g.getAttribute("position").count; k++) idx.push(k); g.setIndex(idx); }
    const a = g.index.array; for (let i = 0; i < a.length; i += 3) { const s = a[i + 1]; a[i + 1] = a[i + 2]; a[i + 2] = s; }
    g.computeVertexNormals(); return g;
  };

  // ---------- OwlKit: the barn owl scribe ----------
  {
    const m = model("OwlKit");
    m.bone("Hips", null, [0, 0.9, 0]);
    m.bone("Body", "Hips", [0, 0.9, 0]);
    m.add("Body", lathe([[0.02, 0.5], [0.56, 0.56], [0.78, 0.86], [0.8, 1.24], [0.66, 1.62], [0.44, 1.92], [0.02, 2.02]], 22), C.buff);
    m.add("Body", at(ball(0.56, 0.62, 0.34, 18), [0, 1.16, 0.46]), C.chest); // the white breast
    for (let k = 0; k < 12; k++) m.add("Body", at(lo(0.035, 0.045, 0.02), [(rnd(k * 3) - 0.5) * 0.7, 0.8 + rnd(k * 5) * 0.7, 0.76 - Math.abs(rnd(k * 3) - 0.5) * 0.3]), C.speck);
    for (let k = 0; k < 14; k++) { const a = rnd(k * 7) * Math.PI * 1.2 + Math.PI * 0.4; m.add("Body", at(lo(0.05, 0.035, 0.02), [Math.cos(a) * 0.76, 1.0 + rnd(k * 11) * 0.7, -Math.abs(Math.sin(a)) * 0.7]), C.grey); }
    // the shawl: an ink-stained indigo knit over her shoulders, knotted at the front
    m.add("Body", at(ball(0.88, 0.4, 0.8, 20), [0, 1.8, -0.06]), C.shawl);
    m.add("Body", at(ball(0.84, 0.62, 0.5, 18), [0, 1.42, -0.36]), C.shawl); // it hangs down her back
    m.add("Body", tube(ring(0, 1.62, -0.02, 0.84, 0.76, 24), 0.09, 7, 40), C.shawlLight); // its edge
    for (let k = 0; k < 10; k++) { const a = (k / 10) * Math.PI * 2; m.add("Body", limb([Math.sin(a) * 0.82, 1.6, Math.cos(a) * 0.74 - 0.02], [Math.sin(a) * 0.86, 1.36, Math.cos(a) * 0.78 - 0.02], 0.035, 0.025, 5), C.shawlDark); } // fringe
    m.add("Body", at(ball(0.16, 0.14, 0.12, 10), [0.1, 1.66, 0.76]), C.shawlDark); // the knot
    for (const [dx, dl] of [[-0.02, 0.42], [0.2, 0.36]]) m.add("Body", at(pillow(0.12, dl, 0.06, 0.4, 6), [0.1 + dx, 1.62 - dl / 2, 0.8], [0, 0, dx * 40]), C.shawl);
    for (const [x, y, z, s] of [[0.5, 1.84, 0.5, 0.12], [-0.4, 1.9, 0.6, 0.08], [0.62, 1.72, -0.3, 0.1], [-0.2, 1.76, 0.74, 0.06]]) m.add("Body", at(lo(s, s * 0.6, 0.04), [x, y, z], [0, Math.atan2(x, z) * 57, 0]), C.ink); // ink stains

    m.bone("Head", "Body", [0, 2.0, 0]);
    m.add("Head", at(ball(1.04, 0.92, 0.94, 26), [0, 2.82, 0]), C.buff);
    for (let k = 0; k < 24; k++) { const a = rnd(k * 13) * Math.PI * 2, b = rnd(k * 17) * 0.9 + 0.2; const p = [Math.sin(a) * Math.sin(b) * 1.03, 2.82 + Math.cos(b) * 0.9, Math.cos(a) * Math.sin(b) * 0.93]; if (p[2] > 0.45) continue; m.add("Head", at(lo(0.05, 0.04, 0.02), p, [0, a * 57, 0]), k % 3 ? C.greyDark : C.speck); }
    // the heart-shaped face: two lobes and a point, white, with a buff rim
    for (const s of [-1, 1]) {
      m.add("Head", at(ball(0.5, 0.56, 0.2, 18), [0.34 * s, 2.86, 0.78], [0, 18 * s, 0]), C.face);
      m.add("Head", at(ball(0.54, 0.6, 0.18, 18), [0.36 * s, 2.88, 0.72], [0, 18 * s, 0]), C.faceRim);
    }
    m.add("Head", at(ball(0.34, 0.5, 0.2, 14), [0, 2.48, 0.8]), C.face);
    m.add("Head", at(ball(0.36, 0.52, 0.18, 14), [0, 2.48, 0.74]), C.faceRim);
    m.add("Head", tube([[-0.06, 3.3, 0.9], [0, 2.9, 0.98], [0.06, 3.3, 0.9]], 0.03, 5, 10), C.faceRim); // the ridge down the middle
    m.add("Head", at(lathe([[0.11, 0], [0.08, 0.14], [0.03, 0.26], [0, 0.3]], 10), [0, 2.62, 0.96], [110, 0, 0]), C.beak);
    m.add("Head", at(ball(0.07, 0.05, 0.05, 8), [0, 2.48, 1.06]), C.beakDark);
    m.bone("Eyes", "Head", [0, 2.9, 0.92]);
    for (const s of [-1, 1]) {
      m.add("Eyes", at(ball(0.24, 0.26, 0.09, 14), [0.34 * s, 2.9, 0.94], [0, 18 * s, 0]), C.eye);
      m.add("Eyes", at(ball(0.06, 0.07, 0.03, 8), [0.34 * s + 0.06, 2.98, 1.01]), C.white);
      m.add("Eyes", at(ball(0.03, 0.03, 0.02, 6), [0.34 * s - 0.06, 2.84, 1.01]), C.white);
    }
    m.bone("EyesShut", "Head", [0, 2.9, 0.98]);
    for (const s of [-1, 1]) m.add("EyesShut", tube([[0.18 * s, 2.92, 0.96], [0.34 * s, 2.84, 1.0], [0.5 * s, 2.92, 0.92]], 0.035, 6, 10), C.speck);
    // half-moon spectacles, low on the beak
    m.bone("Specs", "Head", [0, 2.76, 1.04]);
    for (const s of [-1, 1]) {
      m.add("Specs", tube(vring(0.34 * s, 2.9, 1.04, 0.29, 18), 0.03, 6, 24), C.brass);
      m.add("Specs", tube([[0.63 * s, 2.92, 1.0], [0.9 * s, 2.96, 0.5]], 0.018, 5, 4), C.brassDark);
    }
    m.add("Specs", tube([[-0.05, 2.92, 1.06], [0, 2.95, 1.09], [0.05, 2.92, 1.06]], 0.02, 5, 6), C.brass);
    for (const s of [-1, 1]) m.add("Head", at(lo(0.3, 0.16, 0.26, 10, 6), [0.5 * s, 3.62, -0.1], [0, 0, 20 * s]), C.buffDark); // soft crown, no ear tufts

    // wings as arms: a soft feathered paddle with a fringe of primaries
    m.bone("ArmL", "Body", [0.72, 1.7, 0]);
    m.add("ArmL", at(puff([[0, 0.2], [0.3, 0.26], [0.42, -0.4], [0.3, -1.0], [0.12, -1.12], [-0.06, -0.5]], 0.22, 0.1), [0.72, 1.7, 0], [0, 90, 0]), C.grey);
    for (let k = 0; k < 5; k++) m.add("ArmL", at(puff([[0, 0.05], [0.04, 0.08], [0.08, 0.05], [0.04, -0.05]], 0.02, 0.01), [0.86, 1.6 - (k % 2) * 0.22, 0.24 - Math.floor(k / 2) * 0.16], [0, 90, 180]), C.heart);
    m.add("ArmL", at(pillow(0.06, 0.12, 0.4, 0.4, 6), [0.85, 1.12, 0.05]), C.face); // the white band
    m.bone("ForeL", "ArmL", [0.82, 1.1, 0.1]);
    for (let k = 0; k < 4; k++) m.add("ForeL", at(pillow(0.13, 0.46, 0.06, 0.5, 6), [0.84, 0.84 - k * 0.02, 0.22 - k * 0.12], [0, 90, -8 + k * 6]), k % 2 ? C.greyDark : C.heart);
    m.mirror("ArmL", "ArmR"); m.mirror("ForeL", "ForeR", "ArmR");
    m.bone("LegL", "Hips", [0.3, 0.9, 0.1]);
    m.add("LegL", limb([0.3, 0.9, 0.1], [0.34, 0.5, 0.14], 0.24, 0.18), C.chest);
    m.add("LegL", limb([0.34, 0.5, 0.14], [0.34, 0.12, 0.16], 0.09, 0.08), C.legs);
    for (const a of [-24, 0, 24]) m.add("LegL", limb([0.34, 0.12, 0.2], [0.34 + Math.sin(a * Math.PI / 180) * 0.3, 0.06, 0.2 + Math.cos(a * Math.PI / 180) * 0.3], 0.06, 0.035, 6), C.talon);
    m.add("LegL", limb([0.34, 0.12, 0.16], [0.34, 0.06, -0.14], 0.05, 0.03, 6), C.talon);
    m.mirror("LegL", "LegR");
    m.bone("Tail1", "Hips", [0, 0.8, -0.6]);
    for (const dx of [-0.2, 0, 0.2]) m.add("Tail1", at(pillow(0.22, 0.08, 0.6, 0.5, 6), [dx, 0.7, -0.92], [-24, dx * 60, 0]), dx ? C.grey : C.heart);
    out.push(m);
  }

  // ---------- RuneRoom: the round tower room, from inside ----------
  {
    const m = model("RuneRoom");
    const RAD = 7.6, H = 7.2, WIN = { half: 2.9, cy: 4.2 }; // the window: a round porthole of radius 2.9 round (0, 4.2) (setting sheet)
    const NA = 48, NY = 14;
    const inWin = (x, y, z) => z < 0 && x * x + (y - WIN.cy) * (y - WIN.cy) < WIN.half * WIN.half;
    m.bone("Wall", null, [0, 0, 0]);
    { // the wall: a cylinder of plaster, the window cells left out, faced inward
      const P = [], idx = [];
      const pt = (i, j) => { const a = (i / NA) * Math.PI * 2, y = (H * j) / NY, r = RAD + Math.sin(i * 1.7) * 0.05; return [Math.sin(a) * r, y, -Math.cos(a) * r]; };
      for (let j = 0; j <= NY; j++) for (let i = 0; i <= NA; i++) P.push(...pt(i, j));
      for (let j = 0; j < NY; j++) for (let i = 0; i < NA; i++) {
        const c = pt(i + 0.5, j + 0.5); if (inWin(c[0], c[1], c[2])) continue;
        const p = j * (NA + 1) + i, q = p + 1, r = p + NA + 1, s = r + 1;
        idx.push(p, q, r, q, s, r);
      }
      const g = new THREE.BufferGeometry(); g.setAttribute("position", new THREE.Float32BufferAttribute(P, 3)); g.setIndex(idx); g.computeVertexNormals();
      m.add("Wall", g, C.plaster);
    }
    m.bone("Blocks", null, [0, 0, 0]);
    for (let k = 0; k < 120; k++) { // rounded wooden blocks laid in the wall (setting sheet)
      const a = rnd(k * 3.3) * Math.PI * 2, y = 0.5 + rnd(k * 5.1) * 6.4, x = Math.sin(a) * (RAD - 0.04), z = -Math.cos(a) * (RAD - 0.04);
      if (z < -5.5 && x * x + (y - WIN.cy) ** 2 < 3.6 * 3.6) continue;
      m.add("Blocks", at(pillow(1.3 + rnd(k) * 0.5, 0.62, 0.28, 0.5, 6), [x * 0.985, y, z * 0.985], [0, -a * 57.3, 0]), [C.wood, C.woodLight, C.woodDark][k % 3]);
    }
    m.add("Wall", flip(at(half(RAD + 0.02, 3.4, RAD + 0.02, 30), [0, H - 0.02, 0])), C.plasterDark); // the dome over the room
    m.add("Wall", tube(ring(0, H, 0, RAD - 0.12, RAD - 0.12, 40), 0.22, 8, 60), C.woodDark); // the ring beam
    for (let k = 0; k < 10; k++) { const a = (k / 10) * Math.PI * 2; m.add("Wall", tube([[Math.sin(a) * (RAD - 0.2), H, -Math.cos(a) * (RAD - 0.2)], [Math.sin(a) * 4.8, H + 2.3, -Math.cos(a) * 4.8], [0, H + 3.3, 0]], 0.13, 6, 12), C.wood); } // ribs
    // the window: a deep arched reveal, a clay sill, open to the night
    const reveal = []; for (let i = 0; i <= 40; i++) { const a = (Math.PI * 2 * i) / 40; reveal.push([Math.cos(a) * WIN.half, WIN.cy + Math.sin(a) * WIN.half]); }
    m.add("Wall", tube(reveal.map(([x, y]) => [x, y, -RAD + 0.1]), 0.32, 8, 50), C.clayLight);
    m.add("Wall", tube(reveal.map(([x, y]) => [x * 1.02, y, -RAD - 0.45]), 0.3, 8, 50), C.clayDark);
    m.add("Wall", at(box(WIN.half * 2 + 3.0, WIN.cy - WIN.half + 0.2, 1.0), [0, (WIN.cy - WIN.half) / 2, -RAD - 0.5]), C.woodDark);
    // the outside of the spire round the window, so the reveal has thickness from the cameras' side
    for (const s of [-1, 1]) m.add("Wall", at(box(4.0, H + 1.5, 0.4), [s * (WIN.half + 2.3), H / 2, -RAD - 0.9]), C.woodDark);
    m.add("Wall", tube([[-2.4, 2.0, -RAD + 0.3], [-2.9, 4.2, -RAD + 1.1], [-2.6, 6.0, -RAD + 0.5]], 0.12, 6, 10), C.woodLight); // the opened casement
    m.add("Wall", at(box(0.12, 3.6, 1.4), [-2.75, 4.0, -RAD + 0.75], [0, -50, 0]), C.wood);
    m.add("Wall", at(box(WIN.half * 2 + 1, 2.4, 0.4), [0, WIN.cy + WIN.half + 1.1, -RAD - 0.9]), C.woodDark);
    // the floor: boards
    m.bone("Floor", null, [0, 0, 0]);
    m.add("Floor", at(cyl(RAD, RAD, 0.2, 40), [0, -0.1, 0]), C.floor);
    for (let k = -7; k <= 6; k++) { const xx = k + 0.5, len = 2 * Math.sqrt(Math.max(0, RAD * RAD - xx * xx)); if (len < 1) continue; m.add("Floor", at(box(0.04, 0.02, len - 0.3), [xx, 0.005, 0]), C.woodDark); }
    for (let k = 0; k < 9; k++) m.add("Floor", at(box(0.9, 0.012, 1.0 + rnd(k) * 2), [(rnd(k * 3) - 0.5) * 10, 0.008, (rnd(k * 5) - 0.5) * 10]), C.floorLight);
    m.add("Floor", at(cyl(2.6, 2.6, 0.04, 28), [0, 0.02, -2.8]), C.shawlDark); // a round rug under the desk
    m.add("Floor", tube(ring(0, 0.05, -2.8, 2.5, 2.5, 32), 0.05, 5, 48), C.brassDark);
    // shelves of tin plates and books round the side walls, a ladder, a telescope by the window
    m.bone("Shelves", null, [0, 0, 0]);
    for (const side of [-1, 1]) for (const y of [1.2, 2.4, 3.6, 4.8]) {
      const a0 = side * 0.75, a1 = side * 1.75; // angles from the back (window) toward the sides
      const pts = []; for (let i = 0; i <= 10; i++) { const a = a0 + ((a1 - a0) * i) / 10; pts.push([Math.sin(a) * (RAD - 0.55), y, -Math.cos(a) * (RAD - 0.55)]); }
      m.add("Shelves", tube(pts, 0.09, 4, 20), C.wood);
      for (let k = 0; k < 9; k++) {
        const a = a0 + ((a1 - a0) * (k + 0.5)) / 9, r = RAD - 0.6, x = Math.sin(a) * r, z = -Math.cos(a) * r, kind = (k + Math.round(y)) % 4;
        if (side < 0 || (kind === 0 && rnd(k + y) < 0.2)) m.add("Shelves", at(cyl(0.34, 0.34, 0.05, 14), [x, y + 0.42, z], [90, -a * 57.3, 8]), k % 2 ? C.tin : C.tinDark); // a tin plate on its edge
        else { const h = 0.48 + rnd(k * 7 + y) * 0.22; m.add("Shelves", at(box(0.14, h, 0.4), [x, y + 0.08 + h / 2, z], [0, -a * 57.3, (rnd(k) - 0.5) * 10]), [C.leather, C.book2, C.book3][kind % 3]); }
      }
    }
    m.add("Shelves", tube([[5.4, 0, -3.4], [6.4, 6.6, -2.8]], 0.08, 5, 4), C.woodLight); // the ladder, against the books on the +X side (setting sheet)
    m.add("Shelves", tube([[5.0, 0, -2.6], [6.0, 6.6, -2.0]], 0.08, 5, 4), C.woodLight);
    for (let k = 1; k < 11; k++) { const u = k / 11; m.add("Shelves", tube([[5.4 + u, 6.6 * u, -3.4 + 0.6 * u], [5.0 + u, 6.6 * u, -2.6 + 0.6 * u]], 0.05, 4, 2), C.wood); }
    m.bone("Scope", null, [4.1, 0, -5.0]);
    for (const a of [0, 2.1, 4.2]) m.add("Scope", limb([4.1, 2.0, -5.0], [4.1 + Math.sin(a) * 0.7, 0, -5.0 + Math.cos(a) * 0.7], 0.05, 0.04, 6), C.woodDark);
    m.add("Scope", at(cyl(0.16, 0.24, 2.6, 14), [3.8, 2.7, -5.6], [-55, 0, 18]), C.brass);
    m.add("Scope", at(cyl(0.26, 0.26, 0.18, 14), [3.35, 3.4, -6.6], [-55, 0, 18]), C.brassDark);
    out.push(m);
  }

  // ---------- RuneDesk: desk, papers, ink, the lamp and the seven candles ----------
  {
    const m = model("RuneDesk");
    const TOP = 1.7;
    m.bone("Desk", null, [0, 0, 0]);
    m.add("Desk", at(pillow(4.4, 0.18, 1.9, 0.2, 8), [0, TOP - 0.09, 0]), C.wood);
    for (const [x, z] of [[-1.95, -0.7], [1.95, -0.7], [-1.95, 0.7], [1.95, 0.7]]) m.add("Desk", at(cyl(0.12, 0.09, TOP - 0.18, 8), [x, (TOP - 0.18) / 2, z]), C.woodDark);
    m.add("Desk", at(box(4.0, 0.08, 1.6), [0, 0.5, 0]), C.woodDark); // a shelf under it
    for (let k = 0; k < 4; k++) m.add("Desk", at(cyl(0.12, 0.12, 1.1, 10), [-1.4 + k * 0.32, 0.66, (rnd(k) - 0.5) * 0.6], [0, 0, 90]), k % 2 ? C.paper : C.paperDark); // rolled scrolls below
    m.add("Desk", at(box(1.2, 0.02, 0.9), [-1.35, TOP + 0.01, 0.35], [0, 8, 0]), C.paper); // the open page she reads from
    for (let k = 0; k < 6; k++) m.add("Desk", at(box(0.9, 0.012, 0.03), [-1.4, TOP + 0.03, 0.08 + k * 0.11], [0, 8, 0]), C.ink);
    for (const [x, z, col] of [[1.1, -0.55, C.ink], [1.42, -0.42, C.book2]]) m.add("Desk", at(lathe([[0.02, 0], [0.13, 0], [0.15, 0.14], [0.08, 0.2], [0.06, 0.24], [0.02, 0.24]], 10), [x, TOP, z]), col);
    m.add("Desk", tube([[1.12, TOP + 0.2, -0.55], [1.0, TOP + 0.7, -0.62], [0.86, TOP + 1.05, -0.7]], (u) => 0.02 + 0.07 * u * (1 - u) * 4, 6, 10), C.white); // the quill
    for (let k = 0; k < 3; k++) m.add("Desk", at(box(0.9, 0.04 + k * 0.01, 0.7), [1.6, TOP + 0.03 + k * 0.05, 0.4], [0, -10 + k * 12, 0]), [C.paper, C.paperDark, C.paper][k]); // a stack of pages
    // the brass lamp at the back left of the desk; its flame is a Neon bone and the scene's warm light sits on it
    m.bone("Lamp", "Desk", [-1.7, TOP, -0.5]);
    m.add("Lamp", at(lathe([[0.02, 0], [0.3, 0], [0.32, 0.06], [0.12, 0.12], [0.08, 0.4], [0.22, 0.5], [0.24, 0.62], [0.1, 0.7], [0.02, 0.7]], 14), [-1.7, TOP, -0.5]), C.brass);
    m.add("Lamp", at(lathe([[0.02, 0], [0.16, 0.02], [0.2, 0.24], [0.14, 0.5], [0.02, 0.52]], 14), [-1.7, TOP + 0.7, -0.5]), C.tinLight); // the glass chimney
    m.bone("LampFlame", "Lamp", [-1.7, TOP + 0.86, -0.5], "Neon");
    m.add("LampFlame", at(ball(0.06, 0.14, 0.06, 8), [-1.7, TOP + 0.88, -0.5]), C.flame);
    // seven candles along the back edge: one burns down each night (the scene shrinks each Wax bone and hides its flame)
    for (let k = 1; k <= 7; k++) {
      const x = -0.9 + (k - 1) * 0.42, z = -0.72;
      m.add("Desk", at(lathe([[0.02, 0], [0.12, 0], [0.13, 0.03], [0.05, 0.05], [0.02, 0.05]], 10), [x, TOP, z]), C.brassDark);
      m.bone("Wax" + k, "Desk", [x, TOP + 0.04, z]);
      m.add("Wax" + k, at(cyl(0.06, 0.06, 0.5, 10), [x, TOP + 0.29, z]), C.wax);
      m.add("Wax" + k, at(ball(0.065, 0.04, 0.065, 8), [x + 0.03, TOP + 0.48, z + 0.02]), C.wax); // a drip
      m.bone("Flame" + k, "Wax" + k, [x, TOP + 0.6, z], "Neon");
      m.add("Flame" + k, at(ball(0.04, 0.09, 0.04, 8), [x, TOP + 0.62, z]), C.flame);
    }
    out.push(m);
  }

  // ---------- SpireSea: the clay spires outside under the moon ----------
  {
    const m = model("SpireSea");
    m.bone("Spires", null, [0, 0, 0]);
    m.bone("Windows", null, [0, 0, 0], "Neon");
    let n = 0;
    for (let k = 0; k < 60; k++) {
      const a = (rnd(k * 2.7) - 0.5) * 2.4, d = 18 + rnd(k * 4.1) * 60, x = Math.sin(a) * d, z = -Math.cos(a) * d - 6;
      const h = 8 + rnd(k * 6.3) * 14 + d * 0.12, r = 1.4 + rnd(k * 8.9) * 2.2, base = -10 - rnd(k) * 4;
      const col = d > 50 ? C.spireDark : d > 32 ? C.spire : C.spireLight;
      m.add("Spires", at(lathe([[r * 1.2, 0], [r, h * 0.35], [r * 0.82, h * 0.7], [r * 0.5, h * 0.9], [r * 0.12, h], [0, h * 1.04]], 10), [x, base, z]), col);
      if (rnd(k * 9.1) > 0.4) m.add("Spires", at(lathe([[r * 0.95, 0], [r * 1.05, 0.25], [r * 0.95, 0.5]], 10), [x, base + h * 0.62, z]), C.spireDark); // a balcony ring
      for (let w = 0; w < 2; w++) if (rnd(k * 3 + w) > 0.45 && n < 70) { n++; const wy = base + h * (0.3 + 0.35 * w), ww = r * (1 - 0.18 * w) * 0.98; m.add("Windows", at(box(0.3, 0.5, 0.1), [x, wy, z + ww]), C.window); }
    }
    m.add("Spires", at(cyl(90, 90, 0.5, 24), [0, -12, -40]), C.night); // the dark ground far below
    out.push(m);
  }

  // ---------- RunePick: the tin blank, cut rune by rune, and the haft it gets at the end ----------
  {
    const m = model("RunePick");
    m.bone("Head", null, [0, 0, 0]);
    const shape = [[-1.3, -0.12], [-1.0, 0.1], [-0.4, 0.26], [0, 0.32], [0.4, 0.26], [1.0, 0.1], [1.3, -0.12], [0.9, -0.08], [0.3, -0.2], [0, -0.26], [-0.3, -0.2], [-0.9, -0.08]];
    m.add("Head", at(puff(shape, 0.16, 0.05), [0, 0, 0], [-90, 0, 0]), C.tin); // lies flat on the desk: the blade along X
    m.add("Head", at(cyl(0.2, 0.2, 0.2, 12), [0, 0.04, 0]), C.tinDark); // the eye for the haft
    m.bone("Haft", "Head", [0, 0, 0]);
    m.add("Haft", at(cyl(0.09, 0.11, 3.0, 10), [0, 0.1, 1.5], [90, 0, 0]), C.woodLight);
    for (const z of [0.5, 0.75, 1.0]) m.add("Haft", at(cyl(0.12, 0.12, 0.08, 10), [0, 0.1, z], [90, 0, 0]), C.leather);
    const RX = [-1.0, -0.68, -0.36, 0, 0.36, 0.68, 1.0];
    for (let k = 1; k <= 7; k++) { // each rune: the cut lines (dark), and over them its light (Neon), shown when it is spoken
      const x = RX[k - 1], y = 0.17, s = 0.11;
      const strokes = [[[x - s, y, -s], [x + s, y, s]], [[x, y, -s * 1.3], [x, y, s * 1.3]], k % 2 ? [[x - s, y, s * 0.4], [x + s * 0.6, y, s * 0.4]] : [[x + s, y, -s], [x - s * 0.4, y, 0]]];
      m.bone("Cut" + k, "Head", [x, y, 0]);
      for (const st of strokes) m.add("Cut" + k, tube(st, 0.02, 4, 2), C.cut);
      m.bone("Rune" + k, "Head", [x, y + 0.01, 0], "Neon");
      for (const st of strokes) m.add("Rune" + k, tube(st.map(([a, b, c]) => [a, b + 0.012, c]), 0.024, 4, 2), C.rune);
    }
    out.push(m);
  }

  // ---------- small things: the engraving tool, a tin curl, a page ----------
  {
    const t = model("EngraveTool");
    t.bone("Body", null, [0, 0, 0]);
    t.add("Body", at(cyl(0.07, 0.09, 0.5, 10), [0, 0.25, 0]), C.woodLight);
    t.add("Body", at(cyl(0.02, 0.035, 0.26, 8), [0, 0.63, 0]), C.tinLight);
    t.add("Body", at(cyl(0.095, 0.095, 0.05, 10), [0, 0.5, 0]), C.brass);
    out.push(t);
    const c = model("TinCurl");
    c.bone("Body", null, [0, 0, 0]);
    const sp = []; for (let i = 0; i <= 20; i++) { const a = i * 0.6; sp.push([Math.cos(a) * (0.03 + i * 0.004), i * 0.006, Math.sin(a) * (0.03 + i * 0.004)]); }
    c.add("Body", tube(sp, 0.012, 4, 30), C.tinLight);
    out.push(c);
    const p = model("Page");
    p.bone("Body", null, [0, 0, 0]);
    p.add("Body", at(box(0.8, 0.01, 1.0), [0, 0, 0]), C.paper);
    for (let k = 0; k < 5; k++) p.add("Body", at(box(0.6, 0.012, 0.025), [0, 0.006, -0.35 + k * 0.15]), C.ink);
    out.push(p);
  }
  return out;
}
