-- TierGate (ReplicatedStorage.Shared.TierGate), started by PixelClient. Town and Mine Map Overhaul 3.1 (2026-11-27): deposits
-- have hardness gates (C.minTier: each layer's base, mid and rare ore needs a pickaxe tier). A deposit too hard for the held
-- pickaxe shows "Locked · Needs T<n>" on its prompt; trying it anyway throws metallic sparks off the rock and says which pickaxe
-- to forge (the server refuses the extraction and sends Fx "needTier"). Display only: the server decides.
local RunService = game:GetService("RunService")
local M = {}
local SPARK = Color3.fromRGB(255, 226, 150)

function M.start(E)
	local C, R = E.C, E.R
	local equip = 1
	local function mark()
		local caves = workspace:FindFirstChild("Caves")
		local dep = caves and caves:FindFirstChild("Deposits")
		for _, d in dep and dep:GetChildren() or {} do
			local core = d:IsA("Model") and d.PrimaryPart
			local pr = core and core:FindFirstChildOfClass("ProximityPrompt")
			if pr then
				local need = C.minTier(d:GetAttribute("Layer"), d:GetAttribute("Ore"))
				if equip < need then
					pr.ActionText, pr.ObjectText = "Locked", "Needs T" .. need .. " " .. (C.PICKS[need] and C.PICKS[need].name or "")
				elseif pr.ActionText == "Locked" then
					pr.ActionText, pr.ObjectText = "Extract", d:GetAttribute("OreName") or ""
				end
			end
		end
	end
	R.State.OnClientEvent:Connect(function(st)
		if type(st) == "table" and st.equip and st.equip ~= equip then
			equip = st.equip
			mark()
		end
	end)
	task.spawn(function() while true do task.wait(6) if E.plr:GetAttribute("InCave") then mark() end end end) -- deposits regrow and stream in
	local function sparks(at)
		local calm = false
		pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
		if calm then return end
		for k = 1, 14 do
			local q = Instance.new("Part")
			q.Size = Vector3.new(0.12, 0.12, 0.5 + (k % 3) * 0.15)
			q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
			q.Material, q.Color = Enum.Material.Neon, k % 4 == 0 and Color3.new(1, 1, 1) or SPARK
			local dir = (Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5)).Unit
			q.CFrame = CFrame.lookAt(at, at + dir)
			q.Parent = workspace.CurrentCamera
			local t0, v = os.clock(), dir * (14 + math.random() * 10)
			local c
			c = RunService.Heartbeat:Connect(function()
				local u = os.clock() - t0
				if u > 0.45 or not q.Parent then c:Disconnect() q:Destroy() return end
				local p = at + v * u + Vector3.new(0, -30 * u * u, 0)
				q.CFrame = CFrame.lookAt(p, p + (v + Vector3.new(0, -60 * u, 0)))
				q.Transparency = u / 0.45
			end)
		end
	end
	R.Fx.OnClientEvent:Connect(function(kind, need, name, dep)
		if kind ~= "needTier" then return end
		local core = typeof(dep) == "Instance" and dep:IsA("Model") and dep.PrimaryPart
		if core then sparks(core.Position) end
		E.sfx("breakRock", 2.3)
		E.toast("NEEDS TIER " .. tostring(need) .. " (" .. string.upper(tostring(name)) .. ")  \u{00B7}  FORGE IN TOWN", Color3.fromRGB(255, 196, 120), true)
		if E.shake then pcall(E.shake, 0.15) end
	end)
end

return M
