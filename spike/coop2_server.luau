-- Directive v14 phase 4: the real two-player co-op test (Studio only). spike/coop2_test.py installs this as ServerScriptService.Coop2Test
-- and starts StudioTestService:ExecuteMultiplayerTestAsync(2, { mode = "coop2" }); it does nothing in any other session.
-- Two real clients (spike/coop2_client.luau runs their side): the clink pair in town, both ride down, a HELP ping heard by the
-- other, a grab (Studio hook DevGrab) freed by the friend's pickaxe (GloomStrike, the Savior bonus), and a crew of two on Camp 1's
-- cart (Studio hook DevBoard = the V prompt) with each rider's job and the result card's spacing over CONTINUE.
local STS = game:GetService("StudioTestService")
local ok, args = pcall(function() return STS:GetTestArgs() end)
if not ok or type(args) ~= "table" or args.mode ~= "coop2" then return end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local R = Instance.new("RemoteEvent")
R.Name = "CoopTestR"
R.Parent = RS
local log, got = {}, {}
local function L(s) table.insert(log, s) print("[coop2] " .. s) end
R.OnServerEvent:Connect(function(p, kind, v)
	local k = p.Name .. ":" .. tostring(kind)
	got[k] = (got[k] or 0) + 1
	if v ~= nil then got[k .. "="] = tostring(v) end
end)
local function hrp(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local t0 = os.clock()
local ps
repeat
	task.wait(0.5)
	ps = Players:GetPlayers()
until (#ps >= 2 and hrp(ps[1]) and hrp(ps[2])) or os.clock() - t0 > 120
if #ps < 2 then STS:EndTest({ ok = false, log = { "only " .. #ps .. " players joined" } }) return end
local A, B = ps[1], ps[2]
L("players " .. A.Name .. " + " .. B.Name)
task.wait(12) -- profiles load and the town settles
local function g(p, k) return tostring(got[p.Name .. ":" .. k]) end
-- 1 the clink pair in town
hrp(B).CFrame = hrp(A).CFrame * CFrame.new(5, 0, 0)
task.wait(1.5)
R:FireAllClients("clink")
task.wait(3)
L("clink: A heard B's clink=" .. g(A, "fx_clink") .. " pair=" .. g(A, "fx_clinkPair") .. " | B heard=" .. g(B, "fx_clink") .. " pair=" .. g(B, "fx_clinkPair"))
-- 2 both ride down to Camp 1
R:FireAllClients("down")
local t1 = os.clock()
repeat task.wait(1) until (A:GetAttribute("InCave") and B:GetAttribute("InCave")) or os.clock() - t1 > 70
L("down: A InCave=" .. tostring(A:GetAttribute("InCave")) .. " B InCave=" .. tostring(B:GetAttribute("InCave")))
task.wait(5)
if hrp(A) and hrp(B) then hrp(B).CFrame = hrp(A).CFrame * CFrame.new(4, 0, 0) end
task.wait(1.5)
-- 3 a HELP ping from A, heard by B
R:FireClient(A, "ping")
task.wait(2.5)
L("ping: B got=" .. g(B, "fx_ping") .. " (" .. g(B, "fx_ping=") .. ")")
-- 4 B is grabbed, A frees B with the pickaxe
B:SetAttribute("DevGrab", true)
task.wait(1.2)
local grabbed = B:GetAttribute("GrabbedUntil") ~= nil
if hrp(A) and hrp(B) then hrp(A).CFrame = hrp(B).CFrame * CFrame.new(3, 0, 0) end
task.wait(0.8)
R:FireClient(A, "strike", B)
task.wait(2.5)
L("rescue: grabbed=" .. tostring(grabbed) .. " freed=" .. tostring(B:GetAttribute("GrabbedUntil") == nil) .. " A savior=" .. g(A, "fx_saviorBonus") .. " A rescuedFriend=" .. g(A, "fx_rescuedFriend") .. " B rescued=" .. g(B, "fx_rescued"))
B:SetAttribute("DevGrab", nil)
task.wait(16) -- the grab's shield and the camp settle before the ride
-- 5 a crew of two on Camp 1's cart
R:FireAllClients("crewdbg")
task.wait(0.5)
A:SetAttribute("DevBoard", true)
task.wait(0.6)
B:SetAttribute("DevBoard", true)
task.wait(0.8)
L("board: A seat=" .. tostring(A:GetAttribute("CrewSeat")) .. " B seat=" .. tostring(B:GetAttribute("CrewSeat")))
A:SetAttribute("DevBoard", nil)
task.wait(0.3)
A:SetAttribute("DevBoard", true) -- the driver presses again: go now
task.wait(8)
-- v15: the crew's Gloom runs on the server (DevCrewGap is its gap, set 4x a second in Studio): it creeps in, B's flare pushes it back,
-- and both clients hold the server's number ("G")
local g1 = A:GetAttribute("DevCrewGap")
task.wait(3)
local g2 = A:GetAttribute("DevCrewGap")
R:FireClient(B, "flare")
task.wait(0.7)
local g3 = A:GetAttribute("DevCrewGap")
R:FireAllClients("gap")
task.wait(1.2)
L(("crew gloom: server %s -> %s (creep) -> %s (flare) | A sees %s, B sees %s | creeps=%s pushed=%s"):format(tostring(g1), tostring(g2), tostring(g3), g(A, "gap="), g(B, "gap="),
	tostring(type(g1) == "number" and type(g2) == "number" and g2 < g1), tostring(type(g2) == "number" and type(g3) == "number" and g3 > g2)))
task.wait(3)
R:FireAllClients("state")
task.wait(2)
L("ride: A=" .. g(A, "state=") .. " | B=" .. g(B, "state="))
for _ = 1, 60 do -- the result card, as soon as it is up on both (v15: every 1.5 s; the card shows about 6 s, so a 7.5 s probe could miss it)
	task.wait(1)
	R:FireAllClients("card")
	task.wait(0.5)
	local ca, cb = got[A.Name .. ":card="], got[B.Name .. ":card="]
	if ca and ca ~= "none" and cb and cb ~= "none" then break end
end
L("card: A " .. g(A, "card=") .. " | B " .. g(B, "card="))
STS:EndTest({ ok = true, log = log })
