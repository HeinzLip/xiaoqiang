class_name Enemy extends Area2D

signal defeated(enemy: Enemy)

const COIN_PICKUP_SCENE := preload("res://scenes/Coin/CoinPickup.tscn")
const NORMAL_COIN_DROP_CHANCE := 0.24
const BOSS_COIN_COUNT := 24
const BOSS_COIN_VALUE := 5
const ELITE_HEALTH_MULTIPLIER := 5.0
const ELITE_DAMAGE_MULTIPLIER := 1.75
const ELITE_SPEED_MULTIPLIER := 0.75
const ELITE_RESOURCE_PATH := "res://assets/enemies/elite_champion_standard_sheet.png"
const ELITE_ANIMATION_COLUMNS := 10
const ELITE_ANIMATION_ROWS := 4
const IDLE_ROW := 0
const WALK_ROW := 1
const HIT_ROW := 2
const DEATH_ROW := 3
# 5 行动画 (含近战攻击) 的行索引
const ATTACK_ROW := 2
const ATTACK_HIT_ROW := 3
const ATTACK_DEATH_ROW := 4
const IDLE_FRAME_COUNT := 6
const WALK_FRAME_COUNT := 10
const HIT_FRAME_COUNT := 5
const DEATH_FRAME_COUNT := 10
const ATTACK_FRAME_COUNT := 6
const IDLE_FRAME_RATE := 5.0
const WALK_FRAME_RATE := 10.0
const HIT_FRAME_RATE := 14.0
const DEATH_FRAME_RATE := 10.0
const ATTACK_FRAME_RATE := 10.0
const HIT_ANIMATION_DURATION := float(HIT_FRAME_COUNT) / HIT_FRAME_RATE
const LEGACY_WALK_FRAME_RATE := 5.0

var mPlayer: Player
@export var max_health: float = 32.0
var current_health: float

var is_attack_player := false
var is_elite := false
var is_boss := false
var experience_reward := 12
var move_speed := 85.0
var attack_damage := 8.0
var attack_interval := 0.9
var _attack_cooldown := 0.0
var is_ranged := false
var _ranged_attack_cooldown := 0.0
var _ranged_attack_interval := BalanceConfig.RANGED_ATTACK_INTERVAL
var _ranged_attack_range := BalanceConfig.RANGED_ATTACK_RANGE
var _is_dead := false
var _slow_ratio := 0.0
var _slow_remaining := 0.0
var _shock_remaining := 0.0
var _shock_spark_time := 0.0
var _visual_resource_path := ""
var _animation_columns := 1
var _animation_rows := 1
var _visual_idle_frame := 0
var _legacy_walk_animation_time := 0.0
var _active_animation_row := -1
var _active_animation_elapsed := 0.0
var _hit_remaining := 0.0
var _attack_animation_remaining := 0.0
var _death_animation_finished := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var shock_sprite: Sprite2D = $ShockSprite
@onready var elite_health_bar: ProgressBar = $EliteHealthBar

const SHOCK_FRAME_COUNT := 4
const SHOCK_FRAME_RATE := 12.0

