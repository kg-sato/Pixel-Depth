"""python cave_cap.py <prefix>: cave lighting preset on, Edit-camera captures of the camp and each piece, then restore lighting"""
import json, os, subprocess, sys, time
root = r"C:\Users\kgsat\Documents\Roblox"
out = os.path.join(root, "Games", "Pixel Depth", "captures", "caves"); os.makedirs(out, exist_ok=True)
def run(tool, args, shot=None):
    env = dict(os.environ)
    if shot: env["STUDIO_SHOT"] = shot
    r = subprocess.run([sys.executable, os.path.join(root, "tools", "studio_live.py"), tool, json.dumps(args)], capture_output=True, text=True, cwd=root, env=env)
    return (r.stdout + r.stderr).strip()
pre = sys.argv[1]
setup = r'''
local L = game.Lighting
local C = require(game.ReplicatedStorage.Shared.Config)
for name, props in C.CAVE_LIGHT do
  local o = name == "Lighting" and L or L:FindFirstChild(name)
  if not o and name == "DepthOfField" then o = Instance.new("DepthOfFieldEffect") o.Name = "DepthOfField" o.Parent = L o:SetAttribute("CaveTemp", true) end
  for k, v in props do
    if o:GetAttribute("Saved_" .. k) == nil then
      local old = o[k]
      o:SetAttribute("Saved_" .. k, typeof(old) == "EnumItem" and ("enum:" .. old.Name) or old)
    end
    o[k] = v
  end
end
local cv = workspace.Caves
local o = Vector3.new(-3000, 0, 0)
local v = { camp = { o + Vector3.new(22, 14, -24), o + Vector3.new(-2, 2, 6) } }
for _, n in { "Chasm", "Grotto", "Mushrooms" } do
  local g = cv[n] local e, d = g:GetAttribute("Entry"), g:GetAttribute("Dir")
  local fwd = { Chasm = 60, Grotto = 50, Mushrooms = 100 }
  local at = e + d * fwd[n] + Vector3.new(0, n == "Mushrooms" and 12 or 0, 0)
  v[n] = n == "Chasm" and { e + d * 56 + Vector3.new(0, 2, 0), e + d * 130 + Vector3.new(0, -55, 0) } or { e + d * (n == "Mushrooms" and 50 or 4) + Vector3.new(0, 14, 0) + Vector3.new(d.Z, 0, -d.X) * 6, at }
end
local s = {}
for k, p in v do table.insert(s, string.format("%s %.1f %.1f %.1f %.1f %.1f %.1f", k, p[1].X, p[1].Y, p[1].Z, p[2].X, p[2].Y, p[2].Z)) end
return table.concat(s, ";")
'''
res = run("execute_luau", {"datamodel_type": "Edit", "code": setup}).splitlines()[-1]
for item in res.split(";"):
    f = item.split(); n = f[0]; e = f[1:4]; a = f[4:7]
    code = ("local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.FieldOfView=70 "
            f"c.Focus=CFrame.new({a[0]},{a[1]},{a[2]}) c.CFrame=CFrame.lookAt(Vector3.new({e[0]},{e[1]},{e[2]}),Vector3.new({a[0]},{a[1]},{a[2]})) return 'ok'")
    run("execute_luau", {"datamodel_type": "Edit", "code": code}); time.sleep(1.5)
    run("screen_capture", {"capture_id": n}, shot=os.path.join(out, f"{pre}_{n}.png")); print(n)
restore = r'''
local L = game.Lighting
for _, o in { L, L:FindFirstChild("Atmosphere"), L:FindFirstChild("Bloom"), L:FindFirstChild("ColorCorrection"), L:FindFirstChild("DepthOfField") } do
  if o then
    if o:GetAttribute("CaveTemp") then o:Destroy() else
      for k, v in o:GetAttributes() do
        local prop = k:match("^Saved_(.+)")
        if prop then
          if type(v) == "string" and v:sub(1, 5) == "enum:" then o[prop] = Enum.LightingStyle[v:sub(6)] else o[prop] = v end
          o:SetAttribute(k, nil)
        end
      end
    end
  end
end
return "restored"
'''
if "--keep" not in sys.argv: print(run("execute_luau", {"datamodel_type": "Edit", "code": restore}).splitlines()[-1])
from PIL import Image
ns = ["camp", "Chasm", "Grotto", "Mushrooms"]
ims = [Image.open(os.path.join(out, f"{pre}_{n}.png")).convert("RGB") for n in ns]
w, h = ims[0].size; tw = 800; th = int(h * tw / w)
s = Image.new("RGB", (tw * 2, th * 2))
for i, im in enumerate(ims): s.paste(im.resize((tw, th)), ((i % 2) * tw, (i // 2) * th))
s.save(os.path.join(out, f"{pre}_sheet.jpg"), quality=85)
