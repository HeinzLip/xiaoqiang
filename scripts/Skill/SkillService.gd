extends Node

var build_state := RunBuildState.new()

func reset_run() -> void:
	build_state.reset()

func register_starter_weapon(weapon_type: StringName) -> void:
	build_state.unlock_weapon(weapon_type)
	var definition := SkillCatalog.get_weapon_unlock_definition(weapon_type)
	if definition != null:
		build_state.set_level(definition.id, 1)

func can_offer(definition: SkillDefinition) -> bool:
	if definition == null:
		return false
	if definition.has_level_cap() and build_state.get_level(definition.id) >= definition.max_level:
		return false
	match definition.kind:
		SkillDefinition.Kind.WEAPON_UNLOCK:
			return not build_state.has_weapon(definition.weapon_type) and build_state.get_weapon_count() < WeaponManager.MAX_NEW_SKILLS
		SkillDefinition.Kind.ATTRIBUTE_UPGRADE:
			# Do not present an attribute card until its concrete weapon exists.
			# This keeps queued rewards from offering an upgrade that cannot be
			# applied while a weapon scene is still being attached or was removed.
			return build_state.has_weapon(definition.weapon_type) \
				and is_instance_valid(Global.weapont_system) \
				and Global.weapont_system.has_weapon(definition.weapon_type)
		SkillDefinition.Kind.UNIVERSAL_UPGRADE, SkillDefinition.Kind.GOLD:
			return true
	return false

func make_option(definition: SkillDefinition) -> RewardOption:
	return RewardOption.new(definition, build_state.get_level(definition.id))

func apply_option(option: RewardOption) -> bool:
	if option == null:
		return false
	return apply_definition(option.definition)

func apply_definition(definition: SkillDefinition) -> bool:
	if not can_offer(definition):
		return false
	match definition.kind:
		SkillDefinition.Kind.WEAPON_UNLOCK:
			if not WeaponManager.add_weapon(String(definition.weapon_type)):
				return false
			build_state.unlock_weapon(definition.weapon_type)
		SkillDefinition.Kind.ATTRIBUTE_UPGRADE:
			if not Global.weapont_system.apply_attribute_upgrade(definition):
				return false
		SkillDefinition.Kind.UNIVERSAL_UPGRADE:
			var next_level := build_state.get_level(definition.id) + 1
			if not Global.weapont_system.apply_universal_upgrade(definition, next_level):
				return false
		SkillDefinition.Kind.GOLD:
			CurrencyManager.add_run_gold(definition.gold_amount)
	build_state.increase_level(definition.id)
	return true
