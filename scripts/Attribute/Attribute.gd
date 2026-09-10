class_name Attribute extends Resource

signal value_changed(change_value: float)

enum ModifierAttrType {
	BASE,
	CURRENT
}

## 基础属性
var _base_value: float = 0.0

## 额外属性
var _add_value: float = 0.0

## 额外属性比例
var _ratio_value: float = 0.0

## 当前属性比例
var _current_ratio_value: float = 0.0

## 当前属性
var _current_value: float = 0.0

var _buffer_list: Array[AttributeBuff] = []

var _attr_type: int

func _init(type: int) -> void:
	_attr_type = type
	pass

## 计算当前属性
func calu_current_value() -> void:
	var calculated_value := _base_value + _add_value + _base_value * _ratio_value
	calculated_value += calculated_value * _current_ratio_value
	for buff in _buffer_list:
		if not buff.is_live():
			continue
		calculated_value += buff._buff_value
		calculated_value += calculated_value * buff._buff_ratio_value
	_current_value = calculated_value

## 基础属性直接叠加，不要轻易修改基础属性
func add_base_value(value: float) -> void:
	_base_value += value
	calu_current_value()
	value_changed.emit(_current_value)

## 额外属性直接叠加
func add_value(value: float) -> void:
	_add_value += value
	calu_current_value()
	value_changed.emit(_current_value)

## 额外属性比例叠加剩余比例的百分比
func add_surplus_value(value: float) -> void:
	var _formatValue = clampf(value, 0.0, 1.0)
	_ratio_value += (1.0 - _ratio_value) * _formatValue
	calu_current_value()
	value_changed.emit(_current_value)

## 额外属性比例直接叠加
func add_ratio(ratio: float) -> void:
	_ratio_value += ratio
	calu_current_value()
	value_changed.emit(_current_value)

## 当前属性比例直接叠加
func add_current_ratio(ratio: float) -> void:
	_current_ratio_value += ratio
	calu_current_value()
	value_changed.emit(_current_value)

## 增加当前属性buff
func add_buffer(buff: AttributeBuff) -> void:
	if buff == null or _buffer_list.has(buff):
		return
	_buffer_list.append(buff)
	buff.set_release_callback(_buff_release)
	buff.start()
	calu_current_value()
	value_changed.emit(_current_value)

func _buff_release(buff: AttributeBuff) -> void:
	_buffer_list.erase(buff)
	calu_current_value()
	value_changed.emit(_current_value)

func register_value_changed(_on_value_changed: Callable) -> void:
	value_changed.connect(_on_value_changed)

func unregitser_value_changed(_on_value_changed: Callable) -> void:
	if (value_changed.is_connected(_on_value_changed)):
		value_changed.disconnect(_on_value_changed)

func get_attr_type() -> AttributeEnum.DartAttribute:
	return _attr_type

func get_current_value() -> float:
	return _current_value
