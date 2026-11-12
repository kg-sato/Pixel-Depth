"""Field Notebook UI kit for Pixel Depth (2026-11-12): the 9-slice skins of the HUD and panels, drawn as SVG and rendered by
headless Edge on a transparent page, then cut into art/ui_notebook/<kind>.png. Same image sizes and slice centres as the glass
kit (art/ui_glass, slices in PixelClient SLICE), so only the SKIN ids change. Look: design board "Pixel Depth Notebook UI"
(vault brief UI Rework Field Notebook (2026-11-12)): torn paper strips with paint splats, voxel block buttons, parchment cards,
a notebook cover panel, a leather plate, wooden plank and comic header title bars.
    python art/pd_ui_notebook.py        (needs Edge; writes art/ui_notebook/*.png and _sheet.png)"""
import pathlib, subprocess, time
from PIL import Image

here = pathlib.Path(__file__).resolve().parent
out = here / "ui_notebook"; out.mkdir(exist_ok=True)
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
INK, PAPER, PAPER_D, LINE = "#2B2233", "#F3E6C4", "#E3D2A6", "#BBA674"
WOOD, WOOD_D, BROWN = "#8A5A33", "#6B4426", "#3B2416"
SIZE = {"butter": (160, 100), "card": (176, 136), "dark": (112, 112), "keycap": (72, 76), "keycapDown": (72, 76), "lilac": (160, 100),
        "mint": (160, 100), "off": (160, 100), "panel": (200, 200), "pill": (176, 76), "pillButter": (176, 80), "pillLilac": (176, 80),
        "pillMint": (176, 80), "pillPink": (176, 80), "pink": (160, 100), "ribbonLilac": (352, 104), "ribbonPink": (352, 104),
        "sky": (160, 100), "slot": (104, 104), "tab": (136, 84), "tabOn": (136, 84),
        "close": (96, 100), "grid": (128, 128)}  # close: the panel close block (sprite, not sliced); grid: the blueprint paper tile
BTN = {"mint": ("#25B5A0", "#167A6C"), "pink": ("#E0486D", "#9C2947"), "lilac": ("#6D8FF0", "#3A56B0"), "butter": ("#F6B93B", "#B9801F"),
       "sky": ("#5FB4E8", "#2F7DB3"), "off": ("#C4BCAE", "#8A8274")}
SPLAT = {"pillButter": "#F6B93B", "pillPink": "#E0486D", "pillMint": "#25B5A0", "pillLilac": "#4F7FE0", "pill": None}


def block(w, h, top, lip, face, edge, r=12, b=8, lipH=16):
    # a voxel block seen from the front: ink outline, a face and a darker bottom edge
    return (f'<rect x="4" y="{top}" width="{w - 8}" height="{h - top - 4}" rx="{r}" fill="{INK}"/>'
            f'<rect x="{4 + b}" y="{top + b}" width="{w - 8 - 2 * b}" height="{h - top - 4 - 2 * b}" rx="{r - 5}" fill="{edge}"/>'
            f'<rect x="{4 + b}" y="{top + b}" width="{w - 8 - 2 * b}" height="{h - top - 4 - 2 * b - lipH}" rx="{r - 5}" fill="{face}"/>'
            f'<rect x="{4 + b + 6}" y="{top + b + 5}" width="{w - 8 - 2 * b - 12}" height="5" rx="2.5" fill="#FFFFFF" opacity="0.28"/>')


