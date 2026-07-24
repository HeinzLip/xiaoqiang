import math
import os
import random
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


SEED = 94721
HEIGHT = 18.0
TRUNK_BOTTOM_RADIUS = 0.72
TRUNK_TOP_RADIUS = 0.20
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "assets" / "models" / "realistic_large_pine.glb"


random.seed(SEED)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def make_material(name, base_color, roughness=0.9, metallic=0.0):
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
    bsdf.inputs["Metallic"].default_value = metallic
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


def trunk_radius_at(t):
    shaped = (1.0 - t) ** 1.22
    return TRUNK_TOP_RADIUS + (TRUNK_BOTTOM_RADIUS - TRUNK_TOP_RADIUS) * shaped


def trunk_surface_point(z, angle, extra_radius=0.0):
    t = z / HEIGHT
    radius = trunk_radius_at(t) + extra_radius
    return Vector((math.cos(angle) * radius, math.sin(angle) * radius, z))


def create_trunk(material):
    radial_segments = 80
    height_segments = 72
    verts = []
    faces = []

    for j in range(height_segments + 1):
        t = j / height_segments
        z = HEIGHT * t
        base_radius = trunk_radius_at(t)
        for i in range(radial_segments):
            angle = math.tau * i / radial_segments
            groove = (
                math.sin(angle * 10.0 + z * 0.82) * 0.030
                + math.sin(angle * 23.0 - z * 1.18) * 0.018
                + math.sin(angle * 5.0 + z * 0.21) * 0.020
            )
            rough = random.uniform(-0.010, 0.010)
            radius = max(0.05, base_radius + groove + rough)
            verts.append((math.cos(angle) * radius, math.sin(angle) * radius, z))

    for j in range(height_segments):
        for i in range(radial_segments):
            a = j * radial_segments + i
            b = j * radial_segments + (i + 1) % radial_segments
            c = (j + 1) * radial_segments + (i + 1) % radial_segments
            d = (j + 1) * radial_segments + i
            faces.append((a, b, c, d))

    bottom_center = len(verts)
    verts.append((0, 0, 0))
    top_center = len(verts)
    verts.append((0, 0, HEIGHT))
    for i in range(radial_segments):
        faces.append((bottom_center, i, (i + 1) % radial_segments))
        top_a = height_segments * radial_segments + i
        top_b = height_segments * radial_segments + (i + 1) % radial_segments
        faces.append((top_center, top_b, top_a))

    mesh = bpy.data.meshes.new("RealisticPineTrunkMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()

    obj = bpy.data.objects.new("RealisticPineTrunk", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth()
    obj.select_set(False)

    texture = bpy.data.textures.new("PineBarkFineNoise", "VORONOI")
    texture.noise_scale = 0.82
    texture.intensity = 0.28
    modifier = obj.modifiers.new("Fine bark relief", "DISPLACE")
    modifier.strength = 0.028
    modifier.texture = texture
    return obj


def create_bark_ridges(material):
    for i in range(34):
        base_angle = math.tau * i / 34.0 + random.uniform(-0.08, 0.08)
        z0 = random.uniform(0.2, 1.6)
        z1 = random.uniform(HEIGHT * 0.55, HEIGHT * 0.98)
        segments = random.randint(5, 8)
        points = []
        for j in range(segments):
            f = j / (segments - 1)
            z = z0 + (z1 - z0) * f
            angle = base_angle + math.sin(f * math.pi * 1.5 + i) * 0.055
            points.append(trunk_surface_point(z, angle, 0.025))

        curve = bpy.data.curves.new(f"DarkBarkCrease{i:02d}", "CURVE")
        curve.dimensions = "3D"
        curve.resolution_u = 2
        curve.bevel_depth = random.uniform(0.008, 0.018)
        curve.bevel_resolution = 2
        spline = curve.splines.new("POLY")
        spline.points.add(len(points) - 1)
        for point, co in zip(spline.points, points):
            point.co = (co.x, co.y, co.z, 1.0)

        obj = bpy.data.objects.new(curve.name, curve)
        bpy.context.collection.objects.link(obj)
        obj.data.materials.append(material)


def create_roots(material):
    for i in range(9):
        angle = math.tau * i / 9.0 + random.uniform(-0.16, 0.16)
        direction = Vector((math.cos(angle), math.sin(angle), 0))
        p0 = direction * 0.34 + Vector((0, 0, 0.16))
        p1 = direction * random.uniform(1.1, 1.75) + Vector((0, 0, random.uniform(0.04, 0.12)))
        cylinder_between(f"RootFlare{i:02d}", p0, p1, 0.20, 0.055, material, 10)


def perpendicular_basis(direction):
    direction = direction.normalized()
    up = Vector((0, 0, 1))
    if abs(direction.dot(up)) > 0.92:
        up = Vector((1, 0, 0))
    side = direction.cross(up).normalized()
    lift = side.cross(direction).normalized()
    return side, lift


def create_needle_cluster(name, center, direction, fullness, materials):
    direction = Vector(direction).normalized()
    side, lift = perpendicular_basis(direction)
    needle_count = int(random.randint(34, 52) * fullness)
    verts = []
    faces = []
    material_indices = []

    for _ in range(needle_count):
        swirl = random.uniform(0, math.tau)
        spread = random.uniform(0.02, 0.24) * fullness
        local_center = Vector(center) + side * math.cos(swirl) * spread + lift * math.sin(swirl) * spread
        fan = (
            direction * random.uniform(0.75, 1.15)
            + side * random.uniform(-0.48, 0.48)
            + lift * random.uniform(-0.18, 0.44)
        ).normalized()
        needle_len = random.uniform(0.42, 0.78) * fullness
        width = random.uniform(0.012, 0.026) * fullness
        needle_side, _ = perpendicular_basis(fan)
        base_a = local_center - needle_side * width
        base_b = local_center + needle_side * width
        tip = local_center + fan * needle_len
        idx = len(verts)
        verts.extend([base_a[:], base_b[:], tip[:]])
        faces.append((idx, idx + 1, idx + 2))
        material_indices.append(random.randrange(len(materials)))

    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for material in materials:
        obj.data.materials.append(material)
    for poly, mat_index in zip(obj.data.polygons, material_indices):
        poly.material_index = mat_index
    return obj


def create_pine_crown(branch_material, needle_materials):
    branch_endpoints = []
    for tier in range(17):
        t = tier / 16.0
        z = HEIGHT * (0.15 + 0.75 * t)
        tier_radius = HEIGHT * 0.36 * ((1.0 - t) ** 0.72) + 0.35
        branch_count = 9 if tier < 12 else 7
        angle_offset = random.uniform(0, math.tau)

        for branch_index in range(branch_count):
            angle = angle_offset + math.tau * branch_index / branch_count + random.uniform(-0.09, 0.09)
            out = Vector((math.cos(angle), math.sin(angle), 0))
            start = trunk_surface_point(z, angle, 0.03)
            slope = -0.20 + 0.50 * t
            length = tier_radius * random.uniform(0.76, 1.12)
            bend = Vector((-math.sin(angle), math.cos(angle), 0)) * random.uniform(-0.22, 0.22)
            mid = start + out * length * 0.54 + bend + Vector((0, 0, slope * length * 0.34))
            end = start + out * length + bend * 0.55 + Vector((0, 0, slope * length * 0.52))
            r0 = (0.13 - 0.075 * t) * random.uniform(0.86, 1.12)
            r1 = r0 * 0.44
            r2 = r0 * 0.20

            cylinder_between(f"PrimaryBranch{tier:02d}_{branch_index:02d}A", start, mid, r0, r1, branch_material, 10)
            cylinder_between(f"PrimaryBranch{tier:02d}_{branch_index:02d}B", mid, end, r1, r2, branch_material, 9)
            branch_endpoints.append((end, (end - mid).normalized(), 1.1 - t * 0.22))

            twig_count = 4 if tier < 13 else 3
            for twig in range(twig_count):
                f = random.uniform(0.45, 0.95)
                twig_start = mid.lerp(end, f)
                twig_angle = angle + random.choice([-1, 1]) * random.uniform(0.38, 0.85)
                twig_dir = (
                    Vector((math.cos(twig_angle), math.sin(twig_angle), 0)) * 0.88
                    + Vector((0, 0, random.uniform(-0.12, 0.42)))
                ).normalized()
                twig_length = length * random.uniform(0.18, 0.34) * (1.06 - t * 0.34)
                twig_end = twig_start + twig_dir * twig_length
                cylinder_between(
                    f"Twig{tier:02d}_{branch_index:02d}_{twig:02d}",
                    twig_start,
                    twig_end,
                    r1 * 0.36,
                    r1 * 0.10,
                    branch_material,
                    7,
                )
                branch_endpoints.append((twig_end, twig_dir, 0.82))

    for i, (endpoint, direction, fullness) in enumerate(branch_endpoints):
        create_needle_cluster(f"NeedleSpray{i:03d}", endpoint, direction, fullness, needle_materials)
        if random.random() < 0.62:
            side, lift = perpendicular_basis(direction)
            offset = side * random.uniform(-0.28, 0.28) + lift * random.uniform(-0.10, 0.24)
            create_needle_cluster(f"NeedleSprayExtra{i:03d}", endpoint + offset, direction, fullness * 0.82, needle_materials)


def create_top(branch_material, needle_materials):
    top_start = Vector((0, 0, HEIGHT * 0.82))
    top_end = Vector((0.08, -0.03, HEIGHT * 1.02))
    cylinder_between("StraightTopLeader", top_start, top_end, 0.09, 0.025, branch_material, 9)

    for i in range(28):
        z = random.uniform(HEIGHT * 0.80, HEIGHT * 1.01)
        angle = random.uniform(0, math.tau)
        direction = (Vector((math.cos(angle), math.sin(angle), random.uniform(0.28, 0.88)))).normalized()
        center = Vector((0, 0, z)) + Vector((math.cos(angle), math.sin(angle), 0)) * random.uniform(0.08, 0.45)
        create_needle_cluster(f"TopNeedleSpray{i:02d}", center, direction, random.uniform(0.62, 0.88), needle_materials)


def set_origin_and_scale():
    for obj in bpy.context.scene.objects:
        obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.select_all(action="DESELECT")


def add_lod_note():
    empty = bpy.data.objects.new("ModelNote_realistic_pine_generated_for_godot", None)
    empty["description"] = "Procedural realistic large pine: detailed bark, root flares, branches, twigs, and many triangular needle sprays."
    bpy.context.collection.objects.link(empty)


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
    bark = make_material("rough reddish brown pine bark", (0.32, 0.18, 0.09, 1), 0.97)
    dark_bark = make_material("deep bark creases", (0.12, 0.07, 0.035, 1), 1.0)
    needles = [
        make_material("deep blue green pine needles", (0.025, 0.15, 0.075, 1), 0.86),
        make_material("mature dark green pine needles", (0.04, 0.24, 0.105, 1), 0.88),
        make_material("fresh lit green needle tips", (0.12, 0.36, 0.15, 1), 0.82),
    ]

    create_trunk(bark)
    create_bark_ridges(dark_bark)
    create_roots(bark)
    create_pine_crown(bark, needles)
    create_top(bark, needles)
    add_lod_note()
    set_origin_and_scale()
    export_glb()


if __name__ == "__main__":
    main()
