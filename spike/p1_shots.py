"""Directive v13 phase 1 stills: town HUD standard and dynamic, the Codex, a boon offer, the Soul Tree, the settings with the
Dynamic HUD row, the touch layout in the caves.   python spike/p1_shots.py <prefix>"""
import sys, time
import night as N
pre = sys.argv[1] if len(sys.argv) > 1 else "p1"
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
N.play(True); time.sleep(12)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
time.sleep(2)
N.shot(pre + "_town_std")
print("dynamic:", C("game.Players.LocalPlayer:SetAttribute('HudDynamic',true) return 1")); time.sleep(10)
N.shot(pre + "_town_dyn")
print("left column x:", C("return game.Players.LocalPlayer.PlayerGui.PixelHUD.LeftColumn.Position.X.Scale"))
C("game.Players.LocalPlayer:SetAttribute('HudDynamic',nil) return 1"); time.sleep(1.5)
S(P + "p:SetAttribute('DevCodex',12) for _,n in {'Fafnir','Shinemane','Kirin','Tosk'} do p:SetAttribute('DevMarquee',n) task.wait(1.2) end return 1"); time.sleep(2)
for _ in range(3):  # the key can land while a marquee holds the input: retry until the gallery is up
    N.key("K"); time.sleep(2.5)
    if C("return tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('Codex',true).Visible)") == "true": break
N.shot(pre + "_codex")
N.key("K"); time.sleep(1.2)
S(P + "game.ReplicatedStorage.Remotes.Fx:FireClient(p,'boonOffer','flare','shield') return 1"); time.sleep(2.2)
N.shot(pre + "_boon")
C("for _,d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do if d.Name=='BoonClose' and d:IsA('GuiButton') then end end local b=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Boon',true) if b then b.Visible=false end return 1"); time.sleep(1)
S(P + "p:SetAttribute('DevSoul',12) return 1"); time.sleep(1)
C("game.Players.LocalPlayer:SetAttribute('DevOpen','soul') return 1"); time.sleep(2.5)
N.shot(pre + "_soul")
C("game.Players.LocalPlayer:SetAttribute('DevOpen',nil) local w=game.Players.LocalPlayer.PlayerGui:FindFirstChild('SoulTree',true) if w then w.Visible=false end return 1"); time.sleep(1)
N.key("N"); time.sleep(2.5)
N.shot(pre + "_settings")
N.key("N"); time.sleep(1)
print("errors:", C("local n=0 for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not m.message:find('not authorized') then n+=1 end end return n"))
