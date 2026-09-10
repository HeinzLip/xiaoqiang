#!/usr/bin/env python3
"""基于原始素材重建普通怪标准精灵表。

背景: 项目里的 *_standard_sheet.png 是外部生成的坏素材 —— walk 行 10 帧
几乎全是同一个静态姿势, 且帧内容串帧/溢出格子, 播放时动画不连贯、被裁剪。

本脚本用原始连贯素材重建:
  - idle  (6帧):  原始 idle 单帧做轻微呼吸动画（上下浮动 + 缩放）
  - walk  (10帧): 原始 walk 动画帧循环扩展 (0,1,2,0,1,2,0,1,2,0), 保证步态连贯
  - hit   (5帧):  idle 帧 + 白色闪烁 + 轻微后仰
  - death (10帧): idle 帧下沉 + 缩小 + 淡出

所有帧统一: 裁剪到内容、缩放、脚底对齐、水平居中, 严格放在 256x256 格子内,
保证播放时不被 Sprite2D 裁剪、不串帧。

原始素材帧宽 (按内容段检测):
  rotten_zombie / alien_creature / sci_fi_monster: 768px = 3帧 x 256px
  evil_bug: 1152px = 3帧 x 384px
"""
import argparse
import math
import os
from pathlib import Path

import numpy as np
from PIL import Image

CELL = 256
OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "enemies"

# 每只怪的原始素材配置: idle 单帧 + walk 动画
# 僵尸的移动风格以 clean_walk 为准(用户认可), idle/hit/death 均从
# clean_walk 派生以保证风格统一; 其他怪用与 idle 同源的 walk 素材。
# flip: 原始素材默认面朝左则需要翻转为朝右 (enemy.gd 假设朝右)
MONSTERS = {
    "rotten_zombie": {
        "idle": "rotten_zombie_clean_walk_aligned.png",
        "idle_frame": 1,
        "walk": "rotten_zombie_clean_walk_aligned.png",
        "walk_frame_width": 256,
        "flip": False,
    },
    "evil_bug": {
        "idle": "evil_bug.png",
        "walk": "evil_bug_walk_aligned.png",
        "walk_frame_width": 384,
        "flip": True,
    },
    "alien_creature": {
        "idle": "alien_creature.png",
        "walk": "alien_creature_walk_aligned.png",
        "walk_frame_width": 256,
        "flip": True,
    },
    "sci_fi_monster": {
        "idle": "sci_fi_monster.png",
        "walk": "sci_fi_monster_walk_aligned.png",
        "walk_frame_width": 256,
        "flip": False,
    },
}


def normalize_frame(img: Image.Image, target_height: int = 200, flip: bool = True) -> Image.Image:
    """裁剪 alpha 内容、缩放、放入 256x256 格子: 脚底对齐 + 水平居中。

    原始素材默认面朝左, 而 enemy.gd 的 flip 逻辑假设素材默认面朝右,
    因此默认统一水平翻转; flip=False 的怪(原始已朝右)不翻转。
    """
    if flip:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    alpha = np.array(img.convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > 40)
    if len(xs) == 0:
        return Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    x0, x1 = xs.min(), xs.max()
    y0, y1 = ys.min(), ys.max()
    crop = img.crop((x0, y0, x1 + 1, y1 + 1))
    cw, ch = crop.size
    scale = min(target_height / ch, (CELL - 16) / cw)
    nw, nh = max(1, int(round(cw * scale))), max(1, int(round(ch * scale)))
    nw, nh = min(nw, CELL - 12), min(nh, CELL - 8)
    crop = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    px = (CELL - nw) // 2
    py = CELL - 6 - nh
    canvas.paste(crop, (px, py), crop)
    return canvas


