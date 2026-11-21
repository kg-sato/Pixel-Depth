"""Upload audio/sfx/cave/*.wav (directive v13) through tools/upload_asset.py and keep the ids in audio/sfx/cave/asset_ids.json.
Skips files already in the json. Uploads are pre-approved (the owner, 2026-10-28); each id is also logged in tools/uploads.json."""
import json, os, re, subprocess, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[3]
d = pathlib.Path(__file__).resolve().parent / "sfx" / "cave"
ids_p = d / "asset_ids.json"
ids = json.loads(ids_p.read_text()) if ids_p.exists() else {}
py = root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe"
for f in sorted(d.glob("*.wav")):
    if f.stem in ids: continue
    r = subprocess.run([str(py), "-I", str(root / "tools" / "upload_asset.py"), str(f), "--user", "872430111", "--name", "PD Cave " + f.stem, "--upload"], capture_output=True, text=True, cwd=root, timeout=600)
    m = re.findall(r"\b(\d{9,})\b", r.stdout)
    if r.returncode == 0 and m:
        ids[f.stem] = m[-1]; ids_p.write_text(json.dumps(ids, indent=1)); print(f.stem, m[-1], flush=True)
    else:
        print("FAILED", f.stem, (r.stdout + r.stderr)[-300:], flush=True)
