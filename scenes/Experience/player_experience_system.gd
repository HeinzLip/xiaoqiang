extends Node2D

var current_experience_value:int = 0

var current_level: int = 1

var current_level_max_experience: int= 100

func add_player_experience(_experience: float) -> void:
	current_experience_value += _experience;
	
	prints("add_player_experience ->", current_experience_value)
	if current_experience_value >= current_level_max_experience:
		current_experience_value -= current_level_max_experience
		var diff_level = current_experience_value / current_level_max_experience
		current_experience_value = current_experience_value % current_level_max_experience
		current_level += diff_level
		prints("技能升级")
		get_tree().paused = true
		Global.show_skill_ui()
		## TODO 增加技能
		## TODO 升级技能
	pass
