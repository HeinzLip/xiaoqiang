extends Node2D



var skill_pool = [
	"dart_weapon"
]

var skill_gain_poll = [
	SkillPoint.new("攻击速度","提升攻击速度",SkillEffect.new("dart_weapon", "dart_fire_delay", SkillEffect.GainType.BASE_RATIO, -0.1)),
	SkillPoint.new("数量","提升子弹的数量",SkillEffect.new("dart_weapon", "dart_number", SkillEffect.GainType.CURRENT_VALUE, 2)),
	SkillPoint.new("子弹移动速度","提升子弹飞行速度",SkillEffect.new("dart_weapon", "move_speed", SkillEffect.GainType.BASE_RATIO, 0.2)),
	SkillPoint.new("子弹飞行距离","提升子弹飞行距离",SkillEffect.new("dart_weapon", "max_fly_distance", SkillEffect.GainType.BASE_RATIO, 0.1)),
]

func get_random_skills() -> Array[SkillPoint]:
	var temp_skills = skill_gain_poll.duplicate()
	temp_skills.shuffle()
	var result: Array[SkillPoint]
	for i in range(min(3, temp_skills.size())):
		# 4. 逐个元素进行类型转换
		result.append(temp_skills[i] as SkillPoint)
	return result
