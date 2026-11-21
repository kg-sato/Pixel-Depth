"""Synthesised cave sounds for Pixel Depth (directive v13 phase 2; our own, made with numpy and scipy; no samples).
    python audio/pd_cave_sfx.py audio/sfx/cave
Beds (seamless loops, played in gestures with rest gaps by Shared.AudioManager): rootholm_wind, clay_kiln_hum, glitter_shimmer,
muspell_rumble, town_hearth.
Strike stems (the two-element rule, vault Research/Audio/Subterranean Soundscapes and Dynamic Audio (2026-11-20)): one low body
thump under a material ring: root_thock, clay_squelch, crystal_chime, basalt_flint.
Threats and events: stalker_skitter, clay_scrape, spore_storm, kiln_surge, golden_vein, crystal_rift, clink, escape_drum.
Every file is measured (audio/pd_audit.py) and the run ends with a table; strike stems peak at -1.5 dBFS, beds sit 20 dB under."""
import os, sys, wave
import numpy as np
from scipy.signal import butter, sosfilt
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pd_audit import report

SR = 44100
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "sfx", "cave")
os.makedirs(out, exist_ok=True)
rng = np.random.default_rng(2026)
rows = []


def sec(s): return int(s * SR)
def tt(n): return np.arange(n) / SR
def noise(n): return rng.standard_normal(n)
def lp(x, hz, order=2): return sosfilt(butter(order, min(hz, SR / 2 - 100) / (SR / 2), "lowpass", output="sos"), x)
def hp(x, hz, order=2): return sosfilt(butter(order, hz / (SR / 2), "highpass", output="sos"), x)
def bp(x, lo, hi, order=2): return sosfilt(butter(order, [lo / (SR / 2), min(hi, SR / 2 - 100) / (SR / 2)], "bandpass", output="sos"), x)
def env(n, attack, decay):
    t = tt(n)
    return np.minimum(t / max(attack, 1e-4), 1) * np.exp(-np.maximum(t - attack, 0) / decay)
def bell(f, n, decay, partials=((1, 1), (2.76, 0.4), (5.4, 0.18), (8.9, 0.08))):
    t = tt(n)
    return sum(a * np.sin(2 * np.pi * f * k * t) * np.exp(-t / (decay / (1 + k * 0.6))) for k, a in partials)
def place(buf, x, at):
    at = int(at) % len(buf)
    m = min(len(x), len(buf) - at)
    buf[at:at + m] += x[:m]
    if m < len(x): buf[:len(x) - m] += x[m:]  # wraps round: a loop stays seamless


def save(name, x, peak_db=-1.5, loop=False, kind="sfx"):
    x = np.asarray(x, dtype=np.float64)
    if loop:  # a seamless loop: the tail crossfades into the head
        n = sec(1.5)
        x[:n] = x[:n] * np.linspace(0, 1, n) ** 0.5 + x[-n:] * np.linspace(1, 0, n) ** 0.5
        x = x[:-n]
    else:
        n = min(len(x) // 4, 1764); x[-n:] *= np.linspace(1, 0, n)
        x[:32] *= np.linspace(0, 1, 32)
    x = x - x.mean()
    x = x * (10 ** (peak_db / 20)) / max(np.abs(x).max(), 1e-9)
    with wave.open(os.path.join(out, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
    r = report(name, x, SR); r["kind"] = kind; rows.append(r)


# ---------------------------------------------------------------- beds (32 s loops + 1.5 s crossfade), peak -21 dBFS
L = sec(33.5)
t = tt(L)
# Rootholm: a soft cold draught through roots, breathing slowly, with a few low root creaks
w = bp(noise(L), 160, 900) * (0.55 + 0.45 * np.sin(2 * np.pi * t / 11.17) ** 2) * (0.8 + 0.2 * np.sin(2 * np.pi * t / 4.19))
w += lp(noise(L), 120) * 0.6
for at in (3.1, 13.7, 24.2):
    n = sec(1.1); tc = tt(n)
    f = 95 + 25 * np.sin(2 * np.pi * 1.7 * tc)
    creak = np.sin(2 * np.pi * np.cumsum(f) / SR) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 23 * tc))) * env(n, 0.3, 0.35)
    place(w, bp(creak, 70, 400) * 0.5, sec(at))
save("rootholm_wind", w, -21, loop=True, kind="bed")
# Clay kiln: a warm low hum from the kiln with soft crackle and a slow breath of heat
hum = sum(a * np.sin(2 * np.pi * f * t + p) for f, a, p in ((55, 1, 0), (110, 0.45, 1.1), (165, 0.18, 2.3), (82.5, 0.25, 0.4)))
hum *= 0.7 + 0.3 * np.sin(2 * np.pi * t / 8.37)
roar = lp(noise(L), 380) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 5.58 + 1))
k = hum * 0.25 + roar * 0.9
for at in rng.uniform(0, 32, 70):
    n = sec(0.02); place(k, hp(noise(n), 1800) * env(n, 0.0005, 0.004) * rng.uniform(0.3, 1.2), sec(at))
