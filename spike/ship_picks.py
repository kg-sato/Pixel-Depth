"""Ship finished pickaxes into the game: upload each GLB (Open Cloud, uploads pre-approved) and its forge icons (Studio
upload_image), log every id in tools/uploads.json and art/forge/icons/asset_ids.json, and print the Luau ART rows to paste.
    python "Games/Pixel Depth/spike/ship_picks.py" pk_03:CopperPickaxe pk_04:BogIronPickaxe ...
Run from C:\\Users\\kgsat\\Documents\\Roblox. Studio must be open (icons go through it). Then insert the models with
insert_asset into ServerStorage.Pickaxes and run src/install_pickaxes.luau."""
import json, os, re, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
game = os.path.join(root, "Games", "Pixel Depth")
py_venv = os.path.join(root, "Hunyuan3D", ".venv", "Scripts", "python.exe")
ids_path = os.path.join(game, "art", "forge", "icons", "asset_ids.json")
ids = json.load(open(ids_path))
rows = []
for arg in sys.argv[1:]:
    tag, name = arg.split(":")
    glb = os.path.join(game, "blender", "out", tag, name + ".glb")
    assert os.path.exists(glb), glb
    out = subprocess.run([py_venv, "-I", os.path.join(root, "tools", "upload_asset.py"), glb, "--user", "872430111", "--name", name, "--upload"],
                         capture_output=True, text=True, cwd=root).stdout
    m = re.search(r"asset id (\d+)", out)
    assert m, out[-500:]
    model_id = m.group(1)
    files = [name + ".png", name + "_card.png"]
    for f in files:
        assert os.path.exists(os.path.join(game, "art", "forge", "icons", f)), f
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "img_upload.py"), os.path.join(game, "art", "forge", "icons")] + files,
                       capture_output=True, text=True, cwd=root).stdout
    got = dict(re.findall(r'/([\w]+)\.png":"rbxassetid://(\d+)"', r))
    assert len(got) == 2, r[-500:]
    ids[name], ids[name + "_card"], ids[name + "_model"] = got[name], got[name + "_card"], model_id
    log = json.load(open(os.path.join(root, "tools", "uploads.json")))
    stamp = time.strftime("%Y-%m-%d %H:%M")
    for k in (name, name + "_card"):
        log.append({"file": f"Games/Pixel Depth/art/forge/icons/{k}.png", "type": "Image", "assetId": got[k], "time": stamp})
    if not any(e.get("assetId") == model_id for e in log):
        log.append({"file": f"Games/Pixel Depth/blender/out/{tag}/{name}.glb", "type": "Model", "assetId": model_id, "time": stamp})
    json.dump(log, open(os.path.join(root, "tools", "uploads.json"), "w"), indent=1)
    rows.append(f"\t\t{name} = {{ {got[name]}, {got[name + '_card']} }},")
    print(name, "model", model_id, "icon", got[name], "card", got[name + "_card"])
json.dump(dict(sorted(ids.items())), open(ids_path, "w"), indent=1)
print("\n".join(rows))
