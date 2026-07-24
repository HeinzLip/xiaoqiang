@tool
class_name LargePineTree
extends Node3D

@export_range(8.0, 30.0, 0.5) var tree_height: float = 16.0:
	set(value):
		tree_height = maxf(value, 1.0)
		_schedule_rebuild()

@export_range(0.2, 1.2, 0.05) var trunk_radius: float = 0.48:
	set(value):
		trunk_radius = maxf(value, 0.05)
		_schedule_rebuild()

@export_range(6, 18, 1) var branch_tiers: int = 12:
	set(value):
		branch_tiers = maxi(value, 1)
		_schedule_rebuild()

@export_range(0.6, 1.6, 0.05) var foliage_fullness: float = 1.15:
	set(value):
		foliage_fullness = maxf(value, 0.1)
		_schedule_rebuild()

@export var random_seed: int = 4312:
	set(value):
		random_seed = value
		_schedule_rebuild()

const GENERATED_GROUP := "_large_pine_tree_generated"

var _rng := RandomNumberGenerator.new()
var _bark_material: StandardMaterial3D
var _bark_dark_material: StandardMaterial3D
var _needle_material: StandardMaterial3D
var _needle_dark_material: StandardMaterial3D
var _needle_light_material: StandardMaterial3D


func _enter_tree() -> void:
	_schedule_rebuild()


func _ready() -> void:
	_schedule_rebuild()


func _schedule_rebuild() -> void:
	if not is_inside_tree():
		return
	call_deferred("_rebuild_tree")


func _rebuild_tree() -> void:
	if not is_inside_tree():
		return

	_clear_generated_nodes()
	_rng.seed = random_seed
	_create_materials()

	var model_root := Node3D.new()
	model_root.name = "GeneratedModel"
	model_root.add_to_group(GENERATED_GROUP)
	add_child(model_root)

	_add_trunk(model_root)
	_add_bark_ridges(model_root)
	_add_branch_tiers(model_root)
	_add_layered_needles(model_root)
	_add_top_spire(model_root)


func _clear_generated_nodes() -> void:
	for child in get_children():
		if child.is_in_group(GENERATED_GROUP):
			remove_child(child)
			child.queue_free()


func _create_materials() -> void:
	_bark_material = _make_material(Color(0.45, 0.28, 0.16), 0.92)
	_bark_dark_material = _make_material(Color(0.24, 0.14, 0.08), 0.96)
	_needle_material = _make_material(Color(0.05, 0.28, 0.13), 0.86)
	_needle_dark_material = _make_material(Color(0.025, 0.14, 0.075), 0.92)
	_needle_light_material = _make_material(Color(0.11, 0.40, 0.18), 0.82)


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _add_trunk(parent: Node3D) -> void:
	var height := tree_height * 0.96
	var trunk := _create_cylinder(
		"StraightTrunk",
		Vector3.ZERO,
		Vector3.UP,
		height,
		trunk_radius,
		trunk_radius * 0.28,
		_bark_material,
		20
	)
	parent.add_child(trunk)


func _add_bark_ridges(parent: Node3D) -> void:
	var ridge_count := 9
	for i in range(ridge_count):
		var angle := TAU * float(i) / float(ridge_count)
		var radius := trunk_radius * 1.025
		var xz := Vector3(cos(angle), 0.0, sin(angle)) * radius
		var ridge_height := tree_height * _rng.randf_range(0.55, 0.82)
		var start_y := _rng.randf_range(0.2, tree_height * 0.12)
		var ridge := _create_cylinder(
			"BarkRidge%02d" % i,
			Vector3(xz.x, start_y, xz.z),
			Vector3.UP,
			ridge_height,
			trunk_radius * 0.035,
			trunk_radius * 0.018,
			_bark_dark_material,
			8
		)
		parent.add_child(ridge)


func _add_branch_tiers(parent: Node3D) -> void:
	for tier in range(branch_tiers):
		var tier_ratio := float(tier) / float(maxi(branch_tiers - 1, 1))
		var y := lerpf(tree_height * 0.18, tree_height * 0.83, tier_ratio)
		var tier_radius := _branch_radius_for_tier(tier_ratio)
		var branch_count := 8 if tier % 2 == 0 else 7
		var angle_offset := tier_ratio * 1.7 + _rng.randf_range(-0.12, 0.12)

		for branch_index in range(branch_count):
			var angle := TAU * float(branch_index) / float(branch_count) + angle_offset
			var horizontal := Vector3(cos(angle), 0.0, sin(angle))
			var slope := lerpf(-0.10, 0.28, tier_ratio)
			var direction := Vector3(horizontal.x, slope, horizontal.z).normalized()
			var branch_length := tier_radius * _rng.randf_range(0.78, 1.08)
			var branch_start := Vector3(0.0, y, 0.0) + horizontal * trunk_radius * 0.56
			var branch_radius := lerpf(trunk_radius * 0.12, trunk_radius * 0.045, tier_ratio)

			var branch := _create_cylinder(
				"Branch%02d_%02d" % [tier, branch_index],
				branch_start,
				direction,
				branch_length,
				branch_radius,
				branch_radius * 0.35,
				_bark_material,
				10
			)
			parent.add_child(branch)

			_add_needles_on_branch(parent, branch_start, direction, branch_length, tier_ratio, tier, branch_index)


