class_name AttributeModifier extends Resource

enum ModifierType {
	ADD,
	SUB,
	MULT,
	DIVID,
}

static func compute(type: ModifierType, currentValue: float, ratio: float) -> float:
	var result = currentValue
	match type:
		ModifierType.ADD:
			result += ratio
		ModifierType.SUB:
			result -= ratio
		ModifierType.MULT:
			result *= ratio
		ModifierType.DIVID:
			if ratio != 0:
				result /= ratio
	return result
		

static func add(currentValue: float, ratio: float) -> float:
	return AttributeModifier.compute(ModifierType.ADD, currentValue, ratio)
static func sub(currentValue: float, ratio: float) -> float:
	return AttributeModifier.compute(ModifierType.SUB, currentValue, ratio)
static func mult(currentValue: float, ratio: float) -> float:
	return AttributeModifier.compute(ModifierType.MULT, currentValue, ratio)
static func divid(currentValue: float, ratio: float) -> float:
	return AttributeModifier.compute(ModifierType.DIVID, currentValue, ratio)
	
