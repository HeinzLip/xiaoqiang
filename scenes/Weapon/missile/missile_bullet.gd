extends Weapon

## 子弹发射时间
var _bullet_fire_delay: float = 1.0
## 子弹每次发射的数量
var _bullet_fire_number: int = 1
## 子弹发射后移动速度
var _bullet_fire_speed: float = 1.0
## 子弹发射后的尺寸
var _bullet_scale: float = 1.0
## 子弹发射后的伤害
var _bullet_damage: float = 1.0
## 发射子弹的角度
var _buller_fire_angle: float = 5

@onready var game_pool := $MissileBulletPool

var _fire_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var missile_bullet_scene = preload("res://scenes/Bullet/missile/Missile.tscn")
	game_pool.init(missile_bullet_scene, _bullet_fire_number)
	
func _create_timer():
	_fire_timer = Timer.new();
	_fire_timer.wait_time = _bullet_fire_delay
	add_child(_fire_timer)
	_fire_timer.start()
	_fire_timer.timeout.connect(_fire_missile_bullet)
	
func _fire_missile_bullet():
	var update_angle = _buller_fire_angle / (_bullet_fire_number - 1)
	var start_angle = -_buller_fire_angle / 2
	for index in range(_bullet_fire_number):
		var bullet = game_pool.get_pool_object()
		bullet.global_rotation_degrees = global_rotation_degrees + start_angle + update_angle * index


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
