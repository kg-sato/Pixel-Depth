"""Play test of the caves: lift down with Q, captures at camp and in each piece, torch aged to show dimming and fear."""
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "caves")
pre = sys.argv[1] if len(sys.argv) > 1 else "p1"


def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot:
        env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env, encoding="utf-8")
    return ((r.stdout or "") + (r.stderr or "")).strip().splitlines()[-1:] or [""]


def lua(code, where="Server"):
    return run("execute_luau", {"code": code, "datamodel_type": where})[0]


def shot(name):
    time.sleep(1.2)
    run("screen_capture", {"capture_id": name}, shot=os.path.join(out, f"{pre}_{name}.png"))
    print(name, lua("local p=game.Players.LocalPlayer local h=p.PlayerGui.PixelHUD.CaveHud return tostring(p:GetAttribute('InCave'))..' '..h.TorchPill:FindFirstChildWhichIsA('TextLabel').Text..' fps '..math.floor(workspace:GetRealPhysicsFPS())", "Client"))


print("state", run("get_studio_state", {})[0])
run("user_keyboard_input", {"actions": [{"action": "keyPress", "key_code": "Q"}], "datamodel_type": "Client"})
time.sleep(2.5)
shot("camp")
# face the fire from the lift
lua("local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local o=Vector3.new(-3000,0,0) h.CFrame=CFrame.lookAt(o+Vector3.new(-4,3,-20),o+Vector3.new(0,3,12))")
shot("camp_fire")
for n in ["Chasm", "Grotto", "Mushrooms"]:
    lua(f"local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local g=workspace.Caves['{n}'] local e,d=g:GetAttribute('Entry'),g:GetAttribute('Dir') "
        f"local at=e+d*({ {'Chasm': 20, 'Grotto': 12, 'Mushrooms': 60}[n] })+Vector3.new(0,4,0) h.CFrame=CFrame.lookAt(at, at+d*10+Vector3.new(0,{ {'Chasm': -4, 'Grotto': -2, 'Mushrooms': 2}[n] },0))")
    time.sleep(1.0)
    shot(n)
lua("game.Players:GetPlayers()[1]:SetAttribute('DevTorchAge', 250)")
time.sleep(1.0)
shot("Mushrooms_dim")
