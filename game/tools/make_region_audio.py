#!/usr/bin/env python3
"""Makes the music and sound effects of each Jar World region, from code (nothing to license).

  python3 game/tools/make_region_audio.py      (needs numpy; ffmpeg for the web copies)

Writes game/audio/<region>/music.wav (a seamless loop) and sfx_select / sfx_drop / sfx_pour /
sfx_twinkle / sfx_jar_done / sfx_win.wav for reef, sunpetal, grove, candy and space.
Firefly Night keeps the original sounds (tools/make_audio.py). With --web <folder> it also writes
small .mp3 copies there for the web test page.
"""
import os, sys, wave, subprocess
import numpy as np

SR = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = np.random.default_rng(7)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def T(d):
    return np.arange(int(d * SR)) / SR


def env(n, a, r):
    e = np.ones(n)
    a = max(1, min(n, int(a * SR))); r = max(1, min(n, int(r * SR)))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def add(buf, sig, at, gain=1.0):
    """Adds sig at time `at`, wrapping around the end so loops stay seamless."""
    i = int(at * SR) % len(buf)
    n = len(sig)
    end = i + n
    if end <= len(buf):
        buf[i:end] += sig * gain
    else:
        cut = len(buf) - i
        buf[i:] += sig[:cut] * gain
        rest = sig[cut:]
        buf[:len(rest)] += rest[:len(buf)] * gain


def fft_filter(sig, lo=0.0, hi=None):
    """Band filter in the frequency domain (circular, so a loop stays seamless)."""
    F = np.fft.rfft(sig)
    f = np.fft.rfftfreq(len(sig), 1 / SR)
    m = np.ones_like(f)
    if hi:
        m *= 1 / (1 + (f / hi) ** 4)
    if lo:
        m *= 1 / (1 + (lo / np.maximum(f, 1e-3)) ** 4)
    return np.fft.irfft(F * m, len(sig))


def echo(buf, delay, fb, mix, loop=True):
    d = int(delay * SR)
    out = buf.copy(); tap = buf.copy()
    for _ in range(6):
        tap = (np.roll(tap, d) if loop else np.concatenate([np.zeros(d), tap[:-d]])) * fb
        out += tap * mix
    return out


def save(path, sig, peak=0.85):
    sig = sig / (np.max(np.abs(sig)) + 1e-9) * peak
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((sig * 32767).astype(np.int16).tobytes())


# ---------- instruments ----------
def sine(f, d):
    return np.sin(2 * np.pi * f * T(d))


def sweep(f0, f1, d, curve=1.0):
    t = T(d); u = (t / d) ** curve
    f = f0 + (f1 - f0) * u
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def pluck(f, d, bright=0.35, decay=3.2):
    t = T(d)
    s = np.sin(2 * np.pi * f * t) + bright * np.sin(4 * np.pi * f * t) * np.exp(-t * 9) + 0.12 * np.sin(2 * np.pi * f * 4.01 * t) * np.exp(-t * 20)
    return s * np.exp(-t * decay) * env(len(t), 0.004, 0.05)


def marimba(f, d=0.6):
    t = T(d)
    s = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 30)
    return s * np.exp(-t * 6) * env(len(t), 0.002, 0.05)


def bell(f, d=2.0, decay=2.5):
    t = T(d)
    s = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 3) + 0.25 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 6)
    return s * np.exp(-t * decay) * env(len(t), 0.002, 0.1)


def toy(f, d=0.35):
    t = T(d)
    s = np.sin(2 * np.pi * f * t) + 0.6 * np.sin(2 * np.pi * f * 3.0 * t) * np.exp(-t * 18) + 0.3 * np.sin(2 * np.pi * f * 5.1 * t) * np.exp(-t * 30)
    return s * np.exp(-t * 9) * env(len(t), 0.001, 0.03)


def flute(f, d):
    t = T(d)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5 * t) * np.clip(t * 3, 0, 1)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    s = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
    s += 0.04 * fft_filter(rng.standard_normal(len(t)), 800, 3000) * np.exp(-t * 6)
    return s * env(len(t), 0.06, min(0.25, d * 0.4))


