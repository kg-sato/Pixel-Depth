"""Field Notebook UI kit for Pixel Depth, painted pass (2026-11-12): the 9-slice skins of the HUD and panels, drawn as SVG with
procedural material (wood grain, paper fibre, leather pores, bevel light) and rendered by headless Edge on a transparent page,
then cut into art/ui_notebook/<kind>.png. Same image sizes and slice centres as the glass kit (art/ui_glass, slices in
PixelClient SLICE), so only the SKIN ids change. Look: design board "Pixel Depth Notebook UI" (vault brief UI Rework Field
Notebook (2026-11-12)). The first pass was flat fills; a harsh grader plateaued on "no material depth", so every surface now
carries grain and a lit top edge. Texture sits mostly in the corners and edges: a 9-slice stretches its middle.
    python art/pd_ui_notebook.py        (needs Edge; writes art/ui_notebook/*.png, _sheet.png, _preview.jpg)"""
import pathlib, subprocess, time
from PIL import Image

here = pathlib.Path(__file__).resolve().parent
out = here / "ui_notebook"; out.mkdir(exist_ok=True)
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
INK, PAPER, PAPER_D, LINE = "#2B2233", "#F3E6C4", "#E3D2A6", "#BBA674"
WOOD, WOOD_L, WOOD_D, BROWN = "#A06A3A", "#C08A52", "#6B4426", "#3B2416"
SIZE = {"butter": (160, 100), "card": (176, 136), "dark": (112, 112), "keycap": (72, 76), "keycapDown": (72, 76), "lilac": (160, 100),
        "mint": (160, 100), "off": (160, 100), "panel": (200, 200), "pill": (176, 76), "pillButter": (176, 80), "pillLilac": (176, 80),
        "pillMint": (176, 80), "pillPink": (176, 80), "pink": (160, 100), "ribbonLilac": (352, 104), "ribbonPink": (352, 104),
        "sky": (160, 100), "slot": (104, 104), "tab": (136, 84), "tabOn": (136, 84),
        "close": (96, 100), "grid": (128, 128), "dial": (512, 512)}  # close: sprite; grid: blueprint tile; dial: the brass compass body (wheel, survival dial, radar)
PAINT = {"mint": "#2FA896", "pink": "#D8456B", "lilac": "#6D8FF0", "butter": "#F0B43A", "sky": "#5FB4E8", "off": "#B9B0A0"}
SPLAT = {"pillButter": "#E9AE36", "pillPink": "#C93A5F", "pillMint": "#2A9E8C", "pillLilac": "#4F7FE0", "pill": None}

