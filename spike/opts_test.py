"""Are the settings saved? Starts Play, sends settings through the Opts remote, sends bad input, reads what the server kept,
then tests the load path with the Studio hook DevOpts (Studio itself saves nothing).   python spike/opts_test.py"""
import time
import night as N
C1 = lambda code: N.lua(code, "Client").splitlines()[-1]
S1 = lambda code: N.lua(code, "Server").splitlines()[-1]
KEPT = "local HS=game:GetService('HttpService') local got local R=game.ReplicatedStorage.Remotes.Opts local con=R.OnClientEvent:Connect(function(o) got=o end) task.wait(0.3) R:FireServer('get') task.wait(0.8) con:Disconnect() return got and HS:JSONEncode(got) or 'no answer'"
N.play(True); time.sleep(8)
C1("game.ReplicatedStorage.Remotes.Opts:FireServer({vol=3,shake=false,hints=true,dark=true}) return 1"); time.sleep(0.5)
print("kept after a good send:", C1(KEPT))
C1("local R=game.ReplicatedStorage.Remotes.Opts R:FireServer({vol=1e9,shake='no',gold=999999,dark=true,hints={}}) return 1"); time.sleep(0.5)
print("kept after a bad send:", C1(KEPT))
C1("game.ReplicatedStorage.Remotes.Opts:FireServer(12345) return 1"); time.sleep(0.5)
print("kept after a number:", C1(KEPT))
N.play(False); time.sleep(4)
# Studio saves nothing ("Roblox API services unavailable"), so a real rejoin cannot be tested here. The load path is tested with
# the Studio hook DevOpts (a workspace attribute set in Edit mode): the server reads it as the saved settings.
N.lua('workspace:SetAttribute("DevOpts",[[{"vol":3,"shake":false,"hints":true,"dark":true,"gold":5}]]) return 1', "Edit")
N.play(True); time.sleep(10)
print("loaded on join:", C1("local p=game.Players.LocalPlayer local g=game:GetService('SoundService'):FindFirstChild('PixelMaster') return 'NoShake '..tostring(p:GetAttribute('NoShake'))..' DevLowLight '..tostring(p:GetAttribute('DevLowLight'))..' volume '..tostring(g and math.floor(g.Volume*10+0.5))"))
print("server holds:", C1(KEPT))
N.play(False); time.sleep(3)
N.lua("workspace:SetAttribute('DevOpts',nil) return 1", "Edit")
print("hook cleared:", N.lua("return tostring(workspace:GetAttribute('DevOpts'))", "Edit").splitlines()[-1])
