"""The folded HUD (Shared.HudCompact) and the one timers pill: do the buttons hide behind MENU, open on a click and fold again,
and does the top of the screen hold one pill?   python spike/menu_test.py"""
import time, pathlib
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
HUD = "game.Players.LocalPlayer.PlayerGui.PixelHUD"
def click(path): return N.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": path.replace(HUD, PATH)}], "datamodel_type": "Client"})[-60:]
STATE = ("local h=" + HUD + " local r=h.LeftColumn.Buttons local t=h:FindFirstChild('Timers',true) local n=0 for _,c in t:GetChildren() do if c:IsA('GuiObject') and c.Visible then n+=1 end end "
         "return 'buttons '..tostring(r.Visible)..' attr '..tostring(game.Players.LocalPlayer:GetAttribute('MenuOpen'))..' | timer boxes showing '..n..' | list '..tostring(t.Drop.Visible)")
N.play(True); time.sleep(8)
C1("game.Players.LocalPlayer:SetAttribute('DevRidden', true) return 1"); time.sleep(0.5)  # the pill hides until the first ride (2026-11-20)
PATH = "Players." + C1("return game.Players.LocalPlayer.Name") + ".PlayerGui.PixelHUD"  # the click tool wants the path from the data model's root
print("at the start:", C1(STATE))
click(HUD + ".LeftColumn.Currency.MenuButton.Hit"); time.sleep(0.8)
print("MENU clicked:", C1(STATE))
print("overlaps with the menu open:", C1(open(pathlib.Path(N.__file__).resolve().parent / "hud_overlap.luau", encoding="utf-8").read()))
click(HUD + ".LeftColumn.Buttons.InventoryButton"); time.sleep(1.2)
print("BAG used:", C1(STATE))
N.key("B"); time.sleep(0.8)
click(HUD + ".LeftColumn.Currency.MenuButton.Hit"); time.sleep(0.6)
click(HUD + ".LeftColumn.Currency.MenuButton.Hit"); time.sleep(0.6)
print("MENU twice:", C1(STATE))
click(HUD + ".Timers.Main.Open"); time.sleep(0.8)
print("timers pill clicked:", C1(STATE))
click(HUD + ".Timers.Main.Open"); time.sleep(0.8)
print("timers pill clicked again:", C1(STATE))
print("overlaps at rest:", C1(open(pathlib.Path(N.__file__).resolve().parent / "hud_overlap.luau", encoding="utf-8").read()))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
