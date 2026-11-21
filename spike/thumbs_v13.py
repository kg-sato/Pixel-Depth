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
      "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') or g:IsA('BillboardGui') or g:IsA('SurfaceGui') then g.Enabled=false end end for _,b in workspace:GetDescendants() do if b:IsA('BillboardGui') then b.Enabled=false end end "
      f"local p, a = {pos}, {at} "
      f"RS:BindToRenderStep('{nm}', Enum.RenderPriority.Camera.Value+45, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView={fov} cam.CFrame=CFrame.lookAt(p, a) "
      "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') and g.Enabled then g.Enabled=false end end "  # every frame: some layers switch themselves back on (the forge shot kept a purple corner)
      "for _,d in cam:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 elseif d:IsA('ParticleEmitter') and d.Enabled then d.Enabled=false d:Clear() end end "
      "local ch=game.Players.LocalPlayer.Character if ch then for _,d in ch:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 elseif d:IsA('ParticleEmitter') or d:IsA('BillboardGui') or d:IsA('Light') then d.Enabled=false end end end "
      "for _,d in workspace:GetChildren() do if d:IsA('Model') and d:GetAttribute('Pet') ~= nil then d:PivotTo(CFrame.new(0,-900,0)) end end end) "
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
hold("workspace.Hub:FindFirstChild('Anvil',true).Position + ((Vector3.new(0,0,0)-workspace.Hub:FindFirstChild('Anvil',true).Position)*Vector3.new(1,0,1)).Unit*9.5 + Vector3.new(2.5,3.2,0)", "workspace.Hub:FindFirstChild('Anvil',true).Position+Vector3.new(0,1.6,0)", 50); snap("1_forge_arch")  # close on Bolt's anvil and its sparks (Gemini: the high view made the smith a speck)
# 3 a towering boss silhouette (Dredge + Hades): a small miner before the Root Warden, rim-lit
C("game.ReplicatedStorage.Remotes.Surface:FireServer('down') return 1"); time.sleep(16)
S(P + "local w=workspace.Caves:FindFirstChild('Warden',true) local wp=w:GetPivot().Position local f=(wp-require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN)*Vector3.new(1,0,1) h.CFrame=CFrame.lookAt(wp-f.Unit*9+Vector3.new(0,3,0), wp) return 1"); time.sleep(2)
hold("workspace.Caves:FindFirstChild('Warden',true):GetPivot().Position + Vector3.new(math.cos(math.rad(318)),0,math.sin(math.rad(318)))*17 + Vector3.new(0,2.2,0)",  # where a fighter stands (boss_fight_test: 315 degrees): the camp tent stands in front of its face
     "workspace.Caves:FindFirstChild('Warden',true):GetPivot().Position+Vector3.new(0,5,0)", 46); snap("4_boss")
# 5 the campfire clink at Camp 1's hearth (Valheim capsule): the miner by the fire, gold clink sparks
S(P + "h.CFrame=CFrame.new(require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(-26,3,-14)) return 1"); time.sleep(2.5)  # away from Wick: his line bubble shows only near him
S(P + "game.ReplicatedStorage.Remotes.Fx:FireClient(p,'clink',p.UserId,require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(3.5,0.5,13)) return 1")
hold("O1+Vector3.new(13.5,3.4,13.5)", "O1+Vector3.new(6,1.9,8.6)", 50); snap("5_campfire")  # Wick and the fire, close but not in the flames (Gemini: too far, the floor ate the frame)
# 3 the mythic egg rupture (Slime Rancher 2 + Hollow Knight): a Secret hatch frozen on the burst
C("for i=1,20 do pcall(function() game:GetService('RunService'):UnbindFromRenderStep('Thumb'..i) end) end for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=(g.Name~='DailyChest') end end game.Players.LocalPlayer:SetAttribute('DevHatchFreeze', 8.25) return 1")  # the daily chest pops up again on the way home from the crew ride
S("game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', 'Ninering') return 1"); time.sleep(9.2)
C("for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end return 1")
snap("3_hatch")
C("game.Players.LocalPlayer:SetAttribute('DevHatchFreeze', nil) for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end return 1")
# 2 the four-rider crew cart (Deep Rock Galactic + Mario Kart capsule): a crew run seen from ahead of the cart, copies of the
# player fill the empty seats (Studio hooks DevCrewBot: the server drives; DevCrewFill: copies sit in seats 1, 3 and 4)
C("for i=1,20 do pcall(function() game:GetService('RunService'):UnbindFromRenderStep('Thumb'..i) end) end return 1")
S(P + "local body=workspace.Caves:FindFirstChild('CartBody',true) h.CFrame=body.CFrame*CFrame.new(0,3,6) p:SetAttribute('DevCrewFill',true) p:SetAttribute('DevCrewBot','lookout') return 1")
time.sleep(9)
C("local RS=game:GetService('RunService') RS:BindToRenderStep('ThumbCart', Enum.RenderPriority.Last.Value, function() "
  "local w=workspace:FindFirstChild('MinecartEscape') if not w then return end local cart "
  "local best=0 for _,m in w:GetChildren() do if m:IsA('Model') and not m:FindFirstChildOfClass('Humanoid') then local n=0 for _,d in m:GetDescendants() do if d:IsA('BasePart') then n+=1 end end if n>best then best,cart=n,m end end end "
  "if not cart then return end for _,d in w:GetDescendants() do if d:IsA('BasePart') and string.sub(d.Name,1,5)=='Flame' then d.LocalTransparencyModifier=1 elseif d:IsA('ParticleEmitter') then d.Enabled=false end end local cam=workspace.CurrentCamera local c=cart:GetPivot() "
  "cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView=58 cam.CFrame=CFrame.lookAt((c*CFrame.new(0.6,4.3,-6.2)).Position,(c*CFrame.new(0,3.1,0.8)).Position) "
  "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end end) "
  "task.delay(6, function() pcall(function() RS:UnbindFromRenderStep('ThumbCart') end) end) return 1")
time.sleep(2.0)
snap("2_crew_cart")
S(P + "p:SetAttribute('DevCrewFill',nil) return 1")
time.sleep(30)  # the run ends and the player is home in town
print("done")
