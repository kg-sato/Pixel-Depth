"""Drive the first minute in a running Studio Play session (v3: camp hub + first-person mine) and capture each beat.
Usage (Play must be running): python "Games/Pixel Depth/spike/play_test.py"
Writes captures/ft3_*.png and prints the elapsed time, tutorial step, gold and bag at each beat."""
import json, os, subprocess, sys, time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
LIVE = os.path.join(ROOT, "tools", "studio_live.py")
CAP = os.path.join(os.path.dirname(__file__), "..", "captures")
gui = "LocalPlayer.PlayerGui.PixelHUD."
t0 = time.time()


def call(tool, args, shot=None):
    env = dict(os.environ)
    if shot:
        env["STUDIO_SHOT"] = os.path.join(CAP, shot)
    r = subprocess.run([sys.executable, LIVE, tool, json.dumps(args)], capture_output=True, text=True, encoding="utf-8", env=env)
    return ((r.stdout or r.stderr).strip().splitlines() or [""])[-1]


def lua(code, where="Server"):
    return call("execute_luau", {"code": code, "datamodel_type": where})


def click(name, times=1, gap=240):
    acts = []
    for _ in range(times):
        acts += [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": gui + name}, {"action": "wait", "wait_time_ms": gap}]
    call("user_mouse_input", {"actions": acts, "datamodel_type": "Client"})



def key(code, hold_ms=0):
    acts = [{"action": "keyDown", "key_code": code}, {"action": "wait", "wait_time_ms": hold_ms}, {"action": "keyUp", "key_code": code}] if hold_ms else [{"action": "keyPress", "key_code": code}]
    call("user_keyboard_input", {"actions": acts, "datamodel_type": "Client"})


def beat(name):
    info = lua("local p = game.Players.LocalPlayer local g = p.PlayerGui.PixelHUD local t = {} "
               "for _, l in g:GetDescendants() do if l:IsA('TextLabel') and l.Visible and #l.Text > 0 and #l.Text < 40 then table.insert(t, l.Text) end end "
               "return tostring(p:GetAttribute('InMine')) .. ' | ' .. table.concat(t, ' / '):sub(1, 220)", "Client")
    print(f"{time.time() - t0:5.1f}s {name}: {info}")
    call("screen_capture", {"capture_id": name}, shot=f"ft3_{name}.png")


def stand_on_start():  # put the miner over the first start cell so DIG digs straight down
    lua("local p = game.Players:GetPlayers()[1] local b = workspace.Shafts['Shaft_' .. p.UserId].Blocks "
        "local best for _, q in b:GetChildren() do local r, c, d = q:GetAttribute('R'), q:GetAttribute('C'), q:GetAttribute('D') "
        "if c == 10 and d == 10 and r and r >= 4 and (not best or r < best:GetAttribute('R')) then best = q end end "
        "if best then p.Character.HumanoidRootPart.CFrame = CFrame.new(best.Position + Vector3.new(0, 5, 0)) end return best and best.Name or 'none'")


beat("00_hub")
key("Q")  # the lift: down into your mine from the hub
time.sleep(1.5)
beat("01_landing")
key("E", 300)
time.sleep(0.6)
beat("02_first_block")
for i in range(14):
    stand_on_start()
    time.sleep(0.4)
    key("E", 800)
beat("03_vein")
key("E", 2400)
time.sleep(0.6)
beat("04_full")
key("Return")
time.sleep(1.8)
beat("05_sold_at_camp")
key("G")
time.sleep(0.6)
beat("06_forge")
click("Forge.Buy")
time.sleep(0.8)
beat("07_bought")
key("G")
time.sleep(0.4)
key("Q")
time.sleep(1.5)
for i in range(10):
    stand_on_start()
    time.sleep(0.4)
    key("E", 800)
time.sleep(0.6)
beat("08_egg")
time.sleep(2.2)
beat("09_hatch")
time.sleep(4.5)
beat("10_crew")
print(f"{time.time() - t0:5.1f}s done")
