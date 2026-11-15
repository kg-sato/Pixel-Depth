"""Play a forge biography scene in real time three ways (full, fast, skipped) and report the time, errors and clean-up.
    python spike/story_run.py WoodPickaxe "Wood Pickaxe" """
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night as N
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]
model, name = sys.argv[1], sys.argv[2]
RUN = "local S = require(game.ReplicatedStorage.Shared.ForgeStory) local t0 = os.clock() local o = { name = '%s', model = '%s', rarity = { 'Common', 1, Color3.fromRGB(159, 227, 196) }%s } %s local ok, e = pcall(function() return S.play(o) end) return string.format('%%s %%s %%.2fs stage=%%s cam=%%s gui=%%s', tostring(ok), tostring(e), os.clock() - t0, tostring(workspace:FindFirstChild('ForgeStage')), tostring(workspace.CurrentCamera.CameraType), tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('ForgeStoryGui') ~= nil))"
N.play(False); N.restore(); N.play(True); time.sleep(11)
print("full:", C(RUN % (name, model, "", "")))
print("fast:", C(RUN % (name, model, ", fast = true", "")))
print("skip:", C(RUN % (name, model, "", "task.delay(2, function() game:GetService('VirtualInputManager'):SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)")))
print("client errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if (m.messageType==Enum.MessageType.MessageError or string.find(m.message,'ForgeStory')) and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,260) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
