"""One picture per forge model, alone, in three views (front, side, three-quarter back) on a grey stage, for grading it
against its own reference sheet. Uses the test scene ForgeTurn through ForgeStory (Play is started and stopped here).
    python spike/asset_shots.py BoltKit Cabin Spruce1 KitBirch2      -> captures/night/asset_<Model>.png"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night as N
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]
PLAY = "task.spawn(function() local ok, e = pcall(function() require(game.ReplicatedStorage.Shared.ForgeStory).play({ name = 'turn', model = '__turn', turn = '%s', rarity = { 'Common', 1, Color3.fromRGB(159, 227, 196) }, freeze = 1, freezeFor = 7 }) end) if not ok then warn('STORYERR ' .. tostring(e)) end end) return 1"
N.play(False); N.restore()
N.play(True); time.sleep(11)
for name in sys.argv[1:]:
    C(PLAY % name); time.sleep(3.2); N.shot("asset_" + name); time.sleep(6.5)
print("client errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if (m.messageType==Enum.MessageType.MessageError or string.find(m.message,'STORYERR') or string.find(m.message,'ForgeStory')) and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,260) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