func setup(wave_config: Dictionary, difficulty_multiplier: float, elite: bool, boss: bool = false) -> void:
	is_elite = elite
	is_boss = boss
	if is_elite and not is_boss:
		_visual_resource_path = str(wave_config.get("elite_resource", ELITE_RESOURCE_PATH))
		_animation_columns = maxi(int(wave_config.get("elite_animation_columns", ELITE_ANIMATION_COLUMNS)), 1)
		_animation_rows = maxi(int(wave_config.get("elite_animation_rows", ELITE_ANIMATION_ROWS)), 1)
	else:
		_visual_resource_path = str(wave_config.get("resource", ""))
		_animation_columns = maxi(int(wave_config.get("animation_columns", wave_config.get("animation_frames", 1))), 1)
		_animation_rows = maxi(int(wave_config.get("animation_rows", 1)), 1)
	_visual_idle_frame = clampi(int(wave_config.get("idle_frame", 0)), 0, _animation_columns - 1)
	var multiplier := maxf(difficulty_multiplier, 0.1)
	var base_health := float(wave_config.get("health", 32.0))
	var base_damage := float(wave_config.get("attack_damage", 8.0))
	var base_speed := float(wave_config.get("move_speed", 85.0))
	var base_experience := int(wave_config.get("experience_reward", 12))
	max_health = base_health * multiplier
	attack_damage = base_damage * multiplier
	move_speed = base_speed * multiplier
	# 敌人原型 (archetype) 数值修正: fast 快而脆 / tank 慢而厚 / ranged 远程更脆
	var archetype := str(wave_config.get("archetype", ""))
	is_ranged = false
	if not archetype.is_empty() and BalanceConfig.ENEMY_ARCHETYPE.has(archetype):
		var mods: Dictionary = BalanceConfig.ENEMY_ARCHETYPE[archetype]
		max_health *= float(mods.get("health", 1.0))
		attack_damage *= float(mods.get("attack_damage", 1.0))
		move_speed *= float(mods.get("move_speed", 1.0))
		is_ranged = archetype == "ranged"
	attack_interval = 0.55 if boss else (0.7 if elite else 0.9)
	if boss:
		experience_reward = roundi(float(wave_config.get("experience_reward", 360)) * multiplier)
	elif elite:
		max_health *= ELITE_HEALTH_MULTIPLIER
		attack_damage *= ELITE_DAMAGE_MULTIPLIER
		move_speed *= ELITE_SPEED_MULTIPLIER
		experience_reward = roundi(float(base_experience) * 6.5 * multiplier)
	else:
		experience_reward = roundi(float(base_experience) * multiplier)

func _ready() -> void:
	current_health = max_health
	mPlayer = Global.player
	add_to_group(GroupConfig.get_instance().Enemy_Group)
	RunMetrics.register_enemy(self)
	_apply_visual_resource()
	if is_boss:
		scale = Vector2.ONE * 0.70
		sprite.modulate = Color.WHITE
	elif is_elite:
		scale = Vector2.ONE * 0.47
		sprite.modulate = Color.WHITE
	else:
		scale = Vector2.ONE * 0.25
		sprite.modulate = Color.WHITE
	# 电球精灵抵消节点缩放, 保持合适的世界显示尺寸 (约 110px 覆盖身体)
	if is_instance_valid(shock_sprite):
		var enemy_scale := maxf(absf(scale.x), 0.001)
		shock_sprite.scale = Vector2.ONE * (110.0 / 128.0) / enemy_scale
	_update_elite_health_bar()

func _apply_visual_resource() -> void:
	sprite.hframes = _animation_columns
	sprite.vframes = _animation_rows
	if _has_standard_animation():
		_set_animation_frame(IDLE_ROW, 0)
	else:
		sprite.frame = _visual_idle_frame
	sprite.flip_h = false
	if not _visual_resource_path.is_empty():
		var configured_texture := load(_visual_resource_path) as Texture2D
		if configured_texture != null:
			sprite.texture = configured_texture
		else:
			push_warning("Enemy resource could not be loaded: %s" % _visual_resource_path)

func _process(delta: float) -> void:
	if _is_dead:
		_advance_death_animation(delta)
		return
	if not is_instance_valid(mPlayer):
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_slow_remaining = maxf(_slow_remaining - delta, 0.0)
	if _slow_remaining <= 0.0:
		_slow_ratio = 0.0
	# 感电动画: 电球精灵帧播放
	var was_shocked := _shock_remaining > 0.0
	_shock_remaining = maxf(_shock_remaining - delta, 0.0)
	if _shock_remaining > 0.0:
		_shock_spark_time += delta
		if is_instance_valid(shock_sprite):
			shock_sprite.visible = true
			shock_sprite.frame = int(floor(_shock_spark_time * SHOCK_FRAME_RATE)) % SHOCK_FRAME_COUNT
	elif was_shocked:
		if is_instance_valid(shock_sprite):
			shock_sprite.visible = false
	var is_moving := false
	if not is_attack_player:
		if is_ranged:
			# 远程: 射程外追击, 射程内停步朝玩家开火
			_ranged_attack_cooldown = maxf(_ranged_attack_cooldown - delta, 0.0)
			var distance_to_player := global_position.distance_to(mPlayer.global_position)
			if distance_to_player <= _ranged_attack_range:
				sprite.flip_h = mPlayer.global_position.x < global_position.x
				if _ranged_attack_cooldown <= 0.0:
					_fire_ranged_projectile()
					_ranged_attack_cooldown = _ranged_attack_interval
			else:
				is_moving = _move_toward_player(delta)
		else:
			is_moving = _move_toward_player(delta)
	elif _attack_cooldown <= 0.0:
		Global.player.apply_damage(-attack_damage)
		_attack_cooldown = attack_interval
	_update_animation(delta, is_moving)

