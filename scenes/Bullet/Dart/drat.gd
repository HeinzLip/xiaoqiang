class_name Dart extends Bullet

## 飞镖三阶段机制: 飞出 1 秒(对沿途敌人造成一次飞行伤害) -> 原地旋转 spin_time 秒周期造成伤害
## -> 爆炸: 对 1.2x碰撞体半径 内敌人造成爆炸伤害 -> 隐藏等待下次发射复用。
## 伤害刻度 (对齐游戏 ~1 级刻度): 飞行 0.5 = 旋转 0.8 x FLY_DAMAGE_RATIO(0.625); 爆炸 2。
## 爆炸半径动态: 1.2 x 碰撞体实际尺寸 (24 x dart_scale 体积强化) x 爆炸半径卡倍率。
## 伤害值均为正数, 应用时取负; 基础伤害已含永久加成, 专属比例由属性回调维护, 通用倍率在应用时相乘。

const SPIN_TICK_INTERVAL := 0.2    # 旋转阶段伤害结算间隔
const SPIN_ROTATE_SPEED := TAU * 3.0
const FLY_SPIN_SPEED := TAU * 2.0   # 飞行阶段视觉自旋速度 (动效, 不影响移动方向)
const FLY_TIME := 1.0               # 飞行时长固定 (覆盖距离成长走 MOVE_SPEED 飞行速度卡)
const FLY_DAMAGE_RATIO := 0.625     # 飞行伤害 = 旋转伤害 x 0.625 (0.5 / 0.8)
const DART_COLLISION_SIZE := 24.0   # Dart.tscn 碰撞体尺寸 (RectangleShape2D 24x24)
const EXPLOSION_RADIUS_RATIO := 1.2 # 爆炸半径 = 碰撞体实际尺寸 x 1.2

enum Phase { FLY, SPIN }

@onready var sprite: Sprite2D = $Sprite2D

var attribute_set: AttributeSet

var move_speed := 420.0
var spin_time := 0.5
var _dart_damage := BalanceConfig.WEAPON_BASE["dart_damage"]  # 旋转阶段伤害 (当前值, 含升级比例); 飞行 = x0.625 派生
var _explosion_damage := BalanceConfig.WEAPON_BASE["dart_explosion_damage"]  # 爆炸伤害 (当前值, 含升级比例)
var _explosion_radius_multiplier := 1.0  # 爆炸半径卡倍率 (叠加在动态底数上)
var _dart_scale := 1.0
var _universal_damage_multiplier := 1.0

var isRunning := false: set = _update_running_state
var _phase := Phase.FLY
var _phase_elapsed := 0.0
var _spin_tick := 0.0
var _hit_enemy_ids: Dictionary = {}

func set_attribute(attr_set: AttributeSet) -> void:
	self.attribute_set = attr_set
	var move_speed_attr := attr_set.find_attr(AttributeEnum.instance.MOVE_SPEED)
	move_speed_attr.register_value_changed(_on_move_speed_change)
	move_speed = move_speed_attr.get_current_value()
	var spin_time_attr := attr_set.find_attr(AttributeEnum.instance.DART_SPIN_TIME)
	spin_time_attr.register_value_changed(_on_spin_time_change)
	spin_time = spin_time_attr.get_current_value()
	var damage_attr := attr_set.find_attr(AttributeEnum.instance.DART_DAMAGE)
	damage_attr.register_value_changed(_on_damage_change)
	_dart_damage = damage_attr.get_current_value()
	var explosion_damage_attr := attr_set.find_attr(AttributeEnum.instance.DART_EXPLOSION_DAMAGE)
	explosion_damage_attr.register_value_changed(_on_explosion_damage_change)
	_explosion_damage = explosion_damage_attr.get_current_value()
	var radius_attr := attr_set.find_attr(AttributeEnum.instance.DART_EXPLOSION_RADIUS)
	radius_attr.register_value_changed(_on_explosion_radius_change)
	_explosion_radius_multiplier = radius_attr.get_current_value()
	var scale_attr := attr_set.find_attr(AttributeEnum.instance.DART_SCALE)
	scale_attr.register_value_changed(_on_scale_change)
	_on_scale_change(scale_attr.get_current_value())

