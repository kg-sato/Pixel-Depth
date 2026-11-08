-- Edit-mode preview of the caves: rebuilds workspace.Caves from ServerScriptService.CaveBuilder (origin and seed as in Config)
local old = workspace:FindFirstChild("Caves") if old then old:Destroy() end
local m = game.ServerScriptService.CaveBuilder:Clone()
local Cave = require(m)
local t = os.clock()
local cave = Cave.build(workspace, Vector3.new(-3000, 0, 0), 7)
local parts, lights = 0, 0
for _, d in cave:GetDescendants() do if d:IsA("BasePart") then parts += 1 elseif d:IsA("PointLight") then lights += 1 end end
m:Destroy()
local cf, size = cave:GetBoundingBox()
return string.format("parts %d lights %d floors %d ceil %d walls %d cells %d build %.2fs size %s", parts, lights, cave:GetAttribute("Floors"), cave:GetAttribute("Ceilings"), cave:GetAttribute("Walls"), cave:GetAttribute("Cells"), os.clock() - t, tostring(size))