## 近战敌人/远程敌人(射程外) 朝向玩家并移动, 返回是否在移动
func _move_toward_player(delta: float) -> bool:
	var horizontal_distance := mPlayer.global_position.x - global_position.x
	if absf(horizontal_distance) > 0.01:
		sprite.flip_h = horizontal_distance < 0.0
	var speed_multiplier := 1.0 - _slow_ratio
	global_position = global_position.move_toward(mPlayer.global_position, move_speed * speed_multiplier * delta)
	return true

## 远程攻击: 朝玩家当前位置射出弹体 (伤害 = 当前 attack_damage, 含难度/原型修正)
func _fire_ranged_projectile() -> void:
	# 有攻击行动画时播放一次开火动画 (弹体与动画同时触发, 视觉预告)
	if _has_attack_animation():
		_attack_animation_remaining = float(ATTACK_FRAME_COUNT) / ATTACK_FRAME_RATE
		_active_animation_row = -1
		_active_animation_elapsed = 0.0
	var projectile := preload("res://scenes/enemy/enemy_projectile.gd").new() as EnemyProjectile
	if projectile == null:
		return
	projectile.configure(global_position, mPlayer.global_position, attack_damage)
	get_tree().current_scene.add_child(projectile)

func _update_animation(delta: float, is_moving: bool) -> void:
	if not _has_standard_animation():
		if is_moving:
			_advance_legacy_walk_animation(delta)
		else:
			_reset_legacy_walk_animation()
		return
	if _hit_remaining > 0.0:
		_hit_remaining = maxf(_hit_remaining - delta, 0.0)
		_play_animation_row(_hit_row(), HIT_FRAME_COUNT, HIT_FRAME_RATE, delta, false)
	elif _attack_animation_remaining > 0.0:
		# 远程开火/攻击动画 (一次性播放, 播放期间敌人站定)
		_attack_animation_remaining = maxf(_attack_animation_remaining - delta, 0.0)
		_play_animation_row(ATTACK_ROW, ATTACK_FRAME_COUNT, ATTACK_FRAME_RATE, delta, false)
	elif is_attack_player and _has_attack_animation():
		_play_animation_row(ATTACK_ROW, ATTACK_FRAME_COUNT, ATTACK_FRAME_RATE, delta, true)
	elif is_moving:
		_play_animation_row(WALK_ROW, WALK_FRAME_COUNT, WALK_FRAME_RATE, delta, true)
	else:
		_play_animation_row(IDLE_ROW, IDLE_FRAME_COUNT, IDLE_FRAME_RATE, delta, true)

func _play_animation_row(row: int, frame_count: int, frame_rate: float, delta: float, loop: bool) -> bool:
	if _active_animation_row != row:
		_active_animation_row = row
		_active_animation_elapsed = 0.0
	else:
		_active_animation_elapsed += delta
	var frame_index := int(floor(_active_animation_elapsed * frame_rate))
	if loop:
		frame_index = posmod(frame_index, frame_count)
	else:
		frame_index = mini(frame_index, frame_count - 1)
	_set_animation_frame(row, frame_index)
	return not loop and _active_animation_elapsed >= float(frame_count) / frame_rate

func _set_animation_frame(row: int, column: int) -> void:
	var safe_row := clampi(row, 0, _animation_rows - 1)
	var safe_column := clampi(column, 0, _animation_columns - 1)
	sprite.frame = safe_row * _animation_columns + safe_column

func _has_standard_animation() -> bool:
	return _animation_columns >= WALK_FRAME_COUNT and _animation_rows >= DEATH_ROW + 1

func _has_attack_animation() -> bool:
	return _animation_rows >= ATTACK_DEATH_ROW + 1

func _hit_row() -> int:
	return ATTACK_HIT_ROW if _has_attack_animation() else HIT_ROW

func _death_row() -> int:
	return ATTACK_DEATH_ROW if _has_attack_animation() else DEATH_ROW

