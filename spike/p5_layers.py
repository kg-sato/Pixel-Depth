"""Landmark stills of the Cave v2 deep layers (Play must be running): builds each layer's preview like cavev2_shots.py, then
frames its v13 landmarks (layer 2: the Titan's face, drapery, a glow-pebble trail; layer 3: the diagonal crystal ribs, an
obsidian pool; layer 4: the magma lake grate walk, Causeway steps).   python spike/p5_layers.py <tag> [seed]
-> captures/night/<tag>_L<layer>_<landmark>.png"""
import sys, time
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "lm"
seed = sys.argv[2] if len(sys.argv) > 2 else "7"
LM = {2: [("TitanFace", 26, 10), ("Drapery", 14, -4), ("GlowPebble", 9, 4)], 3: [("CrystalRib", 30, 6), ("ObsidianPool", 13, 6)], 4: [("GrateSlat", 22, 9), ("CausewayStep", 14, 6), ("MagmaLake", 34, 14)]}
_n = [0]
for L, marks in LM.items():
    print(N.lua("local C=require(game.ReplicatedStorage.Shared.Config) local o=workspace:FindFirstChild('CavesV2') if o then o:Destroy() end "
                f"local m=require(game.ServerScriptService.CaveV2).build(workspace, C.CAVE_V2_ORIGIN, {seed}, {{ layer = {L} }}) pcall(function() require(game.ServerScriptService.CaveProps).build(m) end) "
                "local p=game.Players:GetPlayers()[1] p.Character.HumanoidRootPart.Anchored=true p.Character:PivotTo(CFrame.new(C.CAVE_V2_ORIGIN+Vector3.new(0,40,0))) return m:GetAttribute('Parts')", "Server").splitlines()[-1])
    time.sleep(3)
    for name, dist, up in marks:
        _n[0] += 1
        nm = f"LM{_n[0]}"
        r = N.lua("local RS=game:GetService('RunService') for i=1,60 do pcall(function() RS:UnbindFromRenderStep('LM'..i) end) end "
                  f"local m=workspace:FindFirstChild('CavesV2') local t for _,d in m:GetDescendants() do if d.Name=='{name}' and d:IsA('BasePart') then t=d break end end if not t then return 'none' end "
                  "local C=require(game.ReplicatedStorage.Shared.Config) local c=C.CAVE_V2_ORIGIN local fl=(c-t.Position)*Vector3.new(1,0,1) fl=fl.Magnitude>1 and fl.Unit or Vector3.xAxis "
                  f"local p=t.Position+fl*{dist}+Vector3.new(0,{up},0) local a=t.Position "
                  "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end "
                  "local torch=workspace:FindFirstChild('LMTorch') or Instance.new('Part') torch.Name='LMTorch' torch.Anchored=true torch.CanCollide=false torch.Transparency=1 torch.Size=Vector3.one torch.Parent=workspace "
                  "local tl=torch:FindFirstChildOfClass('PointLight') or Instance.new('PointLight', torch) tl.Color=Color3.fromRGB(255,190,120) tl.Range=40 tl.Brightness=1 tl.Shadows=true torch.Position=p "
                  f"RS:BindToRenderStep('{nm}', Enum.RenderPriority.Camera.Value+40, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView=75 cam.CFrame=CFrame.lookAt(p, a) "
                  "for _,d in cam:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 end end end) "
                  f"task.delay(10, function() pcall(function() RS:UnbindFromRenderStep('{nm}') end) end) return tostring(t.Position)", "Client").splitlines()[-1]
        print(L, name, r)
        if r == "none": continue
        time.sleep(1.6)
        N.shot(f"{tag}_L{L}_{name}")
N.lua("for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end return 1", "Client")
print("done")
