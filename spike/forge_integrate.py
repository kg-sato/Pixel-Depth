"""Take a drafted forge scene into the game: upload its sky pictures, fill the ID_<scene>_<look>_<side|up|dn> placeholders,
register it in ForgeStory.SCENES and log the ids.
    python integrate.py <scene> <PickaxeModel> <Module> <look> [<look> ...]     e.g.  ashcoal AshcoalPickaxe ForgeAshcoal dusk night dawn
Works on the repo copy of src/<Module>.luau (the drafting worker's file) and mirrors it and ForgeStory.luau back to the scratchpad."""
import io, json, re, shutil, subprocess, sys, pathlib
scene, model, module, looks = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
R = pathlib.Path("C:/Users/kgsat/Documents/Roblox"); G = R / "Games" / "Pixel Depth"
S = G
ap = G / "design3d" / "assets.json"; assets = json.loads(ap.read_text(encoding="utf-8"))
names = [f"{scene}_sky_{l}_{k}.png" for l in looks for k in ("side", "up", "dn")]
need = [n for n in names if n not in assets]
if need:
    r = subprocess.run([sys.executable, str(R / "tools" / "img_upload.py"), str(G / "design3d" / "tex")] + need, capture_output=True, text=True, cwd=R)
    got = json.loads(re.search(r"\{.*\}", r.stdout, re.S).group(0))
    for url, rid in got.items(): assets[url.rsplit("/", 1)[1]] = rid.replace("rbxassetid://", "")
    ap.write_text(json.dumps(assets, indent=2), encoding="utf-8")
missing = [n for n in names if n not in assets]
if missing: sys.exit("not uploaded: " + ", ".join(missing))
p = G / "src" / f"{module}.luau"; s = io.open(p, encoding="utf-8").read()
for l in looks:
    for k in ("side", "up", "dn"):
        s = s.replace(f"ID_{scene}_{l}_{k}", assets[f"{scene}_sky_{l}_{k}.png"])
left = sorted(set(re.findall(r"ID_[A-Za-z0-9_]+", s)))
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
pass
t = S / "src" / "ForgeStory.luau"; s = io.open(t, encoding="utf-8").read()
if f'{model} = "{module}"' not in s:
    a = 'WoodPickaxe = "ForgeWood",'
    assert s.count(a) == 1
    s = s.replace(a, a + f' {model} = "{module}",')
    io.open(t, "w", encoding="utf-8", newline="\n").write(s)
pass
print("integrated", scene, "placeholders left:", left)
