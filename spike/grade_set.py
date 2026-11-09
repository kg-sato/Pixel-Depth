"""python grade_set.py <out folder name under captures/>: in a fresh Play session, capture the night-of-Nov-9 grading set:
7_gemshop, 9_station, 5_wick, 6_gloomling, 2_escape_sheet (two frames) and 3_escape_card. Start Play first (~8 s)."""
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
game = os.path.join(root, "Games", "Pixel Depth")
out = os.path.join(game, "captures", sys.argv[1]); os.makedirs(out, exist_ok=True)
PY = os.path.join(root, "Hunyuan3D", ".venv", "Scripts", "python.exe")

def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot: env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env, encoding="utf-8")
    return ((r.stdout or "") + (r.stderr or "")).strip().splitlines()[-1:] or [""]
def lua(code, where="Server"): return run("execute_luau", {"code": code, "datamodel_type": where})[0]
def shot(name): run("screen_capture", {"capture_id": name}, shot=os.path.join(out, name + ".png"))
def click_at(x, y): run("user_mouse_input", {"actions": [{"action": "moveTo", "x": x, "y": y}, {"action": "mouseButtonClick", "mouse_button": "left"}], "datamodel_type": "Client"})

CAM = """local RS = game:GetService("RunService") local cam = workspace.CurrentCamera
pcall(function() RS:UnbindFromRenderStep("ClaudeCam") end)
local off = {} if _G.HIDEGUI then for _, g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA("ScreenGui") and g.Enabled then g.Enabled = false table.insert(off, g) end end end
RS:BindToRenderStep("ClaudeCam", Enum.RenderPriority.Camera.Value + 40, function() cam.CameraType = Enum.CameraType.Scriptable %s end)
task.delay(%s, function() RS:UnbindFromRenderStep("ClaudeCam") for _, g in off do g.Enabled = true end end) return 1"""

# 7 gem shop
xy = lua("local p=game.Players.LocalPlayer.PlayerGui.PixelHUD.GemPill local c=p.AbsolutePosition+p.AbsoluteSize/2 return math.floor(c.X)..','..math.floor(c.Y)", "Client")
x, y = map(int, xy.split(","))
click_at(x, y); time.sleep(0.8); shot("7_gemshop"); click_at(x, y); time.sleep(0.5)
# ride down
lua('game.ReplicatedStorage.Remotes.Surface:FireServer("down") return 1', "Client"); time.sleep(13)
# 9 station
lua("_G.HIDEGUI = true return 1", "Client")
lua(CAM % ("""local body = workspace.Caves:FindFirstChild("CartBody", true) local st = body.CFrame * CFrame.new(0, -1.65, -3)
cam.FieldOfView = 70 cam.CFrame = CFrame.lookAt((st * CFrame.new(10, 7, 12)).Position, (st * CFrame.new(0, 2.5, -6)).Position)""", 3), "Client")
time.sleep(1); shot("9_station"); time.sleep(2.5)
lua("_G.HIDEGUI = false return 1", "Client")
# 5 Wick
lua('local p=game.Players:GetPlayers()[1] local h=workspace.Caves:FindFirstChild("WickHead",true) p.Character.HumanoidRootPart.CFrame=CFrame.new(h.Position+h.CFrame.LookVector*7+Vector3.new(0,2,0)) return 1')
time.sleep(2)
lua(CAM % ("""local t = workspace.Caves:FindFirstChild("WickHead", true) cam.FieldOfView = 55
cam.CFrame = CFrame.lookAt(t.Position + t.CFrame.LookVector * 8 + Vector3.new(1.5, 1.5, 0), t.Position + Vector3.new(0, 0.6, 0))""", 3), "Client")
time.sleep(0.8); shot("5_wick"); time.sleep(2.5)
# 6 gloomling
lua('local p=game.Players:GetPlayers()[1] p:SetAttribute("DevBanked", true) p:SetAttribute("DevTorchAge", 230) local e=workspace.Caves.Mushrooms:GetAttribute("Entry") p.Character.HumanoidRootPart.CFrame=CFrame.new(e+Vector3.new(0,4,0)) return 1')
for _ in range(40):  # wait until a gloomling is 7-14 studs away
    d = lua('local h=game.Players:GetPlayers()[1].Character.HumanoidRootPart local b=999 for _,g in workspace.Gloom:GetChildren() do b=math.min(b,(g.Position-h.Position).Magnitude) end return math.floor(b)')
    if d.isdigit() and 7 <= int(d) <= 14: break
    time.sleep(0.25)
lua(CAM % ("""local g = workspace.GloomVis:FindFirstChildOfClass("Model") local h = game.Players.LocalPlayer.Character.Head
if g and g.PrimaryPart then cam.CFrame = CFrame.lookAt(h.Position + Vector3.new(0, 0.4, 0), g.PrimaryPart.Position) end""", 3), "Client")
time.sleep(0.6); shot("6_gloomling"); time.sleep(2.5)
# escape: back to camp, then ride up
lua('local p=game.Players:GetPlayers()[1] p:SetAttribute("DevTorchAge", 0) local l=workspace.Caves:FindFirstChild("LiftLanding",true) p.Character.HumanoidRootPart.CFrame=l.CFrame+Vector3.new(0,3,0) return 1')
time.sleep(2)
lua('game.ReplicatedStorage.Remotes.Surface:FireServer("up") return 1', "Client")
t0 = time.time()
for t, name in ((6, "esc_a"), (15, "esc_b")):
    while time.time() - t0 < t: time.sleep(0.05)
    shot(name)
CARD = ('local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild("MinecartEscapeGui") if not g then return "gone" end '
        'for _,f in g:GetChildren() do if f:IsA("Frame") and f:FindFirstChildOfClass("UIScale") then return "card" end end return "run"')
for _ in range(400):
    r = lua(CARD, "Client")
    if r == "card":
        time.sleep(0.6); shot("esc_card"); break
    if r == "gone": break
    time.sleep(0.3)
subprocess.run([PY, "-c", f"""
from PIL import Image
import os
o = r'{out}'
a = Image.open(os.path.join(o, 'esc_a.png')).convert('RGB').resize((820, 540)); b = Image.open(os.path.join(o, 'esc_b.png')).convert('RGB').resize((820, 540))
W = Image.new('RGB', (1640, 540)); W.paste(a, (0, 0)); W.paste(b, (820, 0)); W.save(os.path.join(o, '2_escape_sheet.png'))
if os.path.exists(os.path.join(o, 'esc_card.png')):
    c = Image.open(os.path.join(o, 'esc_card.png')).convert('RGB'); w, h = c.size
    c.crop((int(w * 0.29), int(h * 0.2), int(w * 0.71), int(h * 0.8))).save(os.path.join(o, '3_escape_card.png'))
for f in ('esc_a.png', 'esc_b.png', 'esc_card.png'):
    if os.path.exists(os.path.join(o, f)): os.remove(os.path.join(o, f))
"""])
print("done", sorted(os.listdir(out)))