def synth(f, d, decay=4.0):
    t = T(d)
    s = sum(np.sin(2 * np.pi * f * k * t) / k for k in (1, 3, 5, 7)) * 0.8
    return s * np.exp(-t * decay) * env(len(t), 0.005, 0.05)


def pad(fs, d, wobble=0.0, bright=0.18):
    t = T(d)
    s = np.zeros_like(t)
    for f in fs:
        for det in (-0.7, 0.7):
            ff = (f + det) * (1 + wobble * np.sin(2 * np.pi * 0.3 * t))
            ph = 2 * np.pi * np.cumsum(ff) / SR
            s += np.sin(ph) + bright * np.sin(2 * ph)
    s /= len(fs) * 2
    return s * env(len(t), d * 0.35, d * 0.4)


def noise(d):
    return rng.standard_normal(int(d * SR))


def bloop(f0, f1, d=0.12):
    return sweep(f0, f1, d, 0.6) * np.exp(-T(d) * (4 / d)) * env(int(d * SR), 0.003, 0.02)


def chirp_bird(base=2800, d=0.18):
    t = T(d)
    f = base + 900 * np.sin(2 * np.pi * 28 * t) * np.exp(-t * 6) + 1200 * t / d
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), 0.005, 0.05) * np.exp(-t * 6)


def music(bpm, bars):
    beat = 60 / bpm
    return np.zeros(int(round(bars * 4 * beat * SR))), beat


# ---------- the five regions ----------
def reef():
    buf, B = music(80, 8)
    chords = [[62, 66, 69, 73, 76], [59, 62, 66, 69, 73], [55, 59, 62, 66, 69], [57, 61, 64, 66, 69]]
    for c, ch in enumerate(chords):
        add(buf, pad([hz(m) for m in ch[:4]], 8 * B + 1.5, wobble=0.004), c * 8 * B, 0.5)
        add(buf, pluck(hz(ch[0] - 24), 2.5, 0.1, 1.5), c * 8 * B, 0.5)
        add(buf, pluck(hz(ch[0] - 24), 2.0, 0.1, 1.5), c * 8 * B + 4 * B, 0.35)
    pent = [62, 64, 66, 69, 71, 74, 76, 78]
    mel = [0, 2, 4, 3, 5, 4, 2, 1, 3, 2, 0, 1, 4, 6, 5, 3]
    for k in range(32):
        n = pent[mel[k % 16]] + (12 if k % 8 == 6 else 0)
        if k % 4 != 3:
            add(buf, marimba(hz(n), 0.9), k * B, 0.32)
    for k in range(40):
        add(buf, bloop(220 + rng.random() * 300, 600 + rng.random() * 900, 0.06 + rng.random() * 0.08), rng.random() * len(buf) / SR, 0.08 + rng.random() * 0.08)
    wav = fft_filter(noise(len(buf) / SR), 60, 500)
    t = np.arange(len(buf)) / SR
    wav *= 0.5 + 0.5 * np.sin(2 * np.pi * t / (len(buf) / SR / 3)) ** 2
    buf += wav * 0.05
    buf = echo(fft_filter(buf, 30, 3500), 3 * B / 4, 0.35, 0.3)
    sfx = {
        "select": bloop(260, 760, 0.13) + np.concatenate([np.zeros(1500), bloop(500, 1100, 0.07)])[:int(0.13 * SR)] * 0.5,
        "drop": np.concatenate([bloop(1000, 230, 0.09) * 0.8, np.zeros(200)]) + np.concatenate([fft_filter(noise(0.05), 300, 2000) * np.exp(-T(0.05) * 60) * 0.25, np.zeros(int(0.09 * SR) + 200 - int(0.05 * SR))]),
        "twinkle": bloop(600, 1500, 0.06),
    }
    pour = np.zeros(int(0.5 * SR))
    for k in range(6):
        add(pour, bloop(300 + 120 * k, 800 + 150 * k, 0.08), k * 0.065, 0.7)
    pour += fft_filter(noise(0.5), 400, 2500) * np.exp(-T(0.5) * 6) * 0.15
    sfx["pour"] = pour
    done = np.zeros(int(1.0 * SR))
    for k, m in enumerate([62, 66, 69, 74, 78]):
        add(done, bloop(hz(m) * 0.5, hz(m), 0.12) * 0.6, k * 0.08)
        add(done, marimba(hz(m), 0.5) * 0.5, k * 0.08)
    sfx["jar_done"] = echo(done, 0.12, 0.3, 0.3, False)
    win = np.zeros(int(2.2 * SR))
    for k, m in enumerate([62, 66, 69, 74, 69, 74, 78, 81]):
        add(win, marimba(hz(m), 0.8), k * 0.12, 0.6)
    for k in range(14):
        add(win, bloop(300 + rng.random() * 400, 900 + rng.random() * 900, 0.08), 0.2 + rng.random() * 1.6, 0.3)
    sfx["win"] = echo(win, 0.18, 0.3, 0.3, False)
    return buf, sfx


