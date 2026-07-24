class_name Dart extends Bullet

var attribute_set: AttributeSet

## 飞镖的速度
var move_speed: float
## 飞镖的飞行距离
var max_fly_distance: float
var fly_direction := 1
var _hit_enemy_ids: Dictionary = {}
var _universal_damage_multiplier := 1.0

var isRunning := false: set = _update_running_state

func set_attribute(attr_set: AttributeSet) -> void:
	self.attribute_set = attr_set
	var move_speed_attr = attr_set.find_attr(AttributeEnum.instance.MOVE_SPEED)
	move_speed_attr.register_value_changed(_move_speed_change)
	move_speed = move_speed_attr.get_current_value()
	#prints("dart bullet move speed ->", move_speed)
	var max_fly_distance_attr = attr_set.find_attr(AttributeEnum.instance.MAX_FLY_DISTANCE)
	max_fly_distance = max_fly_distance_attr.get_current_value()
	max_fly_distance_attr.register_value_changed(_move_max_fly_distance)
	
func _ready() -> void:
	super._ready()
	area_entered.connect(_on_area_entered)
	
func _physics_process(delta: float) -> void:
	if not isRunning:
		return
	var from_position := global_position
	var to_position := from_position + Vector2.RIGHT.rotated(global_rotation) * move_speed * delta * fly_direction
	_hit_enemies_in_path(from_position, to_position)
	global_position = to_position
	
	var fly_distance = position.length()
	#prints("飞镖飞行距离->", fly_distance, fly_direction, move_speed)
	if fly_distance >= max_fly_distance:
		fly_direction = -1
		_hit_enemy_ids.clear()
	elif isRunning && fly_distance <= 1:
		isRunning = false

func fire():
	#prints("发射")
	_hit_enemy_ids.clear()
	isRunning = true
	fly_direction = 1

func _on_area_entered(area: Area2D) -> void:
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
	enemy.apply_damage(bullet_damage())

func _update_running_state(val):
	
	if val == false && self.isRunning == true:
		_complete()
	isRunning = val
	pass

func _move_speed_change(_change_value) ->void:
	#print('_move_speed_change ->', _change_value)
	move_speed = _change_value
	pass

func _move_max_fly_distance(_change_value) -> void:
	max_fly_distance = _change_value
	pass

func _complete():
	pass

func bullet_damage() -> float:
	return -24.0 * CurrencyManager.get_damage_multiplier() * _universal_damage_multiplier

func set_universal_damage_multiplier(value: float) -> void:
	_universal_damage_multiplier = maxf(value, 0.0)
