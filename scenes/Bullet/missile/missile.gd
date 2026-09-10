class_name Missile extends Area2D

var _bullet_move_speed := 900.0
var _bullet_penetrate_max_number := 0
var _bullet_penetrate_number := 0
var _bullet_reflex_number := 0
var _bullet_reflex_remaining := 0
var _bullet_damage := BalanceConfig.WEAPON_BASE["missile_damage"]
var _bullet_scale := 1.0
var _bullet_life_time := 1.5
var _damage_multiplier := 1.0
var _attribute_set: AttributeSet
var _bullet_is_live := false
var _attributes_bound := false
var _hit_enemy_ids: Dictionary = {}

var missile_pool: GamePool
var _bullet_life_timer := Timer.new()

func _ready() -> void:
	area_entered.connect(_on_bullet_enter)
	_bullet_life_timer.one_shot = true
	add_child(_bullet_life_timer)
	_bullet_life_timer.timeout.connect(_on_bullet_life_timer_timeout)

func _bind_attributes() -> void:
	var bullet_scale := _attribute_set.find_attr(AttributeEnum.instance.BULLET_SCALE)
	var bullet_damage := _attribute_set.find_attr(AttributeEnum.instance.BULLET_DAMAGE)
	var bullet_life_time := _attribute_set.find_attr(AttributeEnum.instance.BULLET_LIFE_TIME)
	var bullet_move_speed := _attribute_set.find_attr(AttributeEnum.instance.BULLET_MOVE_SPEED)
	var penetrate := _attribute_set.find_attr(AttributeEnum.instance.BULLET_PENETRATE_MAX_NUMBER)
	var reflex := _attribute_set.find_attr(AttributeEnum.instance.BULLET_REFLEX_NUMBER)
	if bullet_scale == null or bullet_damage == null or bullet_life_time == null or bullet_move_speed == null or penetrate == null or reflex == null:
		return
	_bullet_scale = bullet_scale.get_current_value()
	_bullet_damage = bullet_damage.get_current_value()
	_bullet_life_time = bullet_life_time.get_current_value()
	_bullet_move_speed = bullet_move_speed.get_current_value()
	_bullet_penetrate_max_number = roundi(penetrate.get_current_value())
	_bullet_reflex_number = maxi(roundi(reflex.get_current_value()), 0)
	bullet_scale.register_value_changed(_on_bullet_scale)
	bullet_damage.register_value_changed(_on_bullet_damage)
	bullet_life_time.register_value_changed(_on_bullet_life_time)
	bullet_move_speed.register_value_changed(_on_bullet_move_speed)
	penetrate.register_value_changed(_on_bullet_penetrate_max_number)
	reflex.register_value_changed(_on_bullet_reflex_number)
	_attributes_bound = true
	_on_bullet_scale(_bullet_scale)

func _physics_process(delta: float) -> void:
	if not _bullet_is_live:
		return
	var from_position := global_position
	var to_position := from_position + Vector2.RIGHT.rotated(global_rotation) * _bullet_move_speed * delta
	if _reflect_out_of_bounds(to_position):
		# 反弹/销毁的当前帧停留在原地, 下一帧沿新方向继续
		to_position = global_position
	_hit_enemies_in_path(from_position, to_position)
	if _bullet_is_live:
		global_position = to_position

func _on_bullet_enter(area: Area2D) -> void:
	_try_hit_enemy(area as Enemy)

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
	while _bullet_is_live and hit_count < 16:
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
	if not _bullet_is_live or not is_instance_valid(enemy):
		return
	var enemy_id := enemy.get_instance_id()
	if _hit_enemy_ids.has(enemy_id):
		return
	_hit_enemy_ids[enemy_id] = true
	enemy.apply_damage(-_bullet_damage)
	AudioManager.play_missile_hit(-10.0)
	_bullet_penetrate_number -= 1
	if _bullet_penetrate_number < 0:
		_queue_recycle()

func _on_bullet_life_timer_timeout() -> void:
	_queue_recycle()

func _on_bullet_scale(value: float) -> void:
	_bullet_scale = value
	scale = Vector2.ONE * _bullet_scale

func _on_bullet_damage(value: float) -> void:
	_bullet_damage = value * _damage_multiplier

func set_damage_multiplier(value: float) -> void:
	_damage_multiplier = maxf(value, 0.0)
	if _attribute_set == null:
		return
	var bullet_damage := _attribute_set.find_attr(AttributeEnum.instance.BULLET_DAMAGE)
	if bullet_damage != null:
		_on_bullet_damage(bullet_damage.get_current_value())

func _on_bullet_life_time(value: float) -> void:
	_bullet_life_time = maxf(value, 0.1)

func _on_bullet_move_speed(value: float) -> void:
	_bullet_move_speed = value

func _on_bullet_penetrate_max_number(value: float) -> void:
	_bullet_penetrate_max_number = roundi(value)

## 可视区反弹: 下一帧位置超出"相机可视矩形"时反射方向并消耗一次反弹次数。
## 反弹发生在屏幕边缘 (玩家可见); 无反弹次数时子弹离开屏幕即回收, 避免飞出后空转。
func _reflect_out_of_bounds(next_position: Vector2) -> bool:
	var rect := _get_visible_world_rect()
	var bounced := false
	if next_position.x < rect.position.x or next_position.x > rect.end.x:
		global_rotation = PI - global_rotation
		bounced = true
	if next_position.y < rect.position.y or next_position.y > rect.end.y:
		global_rotation = -global_rotation
		bounced = true
	if bounced:
		if _bullet_reflex_remaining <= 0:
			_queue_recycle()
		else:
			_bullet_reflex_remaining -= 1
	return bounced

## 相机可视矩形 (世界坐标): 相机中心 ± 视口半尺寸; 无相机时退回世界活动边界
func _get_visible_world_rect() -> Rect2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return Rect2(
			Vector2(-Global.global_data.move_max_width, -Global.global_data.move_max_height),
			Vector2(Global.global_data.move_max_width * 2.0, Global.global_data.move_max_height * 2.0)
		)
	var half := Global.camera_size * 0.5
	return Rect2(camera.global_position - half, Global.camera_size)

func _on_bullet_reflex_number(value: float) -> void:
	_bullet_reflex_number = maxi(roundi(value), 0)

func init(attributes: AttributeSet, pool: GamePool, damage_multiplier: float = 1.0) -> void:
	_attribute_set = attributes
	missile_pool = pool
	set_damage_multiplier(damage_multiplier)
	if not _attributes_bound:
		_bind_attributes()
	_bullet_is_live = true
	monitoring = true
	_bullet_penetrate_number = _bullet_penetrate_max_number
	_bullet_reflex_remaining = _bullet_reflex_number
	_hit_enemy_ids.clear()
	_bullet_life_timer.start(_bullet_life_time)

func _queue_recycle() -> void:
	if not _bullet_is_live:
		return
	_bullet_is_live = false
	_bullet_life_timer.stop()
	# This can be reached from Area2D.area_entered. Reparenting a collision
	# object while physics queries are being flushed is forbidden by Godot.
	set_deferred("monitoring", false)
	call_deferred("_return_to_pool")

func _return_to_pool() -> void:
	if missile_pool != null:
		missile_pool.recycle_object(self)