# material filters, defined once for the page. Each lays noise over the shape it is applied to (operator atop keeps the shape).
DEFS = """<svg width="0" height="0" style="position:absolute"><defs>
<filter id="wood" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.012 0.42" numOctaves="3" seed="7" result="n"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 0.22  0 0 0 0 0.12  0 0 0 0 0.06  0 0 0 -2.2 1.3" result="dark"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 1  0 0 0 0 0.86  0 0 0 0 0.62  0 0 0 2.0 -1.05" result="light"/>
<feComposite in="dark" in2="SourceGraphic" operator="atop" result="a"/><feComposite in="light" in2="a" operator="atop"/></filter>
<filter id="paper" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.035 0.7" numOctaves="2" seed="11" result="n"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 0.45  0 0 0 0 0.33  0 0 0 0 0.16  0 0 0 -1.3 0.6" result="fib"/>
<feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="1" seed="5" result="s"/>
<feColorMatrix in="s" type="matrix" values="0 0 0 0 0.36  0 0 0 0 0.25  0 0 0 0 0.12  0 0 0 -3 1.36" result="speck"/>
<feComposite in="fib" in2="SourceGraphic" operator="atop" result="a"/><feComposite in="speck" in2="a" operator="atop"/></filter>
<filter id="paperSoft" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.035 0.7" numOctaves="2" seed="11" result="n"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 0.45  0 0 0 0 0.33  0 0 0 0 0.16  0 0 0 -0.5 0.27" result="fib"/>
<feComposite in="fib" in2="SourceGraphic" operator="atop"/></filter>
<filter id="leather" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.55" numOctaves="3" seed="3" result="n"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 0.1  0 0 0 0 0.05  0 0 0 0 0.03  0 0 0 -2.6 1.5" result="pore"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 0.86  0 0 0 0 0.62  0 0 0 0 0.44  0 0 0 2.2 -1.44" result="shine"/>
<feComposite in="pore" in2="SourceGraphic" operator="atop" result="a"/><feComposite in="shine" in2="a" operator="atop"/></filter>
<filter id="metal" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.02 0.6" numOctaves="2" seed="9" result="n"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 1  0 0 0 0 0.95  0 0 0 0 0.75  0 0 0 2.4 -1.25" result="l"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 0.3  0 0 0 0 0.18  0 0 0 0 0.04  0 0 0 -2.4 1.3" result="d"/>
<feComposite in="d" in2="SourceGraphic" operator="atop" result="a"/><feComposite in="l" in2="a" operator="atop"/></filter>
<filter id="soft"><feGaussianBlur stdDeviation="3"/></filter>
<linearGradient id="gWood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C08A52"/><stop offset="0.55" stop-color="#A06A3A"/><stop offset="1" stop-color="#8A5A30"/></linearGradient>
<linearGradient id="gPaper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FBF1D6"/><stop offset="0.7" stop-color="#F3E6C4"/><stop offset="1" stop-color="#E6D5A8"/></linearGradient>
<linearGradient id="gLeather" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#70493A"/><stop offset="1" stop-color="#48302A"/></linearGradient>
<linearGradient id="gCover" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5B4568"/><stop offset="1" stop-color="#3A2A45"/></linearGradient>
<linearGradient id="gBrass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFE9A6"/><stop offset="0.25" stop-color="#E3B455"/><stop offset="0.5" stop-color="#8E6420"/><stop offset="0.75" stop-color="#E9BE62"/><stop offset="1" stop-color="#A9782A"/></linearGradient>
<linearGradient id="gBrass2" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7C5618"/><stop offset="0.5" stop-color="#F0CC78"/><stop offset="1" stop-color="#8E6420"/></linearGradient>
<radialGradient id="gFace" cx="0.5" cy="0.42" r="0.6"><stop offset="0" stop-color="#6A4636"/><stop offset="1" stop-color="#2E1D1A"/></radialGradient>
</defs></svg>"""


def wood_block(w, h, paint=None, top=4):
    # a wooden block seen from the front: bark outline, grained face with a lit top edge, a darker bottom edge, two nails
    x0, x1, y1 = 4, w - 4, h - 4
    s = (f'<rect x="{x0}" y="{top + 5}" width="{w - 8}" height="{h - top - 6}" rx="12" fill="#140C1C" opacity="0.45"/>'
         f'<rect x="{x0}" y="{top}" width="{w - 8}" height="{h - top - 8}" rx="12" fill="{BROWN}"/>'
         f'<rect x="{x0 + 7}" y="{top + 7}" width="{w - 22}" height="{h - top - 22}" rx="7" fill="{WOOD_D}" filter="url(#wood)"/>'
         f'<rect x="{x0 + 7}" y="{top + 7}" width="{w - 22}" height="{h - top - 36}" rx="7" fill="url(#gWood)" filter="url(#wood)"/>'
         f'<rect x="{x0 + 11}" y="{top + 10}" width="{w - 30}" height="4" rx="2" fill="#FFE2B0" opacity="0.5"/>')
    if paint:  # a band of paint brushed across the top, a little uneven
        s += (f'<path d="M{x0 + 9} {top + 16} Q{w / 2} {top + 12} {x1 - 9} {top + 17} L{x1 - 9} {top + 29} Q{w / 2} {top + 33} {x0 + 9} {top + 28} Z" fill="{paint}" filter="url(#paper)"/>'
              f'<path d="M{x0 + 12} {top + 18} H{x1 - 12}" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="3" stroke-linecap="round"/>')
    for cx in (x0 + 16, x1 - 16):
        s += f'<circle cx="{cx}" cy="{y1 - 22}" r="3.2" fill="{BROWN}"/><circle cx="{cx - 0.8}" cy="{y1 - 22.8}" r="1.6" fill="#E9BE62"/>'
    return s


