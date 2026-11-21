"""Directive v13 phase 4/5 stills (starts Play): town shoreline, signpost sightline, crew hearth cabins, forge sparks, Camp 1
hearth, a cave vignette, the Clay Caves Jar Gallery.   python spike/p4_shots.py <prefix> [view ...]   -> captures/night/<prefix>_<view>.png
The camera is held by a client RenderStep binding (it outlives the Lua call), the HUD hidden for clean world stills."""
import sys, time
import night as N
pre = sys.argv[1] if len(sys.argv) > 1 else "p4"
want = set(sys.argv[2:])
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
_n = [0]
def aim(pos, at, fov=70, hud=False, signs=False):
    _n[0] += 1
    nm = f"P4Cam{_n[0]}"  # a fresh name each time: an older view's timed unbind must not end this one
    C(f"local RS=game:GetService('RunService') for i=1,{_n[0]} do pcall(function() RS:UnbindFromRenderStep('P4Cam'..i) end) end "
      f"for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') and g.Name~='CrewPlate' then g.Enabled={'true' if hud else 'false'} end end "
      + ("" if signs else "for _,b in workspace:GetDescendants() do if b:IsA('BillboardGui') and b.Name=='CrewSign' then b.Enabled=false end end ") +
      f"local p, a = {pos}, {at} "
      "local ch=game.Players.LocalPlayer.Character for _,d in ch:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 elseif d:IsA('ParticleEmitter') or d:IsA('BillboardGui') or d:IsA('Light') then d.Enabled=false end end "
      f"RS:BindToRenderStep('{nm}', Enum.RenderPriority.Camera.Value+40, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView={fov} cam.CFrame=CFrame.lookAt(p, a) for _,d in cam:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 elseif d:IsA('ParticleEmitter') and d.Enabled then d.Enabled=false d:Clear() end end end) "
      f"task.delay(14, function() pcall(function() RS:UnbindFromRenderStep('{nm}') end) end) return 1")
    time.sleep(1.6)
def shot(name):
    if not want or name in want: N.shot(f"{pre}_{name}")
N.play(True); time.sleep(12)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
V = "Vector3.new"
TOWN = [
    ("shore", f"{V}(-17,7,31)", f"{V}(-9,0.7,40)", 58),  # 2026-11-20: down on the bank over the stream's bend and the bridge
    ("sign", f"{V}(11,13.5,-6.4)", f"{V}(11,4.2,-14)", 50),  # the town camera's own angle (C.CAM_PITCH 52, from the south): the boards tilt up to it
    ("cabins", f"{V}(37,6.5,3)", f"{V}(47.5,3,-1.5)", 64),
    ("forge", f"{V}(-34,17,-6)", f"{V}(-37,4,-22)", 56),  # high from the south like the town camera: the refinery stands in the forge yard (the owner, 2026-11-14)
]
for name, p, a, fov in TOWN:
    if want and name not in want: continue
    aim(p, a, fov); shot(name)
if not want or want & {"hearth", "vignette", "gallery"}:
    C("for i=1,40 do pcall(function() game:GetService('RunService'):UnbindFromRenderStep('P4Cam'..i) end) end game.ReplicatedStorage.Remotes.Surface:FireServer('down') return 1"); time.sleep(16)
    print("in cave:", C("return tostring(game.Players.LocalPlayer:GetAttribute('InCave'))"))
    aim("require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(10,6.5,23)", "require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(-0.5,1.4,11)", 58)  # the campfire is at cell (0, 3): 12 studs south of the origin
    shot("hearth")
    print("vignettes:", S("local v=workspace.Caves:FindFirstChild('Vignettes') return v and v:GetAttribute('Made') or 'none'"))
    h = C("for _,d in workspace.Caves.Vignettes:GetChildren() do if d.Name=='Helmet' then return tostring(d.Position) end end return 'none'")
    if h != "none":
        S(f"local p=game.Players:GetPlayers()[1] p.Character:PivotTo(CFrame.new(Vector3.new({h})+Vector3.new(6,4,6))) return 1"); time.sleep(2)
        aim(f"Vector3.new({h})+Vector3.new(4,3.2,4)", f"Vector3.new({h})", 60); shot("vignette")
    S("local p=game.Players:GetPlayers()[1] local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE2_ORIGIN p.Character:PivotTo(CFrame.new(O+Vector3.new(11,6,-62))) return 1"); time.sleep(3)
    aim("require(game.ReplicatedStorage.Shared.Config).CAVE2_ORIGIN+Vector3.new(24,13,-56)", "require(game.ReplicatedStorage.Shared.Config).CAVE2_ORIGIN+Vector3.new(8,4,-88)", 70)
    shot("gallery")
    if not want or "kilncart" in want:  # directive v13: the Kiln Camp's crew cart and its CREW RIDE sign
        kb = C("local b=workspace.Caves:FindFirstChild('KilnCartBody',true) return b and tostring(b.Position) or 'none'")
        if kb != "none":
            S(f"local p=game.Players:GetPlayers()[1] p.Character:PivotTo(CFrame.new(Vector3.new({kb})+Vector3.new(14,3,10))) return 1"); time.sleep(3)
            C("for _,b in workspace:GetDescendants() do if b:IsA('BillboardGui') and b.Name=='CrewSign' then b.Enabled=true end end return 1")
            aim(f"Vector3.new({kb})+Vector3.new(9,5.5,7)", f"Vector3.new({kb})+Vector3.new(0,3.2,0)", 60, signs=True); shot("kilncart")
C("for i=1,40 do pcall(function() game:GetService('RunService'):UnbindFromRenderStep('P4Cam'..i) end) end for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end return 1")
print("done")
