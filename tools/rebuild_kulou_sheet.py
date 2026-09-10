#!/usr/bin/env python3
"""从 kulou_sprite.png 生成骷髅标准精灵表 (5 行动画)。

源素材 kulou_sprite.png 行布局 (用户确认):
  行1 (94-252)    = 行走 walk (7帧)
  行2 (394-552)   = 近战攻击 attack (6帧, 其中1帧粘连需拆分)
  行3 (689-843)   = 受击 hit (7帧)
  行4 (992-1139)  = 死亡 death (完整骷髅 + 碎片)

生成 5 行标准表 (2560x1280, 10列x5行):
  行0 idle / 行1 walk / 行2 attack / 行3 hit / 行4 death
"""
import math
from pathlib import Path
from collections import deque

import numpy as np
from PIL import Image

ENEMIES = Path(__file__).resolve().parents[1] / "assets" / "enemies"
SRC = ENEMIES / "kulou_sprite.png"
OUT = ENEMIES / "kulou_standard_sheet.png"
CELL = 256
COLS = 10
BG = (18, 22, 32)

# 各行动画帧坐标 (x0,x1,y0,y1)
WALK_FRAMES = [
    (57, 189, 94, 252), (231, 363, 94, 252), (391, 522, 94, 252),
    (556, 692, 94, 252), (727, 862, 94, 252), (892, 1021, 94, 252),
    (1049, 1178, 94, 252),
]
ATTACK_FRAMES = [
    (50, 187, 394, 552), (229, 381, 394, 552), (397, 575, 394, 552),
    (578, 733, 394, 552), (734, 889, 394, 552),
    (917, 1060, 394, 552), (1088, 1221, 394, 552),
]
HIT_FRAMES = [
    (74, 194, 689, 843), (239, 370, 689, 843), (414, 543, 689, 843),
    (596, 725, 689, 843), (774, 885, 689, 843), (921, 1056, 689, 843),
    (1087, 1219, 689, 843),
]
# death: 完整骷髅帧(前) + 碎片(后)
DEATH_BODY_FRAMES = [
    (41, 184, 992, 1139), (224, 355, 992, 1139), (396, 494, 992, 1139),
    (570, 707, 992, 1139), (739, 871, 992, 1139), (955, 1060, 992, 1139),
    (1129, 1227, 992, 1139),
]
DEATH_SHARD_FRAMES = [
    (496, 531, 992, 1139), (917, 950, 992, 1139),
]


def extract_clean() -> np.ndarray:
    im = Image.open(SRC).convert("RGBA")
    a = np.array(im).astype(int)
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    dist = np.sqrt((r - BG[0]) ** 2 + (g - BG[1]) ** 2 + (b - BG[2]) ** 2)
    mask = (dist > 40) & (a[:, :, 3] > 250)
    alpha = mask
    h, w = alpha.shape
    visited = np.zeros_like(alpha, dtype=bool)
    labels = np.zeros_like(alpha, dtype=int)
    sizes = {}
    label = 0
    for y in range(h):
        for x in range(w):
            if alpha[y, x] and not visited[y, x]:
                label += 1
                q = deque([(y, x)])
                visited[y, x] = True
                cnt = 0
                while q:
                    cy, cx = q.popleft()
                    cnt += 1
                    labels[cy, cx] = label
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] and not visited[ny, nx]:
                                visited[ny, nx] = True
                                q.append((ny, nx))
                sizes[label] = cnt
    keep = set(l for l, s in sizes.items() if s > 150)
    out = a.copy()
    out[~np.isin(labels, list(keep)), 3] = 0
    return out.astype(np.uint8)


def extract_frame(clean: np.ndarray, bbox, flip: bool = True) -> Image.Image:
    x0, x1, y0, y1 = bbox
    crop = clean[y0:y1 + 1, x0:x1 + 1]
    img = Image.fromarray(crop, "RGBA")
    if flip:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img


def normalize(img: Image.Image) -> Image.Image:
    alpha = np.array(img.convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > 40)
    if len(xs) == 0:
        return Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    crop = img.crop((x0, y0, x1 + 1, y1 + 1))
    cw, ch = crop.size
    scale = min(205.0 / ch, (CELL - 14) / cw)
    nw, nh = max(1, int(round(cw * scale))), max(1, int(round(ch * scale)))
    nw, nh = min(nw, CELL - 12), min(nh, CELL - 8)
    crop = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    canvas.paste(crop, ((CELL - nw) // 2, CELL - 6 - nh), crop)
    return canvas


def tint_color(img: Image.Image, color: tuple, amount: float) -> Image.Image:
    arr = np.array(img).astype(np.float32)
    arr[:, :, 0] = arr[:, :, 0] * (1 - amount) + color[0] * amount
    arr[:, :, 1] = arr[:, :, 1] * (1 - amount) + color[1] * amount
    arr[:, :, 2] = arr[:, :, 2] * (1 - amount) + color[2] * amount
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def cycle(frames: list, count: int) -> list:
    n = len(frames)
    period = n * 2 - 2 if n > 1 else 1
    out = []
    for i in range(count):
        t = i % period
        idx = t if t < n else period - t
        out.append(frames[idx])
    return out


def make_idle(base: Image.Image, count=6) -> list:
    frames = []
    base_arr = np.array(base)
    for i in range(count):
        t = (i + 0.5) / count
        bob = 3 * math.sin(t * math.tau)
        scale = 1.0 + 0.015 * math.sin(t * math.tau + math.pi)
        nw = max(1, int(CELL * scale))
        content = Image.fromarray(base_arr).resize((nw, nw), Image.LANCZOS)
        canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        py = CELL - 6 - nw + int(round(bob))
        canvas.paste(content, ((CELL - nw) // 2, py), content)
        frames.append(canvas)
    return frames


def build_sheet() -> Image.Image:
    clean = extract_clean()
    walk = [normalize(extract_frame(clean, b)) for b in WALK_FRAMES]
    hit = [normalize(extract_frame(clean, b)) for b in HIT_FRAMES]
    death_body = [normalize(extract_frame(clean, b)) for b in DEATH_BODY_FRAMES]
    death_shard = [normalize(extract_frame(clean, b)) for b in DEATH_SHARD_FRAMES]
    # attack 源图帧朝向: 大部分朝右(0-4,6), 只有第6帧(attack5)朝左需翻转
    attack_flips = [False, False, False, False, False, True, False]
    attack = [normalize(extract_frame(clean, b, f)) for b, f in zip(ATTACK_FRAMES, attack_flips)]
    idle_base = walk[0]

    # death 序列: 完整骷髅 x6 -> 碎片 x2 -> 空 x2
    death = death_body[:6]
    death += death_shard
    death += [Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))] * 2
    death = death[:10]

    sheet = Image.new("RGBA", (CELL * COLS, CELL * 5), (0, 0, 0, 0))
    def place(col, row, img):
        sheet.paste(img, (col * CELL, row * CELL), img)

    for col, img in enumerate(make_idle(idle_base, 6)):
        place(col, 0, img)
    for col, img in enumerate(cycle(walk, 10)):
        place(col, 1, img)
    for col, img in enumerate(cycle(attack, 6)):
        place(col, 2, img)
    for col, img in enumerate(hit[:5]):
        place(col, 3, img)
    for col, img in enumerate(death):
        place(col, 4, img)
    return sheet


def main():
    sheet = build_sheet()
    sheet.save(OUT)
    print("saved:", OUT, sheet.size)


if __name__ == "__main__":
    main()
