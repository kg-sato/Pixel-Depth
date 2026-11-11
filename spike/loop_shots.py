"""The core loop as a sequence of Studio screenshots (for nights when the display sleeps and tools/record_window.py only
returns a frozen frame). Same route as loop_rec.py: town, ride down, Perfect Strike, Vein Rush, a shrine, Gloomlings, the
escape ride, town. Writes labelled contact sheets to <workspace>/Overnight/judge/loopshots_<name>/sheet_N.jpg.
    python spike/loop_shots.py <name>"""
import pathlib, shutil, subprocess, sys, time
from PIL import Image, ImageDraw
here = pathlib.Path(__file__).resolve().parent
game, ws = here.parent, here.parent.parent.parent
name = sys.argv[1] if len(sys.argv) > 1 else "s1"
out = ws / "Overnight" / "judge" / f"loopshots_{name}"; out.mkdir(parents=True, exist_ok=True)
cap = game / "captures" / "night"
sys.path.insert(0, str(here))
from prompt_test import SAFE  # a standing point with floor under it: a fixed offset by the shrine dropped the player out of the map
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
frames, t0 = [], time.time()
def shot(label):
    n = f"ls_{name}_{len(frames):02d}"
    night("shot", n); frames.append((cap / f"{n}.png", f"{time.time() - t0:4.0f}s {label}"))
def series(label, count, gap):
    for _ in range(count): shot(label); time.sleep(gap)
night("play"); time.sleep(4); t0 = time.time()
series("town start", 2, 1.5)
night("key", "Q"); series("ride down", 6, 2.6)
time.sleep(4); shot("camp 1 arrival")
subprocess.run([sys.executable, str(here / "mg_night.py"), "lsmg"], capture_output=True, text=True, cwd=here)
for k in ("strike", "strike_hit", "result", "rush_start", "rush_mid", "rush_result"):
    f = cap / f"lsmg_{k}.png"
    if f.exists(): frames.append((f, f"minigame: {k}"))
time.sleep(2.5); shot("after the minigames")
night("lua", "Server", SAFE + P + "local s=workspace.Caves:FindFirstChild('LostLanternSpot',true) h.CFrame=CFrame.new(safe(s.Position), s.Position) return 1"); time.sleep(2.5); shot("at a shrine")
night("lua", "Server", P + "p:SetAttribute('DevBanked',true) p:SetAttribute('DevTorchAge',900) return 1")
series("Gloomlings (torch out)", 9, 1.4)
night("lua", "Server", P + "local l=workspace.Caves:FindFirstChild('LiftLanding',true) h.CFrame=l.CFrame+Vector3.new(0,3,0) return 1"); time.sleep(4); shot("back at camp 1")
night("key", "Q"); series("escape ride", 16, 1.9)
time.sleep(6); series("town after the escape", 3, 2.5)
print("client errors:", night("lua", "Client", "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,140)]=true end end local e={} for k in t do table.insert(e,k) end return table.concat(e,' ## ')"))
night("stop")
W = 480
for s in range(0, len(frames), 16):
    chunk = frames[s:s + 16]
    ims = [Image.open(f).convert("RGB") for f, _ in chunk]
    ims = [i.resize((W, int(i.height * W / i.width))) for i in ims]
    h = ims[0].height + 16
    sheet = Image.new("RGB", (W * 4, h * 4), (0, 0, 0))
    for k, im in enumerate(ims):
        x, y = (k % 4) * W, (k // 4) * h
        sheet.paste(im, (x, y + 16)); ImageDraw.Draw(sheet).text((x + 4, y + 2), chunk[k][1], fill=(255, 255, 0))
    sheet.save(out / f"sheet_{s // 16 + 1}.jpg", quality=84)
print(len(frames), "frames ->", out)
