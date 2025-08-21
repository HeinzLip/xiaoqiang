## 敌人掉落的经验管理类
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
		bean_result.process_mode = Node.ProcessMode.PROCESS_MODE_INHERIT
	else:
		bean_result = load_bean()
	
	bean_result.set_attribute()
	return bean_result
	
func recycle_bean(_bean: ExperienceBean) -> void:
	_bean.get_parent().remove_child(_bean)
	##回收后要将节点的process事件屏蔽掉
	_bean.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
	_free_beans.push_back(_bean)
