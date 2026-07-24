import math
import random
from pathlib import Path

import bpy
from mathutils import Vector


SEED = 20260615
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "assets" / "models" / "japanese_cloud_pine.glb"

random.seed(SEED)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def make_material(name, base_color, roughness=0.9):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.use_backface_culling = False
    bsdf = None
    for node in material.node_tree.nodes:
        if node.type == "BSDF_PRINCIPLED":
            bsdf = node
            break
    if bsdf is None:
        bsdf = material.node_tree.nodes.new(type="ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = base_color
    bsdf.inputs["Roughness"].default_value = roughness
    return material


def align_z_to_vector(direction):
    return direction.to_track_quat("Z", "Y").to_euler()


def cylinder_between(name, start, end, radius_start, radius_end, material, vertices=12):
    start = Vector(start)
    end = Vector(end)
    direction = end - start
    length = direction.length
    if length <= 0.0001:
        return None

    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius_start,
        radius2=radius_end,
        depth=length,
        end_fill_type="TRIFAN",
        location=(start + end) * 0.5,
        rotation=align_z_to_vector(direction),
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}Mesh"
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return obj


def trunk_center_at(z):
    return Vector((
        math.sin(z * 0.72) * 0.075 + math.sin(z * 1.9) * 0.025,
        math.cos(z * 0.58) * 0.045,
        z,
    ))


def trunk_radius_at(t):
    return 0.30 + (0.62 - 0.30) * ((1.0 - t) ** 0.72)


