// Export a forge biography scene file for Roblox: one JSON per model (for tools/design3d/write_glb.py, one mesh per bone,
// rest coordinates kept) and one rig manifest for all models (parent, joint, centre, size, material, colour per bone).
//   node design3d/export.mjs wood design3d/out
// THREE comes from the shared tools folder (three 0.182.0, pinned there).
import { writeFileSync, mkdirSync } from "node:fs";
import { pathToFileURL, fileURLToPath } from "node:url";
import { resolve, dirname } from "node:path";
const here = dirname(fileURLToPath(import.meta.url));
const THREE = await import(pathToFileURL(resolve(here, "../../../tools/design3d/node_modules/three/build/three.module.js")).href);
const { makeToy } = await import(pathToFileURL(resolve(here, "toy.mjs")).href);
const [, , sceneName, outDir] = process.argv;
const scene = await import(pathToFileURL(resolve(here, sceneName + ".mjs")).href);
const models = scene.build(THREE, makeToy(THREE));
mkdirSync(outDir, { recursive: true });
const rigs = {};
// soft pastel look (owner, 2026-11-16): every texture colour is lifted toward white and a little desaturated; very dark
// colours (pupils, lines) only lift a touch so faces still read. Neon bones keep their own colour (b.color below).
function pastel(hex) {
  const c = new THREE.Color(hex), hsl = {};
  c.getHSL(hsl);
  const l = hsl.l < 0.12 ? hsl.l + 0.05 : hsl.l + (1 - hsl.l) * 0.26;
  c.setHSL(hsl.h, hsl.s * 0.78, Math.min(l, 0.95));
  return "#" + c.getHexString();
}
for (const m of models) {
  const man = m.manifest(), parts = [];
  let tris = 0;
  for (const b of man) {
    const g = m.merged(b.name);
    parts.push({ name: b.name, image: b.image ? resolve(here, b.image) : undefined, palette: m.palette.map(pastel), position: Array.from(g.getAttribute("position").array), normal: Array.from(g.getAttribute("normal").array), uv: Array.from(g.getAttribute("uv").array), index: Array.from(g.index.array) });
    tris += b.tris;
    if (b.tris > 20000) throw new Error(`${m.name}.${b.name}: ${b.tris} triangles (rule: under 20,000)`);
    // a Neon bone shows one flat colour in Roblox: the first colour its mesh uses
    const u = g.getAttribute("uv").array[0], v = 1 - g.getAttribute("uv").array[1];
    b.color = m.palette[Math.floor(v * 8) * 8 + Math.floor(u * 8)] || "#ffffff";
  }
  const all = m.bones().filter((b) => !man.find((x) => x.name === b.name)).map((b) => ({ name: b.name, parent: b.parent, joint: b.joint, empty: true }));
  rigs[m.name] = { bones: man.concat(all) };
  writeFileSync(resolve(outDir, m.name + ".json"), JSON.stringify({ name: m.name, size: [0, 0, 0], parts }));
  console.log(`${m.name}: ${man.length} meshes, ${tris} triangles, ${m.palette.length} colours`);
}
writeFileSync(resolve(outDir, sceneName + "_rig.json"), JSON.stringify(rigs));
