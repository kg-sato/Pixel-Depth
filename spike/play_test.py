"""Drive the first-minute loop in a running Studio Play session and capture each beat.
Usage (Play must be running): python Games/Pixel-_/spike/play_test.py <UserId>
Writes captures/ft_*.png and prints the elapsed time of each beat."""
import json, os, subprocess, sys, time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
LIVE = os.path.join(ROOT, "tools", "studio_live.py")
CAP = os.path.join(os.path.dirname(__file__), "..", "captures")
uid = sys.argv[1]
blocks = f"game.Workspace.Shafts.Shaft_{uid}.Blocks."
gui = "LocalPlayer.PlayerGui.PixelHUD."
t0 = time.time()

def call(tool, args, shot=None):
    env = dict(os.environ)
    if shot:
        env["STUDIO_SHOT"] = os.path.join(CAP, shot)
    r = subprocess.run([sys.executable, LIVE, tool, json.dumps(args)], capture_output=True, text=True, encoding="utf-8", env=env)
    return (r.stdout or r.stderr).strip().splitlines()[-1:] or [""]

def click(path, times=1, gap=260):
    # 3D parts: instance_path clicks never reach UserInputService, so click the block's screen point (tool x,y = below the top bar)
    where = {"instance_path": path}
    if path.startswith("game.Workspace"):
        name = path.rsplit(".", 1)[1]
        code = ("local b = workspace.Shafts:FindFirstChild('Shaft_%s').Blocks:FindFirstChild('%s') "
                "if not b then return 'none' end local v = workspace.CurrentCamera:WorldToViewportPoint(b.Position + Vector3.new(0, 0, 2)) "
                "return math.floor(v.X) .. ',' .. math.floor(v.Y - game:GetService('GuiService'):GetGuiInset().Y)") % (uid, name)
        xy = call("execute_luau", {"code": code, "datamodel_type": "Client"})[0]
        if "," not in xy:
            print("   missing block", name); return
        x, y = map(int, xy.split(","))
        where = {"x": x, "y": y}
    acts = [dict({"action": "moveTo"}, **where)]
    for _ in range(times):
        acts += [{"action": "mouseButtonClick", "mouse_button": "left"}, {"action": "wait", "wait_time_ms": gap}]
    call("user_mouse_input", {"actions": acts, "datamodel_type": "Client"})

def beat(name):
    print(f"{time.time() - t0:5.1f}s {name}", call("screen_capture", {"capture_id": name}, shot=f"ft_{name}.png"))

beat("00_spawn")
click(blocks + "1_12"); time.sleep(0.8)
click(blocks + "2_12"); time.sleep(0.8)
click(blocks + "3_12", 2); time.sleep(0.8)
click(blocks + "4_12", 2); time.sleep(0.6)
beat("01_frenzy")
click(blocks + "4_11", 2); click(blocks + "4_13", 2); time.sleep(0.5)
beat("02_full")
click(gui + "SellPopup.Sell"); time.sleep(1.0)
beat("03_sold")
click(gui + "Upgrades"); time.sleep(0.5)
beat("04_forge")
click(gui + "Forge.RowPick.BuyPick"); time.sleep(0.6)
beat("04b_bought")
click(gui + "Forge.Close"); time.sleep(0.3)
click(gui + "Surface"); time.sleep(2.5)
click(blocks + "5_12"); time.sleep(0.8)
click(blocks + "6_12"); time.sleep(0.4)
beat("05_hatch_shake")
time.sleep(1.6)
beat("06_hatch_reveal")
time.sleep(4)
beat("07_crew_digs")
print(f"{time.time() - t0:5.1f}s done")