def create_gnarled_trunk(material):
    height = 6.15
    radial_segments = 72
    height_segments = 44
    verts = []
    faces = []

    for j in range(height_segments + 1):
        t = j / height_segments
        z = height * t
        center = trunk_center_at(z)
        base_radius = trunk_radius_at(t)
        for i in range(radial_segments):
            angle = math.tau * i / radial_segments
            groove = (
                math.sin(angle * 9.0 + z * 1.35) * 0.040
                + math.sin(angle * 18.0 - z * 0.65) * 0.026
                + math.sin(angle * 5.0 + z * 0.45) * 0.022
            )
            swelling = 0.06 * math.exp(-((z - 2.6) ** 2) / 2.8) * math.sin(angle * 3.0 + 0.7)
            radius = max(0.10, base_radius + groove + swelling + random.uniform(-0.010, 0.010))
            verts.append((center.x + math.cos(angle) * radius, center.y + math.sin(angle) * radius, z))

    for j in range(height_segments):
        for i in range(radial_segments):
            a = j * radial_segments + i
            b = j * radial_segments + (i + 1) % radial_segments
            c = (j + 1) * radial_segments + (i + 1) % radial_segments
            d = (j + 1) * radial_segments + i
            faces.append((a, b, c, d))

    mesh = bpy.data.meshes.new("JapaneseCloudPineTrunkMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("JapaneseCloudPineTrunk", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth()
    obj.select_set(False)
    return obj


def trunk_surface(z, angle, extra=0.0):
    center = trunk_center_at(z)
    radius = trunk_radius_at(min(max(z / 6.15, 0.0), 1.0)) + extra
    return center + Vector((math.cos(angle) * radius, math.sin(angle) * radius, 0))


def create_bark_cracks(material):
    for i in range(42):
        angle = math.tau * i / 42.0 + random.uniform(-0.06, 0.06)
        z0 = random.uniform(0.10, 0.55)
        z1 = random.uniform(4.8, 6.15)
        pieces = random.randint(5, 8)
        points = []
        for j in range(pieces):
            f = j / (pieces - 1)
            z = z0 + (z1 - z0) * f
            wobble = math.sin(f * math.pi * 2.0 + i * 0.31) * 0.045
            points.append(trunk_surface(z, angle + wobble, 0.030))
        curve = bpy.data.curves.new(f"DeepVerticalBarkCrack{i:02d}", "CURVE")
        curve.dimensions = "3D"
        curve.resolution_u = 2
        curve.bevel_depth = random.uniform(0.010, 0.022)
        curve.bevel_resolution = 2
        spline = curve.splines.new("POLY")
        spline.points.add(len(points) - 1)
        for point, co in zip(spline.points, points):
            point.co = (co.x, co.y, co.z, 1.0)
        obj = bpy.data.objects.new(curve.name, curve)
        bpy.context.collection.objects.link(obj)
        obj.data.materials.append(material)


def create_roots(material):
    for i in range(8):
        angle = math.tau * i / 8.0 + random.uniform(-0.18, 0.18)
        direction = Vector((math.cos(angle), math.sin(angle), 0))
        start = direction * 0.26 + Vector((0, 0, 0.20))
        end = direction * random.uniform(0.95, 1.55) + Vector((0, 0, random.uniform(0.03, 0.10)))
        cylinder_between(f"ExposedRoot{i:02d}", start, end, 0.18, 0.055, material, 10)


def branch_path(name, points, start_radius, end_radius, material, vertices=12):
    for i in range(len(points) - 1):
        f0 = i / max(1, len(points) - 1)
        f1 = (i + 1) / max(1, len(points) - 1)
        r0 = start_radius + (end_radius - start_radius) * f0
        r1 = start_radius + (end_radius - start_radius) * f1
        cylinder_between(f"{name}_seg{i:02d}", points[i], points[i + 1], r0, r1, material, vertices)


def local_axes(angle):
    x_axis = Vector((math.cos(angle), math.sin(angle), 0))
    y_axis = Vector((-math.sin(angle), math.cos(angle), 0))
    return x_axis, y_axis


def create_cloud_pad(name, center, size_x, size_y, thickness, angle, material, needle_materials):
    center = Vector(center)
    x_axis, y_axis = local_axes(angle)
    rings = 8
    segments = 56
    verts = []
    faces = []

    for layer in (1, -1):
        for r_i in range(rings + 1):
            r = r_i / rings
            for s in range(segments):
                theta = math.tau * s / segments
                oval = x_axis * (math.cos(theta) * size_x * r) + y_axis * (math.sin(theta) * size_y * r)
                crown = thickness * (1.0 - r ** 1.75) * (0.58 if layer > 0 else -0.42)
                edge_lift = math.sin(theta * 5.0 + size_x) * 0.035 * (1.0 - r * 0.35)
                jitter = random.uniform(-0.030, 0.030) * (0.25 + r)
                co = center + oval + Vector((0, 0, crown + edge_lift + jitter))
                verts.append(co[:])

    layer_offset = (rings + 1) * segments
    for r_i in range(rings):
        for s in range(segments):
            a = r_i * segments + s
            b = r_i * segments + (s + 1) % segments
            c = (r_i + 1) * segments + (s + 1) % segments
            d = (r_i + 1) * segments + s
            faces.append((a, b, c, d))

            ab = layer_offset + r_i * segments + s
            bb = layer_offset + (r_i + 1) * segments + s
            cb = layer_offset + (r_i + 1) * segments + (s + 1) % segments
            db = layer_offset + r_i * segments + (s + 1) % segments
            faces.append((ab, bb, cb, db))

    outer_top = rings * segments
    outer_bottom = layer_offset + rings * segments
    for s in range(segments):
        top_a = outer_top + s
        top_b = outer_top + (s + 1) % segments
        bottom_b = outer_bottom + (s + 1) % segments
        bottom_a = outer_bottom + s
        faces.append((top_a, top_b, bottom_b, bottom_a))

    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth()
    obj.select_set(False)

    create_pad_needles(f"{name}_NeedleFringe", center, size_x, size_y, thickness, angle, needle_materials)
    return obj


def create_pad_needles(name, center, size_x, size_y, thickness, angle, materials):
    center = Vector(center)
    x_axis, y_axis = local_axes(angle)
    verts = []
    faces = []
    mat_indices = []
    count = int(180 + (size_x + size_y) * 45)

    for _ in range(count):
        theta = random.uniform(0, math.tau)
        r = random.uniform(0.45, 1.03)
        base = center + x_axis * (math.cos(theta) * size_x * r) + y_axis * (math.sin(theta) * size_y * r)
        base.z += random.uniform(-0.04, thickness * 0.38)
        outward = (x_axis * math.cos(theta) + y_axis * math.sin(theta)).normalized()
        direction = (outward * random.uniform(0.45, 1.10) + Vector((0, 0, random.uniform(0.05, 0.36)))).normalized()
        side = direction.cross(Vector((0, 0, 1)))
        if side.length < 0.001:
            side = Vector((1, 0, 0))
        side.normalize()
        width = random.uniform(0.010, 0.020)
        length = random.uniform(0.30, 0.58)
        idx = len(verts)
        verts.extend([(base - side * width)[:], (base + side * width)[:], (base + direction * length)[:]])
        faces.append((idx, idx + 1, idx + 2))
        mat_indices.append(random.randrange(len(materials)))

    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for material in materials:
        obj.data.materials.append(material)
    for poly, mat_index in zip(obj.data.polygons, mat_indices):
        poly.material_index = mat_index
    return obj


def create_reference_style_tree(bark, dark_bark, pad_materials, needle_materials):
    create_gnarled_trunk(bark)
    create_bark_cracks(dark_bark)
    create_roots(bark)

    branches = [
        ("LowerLeftArm", [trunk_surface(2.35, 3.25, 0.04), (-1.15, -0.08, 2.45), (-3.20, -0.08, 2.75), (-4.85, 0.00, 3.00)], 0.18, 0.055),
        ("LowerRightArm", [trunk_surface(2.75, 6.08, 0.04), (1.30, 0.05, 2.70), (3.10, 0.03, 2.95), (4.80, 0.18, 3.25)], 0.17, 0.052),
        ("MiddleLeftArm", [trunk_surface(3.35, 3.85, 0.04), (-1.00, -0.35, 3.70), (-2.35, -0.42, 4.15), (-3.35, -0.36, 4.65)], 0.16, 0.045),
        ("MiddleRightArm", [trunk_surface(3.85, 5.90, 0.04), (1.05, 0.40, 4.05), (2.30, 0.62, 4.52), (3.35, 0.68, 4.92)], 0.15, 0.042),
        ("UpperLeftArm", [trunk_surface(4.80, 3.60, 0.04), (-0.70, -0.18, 5.38), (-1.70, -0.25, 6.15), (-2.70, -0.18, 6.95)], 0.13, 0.035),
        ("UpperRightArm", [trunk_surface(4.90, 0.25, 0.04), (0.85, 0.52, 5.55), (1.75, 0.75, 6.05), (2.55, 0.75, 6.46)], 0.13, 0.034),
        ("TopLeaderLeft", [trunk_center_at(5.35), (-0.25, -0.06, 6.12), (-0.88, -0.16, 7.08), (-1.35, -0.12, 7.72)], 0.12, 0.030),
        ("TopLeaderRight", [trunk_center_at(5.45), (0.28, 0.10, 6.20), (0.72, 0.22, 7.05), (1.18, 0.28, 7.55)], 0.11, 0.028),
    ]
    for name, points, start_radius, end_radius in branches:
        branch_path(name, [Vector(p) for p in points], start_radius, end_radius, bark, 12)

    pads = [
        ("LowerLeftCloud", (-4.18, -0.02, 3.18), 1.62, 0.42, 0.34, 0.04, 0),
        ("LowerLeftInnerCloud", (-2.15, -0.14, 3.10), 1.16, 0.36, 0.30, 0.12, 1),
        ("LowerRightCloud", (4.12, 0.22, 3.45), 1.74, 0.46, 0.34, 0.05, 0),
        ("MiddleLeftCloud", (-2.78, -0.48, 4.78), 1.42, 0.46, 0.36, 0.20, 1),
        ("CenterLowerCloud", (-0.32, -0.24, 4.18), 1.18, 0.40, 0.30, -0.05, 2),
        ("MiddleRightCloud", (2.72, 0.72, 5.10), 1.25, 0.42, 0.34, 0.12, 0),
        ("UpperLeftCloud", (-2.16, -0.20, 7.05), 1.18, 0.46, 0.34, 0.06, 0),
        ("UpperCenterCloud", (-0.42, 0.02, 6.55), 1.25, 0.48, 0.36, -0.12, 1),
        ("UpperRightCloud", (1.72, 0.36, 6.80), 1.04, 0.40, 0.30, 0.18, 2),
        ("TopLeftCloud", (-1.12, -0.18, 7.78), 0.90, 0.36, 0.28, 0.08, 1),
        ("TopRightCloud", (1.05, 0.30, 7.66), 0.88, 0.34, 0.26, 0.14, 0),
        ("FarLeftSmallCloud", (-5.45, 0.02, 3.34), 0.82, 0.28, 0.24, -0.04, 2),
        ("FarRightSmallCloud", (5.28, 0.22, 3.62), 0.84, 0.30, 0.24, 0.06, 1),
    ]
    for name, center, sx, sy, thickness, angle, material_index in pads:
        create_cloud_pad(name, center, sx, sy, thickness, angle, pad_materials[material_index], needle_materials)

    twig_specs = [
        ((-3.05, -0.08, 2.78), (-4.20, -0.02, 3.04), 0.040),
        ((3.10, 0.02, 2.98), (4.10, 0.20, 3.28), 0.040),
        ((-2.25, -0.42, 4.15), (-2.78, -0.48, 4.55), 0.034),
        ((2.30, 0.62, 4.55), (2.72, 0.72, 4.88), 0.032),
        ((-1.70, -0.25, 6.15), (-2.15, -0.20, 6.82), 0.030),
        ((0.72, 0.22, 7.05), (1.05, 0.30, 7.48), 0.026),
        ((-0.88, -0.16, 7.08), (-1.12, -0.18, 7.58), 0.026),
    ]
    for i, (start, end, radius) in enumerate(twig_specs):
        cylinder_between(f"VisibleTwigUnderCloud{i:02d}", start, end, radius, radius * 0.35, dark_bark, 8)


def export_glb():
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT_PATH),
        export_format="GLB",
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_draco_mesh_compression_enable=False,
    )


def main():
    clear_scene()
    bark = make_material("dark rugged pine bark", (0.20, 0.12, 0.065, 1), 0.98)
    dark_bark = make_material("black brown exposed branch bark", (0.055, 0.038, 0.024, 1), 1.0)
    pad_materials = [
        make_material("dense mature pine needle pad", (0.075, 0.24, 0.115, 1), 0.88),
        make_material("slightly blue green pine pad", (0.06, 0.20, 0.12, 1), 0.90),
        make_material("sunlit soft green pine pad", (0.13, 0.34, 0.15, 1), 0.84),
    ]
    needle_materials = [
        make_material("individual dark pine needles", (0.035, 0.13, 0.075, 1), 0.9),
        make_material("individual green pine needles", (0.08, 0.27, 0.12, 1), 0.88),
        make_material("individual yellow green needle tips", (0.15, 0.36, 0.14, 1), 0.82),
    ]
    create_reference_style_tree(bark, dark_bark, pad_materials, needle_materials)
    export_glb()


if __name__ == "__main__":
    main()
