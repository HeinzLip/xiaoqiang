extends Node

var weapon_names := {
	WeaponType.Missile_Weapon: "子弹",
	WeaponType.Dart_Weapon: "回旋飞镖",
	WeaponType.Arc_Weapon: "电弧",
	WeaponType.Sound_Wave_Weapon: "声波",
	WeaponType.Ice_Spike_Weapon: "冰刺",
	WeaponType.Lightning_Weapon: "落雷",
}

const UNIVERSAL_DAMAGE := &"universal.damage"
const UNIVERSAL_ATTACK_FREQUENCY := &"universal.attack_frequency"

var _definitions: Dictionary = {}
var _weapon_upgrade_ids: Dictionary = {}
var _weapon_unlock_ids: Array[StringName] = []
var _universal_upgrade_ids: Array[StringName] = []
var _gold_reward_ids: Array[StringName] = []

func _ready() -> void:
	_load_definitions()

func _load_definitions() -> void:
	_definitions.clear()
	_weapon_upgrade_ids.clear()
	_weapon_unlock_ids.clear()
	_universal_upgrade_ids.clear()
	_gold_reward_ids.clear()
	for weapon_type in weapon_names:
		var weapon_name: String = weapon_names[weapon_type]
		var unlock := SkillDefinition.new()
		unlock.id = StringName("weapon.%s" % weapon_type)
		unlock.kind = SkillDefinition.Kind.WEAPON_UNLOCK
		unlock.title = "获得%s" % weapon_name
		unlock.description = "解锁新武器：%s" % weapon_name
		unlock.weapon_type = StringName(weapon_type)
		unlock.max_level = 1
		_register(unlock)
		_weapon_unlock_ids.append(unlock.id)

	for weapon_type in FileManager.skill_map:
		for raw_item in FileManager.skill_map[weapon_type]:
			var item := raw_item as SkillListItem
			if item == null:
				continue
			var item_weapon_type := StringName(item.weapon_name)
			var item_attribute_key := StringName(item.attribute_name)
			# Quantity is registered below as one standard, explicit +1 card per
			# compatible weapon. Do not retain the older vague/duplicate CSV cards.
			if _is_quantity_attribute(item_weapon_type, item_attribute_key):
				continue
			var upgrade := SkillDefinition.new()
			upgrade.id = StringName("%s.%s" % [item.weapon_name, item.skill_name])
			upgrade.kind = SkillDefinition.Kind.ATTRIBUTE_UPGRADE
			upgrade.title = item.skill_name_zh
			upgrade.description = item.description
			upgrade.weapon_type = item_weapon_type
			upgrade.attribute_key = item_attribute_key
			upgrade.operation = item.attribute_type
			upgrade.value = item.attribute_value
			upgrade.max_level = 6
			_register(upgrade)
			if not _weapon_upgrade_ids.has(upgrade.weapon_type):
				_weapon_upgrade_ids[upgrade.weapon_type] = []
			_weapon_upgrade_ids[upgrade.weapon_type].append(upgrade.id)

	_register_weapon_quantity_upgrade(
		WeaponType.Missile_Weapon,
		AttributeEnum.instance.BULLET_FIRE_NUMBER
	)
	_register_weapon_quantity_upgrade(
		WeaponType.Dart_Weapon,
		AttributeEnum.instance.DART_NUMBER
	)
	_register_weapon_quantity_upgrade(
		WeaponType.Sound_Wave_Weapon,
		AttributeEnum.instance.SOUND_WAVE_COUNT
	)
	_register_weapon_quantity_upgrade(
		WeaponType.Ice_Spike_Weapon,
		AttributeEnum.instance.ICE_SPIKE_COUNT
	)
	_register_weapon_quantity_upgrade(
		WeaponType.Lightning_Weapon,
		AttributeEnum.instance.LIGHTNING_COUNT
	)
	_register_universal(UNIVERSAL_DAMAGE, "通用伤害", "所有技能伤害 +10%", 0.1)
	_register_universal(UNIVERSAL_ATTACK_FREQUENCY, "通用频率", "所有技能攻击频率 +10%", 0.1)
	_register_gold(&"gold.small", 20)
	_register_gold(&"gold.medium", 30)
	_register_gold(&"gold.large", 40)

