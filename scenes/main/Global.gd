extends Node2D


var move_max_width = 1000
var move_max_height = 2000

@onready var camera_size := get_viewport_rect().size

var skill_ui: CanvasLayer

var weapont_system: WeaponSystem

var game_size = Vector2(move_max_width * 2, move_max_height * 2)

var player: Player:
	get :
		return _get_palyer()

func _ready() -> void:
	skill_ui = get_tree().current_scene.find_child("CanvasLayer")
	weapont_system = get_tree().current_scene.find_child("WeaponSystem")
	pass
	
func _get_palyer() -> Player:
	var _player =  get_tree().current_scene.player
	return _player
	
func show_skill_ui() -> void:
	skill_ui.visible = true
	
func hide_skill_ui() -> void:
	skill_ui.visible = false

	
