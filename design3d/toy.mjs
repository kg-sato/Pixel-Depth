// Charm-toy library for the forge biography models (Pixel Depth, brief "Forge Biographies (2026-11-15)").
// One file drives the board preview and the Roblox export. Units are studs, Y up. Every shape is rounded; every model is a
// set of named bones (one mesh each) with a joint, so each limb can turn in the preview and in Studio.
export function makeToy(THREE) {
  const TAU = Math.PI * 2;

  // ---- shapes (all return an indexed BufferGeometry with smooth normals) ----
  function ball(rx, ry = rx, rz = rx, seg = 14) {
    const g = new THREE.SphereGeometry(1, seg, Math.max(8, Math.round(seg * 0.7)));
    g.scale(rx, ry, rz);
    g.computeVertexNormals();
    return g;
  }
  // a pillow: a box whose corners are fully rounded (superellipsoid). e = 0.25 is boxy, 1 is a ball.
  function pillow(w, h, d, e = 0.35, seg = 14) {
    const pos = [], idx = [];
    const f = (c) => Math.sign(c) * Math.pow(Math.abs(c), e);
    for (let j = 0; j <= seg; j++) {
      const v = -Math.PI / 2 + (j / seg) * Math.PI;
      for (let i = 0; i <= seg * 2; i++) {
        const u = -Math.PI + (i / (seg * 2)) * TAU;
        pos.push((w / 2) * f(Math.cos(v)) * f(Math.cos(u)), (h / 2) * f(Math.sin(v)), (d / 2) * f(Math.cos(v)) * f(Math.sin(u)));
      }
    }
    const row = seg * 2 + 1;
    for (let j = 0; j < seg; j++) for (let i = 0; i < seg * 2; i++) {
      const a = j * row + i, b = a + 1, c = a + row, dd = c + 1;
      idx.push(a, c, b, b, c, dd);
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    g.setIndex(idx);
    g.computeVertexNormals();
    return g;
  }
  function capsule(r, len, seg = 12) { // along Y, total height len + 2r
    const g = new THREE.CapsuleGeometry(r, len, 6, seg);
    return g;
  }
  // a limb between two points with a radius at each end (a soft cone with round caps)
  function limb(a, b, ra, rb = ra, seg = 12) {
    const A = new THREE.Vector3(...a), B = new THREE.Vector3(...b);
    const len = A.distanceTo(B);
    const pts = [];
    const n = seg <= 6 ? 2 : 4;
    for (let i = 0; i <= n; i++) { const t = (i / n) * (Math.PI / 2); pts.push(new THREE.Vector2(ra * Math.sin(t), -ra * Math.cos(t))); }
    for (let i = 0; i <= n; i++) { const t = (i / n) * (Math.PI / 2); pts.push(new THREE.Vector2(rb * Math.cos(t), len + rb * Math.sin(t))); }
    const g = new THREE.LatheGeometry(pts, seg);
    g.computeVertexNormals();
    const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), B.clone().sub(A).normalize());
    g.applyQuaternion(q);
    g.translate(A.x, A.y, A.z);
    return g;
  }
  // lathe from [radius, height] pairs, bottom to top
  function lathe(profile, seg = 20) {
    const g = new THREE.LatheGeometry(profile.map(([r, y]) => new THREE.Vector2(Math.max(r, 0.0001), y)), seg);
    g.computeVertexNormals();
    return g;
  }
  // a tube along points; r may be a number or a function of 0..1
  function tube(points, r, seg = 8, steps = 24) {
    const curve = new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(...p)));
    const frames = curve.computeFrenetFrames(steps, false);
    const pos = [], idx = [];
    for (let i = 0; i <= steps; i++) {
      const t = i / steps, c = curve.getPointAt(t), rr = typeof r === "function" ? r(t) : r;
      for (let j = 0; j <= seg; j++) {
        const a = (j / seg) * TAU;
        const n = frames.normals[i].clone().multiplyScalar(Math.cos(a)).add(frames.binormals[i].clone().multiplyScalar(Math.sin(a)));
        pos.push(c.x + n.x * rr, c.y + n.y * rr, c.z + n.z * rr);
      }
    }
    const row = seg + 1;
    for (let i = 0; i < steps; i++) for (let j = 0; j < seg; j++) {
      const a = i * row + j, b = a + 1, c = a + row, d = c + 1;
      idx.push(a, b, c, b, d, c);
    }
    // round end caps: fans to the end points
    const s = pos.length / 3; const p0 = curve.getPointAt(0), p1 = curve.getPointAt(1);
    pos.push(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z);
    for (let j = 0; j < seg; j++) { idx.push(s, j + 1, j); idx.push(s + 1, steps * row + j, steps * row + j + 1); }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    g.setIndex(idx);
    g.computeVertexNormals();
    return g;
  }
  // a flat shape from 2D points (x, y), puffed: extruded with a round bevel, then smoothed with a crease angle
  function puff(points2, depth = 0.2, bevel = 0.08, curved = true) {
    const sh = new THREE.Shape();
    if (curved) {
      const c = new THREE.CatmullRomCurve3(points2.map(([x, y]) => new THREE.Vector3(x, y, 0)), true);
      const ps = c.getPoints(points2.length * 6);
      sh.moveTo(ps[0].x, ps[0].y);
      for (let i = 1; i < ps.length; i++) sh.lineTo(ps[i].x, ps[i].y);
    } else {
      sh.moveTo(points2[0][0], points2[0][1]);
      for (let i = 1; i < points2.length; i++) sh.lineTo(points2[i][0], points2[i][1]);
    }
    const g = new THREE.ExtrudeGeometry(sh, { depth, bevelEnabled: true, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 3, curveSegments: 6 });
    g.translate(0, 0, -depth / 2);
    return crease(g, 50);
  }
  // recompute normals so faces within `deg` of each other shade smooth (works on any geometry, returns it indexed 1:1)
  function crease(g, deg = 40) {
    const ng = g.index ? g.toNonIndexed() : g;
    const p = ng.getAttribute("position"), n = p.count, cosT = Math.cos((deg * Math.PI) / 180);
    const fn = [], map = new Map(), key = (i) => `${Math.round(p.getX(i) * 1e4)},${Math.round(p.getY(i) * 1e4)},${Math.round(p.getZ(i) * 1e4)}`;
    const a = new THREE.Vector3(), b = new THREE.Vector3(), c = new THREE.Vector3();
    for (let f = 0; f < n / 3; f++) {
      a.fromBufferAttribute(p, f * 3); b.fromBufferAttribute(p, f * 3 + 1); c.fromBufferAttribute(p, f * 3 + 2);
      const nn = b.clone().sub(a).cross(c.clone().sub(a)); // area-weighted
      fn.push(nn);
      for (let k = 0; k < 3; k++) { const kk = key(f * 3 + k); if (!map.has(kk)) map.set(kk, []); map.get(kk).push(f); }
    }
    const out = new Float32Array(n * 3);
    for (let f = 0; f < n / 3; f++) {
      const me = fn[f].clone().normalize();
      for (let k = 0; k < 3; k++) {
        const acc = new THREE.Vector3();
        for (const o of map.get(key(f * 3 + k))) if (fn[o].lengthSq() > 0 && fn[o].clone().normalize().dot(me) >= cosT) acc.add(fn[o]);
        if (acc.lengthSq() === 0) acc.copy(me);
        acc.normalize();
        out.set([acc.x, acc.y, acc.z], (f * 3 + k) * 3);
      }
    }
    ng.setAttribute("normal", new THREE.BufferAttribute(out, 3));
    return ng;
  }
  // move / turn / scale a geometry: at(g, [x,y,z], [rx,ry,rz] degrees, scale or [sx,sy,sz])
  function at(g, p = [0, 0, 0], r = [0, 0, 0], s = 1) {
    const sc = Array.isArray(s) ? s : [s, s, s];
    const m = new THREE.Matrix4().compose(new THREE.Vector3(...p), new THREE.Quaternion().setFromEuler(new THREE.Euler((r[0] * Math.PI) / 180, (r[1] * Math.PI) / 180, (r[2] * Math.PI) / 180, "YXZ")), new THREE.Vector3(...sc));
    g.applyMatrix4(m);
    if (sc[0] * sc[1] * sc[2] < 0) {
      if (!g.index) { const idx = []; for (let k = 0; k < g.getAttribute("position").count; k++) idx.push(k); g.setIndex(idx); }
      const arr = g.index.array; for (let i = 0; i < arr.length; i += 3) { const t = arr[i]; arr[i] = arr[i + 1]; arr[i + 1] = t; }
    }
    g.computeBoundingBox();
    return g;
  }

  // paper-theatre backdrop pieces. A strip is a wall from y = bottom up to top(u), u = 0..1 along its length, bent round the
  // stage: x runs along the arc, radius is how far behind the stage it stands (the wall faces the stage centre, at -Z back).
  function strip(top, bottom, half, radius, n = 72, edge = 0) {
    const pos = [], idx = [];
    for (let i = 0; i <= n; i++) {
      const u = i / n, a = ((-half + u * 2 * half) / radius), y1 = top(u), y0 = edge ? y1 - edge : bottom;
      const x = Math.sin(a) * radius, z = -Math.cos(a) * radius;
      pos.push(x, y0, z, x, y1, z);
    }
    for (let i = 0; i < n; i++) { const a = i * 2, b = a + 1, c = a + 2, d = a + 3; idx.push(a, c, b, b, c, d); }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    g.setIndex(idx); g.computeVertexNormals();
    return g;
  }
  // bend a flat piece standing at z = -radius round the same arc (x becomes the arc length)
  function bend(g, radius) {
    const p = g.getAttribute("position");
    for (let i = 0; i < p.count; i++) {
      const r = -p.getZ(i), a = p.getX(i) / radius;
      p.setXYZ(i, Math.sin(a) * r, p.getY(i), -Math.cos(a) * r);
    }
    p.needsUpdate = true; g.computeVertexNormals(); g.computeBoundingBox();
    return g;
  }

  // ---- a model: bones with one merged mesh each ----
  function model(name) {
    const palette = [];
    const bones = new Map();
    const order = [];
    const ci = (hex) => { let i = palette.indexOf(hex); if (i < 0) { palette.push(hex); i = palette.length - 1; } if (i >= 64) throw new Error(name + ": more than 64 colours"); return i; };
    const m = {
      name, palette,
      // bone(name, parent or null, joint [x,y,z] in rest coordinates, material class)
      // image: a painted picture for this bone (a PNG path relative to design3d/); its geometry then brings its own UVs (addTex)
      bone(bn, parent, joint, mat = "SmoothPlastic", image = null) { bones.set(bn, { name: bn, parent, joint, mat, image, geos: [] }); order.push(bn); return m; },
      addTex(bn, g) {
        const b = bones.get(bn); if (!b || !b.image) throw new Error(name + ": " + bn + " has no image");
        if (!g.index) { const idx = []; for (let k = 0; k < g.getAttribute("position").count; k++) idx.push(k); g.setIndex(idx); }
        if (!g.getAttribute("normal")) g.computeVertexNormals();
        b.geos.push(g); return m;
      },
      // add(bone, geometry in rest coordinates, colour)
      add(bn, g, hex) {
        const b = bones.get(bn); if (!b) throw new Error(name + ": no bone " + bn);
        const i = ci(hex), n = g.getAttribute("position").count, uv = new Float32Array(n * 2), u = ((i % 8) + 0.5) / 8, v = 1 - (Math.floor(i / 8) + 0.5) / 8;
        for (let k = 0; k < n; k++) { uv[2 * k] = u; uv[2 * k + 1] = v; }
        g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
        if (!g.index) { const idx = []; for (let k = 0; k < n; k++) idx.push(k); g.setIndex(idx); }
        if (!g.getAttribute("normal")) g.computeVertexNormals();
        b.geos.push(g); return m;
      },
      // mirror a bone's geometry across X into another bone (left/right limbs)
      mirror(from, to, parent, mat) {
        const s = bones.get(from);
        m.bone(to, parent ?? s.parent, [-s.joint[0], s.joint[1], s.joint[2]], mat ?? s.mat);
        const d = bones.get(to);
        for (const g of s.geos) d.geos.push(at(g.clone(), [0, 0, 0], [0, 0, 0], [-1, 1, 1]));
        return m;
      },
      merged(bn) { // one geometry per bone, rest coordinates
        const b = bones.get(bn); let np = 0, ni = 0;
        for (const g of b.geos) { np += g.getAttribute("position").count; ni += g.index.count; }
        const pos = new Float32Array(np * 3), nor = new Float32Array(np * 3), uv = new Float32Array(np * 2), idx = new Uint32Array(ni);
        let op = 0, oi = 0;
        for (const g of b.geos) {
          const p = g.getAttribute("position"), n = g.getAttribute("normal"), t = g.getAttribute("uv");
          pos.set(p.array, op * 3); nor.set(n.array, op * 3); uv.set(t.array, op * 2);
          for (let k = 0; k < g.index.count; k++) idx[oi + k] = g.index.array[k] + op;
          op += p.count; oi += g.index.count;
        }
        const g = new THREE.BufferGeometry();
        g.setAttribute("position", new THREE.BufferAttribute(pos, 3)); g.setAttribute("normal", new THREE.BufferAttribute(nor, 3)); g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
        g.setIndex(new THREE.BufferAttribute(idx, 1)); g.computeBoundingBox();
        return g;
      },
      bones: () => order.map((n) => bones.get(n)),
      // rig manifest for Studio: per bone its parent, joint, the centre and size of its mesh, material class, triangles
      manifest() {
        return order.filter((n) => bones.get(n).geos.length).map((n) => {
          const b = bones.get(n), g = m.merged(n), c = new THREE.Vector3(), s = new THREE.Vector3();
          g.boundingBox.getCenter(c); g.boundingBox.getSize(s);
          const r = (x) => Math.round(x * 1000) / 1000;
          return { name: n, parent: b.parent, joint: b.joint.map(r), center: [r(c.x), r(c.y), r(c.z)], size: [r(s.x), r(s.y), r(s.z)], mat: b.mat, image: b.image || undefined, tris: g.index.count / 3 };
        });
      },
      // preview: a THREE.Group tree, one Group per bone at its joint, with the mesh inside; nodes[name] turns the limb
      preview(material) {
        const nodes = {}, root = new THREE.Group(); root.name = name;
        for (const n of order) {
          const b = bones.get(n), grp = new THREE.Group(); grp.name = n;
          const pj = b.parent ? bones.get(b.parent).joint : [0, 0, 0];
          grp.position.set(b.joint[0] - pj[0], b.joint[1] - pj[1], b.joint[2] - pj[2]);
          if (b.geos.length) { const g = m.merged(n); g.translate(-b.joint[0], -b.joint[1], -b.joint[2]); const mesh = new THREE.Mesh(g, material(b.mat)); mesh.castShadow = true; mesh.receiveShadow = true; grp.add(mesh); }
          (b.parent ? nodes[b.parent] : root).add(grp); nodes[n] = grp;
        }
        return { root, nodes };
      },
    };
    return m;
  }
  // a height field: rows of heights (nz + 1 rows of nx + 1 values, row 0 at z0), planar UVs (u along x, v = 0 at z1), and an
  // optional skip(i, j) that leaves a cell out (a hole, for the lake)
  function field(x0, z0, x1, z1, heights, skip) {
    const nz = heights.length - 1, nx = heights[0].length - 1, pos = [], uv = [], idx = [];
    for (let j = 0; j <= nz; j++) for (let i = 0; i <= nx; i++) {
      pos.push(x0 + ((x1 - x0) * i) / nx, heights[j][i], z0 + ((z1 - z0) * j) / nz);
      uv.push(i / nx, 1 - j / nz);
    }
    const row = nx + 1;
    for (let j = 0; j < nz; j++) for (let i = 0; i < nx; i++) {
      if (skip && skip(i, j)) continue;
      const a = j * row + i, b = a + 1, c = a + row, d = c + 1;
      idx.push(a, c, b, b, c, d);
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
    g.setIndex(idx); g.computeVertexNormals(); g.computeBoundingBox();
    return g;
  }
  // mirror a geometry in the water plane y = level (the reflection drawn under the lake): flips the winding and the normals
  function mirrorY(g, level) { return at(g.clone(), [0, 2 * level, 0], [0, 0, 0], [1, -1, 1]); }
  const rnd = (i) => { const x = Math.sin(i * 127.1 + 11.7) * 43758.5453; return x - Math.floor(x); };
  return { ball, pillow, capsule, limb, lathe, tube, puff, crease, at, strip, bend, field, mirrorY, rnd, model, TAU };
}
