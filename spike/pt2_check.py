"""Playtest 2 checks (Play running): selling at Bolt (near and far), the sell screen, the seated minecart ride, the minigame
lock (Space must strike, never jump), the cave look with ore highlights, and the chasm kill floor.
    python "Games/Pixel Depth/spike/pt2_check.py" <prefix>     captures go to captures/pt2/<prefix>_*.png"""
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "pt2"); os.makedirs(out, exist_ok=True)
pre = sys.argv[1] if len(sys.argv) > 1 else "c1"
only = sys.argv[2].split(",") if len(sys.argv) > 2 else None


def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot: env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env, encoding="utf-8")
    return ((r.stdout or "") + (r.stderr or "")).strip().splitlines()[-1:] or [""]
def lua(code, where="Server"): return run("execute_luau", {"code": code, "datamodel_type": where})[0]
def shot(name): time.sleep(0.3); run("screen_capture", {"capture_id": name}, shot=os.path.join(out, f"{pre}_{name}.png"))
def key(k): run("user_keyboard_input", {"actions": [{"action": "keyPress", "key_code": k}], "datamodel_type": "Client"})
def want(step): return only is None or step in only
P = 'local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart '
GOLD = P + 'local st=p.PlayerGui and 0 return tostring(p:GetAttribute("DevProbe"))'

if want("sell"):
    lua(P + 'p:SetAttribute("DevOres", 10) return 1'); time.sleep(1.5)
    probe = ('local g=p.PlayerGui.PixelHUD:FindFirstChild("GoldPill",true) local l=g and g:FindFirstChildWhichIsA("TextLabel",true) return "gold "..(l and l.Text or "?")')
    print("before", lua(P.replace("game.Players:GetPlayers()[1]", "game.Players.LocalPlayer") + probe, "Client"))
    print("far sell", lua('game.ReplicatedStorage.Remotes.SellPick:FireServer({["1.1"]=10}) return "sent"', "Client")); time.sleep(1.2)
    print("after far", lua(P.replace("game.Players:GetPlayers()[1]", "game.Players.LocalPlayer") + probe, "Client"))
    print("to bolt", lua(P + 'local b=workspace.Hub:FindFirstChild("Bolt",true) h.CFrame=b.Body.CFrame*CFrame.new(0,0,5) return "ok"'))
    time.sleep(0.8)
    print("near sell", lua('game.ReplicatedStorage.Remotes.SellPick:FireServer({["1.1"]=10,["1.2"]=4}) return "sent"', "Client")); time.sleep(1.5)
    print("after near", lua(P.replace("game.Players:GetPlayers()[1]", "game.Players.LocalPlayer") + probe, "Client"))
    lua(P + 'game.ReplicatedStorage.Remotes.Fx:FireClient(p, "openSell") return 1'); time.sleep(1.0)
    shot("sell_panel")
    lua('local i=game.Players.LocalPlayer.PlayerGui.PixelHUD:FindFirstChild("Inventory",true) if i then i.Visible=false end return 1', "Client")
    shot("bolt_town")

if want("ride"):
    lua(P + 'h.CFrame=CFrame.new(0,4,16) return 1'); time.sleep(0.5)
    key("Q"); time.sleep(0.5); shot("board"); time.sleep(2.1); shot("ride_a"); time.sleep(2.2); shot("ride_b"); time.sleep(9)

if want("lock"):
    print("go", lua(P + 'local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do if d:GetAttribute("Ore")<3 then local m=(d.PrimaryPart.Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end '
                    'local c=best.PrimaryPart local at=c.Position+Vector3.new(3.4,2.5,0) local rp=RaycastParams.new() rp.FilterDescendantsInstances={p.Character} local f=workspace:Raycast(at,Vector3.new(0,-8,0),rp) if f then at=f.Position+Vector3.new(0,3,0) end '
                    'h.CFrame=CFrame.lookAt(at,Vector3.new(c.Position.X,at.Y,c.Position.Z)) return "d "..math.floor(bd)'))
    time.sleep(1.0)
    lua('local cam=workspace.CurrentCamera local h=game.Players.LocalPlayer.Character.HumanoidRootPart local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do local m=(d.PrimaryPart.Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end cam.CFrame=CFrame.lookAt(cam.CFrame.Position,best.PrimaryPart.Position) return 1', "Client")
    time.sleep(0.4); key("E"); time.sleep(0.8)
    lua('local h=game.Players.LocalPlayer.Character.HumanoidRootPart _G.Y0=h.Position.Y _G.YMAX=0 _G.FZ=0 local hum=game.Players.LocalPlayer.Character.Humanoid _G.S=game:GetService("RunService").Heartbeat:Connect(function() if hum.WalkSpeed==0 then _G.FZ+=1 _G.YMAX=math.max(_G.YMAX,h.Position.Y-_G.Y0) end end) return 1', "Client")
    for _ in range(8): key("Space"); time.sleep(0.15)
    shot("lock")
    print("lock", lua('_G.S:Disconnect() local hum=game.Players.LocalPlayer.Character.Humanoid return string.format("rise while frozen %.2f over %d frames, walk %s jp %s", _G.YMAX, _G.FZ, hum.WalkSpeed, hum.JumpPower)', "Client"))
    time.sleep(4)
    print("after", lua('local hum=game.Players.LocalPlayer.Character.Humanoid return string.format("walk %s jp %s", hum.WalkSpeed, hum.JumpPower)', "Client"))

if want("cave"):
    shot("cave_look")
    print("highlights", lua('local n,on=0,0 for _,x in workspace.ClientFX:GetChildren() do if x.Name=="OreHighlight" then n+=1 if x.Enabled then on+=1 end end end return n.." made, "..on.." on"', "Client"))

if want("fall"):
    print("fall", lua(P + 'local kf for _,d in workspace.Caves:GetDescendants() do if d:GetAttribute("KillFloor") then kf=d end end h.CFrame=kf.CFrame+Vector3.new(0,6,0) return "dropped from "..math.floor(kf.Position.Y)'))
    time.sleep(2.5); shot("fell")
    print("after fall", lua(P + 'local l=workspace.Caves:FindFirstChild("LiftLanding",true) return "dist to camp "..math.floor((h.Position-l.Position).Magnitude)'))
