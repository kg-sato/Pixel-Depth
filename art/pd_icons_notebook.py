"""Field Notebook icon set for Pixel Depth (2026-11-12): flat ink-outlined icons in the kit's materials (brass, wood, leather,
paper, berry, teal), drawn as SVG and rendered by headless Edge, cut into art/icons_notebook/<name>.png (256 px, transparent).
They replace the glossy soft-kit icons (art/icons_soft) that a harsh grader kept naming as the last pastel remnant.
    python art/pd_icons_notebook.py"""
import pathlib, subprocess, time
from PIL import Image

here = pathlib.Path(__file__).resolve().parent
out = here / "icons_notebook"; out.mkdir(exist_ok=True)
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
INK, BRASS, BRASS_D, WOOD, WOOD_D, LEATHER, PAPER, BERRY, BERRY_D, TEAL, STEEL, FLAME, FLAME_D = (
    "#3B2416", "#E9BE62", "#B9862E", "#B27A45", "#7A5030", "#8A5A3A", "#F3E6C4", "#D8456B", "#9C2947", "#2F9E8E", "#B8BCC6", "#FFB52E", "#F0782A")
ST = f'stroke="{INK}" stroke-width="9" stroke-linejoin="round" stroke-linecap="round"'
THIN = f'stroke="{INK}" stroke-width="6" stroke-linejoin="round" stroke-linecap="round" fill="none"'


def lantern(flame):  # the survival dial's centre: a miner's lantern whose flame shrinks with fear
    f = {"calm": (26, 34), "uneasy": (19, 24), "scared": (11, 14)}[flame]
    return (f'<path d="M44 26 Q64 4 84 26" {THIN}/><rect x="36" y="26" width="56" height="14" rx="5" fill="{BRASS}" {ST}/>'
            f'<rect x="32" y="40" width="64" height="56" rx="8" fill="#3A2A33" {ST}/><rect x="28" y="96" width="72" height="16" rx="5" fill="{BRASS}" {ST}/>'
            f'<path d="M64 {88 - f[1]} C{64 + f[0] / 2} {88 - f[1] / 2} {64 + f[0] / 2} 88 64 90 C{64 - f[0] / 2} 88 {64 - f[0] / 2} {88 - f[1] / 2} 64 {88 - f[1]} Z" fill="{FLAME}" stroke="{FLAME_D}" stroke-width="4"/>'
            f'<path d="M48 44 V92 M80 44 V92" stroke="{BRASS_D}" stroke-width="5"/>')


