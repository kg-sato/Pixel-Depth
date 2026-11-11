"""Record the core loop in the player's real view (town, ride down, Perfect Strike, Vein Rush, a shrine, Gloomlings, the
escape ride) as one video, then cut it into contact sheets for the Gemini loop grade. Studio open in Edit mode.
    python spike/loop_rec.py <name>     video: captures/loop/<name>.mp4, sheets: <workspace>/Overnight/judge/loop_<name>/
Shortcuts (say so in the grade brief): teleports to the deposits and the shrine, strikes sent through the remote when the
needle crosses the gold, Dev attributes DevBanked and DevTorchAge to bring the Gloomlings."""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
game, ws = here.parent, here.parent.parent.parent
name = sys.argv[1] if len(sys.argv) > 1 else "loop"
VENV = r"C:\Users\kgsat\Documents\Roblox\Hunyuan3D\.venv\Scripts\python.exe"
video = game / "captures" / "loop" / f"{name}.mp4"; video.parent.mkdir(parents=True, exist_ok=True)
sheets = ws / "Overnight" / "judge" / f"loop_{name}"; sheets.mkdir(parents=True, exist_ok=True)
SECS = 215
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
t0 = time.time()
def mark(what): print(f"{time.time() - t0:5.0f} s  {what}", flush=True)
night("play"); time.sleep(3)
rec = subprocess.Popen([VENV, "-I", str(ws / "tools" / "record_window.py"), str(video), str(SECS), "20"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
t0 = time.time(); mark("recording starts: town"); time.sleep(7)
night("key", "Q"); mark("Q: ride down"); time.sleep(26)
mark("minigames (mg_night.py: strike, then rush)")
subprocess.run([sys.executable, str(here / "mg_night.py"), "loop_" + name], capture_output=True, text=True, cwd=here)
time.sleep(3)
night("lua", "Server", P + "local s=workspace.Caves:FindFirstChild('LostLanternSpot',true) h.CFrame=CFrame.new(s.Position+Vector3.new(5,3,5), s.Position) return 1"); mark("teleport: shrine"); time.sleep(7)
night("lua", "Server", P + "p:SetAttribute('DevBanked',true) p:SetAttribute('DevTorchAge',900) return 1"); mark("torch aged: Gloomlings come"); time.sleep(26)
night("lua", "Server", P + "local l=workspace.Caves:FindFirstChild('LiftLanding',true) h.CFrame=l.CFrame+Vector3.new(0,3,0) return 1"); mark("teleport: camp"); time.sleep(6)
night("key", "Q"); mark("Q: escape ride");
left = SECS - (time.time() - t0)
time.sleep(max(left + 4, 4))
print(rec.communicate(timeout=120)[0][-300:])
print("client errors:", night("lua", "Client", "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,140)]=true end end local e={} for k in t do table.insert(e,k) end return table.concat(e,' ## ')"))
night("stop")
r = subprocess.run([VENV, "-I", str(ws / "tools" / "video_sheets.py"), str(video), str(sheets), "2.5"], capture_output=True, text=True)
print([l for l in r.stdout.splitlines() if l.startswith("wrote")][-3:])
