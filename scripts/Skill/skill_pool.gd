extends Node2D

var skill_data: Dictionary

func _ready() -> void:
	skill_data = FileManager.skill_map

func _make_effect(item: SkillListItem) -> SkillEffect:
	return SkillEffect.new(
		item.weapon_name,
		item.attribute_name,
		item.attribute_type,
		item.attribute_value
	)

func _random_choices(candidates: Array[SkillPoint], count: int = 3) -> Array[SkillPoint]:
	candidates.shuffle()
	var result: Array[SkillPoint] = []
	for index in range(mini(count, candidates.size())):
		result.append(candidates[index])
	return result

## Level-up rewards only improve weapons that the player already owns.
func _get_upgrade_candidates() -> Array[SkillPoint]:
	var candidates: Array[SkillPoint] = []
	var weapon_system := Global.weapont_system
	if not is_instance_valid(weapon_system):
		return candidates
	for weapon_type in WeaponManager.get_weapon_list():
		for raw_item in skill_data.get(weapon_type, []):
			var item := raw_item as SkillListItem
			if item == null:
				continue
			var effect := _make_effect(item)
			if not weapon_system.can_upgrade_skill(effect):
				continue
			var upgrade_level := weapon_system.get_skill_upgrade_count(effect)
			candidates.append(SkillPoint.new(
				item.skill_name_zh,
				"%s（%d / %d）" % [item.description, upgrade_level, WeaponSystem.MAX_SKILL_UPGRADE_LEVEL],
				effect,
				SkillPoint.RewardType.UPGRADE,
				weapon_type
			))
	return candidates

func _get_universal_upgrade_candidates() -> Array[SkillPoint]:
	var candidates: Array[SkillPoint] = []
	var weapon_system := Global.weapont_system
	if not is_instance_valid(weapon_system):
		return candidates
	var upgrades := [
		[WeaponSystem.UNIVERSAL_DAMAGE, "通用伤害", "所有技能伤害 +10%"],
		[WeaponSystem.UNIVERSAL_ATTACK_FREQUENCY, "通用频率", "所有技能攻击频率 +10%"],
		[WeaponSystem.UNIVERSAL_COUNT, "通用数量", "可发射技能数量 +1"],
	]
	for upgrade in upgrades:
		var key: String = upgrade[0]
		if not weapon_system.can_upgrade_universal_skill(key):
			continue
		candidates.append(SkillPoint.new(
			upgrade[1],
			"%s（%d / %d）" % [
				upgrade[2],
				weapon_system.get_universal_upgrade_count(key),
				WeaponSystem.MAX_SKILL_UPGRADE_LEVEL,
			],
			null,
			SkillPoint.RewardType.UNIVERSAL_UPGRADE,
			"",
			0,
			key
		))
	return candidates

func _get_all_upgrade_candidates() -> Array[SkillPoint]:
	var candidates := _get_upgrade_candidates()
	candidates.append_array(_get_universal_upgrade_candidates())
	return candidates

func get_random_upgrade_skills(count: int = 3) -> Array[SkillPoint]:
	return _random_choices(_get_all_upgrade_candidates(), count)

## Elite enemies offer a missing weapon first. Once all weapons are owned,
## their drop becomes a set of regular upgrades instead of opening an empty UI.
func _get_new_skill_candidates() -> Array[SkillPoint]:
	var candidates: Array[SkillPoint] = []
	if not WeaponManager.can_learn_new_skill():
		return candidates
	for weapon_type in WeaponManager.get_available_weapon_list():
		if WeaponManager.has_weapon(weapon_type):
			continue
		candidates.append(SkillPoint.new(
			"获得%s" % WeaponManager.get_weapon_display_name(weapon_type),
			"解锁新武器：%s" % WeaponManager.get_weapon_display_name(weapon_type),
			null,
			SkillPoint.RewardType.WEAPON_UNLOCK,
			weapon_type
		))
	return candidates

func get_random_new_weapon_skills(count: int = 3) -> Array[SkillPoint]:
	return _random_choices(_get_new_skill_candidates(), count)

func get_elite_reward_choices() -> Array[SkillPoint]:
	var choices: Array[SkillPoint] = []
	if WeaponManager.can_learn_new_skill():
		choices = _random_choices(_get_new_skill_candidates(), 3)
		# The current skill catalog can temporarily have fewer than three new
		# skills. Existing and universal upgrades fill the remaining card slots.
		if choices.size() < 3:
			choices.append_array(_random_choices(_get_all_upgrade_candidates(), 3 - choices.size()))
		return choices

	var candidates := _get_all_upgrade_candidates()
	for gold_amount in [20, 30, 40]:
		candidates.append(_make_gold_chest(gold_amount))
	return _random_choices(candidates, 3)

func _make_gold_chest(gold_amount: int) -> SkillPoint:
	return SkillPoint.new(
		"金币宝箱",
		"获得 %d 本局金币" % gold_amount,
		null,
		SkillPoint.RewardType.GOLD,
		"",
		gold_amount
	)

func get_random_skills() -> Array[SkillPoint]:
	return get_random_upgrade_skills()
