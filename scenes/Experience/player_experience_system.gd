extends Node2D

signal progression_changed(level: int, experience: float, experience_needed: float)

var current_experience_value: float = 0.0
var current_level: int = 1
var current_level_max_experience: float = BalanceConfig.XP_BASE

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

func apply_choice(option: RewardOption) -> bool:
	if not _is_choosing_reward or option == null:
		return false
	if not SkillService.apply_option(option):
		# A card can become stale when a queued reward changed the available
		# upgrade set. Keep the current reward queued and replace the stale
		# cards, instead of leaving the clicked card permanently disabled.
		_is_choosing_reward = false
		_present_next_reward()
		return false
	_is_choosing_reward = false
	if not _pending_rewards.is_empty():
		_pending_rewards.pop_front()
	Global.hide_skill_ui()
	get_tree().paused = false
	call_deferred("_present_next_reward")
	return true

func _present_next_reward() -> void:
	if _is_choosing_reward:
		return
	if _pending_rewards.is_empty():
		_finish_reward_selection()
		return
	var reward_type: String = _pending_rewards.front()
	var choices: Array[RewardOption]
	var title := "选择一项强化"
	if reward_type == "elite":
		choices = SkillPool.get_elite_reward_choices()
		if SkillService.build_state.get_weapon_count() < WeaponManager.MAX_NEW_SKILLS:
			title = "精英战利品：3选1（新技能 %d / %d）" % [
				SkillService.build_state.get_weapon_count(),
				WeaponManager.MAX_NEW_SKILLS,
			]
		else:
			title = "精英战利品：3选1（强化或金币）"
	else:
		choices = SkillPool.get_random_upgrade_skills()
	if choices.is_empty():
		# All applicable upgrades have reached their cap. Remove this reward
		# and continue processing so the game is unpaused if the queue is done.
		_pending_rewards.pop_front()
		call_deferred("_present_next_reward")
		return
	_is_choosing_reward = true
	get_tree().paused = true
	Global.show_skill_ui(choices, title)

func _finish_reward_selection() -> void:
	_is_choosing_reward = false
	Global.hide_skill_ui()
	get_tree().paused = false

func _experience_needed_for_level(level: int) -> float:
	return BalanceConfig.XP_BASE + float(maxi(level - 1, 0)) * BalanceConfig.XP_STEP

func _emit_progression() -> void:
	progression_changed.emit(current_level, current_experience_value, current_level_max_experience)

func clear_by_player_dead() -> void:
	current_experience_value = 0.0
	current_level = 1
	current_level_max_experience = BalanceConfig.XP_BASE
	_pending_rewards.clear()
	_is_choosing_reward = false
	_emit_progression()
