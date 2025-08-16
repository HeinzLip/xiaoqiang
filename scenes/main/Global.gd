extends Node2D
var _global_data: GlobalData
var global_data: GlobalData:
    set(vale):
        if _global_data == null:
            _global_data = vale
    get:
        return _global_data

var _camera_size = Vector2.ZERO
var camera_size: Vector2:
    set(vale):
        if _camera_size == null:
            _camera_size = vale
    get:
        if _camera_size == Vector2.ZERO:
            _camera_size = get_viewport_rect().size
        return _camera_size

var _ui_panel: UIPanel
var ui_panel: UIPanel:
    set(vale):
        if _ui_panel == null:
            _ui_panel = vale
    get:
        if not is_instance_valid(_ui_panel):
            _ui_panel = get_tree().current_scene.get_node("UIPanel")
        return _ui_panel

var _weapont_system: WeaponSystem
var weapont_system: WeaponSystem:
    set(vale):
        _weapont_system = vale
    get:
        if not is_instance_valid(_weapont_system):
            _weapont_system = get_tree().current_scene.get_node("WeaponSystem")
        return _weapont_system

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
        if not is_instance_valid(_player):
            _player = get_tree().current_scene.get_node("Player")
        return _player

func _ready() -> void:
    global_data = GlobalData.new()
    ui_panel = get_tree().current_scene.get_node("UIPanel")
    weapont_system = get_tree().current_scene.get_node("WeaponSystem")
    player = get_tree().current_scene.get_node("Player")
    prints("Experience Bean -> ready ->", ui_panel, weapont_system, player)
    pass

func show_skill_ui() -> void:
    prints("Experience Bean -> show_skill_ui")
    if is_instance_valid(ui_panel):
        ui_panel.show_ui(UIPanel.UIType.SKILL_UI)
    
func hide_skill_ui() -> void:
    if is_instance_valid(ui_panel):
        ui_panel.hide_ui()
    
func show_game_end() -> void:
    if is_instance_valid(ui_panel):
        ui_panel.show_ui(UIPanel.UIType.GAME_END_UI)
func hide_game_end() -> void:
    if is_instance_valid(ui_panel):
        ui_panel.hide_ui()
    
    
func player_dead() -> void:
    get_tree().paused = true
    show_game_end()
    
## 复活
func recycle_life() -> void:
    pass

## 重置游戏
func reset_world() -> void:
    get_tree().reload_current_scene()
    PlayerExperienceSystem.clear_by_player_dead()
    hide_game_end()
    get_tree().paused = false
