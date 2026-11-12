"""Capture the grading set for the glass + gameplay night pass (one picture per demo-audit item). Stops and restarts Play.
    python spike/grade_night.py <round>      captures go to captures/grade_<round>/NN_name.png
Items: 01 left column, 02 survival talisman, 03 modal blur, 04 radar, 05 loot card (no prompts), 06 perfect strike, 07 vein rush,
08 ore icon, 09 lanterns (cave, town), 10 cave ceiling, 11 town sheen, 12 escape tunnel, 13 forge moon, 14 cart and station,
15 pickaxe hand, 16 wardrobe."""
import sys, time, pathlib
import night as N

rnd = sys.argv[1]
only = sys.argv[2].split(",") if len(sys.argv) > 2 else None
N.out = N.game / "captures" / f"grade_{rnd}"; N.out.mkdir(parents=True, exist_ok=True)
P = 'local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart '
def want(k): return only is None or k in only
def C(code): return N.lua(code, "Client").splitlines()[-1:]
def S(code): return N.lua(code, "Server").splitlines()[-1:]
CAM = ('local RS=game:GetService("RunService") local cam=workspace.CurrentCamera pcall(function() RS:UnbindFromRenderStep("NightCam") end) '
       'local off={} if %s then for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA("ScreenGui") and g.Enabled then g.Enabled=false table.insert(off,g) end end end '
       'local vmp={} for _,d in cam:GetDescendants() do if d:IsA("BasePart") and d.LocalTransparencyModifier<1 then d.LocalTransparencyModifier=1 table.insert(vmp,d) end end '
       'RS:BindToRenderStep("NightCam", Enum.RenderPriority.Camera.Value+40, function() cam.CameraType=Enum.CameraType.Scriptable %s end) '
       'task.delay(%s, function() RS:UnbindFromRenderStep("NightCam") for _,g in off do g.Enabled=true end for _,d in vmp do d.LocalTransparencyModifier=0 end if game.Players.LocalPlayer:GetAttribute("InCave") then cam.CameraType=Enum.CameraType.Custom end end) return 1')
def cam(body, secs=2.5, hide=True): C(CAM % ("true" if hide else "false", body, secs))
def near_deposit(which, dist=6):
    return S(P + "local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do if (" + which + ") and d.PrimaryPart.Transparency<1 then "
             "local m=(d.PrimaryPart.Position-Vector3.new(-3000,0,0)).Magnitude if not bd or m<bd then best,bd=d,m end end end if not best then return 'none' end "
             "local c=best.PrimaryPart local at=c.Position-c.CFrame.LookVector*Vector3.new(1,0,1)*" + str(dist) + "+Vector3.new(0,3,0) "
             "h.CFrame=CFrame.lookAt(at,Vector3.new(c.Position.X,at.Y,c.Position.Z)) return best:GetAttribute('OreName')")
def face():
    C("local c=workspace.CurrentCamera local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do local m=(d.PrimaryPart.Position-c.CFrame.Position).Magnitude "
      "if not bd or m<bd then best,bd=d,m end end c.CFrame=CFrame.lookAt(c.CFrame.Position,best.PrimaryPart.Position) return bd")
    time.sleep(0.5)
STRIKE = ("local hud=game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.PerfectStrike local nd,ar=hud:FindFirstChild('Needle',true),hud:FindFirstChild('Arc',true) "
          "local t0=os.clock() while os.clock()-t0<3 do if math.abs((nd.Rotation-ar.Rotation+180)%360-180)<5 then break end task.wait() end "
          "game.ReplicatedStorage.Remotes.Extract:FireServer('strike',workspace:GetServerTimeNow()) return 1")

N.play(False); time.sleep(1); N.play(True)
# --- town
if want("11"):
    cam('cam.FieldOfView=50 cam.CFrame=CFrame.lookAt(Vector3.new(-10,16,44),Vector3.new(-16,1,22))'); time.sleep(1.2); N.shot("11_town_sheen"); time.sleep(1.6)
if want("09"):
    cam('cam.FieldOfView=32 cam.CFrame=CFrame.lookAt(Vector3.new(31,5.5,21),Vector3.new(25.5,3,12))'); time.sleep(1.2); N.shot("09b_town_lantern"); time.sleep(1.6)
if want("14"):
    cam('local c=workspace.Hub:FindFirstChild("HubCart",true) local b=c:GetPivot() cam.FieldOfView=45 cam.CFrame=CFrame.lookAt((b*CFrame.new(6,5,-7)).Position,(b*CFrame.new(0,1.6,0)).Position)'); time.sleep(1.2); N.shot("14a_town_cart"); time.sleep(1.6)
if want("16"):
    C('game.ReplicatedStorage.Remotes.Wear:FireServer("set","hat","helmet") task.wait(0.2) game.ReplicatedStorage.Remotes.Wear:FireServer("set","outfit","scarf") task.wait(0.2) game.ReplicatedStorage.Remotes.Wear:FireServer("set","face","goggles") return 1')
    time.sleep(0.6); N.key("V"); time.sleep(1.4); N.shot("16_wardrobe"); N.key("V"); time.sleep(0.6)
