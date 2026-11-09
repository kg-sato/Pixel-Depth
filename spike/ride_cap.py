"""python ride_cap.py <prefix> [times...]: start the minecart ride in Play (Client fires Surface "down") and capture frames at
the given seconds after the start (default 0.8 3.4 5.3 7.0 8.7 10.6). Captures go to captures/phase4/<prefix>_<t>.png"""
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "phase4"); os.makedirs(out, exist_ok=True)
def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot: env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env)
    return (r.stdout + r.stderr).strip()
pre = sys.argv[1]
times = [float(x) for x in sys.argv[2:]] or [0.8, 3.4, 5.3, 7.0, 8.7, 10.6]
print(run("execute_luau", {"datamodel_type": "Client", "code": 'game.ReplicatedStorage.Remotes.Surface:FireServer("down") return "fired"'}))
t0 = time.time()
for t in times:
    while time.time() - t0 < t: time.sleep(0.02)
    print(f"{t:.1f} at {time.time() - t0:.2f}", run("screen_capture", {"capture_id": f"{pre}_{t}"}, shot=os.path.join(out, f"{pre}_{t}.png"))[-30:])
