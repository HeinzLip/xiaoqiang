class_name Player extends CharacterBody2D

signal health_changed(current: float, maximum: float)

const BASE_MOVE_SPEED := BalanceConfig.BASE_MOVE_SPEED
const BASE_MAX_HEALTH := BalanceConfig.BASE_MAX_HEALTH
var move_speed := BASE_MOVE_SPEED
@export var max_health := BASE_MAX_HEALTH
var current_health: float
var _skill_move_speed_bonus := 0.0

@onready var player_attacked_area := $Attacked_Area
@onready var player_experience_area := $Experience_Area
@onready var player_visual: PlayerVisual = $PlayerVisual

@onready var screen_size := get_viewport_rect().size

func _ready() -> void:
	_refresh_move_speed()
	max_health = BASE_MAX_HEALTH + CurrencyManager.get_max_health_bonus()
	# 光环区域用分组标识 (而非运行时改名/字符串匹配), 供敌人/拾取物判断
	player_attacked_area.add_to_group(GroupConfig.get_instance().Player_Attack_Area_Group)
	player_experience_area.add_to_group(GroupConfig.get_instance().Player_Experience_Area_Group)
	global_position = Vector2.ZERO
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	
	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		direction.x += -1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y += -1
	velocity = direction.normalized() *move_speed
	player_visual.set_movement(direction)
	player_visual.update_animation(delta)
	#velocity = Vector2.UP.rotated(rotation).normalized() * move_speed * delta
	
	#prints("current direction ->", direction, "velocity ->", velocity)
	
	move_and_slide()
	#print("current position ->", position, "screen_size ->", screen_size)
	global_position = global_position.clamp(Vector2(-Global.global_data.move_max_width, -Global.global_data.move_max_height), Vector2(Global.global_data.move_max_width, Global.global_data.move_max_height))
	

func _reset_over() -> void:
		prints("reset over ->", get_tree())
		
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")

## player接受enemy的伤害
func apply_damage(_damage: float) -> void:
	current_health = clampf(current_health + _damage, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	if _damage < 0:
		player_visual.play_hit_flash()
		#prints("player player attacked anim")
		pass
	if current_health <= 0:
		Global.player_dead()

func set_skill_move_speed_bonus(bonus: float) -> void:
	_skill_move_speed_bonus = maxf(bonus, 0.0)
	_refresh_move_speed()

func _refresh_move_speed() -> void:
	move_speed = (BASE_MOVE_SPEED + CurrencyManager.get_move_speed_bonus()) * (1.0 + _skill_move_speed_bonus)
		
func _exit_tree() -> void:
	prints("player free")