if want("13"):
    C('task.spawn(function() require(game.ReplicatedStorage.Shared.ForgeCutscene).play({ name = "Moonlit Pickaxe", model = "MoonlitPickaxe", rarity = { "Epic", 1, Color3.fromRGB(190,150,255) }, sfx = function() end }) end) return 1')
    time.sleep(1.7); N.shot("13_forge_moon"); time.sleep(8)
# --- the ride down and the caves
N.key("Q"); time.sleep(5.2)
if want("14"): N.shot("14c_ride")
time.sleep(10.5)
if want("14"):
    cam('local body=workspace.Caves:FindFirstChild("CartBody",true) local st=body.CFrame*CFrame.new(0,-1.65,-3) cam.FieldOfView=60 cam.CFrame=CFrame.lookAt((st*CFrame.new(9,6,9)).Position,(st*CFrame.new(1,1.8,2)).Position)'); time.sleep(1.2); N.shot("14b_camp_cart_station"); time.sleep(1.6)
if want("09"):
    cam('local sm=workspace.Caves.Camp:FindFirstChild("SmudgeEye") local l,ld for _,o in workspace.Caves.Camp:GetChildren() do if o.Name=="Lantern" then local d=sm and (o.Position-sm.Position).Magnitude or 0 if not ld or d>ld then l,ld=o,d end end end cam.FieldOfView=45 cam.CFrame=CFrame.lookAt(l.Position+Vector3.new(3.5,0.5,5),l.Position-Vector3.new(0,1,0))'); time.sleep(1.2); N.shot("09a_cave_lantern"); time.sleep(1.6)
if want("10"):
    S(P + 'h.CFrame=CFrame.new(require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(6,4,10)) return 1'); time.sleep(1.5)
    C('local c=workspace.CurrentCamera c.CFrame=CFrame.lookAt(c.CFrame.Position,c.CFrame.Position+Vector3.new(0.6,1,0.3)) return 1'); time.sleep(0.6); N.shot("10_cave_ceiling")
if want("01") or want("04") or want("15"):
    S(P + 'p:SetAttribute("DevOres", 3) return 1'); near_deposit("d:GetAttribute('Ore')<3", 10); time.sleep(1.4); face()
    C('local t=game.Players.LocalPlayer.PlayerGui.PixelHUD.LeftColumn.Tracker.TrackerPill:FindFirstChildWhichIsA("TextButton") return 1')
    N.shot("15_pickaxe_hand"); N.shot("04_radar"); N.shot("01a_left_column")
if want("06") or want("08") or want("05"):
    print("strike at", near_deposit("d:GetAttribute('Ore')<3")); time.sleep(1.2); face(); N.key("E"); time.sleep(0.8); N.shot("06a_perfect_strike")
    C(STRIKE); time.sleep(0.1); N.shot("06b_perfect_strike_hit")
    for _ in range(2): time.sleep(0.5); C(STRIKE)
    time.sleep(1.25); N.shot("08_ore_icon_card"); time.sleep(2.6)
if want("03"):
    N.key("B"); time.sleep(1.2); N.shot("03_modal_blur")  # after the strike minigame: the bag holds ore, so the grid is filled
    C('game.Players.LocalPlayer.PlayerGui:FindFirstChild('Inventory',true).Visible=false return 1'); time.sleep(0.8)
if want("07"):
    print("rush at", near_deposit("d:GetAttribute('Ore')==3")); time.sleep(1.2); face(); N.key("E"); time.sleep(0.9); N.shot("07a_vein_rush")
    seq = (C("return game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.VeinRush:GetAttribute('Seq') or ''") or [""])[0].strip()
    for i, c in enumerate(seq):
        N.key("D" if c == "1" else "A")
        if i == 2: N.shot("07b_vein_rush_cleave")
    time.sleep(4)
if want("02"):
    S(P + 'p:SetAttribute("DevTorchAge", 200) h.CFrame=CFrame.new(game.ReplicatedStorage.Shared and (require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(0,4,46))) return 1')
    time.sleep(1.5); N.shot("02_survival_talisman")
    S(P + 'p:SetAttribute("DevTorchAge", 0) h.CFrame=CFrame.new(require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN+Vector3.new(0,4,6)) return 1'); time.sleep(1.5)
# --- the escape
if want("12"):
    C('game.ReplicatedStorage.Remotes.Surface:FireServer("up") return 1')
    time.sleep(9); N.shot("12a_escape_tunnel"); time.sleep(6); N.shot("12b_escape_tunnel"); time.sleep(8); N.shot("12c_escape_tunnel")
print(C("local t={} for _,l in game.LogService:GetLogHistory() do if l.messageType==Enum.MessageType.MessageError then table.insert(t,l.message:sub(1,200)) end end return table.concat(t,' | ')"))
print(sorted(f.name for f in N.out.glob("*.png")))
N.play(False)
