class_name ExperienceBean extends Area2D

@onready var bean_sprite := $Sprite2D

@export var experience_value: float

@export var experience_move_speed: float

var player: Player

func set_attribute() -> void:
	## experience_bean 创建后，更新对象属性
	pass

func _process(delta: float) -> void:
	if is_instance_valid(player) && is_inside_tree():
		#if name.begins_with("@"):
			#return
		var player_global_position = player.global_position
		var distance = global_position.distance_to(player_global_position)
		if distance < 20:
			_update_player_experience(experience_value)
			## experience_bean已经碰到player，则可以执行player的经验操作，并释放player对象
			player = null
			EEManager.recycle_bean(self)
		else:
			## 逐步追近player
			var toPlayerDirection = global_position.direction_to(player.global_position)
			global_position += toPlayerDirection * experience_move_speed * delta
	pass

func _update_player_experience(_experience_value: float) -> void:
	prints('_update_player_experience ->', _experience_value, name)
	if is_instance_valid(player):
		PlayerExperienceSystem.add_player_experience(_experience_value)
	pass

func _on_area_entered(area: Area2D) -> void:
	if area.name == "player_experience_area":
		## 增加经验
		player = area.get_parent()
		pass
	pass # Replace with function body.
