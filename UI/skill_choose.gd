class_name SkillChoose extends ColorRect

var skill_uis: Array[ImageAndLabel]

func _ready() -> void:
	skill_uis.append($VBoxContianer/HBoxContainer/ImageAndLabel2)
	skill_uis.append($VBoxContianer/HBoxContainer/ImageAndLabel4)
	skill_uis.append($VBoxContianer/HBoxContainer/ImageAndLabel)

func configure(skills: Array[SkillPoint], title: String) -> void:
	$VBoxContianer/Label.text = title
	for index in range(skill_uis.size()):
		var card := skill_uis[index]
		if index < skills.size():
			card.visible = true
			card.update_info(skills[index])
		else:
			card.visible = false