func _advance_legacy_walk_animation(delta: float) -> void:
	if _animation_columns <= 1:
		return
	_legacy_walk_animation_time += delta
	var sequence_index := int(floor(_legacy_walk_animation_time * LEGACY_WALK_FRAME_RATE)) % 4
	var next_frame := 1
	if sequence_index == 0:
		next_frame = 0
	elif sequence_index == 2:
		next_frame = 2
	sprite.frame = next_frame % _animation_columns

func _reset_legacy_walk_animation() -> void:
	_legacy_walk_animation_time = 0.0
	sprite.frame = _visual_idle_frame

func apply_damage(damage: float) -> void:
	if _is_dead:
		return
	var health_before := current_health
	current_health = clampf(current_health + damage, 0.0, max_health)
	RunMetrics.record_damage(self, maxf(health_before - current_health, 0.0))
	_update_elite_health_bar()
	if current_health <= 0.0:
		CountManager.add_destroy_enemy()
		_dead()
	else:
		_trigger_hit_animation()

func apply_slow(slow_ratio: float, duration: float = 1.2) -> void:
	if _is_dead or slow_ratio <= 0.0:
		return
	_slow_ratio = maxf(_slow_ratio, clampf(slow_ratio, 0.0, 0.85))
	_slow_remaining = maxf(_slow_remaining, duration)

## 感电: 短暂减速 + 电球视觉效果 (落雷专属), 效果结束后电球消失。
func apply_shock(duration: float) -> void:
	if _is_dead or duration <= 0.0:
		return
	_slow_ratio = maxf(_slow_ratio, 0.35)
	_slow_remaining = maxf(_slow_remaining, duration)
	_shock_remaining = maxf(_shock_remaining, duration)
	if is_instance_valid(shock_sprite):
		shock_sprite.visible = true
		shock_sprite.frame = 0

func is_shocked() -> bool:
	return _shock_remaining > 0.0

func _update_elite_health_bar() -> void:
	if not is_elite:
		elite_health_bar.hide()
		return
	elite_health_bar.max_value = max_health
	elite_health_bar.value = current_health
	elite_health_bar.visible = current_health < max_health

func _dead() -> void:
	_is_dead = true
	RunMetrics.record_defeat(self)
	elite_health_bar.hide()
	_active_animation_row = -1
	_active_animation_elapsed = 0.0
	_shock_remaining = 0.0
	if is_instance_valid(shock_sprite):
		shock_sprite.visible = false
	queue_redraw()
	# 死亡后立即禁用碰撞, 子弹等可穿透死亡敌人的位置继续前进
	collision_layer = 0
	collision_mask = 0
	set_deferred("monitoring", false)
	if not _has_standard_animation():
		_finish_death()

func _trigger_hit_animation() -> void:
	if not _has_standard_animation():
		return
	_hit_remaining = HIT_ANIMATION_DURATION
	_active_animation_row = -1
	_active_animation_elapsed = 0.0

func _advance_death_animation(delta: float) -> void:
	if _death_animation_finished:
		return
	if _play_animation_row(_death_row(), DEATH_FRAME_COUNT, DEATH_FRAME_RATE, delta, false):
		_finish_death()

func _finish_death() -> void:
	if _death_animation_finished:
		return
	_death_animation_finished = true
	if is_boss:
		_drop_boss_coin_burst()
	elif not is_elite and randf() < NORMAL_COIN_DROP_CHANCE:
		_drop_coin(randi_range(1, 3))
	var bean := EEManager.get_bean()
	bean.configure(experience_reward)
	bean.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", bean)
	if is_elite and not is_boss:
		PlayerExperienceSystem.request_elite_reward()
	defeated.emit(self)
	queue_free()

func _drop_coin(amount: int) -> void:
	var coin := COIN_PICKUP_SCENE.instantiate() as Node2D
	coin.call("configure", amount)
	coin.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", coin)

func _drop_boss_coin_burst() -> void:
	for index in range(BOSS_COIN_COUNT):
		var coin := COIN_PICKUP_SCENE.instantiate() as Node2D
		coin.call("configure", BOSS_COIN_VALUE, true)
		coin.global_position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 110.0)
		get_tree().current_scene.call_deferred("add_child", coin)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(GroupConfig.get_instance().Player_Attack_Area_Group):
		is_attack_player = true
		_attack_cooldown = 0.0

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group(GroupConfig.get_instance().Player_Attack_Area_Group):
		is_attack_player = false
