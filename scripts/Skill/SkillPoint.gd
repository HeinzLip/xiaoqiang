class_name SkillPoint extends Resource

var name: String

var description: String

var effect: SkillEffect

func _init(_name: String, _description: String, _effect: SkillEffect) -> void:
	self.name = _name
	self.description = _description
	self.effect = _effect
	pass
