class_name UIPanel extends CanvasLayer

enum UIType {
	NONE,
	SKILL_UI,
	GAME_END_UI
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
			pass
	if is_instance_valid(cur_ui_node):
		cur_ui_node.visible = true
		prints("显示UI -> ", cur_ui_type)

func show_ui(type: UIType) -> void:
	cur_ui_type = type
	_show_ui()
	visible = true
	
func hide_ui() -> void:
	if is_instance_valid(cur_ui_node):
		cur_ui_node.visible = false
		cur_ui_node = null
	cur_ui_type = UIType.NONE
	visible = false
