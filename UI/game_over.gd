class_name GameOver extends ColorRect

@onready var restart_btn: Button = $VBoxContainer/HBoxContainer/RestartButton
@onready var end_btn: Button = $VBoxContainer/HBoxContainer/EndButton

func _ready() -> void:
	restart_btn.button_up.connect(_restart_game)
	end_btn.button_up.connect(_end_game)
	process_mode = Node.PROCESS_MODE_ALWAYS
	

func _restart_game() -> void:
	prints("重置游戏")
	Global.reset_world()

func _end_game() -> void:
	pass
	
