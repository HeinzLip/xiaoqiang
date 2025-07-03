class_name AttributeSet extends Resource

@export var attrs: Dictionary[String, Attribute]

func find_attr(key: String) -> Attribute:
	if attrs.has(key):
		return attrs.get(key)
	else:
		push_error("AttributeSet can`t find key ->", key)
		return null
