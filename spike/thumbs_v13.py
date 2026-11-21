"""Directive v13 phase 8: five UI-free discovery thumbnail stills for Roblox Thumbnail Personalization, one per archetype in
vault Research/Game Design/FTUE, Co-Op Chemistry and Economy Pacing (2026-11-20) section 3.D (starts Play).
    python spike/thumbs_v13.py <prefix>   -> captures/thumbs/<prefix>_<n>_<name>.png (16:9 crops)
The camera is held by a client RenderStep binding with a fresh name per view; every ScreenGui is off while it holds."""
import sys, time
from PIL import Image
import night as N
pre = sys.argv[1] if len(sys.argv) > 1 else "v13"
out = N.game / "captures" / "thumbs"; out.mkdir(parents=True, exist_ok=True)
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
_n = [0]
def hold(pos, at, fov=60, secs=16):
    _n[0] += 1
    nm = f"Thumb{_n[0]}"
    C("local RS=game:GetService('RunService') local C=require(game.ReplicatedStorage.Shared.Config) local O1,O2=C.CAVE_ORIGIN,C.CAVE2_ORIGIN "
      f"for i=1,{_n[0]} do pcall(function() RS:UnbindFromRenderStep('Thumb'..i) end) end "
      "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end "
      f"local p, a = {pos}, {at} "
      f"RS:BindToRenderStep('{nm}', Enum.RenderPriority.Camera.Value+45, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView={fov} cam.CFrame=CFrame.lookAt(p, a) "
      "for _,d in cam:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 end end end) "
      f"task.delay({secs}, function() pcall(function() RS:UnbindFromRenderStep('{nm}') end) end) return 1")
    time.sleep(1.5)
def snap(name):
    N.shot(f"thumb_{pre}_{name}")
    im = Image.open(N.out / f"thumb_{pre}_{name}.png").convert("RGB"); w, h = im.size
    cw = min(w, int(h * 16 / 9)); im.crop(((w - cw) // 2, 0, (w + cw) // 2, h)).save(out / f"{pre}_{name}.png")
    print("saved", name, flush=True)
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
N.play(True); time.sleep(12)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
# 1 the cozy forge and the glowing mine arch (Core Keeper capsule): the miner by Bolt's anvil sparks, the lit shaft behind
S(P + "local a=workspace.Hub:FindFirstChild('Anvil',true) h.CFrame=CFrame.lookAt(a.Position+Vector3.new(3,1,4), Vector3.new(0,a.Position.Y,0)) return 1"); time.sleep(2)
hold("workspace.Hub:FindFirstChild('Anvil',true).Position+Vector3.new(-5,3.2,9)", "Vector3.new(0,4,0)", 58); snap("1_forge_arch")
# 3 a towering boss silhouette (Dredge + Hades): a small miner before the Root Warden, rim-lit
C("game.ReplicatedStorage.Remotes.Surface:FireServer('down') return 1"); time.sleep(16)
S(P + "local w=workspace.Caves:FindFirstChild('Warden',true) local wp=w:GetPivot().Position local f=(wp-require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN)*Vector3.new(1,0,1) h.CFrame=CFrame.lookAt(wp-f.Unit*9+Vector3.new(0,3,0), wp) return 1"); time.sleep(2)
hold("workspace.Caves:FindFirstChild('Warden',true):GetPivot().Position - ((workspace.Caves:FindFirstChild('Warden',true):GetPivot().Position-O1)*Vector3.new(1,0,1)).Unit*16 + Vector3.new(2,1.5,0)",
     "workspace.Caves:FindFirstChild('Warden',true):GetPivot().Position+Vector3.new(0,6,0)", 62); snap("4_boss")
# 5 the campfire clink at Camp 1's hearth (Valheim capsule): the miner by the fire, gold clink sparks
S(P + "h.CFrame=CFrame.lookAt(require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(4.5,3,3), require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(0,3,0)) return 1"); time.sleep(1.5)
S(P + "game.ReplicatedStorage.Remotes.Fx:FireClient(p,'clink',p.UserId,h.Position) return 1")
hold("O1+Vector3.new(-6,4.5,-7)", "O1+Vector3.new(2,3,1.5)", 56); snap("5_campfire")
# 3 the mythic egg rupture (Slime Rancher 2 + Hollow Knight): a Secret hatch frozen on the burst
C("for i=1,20 do pcall(function() game:GetService('RunService'):UnbindFromRenderStep('Thumb'..i) end) end for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end game.Players.LocalPlayer:SetAttribute('DevHatchFreeze', 8.25) return 1")
S("game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', 'Ninering') return 1"); time.sleep(9.2)
C("for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end return 1")
snap("3_hatch")
C("game.Players.LocalPlayer:SetAttribute('DevHatchFreeze', nil) for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end return 1")
print("done (2, the four-rider cart, needs a crew of real players: taken from the crew test)")
