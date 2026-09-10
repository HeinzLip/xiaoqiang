class_name ExperienceBean extends Area2D

@export var experience_value: int = 12
@export var experience_move_speed: float = 1000.0

var player: Player

func set_attribute() -> void:
	player = null
	visible = true
	monitoring = true

func configure(value: int) -> void:
	experience_value = value
	set_attribute()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_inside_tree():
		return
	var distance := global_position.distance_to(player.global_position)
	if distance < 18.0:
		PlayerExperienceSystem.add_player_experience(experience_value)
		player = null
		EEManager.recycle_bean(self)
		return
	global_position += global_position.direction_to(player.global_position) * experience_move_speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(GroupConfig.get_instance().Player_Experience_Area_Group):
		player = area.get_parent() as Player
