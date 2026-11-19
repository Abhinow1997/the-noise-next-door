"""Makes the chalk scribble heard as a task just done is written out and crossed off.

Asked for on 11 Nov 2026 ("when u complete a task can we have scribe of the task that
was completed and make scribing noise"). There was no such sound in the project, so
Claude Code wrote this to build one from shaped noise, as make_party_beat.py builds the
party's beat. It isn't a generated asset: no model made it.

It's chalk on rough paper, the TO DO list's own look (plan_note.gd): a run of strokes,
each a burst of band-passed noise with the chalk's grit in it, the band sliding up or
down as the stroke turns, with now and then a quick dab, and short lifts between:
  - a stroke is 60 to 170 ms, a dab 18 to 30 ms; the lifts between are 12 to 55 ms;
  - each stroke's noise goes through a band centred somewhere from 2.2 to 4.2 kHz,
    sliding by up to half that again over the stroke, with a fainter, higher band
    (about 6.5 kHz) for the scratch;
  - its loudness rises in 6 ms, swells and falls with the pressure, and lets go in
    15 ms; grit is the loudness jittering every millisecond or so, and sparse clicks;
  - everything under 900 Hz is taken off, so it's dry and light.
The file starts and ends in a lift, so it loops without a seam. plan_note.gd plays it
on a loop while a scrap's words are written or crossed off, from somewhere new in it
each time.

The output is 48 kHz, 16-bit mono, 2.4 s, with a 'smpl' loop marker over the whole
file (the same layout as forest-loop.wav and party-beat.wav), which Godot reads on
import. It's the same every time it's run (the noise comes from a seeded generator).

Run it from the project folder:
    python design/sfx/make_scribble.py
"""

import math
import random
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "audio" / "sfx" / "scribble-loop.wav"
RATE = 48000
LENGTH = 2.4
PEAK = 0.6
# Coefficients are worked out again this often (samples) as a band slides.
BLOCK = 32


def biquad(kind, f, q):
    """RBJ cookbook coefficients (b0, b1, b2, a1, a2), normalised by a0."""
    w = 2.0 * math.pi * f / RATE
    alpha = math.sin(w) / (2.0 * q)
    c = math.cos(w)
    if kind == "band":
        b = (alpha, 0.0, -alpha)
    else:  # high-pass
        b = ((1.0 + c) / 2.0, -(1.0 + c), (1.0 + c) / 2.0)
    a0 = 1.0 + alpha
    return (b[0] / a0, b[1] / a0, b[2] / a0, -2.0 * c / a0, (1.0 - alpha) / a0)


def run(samples, coefs):
    """Filters `samples` with a coefficient set per sample from `coefs(i)`, which is only
    asked for every BLOCK samples."""
    x1 = x2 = y1 = y2 = 0.0
    out = []
    k = None
    for i, x in enumerate(samples):
        if i % BLOCK == 0:
            k = coefs(i)
        b0, b1, b2, a1, a2 = k
        y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x, y1, y
        out.append(y)
    return out


def stroke(rng, n):
    """One stroke (or dab) of `n` samples."""
    # The chalk's grit: loudness jittering about every millisecond, smoothed a little,
    # and sparse clicks where it catches.
    grit = []
    g = 1.0
    target = 1.0
    for i in range(n):
        if i % 48 == 0:
            target = rng.uniform(0.45, 1.0)
        g += (target - g) * 0.08
        grit.append(g)
    noise = [rng.uniform(-1.0, 1.0) * grit[i] for i in range(n)]
    click = 0.0
    for i in range(n):
        if rng.random() < 0.0035:
            click = rng.uniform(0.6, 1.4)
        noise[i] += click * rng.uniform(-1.0, 1.0)
        click *= 0.93
    # The band slides as the stroke turns, up or down.
    f0 = rng.uniform(2200.0, 4200.0)
    f1 = f0 * rng.uniform(0.7, 1.5)
    main = run(noise, lambda i: biquad("band", f0 + (f1 - f0) * i / n, 1.4))
    scratch = run(noise, lambda i: biquad("band", 6500.0, 2.5))
    # Pressure: in quickly, a swell, and lifted off.
    attack, release = int(0.006 * RATE), int(0.015 * RATE)
    swell = rng.uniform(0.0, 0.35)
    out = []
    for i in range(n):
        env = min(1.0, i / attack, (n - i) / release)
        env *= 1.0 - swell + swell * math.sin(math.pi * i / n)
        out.append((main[i] + 0.35 * scratch[i]) * env)
    return out


def main():
    rng = random.Random(11)
    frames = round(LENGTH * RATE)
    mix = [0.0] * frames
    # A lift first and last, so the loop's seam falls in quiet.
    at = int(0.02 * RATE)
    end = frames - int(0.05 * RATE)
    while True:
        dab = rng.random() < 0.15
        n = int(rng.uniform(0.018, 0.030) * RATE) if dab else int(rng.uniform(0.060, 0.170) * RATE)
        if at + n > end:
            break
        level = rng.uniform(0.55, 1.0) * (0.8 if dab else 1.0)
        for i, s in enumerate(stroke(rng, n)):
            mix[at + i] += s * level
        at += n + int(rng.uniform(0.012, 0.055) * RATE)
    mix = run(mix, lambda i: biquad("high", 900.0, 0.707))
    top = max(abs(x) for x in mix)
    write(OUT, [x * PEAK / top for x in mix])
    print("%s: %d frames, %.3f s" % (OUT.relative_to(ROOT), frames, frames / RATE))


def write(path, samples):
    data = bytearray()
    for x in samples:
        data += struct.pack("<h", max(-32768, min(32767, round(x * 32767))))
    fmt = struct.pack("<HHIIHH", 1, 1, RATE, RATE * 2, 2, 16)
    # One forward loop over the whole file, the same layout as forest-loop.wav.
    smpl = struct.pack("<9I", 0, 0, round(1e9 / RATE), 60, 0, 0, 0, 1, 0)
    smpl += struct.pack("<6I", 0, 0, 0, len(samples), 0, 0)
    body = b"WAVE" + b"fmt " + struct.pack("<I", len(fmt)) + fmt
    body += b"data" + struct.pack("<I", len(data)) + bytes(data)
    body += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"RIFF" + struct.pack("<I", len(body)) + body)


if __name__ == "__main__":
    main()
