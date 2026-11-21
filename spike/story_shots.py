"""Capture a forge biography scene frozen at chosen moments (ForgeStory opt.freeze).
    python spike/story_shots.py WoodPickaxe "Wood Pickaxe" 0.8 1.4 2.2 4.2 ...   -> captures/night/story_<model>_<i>.png
Prints the client errors and whether the stage was cleaned up."""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night as N
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]
model, name = sys.argv[1], sys.argv[2]
times = [float(x) for x in sys.argv[3:]]
PLAY = "task.spawn(function() local ok, e = pcall(function() require(game.ReplicatedStorage.Shared.ForgeStory).play({ name = '%s', model = '%s', rarity = { 'Common', 1, Color3.fromRGB(159, 227, 196) }, freeze = %s, pace = 1, freezeFor = %s }) end) if not ok then warn('STORYERR ' .. tostring(e)) end end) return 1"
N.play(False); N.restore()
N.play(True); time.sleep(11)
for i, d in enumerate(times):
    C("workspace:SetAttribute('ForgeStoryT', -1) workspace:SetAttribute('ForgeStoryEnd', false) return 1")
    t0 = time.time(); C(PLAY % (name, model, d, d + 14))
    at = -1.0
    while time.time() - t0 < d + 12:  # wait on the story's own clock, not on ours: a heavy scene takes seconds to build
        try: at = float(C("return tostring(workspace:GetAttribute('ForgeStoryT') or -1)"))
        except ValueError: at = -1.0
        if at >= d - 0.01: break
        time.sleep(0.25)
    time.sleep(0.6); N.shot("story_%s_%d" % (model, i)); print(i, d, "story", round(at, 2), "after", round(time.time() - t0, 2), "s")
    C("workspace:SetAttribute('ForgeStoryEnd', true) return 1")
    for _ in range(40):  # the scene fades out and gives the place back
        time.sleep(0.4)
        if C("return tostring(workspace:FindFirstChild('ForgeStage'))") == "nil": break
    time.sleep(0.8)
print("client errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if (m.messageType==Enum.MessageType.MessageError or string.find(m.message,'STORYERR') or string.find(m.message,'ForgeStory')) and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[#t+1]=string.sub(m.message,1,260) end end return #t..' '..table.concat(t,' | ')"))
print("stage left:", C("return tostring(workspace:FindFirstChild('ForgeStage'))"))
N.play(False)
