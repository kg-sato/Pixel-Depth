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
# the wheel stands in the world as a tilted panel: work out where the WARDROBE slot is drawn, then click that spot
xy = C1("local pg=game.Players.LocalPlayer.PlayerGui local sg=pg.SpatialPanels local part=sg.Adornee local d=sg.Holder.WARDROBE local p=d.AbsolutePosition+d.AbsoluteSize/2 local c=sg.CanvasSize "
        "local w=part.CFrame*Vector3.new(-(p.X/c.X-0.5)*part.Size.X,(0.5-p.Y/c.Y)*part.Size.Y,-part.Size.Z/2) local v=workspace.CurrentCamera:WorldToViewportPoint(w) "
        "local i=game:GetService('GuiService'):GetGuiInset() return math.floor(v.X)..','..math.floor(v.Y-i.Y)")
x, y = [int(v) for v in xy.split(",")]
print("slot drawn at", x, y, night.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "x": x, "y": y}], "datamodel_type": "Client"})[-90:]); time.sleep(1.2)
print(C1("local h=game.Players.LocalPlayer.PlayerGui.PixelHUD local n=0 for _,g in {h, h.Parent:FindFirstChild('SpatialPanels')} do for _,m in g:GetChildren() do if m.Name=='Wardrobe' and m.Visible then n+=1 end end end return 'wheel '..tostring(h.UtilityWheel.Visible)..', wardrobe panels open '..n"))
