-- Splash (ReplicatedFirst.Splash, a LocalScript). Directive v14 phase 1 (audit 2026-11-21, bug 1): a player joined to 3 to 6
-- seconds of bare Roblox sky before the game's own loading screen (Shared.LoadingScreen, started by PixelClient after the
-- place replicates). ReplicatedFirst runs first, so this cover goes up in the first frame: the same obsidian-to-plum backdrop
-- as the loading screen (so the hand-off is invisible), the default Roblox loader removed, a soft pulse so it never looks
-- frozen. It steps aside the moment LoadingScreen's own ScreenGui (PixelLoading) exists, or once the game and the character
-- are in when the intro is off (DevNoIntro, Config.LOADING.on = false), and never stays longer than 12 seconds.
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")
local OBSIDIAN, PLUM = Color3.fromRGB(14, 6, 26), Color3.fromRGB(46, 18, 72)
local LAV = Color3.fromRGB(214, 196, 255)

local gui = Instance.new("ScreenGui")
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.ZIndexBehavior = "PixelSplash", true, false, 999, Enum.ZIndexBehavior.Sibling
local all = Instance.new("CanvasGroup")
all.Name, all.Size, all.BackgroundColor3, all.BorderSizePixel = "All", UDim2.fromScale(1, 1), PLUM, 0
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, OBSIDIAN), ColorSequenceKeypoint.new(0.5, PLUM), ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 12, 54)) })
grad.Parent = all
-- three soft gems pulsing in turn: "loading", never a frozen frame
local dots = {}
for i = 1, 3 do
	local d = Instance.new("Frame")
	d.Size, d.SizeConstraint = UDim2.fromScale(0.014, 0.014), Enum.SizeConstraint.RelativeYY
	d.Position, d.AnchorPoint, d.Rotation = UDim2.fromScale(0.5 + (i - 2) * 0.03, 0.62), Vector2.new(0.5, 0.5), 45
	d.BackgroundColor3, d.BackgroundTransparency, d.BorderSizePixel = LAV, 0.5, 0
	d.Parent = all
	dots[i] = d
end
all.Parent = gui
gui.Parent = pg
-- v16.1 (the 2:35 blue-sky flash): the default loading screen goes only once this cover is parented. Removed first, the bare
-- default sky showed for seconds until PlayerGui came (DevForum "Stare at the sky for a long time before loading", 2023).
ReplicatedFirst:RemoveDefaultLoadingScreen()

local t0 = os.clock()
local pulse = RunService.RenderStepped:Connect(function()
	local t = os.clock() - t0
	for i, d in dots do
		local k = (math.sin(t * 5 - i * 0.9) + 1) / 2
		d.BackgroundTransparency = 0.75 - 0.55 * k
		d.Size = UDim2.fromScale(0.011 + 0.006 * k, 0.011 + 0.006 * k)
	end
end)

local function handedOff()
	if pg:FindFirstChild("PixelLoading") then return true end
	-- the intro is off: the cover lifts once the world and the character are in
	return game:IsLoaded() and plr.Character ~= nil and os.clock() - t0 > 1.5 and plr:GetAttribute("DevNoIntro") ~= nil
end
while os.clock() - t0 < 12 do -- the failsafe: a stuck load never leaves the player on a blank screen
	if handedOff() then break end
	if game:IsLoaded() and plr.Character and os.clock() - t0 > 8 then break end -- loaded but no intro screen came (Config.LOADING.on = false)
	task.wait(0.05)
end
task.wait(0.15) -- one frame for the loading screen to draw underneath, so the two never show a gap
local out = TweenService:Create(all, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { GroupTransparency = 1 })
out.Completed:Connect(function()
	pulse:Disconnect()
	gui:Destroy()
end)
out:Play()