def sunpetal():
    buf, B = music(100, 8)
    chords = [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]]
    for c, ch in enumerate(chords):
        for bar in range(2):
            for k, beat in enumerate([0, 1, 1.5, 2, 3, 3.5]):
                at = (c * 8 + bar * 4 + beat) * B
                for j, m in enumerate(ch + [ch[0] + 12]):
                    add(buf, pluck(hz(m), 0.6, 0.5, 5.0), at + j * 0.012, 0.16 if k % 2 == 0 else 0.11)
            add(buf, pluck(hz(ch[0] - 12), 0.9, 0.2, 3), (c * 8 + bar * 4) * B, 0.35)
            add(buf, pluck(hz(ch[0] - 12 + 7), 0.9, 0.2, 3), (c * 8 + bar * 4 + 2) * B, 0.3)
    melody = [(72, 1), (74, .5), (76, .5), (79, 1), (76, 1), (77, 1), (76, .5), (74, .5), (72, 2), (69, 1), (72, 1), (74, 2), (71, 1), (74, 1),
              (72, 1), (74, .5), (76, .5), (79, 1.5), (81, .5), (79, 1), (77, 1), (76, 1), (74, 1), (72, 1), (74, 1), (76, 2), (74, 1), (71, 1), (72, 2)]
    at = 0.0
    for m, d in melody:
        if at >= 32: break
        add(buf, flute(hz(m), d * B * 0.95), at * B, 0.3)
        at += d
    for k in range(64):
        add(buf, fft_filter(noise(0.05), 5000, 9000) * np.exp(-T(0.05) * 70), k * B / 2, 0.06 if k % 2 else 0.1)
    for k in range(5):
        add(buf, chirp_bird(2600 + rng.random() * 800, 0.16), 1.5 + k * 3.7 + rng.random(), 0.05)
    buf = echo(buf, 3 * B / 4, 0.25, 0.2)
    rust = lambda d: fft_filter(noise(d), 2000, 7000) * env(int(d * SR), 0.01, d * 0.7)
    sfx = {
        "select": marimba(hz(84), 0.25) * 0.7 + np.concatenate([rust(0.08) * 0.25, np.zeros(int(0.25 * SR) - int(0.08 * SR))]),
        "drop": pluck(hz(67), 0.22, 0.2, 14) * 0.9,
        "twinkle": chirp_bird(3000, 0.12),
        "pour": fft_filter(noise(0.4), 1500, 6000) * env(int(0.4 * SR), 0.12, 0.25) * 0.3,
    }
    done = np.zeros(int(1.1 * SR))
    for k, m in enumerate([72, 76, 79, 84]):
        add(done, flute(hz(m), 0.35), k * 0.09, 0.5)
    sfx["jar_done"] = done
    win = np.zeros(int(2.4 * SR))
    for k, m in enumerate([60, 64, 67, 72]):
        add(win, pluck(hz(m), 1.2, 0.5, 3), k * 0.02, 0.4)
    for k, (m, d) in enumerate([(72, .15), (76, .15), (79, .15), (84, .6)]):
        add(win, flute(hz(m), d + 0.2), 0.15 + k * 0.17, 0.5)
    add(win, chirp_bird(3000, 0.2), 1.3, 0.2)
    sfx["win"] = win
    return buf, sfx


