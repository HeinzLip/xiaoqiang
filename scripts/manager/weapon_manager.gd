extends Node

const MAX_NEW_SKILLS := 5

var _weapon_list: Array[String]
var _weapon_map: Dictionary[String, Resource]


func _init() -> void:
	_weapon_list = []
	_weapon_map = {
		WeaponType.Dart_Weapon: preload("res://scenes/Weapon/dart/DartWeapon.tscn"),
		WeaponType.Missile_Weapon: preload("res://scenes/Weapon/missile/MissileBullet.tscn"),
		WeaponType.Arc_Weapon: preload("res://scenes/Weapon/arc/ArcWeapon.tscn"),
		WeaponType.Sound_Wave_Weapon: preload("res://scenes/Weapon/sound_wave/SoundWaveWeapon.tscn"),
	}
	pass

func _ready() -> void:
	# Wait until the main scene has entered the tree before attaching the
	# starter weapon to its WeaponSystem.
	call_deferred("add_weapon", WeaponType.Missile_Weapon)

func get_weapon_list() -> Array[String]:
	return _weapon_list

func get_new_skill_count() -> int:
	return _weapon_list.size()

func can_learn_new_skill() -> bool:
	return get_new_skill_count() < MAX_NEW_SKILLS

func get_available_weapon_list() -> Array[String]:
	var result: Array[String] = []
	for weapon_type in _weapon_map:
		result.append(weapon_type)
	return result

func get_weapon_display_name(_weapon: String) -> String:
	match _weapon:
		WeaponType.Missile_Weapon: return "追踪导弹"
		WeaponType.Dart_Weapon: return "回旋飞镖"
		WeaponType.Arc_Weapon: return "电弧"
		WeaponType.Sound_Wave_Weapon: return "声波"
		_: return _weapon

func has_weapon(_weapon: String) -> bool:
	return _weapon_list.has(_weapon)

func reset_run() -> void:
	_weapon_list.clear()

func add_weapon(_weapon: String) -> bool:
	if has_weapon(_weapon) or not _weapon_map.has(_weapon) or not can_learn_new_skill():
		return false
	if not is_instance_valid(Global.weapont_system):
		return false
	_weapon_list.append(_weapon)
	var get_weapon_class: Resource = _weapon_map.get(_weapon)
	var weapon_obj := get_weapon_class.instantiate() as Weapon
	Global.weapont_system.add_weapon(_weapon, weapon_obj)
	return true
