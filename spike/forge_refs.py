"""Reference sheets for the forge scene models (multi-view turnarounds and material call-outs), made locally with ComfyUI
(FLUX.1 schnell, the workflow of UI Kit/art/comfy_generate.py). Nothing is uploaded.
    python spike/forge_refs.py [name ...]        writes refs/forge/sheets/<name>_s<seed>.png
The owner, 2026-11-15: "use a more detailed reference ... multi views as well as details for materials"."""
import importlib.util, json, pathlib, sys
game = pathlib.Path(__file__).resolve().parent.parent
root = game.parent.parent
spec = importlib.util.spec_from_file_location("comfy_generate", root / "UI Kit" / "art" / "comfy_generate.py")
cg = importlib.util.module_from_spec(spec); spec.loader.exec_module(cg)
out = game / "refs" / "forge" / "sheets"; out.mkdir(parents=True, exist_ok=True)

LOOK = ("Stylized 3D game asset in a soft hand-painted toy style, rounded chunky forms, clean readable shapes, matte painted "
        "surfaces with gentle colour gradients, even soft studio lighting from the upper left, plain pale grey background, no text.")
SHEETS = {
    "cabin_views": (1344, 768, "A model sheet showing the same small rustic two-storey log cabin four times in a row, from left to right: front view, "
                    "left side view, back view, and a three-quarter view. The cabin is built of round stacked honey-brown logs with pale cut ends "
                    "that cross at the corners, a steep grey-blue standing-seam metal roof with deep overhanging eaves, a small gabled dormer with "
                    "a window over the front, a tall fieldstone chimney, a fieldstone footing, a covered side porch with log posts, a plank deck "
                    "and a wooden railing, two steps, warm glowing amber four-pane windows with wooden frames and flower boxes, a plank door with "
                    "a small lit glass pane, a lantern hanging by the door, a stack of split firewood under a lean-to. " + LOOK),
    "cabin_materials": (1024, 1024, "A material call-out board of six square close-up swatches in a two by three grid for a stylized log cabin: "
                        "one, round stacked logs with dark chinking between them and a pale end-grain cut end with growth rings; two, grey-blue "
                        "standing-seam metal roofing with raised ribs and a few rust streaks; three, fieldstone masonry of rounded grey and "
                        "warm brown stones with pale mortar; four, weathered grey-brown deck planks with nail heads; five, a wooden four-pane "
                        "window glowing warm amber from inside; six, split firewood ends stacked. " + LOOK),
    "raccoon_views": (1344, 768, "A character turnaround sheet showing the same chibi young raccoon adventurer four times in a row, from left to right: "
                      "front view, side view, back view, and a three-quarter view, standing in a relaxed pose. He has a huge round fluffy head "
                      "more than half his height on a tiny body with short stubby arms and legs, tall oval black eyes set wide apart each with "
                      "one white highlight, a dark brown mask across the eyes, a cream muzzle with a tiny black nose, round ears with pink "
                      "insides, soft ragged tufts of grey fur at the cheeks and on the crown, a thick bushy tail with five dark rings. He wears "
                      "a red neckerchief, a short teal hooded travelling cloak, a brown leather vest trimmed with cream fur, a belt with a "
                      "brass buckle, a leather satchel on a strap and a rolled bedroll on his back, and holds a small whittling knife. " + LOOK),
    "raccoon_materials": (1024, 1024, "A material call-out board of six square close-up swatches in a two by three grid for a stylized chibi raccoon "
                          "character: one, soft grey fur painted in short overlapping tufts with paler tips; two, dark brown mask fur beside "
                          "cream muzzle fur; three, the tail's dark and light fur rings; four, red woven cotton neckerchief cloth with a "
                          "stitched hem; five, teal wool cloak cloth with a paler hem; six, brown leather with stitching, a brass buckle and "
                          "cream fur trim. " + LOOK),
    "spruce_views": (1344, 768, "A model sheet showing the same tall alpine spruce tree three times in a row: front view, side view and a view from "
                     "below. A narrow dark blue-green spire, boughs in layered whorls that droop and lift at their tips, paler green new growth at "
                     "the bough tips, a bare lower trunk of grey-brown bark with dead stubs and flared roots. " + LOOK),
}
names = sys.argv[1:] or list(SHEETS)
if not cg.server_up(): cg.start_server()
for n in names:
    w, h, prompt = SHEETS[n]
    for seed in (11, 12):
        wf = cg.workflow(prompt, seed, 1024, 4)
        wf["6"]["inputs"]["width"], wf["6"]["inputs"]["height"] = w, h
        pid = json.loads(cg.api("/prompt", {"prompt": wf}))["prompt_id"]
        import time, urllib.parse
        for _ in range(1500):
            hst = json.loads(cg.api("/history/" + pid))
            if pid in hst:
                st = hst[pid]["status"]
                if st.get("status_str") == "error": raise RuntimeError(json.dumps(st.get("messages"))[:600])
                img = hst[pid]["outputs"]["9"]["images"][0]
                q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
                (out / f"{n}_s{seed}.png").write_bytes(cg.api("/view?" + q, timeout=60))
                print("wrote", f"{n}_s{seed}.png", flush=True)
                break
            time.sleep(1)
        else:
            print("timed out", n, seed, flush=True)
