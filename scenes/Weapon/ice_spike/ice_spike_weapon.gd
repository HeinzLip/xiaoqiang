class_name IceSpikeWeapon extends Weapon

const ICE_SPIKE_SCENE := preload("res://scenes/Weapon/ice_spike/IceSpike.tscn")
const FIRE_INTERVAL := 1.25
const BASE_DISTANCE := 210.0
const BASE_WIDTH := 40.0
const BASE_DURATION := 1.0
const BASE_DAMAGE_INTERVAL := 0.2
const BASE_DAMAGE := BalanceConfig.WEAPON_BASE["ice_spike_damage"]
const SPREAD_ANGLE := deg_to_rad(18.0)

var _fire_interval := FIRE_INTERVAL
var _distance := BASE_DISTANCE
var _width := BASE_WIDTH
var _duration := BASE_DURATION
var _damage_interval := BASE_DAMAGE_INTERVAL
var _slow_ratio := 0.0
var _spike_count := 1
var _base_damage := BASE_DAMAGE
var _universal_damage_multiplier := 1.0
var _universal_attack_rate_multiplier := 1.0
var _fire_timer: Timer

func _ready() -> void:
	if attr_set == null:
		attr_set = AttributeSet.new()
	attr_set.attrs = {}
	_base_damage = BASE_DAMAGE * CurrencyManager.get_damage_multiplier()
	_add_attribute(AttributeEnum.instance.ICE_SPIKE_DISTANCE, _distance, _on_distance_changed)
	_add_attribute(AttributeEnum.instance.ICE_SPIKE_WIDTH, _width, _on_width_changed)
	_add_attribute(AttributeEnum.instance.ICE_SPIKE_DURATION, _duration, _on_duration_changed)
	_add_attribute(AttributeEnum.instance.ICE_SPIKE_DAMAGE_INTERVAL, _damage_interval, _on_damage_interval_changed)
	_add_attribute(AttributeEnum.instance.ICE_SPIKE_SLOW, _slow_ratio, _on_slow_changed)
	_add_attribute(AttributeEnum.instance.ICE_SPIKE_COUNT, _spike_count, _on_count_changed)
	_fire_timer = Timer.new()
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_fire_ice_spikes)
	_update_fire_timer()
	_fire_timer.start()

func _add_attribute(attribute_key: String, value: float, callback: Callable) -> void:
	var attribute := Attribute.new(0)
	attribute.add_base_value(value)
	attribute.register_value_changed(callback)
	attr_set.attrs[attribute_key] = attribute

func _fire_ice_spikes() -> void:
	if not is_instance_valid(Global.player):
		return
	var count := maxi(_spike_count, 1)
	var aim_direction := _get_aim_direction()
	var start_angle := -SPREAD_ANGLE * 0.5
	var angle_step := SPREAD_ANGLE / float(maxi(count - 1, 1))
	for index in range(count):
		var direction := aim_direction.rotated(start_angle + angle_step * float(index)) if count > 1 else aim_direction
		var spike := ICE_SPIKE_SCENE.instantiate() as IceSpike
		if spike == null:
			continue
		spike.configure(
			Global.player.global_position,
			direction,
			_damage_for_hit(),
			_distance,
			_width,
			_duration,
			_damage_interval / _universal_attack_rate_multiplier,
			_slow_ratio
		)
		get_tree().current_scene.add_child(spike)
	AudioManager.play_ice_spike(-7.0)

func _get_aim_direction() -> Vector2:
	var closest_enemy: Node2D
	var closest_distance := INF
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := Global.player.global_position.distance_squared_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	if closest_enemy != null:
		return Global.player.global_position.direction_to(closest_enemy.global_position)
	return Vector2.RIGHT

func set_universal_modifiers(damage_multiplier: float, attack_rate_multiplier: float) -> void:
	_universal_damage_multiplier = maxf(damage_multiplier, 0.0)
	_universal_attack_rate_multiplier = maxf(attack_rate_multiplier, 0.1)
	_update_fire_timer()

func _damage_for_hit() -> float:
	return _base_damage * _universal_damage_multiplier

func _update_fire_timer() -> void:
	if is_instance_valid(_fire_timer):
		_fire_timer.wait_time = _fire_interval / _universal_attack_rate_multiplier

func _on_distance_changed(value: float) -> void:
	_distance = maxf(value, 90.0)

func _on_width_changed(value: float) -> void:
	_width = maxf(value, 32.0)

func _on_duration_changed(value: float) -> void:
	_duration = maxf(value, 0.2)

func _on_damage_interval_changed(value: float) -> void:
	_damage_interval = maxf(value, 0.04)

func _on_slow_changed(value: float) -> void:
	_slow_ratio = clampf(value, 0.0, 0.85)

func _on_count_changed(value: float) -> void:
	_spike_count = maxi(roundi(value), 1)
