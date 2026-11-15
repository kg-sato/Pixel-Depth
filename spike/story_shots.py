"""Capture a forge biography scene frozen at chosen moments (ForgeStory opt.freeze).
    python spike/story_shots.py WoodPickaxe "Wood Pickaxe" 0.8 1.4 2.2 4.2 ...   -> captures/night/story_<model>_<i>.png
Prints the client errors and whether the stage was cleaned up."""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night as N
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]
model, name = sys.argv[1], sys.argv[2]
times = [float(x) for x in sys.argv[3:]]
PLAY = "task.spawn(function() local ok, e = pcall(function() require(game.ReplicatedStorage.Shared.ForgeStory).play({ name = '%s', model = '%s', rarity = { 'Common', 1, Color3.fromRGB(159, 227, 196) }, freeze = %s, freezeFor = %s }) end) if not ok then warn('STORYERR ' .. tostring(e)) end end) return 1"
N.play(False); N.restore()
N.play(True); time.sleep(11)
for i, d in enumerate(times):
    t0 = time.time(); C(PLAY % (name, model, d, d + 10))
    time.sleep(d + 0.7); N.shot("story_%s_%d" % (model, i)); print(i, d, round(time.time() - t0, 2))
    time.sleep(max(0, d + 18.5 - (time.time() - t0)))
print("client errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if (m.messageType==Enum.MessageType.MessageError or string.find(m.message,'STORYERR') or string.find(m.message,'ForgeStory')) and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,260) end end return #t..' '..table.concat(t,' | ')"))
print("stage left:", C("return tostring(workspace:FindFirstChild('ForgeStage'))"))
N.play(False)
