class_name ArcWeapon extends Weapon

const ARC_SEGMENTS := 40

var _arc_radius := 210.0
var _arc_damage_interval := 0.5
var _arc_damage := BalanceConfig.WEAPON_BASE["arc_damage"]
var _arc_thickness := 26.0
var _universal_damage_multiplier := 1.0
var _universal_attack_rate_multiplier := 1.0

@onready var arc_area: Area2D = $ArcArea

var _damage_timer: Timer
var _collision_segments: Array[CollisionPolygon2D] = []
var _last_damage_times: Dictionary = {}
var _last_sfx_time := 0.0
const ARC_SFX_INTERVAL := 0.25

func _ready() -> void:
	if attr_set == null:
		attr_set = AttributeSet.new()
	attr_set.attrs = {}
	_add_attribute(AttributeEnum.instance.ARC_RADIUS, _arc_radius, _on_arc_radius_changed)
	_add_attribute(AttributeEnum.instance.ARC_DAMAGE_INTERVAL, _arc_damage_interval, _on_arc_damage_interval_changed)
	_add_attribute(AttributeEnum.instance.ARC_DAMAGE, _arc_damage * CurrencyManager.get_damage_multiplier(), _on_arc_damage_changed)
	_add_attribute(AttributeEnum.instance.ARC_THICKNESS, _arc_thickness, _on_arc_thickness_changed)
	_damage_timer = Timer.new()
	add_child(_damage_timer)
	_damage_timer.timeout.connect(_deal_arc_damage)
	_update_damage_timer()
	_damage_timer.start()
	arc_area.area_entered.connect(_on_arc_area_entered)
	_update_arc_geometry()

func _add_attribute(attribute_key: String, value: float, callback: Callable) -> void:
	var attribute := Attribute.new(0)
	attribute.add_base_value(value)
	attribute.register_value_changed(callback)
	attr_set.attrs[attribute_key] = attribute

func _deal_arc_damage() -> void:
	var current_enemies: Dictionary = {}
	for raw_area in arc_area.get_overlapping_areas():
		var enemy := raw_area as Enemy
		if enemy != null:
			current_enemies[enemy.get_instance_id()] = true
			_try_deal_arc_damage(enemy)
	# 清理已不在电弧范围内的敌人记录, 防止 _last_damage_times 整局无限增长
	for enemy_id in _last_damage_times.keys():
		if not current_enemies.has(enemy_id):
			_last_damage_times.erase(enemy_id)

func _on_arc_area_entered(area: Area2D) -> void:
	var enemy := area as Enemy
	if enemy != null:
		_try_deal_arc_damage(enemy)

func _try_deal_arc_damage(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	var enemy_id := enemy.get_instance_id()
	var current_time := Time.get_ticks_msec() * 0.001
	var last_damage_time := float(_last_damage_times.get(enemy_id, -INF))
	if current_time - last_damage_time < _arc_damage_interval:
		return
	_last_damage_times[enemy_id] = current_time
	enemy.apply_damage(-_arc_damage)
	var now := Time.get_ticks_msec() * 0.001
	if now - _last_sfx_time >= ARC_SFX_INTERVAL:
		_last_sfx_time = now
		AudioManager.play_arc(-8.0)

func _on_arc_radius_changed(value: float) -> void:
	_arc_radius = maxf(value, 40.0)
	_update_arc_geometry()

func _on_arc_damage_interval_changed(value: float) -> void:
	_arc_damage_interval = maxf(value, 0.12)
	_update_damage_timer()

func _on_arc_damage_changed(value: float) -> void:
	_arc_damage = maxf(value, 0.0) * _universal_damage_multiplier

func set_universal_modifiers(damage_multiplier: float, attack_rate_multiplier: float) -> void:
	_universal_damage_multiplier = maxf(damage_multiplier, 0.0)
	_universal_attack_rate_multiplier = maxf(attack_rate_multiplier, 0.1)
	var damage_attribute := attr_set.find_attr(AttributeEnum.instance.ARC_DAMAGE)
	if damage_attribute != null:
		_on_arc_damage_changed(damage_attribute.get_current_value())
	_update_damage_timer()

func _update_damage_timer() -> void:
	if is_instance_valid(_damage_timer):
		_damage_timer.wait_time = _arc_damage_interval / _universal_attack_rate_multiplier

func _on_arc_thickness_changed(value: float) -> void:
	_arc_thickness = clampf(value, 6.0, _arc_radius * 1.5)
	_update_arc_geometry()

func _update_arc_geometry() -> void:
	var outer_radius := _arc_radius + _arc_thickness * 0.5
	var inner_radius := maxf(_arc_radius - _arc_thickness * 0.5, 0.0)
	while _collision_segments.size() < ARC_SEGMENTS:
		var collision_segment := CollisionPolygon2D.new()
		arc_area.add_child(collision_segment)
		_collision_segments.append(collision_segment)
	for index in range(ARC_SEGMENTS):
		var start_angle := TAU * float(index) / ARC_SEGMENTS
		var end_angle := TAU * float(index + 1) / ARC_SEGMENTS
		_collision_segments[index].polygon = PackedVector2Array([
			Vector2.from_angle(start_angle) * inner_radius,
			Vector2.from_angle(start_angle) * outer_radius,
			Vector2.from_angle(end_angle) * outer_radius,
			Vector2.from_angle(end_angle) * inner_radius,
		])
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, _arc_radius, 0.0, TAU, ARC_SEGMENTS, Color(0.34, 0.78, 1.0, 0.85), _arc_thickness, true)
