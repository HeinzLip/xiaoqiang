class_name GameHUD extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var experience_bar: ProgressBar = $MarginContainer/VBoxContainer/ExperienceBar
@onready var experience_label: Label = $MarginContainer/VBoxContainer/ExperienceLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/KillLabel
@onready var coin_label: Label = $MarginContainer/VBoxContainer/CoinLabel
@onready var stage_label: Label = $StageInfo/Content/StageLabel
@onready var objective_label: Label = $StageInfo/Content/ObjectiveLabel

var _refresh_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PlayerExperienceSystem.progression_changed.connect(_on_progression_changed)
	CurrencyManager.run_gold_changed.connect(_on_run_gold_changed)
	if is_instance_valid(Global.player):
		Global.player.health_changed.connect(_on_health_changed)
	_on_progression_changed(
		PlayerExperienceSystem.current_level,
		PlayerExperienceSystem.current_experience_value,
		PlayerExperienceSystem.current_level_max_experience
	)
	_on_health_changed(Global.player.current_health, Global.player.max_health)
	_on_run_gold_changed(CurrencyManager.run_gold)

func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.2
		kill_label.text = "击败  %d" % CountManager.get_destroyed_enemy()

func _on_health_changed(current: float, maximum: float) -> void:
	var percentage := 0.0 if maximum <= 0.0 else current / maximum * 100.0
	health_bar.value = percentage
	health_label.text = "生命  %d / %d" % [roundi(current), roundi(maximum)]

func _on_progression_changed(level: int, experience: float, needed: float) -> void:
	var percentage := 0.0 if needed <= 0.0 else experience / needed * 100.0
	experience_bar.value = percentage
	experience_label.text = "等级 %d   经验 %d / %d" % [level, roundi(experience), roundi(needed)]

func _on_run_gold_changed(amount: int) -> void:
	coin_label.text = "本局金币  %d" % amount

func configure_stage(level_name: String, difficulty_name: String, elite_total: int) -> void:
	stage_label.text = "%s · %s" % [level_name, difficulty_name]
	update_elite_progress(0, elite_total)

func update_elite_progress(defeated: int, elite_total: int) -> void:
	objective_label.text = "精英  %d / %d" % [defeated, elite_total]

func show_final_boss() -> void:
	objective_label.text = "最终Boss出现！"
