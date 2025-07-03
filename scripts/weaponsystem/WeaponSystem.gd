class_name WeaponSystem extends Node2D

var _weapons_: Dictionary[String, Weapon]

func _ready() -> void:
	pass

func add_weapon(_key: String, _weapon: Weapon) -> void:
	self._weapons_.set(_key, _weapon)
	add_child(_weapon)
	
func find_weapon(_key: String) -> Weapon:
	if _weapons_.has(_key):
		return _weapons_.get(_key)
	else:
		push_error("WeaponSystem can`t find key ->", _key)
		return null
		
func update_skill(_skill: SkillEffect) -> void:
	var weapon = _weapons_.get(_skill.weapon_type) as Weapon
	var attr = weapon.attr_set.find_attr(_skill.attribute_type)
	if _skill.gain_type == SkillEffect.GainType.BASE_RATIO:
		attr.add_base_ratio(_skill.gain_value)
	else:
		attr.add_current_value(_skill.gain_value)
	pass
	
func _process(delta: float) -> void:
	var game_main = get_tree().current_scene as GameMain
	global_position  = (game_main.player as CharacterBody2D).global_position
