class_name SkillPoint extends Resource

enum RewardType {
	UPGRADE,
	WEAPON_UNLOCK,
	GOLD,
	UNIVERSAL_UPGRADE,
}

var name: String

var description: String

var effect: SkillEffect

var reward_type: RewardType = RewardType.UPGRADE

## Unlock rewards do not have an attribute effect, so retain the weapon key
## separately from the effect data.
var weapon_type: String
var gold_amount := 0
var universal_upgrade_key := ""

func _init(
	_name: String,
	_description: String,
	_effect: SkillEffect = null,
	_reward_type: RewardType = RewardType.UPGRADE,
	_weapon_type: String = "",
	_gold_amount: int = 0,
	_universal_upgrade_key: String = ""
) -> void:
	self.name = _name
	self.description = _description
	self.effect = _effect
	self.reward_type = _reward_type
	self.weapon_type = _weapon_type
	self.gold_amount = _gold_amount
	self.universal_upgrade_key = _universal_upgrade_key
