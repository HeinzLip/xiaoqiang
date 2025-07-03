class_name Player extends CharacterBody2D

var rotation_speed := PI
var move_speed := 500.0
var max_health := 1
var current_health: float

@onready var player_attacked_area := $Attacked_Area
@onready var player_experience_area := $Experience_Area
@onready var player_attacked_anim := $AnimationPlayer

@onready var screen_size := get_viewport_rect().size

func _ready() -> void:
	player_attacked_area.name = "player_attacked_area"
	player_experience_area.name = "player_experience_area"
	global_position = Vector2.ZERO
	current_health = max_health
	if get_tree().paused:
		get_tree().paused = false

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
	var half_screen_size = screen_size / 2
	global_position = global_position.clamp(Vector2(-Global.global_data.move_max_width, -Global.global_data.move_max_height), Vector2(Global.global_data.move_max_width, Global.global_data.move_max_height))
	

func _reset_over() -> void:
		prints("reset over ->", get_tree())
		
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")

## player接受enemy的伤害
func apply_damage(_damage: float) -> void:
	current_health += _damage
	if _damage < 0:
		player_attacked_anim.play("attacked_anim")
		#prints("player player attacked anim")
		pass
	if current_health <= 0:
		## player死亡逻辑
		get_tree().paused = true
		var isRest = get_tree().reload_current_scene()
		#Global.reset_game()
		#get_tree().current_scene.free()
		
		#get_tree().create_timer(1.0).timeout.connect(_reset_over)
		#call_deferred("")
		
func _exit_tree() -> void:
	prints("player free")