func _add_needles_on_branch(
	parent: Node3D,
	branch_start: Vector3,
	direction: Vector3,
	branch_length: float,
	tier_ratio: float,
	tier: int,
	branch_index: int
) -> void:
	var cluster_count := 3
	for cluster_index in range(cluster_count):
		var along := lerpf(0.45, 0.98, float(cluster_index) / float(cluster_count - 1))
		var center := branch_start + direction * branch_length * along
		center.y += _rng.randf_range(-0.12, 0.16)

		var width := branch_length * lerpf(0.28, 0.18, tier_ratio) * foliage_fullness
		var length := branch_length * lerpf(0.34, 0.22, tier_ratio) * foliage_fullness
		var height := lerpf(0.42, 0.26, tier_ratio) * foliage_fullness
		var material := _needle_material
		if cluster_index == 0:
			material = _needle_dark_material
		elif cluster_index == cluster_count - 1:
			material = _needle_light_material

		var cluster := _create_ellipsoid(
			"NeedleCluster%02d_%02d_%02d" % [tier, branch_index, cluster_index],
			center,
			direction,
			Vector3(width, length, height),
			material
		)
		parent.add_child(cluster)


func _add_layered_needles(parent: Node3D) -> void:
	for tier in range(branch_tiers + 1):
		var tier_ratio := float(tier) / float(branch_tiers)
		var y := lerpf(tree_height * 0.22, tree_height * 0.90, tier_ratio)
		var radius := _branch_radius_for_tier(tier_ratio) * 0.9
		var height := lerpf(1.45, 0.85, tier_ratio) * foliage_fullness
		var cone := _create_cone(
			"FullNeedleLayer%02d" % tier,
			Vector3(0.0, y, 0.0),
			radius,
			radius * 0.10,
			height,
			_needle_material if tier % 2 == 0 else _needle_dark_material
		)
		parent.add_child(cone)


func _add_top_spire(parent: Node3D) -> void:
	var tip := _create_cone(
		"LeafyTopSpire",
		Vector3(0.0, tree_height * 0.91, 0.0),
		trunk_radius * 1.05 * foliage_fullness,
		0.02,
		tree_height * 0.16,
		_needle_light_material
	)
	parent.add_child(tip)

	var stem := _create_cylinder(
		"VisibleTopStem",
		Vector3(0.0, tree_height * 0.82, 0.0),
		Vector3.UP,
		tree_height * 0.15,
		trunk_radius * 0.16,
		trunk_radius * 0.04,
		_bark_material,
		12
	)
	parent.add_child(stem)


func _branch_radius_for_tier(tier_ratio: float) -> float:
	var base_radius := tree_height * 0.34 * foliage_fullness
	var taper := pow(1.0 - tier_ratio, 0.72)
	return maxf(tree_height * 0.045, base_radius * taper)


func _create_cylinder(
	instance_name: String,
	start: Vector3,
	direction: Vector3,
	height: float,
	bottom_radius: float,
	top_radius: float,
	material: Material,
	segments: int
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.radial_segments = segments
	mesh.rings = 2

	var instance := MeshInstance3D.new()
	instance.name = instance_name
	instance.mesh = mesh
	instance.material_override = material
	instance.transform = Transform3D(_basis_from_y_axis(direction.normalized()), start + direction.normalized() * height * 0.5)
	return instance


func _create_cone(
	instance_name: String,
	center: Vector3,
	bottom_radius: float,
	top_radius: float,
	height: float,
	material: Material
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.radial_segments = 28
	mesh.rings = 3

	var instance := MeshInstance3D.new()
	instance.name = instance_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	return instance


func _create_ellipsoid(
	instance_name: String,
	center: Vector3,
	direction: Vector3,
	size: Vector3,
	material: Material
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8

	var instance := MeshInstance3D.new()
	instance.name = instance_name
	instance.mesh = mesh
	instance.material_override = material
	instance.transform = Transform3D(_basis_from_y_axis(direction.normalized()), center)
	instance.scale = size
	return instance


func _basis_from_y_axis(direction: Vector3) -> Basis:
	var normalized_direction := direction.normalized()
	if normalized_direction.is_equal_approx(Vector3.UP):
		return Basis.IDENTITY
	if normalized_direction.is_equal_approx(Vector3.DOWN):
		return Basis(Vector3.RIGHT, PI)

	var axis := Vector3.UP.cross(normalized_direction).normalized()
	var angle := Vector3.UP.angle_to(normalized_direction)
	return Basis(axis, angle)
