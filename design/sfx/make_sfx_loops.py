"""Cuts the game's sound-effect loops from the generated originals in design/sfx/.

Each loop is cut between two quiet points in the steadiest stretch of its sound.
Its first few milliseconds are an equal-power blend with the audio that follows
the cut, so the wrap from the end back to the start is seamless. The output is a
16-bit WAV with a 'smpl' loop marker over the whole file, which Godot reads on
import. There's no EQ, compression or level change.

Run it from the project folder:
    python design/sfx/make_sfx_loops.py
"""
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Source, output, rough start and end of the loop (seconds), blend length (seconds).
LOOPS = [
    # Paw patter: steady from about 2 s, a step about every 0.21 s. The cuts sit
    # just before the steps at 2.05 s and 6.13 s, so the wrap leaves the usual
    # gap between steps.
    ("design/sfx/raccon-running.wav", "assets/audio/sfx/run-loop.wav", 2.03, 6.11, 0.02),
    # Scrabbling: the cuts sit in the two quiet dips around 1.25 s and 6.15 s,
    # which keeps the busiest stretch of climbing between them.
    ("design/sfx/raccoon-climbingtree.wav", "assets/audio/sfx/climb-loop.wav", 1.25, 6.15, 0.03),
]
# Each cut moves to the quietest 5 ms within this many seconds of its rough time.
SEARCH = 0.04


def read(path):
    with wave.open(str(path), "rb") as w:
        channels, width, rate, count = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(count)
    if width == 2:
        ints = struct.unpack("<%dh" % (count * channels), raw)
        scale = 32768.0
    elif width == 3:
        ints = [int.from_bytes(raw[i:i + 3], "little", signed=True) for i in range(0, len(raw), 3)]
        scale = 8388608.0
    else:
        raise ValueError("%s: %d-bit audio isn't handled" % (path, width * 8))
    samples = [v / scale for v in ints]
    return rate, channels, [samples[c::channels] for c in range(channels)]


def quietest(chans, rate, around):
    """The middle of the quietest 5 ms window within SEARCH seconds of a time."""
    win = int(rate * 0.005)
    best, best_energy = None, None
    for start in range(int((around - SEARCH) * rate), int((around + SEARCH) * rate) - win, int(rate * 0.001)):
        energy = sum(ch[i] * ch[i] for ch in chans for i in range(start, start + win))
        if best_energy is None or energy < best_energy:
            best, best_energy = start + win // 2, energy
    return best


def write(path, rate, chans, loop_end):
    frames = len(chans[0])
    data = bytearray()
    for i in range(frames):
        for ch in chans:
            data += struct.pack("<h", max(-32768, min(32767, round(ch[i] * 32767))))
    channels = len(chans)
    fmt = struct.pack("<HHIIHH", 1, channels, rate, rate * channels * 2, channels * 2, 16)
    # One forward loop over the whole file, the same layout as forest-loop.wav.
    smpl = struct.pack("<9I", 0, 0, round(1e9 / rate), 60, 0, 0, 0, 1, 0)
    smpl += struct.pack("<6I", 0, 0, 0, loop_end, 0, 0)
    body = b"WAVE" + b"fmt " + struct.pack("<I", len(fmt)) + fmt
    body += b"data" + struct.pack("<I", len(data)) + bytes(data)
    body += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"RIFF" + struct.pack("<I", len(body)) + body)


def main():
    for source, output, rough_start, rough_end, blend in LOOPS:
        rate, channels, chans = read(ROOT / source)
        start = quietest(chans, rate, rough_start)
        end = quietest(chans, rate, rough_end)
        fade = int(rate * blend)
        loop = []
        for ch in chans:
            part = ch[start:end]
            for i in range(fade):
                t = i / fade
                part[i] = ch[start + i] * math.sin(t * math.pi / 2) + ch[end + i] * math.cos(t * math.pi / 2)
            loop.append(part)
        write(ROOT / output, rate, loop, len(loop[0]) - 1)
        peak = max(abs(v) for ch in loop for v in ch)
        print("%s -> %s: %.3f s to %.3f s (%.3f s, %d Hz, %d ch), %d ms blend, peak %.1f dBFS" % (
            source, output, start / rate, end / rate, (end - start) / rate, rate, channels,
            round(blend * 1000), 20 * math.log10(peak)))


if __name__ == "__main__":
    main()
