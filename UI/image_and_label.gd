class_name ImageAndLabel extends PanelContainer

@onready var _icon: TextureRect = $VBoxContainer/AspectRatioContainer/icon
@onready var _title: Label = $VBoxContainer/title
@onready var _description: Label = $VBoxContainer/description
@onready var _button: Button = $Button
var _option: RewardOption

func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)
	_button.process_mode = Node.PROCESS_MODE_ALWAYS

func update_info(option: RewardOption) -> void:
	self._title.text = option.get_title()
	self._description.text = option.get_description()
	self._option = option
	_icon.modulate = Color("ffd34d") if option.is_gold() else Color.WHITE
	_button.disabled = false

func clear_info() -> void:
	_option = null
	_button.disabled = true

func _on_button_pressed() -> void:
	if _option == null:
		return
	# Prevent a double click from applying the same reward twice while the
	# selection panel is closing.
	_button.disabled = true
	if not PlayerExperienceSystem.apply_choice(_option):
		# The reward panel may have been refreshed because this card was stale.
		# If it remains visible, it must always be clickable again.
		_button.disabled = false
