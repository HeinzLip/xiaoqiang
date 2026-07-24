class_name LevelSelect extends Control

@onready var wallet_label: Label = $WalletLabel
@onready var upgrade_button: Button = $UpgradeButton
@onready var upgrade_panel: Control = $UpgradePanel

@onready var _level_titles: Array[Label] = [
	$CenterPanel/Content/Level1/Content/LevelTitle,
	$CenterPanel/Content/Level2/Content/LevelTitle,
	$CenterPanel/Content/Level3/Content/LevelTitle,
]
@onready var _level_descriptions: Array[Label] = [
	$CenterPanel/Content/Level1/Content/LevelDescription,
	$CenterPanel/Content/Level2/Content/LevelDescription,
	$CenterPanel/Content/Level3/Content/LevelDescription,
]
@onready var _difficulty_buttons: Array = [
	[
		$CenterPanel/Content/Level1/Content/DifficultyButtons/EasyButton,
		$CenterPanel/Content/Level1/Content/DifficultyButtons/NormalButton,
		$CenterPanel/Content/Level1/Content/DifficultyButtons/HardButton,
	],
	[
		$CenterPanel/Content/Level2/Content/DifficultyButtons/EasyButton,
		$CenterPanel/Content/Level2/Content/DifficultyButtons/NormalButton,
		$CenterPanel/Content/Level2/Content/DifficultyButtons/HardButton,
	],
	[
		$CenterPanel/Content/Level3/Content/DifficultyButtons/EasyButton,
		$CenterPanel/Content/Level3/Content/DifficultyButtons/NormalButton,
		$CenterPanel/Content/Level3/Content/DifficultyButtons/HardButton,
	],
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_button.pressed.connect(_open_upgrade_panel)
	CurrencyManager.banked_gold_changed.connect(_on_banked_gold_changed)
	for level_index in range(_difficulty_buttons.size()):
		for difficulty_index in range(_difficulty_buttons[level_index].size()):
			var button := _difficulty_buttons[level_index][difficulty_index] as Button
			button.pressed.connect(_start_level.bind(level_index, difficulty_index))
	_refresh()
	_on_banked_gold_changed(CurrencyManager.banked_gold)

func _open_upgrade_panel() -> void:
	upgrade_panel.show()

func _on_banked_gold_changed(amount: int) -> void:
	wallet_label.text = "永久金币  %d" % amount

func _refresh() -> void:
	for level_index in range(_level_titles.size()):
		_level_titles[level_index].text = LevelProgress.get_level_name(level_index)
		_level_descriptions[level_index].text = LevelProgress.get_level_description(level_index)
		for difficulty_index in range(_difficulty_buttons[level_index].size()):
			var button := _difficulty_buttons[level_index][difficulty_index] as Button
			var unlocked := LevelProgress.is_difficulty_unlocked(level_index, difficulty_index)
			var completed := LevelProgress.is_completed(level_index, difficulty_index)
			var difficulty_name := LevelProgress.get_difficulty_name(difficulty_index)
			button.disabled = not unlocked
			button.text = "%s%s" % [difficulty_name, "  ✓" if completed else ""]
			button.tooltip_text = "已通关" if completed else ("开始挑战" if unlocked else LevelProgress.get_unlock_hint(level_index, difficulty_index))

func _start_level(level_index: int, difficulty_index: int) -> void:
	if not LevelProgress.select_level(level_index, difficulty_index):
		_refresh()
		return
	PlayerExperienceSystem.clear_by_player_dead()
	CountManager.clear()
	WeaponManager.reset_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
