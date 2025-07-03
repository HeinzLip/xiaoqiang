class_name ImageAndLabel extends PanelContainer

@onready var _icon: TextureRect = $VBoxContainer/AspectRatioContainer/icon
@onready var _title: Label = $VBoxContainer/title
@onready var _description: Label = $VBoxContainer/description
@onready var _button: Button = $Button
var _skill: SkillPoint

func _ready() -> void:
	_button.button_down.connect(_on_button_button_down)
	_button.button_up.connect(_on_button_button_up)
	_button.pressed.connect(_on_button_button_press)
	_button.process_mode = Node.PROCESS_MODE_ALWAYS

func update_info(_skill: SkillPoint) -> void:
	self._title.text = _skill.name
	self._description.text = _skill.description
	self._skill = _skill
	
func _on_button_button_press() -> void:
	prints("_on_button_button_press")
func _on_button_button_up() -> void:
	prints("_on_button_button_up")

func _on_button_button_down() -> void:
	var title = _title.text
	prints("选择了 %s" % title)
	Global.weapont_system.update_skill(_skill.effect)
	Global.hide_skill_ui()
	get_tree().paused = false
	pass
