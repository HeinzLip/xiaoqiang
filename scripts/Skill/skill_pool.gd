extends Node

## Reward generation only. Definitions and build state live in SkillCatalog
## and SkillService, so this node no longer owns reward payloads or levels.

func _random_options(definitions: Array[SkillDefinition], count: int = 3) -> Array[RewardOption]:
	definitions.shuffle()
	var options: Array[RewardOption] = []
	for definition in definitions:
		if options.size() >= count:
			break
		options.append(SkillService.make_option(definition))
	return options

func _get_weapon_upgrade_definitions() -> Array[SkillDefinition]:
	var definitions: Array[SkillDefinition] = []
	for weapon_type in SkillService.build_state.get_weapon_types():
		for definition in SkillCatalog.get_weapon_upgrade_definitions(StringName(weapon_type)):
			if SkillService.can_offer(definition):
				definitions.append(definition)
	return definitions

func _get_universal_upgrade_definitions() -> Array[SkillDefinition]:
	var definitions: Array[SkillDefinition] = []
	for definition in SkillCatalog.get_universal_upgrade_definitions():
		if SkillService.can_offer(definition):
			definitions.append(definition)
	return definitions

func _get_all_upgrade_definitions() -> Array[SkillDefinition]:
	var definitions := _get_weapon_upgrade_definitions()
	definitions.append_array(_get_universal_upgrade_definitions())
	return definitions

func get_random_upgrade_skills(count: int = 3) -> Array[RewardOption]:
	return _random_options(_get_all_upgrade_definitions(), count)

func _get_new_weapon_definitions() -> Array[SkillDefinition]:
	var definitions: Array[SkillDefinition] = []
	for definition in SkillCatalog.get_weapon_unlock_definitions():
		if SkillService.can_offer(definition):
			definitions.append(definition)
	return definitions

func get_elite_reward_choices() -> Array[RewardOption]:
	var new_weapon_definitions := _get_new_weapon_definitions()
	if SkillService.build_state.get_weapon_count() < WeaponManager.MAX_NEW_SKILLS:
		var choices := _random_options(new_weapon_definitions, 3)
		if choices.size() < 3:
			choices.append_array(_random_options(_get_all_upgrade_definitions(), 3 - choices.size()))
		return choices

	var candidates := _get_all_upgrade_definitions()
	for definition in SkillCatalog.get_gold_reward_definitions():
		if SkillService.can_offer(definition):
			candidates.append(definition)
	return _random_options(candidates, 3)

func get_random_skills() -> Array[RewardOption]:
	return get_random_upgrade_skills()
