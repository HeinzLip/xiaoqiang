class_name Player extends CharacterBody2D

var rotation_speed := PI
var move_speed := 500.0
var max_health := 10
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
	global_position = global_position.clamp(Vector2(-Global.move_max_width, -Global.move_max_height), Vector2(Global.move_max_width, Global.move_max_height))
	

#func _reset_over() -> void:
		#prints("reset over ->", get_tree())
		#if get_tree() != null:
			#get_tree().paused = false

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
		#call_deferred("_reset_over")
		