save("clay_kiln_hum", k, -21, loop=True, kind="bed")
# Glitterhall: a slow pentatonic pad and far crystal glints in a huge vault
pad = sum(np.sin(2 * np.pi * f * t) * (0.5 + 0.5 * np.sin(2 * np.pi * t / p + i)) for i, (f, p) in enumerate(((220, 16.75), (330, 11.17), (392, 8.37), (494, 6.7))))
g = lp(pad, 1800) * 0.35 + hp(noise(L), 4000) * 0.03
for at in rng.uniform(0, 32, 22):
    n = sec(2.4); f = rng.choice([1568, 1760, 2093, 2349, 2637, 3136])
    place(g, bell(f, n, 1.4) * rng.uniform(0.08, 0.22), sec(at))
save("glitter_shimmer", g, -21, loop=True, kind="bed")
# Muspell: a deep sub rumble, slow magma bubbles and a far roar
r = lp(noise(L), 70, 4) * 3 + lp(noise(L), 260) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 6.7) ** 2) * 0.7
for at in rng.uniform(0, 32, 26):
    n = sec(0.35); tc = tt(n); f0 = rng.uniform(70, 150)
    place(r, np.sin(2 * np.pi * (f0 * tc + 140 * tc * tc)) * env(n, 0.01, 0.07) * rng.uniform(0.3, 0.8), sec(at))
save("muspell_rumble", r, -21, loop=True, kind="bed")
# Town hearth: a gentle fire crackle, a soft night breeze and far crickets
th = lp(noise(L), 600) * 0.25 * (0.7 + 0.3 * np.sin(2 * np.pi * t / 9.57)) + bp(noise(L), 300, 1200) * 0.12
for at in rng.uniform(0, 32, 140):
    n = sec(0.03); place(th, bp(noise(n), 900, 5000) * env(n, 0.0005, 0.006) * rng.uniform(0.2, 1.0), sec(at))
for at in np.arange(0.4, 32, 2.67):
    for j in range(3):
        n = sec(0.045); tc = tt(n)
        place(th, np.sin(2 * np.pi * 4300 * tc) * env(n, 0.004, 0.012) * 0.06, sec(at + j * 0.07))
save("town_hearth", th, -21, loop=True, kind="bed")

# ---------------------------------------------------------------- strike stems: body + material rings
n = sec(0.26); tc = tt(n)
thump = np.sin(2 * np.pi * np.cumsum(150 * np.exp(-tc / 0.05) + 55) / SR) * env(n, 0.002, 0.07) + lp(noise(n), 300) * env(n, 0.001, 0.03) * 1.2
save("thump", thump, -1.5, kind="strike")
n = sec(0.22); tc = tt(n)
save("root_thock", bp(noise(n), 500, 1100) * env(n, 0.001, 0.02) * 1.4 + (np.sin(2 * np.pi * 420 * tc) + 0.6 * np.sin(2 * np.pi * 985 * tc)) * env(n, 0.001, 0.06), -1.5, kind="strike")
n = sec(0.32); tc = tt(n)
sw = np.zeros(n); x = noise(n)
for i, (a, b) in enumerate(((0, 0.08), (0.08, 0.32))):  # a wet slap whose brightness falls, then a little plop
    s0, s1 = sec(a), sec(b); sw[s0:s1] = lp(x[s0:s1], 2200 if i == 0 else 700)
plop = np.sin(2 * np.pi * np.cumsum(300 - 180 * np.minimum(tc / 0.1, 1)) / SR) * env(n, 0.03, 0.06)
save("clay_squelch", sw * env(n, 0.002, 0.06) + plop * 0.8, -1.5, kind="strike")
n = sec(0.9)
save("crystal_chime", bell(2093, n, 0.6) + 0.55 * bell(3136, n, 0.45) + hp(noise(n), 6000) * env(n, 0.0005, 0.008) * 0.5, -1.5, kind="strike")
n = sec(0.28); tc = tt(n)
save("basalt_flint", hp(noise(n), 3200) * env(n, 0.0005, 0.012) * 1.5 + (np.sin(2 * np.pi * 2710 * tc) + 0.7 * np.sin(2 * np.pi * 4130 * tc)) * env(n, 0.001, 0.05) * 0.6, -1.5, kind="strike")

# ---------------------------------------------------------------- threats and events
n = sec(1.5); tc = tt(n)
sk = bp(noise(n), 1000, 3200) * env(n, 0.5, 0.5) * 0.25
for at in np.cumsum(rng.uniform(0.03, 0.09, 16)):
    m = sec(0.012); place(sk, bp(noise(m), 2000, 6000) * env(m, 0.0005, 0.003) * rng.uniform(0.6, 1.2), sec(at + 0.1))
