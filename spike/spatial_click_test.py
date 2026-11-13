"""Do clicks reach a menu that stands in the world (Shared.SpatialPanels)? Starts Play itself.
Opens the bag (B), works out where its close button is drawn, clicks there, and says whether the bag closed.
    python spike/spatial_click_test.py"""
import time
import night as N
C1 = lambda code: N.lua(code, "Client").splitlines()[-1]
MAP = ("local sg=o:FindFirstAncestorWhichIsA('SurfaceGui') local c=o.AbsolutePosition+o.AbsoluteSize/2 if sg then local part=sg.Adornee local cs=sg.CanvasSize "
       "local w=part.CFrame*Vector3.new(-(c.X/cs.X-0.5)*part.Size.X,(0.5-c.Y/cs.Y)*part.Size.Y,-part.Size.Z/2) local v=workspace.CurrentCamera:WorldToViewportPoint(w) "
       "local i=game:GetService('GuiService'):GetGuiInset() c=Vector2.new(v.X,v.Y-i.Y) end return math.floor(c.X)..','..math.floor(c.Y)..','..tostring(sg~=nil)")
N.play(True); time.sleep(8)
N.key("B"); time.sleep(1.5)
r = C1("local inv=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Inventory',true) local o for _,d in inv:GetDescendants() do if d:IsA('ImageButton') and string.find(d.Name,'Close') then o=d break end end " + MAP)
x, y, spatial = r.split(",")
print("close button drawn at", x, y, "in a world panel:", spatial)
N.run("user_mouse_input", {"actions": [{"action": "moveTo", "x": int(x), "y": int(y)}, {"action": "mouseButtonClick", "mouse_button": "left"}], "datamodel_type": "Client"})
time.sleep(0.8)
print("bag still open:", C1("return tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('Inventory',true).Visible)"))
