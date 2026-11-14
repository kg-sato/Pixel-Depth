-- Marquee (ReplicatedStorage.Shared.Marquee), started by PixelClient. Next Systems Plan, phase E (2026-11-13): "a server
-- marquee when anyone hatches a Secret pet". When the server says a player hatched a Mythic or Secret pet (Fx "marquee",
-- display name, pet, rarity) a glass ribbon pops in right under the timer pills (clear of the quest card and of world prompts) on every screen, holds five seconds and pops out.
-- Several in a row wait their turn. Display only: the server decides who hatched what and sends the text's three parts.
local TweenService = game:GetService("TweenService")
local M = {}

function M.start(E)
	local GOLD, PINK = Color3.fromRGB(255, 214, 107), Color3.fromRGB(255, 120, 160)
	local bar = E.panel(E.gui, E.S(380, 40), E.S(606, 74), Vector2.new(0.5, 0.5), "pillLilac")
	bar.Name, bar.Visible, bar.ZIndex = "Marquee", false, 6
	local line = E.text(bar, "", UDim2.fromScale(0.9, 0.5), UDim2.fromScale(0.5, 0.46), Vector2.new(0.5, 0.5), GOLD, 700, false)
	line.Name, line.Font = "Line", E.HEAD or line.Font -- the headline font: Shared.JellyHUD turns it into jelly letters
	local sc = E.new("UIScale", bar, { Scale = 0 })
	local queue, busy = {}, false
	local function run()
		if busy then return end
		busy = true
		while #queue > 0 do
			local m = table.remove(queue, 1)
			line.Text, line.TextColor3 = m[1], m[2]
			bar.Visible, sc.Scale = true, 0
			TweenService:Create(sc, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			E.sfx("upgrade", 1.3)
			task.wait(5)
			local out = TweenService:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
			out:Play()
			out.Completed:Wait()
			bar.Visible = false
			task.wait(0.3)
		end
		busy = false
	end
	E.R.Fx.OnClientEvent:Connect(function(kind, who, pet, rarity)
		if kind ~= "marquee" or type(who) ~= "string" or type(pet) ~= "string" or type(rarity) ~= "string" then return end
		if #queue >= 4 then return end -- a burst of hatches never queues a minute of banners
		queue[#queue + 1] = { string.upper(string.sub(who, 1, 20)) .. "  HATCHED A " .. string.upper(rarity) .. "  " .. string.upper(pet) .. "!", rarity == "Secret" and GOLD or PINK }
		task.spawn(run)
	end)
end

return M
