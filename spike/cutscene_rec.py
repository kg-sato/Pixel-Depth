"""Record every forge biography cutscene back to back as one video in the player's view (Play running, real time).
    python spike/cutscene_rec.py <name>     video: captures/loop/<name>.mp4, sheets: <workspace>/Overnight/judge/cut_<name>/
Studio open in Edit mode (not minimised). Each scene is started by script with ForgeStory.play (the same call the forge uses)."""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
game, ws = here.parent, here.parent.parent.parent
sys.path.insert(0, str(here))
import night as N
name = sys.argv[1] if len(sys.argv) > 1 else "cutscenes"
VENV = r"C:\Users\kgsat\Documents\Roblox\Hunyuan3D\.venv\Scripts\python.exe"
video = game / "captures" / "loop" / f"{name}.mp4"; video.parent.mkdir(parents=True, exist_ok=True)
sheets = ws / "Overnight" / "judge" / f"cut_{name}"; sheets.mkdir(parents=True, exist_ok=True)
SCENES = [("WoodPickaxe", "Wood Pickaxe"), ("StonePickaxe", "Stone Pickaxe"), ("AshcoalPickaxe", "Ashcoal Pickaxe"),
          ("CopperPickaxe", "Kobold-Copper Pickaxe"), ("BogIronPickaxe", "Bog-Iron Pickaxe"), ("RootheartPickaxe", "Rootheart Pickaxe"),
          ("MossbackPickaxe", "Mossback Pickaxe"), ("KilnPickaxe", "Kiln Pickaxe"), ("RuneTinPickaxe", "Rune-Tin Pickaxe"),
          ("GeodePickaxe", "Geode Pickaxe"), ("FossilPickaxe", "Fossil Pickaxe"), ("TitanHammerPickaxe", "Titan Hammer Pickaxe")]
RUN = ("local S = require(game.ReplicatedStorage.Shared.ForgeStory) local ok, e = pcall(function() return S.play({ name = '%s', model = '%s', "
       "rarity = { 'Common', 1, Color3.fromRGB(159, 227, 196) } }) end) return tostring(ok) .. ' ' .. tostring(e)")
N.play(False); N.restore(); N.play(True); time.sleep(12)
secs = 26 * len(SCENES) + 6  # a scene takes about 25 s with the call overhead
if video.exists(): video.unlink()
rec = subprocess.Popen([VENV, "-I", str(ws / "tools" / "record_window.py"), str(video), str(secs), "30"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
t0 = time.time(); time.sleep(1.0)
for model, title in SCENES:
    at = time.time() - t0
    r = (N.lua(RUN % (title, model), "Client").splitlines() or ["?"])[-1]  # yields until the scene ends (about 19.5 s)
    print(f"{at:6.1f} s  {model}: {r}", flush=True)
print(rec.communicate(timeout=240)[0][-300:])
print("client errors:", (N.lua("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[string.sub(m.message,1,160)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' | ')", "Client").splitlines() or ["?"])[-1])
N.play(False)
r = subprocess.run([VENV, "-I", str(ws / "tools" / "video_sheets.py"), str(video), str(sheets), "3"], capture_output=True, text=True)
print([l for l in r.stdout.splitlines() if l.startswith("wrote")][-3:])
