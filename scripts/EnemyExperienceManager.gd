## 敌人掉落的经验管理类
class_name EnemyExperienceManager extends Node

var _free_beans: Array[ExperienceBean]

func load_bean() -> ExperienceBean:
	var bean_class = preload("res://scenes/Experience/ExperienceBean/ExperienceBean.tscn")
	var bean_obj = bean_class.instantiate()
	return bean_obj

func get_bean() -> ExperienceBean:
	var bean_result: ExperienceBean
	if _free_beans.size() > 0:
		bean_result = _free_beans.pop_front() as ExperienceBean
		bean_result.process_mode = Node.ProcessMode.PROCESS_MODE_INHERIT
	else:
		bean_result = load_bean()
	
	bean_result.set_attribute()
	return bean_result
	
func recycle_bean(_bean: ExperienceBean) -> void:
	if is_instance_valid(_bean.get_parent()):
		_bean.get_parent().remove_child(_bean)
	_bean.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
	_bean.visible = false
	_free_beans.push_back(_bean)
