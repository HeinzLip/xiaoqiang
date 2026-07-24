extends Node2D

signal progression_changed(level: int, experience: float, experience_needed: float)

var current_experience_value: float = 0.0
var current_level: int = 1
var current_level_max_experience: float = 60.0

var _pending_rewards: Array[String] = []
var _is_choosing_reward := false

func add_player_experience(_experience: float) -> void:
	current_experience_value += maxf(_experience, 0.0)
	while current_experience_value >= current_level_max_experience:
		current_experience_value -= current_level_max_experience
		current_level += 1
		current_level_max_experience = _experience_needed_for_level(current_level)
		_pending_rewards.append("level")
	_emit_progression()
	_present_next_reward()

func request_elite_reward() -> void:
	_pending_rewards.append("elite")
	_present_next_reward()

func apply_choice(skill: SkillPoint) -> void:
	if not _is_choosing_reward or skill == null:
		return
	match skill.reward_type:
		SkillPoint.RewardType.WEAPON_UNLOCK:
			WeaponManager.add_weapon(skill.weapon_type)
		SkillPoint.RewardType.GOLD:
			CurrencyManager.add_run_gold(skill.gold_amount)
		SkillPoint.RewardType.UNIVERSAL_UPGRADE:
			Global.weapont_system.update_universal_skill(skill.universal_upgrade_key)
		_:
			Global.weapont_system.update_skill(skill.effect)
	_is_choosing_reward = false
	if not _pending_rewards.is_empty():
		_pending_rewards.pop_front()
	Global.hide_skill_ui()
	get_tree().paused = false
	call_deferred("_present_next_reward")

func _present_next_reward() -> void:
	if _is_choosing_reward or _pending_rewards.is_empty():
		return
	var reward_type: String = _pending_rewards.front()
	var choices: Array[SkillPoint]
	var title := "选择一项强化"
	if reward_type == "elite":
		choices = SkillPool.get_elite_reward_choices()
		if WeaponManager.can_learn_new_skill():
			title = "精英战利品：3选1（新技能 %d / %d）" % [
				WeaponManager.get_new_skill_count(),
				WeaponManager.MAX_NEW_SKILLS,
			]
		else:
			title = "精英战利品：3选1（强化或金币）"
	else:
		choices = SkillPool.get_random_upgrade_skills()
	if choices.is_empty():
		# All applicable upgrades have reached their cap. Do not leave the
		# game paused or retain an unresolvable reward in the queue.
		_pending_rewards.pop_front()
		call_deferred("_present_next_reward")
		return
	_is_choosing_reward = true
	get_tree().paused = true
	Global.show_skill_ui(choices, title)

func _experience_needed_for_level(level: int) -> float:
	return 60.0 + float(maxi(level - 1, 0) * 18)

func _emit_progression() -> void:
	progression_changed.emit(current_level, current_experience_value, current_level_max_experience)

func clear_by_player_dead() -> void:
	current_experience_value = 0.0
	current_level = 1
	current_level_max_experience = 60.0
	_pending_rewards.clear()
	_is_choosing_reward = false
	_emit_progression()
