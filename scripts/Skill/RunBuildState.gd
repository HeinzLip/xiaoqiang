class_name RunBuildState extends Resource

## Mutable state for one run. It deliberately contains no scene nodes, so it
## can be reset, saved, or tested independently from the gameplay scene.
var _levels: Dictionary = {}
var _unlocked_weapons: Dictionary = {}

func reset() -> void:
	_levels.clear()
	_unlocked_weapons.clear()

func get_level(skill_id: StringName) -> int:
	return int(_levels.get(skill_id, 0))

func set_level(skill_id: StringName, level: int) -> void:
	_levels[skill_id] = maxi(level, 0)

func increase_level(skill_id: StringName) -> int:
	var next_level := get_level(skill_id) + 1
	set_level(skill_id, next_level)
	return next_level

func unlock_weapon(weapon_type: StringName) -> void:
	_unlocked_weapons[weapon_type] = true

func has_weapon(weapon_type: StringName) -> bool:
	return _unlocked_weapons.has(weapon_type)

func get_weapon_count() -> int:
	return _unlocked_weapons.size()

func get_weapon_types() -> Array[String]:
	var result: Array[String] = []
	for weapon_type in _unlocked_weapons:
		result.append(String(weapon_type))
	return result
