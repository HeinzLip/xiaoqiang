#!/usr/bin/env python3
"""生成卡通地形瓦片表 (cartoon_terrain_atlas.png)。

8 列 × 2 行, 每格 64×64:
  行 0 (可通行): 草地 ×4, 浅草/草地变体 ×4
  行 1 (不可通行): 湖泊 ×3, 高山 ×3, 岩石凸起 ×2

由 LevelTileMap 程序化布局, 并配置地形物理层 (不可通行瓦片阻挡玩家)。
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets" / "tiles" / "cartoon_terrain_atlas.png"
TILE = 64
COLS = 8
ROWS = 2


def grass(draw: ImageDraw.ImageDraw, rng, base):
    """草地: 底色 + 随机草叶纹理。"""
    draw.rectangle([0, 0, TILE, TILE], fill=base)
    for _ in range(26):
        x = rng.randint(2, TILE - 3)
        y = rng.randint(2, TILE - 3)
        c = rng.choice([(40, 120, 50), (55, 140, 60), (80, 160, 75)])
        draw.line([(x, y), (x, y - rng.randint(3, 6))], fill=c, width=2)


def light_grass(draw: ImageDraw.ImageDraw, rng, base):
    """浅草: 更亮的草 + 小花点。"""
    draw.rectangle([0, 0, TILE, TILE], fill=base)
    for _ in range(20):
        x = rng.randint(2, TILE - 3)
        y = rng.randint(2, TILE - 3)
        c = rng.choice([(90, 170, 90), (120, 190, 110)])
        draw.line([(x, y), (x, y - rng.randint(3, 5))], fill=c, width=2)
    for _ in range(4):
        x = rng.randint(4, TILE - 5)
        y = rng.randint(4, TILE - 5)
        draw.ellipse([x - 1, y - 1, x + 1, y + 1], fill=(230, 200, 90))


def lake(draw: ImageDraw.ImageDraw, rng, base):
    """湖泊: 蓝色水面 + 波纹。"""
    draw.rectangle([0, 0, TILE, TILE], fill=base)
    for _ in range(3):
        y = rng.randint(8, TILE - 8)
        rngx = rng.randint(6, TILE - 30)
        for i in range(12):
            a = 200 - i * 8
            draw.line([(rngx + i, y), (rngx + i + 14, y)], fill=(200, 230, 255, a), width=2)
    # 岸边深色边缘
    draw.rectangle([0, 0, TILE, TILE], outline=(30, 60, 110), width=2)


def mountain(draw: ImageDraw.ImageDraw, rng, base):
    """高山: 灰褐色山峰 + 白雪顶。"""
    draw.rectangle([0, 0, TILE, TILE], fill=(70, 80, 95))
    # 山峰主体
    peak_x = TILE // 2
    draw.polygon(
        [(4, TILE - 4), (peak_x, 8), (TILE - 4, TILE - 4)],
        fill=base,
        outline=(40, 48, 60),
    )
    # 雪顶
    draw.polygon(
        [(peak_x - 8, 20), (peak_x, 6), (peak_x + 8, 20)],
        fill=(245, 248, 255),
    )
    # 岩石纹理
    for _ in range(3):
        x = rng.randint(10, TILE - 14)
        y = rng.randint(30, TILE - 10)
        draw.ellipse([x, y, x + 8, y + 6], fill=(95, 105, 120))


def rocks(draw: ImageDraw.ImageDraw, rng, base):
    """岩石凸起: 灰色石堆, 不可通行。"""
    draw.rectangle([0, 0, TILE, TILE], fill=(85, 95, 80))
    for _ in range(5):
        r = rng.randint(6, 11)
        x = rng.randint(6, TILE - 6 - r)
        y = rng.randint(8, TILE - 6 - r)
        draw.ellipse([x, y, x + r, y + r], fill=base, outline=(45, 52, 60))
        draw.ellipse([x + r // 4, y + r // 4, x + r // 2, y + r // 2], fill=(160, 170, 180))
    # 顶部高光
    draw.ellipse([TILE // 2 - 3, 2, TILE // 2 + 3, 8], fill=(150, 160, 175))


def main():
    rng = random.Random(12345)
    img = Image.new("RGBA", (TILE * COLS, TILE * ROWS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    def draw_tile(col, row, painter, *args):
        tmp = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
        td = ImageDraw.Draw(tmp)
        painter(td, rng, *args)
        img.paste(tmp, (col * TILE, row * TILE))

    # 行0: 草地/浅草 (可通行)
    grass_colors = [(60, 130, 55), (66, 138, 60), (72, 148, 66), (78, 156, 72)]
    light_colors = [(110, 175, 95), (130, 190, 110)]
    for i, c in enumerate(grass_colors):
        draw_tile(i, 0, grass, c)
    for i, c in enumerate(light_colors):
        draw_tile(4 + i, 0, light_grass, c)
    draw_tile(6, 0, grass, (64, 140, 58))
    draw_tile(7, 0, grass, (70, 148, 62))

    # 行1: 湖泊/高山/岩石 (不可通行)
    lake_colors = [(40, 110, 180), (45, 118, 190), (50, 125, 200)]
    for i, c in enumerate(lake_colors):
        draw_tile(i, 1, lake, c)
    mount_colors = [(105, 85, 70), (115, 95, 75), (120, 100, 80)]
    for i, c in enumerate(mount_colors):
        draw_tile(3 + i, 1, mountain, c)
    rock_colors = [(120, 130, 140), (130, 140, 150)]
    for i, c in enumerate(rock_colors):
        draw_tile(6 + i, 1, rocks, c)

    img.save(OUT)
    print("saved:", OUT, img.size)


if __name__ == "__main__":
    main()
