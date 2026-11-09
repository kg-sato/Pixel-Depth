"""Forge ore costs test (Play, forge open): buy Stone, select Ashcoal (needs ore), capture, give ore (DevOres), buy Ashcoal.
    python "Games/Pixel Depth/spike/ore_forge_test.py" """
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "phase7"); os.makedirs(out, exist_ok=True)
def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot: env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env, encoding="utf-8")
    return ((r.stdout or "") + (r.stderr or "")).strip().splitlines()[-1:] or [""]
def lua(code, where="Server"): return run("execute_luau", {"code": code, "datamodel_type": where})[0]
def click(path):
    r = lua("local o=game.Players.LocalPlayer.PlayerGui.PixelHUD.Forge for s in string.gmatch('" + path + "','[^.]+') do o=o[s] end local c=o.AbsolutePosition+o.AbsoluteSize/2 return math.floor(c.X)..','..math.floor(c.Y)", "Client")
    x, y = map(int, r.split(","))
    run("user_mouse_input", {"actions": [{"action": "moveTo", "x": x, "y": y}, {"action": "mouseButtonClick", "mouse_button": "left"}], "datamodel_type": "Client"})
def nice():
    r = lua("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('ForgeCelebrate') if not g or not g.Enabled then return 'none' end local b=g.Stage:FindFirstChildWhichIsA('TextButton', true) if not b then return 'none' end local c=b.AbsolutePosition+b.AbsoluteSize/2 return math.floor(c.X)..','..math.floor(c.Y)", "Client")
    if r != "none" and "," in r:
        x, y = map(int, r.split(","))
        run("user_mouse_input", {"actions": [{"action": "moveTo", "x": x, "y": y}, {"action": "mouseButtonClick", "mouse_button": "left"}], "datamodel_type": "Client"})
STATE = "local d=game.Players.LocalPlayer.PlayerGui.PixelHUD.Forge.Detail return 'action='..d.Action.Text..' ore='..(d:FindFirstChild('OreNeed') and d.OreNeed.Visible and d.OreNeed.Text or '-')"
click("Grid.Card2"); click("Detail.Action"); time.sleep(9); nice(); time.sleep(0.8)
click("Grid.Card3"); time.sleep(0.5)
print("ashcoal before ore:", lua(STATE, "Client"))
run("screen_capture", {"capture_id": "ore_need"}, shot=os.path.join(out, "ore_need.png"))
click("Detail.Action"); time.sleep(0.4)
print("after click without ore:", lua(STATE, "Client"))
lua("game.Players:GetPlayers()[1]:SetAttribute('DevOres', 10) return 1"); time.sleep(1)
click("Grid.Card3"); time.sleep(0.4)
print("ashcoal with ore:", lua(STATE, "Client"))
run("screen_capture", {"capture_id": "ore_ok"}, shot=os.path.join(out, "ore_ok.png"))
click("Detail.Action"); time.sleep(9); nice(); time.sleep(0.8)
print("after buy:", lua(STATE, "Client"))
