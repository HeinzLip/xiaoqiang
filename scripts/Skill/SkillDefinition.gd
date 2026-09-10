class_name SkillDefinition extends Resource

## Immutable definition of one selectable reward. Runtime levels and unlocks
## belong to RunBuildState, while RewardOption only carries UI presentation.
enum Kind {
	WEAPON_UNLOCK,
	ATTRIBUTE_UPGRADE,
	UNIVERSAL_UPGRADE,
	GOLD,
}

enum AttributeOperation {
	BASE_VALUE,
	CURRENT_VALUE,
	BASE_SURPLUS_RATIO,
	BASE_RATIO,
	CURRENT_RATIO,
}

@export var id: StringName
@export var kind: Kind
@export var title := ""
@export_multiline var description := ""
@export var weapon_type: StringName
@export var attribute_key: StringName
@export var operation: AttributeOperation
@export var value := 0.0
@export var gold_amount := 0
@export var max_level := 6
@export var weight := 100

func has_level_cap() -> bool:
	return max_level > 0

func description_for_level(current_level: int) -> String:
	if kind in [Kind.ATTRIBUTE_UPGRADE, Kind.UNIVERSAL_UPGRADE] and has_level_cap():
		return "%s（%d / %d）" % [description, current_level, max_level]
	return description
