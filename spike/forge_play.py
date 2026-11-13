"""Play test of the forge v2: open, select, buy (coins), upgrade (gems), equip, the celebration and the tabs. Start Play first (~12 s).
    python "Games/Pixel Depth/spike/forge_play.py" <prefix>
Clicks go to the real buttons (user_mouse_input, GUI coordinates = screen minus the top bar inset); captures go to
captures/forge2/<prefix>_*.png; each step prints the server's gold, gems, pick, equip and levels."""
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "forge2")
pre = sys.argv[1] if len(sys.argv) > 1 else "t1"
os.makedirs(out, exist_ok=True)


def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot:
        env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env, encoding="utf-8")
    return ((r.stdout or "") + (r.stderr or "")).strip().splitlines()[-1:] or [""]


def lua(code, where="Server"):
    return run("execute_luau", {"code": code, "datamodel_type": where})[0]


def shot(name, wait=0.4):
    time.sleep(wait)
    run("screen_capture", {"capture_id": name}, shot=os.path.join(out, f"{pre}_{name}.png"))


def center(path):  # GUI centre of a forge element, from the client
    r = lua("local o=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Forge',true) for s in string.gmatch('" + path + "','[^.]+') do o=o[s] end "
            "local c=o.AbsolutePosition+o.AbsoluteSize/2 "
            # the forge stands in the world as a tilted panel (Shared.SpatialPanels): map the canvas point to where it is drawn
            "local sg=o:FindFirstAncestorWhichIsA('SurfaceGui') if sg then local part=sg.Adornee local cs=sg.CanvasSize "
            "local w=part.CFrame*Vector3.new(-(c.X/cs.X-0.5)*part.Size.X,(0.5-c.Y/cs.Y)*part.Size.Y,-part.Size.Z/2) local v=workspace.CurrentCamera:WorldToViewportPoint(w) "
            "local i=game:GetService('GuiService'):GetGuiInset() c=Vector2.new(v.X,v.Y-i.Y) end "
            "return math.floor(c.X)..','..math.floor(c.Y)", "Client")
    x, y = r.split(",")
    return int(x), int(y)


def click(path):
    x, y = center(path)
    run("user_mouse_input", {"actions": [{"action": "moveTo", "x": x, "y": y}, {"action": "mouseButtonClick", "mouse_button": "left"}], "datamodel_type": "Client"})


STATE = ("local r=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Forge',true) local d=r.Detail "
         "return 'action='..d.Action.Text..' equip='..d.Equip.Text..'('..tostring(d.Equip.Visible)..') name='..d:FindFirstChildWhichIsA('TextLabel').Text")

print("state", run("get_studio_state", {})[0])
print("give", lua("local p=game.Players:GetPlayers()[1] p:SetAttribute('DevGold',800) p:SetAttribute('DevGems',40) return 'ok'"))
time.sleep(1)
run("user_keyboard_input", {"actions": [{"action": "keyPress", "key_code": "G"}], "datamodel_type": "Client"})
shot("open", 1.2)
click("Grid.Card2")
print("select stone", lua(STATE, "Client"))
shot("stone")
click("Detail.Action")
shot("buy_celebrate", 1.3)
click_nice = lua("local b=game.Players.LocalPlayer.PlayerGui.ForgeCelebrate.Stage:FindFirstChild('NICE!',true) or game.Players.LocalPlayer.PlayerGui.ForgeCelebrate.Stage:FindFirstChildWhichIsA('TextButton') "
                 "local c=b.AbsolutePosition+b.AbsoluteSize/2 return math.floor(c.X)..','..math.floor(c.Y)", "Client")
x, y = map(int, click_nice.split(","))
run("user_mouse_input", {"actions": [{"action": "moveTo", "x": x, "y": y}, {"action": "mouseButtonClick", "mouse_button": "left"}], "datamodel_type": "Client"})
print("after buy", lua(STATE, "Client"))
shot("after_buy", 0.6)
click("Detail.Action")  # the bought stone is selected: UPGRADE with gems
shot("upgrade_a", 0.5)
shot("upgrade_b", 0.9)
print("after upgrade", lua(STATE, "Client"))
run("user_mouse_input", {"actions": [{"action": "moveTo", "x": x, "y": y}, {"action": "mouseButtonClick", "mouse_button": "left"}], "datamodel_type": "Client"})
click("Grid.Card1")
click("Detail.Equip")
shot("equip_wood", 0.6)
print("after equip", lua(STATE, "Client"))
click("TabBACKPACKS")
shot("packs", 0.8)
click("TabCHARMS")
shot("charms", 0.5)
print("console", lua("return 'ok'"))
