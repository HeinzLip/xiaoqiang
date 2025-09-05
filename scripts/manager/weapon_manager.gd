extends Node

var _weapon_list: Array[String]
var _weapon_map: Dictionary[String, Resource]


func _init() -> void:
	_weapon_list = []
	_weapon_map = {
		WeaponType.Dart_Weapon: preload("res://scenes/Weapon/dart/DartWeapon.tscn"),
		WeaponType.Missile_Weapon: preload("res://scenes/Weapon/missile/MissileBullet.tscn"),
	}
	pass

func _ready() -> void:
	add_weapon(WeaponType.Missile_Weapon)

func get_weapon_list() -> Array[String]:
	return _weapon_list

func add_weapon(_weapon: String) -> void:
	_weapon_list.append(_weapon)
	var get_weapon_class: Resource = _weapon_map.get(_weapon)
	var weapon_obj = get_weapon_class.instantiate()
	Global.weapont_system.add_weapon(_weapon, weapon_obj)
	pass
