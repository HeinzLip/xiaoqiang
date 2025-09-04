extends Node2D

var skill_data: Dictionary

## 升级技能池
var skill_gain_poll = [
]


func _ready() -> void:
	skill_data = FileManager.get_csv_data("res://skill_list.csv")
	skill_gain_poll = skill_data.values().map(func(x): return SkillPoint.new(x.skill_name_zh, x.description, SkillEffect.new(x.weapon_name, x.attribute_name, int(x.attribute_type), float(x.attribute_value)))) as Array[SkillPoint]

var skill_pool = [
	WeaponType.get_instance().Dart_Weapon,
	WeaponType.get_instance().Missile_Weapon
]


func get_random_skills() -> Array[SkillPoint]:
	prints("skill_gain_poll ->", skill_gain_poll)
	var temp_skills = skill_gain_poll.duplicate()
	temp_skills.shuffle()
	var result: Array[SkillPoint]
	for i in range(min(3, temp_skills.size())):
		# 4. 逐个元素进行类型转换
		result.append(temp_skills[i] as SkillPoint)
	return result
