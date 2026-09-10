#!/usr/bin/env python3
"""程序化生成武器音效 (WAV, 16-bit PCM)。

输出到 assets/audio/ 目录, 由 Godot 导入后经 AudioManager 播放。
"""
import os
import struct
from pathlib import Path

import numpy as np

OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio"
SAMPLE_RATE = 44100


def write_wav(path: Path, samples: np.ndarray) -> None:
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    with open(path, "wb") as f:
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + len(pcm) * 2))
        f.write(b"WAVE")
        f.write(b"fmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16))
        f.write(b"data")
        f.write(struct.pack("<I", len(pcm) * 2))
        pcm.tofile(f)
    print("saved:", path)


def envelope(n: int, attack: float = 0.01, release: float = 0.3) -> np.ndarray:
    """简单的 ADSR 包络: attack 线性上升, 其余指数衰减。"""
    t = np.arange(n) / SAMPLE_RATE
    total = n / SAMPLE_RATE
    a = np.clip(t / attack, 0.0, 1.0) if attack > 0 else np.ones(n)
    r = np.exp(-t / max(release, 1e-4))
    return a * r


def tone(freq: float, dur: float, attack=0.01, release=0.3,
         harmonics=None, decay_per_harmonic=0.6) -> np.ndarray:
    """基频 + 泛音的合成音。"""
    n = int(SAMPLE_RATE * dur)
    t = np.arange(n) / SAMPLE_RATE
    harmonics = harmonics or [1.0]
    s = np.zeros(n)
    for i, amp in enumerate(harmonics):
        s += amp * np.sin(2 * np.pi * freq * (i + 1) * t) * (decay_per_harmonic ** i)
    s *= envelope(n, attack, release)
    return s / max(np.abs(s).max(), 1e-6)


def noise(dur: float, attack=0.01, release=0.3, lowpass=0.3, rng=None) -> np.ndarray:
    """滤波噪声 (用于射击/爆炸)。"""
    rng = rng or np.random.default_rng(0)
    n = int(SAMPLE_RATE * dur)
    s = rng.uniform(-1.0, 1.0, n)
    # 简单低通 (滑动平均)
    k = max(1, int(lowpass * 32))
    if k > 1:
        kernel = np.ones(k) / k
        s = np.convolve(s, kernel, mode="same")
    s *= envelope(n, attack, release)
    return s / max(np.abs(s).max(), 1e-6)


def sweep(f0: float, f1: float, dur: float, attack=0.01, release=0.2,
          harmonics=None) -> np.ndarray:
    """频率滑动的音 (用于电弧/声波)。"""
    n = int(SAMPLE_RATE * dur)
    t = np.arange(n) / SAMPLE_RATE
    phase = 2 * np.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    harmonics = harmonics or [1.0]
    s = np.zeros(n)
    for i, amp in enumerate(harmonics):
        s += amp * np.sin(phase * (i + 1)) * (0.7 ** i)
    s *= envelope(n, attack, release)
    return s / max(np.abs(s).max(), 1e-6)


def mix(*sounds, rng=None) -> np.ndarray:
    rng = rng or np.random.default_rng(1)
    n = max(len(s) for s in sounds)
    out = np.zeros(n)
    for s in sounds:
        pad = np.zeros(n)
        offset = rng.integers(0, 500)
        seg = s[: max(0, n - offset)]
        pad[offset:offset + len(seg)] = seg
        out += pad
    return out / max(np.abs(out).max(), 1e-6)


def gen_missile_fire() -> np.ndarray:
    """导弹发射: 低音起爆 + 短噪声 + 高频脉冲。"""
    boom = sweep(180, 60, 0.18, attack=0.005, release=0.15)
    nz = noise(0.10, attack=0.005, release=0.06, lowpass=0.5) * 0.6
    return mix(boom, nz) * 0.9


def gen_missile_hit() -> np.ndarray:
    """导弹命中: 中频爆裂噪声。"""
    burst = noise(0.16, attack=0.003, release=0.12, lowpass=0.35)
    thud = tone(110, 0.12, attack=0.002, release=0.1, harmonics=[1.0, 0.5]) * 0.5
    return mix(burst, thud) * 0.9


def gen_dart_fire() -> np.ndarray:
    """飞镖发射: 尖锐的嗖声。"""
    whoosh = sweep(1200, 300, 0.12, attack=0.008, release=0.1)
    tick = tone(1800, 0.05, attack=0.002, release=0.04, harmonics=[1.0, 0.4]) * 0.4
    return mix(whoosh, tick) * 0.8


def gen_dart_hit() -> np.ndarray:
    """飞镖命中: 清脆的金属叮。"""
    ding = tone(950, 0.12, attack=0.002, release=0.1, harmonics=[1.0, 0.6, 0.3, 0.15])
    return ding * 0.7


def gen_arc() -> np.ndarray:
    """电弧: 高频电流吱吱声 + 轻微嗡鸣。"""
    crackle = sweep(2400, 1200, 0.25, attack=0.005, release=0.2,
                    harmonics=[1.0, 0.8, 0.5]) * 0.7
    buzz = tone(160, 0.25, attack=0.01, release=0.2, harmonics=[1.0, 0.3]) * 0.3
    return mix(crackle, buzz) * 0.8


def gen_sound_wave() -> np.ndarray:
    """声波: 低沉脉冲回声。"""
    pulse = sweep(90, 40, 0.5, attack=0.02, release=0.4)
    echo = pulse[: int(SAMPLE_RATE * 0.2)] * 0.5
    return mix(pulse, echo) * 0.8


def gen_lightning() -> np.ndarray:
    """落雷: 从高空劈下的爆裂 + 短促高频裂纹。"""
    crack = noise(0.10, attack=0.002, release=0.05, lowpass=0.6)
    boom = sweep(160, 50, 0.30, attack=0.004, release=0.25)
    sizzle = noise(0.14, attack=0.01, release=0.1, lowpass=0.25, rng=np.random.default_rng(7)) * 0.5
    return mix(crack, boom, sizzle) * 0.9


def gen_ice_spike() -> np.ndarray:
	"""冰刺: 清脆冰晶破土声，带短促的冰霜尾音。"""
	crack = noise(0.16, attack=0.002, release=0.09, lowpass=0.08) * 0.45
	chime = sweep(1180, 2180, 0.32, attack=0.004, release=0.22,
	              harmonics=[1.0, 0.35, 0.16]) * 0.75
	ice_body = tone(530, 0.20, attack=0.002, release=0.13,
	                harmonics=[1.0, 0.25, 0.12]) * 0.25
	return mix(crack, chime, ice_body) * 0.78


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    generators = {
        "missile_fire": gen_missile_fire,
        "missile_hit": gen_missile_hit,
        "dart_fire": gen_dart_fire,
        "dart_hit": gen_dart_hit,
        "arc": gen_arc,
        "sound_wave": gen_sound_wave,
        "lightning": gen_lightning,
    }
    for name, gen in generators.items():
        write_wav(OUT_DIR / f"{name}.wav", gen())


if __name__ == "__main__":
    main()
