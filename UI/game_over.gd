class_name GameOver extends ColorRect

@onready var restart_btn: Button = $VBoxContainer/HBoxContainer/RestartButton
@onready var end_btn: Button = $VBoxContainer/HBoxContainer/EndButton
@onready var metrics_label: Label = $VBoxContainer/MetricsLabel

func _ready() -> void:
	restart_btn.button_up.connect(_restart_game)
	end_btn.button_up.connect(_end_game)
	process_mode = Node.PROCESS_MODE_ALWAYS

func configure() -> void:
	metrics_label.text = RunMetrics.get_report_text()

func _restart_game() -> void:
	prints("重置游戏")
	Global.reset_world()

func _end_game() -> void:
	Global.return_to_level_select()
	
