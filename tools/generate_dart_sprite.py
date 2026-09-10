#!/usr/bin/env python3
"""程序化生成飞镖精灵图 v2 (减少锯齿版)。

v2 相对 v1 的改进:
- 刃型从直线多边形改为二次贝塞尔曲线刃: 消除长斜边的阶梯感 (锯齿主因)
- 刃尖用小圆帽圆角化, 不再尖锐刺点
- 超采样从 4x 提升到 8x + LANCZOS: 更多 alpha 渐变层级, 边缘更平滑
- 描边改为固定像素内缩 (均匀约 2px), 而非比例内缩
- 配合 .import 中 mipmaps/generate=true (长期缩小到 25px 显示, 消除采样闪烁)

设计: 4 刃手里剑, 3 钢蓝 + 1 金刃 (旋转可辨), 银白轴心 + 深色孔。

用法: python3 tools/generate_dart_sprite.py
输出: assets/effects/dart_shuriken.png (需 Godot 重新导入)
"""
from PIL import Image, ImageDraw
import math
import os

SIZE = 128
SS = 8  # 超采样倍数 (抗锯齿)
W = SIZE * SS
C = W // 2

TIP_R = 50.0 * SS                # 刃尖半径
BASE_R = 15.0 * SS               # 刃根(内角)半径
BASE_HALF_ANGLE = 36.0           # 刃根半张角 (度)
SIDE_CTRL_R = 27.0 * SS          # 刃侧贝塞尔控制点半径 (小于直线中点 => 微凹刃线, 保留星形轮廓又去阶梯)
OUTLINE_PX = 2.0 * SS            # 描边厚度 (最终约 2px, 扁平卡通粗描边)
TIP_ROUND_R = 2.2 * SS           # 尖端圆角半径

OUTLINE_COLOR = (43, 58, 74, 255)     # 深蓝灰描边
BLADE_COLOR = (94, 135, 172, 255)     # 钢蓝刀刃
GOLD_COLOR = (232, 184, 75, 255)      # 金色主刃
HUB_SILVER = (217, 226, 236, 255)     # 银白轴心
HOLE_COLOR = (30, 42, 54, 255)        # 中心孔

OUT_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "effects", "dart_shuriken.png")


def pt(angle_deg: float, radius: float):
    a = math.radians(angle_deg)
    return (C + math.cos(a) * radius, C + math.sin(a) * radius)


def bezier(p0, p1, p2, steps: int):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        mt = 1.0 - t
        pts.append((mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0],
                    mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1]))
    return pts


def blade_points(tip_angle: float):
    """单刃闭合轮廓: 左根 -> 贝塞尔侧线 -> 尖 -> 贝塞尔侧线 -> 右根 (自动闭合)。"""
    base_left = pt(tip_angle + BASE_HALF_ANGLE, BASE_R)
    base_right = pt(tip_angle - BASE_HALF_ANGLE, BASE_R)
    tip = pt(tip_angle, TIP_R)
    ctrl_left = pt(tip_angle + BASE_HALF_ANGLE / 2.0, SIDE_CTRL_R)
    ctrl_right = pt(tip_angle - BASE_HALF_ANGLE / 2.0, SIDE_CTRL_R)
    left = bezier(base_left, ctrl_left, tip, 12)
    right = bezier(tip, ctrl_right, base_right, 12)
    return left + right[1:]


def centroid(poly):
    n = float(len(poly))
    return (sum(p[0] for p in poly) / n, sum(p[1] for p in poly) / n)


def inset_poly(poly, dist: float):
    """沿各点到质心的方向内缩固定像素, 得到均匀厚度描边。"""
    cx, cy = centroid(poly)
    out = []
    for (x, y) in poly:
        dx, dy = cx - x, cy - y
        length = math.hypot(dx, dy)
        if length < 1e-6:
            out.append((x, y))
        else:
            out.append((x + dx / length * dist, y + dy / length * dist))
    return out


def main() -> None:
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    for i in range(4):
        tip_angle = 45.0 + 90.0 * i
        fill_color = GOLD_COLOR if i == 0 else BLADE_COLOR  # 45度主刃金色
        blade = blade_points(tip_angle)
        # 描边 (满尺寸) + 填充 (内缩)
        d.polygon(blade, fill=OUTLINE_COLOR)
        d.polygon(inset_poly(blade, OUTLINE_PX), fill=fill_color)
        # 尖端圆角: 描边圆 + 填充圆
        tip = pt(tip_angle, TIP_R)
        d.ellipse([tip[0] - TIP_ROUND_R, tip[1] - TIP_ROUND_R,
                   tip[0] + TIP_ROUND_R, tip[1] + TIP_ROUND_R], fill=OUTLINE_COLOR)
        tr2 = TIP_ROUND_R * 0.55
        d.ellipse([tip[0] - tr2, tip[1] - tr2, tip[0] + tr2, tip[1] + tr2], fill=fill_color)

    # 轴心: 描边圆 + 银白圆 + 深色孔
    r_out, r_in, r_hole = 12.5 * SS, 9.5 * SS, 4.5 * SS
    d.ellipse([C - r_out, C - r_out, C + r_out, C + r_out], fill=OUTLINE_COLOR)
    d.ellipse([C - r_in, C - r_in, C + r_in, C + r_in], fill=HUB_SILVER)
    d.ellipse([C - r_hole, C - r_hole, C + r_hole, C + r_hole], fill=HOLE_COLOR)

    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    out = os.path.normpath(OUT_PATH)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print("saved:", out)


if __name__ == "__main__":
    main()
