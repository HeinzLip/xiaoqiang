class_name LightningStrike extends Node2D

## 落雷: 一道闪电从天上劈向落点, 命中半径内的敌人并造成伤害。
## 可带感电效果 (短暂减速)。

const STRIKE_DURATION := 0.35
const STRIKE_SEGMENTS := 12
const STRIKE_THICKNESS := 4.0
const JITTER := 42.0
const HIT_DELAY := 0.08

var _damage := 1.0
var _radius := 5.0
var _shock_duration := 0.0
var _shock_chance := 0.0
var _shock_damage_bonus := 0.0
var _elapsed := 0.0
var _delay := 0.0
var _did_hit := false
var _strike_seed := 0

func configure(target_position: Vector2, damage: float, radius: float, shock_duration: float, shock_chance: float, shock_damage_bonus: float, start_delay: float = 0.0) -> void:
	global_position = target_position
	_damage = maxf(damage, 0.0)
	_radius = maxf(radius, 1.0)
	_shock_duration = maxf(shock_duration, 0.0)
	_shock_chance = clampf(shock_chance, 0.0, 1.0)
	_shock_damage_bonus = maxf(shock_damage_bonus, 0.0)
	_delay = maxf(start_delay, 0.0)
	_strike_seed = randi()

var _strike_points: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	# 闪电从画面上方劈下 (此时节点已在场景树内, 可安全取视口)
	var viewport_size := get_viewport_rect().size
	var origin_y := -viewport_size.y * 0.5
	_strike_points = _build_strike_path(origin_y)
	queue_redraw()

func _build_strike_path(origin_y: float) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _strike_seed
	var points := PackedVector2Array()
	var step_y := (-origin_y) / float(STRIKE_SEGMENTS)
	for i in range(STRIKE_SEGMENTS + 1):
		var y := origin_y + step_y * float(i)
		var jitter := 0.0
		if i > 0 and i < STRIKE_SEGMENTS:
			jitter = rng.randf_range(-JITTER, JITTER)
		points.append(Vector2(jitter, y))
	return points

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= STRIKE_DURATION + _delay:
		queue_free()
		return
	# 延迟后命中一次
	if not _did_hit and _elapsed >= _delay + HIT_DELAY:
		_did_hit = true
		_apply_hit()
	queue_redraw()

func _apply_hit() -> void:
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		# 用敌人实际碰撞体 (含缩放) 与落雷圆做相交检测, 而不是只看中心点
		if not _circle_intersects_enemy(enemy):
			continue
		# 感电中的敌人再次被落雷击中: 伤害 +50% (可被强化提高)
		var final_damage := _damage
		if enemy.is_shocked() and _shock_damage_bonus > 0.0:
			final_damage = _damage * (1.0 + _shock_damage_bonus)
		# 命中后按概率施加感电 (刷新持续时间)
		if _shock_duration > 0.0 and randf() < _shock_chance:
			enemy.apply_shock(_shock_duration)
		enemy.apply_damage(-final_damage)

## 判断落雷圆是否与敌人碰撞体相交 (考虑 scale)。
func _circle_intersects_enemy(enemy: Enemy) -> bool:
	var shape_node := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		# 无碰撞体时退回中心点距离判断
		return enemy.global_position.distance_squared_to(global_position) <= _radius * _radius
	var rect := shape_node.shape as RectangleShape2D
	if rect != null:
		var extents := rect.size * 0.5
		var center := shape_node.global_position
		var half_w := extents.x * absf(enemy.scale.x)
		var half_h := extents.y * absf(enemy.scale.y)
		# 圆 vs AABB 相交
		var closest_x := clampf(global_position.x, center.x - half_w, center.x + half_w)
		var closest_y := clampf(global_position.y, center.y - half_h, center.y + half_h)
		var dx := global_position.x - closest_x
		var dy := global_position.y - closest_y
		return dx * dx + dy * dy <= _radius * _radius
	# 其他形状退回中心点距离
	return enemy.global_position.distance_squared_to(global_position) <= _radius * _radius

func _draw() -> void:
	if _elapsed < _delay:
		return
	var progress := (_elapsed - _delay) / STRIKE_DURATION
	if progress >= 1.0:
		return
	var alpha := 1.0 - progress
	var flash := 0.0
	# 命中瞬间更亮
	if _elapsed >= _delay + HIT_DELAY and _elapsed < _delay + HIT_DELAY + 0.08:
		flash = 1.0
	var outline := Color(0.35, 0.6, 0.95, alpha)
	var core := Color(0.9, 0.97, 1.0, alpha)
	draw_polyline(_strike_points, outline, STRIKE_THICKNESS + 3.0, true)
	draw_polyline(_strike_points, core, STRIKE_THICKNESS, true)
	# 落点爆炸圆
	var impact_alpha := alpha * (0.8 if flash > 0.0 else 0.5)
	draw_circle(Vector2.ZERO, _radius + 8.0, Color(0.6, 0.85, 1.0, impact_alpha * 0.5))
	draw_arc(Vector2.ZERO, _radius + 8.0, 0.0, TAU, 24, Color(0.9, 0.97, 1.0, impact_alpha), 2.0)