def grove():
    buf, B = music(66, 8)
    chords = [[52, 55, 59, 66], [48, 52, 55, 59], [45, 48, 52, 55], [47, 52, 54, 57]]
    for c, ch in enumerate(chords):
        add(buf, pad([hz(m) for m in ch], 8 * B + 2.0, bright=0.1), c * 8 * B, 0.55)
        add(buf, sine(hz(ch[0] - 12), 8 * B) * env(int(8 * B * SR), 1.0, 1.5), c * 8 * B, 0.25)
    scale = [64, 67, 71, 74, 76, 79, 83]
    pat = [0, None, 2, 4, None, 3, None, 1, 5, None, 4, 2, None, 6, None, 3]
    for k in range(32):
        p = pat[k % 16]
        if p is not None:
            add(buf, bell(hz(scale[p]), 2.5, 2.0), k * B, 0.22)
    wind = fft_filter(noise(len(buf) / SR), 200, 1200)
    t = np.arange(len(buf)) / SR
    buf += wind * (0.5 + 0.5 * np.sin(2 * np.pi * t / (len(buf) / SR / 2))) * 0.03
    buf = echo(buf, B, 0.45, 0.35)
    sfx = {
        "select": bell(hz(88), 0.5, 9) * 0.8,
        "drop": bell(hz(76), 0.4, 12),
        "twinkle": bell(hz(96), 0.25, 18) * 0.6,
    }
    pour = np.zeros(int(0.7 * SR))
    for k, m in enumerate([91, 88, 84, 81]):
        add(pour, bell(hz(m), 0.4, 10), k * 0.07, 0.5)
    sfx["pour"] = pour
    done = np.zeros(int(1.6 * SR))
    for k, m in enumerate([76, 79, 83, 88, 91]):
        add(done, bell(hz(m), 1.0, 4), k * 0.08, 0.5)
    sfx["jar_done"] = echo(done, 0.15, 0.35, 0.3, False)
    win = np.zeros(int(2.8 * SR))
    for k, m in enumerate([64, 67, 71, 76, 79, 83, 88]):
        add(win, bell(hz(m), 2.0, 2.2), k * 0.11, 0.45)
    sfx["win"] = echo(win, 0.2, 0.35, 0.3, False)
    return buf, sfx


def candy():
    buf, B = music(112, 8)
    chords = [[65, 69, 72], [62, 65, 69], [58, 62, 65], [60, 64, 67]]
    for c, ch in enumerate(chords):
        for bar in range(2):
            b0 = (c * 8 + bar * 4) * B
            add(buf, pluck(hz(ch[0] - 24), 0.3, 0.6, 12), b0, 0.5)
            add(buf, pluck(hz(ch[0] - 17), 0.3, 0.6, 12), b0 + 2 * B, 0.45)
            for k in [1, 3]:
                for m in ch:
                    add(buf, toy(hz(m), 0.2), b0 + k * B, 0.1)
            for k in range(4):
                add(buf, sine(70, 0.12) * np.exp(-T(0.12) * 35) if k % 2 == 0 else fft_filter(noise(0.08), 1500, 6000) * np.exp(-T(0.08) * 40) * 0.6, b0 + k * B, 0.4)
    mel = [77, 81, 84, 81, 79, 77, 74, None, 74, 77, 81, 79, 77, 74, 72, None, 70, 74, 77, 74, 72, 70, 69, None, 72, 76, 79, 76, 77, None, 77, None]
    for k, m in enumerate(mel * 2):
        if m:
            add(buf, toy(hz(m), 0.3), k * B / 2, 0.3)
    sfx = {
        "select": np.concatenate([fft_filter(noise(0.02), 800, 5000) * 0.5, sweep(700, 250, 0.08) * np.exp(-T(0.08) * 30)]),
        "drop": sweep(500, 260, 0.25) * (1 + 0.3 * np.sin(2 * np.pi * 18 * T(0.25))) * np.exp(-T(0.25) * 10),
        "twinkle": sweep(1200, 1900, 0.07) * env(int(0.07 * SR), 0.005, 0.03),
        "pour": sweep(500, 1400, 0.35, 1.5) * env(int(0.35 * SR), 0.02, 0.08) * 0.8,
    }
    done = np.zeros(int(0.9 * SR))
    for k, m in enumerate([77, 81, 84, 89]):
        add(done, toy(hz(m), 0.4), k * 0.07, 0.6)
    sfx["jar_done"] = done
    win = np.zeros(int(2.0 * SR))
    for k, m in enumerate([77, 81, 84, 81, 84, 89, 93]):
        add(win, toy(hz(m), 0.5), k * 0.12, 0.5)
    add(win, sweep(400, 1600, 0.4, 1.5) * env(int(0.4 * SR), 0.02, 0.1), 0.9, 0.3)
    sfx["win"] = win
    return buf, sfx


