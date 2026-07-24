class_name ImageAndLabel extends PanelContainer

@onready var _icon: TextureRect = $VBoxContainer/AspectRatioContainer/icon
@onready var _title: Label = $VBoxContainer/title
@onready var _description: Label = $VBoxContainer/description
@onready var _button: Button = $Button
var _skill: SkillPoint

func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)
	_button.process_mode = Node.PROCESS_MODE_ALWAYS

func update_info(_skill_param: SkillPoint) -> void:
	self._title.text = _skill_param.name
	self._description.text = _skill_param.description
	self._skill = _skill_param
	_icon.modulate = Color("ffd34d") if _skill_param.reward_type == SkillPoint.RewardType.GOLD else Color.WHITE
	_button.disabled = false

func _on_button_pressed() -> void:
	if _skill == null:
		return
	# Prevent a double click from applying the same reward twice while the
	# selection panel is closing.
	_button.disabled = true
	PlayerExperienceSystem.apply_choice(_skill)
