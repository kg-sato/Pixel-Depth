"""Directive v14 phase 1 stills for the blind grade: menu open, bag, codex, a toast mid-pop and settled, the hearth wash, then in
the caves the tip ribbon, the lead pet, the boss wake stack and the reticle.   python spike/v14_p1_shots.py <prefix>
Stills land in captures/night/<prefix>_<name>.png (Play is started and stopped here)."""
import sys, time
import night as N
pre = sys.argv[1] if len(sys.argv) > 1 else "v14p1"
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
HUD = "game.Players.LocalPlayer.PlayerGui.PixelHUD"
shot = lambda n: N.shot(f"{pre}_{n}")

N.play(False); time.sleep(2); N.play(); time.sleep(10)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1"); time.sleep(1)
path = "Players." + C("return game.Players.LocalPlayer.Name") + ".PlayerGui.PixelHUD"
menu = C("local m=" + HUD + ":FindFirstChild('MenuButton',true) return m and m:GetFullName() or 'none'")
if menu != "none":
    N.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": menu.replace("Players.", "Players.", 1)}], "datamodel_type": "Client"})
    time.sleep(1.5); shot("menu")
    N.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": menu}], "datamodel_type": "Client"}); time.sleep(1)
N.key("B"); time.sleep(2.5); shot("bag"); N.key("B"); time.sleep(1.2)
S(P + "p:SetAttribute('DevCodex',12) return 1"); time.sleep(1.5)
for _ in range(3):
    N.key("K"); time.sleep(2.5)
    if C("local c=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Codex',true) return tostring(c and c.Visible)") == "true": break
shot("codex"); N.key("K"); time.sleep(1.2)
C("require(game.ReplicatedStorage.Shared.ToastManager).show('DODGED!', Color3.fromRGB(120,255,200), false) return 1"); time.sleep(0.18); shot("toast_pop")
time.sleep(1.0); shot("toast_settled"); time.sleep(3)
C("require(game.ReplicatedStorage.Shared.ToastManager).show('THE ROOT WARDEN WAKES!  CRACK ITS 3 KNOTS', Color3.fromRGB(255,190,90), true) return 1"); time.sleep(1.2); shot("toast_long"); time.sleep(3)
S(P + "game.ReplicatedStorage.Remotes.Fx:FireClient(p,'home','done',300) return 1"); time.sleep(0.12); shot("hearth")
time.sleep(4)
N.key("Q"); time.sleep(26)  # ride down to Camp 1
shot("cave_camp")
S(P + "for _,d in workspace.Caves:GetDescendants() do end return 1")
C("local f=game.Players.LocalPlayer.PlayerGui:FindFirstChild('TipBanner',true) if f then f.Visible=true local t=f:FindFirstChildWhichIsA('TextLabel',true) if t then t.Text='TIP: STRIKE ON THE GOLD FOR A PERFECT HIT' end end return f and 'tip' or 'none'"); time.sleep(0.8)
shot("cave_tip")
print("errors:", C("local n=0 for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not m.message:find('not authorized') then n+=1 end end return n"))
