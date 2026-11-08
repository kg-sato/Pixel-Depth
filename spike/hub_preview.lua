local old = workspace:FindFirstChild("Hub") if old then old:Destroy() end
local m = game.ServerScriptService.HubBuilder:Clone()
local Hub = require(m)
local t = os.clock()
local hub = Hub.build(workspace, Vector3.zero)
local parts, tex = 0, 0
for _, d in hub:GetDescendants() do if d:IsA("BasePart") then parts += 1 elseif d:IsA("Texture") then tex += 1 end end
m:Destroy()
local cf, size = hub:GetBoundingBox()
return string.format("parts %d textures %d build %.2fs size %s", parts, tex, os.clock() - t, tostring(size))
