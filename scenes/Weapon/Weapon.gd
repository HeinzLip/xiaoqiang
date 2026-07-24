class_name Weapon extends Node2D

@export var attr_set: AttributeSet

## Run-wide upgrades are applied by WeaponSystem whenever the player picks a
## universal reward. Individual weapons override this when an effect applies.
func set_universal_modifiers(_damage_multiplier: float, _attack_rate_multiplier: float, _count_bonus: int) -> void:
	pass
