class_name GameMain extends Node2D

@onready var enemy_path: PathFollow2D = $Camera2D/Path2D/PathFollow2D
@onready var enemy_timer: Timer = $Timer
@onready var hud: GameHUD = $HUD

const ENEMY_SCENE := preload("res://scenes/enemy/Enemy.tscn")
const BOSS_LOOT_PICKUP_DELAY := 1.0

var elapsed_time := 0.0
var spawned_enemy_count := 0
var _level_index := 0
var _difficulty_index := 0
var _level_config: Dictionary
var _level_completed := false
var _elite_spawned := 0
var _elite_defeated := 0
var _boss_spawned := false

func _ready() -> void:
	randomize()
	Global.bind_game_scene($UIPanel, $WeaponSystem, $Player)
	CurrencyManager.begin_run()
	if not LevelProgress.has_selected_level():
		LevelProgress.select_level(0, 0)
	_level_index = LevelProgress.selected_level_index
	_difficulty_index = LevelProgress.selected_difficulty_index
	_level_config = LevelProgress.get_selected_level_config()
	enemy_timer.wait_time = float(_level_config.get("spawn_interval", 0.55))
	hud.configure_stage(
		LevelProgress.get_level_name(_level_index),
		LevelProgress.get_difficulty_name(_difficulty_index),
		int(_level_config.get("elite_total", 3))
	)
	# WeaponManager is an autoload and survives a scene reload, so each run
	# explicitly asks it to attach the starter weapon to this new scene.
	WeaponManager.call_deferred("add_weapon", WeaponType.Missile_Weapon)

func _spwan_enemy() -> void:
	if _level_completed or _boss_spawned:
		return
	var elite_total := int(_level_config.get("elite_total", 3))
	var elite_interval := int(_level_config.get("elite_interval", 28))
	var next_spawn_count := spawned_enemy_count + 1
	var spawn_elite := _elite_spawned < elite_total and next_spawn_count % elite_interval == 0
	_spawn_enemy(spawn_elite)

func _spawn_enemy(is_elite: bool, is_boss: bool = false) -> void:
	enemy_path.progress_ratio = randf()
	if not is_boss:
		spawned_enemy_count += 1
	var enemy_obj := ENEMY_SCENE.instantiate() as Enemy
	var growth_duration := float(_level_config.get("growth_duration", 75.0))
	var enemy_difficulty := float(_level_config.get("enemy_multiplier", 1.0)) * (1.0 + elapsed_time / growth_duration)
	enemy_obj.setup(is_elite, enemy_difficulty, is_boss)
	enemy_obj.global_position = enemy_path.global_position
	add_child(enemy_obj)
	if is_elite:
		enemy_obj.defeated.connect(_on_elite_defeated)
		if not is_boss:
			_elite_spawned += 1
			hud.update_elite_progress(_elite_defeated, int(_level_config.get("elite_total", 3)))

func _on_enemy_spwan() -> void:
	_spwan_enemy()

func _process(delta: float) -> void:
	if _level_completed or _boss_spawned:
		return
	elapsed_time += delta

func _on_elite_defeated(enemy: Enemy) -> void:
	if enemy.is_boss:
		_complete_after_boss_loot()
		return
	_elite_defeated += 1
	var elite_total := int(_level_config.get("elite_total", 3))
	hud.update_elite_progress(_elite_defeated, elite_total)
	if _elite_spawned >= elite_total and _elite_defeated >= elite_total:
		_spawn_final_boss()

func _spawn_final_boss() -> void:
	if _boss_spawned or _level_completed:
		return
	_boss_spawned = true
	enemy_timer.stop()
	_clear_regular_enemies()
	_spawn_enemy(true, true)
	hud.show_final_boss()

func _clear_regular_enemies() -> void:
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Enemy
		if enemy != null and not enemy.is_elite:
			enemy.queue_free()

func _complete_level() -> void:
	if _level_completed:
		return
	_level_completed = true
	enemy_timer.stop()
	Global.level_completed(_level_index, _difficulty_index)

func _complete_after_boss_loot() -> void:
	await get_tree().create_timer(BOSS_LOOT_PICKUP_DELAY).timeout
	if not get_tree().paused:
		_complete_level()
