#!/usr/bin/env python3
"""程序化生成精英怪（Elite Champion）标准精灵表。

输出符合项目约定: 10 列 × 4 行 PNG, 每格 256×256:
  row 0: idle (6 帧, 列 0-5)
  row 1: walk (10 帧, 列 0-9)
  row 2: hit  (5 帧, 列 0-4)
  row 3: death(10 帧, 列 0-9)
角色面向一个方向, 运行时通过水平翻转实现朝向。

绘制方式: 在 32×32 逻辑网格上以 SUPERSAMPLE 倍数超采样绘制,
再用 LANCZOS 平滑缩放到 256×256, 得到抗锯齿的卡通轮廓。
"""
import math
import os
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

CELL = 256
COLS = 10
ROWS = 4
LOGICAL = 32  # 逻辑网格尺寸（绘制坐标系）
SUPERSAMPLE = 16  # 超采样倍数 -> 画布 = LOGICAL * SUPERSAMPLE = 512
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "assets" / "enemies" / "elite_champion_standard_sheet.png"

# ---- 调色板（黄金 + 猩红 + 暗金属）----
OUTLINE = (24, 16, 18, 255)
GOLD_DARK = (140, 96, 24, 255)
GOLD_MID = (196, 148, 44, 255)
GOLD_LIGHT = (255, 214, 96, 255)
GOLD_HIGHLIGHT = (255, 244, 176, 255)
RED_DARK = (112, 18, 22, 255)
RED_MID = (178, 40, 40, 255)
RED_LIGHT = (224, 74, 52, 255)
SKIN = (126, 58, 44, 255)
SKIN_DARK = (82, 36, 30, 255)
EYE = (255, 240, 120, 255)
WHITE = (255, 255, 255, 255)

S = SUPERSAMPLE  # 坐标/线宽缩放系数


def lerp(a, b, t):
    return int(round(a + (b - a) * t))


def make_cell() -> Image.Image:
    size = LOGICAL * S
    return Image.new("RGBA", (size, size), (0, 0, 0, 0))


def scale_down(img: Image.Image) -> Image.Image:
    return img.resize((CELL, CELL), Image.LANCZOS)


def fit_frame(img: Image.Image) -> Image.Image:
    """裁剪内容、缩放并脚底对齐居中到 256x256, 保证不触边。"""
    alpha = np.array(img.convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > 30)
    if len(xs) == 0:
        return Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    x0, x1 = xs.min(), xs.max()
    y0, y1 = ys.min(), ys.max()
    crop = img.crop((x0, y0, x1 + 1, y1 + 1))
    cw, ch = crop.size
    scale = min(205.0 / ch, (CELL - 14) / cw)
    nw, nh = max(1, int(round(cw * scale))), max(1, int(round(ch * scale)))
    nw, nh = min(nw, CELL - 12), min(nh, CELL - 10)
    crop = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    px = (CELL - nw) // 2
    py = CELL - 6 - nh
    canvas.paste(crop, (px, py), crop)
    return canvas


def ellipse(draw, x0, y0, x1, y1, fill, outline=OUTLINE, width=1):
    draw.ellipse([x0 * S, y0 * S, x1 * S, y1 * S], fill=fill, outline=outline, width=width * S)


def line(draw, pts, fill, width=1):
    draw.line([(x * S, y * S) for x, y in pts], fill=fill, width=width * S)


def polygon(draw, pts, fill, outline=OUTLINE):
    draw.polygon([(x * S, y * S) for x, y in pts], fill=fill, outline=outline)


def draw_body(draw, cx, top, bottom, width, fill, outline=OUTLINE):
    """主体: 略扁的圆角矩形 / 椭圆身体。"""
    half = width / 2.0
    ellipse(draw, cx - half, top, cx + half, bottom, fill, outline, width=2)


def draw_horn(draw, cx, base_y, direction, length):
    """一只弯曲犄角。direction: -1 左, 1 右。"""
    points = [
        (cx + direction * 3, base_y),
        (cx + direction * 8, base_y),
        (cx + direction * 12, base_y - length),
        (cx + direction * 5, base_y - length + 3),
    ]
    polygon(draw, points, fill=RED_DARK, outline=OUTLINE)
    hy = base_y - int(length * 0.55)
    line(draw, [(cx + direction * 6, hy), (cx + direction * 10, hy)], RED_LIGHT, width=1)


def draw_arm(draw, shoulder_x, shoulder_y, swing, length, flip):
    """摆动的手臂, swing 为水平偏移相位。"""
    direction = 1 if flip else -1
    elbow_x = shoulder_x + direction * (swing + 2)
    elbow_y = shoulder_y + 4
    hand_x = elbow_x + direction * 3
    hand_y = elbow_y + length
    line(draw, [(shoulder_x, shoulder_y), (elbow_x, elbow_y)], GOLD_MID, width=3)
    line(draw, [(elbow_x, elbow_y), (hand_x, hand_y)], GOLD_MID, width=2)
    ellipse(draw, hand_x - 1, hand_y - 1, hand_x + 1, hand_y + 1, GOLD_LIGHT, OUTLINE, width=1)


def draw_leg(draw, hip_x, hip_y, swing, flip):
    """摆动的腿, swing 为水平偏移相位。"""
    direction = 1 if flip else -1
    knee_x = hip_x + direction * swing
    knee_y = hip_y + 3
    foot_x = knee_x + direction * (swing + 2)
    foot_y = knee_y + 3
    line(draw, [(hip_x, hip_y), (knee_x, knee_y)], RED_DARK, width=3)
    line(draw, [(knee_x, knee_y), (foot_x, foot_y)], RED_DARK, width=2)
    ellipse(draw, foot_x - 2, foot_y - 1, foot_x + 1, foot_y + 1, RED_LIGHT, OUTLINE, width=1)


