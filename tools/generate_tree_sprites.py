#!/usr/bin/env python3
"""生成 2D 像素风松树精灵表 (tree_sprites.png)。

输出: 4 棵不同样式的松树, 横向排列, 每棵 128x192 (透明背景)。
由 main.gd 在地图上随机放置, 每棵树配 StaticBody2D 碰撞阻挡玩家。
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets" / "tiles" / "tree_sprites.png"
W, H = 128, 192
COUNT = 4
SHEET_W = W * COUNT

TRUNK = (92, 64, 40)
TRUNK_DARK = (60, 40, 26)

TREES = [
    {"needle": (34, 92, 40), "needle_dark": (24, 66, 30), "needle_light": (58, 130, 52), "layers": 4},
    {"needle": (28, 110, 48), "needle_dark": (18, 80, 36), "needle_light": (52, 150, 66), "layers": 5},
    {"needle": (44, 120, 60), "needle_dark": (30, 86, 44), "needle_light": (74, 160, 84), "layers": 4},
    {"needle": (26, 84, 44), "needle_dark": (18, 58, 32), "needle_light": (48, 118, 62), "layers": 5},
]


def draw_tree(draw: ImageDraw.ImageDraw, ox: int, cfg, seed) -> None:
    """绘制一棵松树, 画布原点在 ox, 树根在底部。"""
    import random
    rng = random.Random(seed)
    cx = ox + W // 2
    ground = H - 10
    # 树干
    trunk_h = 46
    trunk_w = 14
    draw.rectangle([cx - trunk_w // 2, ground - trunk_h, cx + trunk_w // 2, ground],
                   fill=TRUNK, outline=TRUNK_DARK, width=2)
    # 树干纹理
    for i in range(3):
        ty = ground - trunk_h + 8 + i * 12
        draw.line([(cx - trunk_w // 2 + 2, ty), (cx + trunk_w // 2 - 2, ty)], fill=TRUNK_DARK, width=1)
    # 树冠: 完整大锥形基底 + 多层三角形, 保证饱满无空洞
    layers = cfg["layers"]
    base_w = 104
    layer_h = 24
    trunk_top = ground - trunk_h
    tip_y = trunk_top - (layers - 1) * (layer_h - 10) - layer_h
    # 整体大锥形 (基底)
    draw.polygon(
        [(cx - base_w // 2, trunk_top), (cx + base_w // 2, trunk_top), (cx, tip_y)],
        fill=cfg["needle_dark"], outline=(12, 40, 20), width=2,
    )
    # 分层三角形
    for i in range(layers):
        y_center = trunk_top + (i * (layer_h - 10) - (layers - 1) * (layer_h - 10) * 0.5) - 10
        w = base_w * (1.0 - 0.22 * i)
        x0 = cx - w / 2
        x1 = cx + w / 2
        y_top = y_center - layer_h
        color = cfg["needle_dark"] if i % 2 == 0 else cfg["needle"]
        draw.polygon([(x0, y_center), (x1, y_center), (cx, y_top)], fill=color, outline=(12, 40, 20), width=2)
        # 每层高光
        draw.line([(cx - w * 0.2, y_center - 2), (cx - w * 0.13, y_top + 3)], fill=cfg["needle_light"], width=3)
    # 树顶尖
    draw.polygon([(cx - 8, tip_y + 10), (cx + 8, tip_y + 10), (cx, tip_y)], fill=cfg["needle_light"], outline=(12, 40, 20), width=1)


def main():
    sheet = Image.new("RGBA", (SHEET_W, H), (0, 0, 0, 0))
    for i, cfg in enumerate(TREES):
        draw_tree(ImageDraw.Draw(sheet), i * W, cfg, i * 97 + 13)
    sheet.save(OUT)
    print("saved:", OUT, sheet.size)


if __name__ == "__main__":
    main()
