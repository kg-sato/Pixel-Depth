"""forge_page.py : build out/pickaxe_forge.html (the Pickaxe Forge artifact) from art/gen/pick_XX.png, specs/pick_XX.json and out/pick_XX/.
Each built pickaxe gets its GLB (the Roblox game mesh) in a three.js viewer, the concept beside the Cycles hero render, and its budget numbers."""
import base64, glob, io, json, os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "..", "art", "gen")


def jpg(path, w):
    im = Image.open(path).convert("RGB")
    im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
    b = io.BytesIO()
    im.save(b, "JPEG", quality=82)
    return "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()


items = []
for i in range(1, 11):
    tag = f"pick_{i:02d}"
    spec_p = os.path.join(HERE, "specs", tag + ".json")
    spec = json.load(open(spec_p, encoding="utf-8")) if os.path.exists(spec_p) else {}
    it = {"tag": tag, "num": i, "name": spec.get("name", ""), "concept": jpg(os.path.join(GEN, tag + ".png"), 520)}
    out = os.path.join(HERE, "out", tag)
    glb = os.path.join(out, spec.get("name", "?") + ".glb")
    if spec and os.path.exists(glb):
        man = json.load(open(os.path.join(out, spec["name"] + "_manifest.json")))
        it.update({"glb": base64.b64encode(open(glb, "rb").read()).decode(), "hero": jpg(os.path.join(out, spec["name"] + "_hero_fx.jpg"), 520), "vfx": man.get("vfx", {}),
                   "tris": man["tris"], "length": man["length"],
                   "parts": [{"name": k.split("_")[-1], "tris": v["tris"]} for k, v in man["parts"].items()]})
        g = glob.glob(os.path.join(out, "grade.json"))
        if g:
            it["grade"] = json.load(open(g[0]))
    items.append(it)

tpl = open(os.path.join(HERE, "forge_template.html"), encoding="utf-8").read()
html = tpl.replace("/*ITEMS*/[]", json.dumps(items))
dst = os.path.join(HERE, "out", "pickaxe_forge.html")
open(dst, "w", encoding="utf-8").write(html)
print(dst, f"{len(html) / 1e6:.2f} MB", sum(1 for x in items if "glb" in x), "built")
