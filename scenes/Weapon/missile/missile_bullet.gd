extends Weapon

var _bullet_fire_delay := 1.0
var _bullet_fire_number := 3
var _bullet_fire_angle := 24.0
var _bullet_damage := BalanceConfig.WEAPON_BASE["missile_damage"]
var _bullet_move_speed := 900.0
var _bullet_life_time := 1.5
var _bullet_scale := 1.0
var _bullet_penetrate_max_number := 0
var _bullet_reflex_number := 0
var _universal_damage_multiplier := 1.0
var _universal_attack_rate_multiplier := 1.0

@onready var game_pool: GamePool = $MissileBulletPool
var _fire_timer: Timer

func _ready() -> void:
	attr_set = AttributeSet.new()
	attr_set.attrs = {}
	_init_attr()
	game_pool.init(preload("res://scenes/Bullet/missile/Missile.tscn"), _bullet_fire_number)
	_create_timer()

func _add_attribute(key: String, value: float, callback: Callable) -> void:
	var attribute := Attribute.new(0)
	attribute.add_base_value(value)
	attribute.register_value_changed(callback)
	attr_set.attrs[key] = attribute

func _init_attr() -> void:
	_add_attribute(AttributeEnum.instance.BULLER_FIRE_ANGLE, _bullet_fire_angle, _on_bullet_fire_angle)
	_add_attribute(AttributeEnum.instance.BULLET_FIRE_DELAY, _bullet_fire_delay, _on_bullet_fire_delay)
	_add_attribute(AttributeEnum.instance.BULLET_FIRE_NUMBER, _bullet_fire_number, _on_bullet_fire_number)
	_add_attribute(AttributeEnum.instance.BULLET_DAMAGE, _bullet_damage * CurrencyManager.get_damage_multiplier(), _on_bullet_damage)
	_add_attribute(AttributeEnum.instance.BULLET_MOVE_SPEED, _bullet_move_speed, _on_bullet_move_speed)
	_add_attribute(AttributeEnum.instance.BULLET_LIFE_TIME, _bullet_life_time, _on_bullet_life_time)
	_add_attribute(AttributeEnum.instance.BULLET_SCALE, _bullet_scale, _on_bullet_scale)
	_add_attribute(AttributeEnum.instance.BULLET_PENETRATE_MAX_NUMBER, _bullet_penetrate_max_number, _on_bullet_penetrate_max_number)
	_add_attribute(AttributeEnum.instance.BULLET_REFLEX_NUMBER, _bullet_reflex_number, _on_bullet_reflex_number)

func _create_timer() -> void:
	_fire_timer = Timer.new()
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_fire_missile_bullet)
	_update_fire_timer()
	_fire_timer.start()

func _fire_missile_bullet() -> void:
	if not is_instance_valid(Global.player):
		return
	var count := maxi(_bullet_fire_number, 1)
	var angle_step := _bullet_fire_angle / float(maxi(count - 1, 1))
	var start_angle := -_bullet_fire_angle * 0.5
	var aim_angle := _get_aim_direction().angle()
	for index in range(count):
		var bullet := game_pool.get_pool_object() as Missile
		# 子弹挂到场景根, 使其世界坐标独立, 不随 WeaponSystem/玩家移动
		var bullet_parent := get_tree().current_scene
		if bullet.get_parent() != bullet_parent:
			bullet.reparent(bullet_parent)
		bullet.global_position = Global.player.global_position
		bullet.global_rotation = aim_angle + (deg_to_rad(start_angle + angle_step * index) if count > 1 else 0.0)
		bullet.init(attr_set, game_pool, _universal_damage_multiplier)
	AudioManager.play_missile_fire(-6.0)

func set_universal_modifiers(damage_multiplier: float, attack_rate_multiplier: float) -> void:
	_universal_damage_multiplier = maxf(damage_multiplier, 0.0)
	_universal_attack_rate_multiplier = maxf(attack_rate_multiplier, 0.1)
	for raw_bullet in game_pool.get_active_objects():
		var bullet := raw_bullet as Missile
		if bullet != null:
			bullet.set_damage_multiplier(_universal_damage_multiplier)
	_update_fire_timer()

func _update_fire_timer() -> void:
	if is_instance_valid(_fire_timer):
		_fire_timer.wait_time = _bullet_fire_delay / _universal_attack_rate_multiplier

func _get_aim_direction() -> Vector2:
	var closest_enemy: Node2D
	var closest_distance := INF
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Node2D
		if enemy == null:
			continue
		var distance := Global.player.global_position.distance_squared_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	if closest_enemy != null:
		return Global.player.global_position.direction_to(closest_enemy.global_position)
	return Vector2.RIGHT

func _on_bullet_fire_angle(value: float) -> void: _bullet_fire_angle = value
func _on_bullet_fire_delay(value: float) -> void:
	_bullet_fire_delay = maxf(value, 0.15)
	_update_fire_timer()
func _on_bullet_fire_number(value: float) -> void: _bullet_fire_number = maxi(roundi(value), 1)
func _on_bullet_damage(value: float) -> void: _bullet_damage = value
func _on_bullet_move_speed(value: float) -> void: _bullet_move_speed = value
func _on_bullet_life_time(value: float) -> void: _bullet_life_time = value
func _on_bullet_scale(value: float) -> void: _bullet_scale = value
func _on_bullet_penetrate_max_number(value: float) -> void: _bullet_penetrate_max_number = roundi(value)
func _on_bullet_reflex_number(value: float) -> void: _bullet_reflex_number = maxi(roundi(value), 0)