save("stalker_skitter", sk, -4, kind="threat")
n = sec(0.95); tc = tt(n)
grain = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 31 * tc))
f = np.linspace(900, 1400, n)
sc = np.zeros(n); xs = noise(n)
for i in range(0, n, 2048):  # a ceramic scrape: a narrow band sweeping up, chattering
    j = min(n, i + 2048); c = f[i]; sc[i:j] = bp(xs[i:j], c * 0.85, c * 1.15)
save("clay_scrape", sc * grain * env(n, 0.08, 0.5), -4, kind="threat")
n = sec(2.6); tc = tt(n)
wh = np.zeros(n); xs = noise(n)
for i in range(0, n, 2048):
    j = min(n, i + 2048); c = 300 + 1700 * (i / n); wh[i:j] = lp(xs[i:j], c)
pad = sum(np.sin(2 * np.pi * f * tc) for f in (196, 233.1, 293.7)) * np.minimum(tc / 1.2, 1) * np.exp(-np.maximum(tc - 1.6, 0) / 0.5)
save("spore_storm", wh * env(n, 1.0, 1.0) * 0.8 + pad * 0.25, -3, kind="event")
n = sec(2.2); tc = tt(n)
saw = sum(np.sin(2 * np.pi * 98 * k * tc) / k for k in range(1, 12))
save("kiln_surge", lp(saw, 900) * env(n, 0.35, 0.9) + lp(noise(n), 200) * env(n, 0.2, 0.7) * 0.8, -3, kind="event")
n = sec(1.8); gv = np.zeros(n)
for i, f in enumerate((1046.5, 1318.5, 1568, 2093)):
    place(gv, bell(f, sec(1.4), 0.7) * (0.7 + 0.1 * i), sec(i * 0.09))
gv += hp(noise(n), 5000) * env(n, 0.3, 0.5) * 0.06
save("golden_vein", gv, -2, kind="event")
n = sec(2.4); cr = np.zeros(n)
for i, f in enumerate((3136, 2637, 2349, 2093, 1760, 1568)):
    place(cr, bell(f, sec(1.6), 0.9) * 0.6, sec(0.35 + i * 0.12))
cr += lp(noise(n), 3000) * np.minimum(tt(n) / 0.35, 1) * np.exp(-np.maximum(tt(n) - 0.35, 0) / 0.08) * 0.4  # a reversed swell into the cascade
save("crystal_rift", cr, -2, kind="event")
n = sec(1.1); cl = bell(1760, n, 0.9, ((1, 1), (2.41, 0.5), (3.87, 0.3), (5.92, 0.15))) + hp(noise(n), 4000) * env(n, 0.0005, 0.01) * 0.5
for at in rng.uniform(0.02, 0.25, 6):
    m = sec(0.01); place(cl, hp(noise(m), 5000) * env(m, 0.0005, 0.002) * 0.4, sec(at))
save("clink", cl, -2, kind="event")
beat = SR * 60 / 132 / 2  # eighth notes at 132 bpm; 16 of them = two bars, then the loop
n = int(beat * 16) + sec(1.5); dr = np.zeros(n)
for i in range(16):
    at = int(i * beat)
    if i % 4 == 0:
        m = sec(0.3); tc = tt(m); place(dr, np.sin(2 * np.pi * np.cumsum(120 * np.exp(-tc / 0.04) + 45) / SR) * env(m, 0.001, 0.12), at)
    if i % 4 == 2 or i in (13, 15):
        m = sec(0.25); tc = tt(m); place(dr, (np.sin(2 * np.pi * 180 * tc) * env(m, 0.001, 0.08) + bp(noise(m), 200, 900) * env(m, 0.001, 0.04)) * 0.7, at)
    m = sec(0.05); place(dr, hp(noise(m), 6000) * env(m, 0.001, 0.015) * (0.25 if i % 2 else 0.4), at)
save("escape_drum", dr, -3, loop=True, kind="loop")

# ---------------------------------------------------------------- the table and the checks
print("\n| sound | kind | sec | peak dBFS | ~LUFS | crest dB | sub/body/crisp % |")
print("|---|---|---|---|---|---|---|")
for r in rows:
    print(f"| {r['name']} | {r['kind']} | {r['sec']} | {r['peak']} | {r['lufs']} | {r['crest']} | {r['sub']}/{r['body']}/{r['crisp']} |")
strike = max(r["peak"] for r in rows if r["kind"] == "strike")
bad = [r["name"] for r in rows if r["peak"] > -1.4]
quiet = [r["name"] for r in rows if r["kind"] == "bed" and not (-24.5 <= r["peak"] - strike <= -17.5)]
print("\nclipping or over -1.5 dBFS:", bad or "none", "| beds 18-24 dB under the strike peak:", "all" if not quiet else quiet)
