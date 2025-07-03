class_name EnemyExperienceManager extends Node

var _free_beans: Array[ExperienceBean]

func load_bean() -> ExperienceBean:
	var bean_class = preload("res://scenes/Experience/ExperienceBean/ExperienceBean.tscn")
	var bean_obj = bean_class.instantiate()
	prints("experience_manager -> experience bean is ->", bean_obj.name)
	return bean_obj

func get_bean() -> ExperienceBean:
	var bean_result: ExperienceBean
	prints("experience_manager ->", _free_beans.size())
	if _free_beans.size() > 0:
		bean_result = _free_beans.pop_front() as ExperienceBean
	else:
		bean_result = load_bean()
	
	bean_result.set_attribute()
	return bean_result
	
func recycle_bean(_bean: ExperienceBean) -> void:
	_bean.get_parent().remove_child(_bean)
	_free_beans.push_back(_bean)
