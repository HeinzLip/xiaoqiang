#!/usr/bin/env python3
"""生成感电美术资源: 敌人身上挂小电球 + 电球间闪电连线的动画精灵表。

输出: 4 帧横向精灵表, 每帧 128x128。帧间连线中点抖动产生"电流蠕动"效果。
使用: Enemy 的 AnimatedSprite2D 感电时播放, 结束停止隐藏。
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets" / "effects" / "shock_balls.png"
CELL = 128
FRAMES = 4
SHEET_W = CELL * FRAMES
SHEET_H = CELL

# 电球布局 (固定, 与帧数无关): 5 个电球相对中心的位置与半径
BALLS = [
    (-38, -14, 8),
    (-14, -34, 6),
    (10, -22, 9),
    (36, -8, 6),
    (0, 2, 7),
]
OUTLINE = (40, 100, 200, 255)
GLOW = (120, 190, 255, 255)
CORE = (230, 245, 255, 255)
WIRE = (120, 200, 255, 255)


def make_ball(draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int, phase: float) -> None:
    """画一个电球: 外发光 + 实心核心 + 白亮高光。"""
    pulse = 1.0 + 0.18 * math.sin(phase)
    rr = max(int(r * pulse), 3)
    # 外发光
    for glow_r in (int(rr * 2.2), int(rr * 1.6)):
        alpha = 60 if glow_r == int(rr * 2.2) else 110
        draw.ellipse([cx - glow_r, cy - glow_r, cx + glow_r, cy + glow_r],
                     fill=(GLOW[0], GLOW[1], GLOW[2], alpha))
    # 实心核心
    draw.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=CORE, outline=OUTLINE, width=2)
    # 高光点
    draw.ellipse([cx - rr // 3, cy - rr // 2, cx + rr // 4, cy - rr // 6], fill=(255, 255, 255, 220))


def make_wire(draw: ImageDraw.ImageDraw, p1, p2, jitter: float, bright: bool) -> None:
    """电球间闪电连线: 中点抖动成折线。"""
    mid = ((p1[0] + p2[0]) / 2 + jitter, (p1[1] + p2[1]) / 2 + jitter * 0.6)
    color = (200, 235, 255, 255) if bright else (120, 190, 255, 220)
    width = 2 if bright else 1
    draw.line([p1, mid], fill=color, width=width)
    draw.line([mid, p2], fill=color, width=width)


def build_frame(frame_index: int) -> Image.Image:
    img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(frame_index * 7919)
    cx = cy = CELL // 2
    phase = frame_index / FRAMES * math.tau
    # 连线: 中心 -> 各电球 -> 中心 (串联链)
    chain = [(cx, cy)]
    chain += [(cx + x, cy + y) for (x, y, _) in BALLS]
    chain.append((cx, cy))
    for i in range(len(chain) - 1):
        jitter = rng.uniform(-6, 6)
        make_wire(draw, chain[i], chain[i + 1], jitter, rng.random() > 0.35)
    # 电球
    for (x, y, r) in BALLS:
        make_ball(draw, cx + x, cy + y, r, phase + frame_index)
    # 中心主电球
    make_ball(draw, cx, cy, 10, phase * 1.3)
    return img


def main():
    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (0, 0, 0, 0))
    for i in range(FRAMES):
        sheet.paste(build_frame(i), (i * CELL, 0))
    sheet.save(OUT)
    print("saved:", OUT, sheet.size)


if __name__ == "__main__":
    main()
