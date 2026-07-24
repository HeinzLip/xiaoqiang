class_name Player extends CharacterBody2D

signal health_changed(current: float, maximum: float)

var rotation_speed := PI
const BASE_MOVE_SPEED := 500.0
const BASE_MAX_HEALTH := 100.0
var move_speed := BASE_MOVE_SPEED
@export var max_health := BASE_MAX_HEALTH
var current_health: float
var _skill_move_speed_bonus := 0.0

@onready var player_attacked_area := $Attacked_Area
@onready var player_experience_area := $Experience_Area
@onready var player_attacked_anim := $AnimationPlayer

@onready var screen_size := get_viewport_rect().size

func _ready() -> void:
	_refresh_move_speed()
	max_health = BASE_MAX_HEALTH + CurrencyManager.get_max_health_bonus()
	player_attacked_area.name = "player_attacked_area"
	player_experience_area.name = "player_experience_area"
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
	if direction == Vector2.ZERO:
		rotation += delta * rotation_speed
	
	velocity = direction.normalized() *move_speed
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
		player_attacked_anim.play("attacked_anim")
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
