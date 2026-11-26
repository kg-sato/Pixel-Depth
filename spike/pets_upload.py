"""v16.1: upload rebuilt voxel pets and wire them in. Copies design3d/pets/<src>/<Name>.glb over design3d/pets/out_vox, uploads
each as a Model asset (uploads are pre-approved, tools/upload_asset.py logs them in tools/uploads.json), writes the new ids into
design3d/pets/out_vox/ids.txt and regenerates src/PetRigData.luau (make_rig_lua.py).
    python spike/pets_upload.py <src dir under design3d/pets> Name [Name ...]"""
import pathlib, re, shutil, subprocess, sys
here = pathlib.Path(__file__).resolve().parent
game = here.parent
ws = game.parent.parent
src = game / "design3d" / "pets" / sys.argv[1]
names = sys.argv[2:]
vox = game / "design3d" / "pets" / "out_vox"
ids_f = vox / "ids.txt"
ids = dict(l.split() for l in ids_f.read_text().splitlines() if len(l.split()) == 2)
VENV = ws / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe"
for n in names:
    key = n.replace(" ", "")
    glb = vox / f"{key}.glb"
    shutil.copy(src / f"{key}.glb", glb)
    r = subprocess.run([str(VENV), "-I", str(ws / "tools" / "upload_asset.py"), str(glb), "--user", "872430111", "--name", f"PD pet {n} v16.1", "--upload"], capture_output=True, text=True, cwd=ws)
    m = re.search(r"asset id (\d+)", r.stdout)
    if not m:
        sys.exit(f"upload failed for {n}:\n{r.stdout[-800:]}\n{r.stderr[-800:]}")
    ids[key] = m.group(1)
    print(n, "->", m.group(1), flush=True)
ids_f.write_text("\n".join(f"{k} {v}" for k, v in ids.items()) + "\n")
print(subprocess.run([sys.executable, str(game / "design3d" / "pets" / "make_rig_lua.py")], capture_output=True, text=True, cwd=game).stdout.strip()[-300:])