def svg(kind):
    w, h = SIZE[kind]
    s = ""
    if kind in BTN:
        s = block(w, h, 4, 0, *BTN[kind])
    elif kind in SPLAT:
        y0, y1 = 14, h - 16  # the paper's straight top and bottom in the stretched middle
        if SPLAT[kind]:
            c = SPLAT[kind]
            s += f'<path d="M6 {h/2} C0 16 20 0 38 6 C58 0 78 12 72 30 C84 44 74 {h-6} 52 {h-4} C30 {h+2} 2 {h-10} 6 {h/2} Z" fill="{c}"/>'
            s += f'<circle cx="80" cy="{h-9}" r="5" fill="{c}"/><circle cx="12" cy="9" r="4" fill="{c}"/>'
        torn = (f"M10 {y0+6} L16 {y0} L40 {y0} L136 {y0} L160 {y0+2} L170 {y0+7} L166 {y0+16} L171 {(y0+y1)/2} L165 {y1-14} L170 {y1-5} L160 {y1} "
                f"L136 {y1} L40 {y1} L18 {y1-1} L9 {y1-6} L13 {y1-16} L8 {(y0+y1)/2+2} L12 {y0+18} Z")
        s += f'<path d="{torn}" transform="translate(0 6)" fill="#140C1C" opacity="0.5"/><path d="{torn}" fill="{PAPER}"/>'
        s += f'<path d="M40 {y1-5} L136 {y1-5} L160 {y1-5} L165 {y1-9} L160 {y1} L18 {y1-1} L12 {y1-5} Z" fill="{PAPER_D}" opacity="0.7"/>'
        if kind != "pill": s += f'<rect x="138" y="{y0-8}" width="26" height="12" fill="#25B5A0" opacity="0.85" transform="rotate(6 151 {y0-2})"/>'
    elif kind == "card":
        s = (f'<rect x="6" y="14" width="164" height="118" rx="12" fill="#140C1C" opacity="0.5"/>'
             f'<rect x="6" y="6" width="164" height="118" rx="12" fill="{BROWN}"/><rect x="13" y="13" width="150" height="104" rx="7" fill="{PAPER}"/>'
             f'<rect x="13" y="103" width="150" height="14" rx="7" fill="{PAPER_D}"/><rect x="13" y="100" width="150" height="8" fill="{PAPER}"/>')
    elif kind == "panel":
        s = (f'<rect x="6" y="18" width="188" height="178" rx="24" fill="#08040C" opacity="0.5"/>'
             f'<rect x="6" y="6" width="188" height="178" rx="24" fill="#3A2A45"/><rect x="6" y="6" width="188" height="170" rx="24" fill="#4A3857"/>'
             f'<rect x="20" y="20" width="160" height="150" rx="10" fill="{PAPER_D}"/><rect x="20" y="20" width="160" height="143" rx="10" fill="{PAPER}"/>')
    elif kind == "dark":
        s = (f'<rect x="4" y="10" width="104" height="98" rx="16" fill="#08040C" opacity="0.5"/>'
             f'<rect x="4" y="4" width="104" height="98" rx="16" fill="#2A1810"/><rect x="11" y="11" width="90" height="84" rx="10" fill="#5A3A2A"/>'
             f'<rect x="19" y="19" width="74" height="68" rx="6" fill="none" stroke="#E3B455" stroke-opacity="0.5" stroke-width="3"/>')
    elif kind in ("keycap", "keycapDown"):
        d = kind == "keycapDown"
        s = (f'<rect x="3" y="{10 if d else 3}" width="66" height="{63 if d else 70}" rx="10" fill="{INK}"/>'
             f'<rect x="9" y="{16 if d else 9}" width="54" height="{51 if d else 58}" rx="6" fill="{LINE}"/>'
             f'<rect x="9" y="{16 if d else 9}" width="54" height="{46 if d else 46}" rx="6" fill="#FFFDF4"/>')
    elif kind == "slot":
        s = (f'<rect x="4" y="4" width="96" height="96" rx="12" fill="{LINE}"/><rect x="10" y="10" width="84" height="84" rx="7" fill="{PAPER_D}"/>'
             f'<rect x="10" y="10" width="84" height="8" rx="4" fill="#C9B88A"/>')
    elif kind in ("tab", "tabOn"):
        face, edge = ("#F6B93B", "#B9801F") if kind == "tabOn" else (PAPER, LINE)
        s = (f'<path d="M4 84 L4 18 Q4 6 16 6 L120 6 Q132 6 132 18 L132 84 Z" fill="{INK}"/>'
             f'<path d="M12 84 L12 20 Q12 14 18 14 L118 14 Q124 14 124 20 L124 84 Z" fill="{face}"/>'
             f'<rect x="12" y="74" width="112" height="10" fill="{edge}"/>')
    elif kind == "close":  # a berry block with a cream X
        s = block(w, h, 4, 0, "#E0486D", "#9C2947") + '<path d="M32 28 L64 60 M64 28 L32 60" stroke="#FFF7E2" stroke-width="11" stroke-linecap="round"/>'
    elif kind == "grid":  # blueprint paper: one bold line and three faint ones each way, tiled in game
        s = '<rect width="128" height="128" fill="#2B63C6"/>' + "".join(f'<path d="M{i * 32} 0 V128 M0 {i * 32} H128" stroke="#FFFFFF" stroke-opacity="{0.3 if i == 0 else 0.12}" stroke-width="2"/>' for i in range(4))
    elif kind == "ribbonPink":  # a wooden plank with two brass nails
        s = (f'<rect x="8" y="18" width="336" height="74" rx="8" fill="#140C1C" opacity="0.5"/>'
             f'<rect x="8" y="8" width="336" height="74" rx="8" fill="{BROWN}"/><rect x="15" y="15" width="322" height="60" rx="4" fill="{WOOD}"/>'
             f'<rect x="15" y="20" width="322" height="3" fill="{WOOD_D}" opacity="0.6"/><rect x="15" y="63" width="322" height="12" rx="4" fill="{WOOD_D}"/>'
             f'<circle cx="32" cy="40" r="7" fill="{BROWN}"/><circle cx="32" cy="39" r="5" fill="#E3B455"/><circle cx="320" cy="40" r="7" fill="{BROWN}"/><circle cx="320" cy="39" r="5" fill="#E3B455"/>')
    elif kind == "ribbonLilac":  # the comic header: a marigold slanted bar with a hard ink shadow (menu titles only)
        s = (f'<path d="M34 20 L346 20 L326 96 L14 96 Z" fill="{INK}"/><path d="M26 8 L338 8 L318 84 L6 84 Z" fill="{INK}"/>'
             f'<path d="M36 16 L327 16 L311 76 L20 76 Z" fill="#F6B93B"/>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" style="position:absolute;left:{{x}}px;top:{{y}}px">{s}</svg>'


def main():
    kinds = sorted(SIZE)
    pos, x, y, rowH = {}, 10, 10, 0
    for k in kinds:
        w, h = SIZE[k]
        if x + w > 1390: x, y, rowH = 10, y + rowH + 10, 0
        pos[k] = (x, y); x += w + 10; rowH = max(rowH, h)
    H = y + rowH + 10
    page = out / "_sheet.html"
    page.write_text('<!doctype html><html><body style="margin:0;background:transparent">' + "".join(svg(k).format(x=pos[k][0], y=pos[k][1]) for k in kinds) + "</body></html>", encoding="utf-8")
    png = out / "_sheet.png"
    if png.exists(): png.unlink()
    p = subprocess.Popen([EDGE, "--headless=new", "--disable-gpu", "--no-first-run", f"--user-data-dir={out / '_edgeprof'}", "--hide-scrollbars", "--force-device-scale-factor=1",
                          "--default-background-color=00000000", f"--window-size=1400,{H}", f"--screenshot={png}", page.as_uri()], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    t0 = time.time()
    while time.time() - t0 < 40 and p.poll() is None and not png.exists(): time.sleep(0.5)
    time.sleep(1.5)
    if p.poll() is None: subprocess.run(["taskkill", "/F", "/T", "/PID", str(p.pid)], capture_output=True)  # only the browser started here
    sheet = Image.open(png).convert("RGBA")
    for k in kinds:
        (x, y), (w, h) = pos[k], SIZE[k]
        sheet.crop((x, y, x + w, y + h)).save(out / f"{k}.png")
    print("sheet", sheet.size, "alpha at 0,0:", sheet.getpixel((0, 0))[3], "kinds", len(kinds))


if __name__ == "__main__":
    main()
