class_name RewardOption extends Resource

## A short-lived UI card. It references an immutable definition instead of
## duplicating effect, weapon, gold, and universal-upgrade fields.
var definition: SkillDefinition
var current_level := 0

func _init(_definition: SkillDefinition = null, _current_level: int = 0) -> void:
	definition = _definition
	current_level = _current_level

func get_title() -> String:
	return definition.title if definition != null else ""

func get_description() -> String:
	return definition.description_for_level(current_level) if definition != null else ""

func is_gold() -> bool:
	return definition != null and definition.kind == SkillDefinition.Kind.GOLD
