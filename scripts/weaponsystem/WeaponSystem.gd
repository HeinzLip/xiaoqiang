class_name WeaponSystem extends Node2D

const MAX_SKILL_UPGRADE_LEVEL := 6
const UNIVERSAL_DAMAGE := "universal_damage"
const UNIVERSAL_ATTACK_FREQUENCY := "universal_attack_frequency"
const UNIVERSAL_COUNT := "universal_count"

var _weapons_: Dictionary[String, Weapon] = {}
var _skill_upgrade_counts: Dictionary = {}
var _universal_damage_multiplier := 1.0
var _universal_attack_rate_multiplier := 1.0
var _universal_count_bonus := 0

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
		
func update_skill(_skill: SkillEffect) -> bool:
	if _skill == null or not _weapons_.has(_skill.weapon_type):
		return false
	if not can_upgrade_skill(_skill):
		return false
	var weapon = _weapons_.get(_skill.weapon_type) as Weapon
	var attr = weapon.attr_set.find_attr(_skill.attribute_type)
	if attr == null:
		return false
	match _skill.gain_type:
		SkillEffect.GainType.BASE_VALUE:
			attr.add_base_value(_skill.gain_value)
		SkillEffect.GainType.CURRENT_VALUE:
			attr.add_value(_skill.gain_value)
		SkillEffect.GainType.BASE_SURPLUS_RATIO:
			attr.add_surplus_value(_skill.gain_value)
		SkillEffect.GainType.BASE_RATIO:
			attr.add_ratio(_skill.gain_value)
		SkillEffect.GainType.CURRENT_RATIO:
			attr.add_current_ratio(_skill.gain_value)
	var upgrade_key := _get_skill_upgrade_key(_skill)
	_skill_upgrade_counts[upgrade_key] = get_skill_upgrade_count(_skill) + 1
	return true

func get_skill_upgrade_count(skill: SkillEffect) -> int:
	if skill == null:
		return 0
	return int(_skill_upgrade_counts.get(_get_skill_upgrade_key(skill), 0))

func can_upgrade_skill(skill: SkillEffect) -> bool:
	return skill != null and get_skill_upgrade_count(skill) < MAX_SKILL_UPGRADE_LEVEL

func _get_skill_upgrade_key(skill: SkillEffect) -> String:
	# A weapon is one skill: its different upgrade attributes share the same
	# six-level cap. Once the counter reaches the cap, every upgrade card for
	# that weapon is removed from the reward pool.
	return skill.weapon_type

func update_universal_skill(upgrade_key: String) -> bool:
	if not can_upgrade_universal_skill(upgrade_key):
		return false
	match upgrade_key:
		UNIVERSAL_DAMAGE:
			_universal_damage_multiplier += 0.1
		UNIVERSAL_ATTACK_FREQUENCY:
			_universal_attack_rate_multiplier += 0.1
		UNIVERSAL_COUNT:
			_universal_count_bonus += 1
		_:
			return false
	_skill_upgrade_counts[_get_universal_upgrade_key(upgrade_key)] = get_universal_upgrade_count(upgrade_key) + 1
	for weapon in _weapons_.values():
		_apply_universal_modifiers(weapon as Weapon)
	return true

func get_universal_upgrade_count(upgrade_key: String) -> int:
	return int(_skill_upgrade_counts.get(_get_universal_upgrade_key(upgrade_key), 0))

func can_upgrade_universal_skill(upgrade_key: String) -> bool:
	return upgrade_key in [UNIVERSAL_DAMAGE, UNIVERSAL_ATTACK_FREQUENCY, UNIVERSAL_COUNT] and get_universal_upgrade_count(upgrade_key) < MAX_SKILL_UPGRADE_LEVEL

func _get_universal_upgrade_key(upgrade_key: String) -> String:
	return "universal:%s" % upgrade_key

func _apply_universal_modifiers(weapon: Weapon) -> void:
	if is_instance_valid(weapon):
		weapon.set_universal_modifiers(
			_universal_damage_multiplier,
			_universal_attack_rate_multiplier,
			_universal_count_bonus
		)
	
func _process(_delta: float) -> void:
	global_position  = (Global.player as CharacterBody2D).global_position

func _exit_tree() -> void:
	_weapons_.clear()
	_skill_upgrade_counts.clear()
	_universal_damage_multiplier = 1.0
	_universal_attack_rate_multiplier = 1.0
	_universal_count_bonus = 0
	#_weapons_.is_empty()
	prints("释放所有weapon",_weapons_.is_empty())