def space():
    buf, B = music(70, 8)
    chords = [[57, 60, 64, 71], [53, 57, 64, 67], [48, 55, 59, 64], [52, 55, 59, 62]]
    for c, ch in enumerate(chords):
        p = pad([hz(m) for m in ch], 8 * B + 2.0, wobble=0.002, bright=0.35)
        add(buf, fft_filter(p, 40, 1800), c * 8 * B, 0.5)
        add(buf, sine(hz(ch[0] - 24), 8 * B) * env(int(8 * B * SR), 0.5, 1.0), c * 8 * B, 0.35)
        arp = [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[3] + 12, ch[2] + 12, ch[1] + 12]
        for k in range(32):
            add(buf, synth(hz(arp[k % 6]), 0.25, 9), c * 8 * B + k * B / 4, 0.12)
    buf = echo(fft_filter(buf, 30, 4000), 3 * B / 4, 0.45, 0.35)
    sfx = {
        "select": synth(880, 0.06, 20) * 0.6 + np.concatenate([np.zeros(int(0.05 * SR)), synth(1320, 0.08, 25)])[:int(0.06 * SR)] * 0.5,
        "drop": sweep(420, 120, 0.22) * np.exp(-T(0.22) * 12),
        "twinkle": synth(1760, 0.05, 40) * 0.5,
        "pour": echo(np.concatenate([sweep(1500, 300, 0.3) * np.exp(-T(0.3) * 8) * 0.6, np.zeros(int(0.3 * SR))]), 0.09, 0.4, 0.4, False),
    }
    done = np.zeros(int(1.2 * SR))
    for k, m in enumerate([69, 72, 76, 81, 84]):
        add(done, synth(hz(m), 0.4, 7), k * 0.07, 0.5)
    sfx["jar_done"] = echo(done, 0.12, 0.35, 0.3, False)
    win = np.zeros(int(2.6 * SR))
    for k, m in enumerate([57, 64, 69, 72, 76, 81, 84, 88]):
        add(win, synth(hz(m), 0.8, 4), k * 0.1, 0.4)
    add(win, fft_filter(pad([hz(69), hz(76), hz(81)], 1.6, bright=0.3), 40, 2500), 0.6, 0.4)
    sfx["win"] = echo(win, 0.18, 0.35, 0.3, False)
    return buf, sfx


REGIONS = {"reef": reef, "sunpetal": sunpetal, "grove": grove, "candy": candy, "space": space}

if __name__ == "__main__":
    web = sys.argv[sys.argv.index("--web") + 1] if "--web" in sys.argv else None
    for name, fn in REGIONS.items():
        m, sfx = fn()
        save(os.path.join(ROOT, name, "music.wav"), m, 0.8)
        for k, s in sfx.items():
            save(os.path.join(ROOT, name, "sfx_%s.wav" % k), s)
        print(name, "music %.1fs" % (len(m) / SR), ", ".join(sfx))
        if web:
            os.makedirs(web, exist_ok=True)
            for k in ["music"] + ["sfx_" + s for s in sfx]:
                src = os.path.join(ROOT, name, k + ".wav")
                br = "48k" if k == "music" else "64k"
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-ac", "1", "-b:a", br, os.path.join(web, "%s_%s.mp3" % (name, k))], check=True)
