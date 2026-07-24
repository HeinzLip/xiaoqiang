extends Node2D

var _destroyed_enemy: int = 0

func add_destroy_enemy() -> int:
	_destroyed_enemy += 1
	return _destroyed_enemy
	
func get_destroyed_enemy() -> int:
	return _destroyed_enemy

func clear() -> void:
	_destroyed_enemy = 0
