class_name LevelComplete extends ColorRect

@onready var result_label: Label = $CenterPanel/Content/ResultLabel
@onready var unlock_label: Label = $CenterPanel/Content/UnlockLabel
@onready var continue_button: Button = $CenterPanel/Content/Buttons/ContinueButton
@onready var retry_button: Button = $CenterPanel/Content/Buttons/RetryButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.pressed.connect(_return_to_level_select)
	retry_button.pressed.connect(_retry_level)

func configure(level_index: int, difficulty_index: int) -> void:
	result_label.text = "%s · %s 通关" % [
		LevelProgress.get_level_name(level_index),
		LevelProgress.get_difficulty_name(difficulty_index),
	]
	unlock_label.text = "%s\n本局带出金币  +%d" % [
		_get_unlock_message(level_index, difficulty_index),
		CurrencyManager.last_carried_gold,
	]

func _get_unlock_message(level_index: int, difficulty_index: int) -> String:
	if difficulty_index < LevelProgress.DIFFICULTIES.size() - 1:
		return "已解锁本关%s难度" % LevelProgress.get_difficulty_name(difficulty_index + 1)
	if level_index < LevelProgress.get_level_count() - 1:
		return "已解锁%s简单难度" % LevelProgress.get_level_name(level_index + 1)
	return "恭喜，全部关卡均已通关！"

func _return_to_level_select() -> void:
	Global.return_to_level_select()

func _retry_level() -> void:
	Global.reset_world()
