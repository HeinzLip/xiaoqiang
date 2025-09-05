extends Node2D

var skill_data: Dictionary


func _ready() -> void:
	pass

func get_skill_gain_poll() -> Array[SkillPoint]:
	var skill_gain_poll = FileManager.skill_map.duplicate();
	var result = []
	for type in WeaponManager.get_weapon_list():
		skill_gain_poll.erase(type)
		result.append(skill_gain_poll[type])
	return result


func get_random_skills() -> Array[SkillPoint]:
	var skill_gain_poll = get_skill_gain_poll()
	prints("skill_gain_poll ->", skill_gain_poll)
	var temp_skills = skill_gain_poll.duplicate()
	temp_skills.shuffle()
	var result: Array[SkillPoint]
	for i in range(min(3, temp_skills.size())):
		# 4. 逐个元素进行类型转换
		result.append(temp_skills[i] as SkillPoint)
	return result
