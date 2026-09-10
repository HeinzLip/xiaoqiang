class_name GameMain extends Node2D

@onready var enemy_path: PathFollow2D = $Camera2D/Path2D/PathFollow2D
@onready var enemy_timer: Timer = $Timer
@onready var hud: GameHUD = $HUD
@onready var level_tile_map: LevelTileMap = $LevelTileMap

const ENEMY_SCENE := preload("res://scenes/enemy/Enemy.tscn")
const BOSS_LOOT_PICKUP_DELAY := 1.0
const TREE_SPRITES := preload("res://assets/tiles/tree_sprites.png")
const TREE_COLLISION_RADIUS := 30.0

var elapsed_time := 0.0
var spawned_enemy_count := 0
var _level_index := 0
var _difficulty_index := 0
var _level_config: Dictionary
var _level_completed := false
var _elite_spawned := 0
var _elite_defeated := 0
var _boss_spawned := false
var _wave_index := 0
var _spawned_in_wave := 0
var _waiting_for_wave_elite := false

func _ready() -> void:
	randomize()
	AudioManager.play_battle_bgm()
	Global.bind_game_scene($UIPanel, $WeaponSystem, $Player)
	CurrencyManager.begin_run()
	if not LevelProgress.has_selected_level():
		LevelProgress.select_level(0, 0)
	_level_index = LevelProgress.selected_level_index
	_difficulty_index = LevelProgress.selected_difficulty_index
	_level_config = LevelProgress.get_selected_level_config()
	RunMetrics.begin_run(
		LevelProgress.get_level_name(_level_index),
		LevelProgress.get_difficulty_name(_difficulty_index),
	)
	# 瓦片地图暂下掉
	_configure_current_wave_timer()
	hud.configure_stage(
		LevelProgress.get_level_name(_level_index),
		LevelProgress.get_difficulty_name(_difficulty_index),
		_get_wave_configs().size()
	)
	# 确保运行状态干净: 直接从编辑器运行 main.tscn (不经 LevelSelect) 时,
	# Autoload 上可能残留上一局的武器解锁/强化等级, 导致初始武器注册失败。
	WeaponManager.reset_run()
	# WeaponManager is an autoload and survives a scene reload, so each run
	# explicitly asks it to attach the starter weapon to this new scene.
	WeaponManager.call_deferred("add_starter_weapon")

func _exit_tree() -> void:
	AudioManager.stop_battle_bgm()

func _spwan_enemy() -> void:
	if _level_completed or _boss_spawned or _waiting_for_wave_elite:
		return
	var wave_config := _get_current_wave_config()
	if wave_config.is_empty():
		return
	_spawn_enemy(wave_config, false)
	_spawned_in_wave += 1
	if _spawned_in_wave >= int(wave_config.get("enemy_count", 1)):
		_waiting_for_wave_elite = true
		enemy_timer.stop()
		_spawn_enemy(wave_config, true)

func _spawn_enemy(enemy_config: Dictionary, is_elite: bool, is_boss: bool = false) -> void:
	enemy_path.progress_ratio = randf()
	if not is_boss:
		if not is_elite:
			spawned_enemy_count += 1
	var enemy_obj := ENEMY_SCENE.instantiate() as Enemy
	enemy_obj.setup(enemy_config, float(_level_config.get("enemy_multiplier", 1.0)), is_elite, is_boss)
	enemy_obj.global_position = enemy_path.global_position
	add_child(enemy_obj)
	if is_elite:
		enemy_obj.defeated.connect(_on_elite_defeated)
		if not is_boss:
			_elite_spawned += 1
			hud.update_elite_progress(_elite_defeated, _get_wave_configs().size())

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
	var waves := _get_wave_configs()
	hud.update_elite_progress(_elite_defeated, waves.size())
	if _wave_index >= waves.size() - 1:
		_spawn_final_boss()
		return
	_wave_index += 1
	_spawned_in_wave = 0
	_waiting_for_wave_elite = false
	_configure_current_wave_timer()
	enemy_timer.start()

func _spawn_final_boss() -> void:
	if _boss_spawned or _level_completed:
		return
	_boss_spawned = true
	enemy_timer.stop()
	_clear_regular_enemies()
	var boss_config: Dictionary = _level_config.get("boss", _get_current_wave_config())
	_spawn_enemy(boss_config, true, true)
	hud.show_final_boss()

func _get_wave_configs() -> Array:
	var waves: Variant = _level_config.get("waves", [])
	return waves as Array if waves is Array else []

func _get_current_wave_config() -> Dictionary:
	var waves := _get_wave_configs()
	if _wave_index < 0 or _wave_index >= waves.size():
		return {}
	var wave: Variant = waves[_wave_index]
	return wave as Dictionary if wave is Dictionary else {}

func _configure_current_wave_timer() -> void:
	var wave_config := _get_current_wave_config()
	enemy_timer.wait_time = float(wave_config.get("spawn_interval", _level_config.get("spawn_interval", 0.55)))

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

## 在草地格上放置 2D 树 (带碰撞, 阻挡玩家), 山/水瓦片本身已有碰撞。
func _place_trees() -> void:
	var placements := level_tile_map.get_tree_placements()
	for world_position in placements:
		var tree := StaticBody2D.new()
		tree.position = world_position
		tree.collision_layer = 1
		tree.collision_mask = 0
		var sprite := Sprite2D.new()
		sprite.texture = TREE_SPRITES
		sprite.hframes = 4
		sprite.frame = randi() % 4
		sprite.position = Vector2(0, -52)
		tree.add_child(sprite)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = TREE_COLLISION_RADIUS
		shape.shape = circle
		shape.position = Vector2(0, -20)
		tree.add_child(shape)
		add_child(tree)
