"""The wheel's touch path: show the TOOLS button (DevTouch), click it, click the WARDROBE slot (town).
    python spike/wheel_touch_test.py     (starts Play itself; shot captures/night/wheel_touch.png)"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
def click(path):
    return night.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": path}], "datamodel_type": "Client"})[-90:]
C1 = lambda code: night.lua(code, "Client").splitlines()[-1]
night.play(True); time.sleep(5)
name = C1("game.Players.LocalPlayer:SetAttribute('DevTouch',1) return game.Players.LocalPlayer.Name")
hud = f"Players.{name}.PlayerGui.PixelHUD"
print(click(hud + ".LeftColumn.Buttons.ToolsButton")); time.sleep(1)
print("wheel open:", C1("return tostring(game.Players.LocalPlayer.PlayerGui.PixelHUD.UtilityWheel.Visible)"))
print(night.shot("wheel_touch").name)
print(click(hud + ".UtilityWheel.Holder.WARDROBE.Tap")); time.sleep(1.2)
print(C1("local h=game.Players.LocalPlayer.PlayerGui.PixelHUD local n=0 for _,g in {h, h.Parent:FindFirstChild('SpatialPanels')} do for _,m in g:GetChildren() do if m.Name=='Wardrobe' and m.Visible then n+=1 end end end return 'wheel '..tostring(h.UtilityWheel.Visible)..', wardrobe panels open '..n"))
