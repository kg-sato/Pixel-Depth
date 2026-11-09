"""Play test of cave stage 3-4: minimap, ore deposits, Perfect Strike, Vein Rush, camp banking. Start Play first (wait ~12 s).
    python "Games/Pixel Depth/spike/cave_mg_play.py" <prefix>
Captures go to captures/caves/<prefix>_*.png; each step prints what the HUD shows."""
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "caves")
pre = sys.argv[1] if len(sys.argv) > 1 else "m1"


def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot:
        env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env, encoding="utf-8")
    return ((r.stdout or "") + (r.stderr or "")).strip().splitlines()[-1:] or [""]


def lua(code, where="Server"):
    return run("execute_luau", {"code": code, "datamodel_type": where})[0]


HUD = "local p=game.Players.LocalPlayer local g=p.PlayerGui.PixelHUD local function t(o) local l=o and o:FindFirstChildWhichIsA('TextLabel',true) return l and l.Text or '?' end "


def shot(name):
    time.sleep(0.4)
    run("screen_capture", {"capture_id": name}, shot=os.path.join(out, f"{pre}_{name}.png"))
    print(name, lua(HUD + "return 'cave='..tostring(p:GetAttribute('InCave'))..' | '..t(g:FindFirstChild('BagPill',true))..' | gold '..t(g:FindFirstChild('GoldPill',true))..' | fps '..math.floor(workspace:GetRealPhysicsFPS())", "Client"))


def face_deposit(which="true"):  # prompts only show for things on screen: turn the first-person camera to the nearest matching deposit
    lua("local h=game.Players.LocalPlayer.Character.HumanoidRootPart local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do "
        "if " + which + " then local m=(d.PrimaryPart.Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end "
        "local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,best.PrimaryPart.Position)", "Client")
    time.sleep(0.5)


def key(k):
    run("user_keyboard_input", {"actions": [{"action": "keyPress", "key_code": k}], "datamodel_type": "Client"})


def go_to(which):  # stand 4 studs out from a deposit, facing it; returns its ore name
    return lua("local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local best,bd "
               "for _,d in workspace.Caves.Deposits:GetChildren() do local ok=" + which + " "
               "if ok then local dist=(d.PrimaryPart.Position-Vector3.new(-3000,0,0)).Magnitude if not bd or dist<bd then best,bd=d,dist end end end "
               "if not best then return 'none' end local c=best.PrimaryPart local rp=RaycastParams.new() rp.FilterDescendantsInstances={p.Character,workspace.Caves.Deposits} "
               "local at for _,dir in {-c.CFrame.LookVector*Vector3.new(1,0,1),Vector3.xAxis,-Vector3.xAxis,Vector3.zAxis,-Vector3.zAxis} do "
               "if not at and dir.Magnitude>0.1 then local t=c.Position+dir.Unit*3.2+Vector3.new(0,2,0) "
               "if not workspace:Raycast(c.Position+Vector3.new(0,2,0),t-(c.Position+Vector3.new(0,2,0)),rp) then local f=workspace:Raycast(t,Vector3.new(0,-8,0),rp) "
               "if f then at=f.Position+Vector3.new(0,3,0) end end end end "
               "at=at or c.Position+Vector3.new(0,4,0) h.CFrame=CFrame.lookAt(at,Vector3.new(c.Position.X,at.Y,c.Position.Z)) "
               "task.wait(0.6) return 'd='..math.floor((h.Position-c.Position).Magnitude)..' '..best:GetAttribute('OreName')..' ore'..best:GetAttribute('Ore')..' L'..best:GetAttribute('Layer')..' at '..math.floor(bd)..' studs'")


print("state", run("get_studio_state", {})[0])
print("deposits", lua("local n={0,0,0} for _,d in workspace.Caves.Deposits:GetChildren() do local o=d:GetAttribute('Ore') n[o]+=1 end return #workspace.Caves.Deposits:GetChildren()..' (common '..n[1]..', uncommon '..n[2]..', rare '..n[3]..')'"))
key("Q")
time.sleep(2.5)
shot("camp_map")
print("common", go_to("d:GetAttribute('Ore')<3"))
time.sleep(1.2)
face_deposit("d:GetAttribute('Ore')<3")
shot("deposit")
key("E")
time.sleep(0.7)
shot("strike_start")
print("strikes", lua("local hud=game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.PerfectStrike local nd,ar=hud:FindFirstChild('Needle',true),hud:FindFirstChild('Arc',true) "
                     "local R=game.ReplicatedStorage.Remotes.Extract local out={} for n=1,3 do local want=n~=2 local t0=os.clock() "
                     "while os.clock()-t0<3 do local d=math.abs((nd.Rotation-ar.Rotation+180)%360-180) if (want and d<6) or (not want and d>90) then break end task.wait() end "
                     "table.insert(out,string.format('%d:%.0f',n,math.abs((nd.Rotation-ar.Rotation+180)%360-180))) R:FireServer('strike',workspace:GetServerTimeNow()) task.wait(0.5) end return table.concat(out,' ')", "Client"))
time.sleep(0.2)
shot("strike_end")
time.sleep(1.5)
rare = go_to("d:GetAttribute('Ore')==3")
print("rare", rare)
if rare != "none":
    time.sleep(1.0)
    face_deposit("d:GetAttribute('Ore')==3")
    key("E")
    time.sleep(0.7)
    key("A")  # first beat through the real input path (a slip or a clean chisel, whichever the cracks say)
    shot("rush_mid")
    # then the whole run through the remote: every beat right except the third (one slip -> PRISTINE, 6 ore)
    print("rush", lua("local seq=game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.VeinRush:GetAttribute('Seq') local ch={} "
                      "for i=1,#seq do local c=tonumber(seq:sub(i,i)) ch[i]= i==3 and c or 3-c end task.wait(#seq*0.13) "
                      "game.ReplicatedStorage.Remotes.Extract:FireServer('rush',ch) return 'seq '..seq..' sent '..#ch", "Client"))
    time.sleep(0.3)
    shot("rush_end")
time.sleep(1.5)
lua("local h=game.Players:GetPlayers()[1].Character.HumanoidRootPart h.CFrame=CFrame.new(-3000,4,-10)")
time.sleep(1.0)
shot("banked")