def load_idle_frame(name: str, cfg: dict, target_height: int) -> Image.Image:
    """加载 idle 基础帧。

    若配置了 idle_frame, 从 walk 素材中取该帧作为 idle(保证与移动风格统一);
    否则使用独立 idle 素材。
    """
    if "idle_frame" in cfg:
        src = Image.open(OUT_DIR / cfg["walk"]).convert("RGBA")
        fw = cfg["walk_frame_width"]
        frame = int(cfg["idle_frame"])
        return normalize_frame(src.crop((frame * fw, 0, (frame + 1) * fw, src.size[1])),
                               target_height, cfg.get("flip", True))
    src = Image.open(OUT_DIR / cfg["idle"]).convert("RGBA")
    return normalize_frame(src, target_height, cfg.get("flip", True))


def load_walk_frames(name: str, cfg: dict, target_height: int):
    src = Image.open(OUT_DIR / cfg["walk"]).convert("RGBA")
    fw = cfg["walk_frame_width"]
    count = src.size[0] // fw
    flip = cfg.get("flip", True)
    frames = [normalize_frame(src.crop((i * fw, 0, (i + 1) * fw, src.size[1])), target_height, flip)
              for i in range(count)]
    return frames


def make_idle(base: Image.Image, count=6) -> list:
    """呼吸动画: 整帧平滑上下浮动 + 轻微缩放。"""
    frames = []
    base_arr = np.array(base)
    for i in range(count):
        t = (i + 0.5) / count
        bob = 3 * np.sin(t * np.pi * 2)
        scale = 1.0 + 0.015 * np.sin(t * np.pi * 2 + np.pi)
        nw = max(1, int(CELL * scale))
        content = Image.fromarray(base_arr).resize((nw, nw), Image.LANCZOS)
        canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        px = (CELL - nw) // 2
        py = CELL - 6 - nw + int(round(bob))
        canvas.paste(content, (px, py), content)
        frames.append(canvas)
    return frames


def make_walk(walk_frames: list, count=10) -> list:
    """用原始清晰 walk 帧做往返循环, 保留明显换腿。

    原始 3 帧代表 左步 -> 并步 -> 右步, 往返 (0,1,2,1,0,1,...)
    让脚部在相邻帧间真实切换, 换腿清晰可见。
    """
    n = len(walk_frames)
    out = []
    period = n * 2 - 2 if n > 1 else 1
    for i in range(count):
        t = i % period
        idx = t if t < n else period - t
        out.append(walk_frames[idx])
    return out


def tint_color(img: Image.Image, color: tuple, amount: float) -> Image.Image:
    """按 amount (0..1) 向指定颜色混合。"""
    arr = np.array(img).astype(np.float32)
    arr[:, :, 0] = arr[:, :, 0] * (1 - amount) + color[0] * amount
    arr[:, :, 1] = arr[:, :, 1] * (1 - amount) + color[1] * amount
    arr[:, :, 2] = arr[:, :, 2] * (1 - amount) + color[2] * amount
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def make_hit(base: Image.Image, count=5) -> list:
    """受击动画: 白色渐显再渐隐 (平滑脉冲), 短促后仰。"""
    frames = []
    white = (255, 255, 255)
    for i in range(count):
        t = i / max(count - 1, 1)
        # 白色先渐显到峰值, 再渐隐回正常 (正弦包络)
        amount = 0.9 * math.sin(t * math.pi)
        lean = int(round((1.0 - t) * 4))
        img = tint_color(base, white, amount)
        canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        canvas.paste(img, (lean, 0), img)
        frames.append(canvas)
    return frames


