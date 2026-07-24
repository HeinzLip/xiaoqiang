class_name Bullet extends Area2D

var bullet_name_prefix := "player_bullet"

func _ready() -> void:
	name = bullet_name_prefix + _get_bullet_name()

func _get_bullet_name() -> String:
	return "base"

func bullet_damage() -> float:
	return -100
