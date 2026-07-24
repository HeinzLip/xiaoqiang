class_name Enemy extends Area2D

signal defeated(enemy: Enemy)

const COIN_PICKUP_SCENE := preload("res://scenes/Coin/CoinPickup.tscn")
const NORMAL_COIN_DROP_CHANCE := 0.24
const BOSS_COIN_COUNT := 24
const BOSS_COIN_VALUE := 5

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
var _is_dead := false
var _slow_ratio := 0.0
var _slow_remaining := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var elite_health_bar: ProgressBar = $EliteHealthBar

func setup(elite: bool, difficulty: float, boss: bool = false) -> void:
	is_elite = elite
	is_boss = boss
	max_health = (920.0 if boss else (160.0 if elite else 32.0)) * difficulty
	experience_reward = roundi((360.0 if boss else (80.0 if elite else 12.0)) * difficulty)
	move_speed = (44.0 if boss else (62.0 if elite else 85.0)) + difficulty * 7.0
	attack_damage = (26.0 if boss else (14.0 if elite else 8.0)) * (0.8 + difficulty * 0.2)
	attack_interval = 0.55 if boss else (0.7 if elite else 0.9)

func _ready() -> void:
	current_health = max_health
	mPlayer = Global.player
	add_to_group(GroupConfig.get_instance().Enemy_Group)
	if is_boss:
		scale = Vector2.ONE * 0.65
		sprite.modulate = Color("b774ff")
	elif is_elite:
		scale = Vector2.ONE * 0.38
		sprite.modulate = Color("ff7168")
	else:
		scale = Vector2.ONE * 0.20
		sprite.modulate = Color("9bd7ff")
	_update_elite_health_bar()

func _process(delta: float) -> void:
	if _is_dead or not is_instance_valid(mPlayer):
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_slow_remaining = maxf(_slow_remaining - delta, 0.0)
	if _slow_remaining <= 0.0:
		_slow_ratio = 0.0
	if not is_attack_player:
		var speed_multiplier := 1.0 - _slow_ratio
		global_position = global_position.move_toward(mPlayer.global_position, move_speed * speed_multiplier * delta)
	elif _attack_cooldown <= 0.0:
		Global.player.apply_damage(-attack_damage)
		_attack_cooldown = attack_interval

func apply_damage(damage: float) -> void:
	if _is_dead:
		return
	current_health = clampf(current_health + damage, 0.0, max_health)
	_update_elite_health_bar()
	if current_health <= 0.0:
		CountManager.add_destroy_enemy()
		_dead()

func apply_slow(slow_ratio: float, duration: float = 1.2) -> void:
	if _is_dead or slow_ratio <= 0.0:
		return
	_slow_ratio = maxf(_slow_ratio, clampf(slow_ratio, 0.0, 0.85))
	_slow_remaining = maxf(_slow_remaining, duration)

func _update_elite_health_bar() -> void:
	if not is_elite:
		elite_health_bar.hide()
		return
	elite_health_bar.max_value = max_health
	elite_health_bar.value = current_health
	elite_health_bar.visible = current_health < max_health

func _dead() -> void:
	_is_dead = true
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
	if area.name == "player_attacked_area":
		is_attack_player = true
		_attack_cooldown = 0.0

func _on_area_exited(area: Area2D) -> void:
	if area.name == "player_attacked_area":
		is_attack_player = false
