#!/usr/bin/env python3
"""生成可循环的战斗背景音乐（16-bit PCM WAV）。

音乐长度固定为 16 秒，所有节奏和音符都落在循环边界内；运行脚本后会
写入 assets/audio/battle_loop.wav，由 AudioManager 作为正式战斗的 BGM 播放。
"""
import math
import struct
from pathlib import Path

import numpy as np


SAMPLE_RATE = 44100
DURATION = 16.0
OUT_PATH = Path(__file__).resolve().parents[1] / "assets" / "audio" / "battle_loop.wav"


def add_tone(buffer: np.ndarray, start: float, duration: float, frequency: float, volume: float) -> None:
    start_index = int(start * SAMPLE_RATE)
    length = min(int(duration * SAMPLE_RATE), len(buffer) - start_index)
    if length <= 0:
        return
    time = np.arange(length) / SAMPLE_RATE
    attack = np.clip(time / 0.015, 0.0, 1.0)
    release = np.clip((duration - time) / 0.16, 0.0, 1.0)
    envelope = attack * release
    # 轻微泛音让旋律有一点街机合成器的轮廓，但不抢占战斗音效。
    sound = np.sin(math.tau * frequency * time)
    sound += 0.22 * np.sin(math.tau * frequency * 2.0 * time)
    buffer[start_index:start_index + length] += sound * envelope * volume


def add_kick(buffer: np.ndarray, start: float, volume: float) -> None:
    start_index = int(start * SAMPLE_RATE)
    length = min(int(0.18 * SAMPLE_RATE), len(buffer) - start_index)
    if length <= 0:
        return
    time = np.arange(length) / SAMPLE_RATE
    frequency = 118.0 * np.exp(-time * 20.0) + 42.0
    phase = math.tau * np.cumsum(frequency) / SAMPLE_RATE
    envelope = np.exp(-time * 17.0)
    buffer[start_index:start_index + length] += np.sin(phase) * envelope * volume


def add_hat(buffer: np.ndarray, start: float, volume: float, rng: np.random.Generator) -> None:
    start_index = int(start * SAMPLE_RATE)
    length = min(int(0.06 * SAMPLE_RATE), len(buffer) - start_index)
    if length <= 0:
        return
    time = np.arange(length) / SAMPLE_RATE
    noise = rng.uniform(-1.0, 1.0, length)
    # 一阶差分去掉低频，让它像轻量 hi-hat 而非爆炸声。
    high_pass = np.concatenate(([0.0], np.diff(noise)))
    buffer[start_index:start_index + length] += high_pass * np.exp(-time * 42.0) * volume


def write_wav(samples: np.ndarray) -> None:
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(samples, -1.0, 1.0) * 32767).astype(np.int16)
    with OUT_PATH.open("wb") as output:
        output.write(b"RIFF")
        output.write(struct.pack("<I", 36 + len(pcm) * 2))
        output.write(b"WAVEfmt ")
        output.write(struct.pack("<IHHIIHH", 16, 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16))
        output.write(b"data")
        output.write(struct.pack("<I", len(pcm) * 2))
        output.write(pcm.tobytes())
    print(f"saved: {OUT_PATH}")


def main() -> None:
    samples = np.zeros(int(SAMPLE_RATE * DURATION), dtype=np.float64)
    rng = np.random.default_rng(20260910)
    tempo = 128.0
    beat = 60.0 / tempo
    root_notes = [146.83, 164.81, 196.00, 174.61]  # D3, E3, G3, F3
    melody_steps = [0, 2, 4, 2, 5, 4, 2, 0]

    for bar in range(8):
        bar_start = bar * beat * 4.0
        root = root_notes[bar % len(root_notes)]
        for step in range(8):
            note_start = bar_start + step * beat * 0.5
            add_tone(samples, note_start, beat * 0.42, root * (2.0 ** (melody_steps[step] / 12.0)), 0.075)
        for pulse in range(4):
            add_tone(samples, bar_start + pulse * beat, beat * 0.82, root * 0.5, 0.055)
            add_kick(samples, bar_start + pulse * beat, 0.16)
        for eighth in range(8):
            add_hat(samples, bar_start + eighth * beat * 0.5, 0.022, rng)

    # 留出足够余量给武器音效，循环时首尾均为静音，减少边界爆音。
    write_wav(samples * 0.72)


if __name__ == "__main__":
    main()
