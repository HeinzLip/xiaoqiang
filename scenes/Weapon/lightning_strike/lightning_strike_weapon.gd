class_name LightningStrikeWeapon extends Weapon

## 落雷武器: 定时从天上随机落下一道雷, 命中半径内敌人。
## 感电机制: 命中后有概率施加感电(1秒), 感电中的敌人再次被落雷击中伤害+50%。
## 专属强化: 频率+25% / 范围+10% / 感电时间+50% / 感电伤害+10% / 感电概率+2% / 每次多一道雷。

const LIGHTNING_STRIKE_SCENE := preload("res://scenes/Weapon/lightning_strike/LightningStrike.tscn")
const BASE_FIRE_INTERVAL := 1.0
const BASE_DAMAGE := BalanceConfig.WEAPON_BASE["lightning_damage"]
const BASE_RADIUS := 15.0
const BASE_SHOCK_DURATION := 1.0
const BASE_SHOCK_CHANCE := 0.30
const BASE_SHOCK_DAMAGE_BONUS := 0.50
const MAX_DISTANCE := 60.0

var _fire_interval := BASE_FIRE_INTERVAL
var _damage := BASE_DAMAGE
var _radius := BASE_RADIUS
var _shock_duration := BASE_SHOCK_DURATION
var _shock_chance := BASE_SHOCK_CHANCE
var _shock_damage_bonus := BASE_SHOCK_DAMAGE_BONUS
var _strike_count := 1
var _base_damage := BASE_DAMAGE
var _universal_damage_multiplier := 1.0
var _universal_attack_rate_multiplier := 1.0
var _fire_timer: Timer

func _ready() -> void:
	if attr_set == null:
		attr_set = AttributeSet.new()
	attr_set.attrs = {}
	_base_damage = BASE_DAMAGE * CurrencyManager.get_damage_multiplier()
	_add_attribute(AttributeEnum.instance.LIGHTNING_FREQUENCY, _fire_interval, _on_fire_interval_changed)
	_add_attribute(AttributeEnum.instance.LIGHTNING_RADIUS, _radius, _on_radius_changed)
	_add_attribute(AttributeEnum.instance.LIGHTNING_SHOCK_DURATION, _shock_duration, _on_shock_duration_changed)
	_add_attribute(AttributeEnum.instance.LIGHTNING_SHOCK_CHANCE, _shock_chance, _on_shock_chance_changed)
	_add_attribute(AttributeEnum.instance.LIGHTNING_SHOCK_DAMAGE, _shock_damage_bonus, _on_shock_damage_changed)
	_add_attribute(AttributeEnum.instance.LIGHTNING_COUNT, _strike_count, _on_count_changed)
	_fire_timer = Timer.new()
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_fire_lightning)
	_update_fire_timer()
	_fire_timer.start()

func _add_attribute(attribute_key: String, value: float, callback: Callable) -> void:
	var attribute := Attribute.new(0)
	attribute.add_base_value(value)
	attribute.register_value_changed(callback)
	attr_set.attrs[attribute_key] = attribute

func _fire_lightning() -> void:
	if not is_instance_valid(Global.player):
		return
	var count := maxi(_strike_count, 1)
	for index in range(count):
		var strike := LIGHTNING_STRIKE_SCENE.instantiate() as LightningStrike
		if strike == null:
			continue
		# 落点在敌人位置附近随机 (无敌人时随机落在玩家周围)
		var target := _pick_random_enemy_position()
		strike.configure(
			target + _random_offset(),
			_damage_for_hit(),
			_radius,
			_shock_duration,
			_shock_chance,
			_shock_damage_bonus,
			float(index) * 0.12
		)
		get_tree().current_scene.add_child(strike)
	AudioManager.play_lightning(-4.0)

func _pick_random_enemy_position() -> Vector2:
	var enemies := get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group)
	var alive: Array[Node2D] = []
	for raw_enemy in enemies:
		var enemy := raw_enemy as Node2D
		if enemy != null and is_instance_valid(enemy):
			alive.append(enemy)
	if alive.is_empty():
		if is_instance_valid(Global.player):
			return Global.player.global_position
		return Vector2.ZERO
	return alive[randi() % alive.size()].global_position

func _random_offset() -> Vector2:
	return Vector2.from_angle(randf() * TAU) * randf_range(0.0, MAX_DISTANCE)

func _damage_for_hit() -> float:
	return _base_damage * _universal_damage_multiplier

func set_universal_modifiers(damage_multiplier: float, attack_rate_multiplier: float) -> void:
	_universal_damage_multiplier = maxf(damage_multiplier, 0.0)
	_universal_attack_rate_multiplier = maxf(attack_rate_multiplier, 0.1)
	_update_fire_timer()

func _update_fire_timer() -> void:
	if is_instance_valid(_fire_timer):
		_fire_timer.wait_time = _fire_interval / _universal_attack_rate_multiplier

func _on_fire_interval_changed(value: float) -> void:
	_fire_interval = maxf(value, 0.1)
	_update_fire_timer()

func _on_radius_changed(value: float) -> void:
	_radius = maxf(value, 1.0)

func _on_shock_duration_changed(value: float) -> void:
	_shock_duration = maxf(value, 0.0)

func _on_shock_chance_changed(value: float) -> void:
	_shock_chance = clampf(value, 0.0, 1.0)

func _on_shock_damage_changed(value: float) -> void:
	_shock_damage_bonus = maxf(value, 0.0)

func _on_count_changed(value: float) -> void:
	_strike_count = maxi(roundi(value), 1)
