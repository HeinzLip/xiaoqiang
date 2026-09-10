class_name WeaponSystem extends Node2D

var _weapons_: Dictionary[String, Weapon] = {}
var _universal_damage_multiplier := 1.0
var _universal_attack_rate_multiplier := 1.0

func _ready() -> void:
	pass

func add_weapon(_key: String, _weapon: Weapon) -> void:
	if _weapons_.has(_key):
		_weapon.queue_free()
		return
	self._weapons_.set(_key, _weapon)
	add_child(_weapon)
	_apply_universal_modifiers(_weapon)
	
func find_weapon(_key: String) -> Weapon:
	if _weapons_.has(_key):
		return _weapons_.get(_key)
	else:
		push_error("WeaponSystem can`t find key ->", _key)
		return null

func has_weapon(weapon_type: StringName) -> bool:
	return _weapons_.has(String(weapon_type))

## Used by the skill laboratory to swap one isolated weapon in-place.
## Normal runs still clear weapons when their scene is released.
func clear_weapons() -> void:
	for weapon in _weapons_.values():
		if is_instance_valid(weapon):
			weapon.queue_free()
	_weapons_.clear()
	_universal_damage_multiplier = 1.0
	_universal_attack_rate_multiplier = 1.0

func apply_attribute_upgrade(definition: SkillDefinition) -> bool:
	if definition == null or definition.kind != SkillDefinition.Kind.ATTRIBUTE_UPGRADE:
		return false
	var weapon := _weapons_.get(String(definition.weapon_type)) as Weapon
	if weapon == null or weapon.attr_set == null:
		return false
	var attribute := weapon.attr_set.find_attr(String(definition.attribute_key))
	if attribute == null:
		return false
	match definition.operation:
		SkillDefinition.AttributeOperation.BASE_VALUE:
			attribute.add_base_value(definition.value)
		SkillDefinition.AttributeOperation.CURRENT_VALUE:
			attribute.add_value(definition.value)
		SkillDefinition.AttributeOperation.BASE_SURPLUS_RATIO:
			attribute.add_surplus_value(definition.value)
		SkillDefinition.AttributeOperation.BASE_RATIO:
			attribute.add_ratio(definition.value)
		SkillDefinition.AttributeOperation.CURRENT_RATIO:
			attribute.add_current_ratio(definition.value)
		_:
			return false
	return true

func apply_universal_upgrade(definition: SkillDefinition, level: int) -> bool:
	if definition == null or definition.kind != SkillDefinition.Kind.UNIVERSAL_UPGRADE:
		return false
	match definition.id:
		SkillCatalog.UNIVERSAL_DAMAGE:
			_universal_damage_multiplier = 1.0 + definition.value * level
		SkillCatalog.UNIVERSAL_ATTACK_FREQUENCY:
			_universal_attack_rate_multiplier = 1.0 + definition.value * level
		_:
			return false
	for weapon in _weapons_.values():
		_apply_universal_modifiers(weapon as Weapon)
	return true

func _apply_universal_modifiers(weapon: Weapon) -> void:
	if is_instance_valid(weapon):
		weapon.set_universal_modifiers(
			_universal_damage_multiplier,
			_universal_attack_rate_multiplier
		)

func _process(_delta: float) -> void:
	# 只跟随玩家坐标本身; 各武器在自身 _process 中跟随, 子弹发射后独立
	if is_instance_valid(Global.player):
		global_position = (Global.player as CharacterBody2D).global_position

func _exit_tree() -> void:
	_weapons_.clear()
	_universal_damage_multiplier = 1.0
	_universal_attack_rate_multiplier = 1.0
	#_weapons_.is_empty()
	prints("释放所有weapon",_weapons_.is_empty())