def draw_champion(img: Image.Image, *, bob: float, walk_phase: float, hit_flash: float,
                  death_t: float, palette) -> None:
    """在超采样画布上绘制精英冠军怪（坐标为 32 逻辑网格）。

    bob: 呼吸/行走上下位移像素 (-1..1)
    walk_phase: 0..1 步态相位
    hit_flash: 0..1 受击白闪
    death_t: 0..1 死亡进度, >=1 表示完全消失
    """
    if death_t >= 1.0:
        return
    draw = ImageDraw.Draw(img)
    cx = LOGICAL // 2
    shrink = 1.0 - 0.45 * death_t
    sink = 4 * death_t
    top = 7.5 + sink
    bottom = 25.5 - sink
    width = (12.5 * shrink) + 2 * (death_t > 0)
    body_fill = GOLD_MID
    accent = RED_MID
    if hit_flash > 0.0:
        body_fill = lerp_color(GOLD_MID, WHITE, hit_flash * 0.8)
        accent = lerp_color(RED_MID, WHITE, hit_flash * 0.8)

    top_i = top + bob
    bottom_i = bottom + bob

    hip_y = bottom_i - 2
    if death_t > 0:
        draw_leg(draw, cx - 4, hip_y, 1, False)
        draw_leg(draw, cx + 4, hip_y, -1, True)
    else:
        leg_swing = 2.5 * math.sin(walk_phase * math.tau)
        draw_leg(draw, cx - 4, hip_y, leg_swing, False)
        draw_leg(draw, cx + 4, hip_y, -leg_swing, True)

    draw_body(draw, cx, top_i, bottom_i, width, body_fill)

    belt_y = top_i + (bottom_i - top_i) * 0.62
    line(draw, [(cx - width * 0.7, belt_y), (cx + width * 0.7, belt_y)], accent, width=2)

    head_top = top_i - 6 + bob * 0.5
    head_bottom = top_i + 2
    ellipse(draw, cx - 6, head_top, cx + 6, head_bottom, SKIN, OUTLINE, width=1)
    crown_y = head_top - 1
    line(draw, [(cx - 3, crown_y), (cx - 3, crown_y - 3)], GOLD_LIGHT, width=1)
    line(draw, [(cx + 3, crown_y), (cx + 3, crown_y - 3)], GOLD_LIGHT, width=1)
    line(draw, [(cx, crown_y), (cx, crown_y - 4)], GOLD_LIGHT, width=1)

    draw_horn(draw, cx - 3, head_top, -1, 8)
    draw_horn(draw, cx + 3, head_top, 1, 8)

    eye_y = head_top + 2
    glow = EYE if hit_flash <= 0.5 else WHITE
    ellipse(draw, cx - 4, eye_y, cx - 1, eye_y + 2, glow, None, 0)
    ellipse(draw, cx + 1, eye_y, cx + 4, eye_y + 2, glow, None, 0)

    if death_t > 0:
        draw_arm(draw, cx - width * 0.5, top_i + 5, 2, 4, False)
        draw_arm(draw, cx + width * 0.5, top_i + 5, -2, 4, True)
    else:
        arm_swing = 2.5 * math.sin(walk_phase * math.tau + math.pi)
        draw_arm(draw, cx - width * 0.5, top_i + 5, arm_swing, 4, False)
        draw_arm(draw, cx + width * 0.5, top_i + 5, -arm_swing, 4, True)


def lerp_color(a, b, t):
    return (lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t), 255)


def build_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (CELL * COLS, CELL * ROWS), (0, 0, 0, 0))

    def place(col, row, img: Image.Image):
        x = col * CELL
        y = row * CELL
        sheet.alpha_composite(fit_frame(scale_down(img)), (x, y))

    # row 0: idle (6 帧) — 轻微呼吸起伏
    for col in range(6):
        cell = make_cell()
        bob = math.sin(col * 2.0) * 0.6
        draw_champion(cell, bob=bob, walk_phase=0.0, hit_flash=0.0, death_t=0.0, palette=None)
        place(col, 0, cell)

    # row 1: walk (10 帧) — 步态摆动 (每帧不同, 平滑循环)
    for col in range(10):
        cell = make_cell()
        phase = (col + 0.5) / 10.0
        bob = math.sin(phase * math.tau) * 0.8
        draw_champion(cell, bob=bob, walk_phase=phase, hit_flash=0.0, death_t=0.0, palette=None)
        place(col, 1, cell)

    # row 2: hit (5 帧) — 受击白闪, 逐渐恢复
    for col in range(5):
        cell = make_cell()
        flash = max(0.0, 1.0 - col * 0.25)
        draw_champion(cell, bob=0.0, walk_phase=0.0, hit_flash=flash, death_t=0.0, palette=None)
        place(col, 2, cell)

    # row 3: death (10 帧) — 下沉压扁消失
    for col in range(10):
        cell = make_cell()
        draw_champion(cell, bob=0.0, walk_phase=0.0, hit_flash=0.0, death_t=col / 10.0, palette=None)
        place(col, 3, cell)

    return sheet


def main() -> None:
    os.makedirs(OUTPUT_PATH.parent, exist_ok=True)
    sheet = build_sheet()
    sheet.save(OUTPUT_PATH)
    print("saved:", OUTPUT_PATH, sheet.size)


if __name__ == "__main__":
    main()