def svg(kind):
    w, h = SIZE[kind]
    s = ""
    if kind in PAINT:
        s = wood_block(w, h, PAINT[kind])
    elif kind in SPLAT:
        y0, y1 = 14, h - 16  # the paper's straight top and bottom in the stretched middle
        if SPLAT[kind]:
            c = SPLAT[kind]
            s += f'<path d="M6 {h/2} C0 16 20 0 38 6 C58 0 78 12 72 30 C84 44 74 {h-6} 52 {h-4} C30 {h+2} 2 {h-10} 6 {h/2} Z" fill="{c}" filter="url(#paper)"/>'
            s += f'<circle cx="80" cy="{h-9}" r="5" fill="{c}"/><circle cx="12" cy="9" r="4" fill="{c}"/><path d="M14 22 Q26 10 42 12" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="4" fill="none" stroke-linecap="round"/>'
        torn = (f"M10 {y0+6} L16 {y0} L40 {y0} L136 {y0} L160 {y0+2} L170 {y0+7} L166 {y0+16} L171 {(y0+y1)/2} L165 {y1-14} L170 {y1-5} L160 {y1} "
                f"L136 {y1} L40 {y1} L18 {y1-1} L9 {y1-6} L13 {y1-16} L8 {(y0+y1)/2+2} L12 {y0+18} Z")
        s += f'<path d="{torn}" transform="translate(0 6)" fill="#140C1C" opacity="0.5"/><path d="{torn}" fill="url(#gPaper)" filter="url(#paperSoft)"/>'
        s += f'<path d="M40 {y1-5} L136 {y1-5} L160 {y1-5} L165 {y1-9} L160 {y1} L18 {y1-1} L12 {y1-5} Z" fill="#C9B480" opacity="0.6"/>'
        s += f'<path d="M18 {y0+3} H160" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="2"/>'
        if kind != "pill": s += f'<rect x="138" y="{y0-8}" width="26" height="12" fill="#2FA896" opacity="0.82" transform="rotate(6 151 {y0-2})"/><rect x="138" y="{y0-8}" width="26" height="4" fill="#FFFFFF" opacity="0.25" transform="rotate(6 151 {y0-2})"/>'
    elif kind == "card":  # a parchment card in a thin wooden frame
        s = (f'<rect x="6" y="14" width="164" height="118" rx="12" fill="#140C1C" opacity="0.5"/>'
             f'<rect x="6" y="6" width="164" height="118" rx="12" fill="{BROWN}"/><rect x="9" y="9" width="158" height="112" rx="10" fill="url(#gWood)" filter="url(#wood)"/>'
             f'<rect x="15" y="15" width="146" height="100" rx="6" fill="{BROWN}"/><rect x="17" y="17" width="142" height="96" rx="5" fill="url(#gPaper)" filter="url(#paperSoft)"/>'
             f'<rect x="17" y="17" width="142" height="5" rx="2" fill="#8A6A3A" opacity="0.25"/>')
    elif kind == "panel":  # the notebook: a cloth cover with a lit edge, a stack of page edges, the page
        s = (f'<rect x="6" y="18" width="188" height="178" rx="24" fill="#08040C" opacity="0.5"/>'
             f'<rect x="6" y="6" width="188" height="178" rx="24" fill="#2A1C33"/><rect x="8" y="8" width="184" height="168" rx="22" fill="url(#gCover)" filter="url(#leather)"/>'
             f'<rect x="14" y="12" width="172" height="4" rx="2" fill="#FFFFFF" opacity="0.14"/>'
             f'<rect x="18" y="18" width="164" height="154" rx="11" fill="#C9B480"/><rect x="19" y="19" width="162" height="150" rx="10" fill="#E3D2A6"/>'
             f'<rect x="20" y="20" width="160" height="145" rx="10" fill="url(#gPaper)" filter="url(#paperSoft)"/>')
    elif kind == "dark":  # a leather plate with a stitched line
        s = (f'<rect x="4" y="10" width="104" height="98" rx="16" fill="#08040C" opacity="0.5"/>'
             f'<rect x="4" y="4" width="104" height="98" rx="16" fill="#2A1810"/><rect x="10" y="10" width="92" height="86" rx="11" fill="url(#gLeather)" filter="url(#leather)"/>'
             f'<rect x="14" y="13" width="84" height="4" rx="2" fill="#FFD9B0" opacity="0.18"/>'
             f'<rect x="19" y="19" width="74" height="68" rx="6" fill="none" stroke="#E3B455" stroke-opacity="0.55" stroke-width="2.5"/>')
    elif kind in ("keycap", "keycapDown"):  # a bone key on a dark base
        d = kind == "keycapDown"
        s = (f'<rect x="3" y="{10 if d else 3}" width="66" height="{63 if d else 70}" rx="10" fill="{BROWN}"/>'
             f'<rect x="9" y="{16 if d else 9}" width="54" height="{51 if d else 58}" rx="6" fill="#B49A66"/>'
             f'<rect x="9" y="{16 if d else 9}" width="54" height="46" rx="6" fill="url(#gPaper)" filter="url(#paperSoft)"/>'
             f'<rect x="13" y="{19 if d else 12}" width="46" height="4" rx="2" fill="#FFFFFF" opacity="0.6"/>')
    elif kind == "slot":  # a recess cut into the page
        s = (f'<rect x="4" y="4" width="96" height="96" rx="12" fill="#9C8654"/><rect x="9" y="9" width="86" height="86" rx="8" fill="#D6C493" filter="url(#paperSoft)"/>'
             f'<rect x="9" y="9" width="86" height="10" rx="5" fill="#6B5630" opacity="0.35"/><rect x="9" y="88" width="86" height="7" rx="3" fill="#FFFFFF" opacity="0.35"/>')
    elif kind in ("tab", "tabOn"):
        s = (f'<path d="M4 84 L4 18 Q4 6 16 6 L120 6 Q132 6 132 18 L132 84 Z" fill="{BROWN}"/>'
             f'<path d="M11 84 L11 20 Q11 13 18 13 L118 13 Q125 13 125 20 L125 84 Z" fill="url(#gWood)" filter="url(#wood)"/>'
             f'<rect x="16" y="16" width="104" height="4" rx="2" fill="#FFE2B0" opacity="0.5"/>')
        if kind == "tabOn": s += f'<path d="M14 24 Q68 19 122 25 L122 40 Q68 45 14 39 Z" fill="#F0B43A" filter="url(#paper)"/>'
        else: s += f'<rect x="11" y="72" width="114" height="12" fill="{WOOD_D}" opacity="0.7"/>'
    elif kind == "ribbonPink":  # a wooden plank with two brass nails
        s = (f'<rect x="8" y="18" width="336" height="74" rx="8" fill="#140C1C" opacity="0.5"/>'
             f'<rect x="8" y="8" width="336" height="74" rx="8" fill="{BROWN}"/><rect x="14" y="14" width="324" height="62" rx="5" fill="{WOOD_D}" filter="url(#wood)"/>'
             f'<rect x="14" y="14" width="324" height="50" rx="5" fill="url(#gWood)" filter="url(#wood)"/><rect x="20" y="17" width="312" height="4" rx="2" fill="#FFE2B0" opacity="0.5"/>'
             f'<circle cx="32" cy="40" r="7.5" fill="{BROWN}"/><circle cx="32" cy="39" r="5.5" fill="url(#gBrass)"/><circle cx="320" cy="40" r="7.5" fill="{BROWN}"/><circle cx="320" cy="39" r="5.5" fill="url(#gBrass)"/>')
    elif kind == "ribbonLilac":  # the comic header: a marigold slanted bar with a hard ink shadow (menu titles only)
        s = (f'<path d="M34 20 L346 20 L326 96 L14 96 Z" fill="{INK}"/><path d="M26 8 L338 8 L318 84 L6 84 Z" fill="{INK}"/>'
             f'<path d="M36 16 L327 16 L311 76 L20 76 Z" fill="#F0B43A" filter="url(#paper)"/><path d="M40 20 L322 20" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="4"/>'
             f'<path d="M24 66 L314 66 L311 76 L20 76 Z" fill="#B9801F" opacity="0.6"/>')
    elif kind == "close":  # a berry-painted block with a cream cross
        s = wood_block(w, h) + (f'<rect x="18" y="16" width="60" height="52" rx="6" fill="#D8456B" filter="url(#paper)"/>'
                                '<path d="M34 28 L62 56 M62 28 L34 56" stroke="#FFF7E2" stroke-width="10" stroke-linecap="round"/>')
    elif kind == "grid":  # blueprint paper: one bold line and three faint ones each way, tiled in game
        s = '<rect width="128" height="128" fill="#2B63C6"/>' + "".join(f'<path d="M{i * 32} 0 V128 M0 {i * 32} H128" stroke="#FFFFFF" stroke-opacity="{0.3 if i == 0 else 0.12}" stroke-width="2"/>' for i in range(4))
    elif kind == "dial":  # the brass compass body: a bevelled brass case, a leather face, engraved ticks and rivets
        ticks = "".join(f'<path d="M256 62 V{86 if i % 4 else 98}" stroke="#F0CC78" stroke-opacity="{0.5 if i % 4 else 0.85}" stroke-width="{3 if i % 4 else 5}" stroke-linecap="round" transform="rotate({i * 11.25} 256 256)"/>' for i in range(32))
        rivets = "".join(f'<g transform="rotate({45 + i * 90} 256 256)"><circle cx="256" cy="26" r="8" fill="#5A3D10"/><circle cx="255" cy="25" r="5.5" fill="url(#gBrass)"/></g>' for i in range(4))
        s = (f'<circle cx="256" cy="266" r="240" fill="#08040C" opacity="0.45" filter="url(#soft)"/>'
             f'<circle cx="256" cy="256" r="246" fill="#3B2416"/><circle cx="256" cy="256" r="240" fill="url(#gBrass)" filter="url(#metal)"/>'
             f'<circle cx="256" cy="256" r="218" fill="url(#gBrass2)"/><circle cx="256" cy="256" r="206" fill="#2A1810"/>'
             f'<circle cx="256" cy="256" r="200" fill="url(#gFace)" filter="url(#leather)"/>'
             f'<circle cx="256" cy="256" r="186" fill="none" stroke="#E3B455" stroke-opacity="0.45" stroke-width="2.5" stroke-dasharray="10 9"/>'
             f'{ticks}{rivets}<path d="M96 150 Q170 60 290 44" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="7" fill="none" stroke-linecap="round"/>')
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
    page.write_text('<!doctype html><html><body style="margin:0;background:transparent">' + DEFS + "".join(svg(k).format(x=pos[k][0], y=pos[k][1]) for k in kinds) + "</body></html>", encoding="utf-8")
    png = out / "_sheet.png"
    if png.exists(): png.unlink()
    p = subprocess.Popen([EDGE, "--headless=new", "--disable-gpu", "--no-first-run", f"--user-data-dir={out / '_edgeprof'}", "--hide-scrollbars", "--force-device-scale-factor=1",
                          "--default-background-color=00000000", f"--window-size=1400,{H}", f"--screenshot={png}", page.as_uri()], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    t0 = time.time()
    while time.time() - t0 < 40 and p.poll() is None and not png.exists(): time.sleep(0.5)
    time.sleep(2)
    if p.poll() is None: subprocess.run(["taskkill", "/F", "/T", "/PID", str(p.pid)], capture_output=True)  # only the browser started here
    sheet = Image.open(png).convert("RGBA")
    for k in kinds:
        (x, y), (w, h) = pos[k], SIZE[k]
        sheet.crop((x, y, x + w, y + h)).save(out / f"{k}.png")
    bg = Image.new("RGBA", sheet.size, (70, 110, 80, 255)); bg.alpha_composite(sheet); bg.convert("RGB").save(out / "_preview.jpg", quality=92)
    print("sheet", sheet.size, "alpha at 0,0:", sheet.getpixel((0, 0))[3], "kinds", len(kinds))


if __name__ == "__main__":
    main()
