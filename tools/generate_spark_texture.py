#!/usr/bin/env python3
"""程序化生成柔和圆点粒子贴图 (CPUParticles2D 用)。

- 16x16 白色柔边圆点: 中心不透明, 径向 (1-dist)^1.5 渐变到透明
- 8x 超采样 + LANCZOS, 边缘平滑无锯齿
- 运行时由 color_ramp 染色 (蓝/金火花)

用法: python3 tools/generate_spark_texture.py
输出: assets/effects/spark.png (需 Godot 重新导入)
"""
from PIL import Image
import math
import os

SIZE = 16
SS = 8
W = SIZE * SS
C = W // 2

OUT_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "effects", "spark.png")


def main() -> None:
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    px = img.load()
    half = float(W) / 2.0
    for y in range(W):
        for x in range(W):
            dx = (x - C) / half
            dy = (y - C) / half
            dist = math.sqrt(dx * dx + dy * dy)
            if dist <= 1.0:
                alpha = int(255 * ((1.0 - dist) ** 1.5))
                px[x, y] = (255, 255, 255, alpha)
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    out = os.path.normpath(OUT_PATH)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print("saved:", out)


if __name__ == "__main__":
    main()
