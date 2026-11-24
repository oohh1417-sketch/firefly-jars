#!/usr/bin/env python3
"""Makes all Firefly Jars audio from code: an original music loop and the sound effects.

Everything here was composed and synthesized for this game, so there is nothing to
license. Run:  python3 tools/make_audio.py   (needs numpy)
Output: audio/music.wav (seamless loop) and audio/sfx_*.wav
"""
import os, wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
os.makedirs(OUT, exist_ok=True)

def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)

def env(n, attack, release):
    e = np.ones(n)
    a = max(1, int(attack * SR)); r = max(1, int(release * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e

def pluck(freq, dur, bright=0.35):
    """Kalimba / music-box like tone."""
    t = np.arange(int(dur * SR)) / SR
    tone = np.sin(2 * np.pi * freq * t) + bright * np.sin(2 * np.pi * freq * 2.0 * t) * np.exp(-t * 9)
    tone += 0.12 * np.sin(2 * np.pi * freq * 4.01 * t) * np.exp(-t * 20)
    return tone * np.exp(-t * 3.2) * env(len(t), 0.004, 0.05)

def pad(freqs, dur):
    t = np.arange(int(dur * SR)) / SR
    s = np.zeros_like(t)
    for f in freqs:
        for det in (-0.6, 0.6):
            s += np.sin(2 * np.pi * (f + det) * t) + 0.18 * np.sin(2 * np.pi * (f + det) * 2 * t)
    s /= len(freqs) * 2
    lfo = 0.85 + 0.15 * np.sin(2 * np.pi * 0.25 * t)
    return s * lfo * env(len(t), dur * 0.35, dur * 0.4)

def add(buf, sig, start_s, gain=1.0, wrap=True):
    i = int(start_s * SR)
    end = i + len(sig)
    if end <= len(buf):
        buf[i:end] += sig * gain
    else:
        cut = len(buf) - i
        buf[i:] += sig[:cut] * gain
        if wrap:
            buf[: len(sig) - cut] += sig[cut:] * gain

def echo(buf, delay_s, fb, mix, wrap=True):
    d = int(delay_s * SR)
    out = buf.copy()
    tap = buf.copy()
    for _ in range(6):
        tap = np.roll(tap, d) * fb if wrap else np.concatenate([np.zeros(d), tap[:-d]]) * fb
        out += tap * mix
    return out

def save(name, sig, peak=0.85):
    sig = sig / (np.max(np.abs(sig)) + 1e-9) * peak
    data = (sig * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wrote", name, f"{len(sig)/SR:.2f}s")

# ---------------- music: "Jar Lights", 72 BPM, 8 bars, loops seamlessly ----------------
BPM = 72
BEAT = 60 / BPM
BARS = 8
music = np.zeros(int(BARS * 4 * BEAT * SR))

# Am9 - Fmaj7 - Cmaj7 - G6sus, two bars each
chords = [[57, 60, 64, 71], [53, 57, 60, 64], [48, 55, 59, 64], [55, 57, 62, 64]]
roots = [45, 41, 48, 43]
for c in range(4):
    start = c * 8 * BEAT
    add(music, pad([hz(m) for m in chords[c]], 8 * BEAT + 1.5), start, 0.32)
    for b in (0, 4):  # soft bass on bars' downbeats
        t = np.arange(int(3.2 * BEAT * SR)) / SR
        bass = np.sin(2 * np.pi * hz(roots[c]) * t) * np.exp(-t * 0.9) * env(len(t), 0.03, 0.4)
        add(music, bass, start + b * BEAT, 0.35)

# melody in A minor pentatonic, (bar, beat-in-eighths, midi, length in eighths)
melody = [
    (0, 0, 76, 3), (0, 3, 74, 1), (0, 4, 72, 2), (0, 6, 69, 2),
    (1, 2, 72, 2), (1, 4, 74, 4),
    (2, 0, 72, 3), (2, 3, 69, 1), (2, 4, 67, 4),
    (3, 4, 69, 2), (3, 6, 72, 2),
    (4, 0, 79, 3), (4, 3, 76, 1), (4, 4, 74, 2), (4, 6, 76, 2),
    (5, 0, 72, 4), (5, 6, 74, 2),
    (6, 0, 76, 2), (6, 2, 74, 2), (6, 4, 72, 2), (6, 6, 69, 2),
    (7, 0, 67, 2), (7, 2, 69, 6),
]
for bar, e8, midi, ln in melody:
    add(music, pluck(hz(midi), max(1.2, ln * BEAT / 2 + 0.8)), bar * 4 * BEAT + e8 * BEAT / 2, 0.42)

# twinkles: high, quiet, deterministic pseudo-random
rng = np.random.default_rng(42)
twinkle_notes = [81, 84, 86, 88, 91, 93]
for k in range(18):
    t0 = rng.uniform(0, BARS * 4 * BEAT)
    add(music, pluck(hz(rng.choice(twinkle_notes)), 1.0, 0.1), t0, 0.12)

music = echo(music, BEAT * 0.75, 0.45, 0.35)
save("music.wav", music, 0.6)

# ---------------- sound effects (not looped) ----------------
def clip(sig, seconds):
    out = np.zeros(int(seconds * SR)); n = min(len(sig), len(out)); out[:n] = sig[:n]; return out

def chirp(f0, f1, dur, vol=1.0):
    t = np.arange(int(dur * SR)) / SR
    f = np.linspace(f0, f1, len(t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return (np.sin(ph) + 0.2 * np.sin(2 * ph)) * env(len(t), 0.005, dur * 0.6) * vol

def seq(notes, step, dur, bright=0.3, total=None):
    total = total or step * len(notes) + dur
    out = np.zeros(int(total * SR))
    for i, m in enumerate(notes):
        add(out, pluck(hz(m), dur, bright), i * step, 1.0, wrap=False)
    return out

save("sfx_select.wav", chirp(700, 1250, 0.12), 0.55)
save("sfx_drop.wav", chirp(1100, 650, 0.1), 0.45)
save("sfx_pour.wav", seq([81, 84, 88], 0.055, 0.35, 0.2), 0.6)
t = np.arange(int(0.18 * SR)) / SR
thud = (np.sin(2 * np.pi * 110 * t) + 0.5 * np.sin(2 * np.pi * 82 * t)) * np.exp(-t * 22)
save("sfx_nope.wav", thud, 0.7)
bell = np.zeros(int(1.4 * SR))
for i, m in enumerate([81, 85, 88, 93]):
    add(bell, pluck(hz(m), 1.2, 0.5), i * 0.04, 1.0, wrap=False)
save("sfx_jar_done.wav", echo(bell, 0.12, 0.35, 0.3, wrap=False), 0.7)
win = seq([69, 72, 74, 76, 79, 81, 84, 88], 0.09, 1.4, 0.4)
save("sfx_win.wav", echo(win, 0.18, 0.4, 0.35, wrap=False), 0.75)
save("sfx_hint.wav", seq([88, 91, 93], 0.08, 0.6, 0.1), 0.5)
save("sfx_whoosh.wav", chirp(400, 900, 0.25, 0.6) * np.linspace(1, 0.3, int(0.25 * SR)), 0.4)
# lid opening: a wooden "pop" followed by a bright rising sparkle
t = np.arange(int(0.06 * SR)) / SR
pop = np.sin(2 * np.pi * 320 * t) * np.exp(-t * 60)
unlock = np.zeros(int(0.9 * SR))
add(unlock, pop, 0.0, 1.0, wrap=False)
add(unlock, seq([84, 88, 91, 96], 0.05, 0.6, 0.3), 0.05, 0.7, wrap=False)
save("sfx_unlock.wav", unlock, 0.65)
# daily puzzle solved: a warmer, longer fanfare than a normal level
daily = seq([69, 73, 76, 81, 85, 88, 93], 0.11, 1.6, 0.45)
save("sfx_daily.wav", echo(daily, 0.2, 0.45, 0.4, wrap=False), 0.75)

# lid screwing on: soft ratchet ticks while it turns, then a firm "click" when it locks
rng = np.random.default_rng(7)
t = np.arange(int(0.035 * SR)) / SR
tick = (np.sin(2 * np.pi * 2400 * t) * 0.6 + rng.uniform(-1, 1, t.size) * 0.4) * np.exp(-t * 160)
save("sfx_tick.wav", tick, 0.35)
t = np.arange(int(0.22 * SR)) / SR
click = (rng.uniform(-1, 1, t.size) * np.exp(-t * 220) * 0.8
         + np.sin(2 * np.pi * 1800 * t) * np.exp(-t * 90) * 0.5
         + np.sin(2 * np.pi * 180 * t) * np.exp(-t * 30) * 0.7)
save("sfx_lock.wav", click, 0.8)

# ---------------- added in v0.14 ----------------
# twinkle: the soft shimmer that follows flying fireflies. Very short, high and quiet;
# the game plays it at a random pitch each time so it never sounds the same twice.
rng = np.random.default_rng(11)
tw = np.zeros(int(0.55 * SR))
for i, m in enumerate([96, 100, 103, 98, 105]):
    add(tw, pluck(hz(m), 0.35, 0.05) * (0.9 - i * 0.12), i * 0.035 + rng.uniform(0, 0.01), 1.0, wrap=False)
t = np.arange(tw.size) / SR
tw += rng.uniform(-1, 1, tw.size) * np.exp(-t * 14) * 0.04   # a breath of air, like wings
save("sfx_twinkle.wav", echo(tw, 0.07, 0.3, 0.25, wrap=False), 0.35)
# coin: two bright metallic clinks
t = np.arange(int(0.35 * SR)) / SR
def ding(f): return (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t) + 0.25 * np.sin(2 * np.pi * f * 5.4 * t)) * np.exp(-t * 11)
coin = np.zeros(int(0.45 * SR)); add(coin, ding(hz(93)), 0.0, 0.7, wrap=False); add(coin, ding(hz(100)), 0.07, 1.0, wrap=False)
save("sfx_coin.wav", coin, 0.5)
# repair: glass mending, a rising shimmer that settles on a warm chord
rep = np.zeros(int(1.6 * SR))
for i, m in enumerate([79, 83, 86, 91, 95, 98, 103]):
    add(rep, pluck(hz(m), 0.8, 0.2), i * 0.07, 0.6, wrap=False)
add(rep, pad([hz(67), hz(71), hz(74)], 1.0), 0.5, 0.5, wrap=False)
save("sfx_repair.wav", echo(rep, 0.12, 0.35, 0.3, wrap=False), 0.6)
