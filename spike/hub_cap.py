"""Edit-mode camera captures of the hub. python cap.py <round> [view ...]"""
import json, math, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "v4")
rnd = sys.argv[1]
def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot: env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env)
    return (r.stdout + r.stderr).strip()
def bear(b, r):
    a = math.radians(b); return (math.sin(a) * r, -math.cos(a) * r)
P, D = math.radians(52), 46
def game(fx, fz, y=3.6, dist=D):  # the in-game bird's-eye: south of the focus, looking north
    return (fx, y + math.sin(P) * dist, fz + math.cos(P) * dist), (fx, y, fz)
def facing(b, r=40, back=34, up=26):  # a 3/4 view looking at the store's front from the shaft side
    sx, sz = bear(b, r); ex, ez = bear(b - 18, r - back)
    return (ex, up, ez), (sx, 6, sz)
V = {
  "overview": ((0, 105, 125), (0, 10, -25)),
  "spawn": game(0, 16),
  "sell": facing(269), "forge": facing(318, 42), "trophy": facing(56, 42), "cabin": facing(97),
  "incubator": facing(225, 41), "notice": facing(7), "campfire": ((20, 22, 58), (6, 2, 34)),
  "top": ((0, 150, 70), (0, 0, -2)),
  "t_west": game(-22, 8), "t_north": game(8, -32, 7.6), "t_east": game(34, 6, 5.6), "t_south": game(-2, 40), "t_sw": game(-22, 30),
  "g_sell": game(*bear(269, 30)), "g_forge": game(*bear(318, 31)), "g_trophy": game(*bear(56, 31)),
  "g_incubator": game(*bear(225, 31)), "g_cabin": game(*bear(97, 30)), "g_notice": game(*bear(7, 30)),
}
names = sys.argv[2:] or list(V)
for n in names:
    eye, at = V[n]
    code = ("local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.FieldOfView=50 "
            f"c.Focus=CFrame.new({at[0]},{at[1]},{at[2]}) c.CFrame=CFrame.lookAt(Vector3.new({eye[0]},{eye[1]},{eye[2]}),Vector3.new({at[0]},{at[1]},{at[2]})) return 'ok'")
    run("execute_luau", {"datamodel_type": "Edit", "code": code})
    time.sleep(1.2)
    p = os.path.join(out, f"{rnd}_{n}.png")
    print(n, run("screen_capture", {"capture_id": n}, shot=p)[-60:])
