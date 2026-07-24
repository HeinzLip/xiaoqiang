class_name DartWeapon extends Weapon

var dart_number := 3
var dart_fire_delay := 1.25
var fire_timer: Timer
var darts: Array[Dart] = []
var _universal_damage_multiplier := 1.0
var _universal_attack_rate_multiplier := 1.0
var _universal_count_bonus := 0

func _ready() -> void:
	if attr_set == null:
		attr_set = AttributeSet.new()
	attr_set.attrs = {}
	_add_attribute(AttributeEnum.instance.DART_FIRE_DELAY, dart_fire_delay, _dart_fire_delay_change)
	_add_attribute(AttributeEnum.instance.DART_NUMBER, dart_number, _dart_number_change)
	_add_attribute(AttributeEnum.instance.MAX_FLY_DISTANCE, 240.0, func(_value: float): pass)
	_add_attribute(AttributeEnum.instance.MOVE_SPEED, 420.0, func(_value: float): pass)
	_update_dart_count()
	fire_timer = Timer.new()
	add_child(fire_timer)
	fire_timer.timeout.connect(_fire)
	_update_fire_timer()
	fire_timer.start()

func _add_attribute(key: String, value: float, callback: Callable) -> void:
	var attribute := Attribute.new(0)
	attribute.add_base_value(value)
	attribute.register_value_changed(callback)
	attr_set.attrs[key] = attribute

func _fire() -> void:
	var step := TAU / float(maxi(darts.size(), 1))
	for index in range(darts.size()):
		var dart := darts[index]
		dart.position = Vector2.ZERO
		dart.rotation = Vector2.UP.rotated(step * index).angle()
		dart.fire()

func _dart_fire_delay_change(value: float) -> void:
	dart_fire_delay = maxf(value, 0.2)
	_update_fire_timer()

func _dart_number_change(value: float) -> void:
	dart_number = maxi(roundi(value), 1)
	_update_dart_count()

func set_universal_modifiers(damage_multiplier: float, attack_rate_multiplier: float, count_bonus: int) -> void:
	_universal_damage_multiplier = maxf(damage_multiplier, 0.0)
	_universal_attack_rate_multiplier = maxf(attack_rate_multiplier, 0.1)
	_universal_count_bonus = maxi(count_bonus, 0)
	_update_fire_timer()
	_update_dart_count()
	for dart in darts:
		dart.set_universal_damage_multiplier(_universal_damage_multiplier)

func _update_fire_timer() -> void:
	if is_instance_valid(fire_timer):
		fire_timer.wait_time = dart_fire_delay / _universal_attack_rate_multiplier

func _update_dart_count() -> void:
	_update_bullet_obj(maxi(dart_number + _universal_count_bonus, 1) - darts.size())

func _update_bullet_obj(add_count: int) -> void:
	if add_count <= 0:
		return
	var dart_scene := preload("res://scenes/Bullet/Dart/Dart.tscn")
	for index in range(add_count):
		var dart := dart_scene.instantiate() as Dart
		dart.set_attribute(attr_set)
		dart.set_universal_damage_multiplier(_universal_damage_multiplier)
		add_child(dart)
		darts.append(dart)
