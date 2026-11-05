"""Synthesize the game's sound effects as 16-bit mono WAVs (stdlib only).

Run: python3 -I tools/sfx/generate_sfx.py "Prime Collapse/Prime Collapse/Sounds"
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 44_100


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def mix(base, layer, at=0.0):
    start = int(RATE * at)
    out = base + [0.0] * max(0, start + len(layer) - len(base))
    for i, v in enumerate(layer):
        out[start + i] += v
    return out


def envelope(n, attack=0.002, decay=0.1):
    a = int(RATE * attack)
    return [(i / a if i < a else 1.0) * math.exp(-(i / RATE) / decay) for i in range(n)]


def tone(freq, seconds, decay, harmonics=((1, 1.0),)):
    n = int(RATE * seconds)
    env = envelope(n, decay=decay)
    return [env[i] * sum(amp * math.sin(2 * math.pi * freq * h * i / RATE) for h, amp in harmonics) for i in range(n)]


def thud():
    # Cardboard box landing: a falling low sine plus a short filtered noise slap.
    n = int(RATE * 0.14)
    env = envelope(n, attack=0.001, decay=0.035)
    phase, body = 0.0, []
    for i in range(n):
        freq = 70 + 110 * math.exp(-i / (RATE * 0.02))
        phase += 2 * math.pi * freq / RATE
        body.append(env[i] * math.sin(phase))
    rng, last, slap = random.Random(7), 0.0, []
    for i in range(int(RATE * 0.03)):
        last += 0.25 * (rng.uniform(-1, 1) - last)
        slap.append(last * math.exp(-i / (RATE * 0.006)) * 1.6)
    return mix(body, slap)


def ka_ching():
    # Register drawer click, then two bright bell partials.
    rng = random.Random(3)
    click = [rng.uniform(-1, 1) * math.exp(-i / (RATE * 0.003)) * 0.5 for i in range(int(RATE * 0.02))]
    bell = ((1, 1.0), (2.76, 0.35), (5.4, 0.12))
    out = mix(silence(0.45), click)
    out = mix(out, tone(1568, 0.25, 0.07, bell), at=0.02)
    return mix(out, tone(2093, 0.4, 0.14, bell), at=0.09)


def fanfare():
    # Rising C-major arpeggio with a held top note.
    soft = ((1, 1.0), (2, 0.25), (3, 0.08))
    out = silence(0.8)
    for k, freq in enumerate((523.25, 659.25, 783.99)):
        out = mix(out, tone(freq, 0.22, 0.09, soft), at=0.07 * k)
    return mix(out, tone(1046.5, 0.55, 0.22, soft), at=0.21)


def write(path, samples, peak=0.7):
    top = max(abs(s) for s in samples) or 1.0
    frames = b"".join(struct.pack("<h", int(32767 * peak * s / top)) for s in samples)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)


if __name__ == "__main__":
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    write(out / "ship.wav", thud(), peak=0.8)
    write(out / "buy.wav", ka_ching())
    write(out / "milestone.wav", fanfare())
