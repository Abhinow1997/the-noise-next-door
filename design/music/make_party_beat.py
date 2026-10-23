"""Makes the party's music: the stand-in beat the campsite's speaker plays.

Asked for on 23 Oct 2026 ("make the speaker play the party's music as a sound in
the world, loud near the camp and faint at his tree"). There was no party track
(the storyboard's MUS-PARTY hasn't been made), so Claude Code wrote this to build
one from plain synthesised sounds until the author's own replaces it. It isn't a
generated asset: no model made it.

It's a light dance groove in F, 8 bars long, on the level music's beat grid, so the
two always fit together:
  - the loop is exactly half as long as forest-loop.wav (16 bars in 41.768 s, so
    91.94 beats a minute), and like that loop it starts 50 ms before its first
    downbeat, so wherever the level music is, the party is at the same point in
    its bar;
  - a kick on every beat (the dancers' knees give on every beat), claps on 2 and
    4, open hats on the off-beats and quiet sixteenth hats;
  - a bass pumping on the off-beats, held on F (the level music is in F major, so
    a held F fits whatever its piano plays), with a C leading back in bars 4 and 8;
  - a soft plucked tune from the F major pentatonic (F G A C D), which has none of
    the notes that would rub against the piano's chords;
  - the bass and the tune duck after each kick, as dance music does;
  - bar 8 drops its last kick for a clap roll back into bar 1.
Far away, the game's 3D sound filters off the top, so at his tree it's mostly the
kick and the bass: the thump of a party next door.

The output is 48 kHz, 16-bit mono, with a 'smpl' loop marker over the whole file
(the same layout as forest-loop.wav), which Godot reads on import. It's the same
every time it's run (the noise comes from a seeded generator).

Run it from the project folder:
    python design/music/make_party_beat.py
"""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEVEL_LOOP = ROOT / "assets/audio/music/forest-loop.wav"
OUT = ROOT / "assets/audio/music/party-beat.wav"

RATE = 48000
BARS = 8
# The level loop starts this far before its first downbeat.
DOWNBEAT = 0.05
PEAK = 0.89     # -1 dBFS

F2, C3, F3 = 87.307, 130.813, 174.614
F4, G4, A4, C5, D5, F5 = 349.228, 391.995, 440.0, 523.251, 587.330, 698.456
# The tune: eight eighth notes a bar, a two-bar phrase, with its own last bar.
TUNE = [[A4, C5, D5, C5, A4, C5, F5, C5], [D5, C5, A4, G4, A4, C5, A4, G4]]
TUNE_END = [F5, D5, C5, A4, G4, F4, G4, A4]
GAIN = {"kick": 1.0, "clap": 0.42, "open_hat": 0.16, "hat": 0.07, "bass": 0.5, "pluck": 0.16}


def main():
    with wave.open(str(LEVEL_LOOP)) as w:
        level_frames, level_rate = w.getnframes(), w.getframerate()
    length = level_frames / level_rate / 2          # 8 of its 16 bars
    frames = round(length * RATE)
    bar = length / BARS
    beat = bar / 4
    step = beat / 4
    mix = [0.0] * frames
    rng = random.Random(7)

    def add(at, samples, gain):
        """Adds `samples` from time `at` (seconds from the first downbeat), wrapping
        round the end of the loop so its tail carries on at the start."""
        start = round((DOWNBEAT + at) * RATE)
        for i, s in enumerate(samples):
            mix[(start + i) % frames] += s * gain

    def duck(at, n):
        """The pump after each kick: how much is left of a sound at each of its n
        samples, starting `at` seconds from the first downbeat."""
        return [1.0 - 0.5 * math.exp(-((at + i / RATE) % beat) / 0.09) for i in range(n)]

    for b in range(BARS):
        last = b == BARS - 1
        for s in range(16):
            at = b * bar + s * step
            if s % 4 == 0 and not (last and s == 12):
                add(at, kick(), GAIN["kick"])
            if s in (4, 12) or (last and s >= 12):
                add(at, clap(rng, 0.6 if last and s in (13, 15) else 1.0), GAIN["clap"])
            if s % 4 == 2:
                add(at, hat(rng, 0.12), GAIN["open_hat"])
            else:
                add(at, hat(rng, 0.03), GAIN["hat"] * (1.0 if s % 2 == 0 else 0.6))
            if s % 4 == 2:
                note = F3 if s in (6, 14) else F2
                if b % 4 == 3 and s == 14:
                    note = C3
                n = bass(note, step * 1.7)
                add(at, [x * d for x, d in zip(n, duck(at, len(n)))], GAIN["bass"])
            if s % 2 == 0:
                tune = TUNE_END if last else TUNE[b % 2]
                n = pluck(tune[s // 2])
                add(at, [x * d for x, d in zip(n, duck(at, len(n)))], GAIN["pluck"])

    top = max(abs(x) for x in mix)
    write(OUT, [x * PEAK / top for x in mix])
    print("%s: %d frames, %.3f s, %d bars at %.2f beats a minute" % (
        OUT.relative_to(ROOT), frames, length, BARS, 60.0 / beat))


def kick():
    """A thump: a sine falling from about 120 Hz to 45 Hz, with a click at the front."""
    out, phase = [], 0.0
    for i in range(round(0.42 * RATE)):
        t = i / RATE
        phase += 2 * math.pi * (45.0 + 75.0 * math.exp(-t / 0.03)) / RATE
        click = math.exp(-t / 0.002) * 0.3
        out.append((math.sin(phase) + click) * math.exp(-t / 0.16))
    return out


def clap(rng, level):
    """Three quick bursts of noise, bright but not hissy, then a short tail."""
    out, low, prev = [], 0.0, 0.0
    for i in range(round(0.2 * RATE)):
        t = i / RATE
        env = sum(math.exp(-(t - d) / 0.008) for d in (0.0, 0.011, 0.022) if t >= d) * 0.5
        env += 0.4 * math.exp(-t / 0.07)
        x = rng.uniform(-1, 1)
        high, prev = x - prev, x                  # take off the lows
        low += (high - low) * 0.35                # and the very top
        out.append(low * env * level)
    return out


def hat(rng, decay):
    """Hiss with the lows taken off: short for a closed hat, longer for an open one."""
    out, prev, prev2 = [], 0.0, 0.0
    for i in range(round(decay * 5 * RATE)):
        x = rng.uniform(-1, 1)
        out.append((x - 2 * prev + prev2) * 0.5 * math.exp(-i / RATE / decay))
        prev2, prev = prev, x
    return out


def bass(f, length):
    """A round synth bass: a few harmonics of a saw over a sine an octave down."""
    out = []
    for i in range(round((length + 0.05) * RATE)):
        t = i / RATE
        env = min(1.0, t / 0.005) * (math.exp(-t / 0.25) if t < length else math.exp(-length / 0.25) * math.exp(-(t - length) / 0.012))
        saw = sum(math.sin(2 * math.pi * f * k * t) / k for k in range(1, 5))
        out.append((0.6 * saw + 0.5 * math.sin(math.pi * f * t)) * env)
    return out


def pluck(f):
    """A soft pluck: a sine with a little of its octave, dying away."""
    out = []
    for i in range(round(0.45 * RATE)):
        t = i / RATE
        out.append((math.sin(2 * math.pi * f * t) + 0.3 * math.sin(4 * math.pi * f * t)) * min(1.0, t / 0.003) * math.exp(-t / 0.12))
    return out


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
