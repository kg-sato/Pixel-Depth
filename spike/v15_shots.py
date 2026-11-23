"""Master Directive v15 stills: the Deep Chronicle, the refinery crucible (cold, melting, stirred), the constellation Soul Tree
and the crimson shatter of the grab card.   python spike/v15_shots.py <tag>   -> captures/night/v15_<tag>_<view>.png"""
import pathlib, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
from prompt_test import trigger
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
def S(c): return (N.lua(c, "Server").splitlines() or ["?"])[-1]
def C(c): return (N.lua(c, "Client").splitlines() or ["?"])[-1]
def cam(eye, at, secs=7, hide_gui=False):  # a camera held by script for `secs` (bound after the game's own camera step)
    return C("local RS=game:GetService('RunService') _G.V15N=(_G.V15N or 0)+1 local nm='V15Cam'.._G.V15N for i=1,_G.V15N-1 do pcall(function() RS:UnbindFromRenderStep('V15Cam'..i) end) end "  # a fresh name each time: an old camera's timer unbound the new one
             + ("for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end " if hide_gui else "")
             + f"local eye,at={eye},{at} RS:BindToRenderStep(nm, 2000, function() local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(eye,at) end) "
             f"task.delay({secs}, function() pcall(function() RS:UnbindFromRenderStep(nm) end) workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end) return 1")
def shot(view): print(view, N.shot(f"v15_{tag}_{view}").name, flush=True)
N.play(False); N.play(True); time.sleep(10)
# A the Deep Chronicle
CH = "local m=workspace.Hub.Chronicle local s=m.ChronicleSlab "
print("rows:", S(CH + "task.wait(7) return m:GetAttribute('Rows')"))
S(P + CH + "h.CFrame=CFrame.lookAt((s.CFrame*CFrame.new(0,-4.2,7)).Position,(s.CFrame*CFrame.new(0,-4.2,0)).Position) return 1"); time.sleep(1)  # a miner reading the stone stands in front of it (RoofFade fades a slab between the camera and the miner)
cam("(s.CFrame*CFrame.new(0,-1.5,13)).Position".replace("s.", "workspace.Hub.Chronicle.ChronicleSlab."), "workspace.Hub.Chronicle.ChronicleSlab.Position+Vector3.new(0,-0.5,0)")
time.sleep(1.2); shot("chronicle")
cam("(workspace.Hub.Chronicle.ChronicleSlab.CFrame*CFrame.new(-10,9,34)).Position", "workspace.Hub.Chronicle.ChronicleSlab.Position")
time.sleep(1.2); shot("chronicle_far")
# B the crucible: cold, then a job, then stirred
CR = "workspace.Hub:FindFirstChild('CrucibleMelt',true)"
S(P + "local m=workspace.Hub.RefineryMouth h.CFrame=CFrame.lookAt(m.Position+m.CFrame.LookVector*-3.5+Vector3.new(0,2,0),m.Position) return 1"); time.sleep(1)  # in front of the firebox (the mouth's front is its -Z)
print("cam:", cam(f"({CR}.CFrame*CFrame.new(0,5.5,-7.5)).Position", f"{CR}.Position"))
time.sleep(1.2); shot("crucible_cold")
S(P + "p:SetAttribute('DevGeodes',2) return 1"); time.sleep(0.6)
print("start:", C("local pr=workspace.Hub.RefineryMouth:FindFirstChildOfClass('ProximityPrompt') local c=workspace.CurrentCamera c.CFrame=CFrame.lookAt(c.CFrame.Position,pr.Parent.Position) task.wait(0.6) pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() task.wait(1) return tostring(game.Players.LocalPlayer:GetAttribute('RefineAt'))"))
cam(f"({CR}.CFrame*CFrame.new(0,5.5,-7.5)).Position", f"{CR}.Position")
time.sleep(2.5); shot("crucible_hot")
S(P + "p:SetAttribute('DevRefine',8) return 1"); time.sleep(5)
cam(f"({CR}.CFrame*CFrame.new(0,5.5,-7.5)).Position", f"{CR}.Position")
time.sleep(1); shot("crucible_late")
S(P + "p:SetAttribute('DevRefine',40) return 1"); time.sleep(1.5)
print("stir prompt on:", C("local pt=workspace.Hub:FindFirstChild('CrucibleStirPoint',true) return tostring(pt:FindFirstChildOfClass('ProximityPrompt').Enabled)"))
print("stir:", C("local pt=workspace.Hub:FindFirstChild('CrucibleStirPoint',true) local pr=pt:FindFirstChildOfClass('ProximityPrompt') local c=workspace.CurrentCamera c.CFrame=CFrame.lookAt(c.CFrame.Position,pt.Position) task.wait(0.6) local a0=game.Players.LocalPlayer:GetAttribute('RefineAt') pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() task.wait(0.8) local a1=game.Players.LocalPlayer:GetAttribute('RefineAt') return string.format('%.1f s earlier, stirred=%s, prompt=%s', (a0 or 0)-(a1 or 0), tostring(game.Players.LocalPlayer:GetAttribute('RefineStirred')), tostring(pr.Enabled))"))
cam(f"({CR}.CFrame*CFrame.new(0,5.5,-7.5)).Position", f"{CR}.Position")
time.sleep(0.4); shot("crucible_stir")
# D the crimson shatter on the grab card
S(P + "game.ReplicatedStorage.Remotes.Fx:FireClient(p,'grabbed',5) return 1"); time.sleep(0.9)
shot("grab_shatter")
time.sleep(6)
# C the Soul Tree
N.lua("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1", "Client")
N.key("Q"); time.sleep(28)  # the shrine's buys only count at Camp 1's fire (SoulTree checks the campfire)
S(P + "p:SetAttribute('DevSoul',20) return 1"); time.sleep(1.5)  # the ride lands at Camp 1 beside the fire
S("local R=game.ReplicatedStorage.Remotes return 1")
print("open:", trigger("SoulTree", "true")); time.sleep(2)  # walks to the campfire prompt: buys only count there
shot("soul_open")
C("game.ReplicatedStorage.Remotes.Soul:FireServer('buy','hide') task.wait(0.8) game.ReplicatedStorage.Remotes.Soul:FireServer('buy','flare') task.wait(0.8) game.ReplicatedStorage.Remotes.Soul:FireServer('buy','hide') task.wait(1) game.Players.LocalPlayer:SetAttribute('DevSoulPick','hide') return 1")
time.sleep(1.5); shot("soul_bought")
C("game.Players.LocalPlayer:SetAttribute('DevSoulPick','shield') return 1"); time.sleep(1); shot("soul_shield")
C("game.Players.LocalPlayer:SetAttribute('DevOpen',nil) local w=game.Players.LocalPlayer.PlayerGui:FindFirstChild('SoulTree',true) if w then w.Visible=false end return 1"); time.sleep(1)
print("done")
