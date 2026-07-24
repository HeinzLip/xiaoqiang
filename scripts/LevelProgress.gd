extends Node

const SAVE_PATH := "user://level_progress.cfg"

const LEVELS: Array[Dictionary] = [
	{
		"name": "第一关",
		"description": "守住初始防线",
		"spawn_interval": 0.66,
		"enemy_multiplier": 0.72,
		"growth_duration": 180.0,
		"elite_interval": 30,
		"elite_total": 3,
	},
	{
		"name": "第二关",
		"description": "穿越危险地带",
		"spawn_interval": 0.58,
		"enemy_multiplier": 0.92,
		"growth_duration": 150.0,
		"elite_interval": 25,
		"elite_total": 4,
	},
	{
		"name": "第三关",
		"description": "完成最终防守",
		"spawn_interval": 0.50,
		"enemy_multiplier": 1.16,
		"growth_duration": 125.0,
		"elite_interval": 20,
		"elite_total": 5,
	},
]

const DIFFICULTIES: Array[Dictionary] = [
	{"name": "简单", "enemy_multiplier": 0.82, "spawn_interval_multiplier": 0.88},
	{"name": "正常", "enemy_multiplier": 1.00, "spawn_interval_multiplier": 1.00},
	{"name": "困难", "enemy_multiplier": 1.22, "spawn_interval_multiplier": 1.16},
]

var selected_level_index := -1
var selected_difficulty_index := -1
var _completed: Dictionary = {}

func _ready() -> void:
	_load_progress()

func get_level_count() -> int:
	return LEVELS.size()

func get_level_name(level_index: int) -> String:
	if not _is_valid_level(level_index):
		return "未知关卡"
	return str(LEVELS[level_index]["name"])

func get_level_description(level_index: int) -> String:
	if not _is_valid_level(level_index):
		return ""
	var elite_total := int(LEVELS[level_index]["elite_total"])
	return "%s · 击败 %d 名精英和最终Boss" % [LEVELS[level_index]["description"], elite_total]

func get_difficulty_name(difficulty_index: int) -> String:
	if not _is_valid_difficulty(difficulty_index):
		return "未知难度"
	return str(DIFFICULTIES[difficulty_index]["name"])

func is_difficulty_unlocked(level_index: int, difficulty_index: int) -> bool:
	if not _is_valid_level(level_index) or not _is_valid_difficulty(difficulty_index):
		return false
	if difficulty_index == 0:
		return level_index == 0 or is_completed(level_index - 1, DIFFICULTIES.size() - 1)
	return is_completed(level_index, difficulty_index - 1)

func is_completed(level_index: int, difficulty_index: int) -> bool:
	return _completed.has(_completion_key(level_index, difficulty_index))

func get_unlock_hint(level_index: int, difficulty_index: int) -> String:
	if is_difficulty_unlocked(level_index, difficulty_index):
		return ""
	if difficulty_index == 0:
		return "通关上一关困难后解锁"
	return "通关本关%s后解锁" % get_difficulty_name(difficulty_index - 1)

func select_level(level_index: int, difficulty_index: int) -> bool:
	if not is_difficulty_unlocked(level_index, difficulty_index):
		return false
	selected_level_index = level_index
	selected_difficulty_index = difficulty_index
	return true

func has_selected_level() -> bool:
	return is_difficulty_unlocked(selected_level_index, selected_difficulty_index)

func get_selected_level_config() -> Dictionary:
	if not has_selected_level():
		select_level(0, 0)
	var config: Dictionary = LEVELS[selected_level_index].duplicate(true)
	var difficulty: Dictionary = DIFFICULTIES[selected_difficulty_index]
	config["enemy_multiplier"] = float(config["enemy_multiplier"]) * float(difficulty["enemy_multiplier"])
	config["spawn_interval"] = float(config["spawn_interval"]) / float(difficulty["spawn_interval_multiplier"])
	return config

func complete_level(level_index: int, difficulty_index: int) -> void:
	if not _is_valid_level(level_index) or not _is_valid_difficulty(difficulty_index):
		return
	_completed[_completion_key(level_index, difficulty_index)] = true
	_save_progress()

func _completion_key(level_index: int, difficulty_index: int) -> String:
	return "%d_%d" % [level_index, difficulty_index]

func _is_valid_level(level_index: int) -> bool:
	return level_index >= 0 and level_index < LEVELS.size()

func _is_valid_difficulty(difficulty_index: int) -> bool:
	return difficulty_index >= 0 and difficulty_index < DIFFICULTIES.size()

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved_progress: Variant = config.get_value("progress", "completed", [])
	if saved_progress is Array:
		for completion_key in saved_progress:
			_completed[str(completion_key)] = true

func _save_progress() -> void:
	var config := ConfigFile.new()
	var saved_progress: Array[String] = []
	for completion_key in _completed.keys():
		saved_progress.append(str(completion_key))
	config.set_value("progress", "completed", saved_progress)
	config.save(SAVE_PATH)
