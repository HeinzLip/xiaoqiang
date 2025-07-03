class_name Attribute extends Resource

signal value_changed(change_value: float)

enum ModifierAttrType {
	BASE,
	CURRENT
}

@export var base_value: float

@export var attribute_tyep: String

var current_value: float

## 用于缓存对与基础属性的加成比例
var current_ratio: float

## 用于缓存所有属性加成后，最后需要叠加的值
var current_additive_value: float

func _init() -> void:
	current_ratio = 0.0
	current_additive_value = 0.0
	current_value = get_current_value()

func add_base_ratio(new_ratio: float) -> float:
	var base_new_ratio = abs(new_ratio)
	var other = 1.0 - current_ratio
	var add_diff = other * new_ratio
	current_ratio += add_diff
	#print("base ratio -> ", current_ratio)
	get_current_value()
	value_changed.emit(current_value)
	return current_value

func add_current_value(new_value: float) -> float:
	current_additive_value += new_value
	current_value += new_value
	value_changed.emit(current_value)
	#print("修改current值，并发送信号")
	return current_value

func get_current_value() -> float:
	current_value = base_value + base_value * current_ratio + current_additive_value
	return current_value

#@export var strength_base: float
#@export var agility_base: float
#@export var intelligence_base: float
#
#var strength_current: float
#var agility_cureent: float
#var intelligence_current: float
#
#func get_strength() -> float:
	#return strength_current
	#
#func get_agility() -> float:
	#return agility_cureent
	#
#func get_intelligence() -> float:
	#return intelligence_current