func _physics_process(delta: float) -> void:
	if not isRunning:
		return
	_phase_elapsed += delta
	match _phase:
		Phase.FLY:
			# 飞出阶段: 沿发射角度匀速前进, 对沿途敌人造成一次飞镖伤害
			var from_position := global_position
			var to_position := from_position + Vector2.RIGHT.rotated(global_rotation) * move_speed * delta
			_hit_enemies_in_path(from_position, to_position)
			global_position = to_position
			# 动效: 精灵自身旋转 (手里剑飞行时自旋), 根节点角度保持飞行方向
			sprite.rotation += FLY_SPIN_SPEED * delta
			queue_redraw()
			if _phase_elapsed >= FLY_TIME:
				_start_spin()
		Phase.SPIN:
			# 旋转阶段: 原地旋转, 周期性对接触敌人造成伤害
			sprite.rotation += SPIN_ROTATE_SPEED * delta
			_spin_tick += delta
			while _spin_tick >= SPIN_TICK_INTERVAL:
				_spin_tick -= SPIN_TICK_INTERVAL
				_deal_spin_damage()
			queue_redraw()
			if _phase_elapsed >= spin_time:
				_explode_and_complete()

func _start_spin() -> void:
	_phase = Phase.SPIN
	_phase_elapsed = 0.0
	_spin_tick = 0.0

## 动效绘制: 飞行尾迹 (FLY) / 旋转切割残影 (SPIN)
func _draw() -> void:
	if not isRunning:
		return
	match _phase:
		Phase.FLY:
			_draw_flight_trail()
		Phase.SPIN:
			_draw_spin_slashing()

func _draw_flight_trail() -> void:
	# 本地坐标: +X 为飞行方向, 尾迹画在后方 (卡通速度线)
	var trail_length := 26.0
	draw_line(Vector2.ZERO, Vector2(-trail_length, 0.0), Color(0.55, 0.82, 1.0, 0.30), 3.0)
	draw_line(Vector2(0.0, -4.0), Vector2(-trail_length * 0.7, -4.0), Color(0.75, 0.9, 1.0, 0.22), 2.0)
	draw_line(Vector2(0.0, 4.0), Vector2(-trail_length * 0.7, 4.0), Color(0.75, 0.9, 1.0, 0.22), 2.0)

func _draw_spin_slashing() -> void:
	# 旋转残影: 沿 sprite 旋转角度画 3 段圆弧, 体现旋转切割
	var arc_span := deg_to_rad(95.0)
	var radius := 20.0
	for index in range(3):
		var base_angle := sprite.rotation + TAU * float(index) / 3.0
		var alpha := 0.35 - float(index) * 0.06
		draw_arc(Vector2.ZERO, radius, base_angle, base_angle + arc_span, 10, Color(0.6, 0.9, 1.0, alpha), 3.0, true)

func _deal_spin_damage() -> void:
	var damage := _dart_damage * _universal_damage_multiplier
	for raw_area in get_overlapping_areas():
		var enemy := raw_area as Enemy
		if enemy != null and is_instance_valid(enemy):
			enemy.apply_damage(-damage)

func _explode_and_complete() -> void:
	# 爆炸: 对动态爆炸半径内敌人造成爆炸伤害 (一次性)
	var damage := _explosion_damage * _universal_damage_multiplier
	var radius := _current_explosion_radius()
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		# 与落雷一致的判伤口径: 圆 vs 敌人碰撞体 AABB 相交 (考虑 scale), 而非只看中心点
		if _explosion_hits_enemy(enemy, radius):
			enemy.apply_damage(-damage)
	# 爆炸动效
	_spawn_explosion_burst()
	# 结束本轮回旋, 触发 _complete() 隐藏复用
	isRunning = false

## 当前爆炸半径: 1.2 x 碰撞体实际尺寸 (24 x 体积缩放) x 爆炸半径卡倍率
func _current_explosion_radius() -> float:
	return DART_COLLISION_SIZE * EXPLOSION_RADIUS_RATIO * _dart_scale * _explosion_radius_multiplier

