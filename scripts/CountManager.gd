extends Node2D

var _destroyed_enemy: int

func add_destroy_enemy() -> int:
	_destroyed_enemy += 1
	prints("destroy enemy number ->", _destroyed_enemy)
	return _destroyed_enemy
	
func get_destroyed_enemy() -> int:
	return _destroyed_enemy
