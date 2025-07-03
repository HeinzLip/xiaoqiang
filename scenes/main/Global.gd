extends Node2D
var _global_data: GlobalData
var global_data: GlobalData:
	set(vale):
		if _global_data == null:
			_global_data = vale
	get:
		return _global_data

var _camera_size = get_viewport_rect().size
var camera_size: Vector2:
	set(vale):
		if _camera_size == null:
			_camera_size = vale
	get:
		return _camera_size

var _skill_ui: CanvasLayer
var skill_ui: CanvasLayer:
	set(vale):
		if _skill_ui == null:
			_skill_ui = vale
	get:
		return _skill_ui

var _weapont_system: WeaponSystem
var weapont_system: WeaponSystem:
	set(vale):
		_weapont_system = vale
	get:
		return weapont_system

var _game_size: Vector2
var game_size: Vector2:
	set(vale):
		if _game_size == null:
			_game_size = vale
	get:
		return _game_size

var _player: Player
var player: Player:
	set(vale):
		if _player == null:
			_player = vale
	get :
		return _player

func _ready() -> void:
	global_data = GlobalData.new()
	skill_ui = get_tree().current_scene.get_node("CanvasLayer")
	weapont_system = get_tree().current_scene.get_node("WeaponSystem")
	player = get_tree().current_scene.player
	prints("Experience Bean -> ready ->", skill_ui, weapont_system, player)
	pass

func show_skill_ui() -> void:
	prints("Experience Bean -> show_skill_ui")
	if not is_instance_valid(skill_ui):
		skill_ui = null
		skill_ui = get_tree().current_scene.find_child("CanvasLayer")
	skill_ui.visible = true
	
func hide_skill_ui() -> void:
	skill_ui.visible = false
