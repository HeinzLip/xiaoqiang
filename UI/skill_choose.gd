class_name SkillChoose extends ColorRect

var skill_uis: Array[ImageAndLabel]

func _ready() -> void:
	skill_uis.append($VBoxContianer/HBoxContainer/ImageAndLabel2)
	skill_uis.append($VBoxContianer/HBoxContainer/ImageAndLabel4)
	skill_uis.append($VBoxContianer/HBoxContainer/ImageAndLabel)
	self.visibility_changed.connect(_on_visible_changed)
	pass

func show_skill_panel() -> void:
	var skills = SkillPool.get_random_skills()
	for index in range(skills.size()):
		var skill: SkillPoint = skills[index]
		skill_uis[index].update_info(skill)

func _on_visible_changed() -> void:
	if self.visible:
		show_skill_panel()
