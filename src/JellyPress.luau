-- JellyPress (ReplicatedStorage.Shared.JellyPress), started by PixelClient. Directive v9 (2026-11-13): every jelly button
-- squashes and bounces when the pointer comes over it or it is pressed (0.92, 1.08, 1; reference Instagram Dd8KZxsNmMY).
-- It watches the player's GUIs for buttons that wear a kit skin (the "Skin" image PixelClient's button() adds) and gives each
-- its own UIScale named "Jelly", so the panel pop scale ("Pop") is left alone. Display only.
local TweenService = game:GetService("TweenService")
local M = {}

function M.start(E)
	local pg = E.plr:WaitForChild("PlayerGui")
	local done = setmetatable({}, { __mode = "k" })
	local function adopt(b)
		if done[b] or not b:IsA("GuiButton") or not b:FindFirstChild("Skin") then return end
		done[b] = true
		local sc = Instance.new("UIScale")
		sc.Name = "Jelly"
		sc.Parent = b
		local function bounce(from)
			sc.Scale = from
			local up = TweenService:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.08 })
			up.Completed:Once(function() TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play() end)
			up:Play()
		end
		b.MouseEnter:Connect(function() bounce(0.96) end)
		b.MouseButton1Down:Connect(function() bounce(0.92) end)
	end
	for _, d in pg:GetDescendants() do adopt(d) end
	pg.DescendantAdded:Connect(function(d)
		if d.Name == "Skin" and d.Parent then adopt(d.Parent) elseif d:IsA("GuiButton") then task.defer(adopt, d) end
	end)
end

return M