ICONS = {
    "coin": f'<circle cx="64" cy="64" r="46" fill="{BRASS}" {ST}/><circle cx="64" cy="64" r="31" fill="none" stroke="{BRASS_D}" stroke-width="6"/><path d="M50 78 L78 50 M66 44 Q84 46 86 62" stroke="{INK}" stroke-width="7" stroke-linecap="round" fill="none"/>',
    "gem": f'<path d="M34 30 H94 L116 58 L64 112 L12 58 Z" fill="{BERRY}" {ST}/><path d="M12 58 H116 M34 30 L50 58 L64 112 L78 58 L94 30 M64 30 L50 58 M64 30 L78 58" stroke="{BERRY_D}" stroke-width="5" fill="none" stroke-linejoin="round"/><path d="M40 38 H60" stroke="#FFFFFF" stroke-opacity="0.6" stroke-width="6" stroke-linecap="round"/>',
    "bag": f'<path d="M44 34 Q64 6 84 34" {THIN}/><rect x="22" y="34" width="84" height="80" rx="18" fill="{LEATHER}" {ST}/><path d="M22 62 Q64 84 106 62 V52 Q106 34 88 34 H40 Q22 34 22 52 Z" fill="{WOOD}" {ST}/><rect x="54" y="62" width="20" height="24" rx="4" fill="{BRASS}" {ST}/>',
    "pick": f'<path d="M30 104 L80 46" stroke="{INK}" stroke-width="22" stroke-linecap="round"/><path d="M30 104 L80 46" stroke="{WOOD}" stroke-width="10" stroke-linecap="round"/><path d="M36 30 Q78 14 110 54 Q84 38 62 44 Q46 48 36 30 Z" fill="{STEEL}" {ST}/>',
    "crew": f'<path d="M20 84 Q20 36 64 36 Q108 36 108 84 Z" fill="{BRASS}" {ST}/><rect x="10" y="80" width="108" height="18" rx="8" fill="{BRASS_D}" {ST}/><circle cx="64" cy="56" r="15" fill="{PAPER}" {ST}/><path d="M64 22 V36" {THIN}/>',
    "surface": f'<path d="M64 12 L92 44 H76 V66 H52 V44 H36 Z" fill="{TEAL}" {ST}/><path d="M22 74 H106 L98 102 H30 Z" fill="{WOOD}" {ST}/><circle cx="44" cy="108" r="9" fill="{STEEL}" {ST}/><circle cx="84" cy="108" r="9" fill="{STEEL}" {ST}/>',
    "star": f'<path d="M64 10 L79 47 L119 50 L88 76 L98 115 L64 93 L30 115 L40 76 L9 50 L49 47 Z" fill="{BRASS}" {ST}/><path d="M64 30 L72 52 L94 54" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    "map": f'<path d="M14 30 L46 18 L82 30 L114 18 V98 L82 110 L46 98 L14 110 Z" fill="{PAPER}" {ST}/><path d="M46 18 V98 M82 30 V110" stroke="{BRASS_D}" stroke-width="5"/><path d="M26 86 Q40 60 58 70 T92 52" stroke="{BERRY_D}" stroke-width="5" stroke-dasharray="3 10" stroke-linecap="round" fill="none"/><path d="M90 40 L104 54 M104 40 L90 54" stroke="{BERRY}" stroke-width="7" stroke-linecap="round"/>',
    "hammer": f'<path d="M34 110 L74 54" stroke="{INK}" stroke-width="22" stroke-linecap="round"/><path d="M34 110 L74 54" stroke="{WOOD}" stroke-width="10" stroke-linecap="round"/><rect x="42" y="16" width="70" height="40" rx="8" fill="{STEEL}" {ST} transform="rotate(35 77 36)"/>',
    "lock": f'<path d="M40 58 V42 Q40 16 64 16 Q88 16 88 42 V58" {THIN}/><rect x="24" y="56" width="80" height="58" rx="12" fill="{BRASS}" {ST}/><circle cx="64" cy="80" r="8" fill="{INK}"/><path d="M64 84 V98" stroke="{INK}" stroke-width="8" stroke-linecap="round"/>',
    "flare": f'<path d="M30 108 L76 52" stroke="{INK}" stroke-width="30" stroke-linecap="round"/><path d="M30 108 L76 52" stroke="{BERRY}" stroke-width="18" stroke-linecap="round"/><path d="M44 92 L52 82" stroke="{PAPER}" stroke-width="18"/><path d="M84 14 C104 30 110 44 100 56 C94 64 80 62 76 52 C72 42 82 36 84 14 Z" fill="{FLAME}" stroke="{FLAME_D}" stroke-width="6" stroke-linejoin="round"/>',  # a stick flare with a paper band, burning at the tip
    "heart": f'<path d="M64 110 C12 74 10 42 30 28 C46 18 60 28 64 42 C68 28 82 18 98 28 C118 42 116 74 64 110 Z" fill="{BERRY}" {ST}/><path d="M32 44 Q36 34 46 34" stroke="#FFFFFF" stroke-opacity="0.6" stroke-width="7" fill="none" stroke-linecap="round"/>',
    "torch": f'<path d="M64 10 C90 40 100 60 84 82 C76 94 52 94 44 82 C30 62 44 46 52 34 C56 46 62 44 64 10 Z" fill="{FLAME}" stroke="{FLAME_D}" stroke-width="7" stroke-linejoin="round"/><path d="M64 50 C74 62 76 72 68 80 C62 84 56 80 56 72 C56 64 62 60 64 50 Z" fill="#FFE9A8"/><rect x="50" y="88" width="28" height="30" rx="5" fill="{WOOD}" {ST}/>',
    "calm": lantern("calm"), "uneasy": lantern("uneasy"), "scared": lantern("scared"),
}


def main():
    names = sorted(ICONS)
    page = out / "_sheet.html"
    body = "".join(f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 128 128" style="position:absolute;left:{(i % 4) * 256}px;top:{(i // 4) * 256}px">{ICONS[n]}</svg>' for i, n in enumerate(names))
    page.write_text('<!doctype html><html><body style="margin:0;background:transparent">' + body + "</body></html>", encoding="utf-8")
    H = ((len(names) + 3) // 4) * 256
    png = out / "_sheet.png"
    if png.exists(): png.unlink()
    p = subprocess.Popen([EDGE, "--headless=new", "--disable-gpu", "--no-first-run", f"--user-data-dir={out / '_edgeprof'}", "--hide-scrollbars", "--force-device-scale-factor=1",
                          "--default-background-color=00000000", f"--window-size=1024,{H}", f"--screenshot={png}", page.as_uri()], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    t0 = time.time()
    while time.time() - t0 < 40 and p.poll() is None and not png.exists(): time.sleep(0.5)
    time.sleep(1.5)
    if p.poll() is None: subprocess.run(["taskkill", "/F", "/T", "/PID", str(p.pid)], capture_output=True)  # only the browser started here
    sheet = Image.open(png).convert("RGBA")
    for i, n in enumerate(names):
        sheet.crop(((i % 4) * 256, (i // 4) * 256, (i % 4) * 256 + 256, (i // 4) * 256 + 256)).save(out / f"{n}.png")
    bg = Image.new("RGBA", sheet.size, (169, 113, 63, 255)); bg.alpha_composite(sheet); bg.convert("RGB").save(out / "_preview.jpg", quality=90)
    print("icons", len(names), sheet.size)


if __name__ == "__main__":
    main()