def make_death(base: Image.Image, count=10) -> list:
    """死亡动画: 角色粉碎成碎片, 碎片向外飞散 + 旋转 + 淡出。

    前 20% 帧开始碎裂(出现裂缝感), 之后碎片逐帧扩散、旋转、淡出,
    最后一帧完全消失。
    """
    frames = []
    shards = _split_into_shards(base, cols=4, rows=3)
    rng = np.random.default_rng(12345)
    # 每块碎片的飞行方向、旋转、速度 (归一化)
    shard_params = []
    for (sx0, sy0, sx1, sy1) in shards:
        cx, cy = (sx0 + sx1) / 2.0 - CELL / 2.0, (sy0 + sy1) / 2.0 - CELL / 2.0
        angle = math.atan2(cy, cx) if (cx * cx + cy * cy) > 1.0 else rng.uniform(0, math.tau)
        dist = math.hypot(cx, cy)
        speed = 45.0 + dist * 0.2 + rng.uniform(-6, 10)
        spin = rng.uniform(-1.4, 1.4)
        shard_params.append((angle, speed, spin))

    for i in range(count):
        t = i / max(count - 1, 1)
        # 前 15% 整体不动(准备碎裂), 之后碎片开始扩散
        spread = max(0.0, t - 0.15) / 0.85
        if spread >= 1.0:
            frames.append(Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0)))
            continue
        canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        for idx, ((sx0, sy0, sx1, sy1), (angle, speed, spin)) in enumerate(zip(shards, shard_params)):
            piece = base.crop((sx0, sy0, sx1 + 1, sy1 + 1))
            # 扩散距离 + 旋转
            shift = speed * spread
            dx, dy = math.cos(angle) * shift, math.sin(angle) * shift
            rot_deg = math.degrees(spin * spread * 6.0)
            alpha_mult = 1.0 - max(0.0, (spread - 0.8) / 0.2)
            if alpha_mult <= 0.01:
                continue
            piece = piece.rotate(rot_deg, expand=False, resample=Image.BILINEAR)
            piece_arr = np.array(piece).astype(np.float32)
            piece_arr[:, :, 3] = piece_arr[:, :, 3] * alpha_mult
            piece = Image.fromarray(np.clip(piece_arr, 0, 255).astype(np.uint8), "RGBA")
            canvas.paste(piece, (int(sx0 + dx), int(sy0 + dy)), piece)
        frames.append(canvas)
    return frames


def _split_into_shards(base: Image.Image, cols=4, rows=3) -> list:
    """把角色内容按 alpha 有效区域切分为 cols x rows 块。"""
    alpha = np.array(base.convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > 40)
    if len(xs) == 0:
        return [(0, 0, CELL - 1, CELL - 1)]
    x0, x1 = xs.min(), xs.max()
    y0, y1 = ys.min(), ys.max()
    w, h = x1 - x0 + 1, y1 - y0 + 1
    shards = []
    for cy in range(rows):
        sy0 = y0 + cy * h // rows
        sy1 = (y0 + (cy + 1) * h // rows) if cy < rows - 1 else y1
        for cx in range(cols):
            sx0 = x0 + cx * w // cols
            sx1 = (x0 + (cx + 1) * w // cols) if cx < cols - 1 else x1
            # 跳过纯透明块
            cell_alpha = alpha[sy0:sy1 + 1, sx0:sx1 + 1]
            if (cell_alpha > 40).any():
                shards.append((sx0, sy0, sx1, sy1))
    return shards


def build_sheet(name: str, cfg: dict) -> Image.Image:
    idle_base = load_idle_frame(name, cfg, target_height=200)
    walk_frames = load_walk_frames(name, cfg, target_height=200)
    sheet = Image.new("RGBA", (CELL * 10, CELL * 4), (0, 0, 0, 0))

    def place(col, row, img):
        sheet.paste(img, (col * CELL, row * CELL), img)

    for col, img in enumerate(make_idle(idle_base, 6)):
        place(col, 0, img)
    for col, img in enumerate(make_walk(walk_frames, 10)):
        place(col, 1, img)
    for col, img in enumerate(make_hit(idle_base, 5)):
        place(col, 2, img)
    for col, img in enumerate(make_death(idle_base, 10)):
        place(col, 3, img)
    return sheet


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("names", nargs="*", help="怪物名; 默认全部")
    args = parser.parse_args()
    targets = args.names or list(MONSTERS.keys())
    for name in targets:
        cfg = MONSTERS[name]
        sheet = build_sheet(name, cfg)
        out = OUT_DIR / f"{name}_standard_sheet.png"
        sheet.save(out)
        print("rebuilt:", out, sheet.size)


if __name__ == "__main__":
    main()
