import sys, time, pathlib
here = pathlib.Path('spike').resolve()
sys.path.insert(0, str(here))
import night as N
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]
PLAY = "task.spawn(function() local ok, e = pcall(function() require(game.ReplicatedStorage.Shared.ForgeCutscene).play({ name = 'Starlight Pickaxe', model = '%s', rarity = { 'LEVEL 2', 1, Color3.fromRGB(255, 127, 208) }, quick = true, freeze = %s }) end) if not ok then warn('ANVILERR ' .. tostring(e)) end end) return 1"
N.play(False); N.restore()
N.play(True); time.sleep(11)
delays = [float(x) for x in sys.argv[1:]] or [0.25, 0.6, 0.8, 0.905, 1.36, 1.69]
for i, d in enumerate(delays):
    t0 = time.time(); C(PLAY % ("CopperPickaxe", d))
    time.sleep(max(0, 9 - (time.time() - t0))); N.shot("anvil_%d" % i); print(i, d, round(time.time() - t0, 2))
    time.sleep(max(0, 23 - (time.time() - t0)))
print("client errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if (m.messageType==Enum.MessageType.MessageError or string.find(m.message,'ANVILERR')) and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,200) end end return #t..' '..table.concat(t,' | ')"))
print("stage left:", C("return tostring(workspace:FindFirstChild('ForgeStage'))"))
N.play(False)