## 圆 vs 敌人碰撞体 AABB 相交 (与 lightning_strike 口径一致, 避免渲染在范围内却不受伤)
func _explosion_hits_enemy(enemy: Enemy, radius: float) -> bool:
	var shape_node := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return global_position.distance_squared_to(enemy.global_position) <= radius * radius
	var rect := shape_node.shape as RectangleShape2D
	if rect != null:
		var extents := rect.size * 0.5
		var center := shape_node.global_position
		var half_w := extents.x * absf(enemy.scale.x)
		var half_h := extents.y * absf(enemy.scale.y)
		var closest_x := clampf(global_position.x, center.x - half_w, center.x + half_w)
		var closest_y := clampf(global_position.y, center.y - half_h, center.y + half_h)
		var dx := global_position.x - closest_x
		var dy := global_position.y - closest_y
		return dx * dx + dy * dy <= radius * radius
	return global_position.distance_squared_to(enemy.global_position) <= radius * radius

func _spawn_explosion_burst() -> void:
	var burst := preload("res://scenes/Weapon/dart/dart_burst.gd").new() as Node2D
	if burst == null:
		return
	burst.global_position = global_position
	get_tree().current_scene.add_child(burst)

func fire():
	# 复用飞镖: 重置为飞出阶段, 重新显示并启用检测。
	# 注意: 发射角度由 dart_weapon._fire() 在调用 fire() 前通过 global_rotation 设置,
	# 这里禁止重置 rotation, 否则所有飞镖会以同一角度(默认朝右)发射并重叠成一枚。
	_hit_enemy_ids.clear()
	visible = true
	set_deferred("monitoring", true)
	_phase = Phase.FLY
	_phase_elapsed = 0.0
	_spin_tick = 0.0
	isRunning = true

## 飞行阶段判伤: 沿上一帧到本帧的位移做射线检测, 命中沿途敌人 (每个敌人每轮飞行命中一次)
func _hit_enemies_in_path(from_position: Vector2, to_position: Vector2) -> void:
	if from_position.is_equal_approx(to_position):
		return
	var direction := from_position.direction_to(to_position)
	var query := PhysicsRayQueryParameters2D.create(from_position, to_position, collision_mask)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var excluded: Array[RID] = [get_rid()]
	var current_position := from_position
	var hit_count := 0
	while hit_count < 16:
		query.from = current_position
		query.exclude = excluded
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return
		var enemy := hit.get("collider") as Enemy
		if enemy == null:
			return
		_try_hit_enemy(enemy)
		excluded.append(enemy.get_rid())
		var hit_position: Vector2 = hit["position"]
		current_position = hit_position + direction * 0.1
		if current_position.distance_squared_to(to_position) <= 0.01:
			return
		hit_count += 1

func _try_hit_enemy(enemy: Enemy) -> void:
	if not isRunning or not is_instance_valid(enemy):
		return
	var enemy_id := enemy.get_instance_id()
	if _hit_enemy_ids.has(enemy_id):
		return
	_hit_enemy_ids[enemy_id] = true
	# 飞行伤害 = 旋转伤害 x 0.625 (0.5 / 0.8), 与旋转伤害共用 dart_damage 成长
	enemy.apply_damage(-(_dart_damage * FLY_DAMAGE_RATIO * _universal_damage_multiplier))
	AudioManager.play_dart_hit(-10.0)

func _update_running_state(val):
	if val == false && self.isRunning == true:
		_complete()
	isRunning = val
	pass

func _complete():
	# 飞镖完成一轮后不释放节点: 隐藏并停用, 等待下次发射复用。
	# (原先在此 queue_free 会导致 dart_weapon.darts 数组持有已释放引用,
	#  再次发射 / 应用通用强化时报 "null instance" 错误, 飞镖武器直接失效)
	visible = false
	set_deferred("monitoring", false)

func set_universal_damage_multiplier(value: float) -> void:
	_universal_damage_multiplier = maxf(value, 0.0)

func _on_move_speed_change(value: float) -> void:
	move_speed = maxf(value, 0.0)

func _on_spin_time_change(value: float) -> void:
	spin_time = maxf(value, 0.05)

func _on_damage_change(value: float) -> void:
	_dart_damage = maxf(value, 0.0)

func _on_explosion_damage_change(value: float) -> void:
	_explosion_damage = maxf(value, 0.0)

func _on_explosion_radius_change(value: float) -> void:
	_explosion_radius_multiplier = maxf(value, 0.5)

func _on_scale_change(value: float) -> void:
	_dart_scale = maxf(value, 0.1)
	scale = Vector2.ONE * _dart_scale
