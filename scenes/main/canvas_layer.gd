class_name UIPanel extends CanvasLayer

enum UIType {
	NONE,
	SKILL_UI,
	GAME_END_UI,
	LEVEL_COMPLETE_UI
}

var cur_ui_type: UIType
var cur_ui_node: Node

func _show_ui() -> void:
	match (cur_ui_type):
		UIType.SKILL_UI:
			cur_ui_node = find_child("SkillChoose")
			pass
		UIType.GAME_END_UI:
			cur_ui_node = find_child("GameOver")
		UIType.LEVEL_COMPLETE_UI:
			cur_ui_node = find_child("LevelComplete")
	if is_instance_valid(cur_ui_node):
		cur_ui_node.visible = true
		prints("显示UI -> ", cur_ui_type)

func show_ui(type: UIType) -> void:
	cur_ui_type = type
	_show_ui()
	visible = true

func show_skill_choices(skills: Array[SkillPoint], title: String) -> void:
	show_ui(UIType.SKILL_UI)
	var skill_choose := cur_ui_node as SkillChoose
	if skill_choose != null:
		skill_choose.configure(skills, title)

func show_level_complete(level_index: int, difficulty_index: int) -> void:
	show_ui(UIType.LEVEL_COMPLETE_UI)
	if is_instance_valid(cur_ui_node):
		cur_ui_node.call("configure", level_index, difficulty_index)
	
func hide_ui() -> void:
	if is_instance_valid(cur_ui_node):
		cur_ui_node.visible = false
		cur_ui_node = null
	cur_ui_type = UIType.NONE
	visible = false
