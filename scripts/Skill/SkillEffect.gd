

class_name SkillEffect extends Node
enum GainType {
	BASE_RATIO,
	CURRENT_VALUE
}

var weapon_type: String

var attribute_type: String

var gain_type: GainType

var gain_value: float

func _init(_wean_type: String, _attribute_type: String, _gain_type: GainType, _gain_value: float) -> void:
	self.weapon_type = _wean_type
	self.attribute_type = _attribute_type
	self.gain_type = _gain_type
	self.gain_value = _gain_value
	pass
