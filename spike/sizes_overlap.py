"""HUD overlap check at other screen shapes (directive v10.0: 0 UI overlaps at 1080p, 1440p and mobile sizes).
Studio's game view cannot be set directly, so this resizes the Studio window until the view has the wanted shape, runs
spike/hud_overlap.luau in town and in the caves, takes a still of each, and puts the window back. Play must be off.
    python spike/sizes_overlap.py            stills and the report: captures/night/size_<shape>_<place>.png, size_report.txt
Shapes: 16:9 (1080p and 1440p are both 16:9: the HUD is laid out in Scale, so the shape decides overlaps) and a phone
in landscape (844 x 390, 2.16:1)."""
import ctypes, time
from ctypes import wintypes
import night as N

u = ctypes.windll.user32
found = []


@ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
def cb(h, _):
    n = u.GetWindowTextLengthW(h)
    if n:
        b = ctypes.create_unicode_buffer(n + 1); u.GetWindowTextW(h, b, n + 1)
        if b.value.endswith("Roblox Studio") and u.IsWindowVisible(h): found.append(h)
    return True


u.EnumWindows(cb, 0)
hwnd = found[0]
was_max = bool(u.IsZoomed(hwnd))
r = wintypes.RECT(); u.GetWindowRect(hwnd, ctypes.byref(r))
orig = (r.left, r.top, r.right - r.left, r.bottom - r.top)
OVER = open(N.game / "spike" / "hud_overlap.luau", encoding="utf-8").read()


def view():
    s = N.lua("local v=workspace.CurrentCamera.ViewportSize return math.floor(v.X)..' '..math.floor(v.Y)", "Client").splitlines()[-1].split()
    return int(s[0]), int(s[1])


def shape(aspect):
    if u.IsZoomed(hwnd): u.ShowWindow(hwnd, 9)  # restore from maximised so it can be sized
    w, h = orig[2], orig[3]
    for _ in range(6):
        u.SetWindowPos(hwnd, 0, orig[0], orig[1], w, h, 0x0004)
        time.sleep(1.5)
        vx, vy = view()
        if abs(vx / vy - aspect) < 0.05: return vx, vy
        w = int(w - (vx - aspect * vy))  # change the width by the view's width error
    return view()


out = []
try:
    N.play(True)
    for name, aspect in (("16x9", 16 / 9), ("phone", 844 / 390)):
        vx, vy = shape(aspect)
        time.sleep(2)
        rep = " | ".join(N.lua(OVER, "Client").strip().splitlines()[-8:])
        N.shot(f"size_{name}_town"); out.append(f"{name} {vx}x{vy} town: {rep}")
        N.key("Q"); time.sleep(32)
        rep = " | ".join(N.lua(OVER, "Client").strip().splitlines()[-8:])
        N.shot(f"size_{name}_cave"); out.append(f"{name} {vx}x{vy} cave: {rep}")
        N.play(False); time.sleep(2); N.play(True)
finally:
    N.play(False)
    u.SetWindowPos(hwnd, 0, orig[0], orig[1], orig[2], orig[3], 0x0004)
    if was_max: u.ShowWindow(hwnd, 3)
(N.out / "size_report.txt").write_text("\n".join(out) + "\n", encoding="utf-8")
print("\n".join(out))
