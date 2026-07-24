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
    set(value):
        _ui_panel = value
    get:
        if not is_instance_valid(_ui_panel):
            _ui_panel = _find_scene_node("UIPanel") as UIPanel
        return _ui_panel

var _weapont_system: WeaponSystem
var weapont_system: WeaponSystem:
    set(value):
        _weapont_system = value
    get:
        if not is_instance_valid(_weapont_system):
            _weapont_system = _find_scene_node("WeaponSystem") as WeaponSystem
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
    set(value):
        _player = value
    get :
        if not is_instance_valid(_player):
            _player = _find_scene_node("Player") as Player
        return _player

func _ready() -> void:
    global_data = GlobalData.new()

func bind_game_scene(panel: UIPanel, weapon_system: WeaponSystem, game_player: Player) -> void:
    ui_panel = panel
    weapont_system = weapon_system
    player = game_player

func _find_scene_node(node_path: NodePath) -> Node:
    var current_scene := get_tree().current_scene
    if not is_instance_valid(current_scene):
        return null
    return current_scene.get_node_or_null(node_path)

func show_skill_ui(skills: Array[SkillPoint] = [], title: String = "选择一项强化") -> void:
    if is_instance_valid(ui_panel):
        ui_panel.show_skill_choices(skills, title)
    
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
    CurrencyManager.finish_run()
    get_tree().paused = true
    show_game_end()

func level_completed(level_index: int, difficulty_index: int) -> void:
    LevelProgress.complete_level(level_index, difficulty_index)
    CurrencyManager.finish_run()
    get_tree().paused = true
    if is_instance_valid(ui_panel):
        ui_panel.show_level_complete(level_index, difficulty_index)
    
## 复活
func recycle_life() -> void:
    pass

## 重置游戏
func reset_world() -> void:
    CurrencyManager.finish_run()
    PlayerExperienceSystem.clear_by_player_dead()
    CountManager.clear()
    WeaponManager.reset_run()
    get_tree().reload_current_scene()
    get_tree().paused = false

func return_to_level_select() -> void:
    CurrencyManager.finish_run()
    get_tree().paused = false
    get_tree().change_scene_to_file("res://UI/LevelSelect.tscn")
