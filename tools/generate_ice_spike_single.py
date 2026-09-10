#!/usr/bin/env python3
"""生成独立冰刺贴图。

用户要求每根冰刺是单独的, 动画时每根单独弹出。
生成单根冰刺贴图, **根部在画布垂直中心** (这样 centered=true 时
锚点即根部), 运行时 scale.y 从 0 向上生长, 实现从地面破土刺出的效果。
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets" / "effects" / "ice_spike_single.png"

W, H = 160, 320
CENTER_Y = H // 2  # 根部锚点位置
ICE_LIGHT = (210, 235, 255, 255)
ICE_MID = (150, 200, 245, 255)
ICE_DARK = (95, 150, 220, 255)
OUTLINE = (70, 110, 190, 255)


def draw_spike(draw: ImageDraw.ImageDraw, cx: int, root_y: int, h: int, half_w: int):
    """绘制一根朝上的冰刺: 根部在 root_y, 尖刺向上。"""
    tip_y = root_y - h
    draw.polygon(
        [
            (cx - half_w, root_y),
            (cx - half_w + half_w * 0.4, tip_y + h * 0.35),
            (cx, tip_y),
            (cx + half_w * 0.4, tip_y + h * 0.35),
            (cx + half_w, root_y),
        ],
        fill=ICE_MID,
        outline=OUTLINE,
    )
    draw.line(
        [(cx - half_w * 0.55, root_y - 4), (cx - half_w * 0.2, tip_y + h * 0.2)],
        fill=ICE_LIGHT,
        width=5,
    )
    draw.line(
        [(cx + half_w * 0.45, root_y - 4), (cx + half_w * 0.15, tip_y + h * 0.25)],
        fill=ICE_DARK,
        width=4,
    )


def main():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_spike(draw, W // 2, CENTER_Y, 270, 42)
    img.save(OUT)
    print("saved:", OUT, img.size, "root_y:", CENTER_Y)


if __name__ == "__main__":
    main()
