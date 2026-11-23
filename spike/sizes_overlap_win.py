"""The Studio window shaping of sizes_overlap.py as a helper: shape(aspect) resizes the window until the game view has that
aspect; restore() puts it back."""
import ctypes, time
from ctypes import wintypes
import night as N
u = ctypes.windll.user32
found = []
@ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
def _cb(h, _):
    n = u.GetWindowTextLengthW(h)
    if n:
        b = ctypes.create_unicode_buffer(n + 1); u.GetWindowTextW(h, b, n + 1)
        if b.value.endswith("Roblox Studio") and u.IsWindowVisible(h): found.append(h)
    return True
u.EnumWindows(_cb, 0)
hwnd = found[0]
was_max = bool(u.IsZoomed(hwnd))
_r = wintypes.RECT(); u.GetWindowRect(hwnd, ctypes.byref(_r))
orig = (_r.left, _r.top, _r.right - _r.left, _r.bottom - _r.top)
def view():
    s = N.lua("local v=workspace.CurrentCamera.ViewportSize return math.floor(v.X)..' '..math.floor(v.Y)", "Client").splitlines()[-1].split()
    return int(s[0]), int(s[1])
def shape(aspect):
    if u.IsZoomed(hwnd): u.ShowWindow(hwnd, 9)
    w, h = orig[2], orig[3]
    for _ in range(6):
        u.SetWindowPos(hwnd, 0, orig[0], orig[1], w, h, 0x0004)
        time.sleep(1.5)
        vx, vy = view()
        if abs(vx / vy - aspect) < 0.05: return vx, vy
        w = int(w - (vx - aspect * vy))
    return view()
def restore():
    u.SetWindowPos(hwnd, 0, orig[0], orig[1], orig[2], orig[3], 0x0004)
    if was_max: u.ShowWindow(hwnd, 3)