func _register_universal(skill_id: StringName, title: String, description: String, value: float) -> void:
	var upgrade := SkillDefinition.new()
	upgrade.id = skill_id
	upgrade.kind = SkillDefinition.Kind.UNIVERSAL_UPGRADE
	upgrade.title = title
	upgrade.description = description
	upgrade.value = value
	upgrade.max_level = 6
	_register(upgrade)
	_universal_upgrade_ids.append(skill_id)

func _register_weapon_quantity_upgrade(weapon_type: StringName, attribute_key: StringName) -> void:
	var weapon_name: String = weapon_names.get(String(weapon_type), String(weapon_type))
	var upgrade := SkillDefinition.new()
	upgrade.id = StringName("%s.quantity" % weapon_type)
	upgrade.kind = SkillDefinition.Kind.ATTRIBUTE_UPGRADE
	upgrade.title = "%s数量" % weapon_name
	upgrade.description = "%s数量 +1" % weapon_name
	upgrade.weapon_type = weapon_type
	upgrade.attribute_key = attribute_key
	upgrade.operation = SkillDefinition.AttributeOperation.CURRENT_VALUE
	upgrade.value = 1.0
	upgrade.max_level = 6
	_register(upgrade)
	if not _weapon_upgrade_ids.has(weapon_type):
		_weapon_upgrade_ids[weapon_type] = []
	_weapon_upgrade_ids[weapon_type].append(upgrade.id)

func _is_quantity_attribute(weapon_type: StringName, attribute_key: StringName) -> bool:
	return (weapon_type == WeaponType.Missile_Weapon and attribute_key == AttributeEnum.instance.BULLET_FIRE_NUMBER) \
		or (weapon_type == WeaponType.Dart_Weapon and attribute_key == AttributeEnum.instance.DART_NUMBER) \
		or (weapon_type == WeaponType.Sound_Wave_Weapon and attribute_key == AttributeEnum.instance.SOUND_WAVE_COUNT) \
		or (weapon_type == WeaponType.Ice_Spike_Weapon and attribute_key == AttributeEnum.instance.ICE_SPIKE_COUNT) \
		or (weapon_type == WeaponType.Lightning_Weapon and attribute_key == AttributeEnum.instance.LIGHTNING_COUNT)

func _register_gold(skill_id: StringName, amount: int) -> void:
	var reward := SkillDefinition.new()
	reward.id = skill_id
	reward.kind = SkillDefinition.Kind.GOLD
	reward.title = "金币宝箱"
	reward.description = "获得 %d 本局金币" % amount
	reward.gold_amount = amount
	reward.max_level = 0
	_register(reward)
	_gold_reward_ids.append(skill_id)

func _register(definition: SkillDefinition) -> void:
	_definitions[definition.id] = definition

func get_definition(skill_id: StringName) -> SkillDefinition:
	return _definitions.get(skill_id) as SkillDefinition

func get_weapon_upgrade_definitions(weapon_type: StringName) -> Array[SkillDefinition]:
	return _definitions_from_ids(_weapon_upgrade_ids.get(weapon_type, []))

func get_weapon_unlock_definitions() -> Array[SkillDefinition]:
	return _definitions_from_ids(_weapon_unlock_ids)

func get_universal_upgrade_definitions() -> Array[SkillDefinition]:
	return _definitions_from_ids(_universal_upgrade_ids)

func get_gold_reward_definitions() -> Array[SkillDefinition]:
	return _definitions_from_ids(_gold_reward_ids)

func get_weapon_unlock_definition(weapon_type: StringName) -> SkillDefinition:
	return get_definition(StringName("weapon.%s" % weapon_type))

func _definitions_from_ids(ids: Array) -> Array[SkillDefinition]:
	var result: Array[SkillDefinition] = []
	for skill_id in ids:
		var definition := get_definition(StringName(skill_id))
		if definition != null:
			result.append(definition)
	return result
